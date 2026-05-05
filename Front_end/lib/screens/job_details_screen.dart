import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

const List<List<Color>> _kSkillPalette = [
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFF0891B2), Color(0xFF06B6D4)],
  [Color(0xFF7C3AED), Color(0xFFA855F7)],
  [Color(0xFF0F766E), Color(0xFF14B8A6)],
  [Color(0xFFB45309), Color(0xFFF59E0B)],
  [Color(0xFFBE123C), Color(0xFFF43F5E)],
  [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
  [Color(0xFF065F46), Color(0xFF10B981)],
];

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  // ── unchanged logic ──────────────────────────────────────────────────────
  void _openJobUrl(BuildContext context) async {
    final url = job['apply_url'] ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Application link not available'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Could not open application link'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _scoreColor(double s) {
    if (s >= 70) return AppColors.success;
    if (s >= 50) return AppColors.warning;
    if (s >= 30) return AppColors.accent;
    return AppColors.textTertiary;
  }

  List<Color> _scoreGradient(double s) {
    if (s >= 70) return [AppColors.success, const Color(0xFF059669)];
    if (s >= 50) return [AppColors.warning, const Color(0xFFD97706)];
    return [AppColors.accent, const Color(0xFF0891B2)];
  }

  String _formatDate(String? d) {
    if (d == null) return 'Recently';
    try {
      final diff = DateTime.now().difference(DateTime.parse(d));
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      return '${(diff.inDays / 30).floor()} months ago';
    } catch (_) {
      return 'Recently';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final matchScore = (job['match_score'] ?? 0.0) as num;
    final matchLevel = job['match_level'] ?? '';
    final matchedSkills = job['matched_skills'] as List<dynamic>? ?? [];
    final allSkills = job['required_skills'] as List<dynamic>? ?? [];
    final summary = job['summary']?.toString() ?? '';
    final company = job['company'] ?? 'Company';
    final initial =
    company.isNotEmpty ? company[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible hero ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bookmark_border_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeroBanner(
                company: company,
                initial: initial,
                title: job['title'] ?? 'Job Title',
                location: job['location'] ?? 'Remote',
                postedDate: _formatDate(job['posted_date']),
                jobType: job['employment_type'] ?? '',
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match score card
                  if (matchScore > 0) ...[
                    _MatchCard(
                      score: matchScore.toDouble(),
                      level: matchLevel,
                      matchedCount: matchedSkills.length,
                      totalCount: allSkills.isNotEmpty
                          ? allSkills.length
                          : matchedSkills.length,
                      gradient: _scoreGradient(matchScore.toDouble()),
                      scoreColor:
                      _scoreColor(matchScore.toDouble()),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Info cards row
                  _InfoRow(
                    location: job['location'] ?? 'Remote',
                    posted: _formatDate(job['posted_date']),
                    jobType: job['employment_type'] ?? 'Full-time',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Matched skills
                  if (matchedSkills.isNotEmpty) ...[
                    _SkillsSection(
                      title: 'Your matching skills',
                      icon: Icons.verified_rounded,
                      iconColor: AppColors.success,
                      skills: matchedSkills,
                      isMatched: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // All required skills
                  if (allSkills.isNotEmpty) ...[
                    _SkillsSection(
                      title: 'All required skills',
                      icon: Icons.checklist_rounded,
                      iconColor: AppColors.primary,
                      skills: allSkills,
                      isMatched: false,
                      matchedSkills: matchedSkills,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // About role
                  if (summary.isNotEmpty) ...[
                    _AboutSection(summary: summary),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Additional info
                  _AdditionalInfo(
                    company: company,
                    location: job['location'] ?? 'N/A',
                    posted: _formatDate(job['posted_date']),
                  ),

                  // Bottom padding for sticky bar
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky bottom apply bar ───────────────────────────────────────
      bottomNavigationBar: _ApplyBar(
          onApply: () => _openJobUrl(context)),
    );
  }
}

// ── Hero banner ────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final String company, initial, title, location, postedDate, jobType;
  const _HeroBanner({
    required this.company,
    required this.initial,
    required this.title,
    required this.location,
    required this.postedDate,
    required this.jobType,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4F46E5),
                Color(0xFF7C3AED),
                Color(0xFF06B6D4),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Decorative rings
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 26,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -20,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
                width: 22,
              ),
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 52, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(AppBorderRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Job title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                // Company name
                Text(
                  company,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Meta pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HeroPill(
                        icon: Icons.location_on_rounded,
                        label: location),
                    _HeroPill(
                        icon: Icons.schedule_rounded,
                        label: postedDate),
                    if (jobType.isNotEmpty)
                      _HeroPill(
                          icon: Icons.work_outline_rounded,
                          label: jobType),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Match card ─────────────────────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final double score;
  final String level;
  final int matchedCount, totalCount;
  final List<Color> gradient;
  final Color scoreColor;
  const _MatchCard({
    required this.score,
    required this.level,
    required this.matchedCount,
    required this.totalCount,
    required this.gradient,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius:
              BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          // Score + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${score.toInt()}% Match',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  level.isNotEmpty
                      ? '$level · $matchedCount of $totalCount skills'
                      : '$matchedCount of $totalCount skills matched',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Ring indicator
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 4,
                  backgroundColor:
                  Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String location, posted, jobType;
  const _InfoRow(
      {required this.location,
        required this.posted,
        required this.jobType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: location,
              color: AppColors.accent),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _InfoCard(
              icon: Icons.schedule_rounded,
              label: 'Posted',
              value: posted,
              color: AppColors.warning),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _InfoCard(
              icon: Icons.work_outline_rounded,
              label: 'Type',
              value: jobType.isNotEmpty ? jobType : 'Full-time',
              color: AppColors.primary),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoCard(
      {required this.icon,
        required this.label,
        required this.value,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
              BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textTertiary)),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skills section ─────────────────────────────────────────────────────────
class _SkillsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<dynamic> skills;
  final bool isMatched;
  final List<dynamic> matchedSkills;

  const _SkillsSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.skills,
    required this.isMatched,
    this.matchedSkills = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: Text(
                  '${skills.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(skills.length, (i) {
              final skill = skills[i].toString();
              // For required skills, check if it's matched
              final isHit = isMatched ||
                  matchedSkills
                      .map((s) => s.toString().toLowerCase())
                      .contains(skill.toLowerCase());
              if (isHit) {
                final palette =
                _kSkillPalette[i % _kSkillPalette.length];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: palette),
                    borderRadius:
                    BorderRadius.circular(AppBorderRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: palette[0].withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(skill,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                );
              }
              // Unmatched skill chip
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(skill,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── About section ──────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  final String summary;
  const _AboutSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: const Icon(Icons.description_rounded,
                    size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'About this role',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Left accent bar
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Additional info ────────────────────────────────────────────────────────
class _AdditionalInfo extends StatelessWidget {
  final String company, location, posted;
  const _AdditionalInfo(
      {required this.company,
        required this.location,
        required this.posted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Quick info',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow2(
              icon: Icons.business_rounded,
              label: 'Company',
              value: company),
          const SizedBox(height: AppSpacing.sm),
          const Divider(
              height: 1,
              color: AppColors.divider),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow2(
              icon: Icons.location_city_rounded,
              label: 'Location',
              value: location),
          const SizedBox(height: AppSpacing.sm),
          const Divider(
              height: 1,
              color: AppColors.divider),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow2(
              icon: Icons.calendar_today_rounded,
              label: 'Posted',
              value: posted),
        ],
      ),
    );
  }
}

class _InfoRow2 extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow2(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Sticky apply bar ───────────────────────────────────────────────────────
class _ApplyBar extends StatelessWidget {
  final VoidCallback onApply;
  const _ApplyBar({required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
        const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Save / bookmark icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              color: AppColors.surface,
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          // Apply button
          Expanded(
            child: GestureDetector(
              onTap: onApply,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}