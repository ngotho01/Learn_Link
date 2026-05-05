import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reads cached jobs & news directly from Firestore.
/// Replaces the FastAPI calls for jobs/news browsing.
class CachedDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── News ─────────────────────────────────────────────────────

  /// Stream of cached news articles filtered by user's field.
  Stream<List<Map<String, dynamic>>> getNewsStream(String field) {
    return _db
        .collection('cached_news')
        .where('field', isEqualTo: field.toLowerCase())
        .orderBy('fetched_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  /// One-shot fetch of cached news (for pull-to-refresh).
  Future<List<Map<String, dynamic>>> getNews(String field) async {
    print('📰 DEBUG: Querying cached_news for field="${field.toLowerCase()}"');
    try {
      final snap = await _db
          .collection('cached_news')
          .where('field', isEqualTo: field.toLowerCase())
          .orderBy('fetched_at', descending: true)
          .get();
      print('📰 DEBUG: Got ${snap.docs.length} articles');
      return snap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('📰 DEBUG ERROR: $e');
      return [];
    }
  }
  // ── Jobs ──────────────────────────────────────────────────────

  /// Fetch cached jobs for a field, score them against the user profile,
  /// and return sorted recommendations.
  Future<Map<String, dynamic>> getPersonalizedJobs({
    required String userId,
    int limit = 20,
  }) async {
    // 1. Load user profile
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return _emptyResult('User profile not found');
    }

    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final userSkills = List<String>.from(userData['skills'] ?? []);
    final userField = (userData['field'] ?? '') as String;
    final userName = (userData['name'] ?? 'User') as String;

    if (userSkills.isEmpty && userField.isEmpty) {
      return _emptyResult('Please add your skills and field of interest');
    }

    // 2. Load cached jobs for user's field
    final snap = await _db
        .collection('cached_jobs')
        .where('field', isEqualTo: userField.toLowerCase())
        .get();

    List<Map<String, dynamic>> jobs =
    snap.docs.map((doc) => Map<String, dynamic>.from(doc.data())).toList();

    if (jobs.isEmpty) {
      // Fallback: try 'technology' if user's field has no jobs
      final fallback = await _db
          .collection('cached_jobs')
          .where('field', isEqualTo: 'technology')
          .get();
      jobs = fallback.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .toList();
    }

    if (jobs.isEmpty) {
      return {
        'user_id': userId,
        'user_name': userName,
        'user_skills': userSkills,
        'user_field': userField,
        'recommendations': <Map<String, dynamic>>[],
        'recommendation_stats': {
          'excellent_matches': 0,
          'good_matches': 0,
          'potential_matches': 0,
          'total_recommendations': 0,
        },
        'message': 'No cached jobs available. Check back later.',
      };
    }

    // 3. Score each job
    for (final job in jobs) {
      final score = _calculateMatchScore(job, userSkills, userField);
      job['match_score'] = (score * 100).round();
      job['match_level'] = _getMatchLevel(score);
      job['matched_skills'] = _findMatchedSkills(job, userSkills);
    }

    // 4. Sort by score descending, take top N
    jobs.sort(
            (a, b) => (b['match_score'] as int).compareTo(a['match_score'] as int));
    final top = jobs.take(limit).toList();

    // 5. Build stats
    final excellent = top.where((j) => (j['match_score'] as int) >= 70).length;
    final good = top
        .where(
            (j) => (j['match_score'] as int) >= 50 && (j['match_score'] as int) < 70)
        .length;
    final potential = top
        .where(
            (j) => (j['match_score'] as int) >= 30 && (j['match_score'] as int) < 50)
        .length;

    return {
      'user_id': userId,
      'user_name': userName,
      'user_skills': userSkills,
      'user_field': userField,
      'recommendations': top,
      'recommendation_stats': {
        'excellent_matches': excellent,
        'good_matches': good,
        'potential_matches': potential,
        'total_recommendations': top.length,
      },
      'message': 'Found ${top.length} personalized job recommendations',
    };
  }

  /// Search cached jobs by keyword (for the search bar).
  Future<List<Map<String, dynamic>>> searchJobs(String query, {int limit = 20}) async {
    final queryLower = query.toLowerCase();

    // Firestore doesn't support full-text search, so we fetch all and filter client-side.
    // With ~250 cached jobs this is fast enough.
    final snap = await _db.collection('cached_jobs').get();
    final allJobs = snap.docs.map((doc) => doc.data()).toList();

    final matches = allJobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final company = (job['company'] ?? '').toString().toLowerCase();
      final description = (job['description'] ?? '').toString().toLowerCase();
      return title.contains(queryLower) ||
          company.contains(queryLower) ||
          description.contains(queryLower);
    }).take(limit).toList();

    return matches;
  }

  // ── Match scoring (mirrors backend logic) ─────────────────────

  double _calculateMatchScore(
      Map<String, dynamic> job, List<String> userSkills, String userField) {
    double score = 0;
    const maxScore = 100.0;

    final jobTitle = (job['title'] ?? '').toString().toLowerCase();
    final jobDesc = (job['description'] ?? '').toString().toLowerCase();
    final jobText = '$jobTitle $jobDesc';

    // 1. Skill matching (60 points)
    if (userSkills.isNotEmpty) {
      int matched = 0;
      for (final skill in userSkills) {
        if (jobText.contains(skill.toLowerCase())) matched++;
      }
      score += (matched / userSkills.length) * 60;
    }

    // 2. Field matching (30 points)
    if (userField.isNotEmpty) {
      final keywords = _getFieldKeywords(userField);
      final fieldMatches =
          keywords.where((kw) => jobText.contains(kw)).length;
      if (fieldMatches > 0) {
        score += (fieldMatches / keywords.length).clamp(0.0, 1.0) * 30;
      }
    }

    // 3. Quality indicators (10 points)
    if (jobDesc.length > 200) score += 5;
    if ((job['apply_url'] ?? '').toString().isNotEmpty) score += 5;

    return (score / maxScore).clamp(0.0, 1.0);
  }

  String _getMatchLevel(double score) {
    final pct = score * 100;
    if (pct >= 70) return 'Excellent Match';
    if (pct >= 50) return 'Good Match';
    if (pct >= 30) return 'Potential Match';
    return 'Fair Match';
  }

  List<String> _findMatchedSkills(
      Map<String, dynamic> job, List<String> userSkills) {
    final jobText =
    '${job['title'] ?? ''} ${job['description'] ?? ''}'.toLowerCase();
    return userSkills
        .where((skill) => jobText.contains(skill.toLowerCase()))
        .toList();
  }

  List<String> _getFieldKeywords(String field) {
    const fieldMap = {
      'technology': ['software', 'developer', 'engineer', 'programming', 'tech', 'digital', 'it', 'computer'],
      'business': ['business', 'management', 'analyst', 'strategy', 'operations', 'consulting', 'sales'],
      'healthcare': ['healthcare', 'medical', 'health', 'clinical', 'patient', 'hospital', 'nurse'],
      'engineering': ['engineering', 'mechanical', 'civil', 'electrical', 'design', 'technical'],
      'design': ['design', 'creative', 'ui', 'ux', 'graphic', 'visual', 'art'],
      'marketing': ['marketing', 'digital marketing', 'social media', 'content', 'brand', 'advertising'],
      'finance': ['finance', 'accounting', 'financial', 'investment', 'banking', 'analyst'],
      'education': ['education', 'teaching', 'instructor', 'training', 'academic', 'learning'],
    };
    return fieldMap[field.toLowerCase()] ?? [field.toLowerCase()];
  }

  // ── Cache freshness ───────────────────────────────────────────

  /// Check when data was last refreshed.
  Future<DateTime?> getLastRefreshTime() async {
    final doc =
    await _db.collection('cache_metadata').doc('last_refresh').get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    final ts = data?['refreshed_at'] as String?;
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  Map<String, dynamic> _emptyResult(String message) {
    return {
      'recommendations': <Map<String, dynamic>>[],
      'recommendation_stats': {
        'excellent_matches': 0,
        'good_matches': 0,
        'potential_matches': 0,
        'total_recommendations': 0,
      },
      'message': message,
    };
  }
}