import 'package:LearnLink/screens/job_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:LearnLink/services/cached_data_service.dart';
import 'package:LearnLink/utils/constants.dart';


const List<List<Color>> _kSkillPalette = [
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFF0891B2), Color(0xFF06B6D4)],
  [Color(0xFF7C3AED), Color(0xFFA855F7)],
  [Color(0xFF0F766E), Color(0xFF14B8A6)],
  [Color(0xFFB45309), Color(0xFFF59E0B)],
  [Color(0xFFBE123C), Color(0xFFF43F5E)],
  [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
];

class JobsScreen extends StatefulWidget {
  const JobsScreen({Key? key}) : super(key: key);

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with TickerProviderStateMixin {
  /// ── CHANGED: using CachedDataService instead of ApiService ──
  final CachedDataService _cachedDataService = CachedDataService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _jobs = [];
  bool _isLoading = false;
  Map<String, dynamic>? _stats;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadPersonalizedJobs();
  }

  /// ── CHANGED: reads from Firestore cached_jobs ──
  Future<void> _loadPersonalizedJobs() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final result = await _cachedDataService.getPersonalizedJobs(
          userId: user.uid,
          limit: 20,
        );
        setState(() {
          _jobs = result['recommendations'] ?? [];
          _stats = result['recommendation_stats'];
          _isLoading = false;
        });
        _listController.forward(from: 0);
        if (_stats != null && mounted) {
          final excellentMatches = _stats!['excellent_matches'] ?? 0;
          if (excellentMatches > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                Text('🎯 Found $excellentMatches excellent matches!'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error loading jobs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load recommendations')),
      );
      setState(() => _isLoading = false);
    }
  }

  /// ── CHANGED: searches cached_jobs in Firestore ──
  Future<void> _searchJobs() async {
    if (_searchController.text.isEmpty) {
      await _loadPersonalizedJobs();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final jobs = await _cachedDataService.searchJobs(
        _searchController.text,
        limit: 20,
      );
      setState(() {
        _jobs = jobs;
        _stats = null;
        _isLoading = false;
      });
      _listController.forward(from: 0);
    } catch (e) {
      print('Error searching jobs: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openJobDetails(Map<String, dynamic> job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  UI — everything below is UNCHANGED from original
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : _jobs.isEmpty
                  ? _buildEmptyState()
                  : _buildJobsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final excellent = _stats?['excellent_matches'] ?? 0;
    final good = _stats?['good_matches'] ?? 0;
    final potential = _stats?['potential_matches'] ?? 0;
    final hasStats = _stats != null && !_isLoading;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: const Icon(Icons.work_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find Jobs',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5)),
                    Text('Matched to your skills',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (_jobs.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text('${_jobs.length} results',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
            ],
          ),
          if (hasStats) ...[
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              _MatchStat(
                  count: excellent, label: 'Excellent', color: AppColors.success),
              const SizedBox(width: 6),
              _MatchStat(
                  count: good, label: 'Good match', color: AppColors.warning),
              const SizedBox(width: 6),
              _MatchStat(
                  count: potential, label: 'Potential', color: AppColors.primary),
            ]),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              style:
              const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "Let's find you a job…",
                hintStyle: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _loadPersonalizedJobs();
                  },
                )
                    : GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        AppColors.primary,
                        AppColors.secondary
                      ]),
                      borderRadius:
                      BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onSubmitted: (_) => _searchJobs(),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPersonalizedJobs,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        itemCount: _jobs.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent]))),
                const SizedBox(width: 7),
                const Text('Top matches',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3)),
                const Spacer(),
                Text('${_jobs.length} jobs',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ]),
            );
          }
          final job = _jobs[index - 1];
          final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _listController,
              curve: Interval(((index - 1) * 0.05).clamp(0.0, 1.0), 1.0,
                  curve: Curves.easeOutCubic),
            ),
          );
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, 0.1), end: Offset.zero)
                  .animate(anim),
              child: _JobCard(
                  job: job as Map<String, dynamic>,
                  index: index - 1,
                  onTap: () => _openJobDetails(job)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (_, i) => _JobSkeleton(index: i),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.1),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.work_off_rounded,
                  size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('No jobs found',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
                'Try updating your profile with\nmore skills to get better matches.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _loadPersonalizedJobs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Retry',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Match stat box ────────────────────────────────────────────────────────
class _MatchStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _MatchStat(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8))),
        ]),
      ),
    );
  }
}

