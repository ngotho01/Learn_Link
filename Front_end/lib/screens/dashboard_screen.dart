import 'package:LearnLink/screens/notifications_screen.dart';
import 'package:LearnLink/services/api_service.dart';
import 'package:LearnLink/services/notification_service.dart';
import 'package:LearnLink/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _jobsMatched = 0;
  int _coursesInProgress = 0;
  bool _isLoadingStats = true;
  late AnimationController _greetingController;
  late AnimationController _cardsController;
  late Animation<double> _greetingAnimation;
  late Animation<Offset> _cardsAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _greetingController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _greetingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _greetingController, curve: Curves.easeOut),
    );
    _cardsAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardsController, curve: Curves.easeOut));

    _greetingController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardsController.forward();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          if (!mounted) return;
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });

          // Load additional stats after user data is loaded
          _loadDashboardStats();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingStats = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isLoadingStats = false);
        return;
      }

      // Fetch all dashboard data in parallel for better performance
      final results = await Future.wait([
        _apiService.getPersonalizedJobs(user.uid, limit: 20),
        _apiService.getPersonalizedLearning(user.uid, maxResults: 15),
      ]);

      final jobsData = results[0] as Map<String, dynamic>;
      final learningData = results[1] as Map<String, dynamic>;

      // Extract data
      final jobs = jobsData['recommendations'] as List? ?? [];
      final stats =
          jobsData['recommendation_stats'] as Map<String, dynamic>? ?? {};
      final videos = learningData['videos'] as List? ?? [];

      if (!mounted) return;
      setState(() {
        _jobsMatched = stats['total_matches'] ?? jobs.length;
        _coursesInProgress = videos.length;
        _isLoadingStats = false;
      });

      print(
          '✅ Dashboard stats loaded: $_jobsMatched jobs, $_coursesInProgress videos');
    } catch (e) {
      print('❌ Error loading dashboard stats: $e');
      if (!mounted) return;
      setState(() {
        _jobsMatched = 0;
        _coursesInProgress = 0;
        _isLoadingStats = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny;
    if (hour < 17) return Icons.wb_sunny_outlined;
    return Icons.nightlight_round;
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        )
            : RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await _loadUserData();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Hero Header Section
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _greetingAnimation,
                  child: _buildHeroHeader(),
                ),
              ),

              // Quick Stats Section
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _cardsAnimation,
                  child: FadeTransition(
                    opacity: _greetingAnimation,
                    child: _buildQuickStats(),
                  ),
                ),
              ),

              // Explore Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.explore,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Access Cards
              SliverPadding(
                padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SlideTransition(
                      position: _cardsAnimation,
                      child: FadeTransition(
                        opacity: _greetingAnimation,
                        child: Column(
                          children: [
                            _buildQuickAccessCard(
                              'Find Jobs',
                              'Discover opportunities tailored for you',
                              Icons.work_rounded,
                              AppColors.primary,
                                  () => Navigator.pushNamed(
                                  context, '/jobs'),
                            ),
                            SizedBox(height: AppSpacing.md),
                            _buildQuickAccessCard(
                              'Industry News',
                              'Stay updated with latest trends',
                              Icons.article_rounded,
                              AppColors.accent,
                                  () => Navigator.pushNamed(
                                  context, '/news'),
                            ),
                            SizedBox(height: AppSpacing.md),
                            _buildQuickAccessCard(
                              'Learn & Grow',
                              'Watch curated educational content',
                              Icons.school_rounded,
                              AppColors.secondary,
                                  () => Navigator.pushNamed(
                                  context, '/learning'),
                            ),
                            SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // Skills Section
              SliverToBoxAdapter(
                child: _buildSkillsSection(),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final userName = _userData?['name'] ?? 'User';
    final userField = _userData?['field'] ?? 'Career Development';

    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getGreetingIcon(),
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              StreamBuilder<int>(
                stream: _notificationService.getUnreadCountStream(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                            BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            userName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  userField,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final skills = _userData?['skills'] as List<dynamic>? ?? [];
    final skillCount = skills.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '$skillCount',
              'Skills',
              Icons.verified_rounded,
              AppColors.success,
              isLoading: false,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              '$_jobsMatched',
              'Jobs Matched',
              Icons.work_rounded,
              AppColors.primary,
              isLoading: _isLoadingStats,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              '$_coursesInProgress',
              'Learning',
              Icons.school_rounded,
              AppColors.accent,
              isLoading: _isLoadingStats,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color,
      {bool isLoading = false}) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          isLoading
              ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
              : Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = _userData?['skills'] as List<dynamic>? ?? [];

    if (skills.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Your Skills',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Navigate to edit skills
                },
                icon: Icon(Icons.edit, size: 16),
                label: Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: skills.map((skill) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      skill.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}