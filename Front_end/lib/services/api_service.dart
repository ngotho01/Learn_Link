import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'https://learnlink-910g.onrender.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get auth token for authenticated requests
  Future<String?> _getAuthToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // Generic GET request with auth - CHANGED: returns dynamic to handle both Map and List
  Future<dynamic> _getRequest(String endpoint) async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);  // Can be Map or List
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  // Jobs API
  Future<List<dynamic>> searchJobs({
    required String query,
    int limit = 10,
  }) async {
    final data = await _getRequest('/jobs/search?query=$query&limit=$limit');
    if (data is Map) {
      return data['jobs'] ?? [];
    }
    return data ?? [];
  }

  Future<List<dynamic>> getRecommendedJobs({
    String? field,
    int limit = 10,
  }) async {
    String endpoint = '/jobs/recommendations?limit=$limit';
    if (field != null) {
      endpoint += '&field=$field';
    }
    final data = await _getRequest(endpoint);
    if (data is Map) {
      return data['jobs'] ?? [];
    }
    return data ?? [];
  }

  // News API
  Future<List<dynamic>> getIndustryNews({
    required String field,
    int limit = 10,
  }) async {
    final data = await _getRequest('/news/industry?field=$field&limit=$limit');
    if (data is Map) {
      return data['articles'] ?? [];
    }
    return data ?? [];
  }

  // YouTube API
  Future<List<dynamic>> searchYouTubeVideos({
    required String query,
    int maxResults = 10,
  }) async {
    final data = await _getRequest(
      '/youtube/search?query=$query&max_results=$maxResults',
    );
    if (data is Map) {
      return data['videos'] ?? [];
    }
    return data ?? [];
  }

  Future<List<dynamic>> getRecommendedVideos({
    String? field,
    int maxResults = 10,
  }) async {
    String endpoint = '/youtube/recommendations?max_results=$maxResults';
    if (field != null) {
      endpoint += '&field=$field';
    }
    final data = await _getRequest(endpoint);
    if (data is Map) {
      return data['videos'] ?? [];
    }
    return data ?? [];
  }

  // AI Summarization
  Future<String> summarizeText(String text) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/ai/summarize'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['summary'] ?? text;
      }
      return text;
    } catch (e) {
      print('Summarization Error: $e');
      return text;
    }
  }

  // ========== PERSONALIZED RECOMMENDATIONS ==========

  // Get personalized job recommendations with match scores
  // Get personalized job recommendations with match scores
  Future<Map<String, dynamic>> getPersonalizedJobs(String userId, {int limit = 20}) async {
    try {
      print('📱 Calling: /recommendations/jobs/$userId?limit=$limit');
      final data = await _getRequest('/recommendations/jobs/$userId?limit=$limit');
      print('📊 Backend response type: ${data.runtimeType}');

      // Handle both Map and List responses
      if (data is List) {
        print('✅ Got List with ${data.length} jobs');
        // FIXED: Use 'recommendations' key to match JobsScreen expectations
        return {
          'recommendations': data,
          'recommendation_stats': {
            'total_matches': data.length,
            'excellent_matches': data.where((j) => (j['match_score'] ?? 0) >= 70).length,
            'good_matches': data.where((j) => (j['match_score'] ?? 0) >= 50 && (j['match_score'] ?? 0) < 70).length,
            'potential_matches': data.where((j) => (j['match_score'] ?? 0) < 50).length,
          }
        };
      } else if (data is Map) {
        print('✅ Got Map response');
        // If backend already returns proper format, use it
        // Otherwise, ensure keys match
        if (data.containsKey('recommendations')) {
          return data as Map<String, dynamic>;
        } else if (data.containsKey('jobs')) {
          // Transform 'jobs' key to 'recommendations'
          return {
            'recommendations': data['jobs'] ?? [],
            'recommendation_stats': data['recommendation_stats'] ?? data['stats'] ?? {},
          };
        }
        return data as Map<String, dynamic>;
      }

      print('⚠️ Unexpected response format');
      return {
        'recommendations': [],
        'recommendation_stats': {
          'total_matches': 0,
          'excellent_matches': 0,
          'good_matches': 0,
          'potential_matches': 0,
        }
      };
    } catch (e) {
      print('❌ Personalized Jobs Error: $e');
      rethrow;
    }
  }

  // Get personalized learning videos
  Future<Map<String, dynamic>> getPersonalizedLearning(String userId, {int maxResults = 15}) async {
    try {
      print('📱 Calling: /recommendations/learning/$userId?max_results=$maxResults');
      final data = await _getRequest('/recommendations/learning/$userId?max_results=$maxResults');

      if (data is List) {
        return {
          'videos': data,  // ← Keep as 'videos' if that's what learning screen expects
          'count': data.length
        };
      } else if (data is Map) {
        return data as Map<String, dynamic>;
      }

      return {'videos': [], 'count': 0};
    } catch (e) {
      print('❌ Personalized Learning Error: $e');
      rethrow;
    }
  }

  // Get personalized news
  Future<Map<String, dynamic>> getPersonalizedNews(String userId, {int limit = 15}) async {
    try {
      final data = await _getRequest('/recommendations/news/$userId?limit=$limit');

      if (data is List) {
        return {'articles': data, 'count': data.length};
      } else if (data is Map) {
        return data as Map<String, dynamic>;
      }

      return {'articles': [], 'count': 0};
    } catch (e) {
      print('Personalized News Error: $e');
      rethrow;
    }
  }

  // Get complete dashboard (all recommendations at once)
  Future<Map<String, dynamic>> getCompleteDashboard(String userId) async {
    try {
      final data = await _getRequest('/recommendations/dashboard/$userId');

      if (data is Map) {
        return data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      print('Dashboard Error: $e');
      rethrow;
    }
  }

  // Get recommendation stats
  Future<Map<String, dynamic>> getRecommendationStats(String userId) async {
    try {
      final data = await _getRequest('/recommendations/stats/$userId');

      if (data is Map) {
        return data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      print('Stats Error: $e');
      rethrow;
    }
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}