// ── Job card ──────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final int index;
  final VoidCallback onTap;
  const _JobCard(
      {required this.job, required this.index, required this.onTap});

  Color _scoreColor(double s) {
    if (s >= 70) return AppColors.success;
    if (s >= 50) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _formatDate(String? d) {
    if (d == null) return 'Recently';
    try {
      final diff = DateTime.now().difference(DateTime.parse(d));
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      return '${(diff.inDays / 30).floor()}mo ago';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = job['title'] ?? 'Job Title';
    final company = job['company'] ?? 'Company';
    final location = job['location'] ?? 'Remote';
    final postedDate = job['posted_date'] as String?;
    final matchScore = (job['match_score'] ?? 0.0) as num;
    final matchLevel = job['match_level'] ?? '';
    final matchedSkills = job['matched_skills'] as List<dynamic>? ?? [];
    final jobType = job['employment_type'] ?? '';
    final scoreColor = _scoreColor(matchScore.toDouble());
    final isFeatured = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: isFeatured
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isFeatured ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (matchScore > 0)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppBorderRadius.lg)),
                  child: Stack(children: [
                    Container(height: 3, color: AppColors.border),
                    FractionallySizedBox(
                      widthFactor:
                      (matchScore / 100).clamp(0.0, 1.0).toDouble(),
                      child: Container(height: 3, color: scoreColor),
                    ),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius:
                            BorderRadius.circular(AppBorderRadius.md),
                            border: Border.all(
                                color:
                                AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Center(
                            child: Text(
                              company.isNotEmpty
                                  ? company[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: isFeatured ? 15 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      height: 1.25,
                                      letterSpacing: -0.2)),
                              const SizedBox(height: 3),
                              Text(company,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        if (matchScore > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: scoreColor,
                              borderRadius:
                              BorderRadius.circular(AppBorderRadius.xl),
                              boxShadow: [
                                BoxShadow(
                                    color: scoreColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Text('${matchScore.toInt()}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _MetaChip(
                          icon: Icons.location_on_rounded,
                          label: location,
                          color: AppColors.textSecondary),
                      if (jobType.isNotEmpty)
                        _MetaChip(
                            icon: Icons.access_time_rounded,
                            label: jobType,
                            color: AppColors.primary,
                            tinted: true),
                      if (matchLevel.isNotEmpty)
                        _MetaChip(
                            icon: Icons.trending_up_rounded,
                            label: matchLevel,
                            color: scoreColor,
                            tinted: true),
                    ]),
                    if (matchedSkills.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm + 2),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: List.generate(
                          matchedSkills.take(4).length,
                              (i) {
                            final palette =
                            _kSkillPalette[i % _kSkillPalette.length];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: palette),
                                borderRadius:
                                BorderRadius.circular(AppBorderRadius.xl),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white
                                              .withValues(alpha: 0.6))),
                                  const SizedBox(width: 4),
                                  Text(matchedSkills[i].toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Container(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.sm),
                    Row(children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(_formatDate(postedDate),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textTertiary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.primary,
                            AppColors.secondary
                          ]),
                          borderRadius:
                          BorderRadius.circular(AppBorderRadius.xl),
                          boxShadow: [
                            BoxShadow(
                                color:
                                AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View Details',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 11, color: Colors.white),
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Meta chip ─────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool tinted;
  const _MetaChip(
      {required this.icon,
        required this.label,
        required this.color,
        this.tinted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tinted
            ? color.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: tinted ? Border.all(color: color.withValues(alpha: 0.2)) : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 12, color: tinted ? color : AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: tinted ? FontWeight.w600 : FontWeight.w500,
                color: tinted ? color : AppColors.textSecondary)),
      ]),
    );
  }
}

// ── Skeleton card ─────────────────────────────────────────────────────────
class _JobSkeleton extends StatefulWidget {
  final int index;
  const _JobSkeleton({required this.index});
  @override
  State<_JobSkeleton> createState() => _JobSkeletonState();
}

class _JobSkeletonState extends State<_JobSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        final alpha = 0.05 + _a.value * 0.08;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _sh(44, 44, alpha, radius: AppBorderRadius.md),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sh(12, double.infinity, alpha),
                          const SizedBox(height: 6),
                          _sh(12, 140, alpha),
                        ])),
                const SizedBox(width: AppSpacing.md),
                _sh(28, 52, alpha, radius: 14),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                _sh(28, 100, alpha),
                const SizedBox(width: 6),
                _sh(28, 80, alpha),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                _sh(24, 70, alpha, radius: 12),
                const SizedBox(width: 5),
                _sh(24, 60, alpha, radius: 12),
                const SizedBox(width: 5),
                _sh(24, 80, alpha, radius: 12),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sh(12, 80, alpha),
                    _sh(30, 100, alpha, radius: 15),
                  ]),
            ],
          ),
        );
      },
    );
  }

  Widget _sh(double h, double w, double alpha, {double radius = 6}) =>
      Container(
        width: w == double.infinity ? null : w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}