import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

// Accent colors for this screen — keeps AppColors clean
const _kRed1 = Color(0xFFFF6584);
const _kRed2 = Color(0xFFFF4568);

class LearningScreen extends StatefulWidget {
  const LearningScreen({Key? key}) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _videos = [];
  bool _isLoading = false;
  late AnimationController _listController;

  final List<String> _tabs = ['All', 'Recommended', 'Enhance Skills', 'Trending'];
  int _selectedTab = 0;

  // ── Local filter — no API calls ─────────────────────────────────────────
  List<dynamic> get _filtered {
    if (_selectedTab == 0) return _videos;
    if (_selectedTab == 1) return _videos.where((v) => _score(v) >= 70).toList();
    if (_selectedTab == 2) return _videos.where((v) => _reason(v).isNotEmpty).toList();
    final s = List.from(_videos)
      ..sort((a, b) => _score(b).compareTo(_score(a)));
    return s.take(10).toList();
  }

  // ── Group by recommended_for skill ─────────────────────────────────────
  Map<String, List<dynamic>> get _skillSections {
    final map = <String, List<dynamic>>{};
    for (final v in _filtered.skip(1)) {
      final key = _reason(v);
      if (key.isNotEmpty) (map[key] ??= []).add(v);
    }
    return map;
  }

  // ── Videos that have no recommended_for grouping ───────────────────────
  List<dynamic> get _ungrouped {
    final grouped = _skillSections.values.expand((e) => e).toSet();
    return _filtered.skip(1).where((v) => !grouped.contains(v)).toList();
  }

  num _score(dynamic v) => (v['relevance_score'] ?? 0.0) as num;
  String _reason(dynamic v) => (v['recommended_for'] ?? '') as String;

  // ── unchanged logic ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadPersonalizedVideos();
  }

  Future<void> _loadPersonalizedVideos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final result = await _apiService.getPersonalizedLearning(user.uid, maxResults: 20);
        if (!mounted) return;
        setState(() {
          _videos = result['recommendations'] ?? [];
          _isLoading = false;
        });
        _listController.forward(from: 0);
      }
    } catch (e) {
      print('❌ Error loading videos: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load recommendations')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchVideos() async {
    if (_searchController.text.isEmpty) {
      await _loadPersonalizedVideos();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final videos = await _apiService.searchYouTubeVideos(
        query: _searchController.text,
        maxResults: 20,
      );
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
      _listController.forward(from: 0);
    } catch (e) {
      print('❌ Error searching videos: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openVideo(Map<String, dynamic> video) async {
    final videoId = video['video_id'] as String?;
    if (videoId == null || videoId.isEmpty) {
      print('❌ No video ID found in: $video');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open video - ID not found')),
        );
      }
      return;
    }
    final url = 'https://www.youtube.com/watch?v=$videoId';
    print('🎥 Opening: $url');
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('❌ Error opening video: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  // ── Root build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : _filtered.isEmpty
                  ? _buildEmpty()
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final total = _videos.length;
    final highMatch = _videos.where((v) => _score(v) >= 70).length;
    final skills = _videos
        .map((v) => _reason(v))
        .where((r) => r.isNotEmpty)
        .toSet()
        .length;

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
                    colors: [_kRed1, _kRed2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learn & Grow',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Curated for your career path',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kRed1, _kRed2]),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text('AI Picks',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          if (!_isLoading && total > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StatBox(value: '$total', label: 'Videos', color: _kRed1),
                const SizedBox(width: 8),
                _StatBox(
                    value: '$highMatch',
                    label: 'High match',
                    color: AppColors.success),
                const SizedBox(width: 8),
                _StatBox(
                    value: '$skills',
                    label: 'Skills covered',
                    color: AppColors.primary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search topics, skills, courses…',
            hintStyle: const TextStyle(
                color: AppColors.textTertiary, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: _kRed1, size: 20),
            suffixIcon: GestureDetector(
              onTap: _searchVideos,
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kRed1, _kRed2]),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.md),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
          ),
          onSubmitted: (_) => _searchVideos(),
        ),
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final sel = _selectedTab == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(
                      colors: [_kRed1, _kRed2])
                      : null,
                  color: sel ? null : AppColors.surfaceVariant,
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.xl),
                  border: Border.all(
                      color: sel
                          ? Colors.transparent
                          : AppColors.border),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Body — sections ─────────────────────────────────────────────────────
  Widget _buildBody() {
    final list = _filtered;
    final sections = _skillSections;
    final ungrouped = _ungrouped;

    return RefreshIndicator(
      color: _kRed1,
      onRefresh: _loadPersonalizedVideos,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          // ── Hero card (first video) ──────────────────────────────────
          if (list.isNotEmpty) ...[
            _SectionHeader(
              title: 'Top pick for you',
              subtitle: _reason(list.first).isNotEmpty
                  ? 'Because you know ${_reason(list.first)}'
                  : 'Your highest match',
              onTap: null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: _HeroCard(
                  video: list.first as Map<String, dynamic>,
                  onTap: () => _openVideo(
                      list.first as Map<String, dynamic>)),
            ),
          ],

          // ── Skill sections (horizontal scroll rows) ──────────────────
          ...sections.entries.map((e) {
            final skill = e.key;
            final vids = e.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: 'Level up $skill',
                  subtitle: 'Boost your existing skill',
                  onTap: null,
                ),
                SizedBox(
                  height: 188,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    itemCount: vids.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(
                          right: AppSpacing.sm + 2),
                      child: _MiniCard(
                        video: vids[i] as Map<String, dynamic>,
                        onTap: () => _openVideo(
                            vids[i] as Map<String, dynamic>),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          // ── Ungrouped: "Add to your toolkit" 2-col grid ──────────────
          if (ungrouped.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: 'Add to your toolkit',
              subtitle: 'New skills near your field',
              onTap: null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm + 2,
                  mainAxisSpacing: AppSpacing.sm + 2,
                  childAspectRatio: 0.78,
                ),
                itemCount: ungrouped.length,
                itemBuilder: (_, i) => _GridCard(
                  video: ungrouped[i] as Map<String, dynamic>,
                  onTap: () => _openVideo(
                      ungrouped[i] as Map<String, dynamic>),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Skeleton ────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _shimmerBox(height: 240),
        const SizedBox(height: AppSpacing.md),
        _shimmerBox(height: 20, width: 160),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _shimmerBox(height: 180)),
            const SizedBox(width: 10),
            Expanded(child: _shimmerBox(height: 180)),
          ],
        ),
      ],
    );
  }

  Widget _shimmerBox({double height = 100, double? width}) =>
      _PulseBox(height: height, width: width);

  // ── Empty ───────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
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
                  _kRed1.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.1),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.video_library_rounded,
                  size: 40,
                  color: _kRed1.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('No videos yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Add more skills to your profile and\nwe\'ll match learning content for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _loadPersonalizedVideos,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kRed1, _kRed2]),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Refresh',
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

// ── Section header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _SectionHeader(
      {required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  )),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary)),
            ],
          ),
          const Spacer(),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: const Text('See all →',
                  style: TextStyle(
                      fontSize: 12,
                      color: _kRed1,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ── Hero card ──────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onTap;
  const _HeroCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = video['title'] ?? 'Video Title';
    final channel = video['channel'] ?? 'Channel';
    final thumbnail = video['thumbnail'] ?? '';
    final score = (video['relevance_score'] ?? 0.0) as num;
    final reason = video['recommended_for'] ?? '';
    final scoreColor = score >= 85
        ? AppColors.success
        : score >= 65
        ? AppColors.warning
        : AppColors.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: _kRed1.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.lg)),
              child: Stack(
                children: [
                  thumbnail.isNotEmpty
                      ? Image.network(thumbnail,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _Placeholder(height: 200))
                      : _Placeholder(height: 200),
                  // Gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.35, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // TOP PICK
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                            AppBorderRadius.xl),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 11, color: Colors.white),
                          SizedBox(width: 3),
                          Text('TOP PICK',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4)),
                        ],
                      ),
                    ),
                  ),
                  // Score badge
                  if (score > 0)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(
                              AppBorderRadius.xl),
                        ),
                        child: Text('${score.toInt()}% match',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  // Centred play button
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.play_arrow_rounded,
                            color: _kRed2,
                            size: 28),
                      ),
                    ),
                  ),
                  // Channel name
                  Positioned(
                    bottom: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Row(
                      children: [
                        _ChannelAvatar(name: channel, size: 24),
                        const SizedBox(width: 6),
                        Text(channel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                    blurRadius: 4,
                                    color: Colors.black54)
                              ],
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Score bar
            _ScoreBar(score: score.toDouble(),
                color: scoreColor),
            // Body
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (reason.isNotEmpty)
                        _ReasonTag(reason: reason),
                      const Spacer(),
                      _WatchButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini card (horizontal scroll item) ────────────────────────────────────
class _MiniCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onTap;
  const _MiniCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = video['title'] ?? 'Video Title';
    final channel = video['channel'] ?? 'Channel';
    final thumbnail = video['thumbnail'] ?? '';
    final score = (video['relevance_score'] ?? 0.0) as num;
    final scoreColor = score >= 85
        ? AppColors.success
        : score >= 65
        ? AppColors.warning
        : AppColors.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.md)),
              child: Stack(
                children: [
                  thumbnail.isNotEmpty
                      ? Image.network(thumbnail,
                      width: double.infinity,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _Placeholder(height: 84))
                      : _Placeholder(height: 84),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black
                                .withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.play_arrow_rounded,
                            color: _kRed2,
                            size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _ScoreBar(score: score.toDouble(), color: scoreColor),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3)),
                  const SizedBox(height: 4),
                  Text(channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary)),
                  const SizedBox(height: 4),
                  Text('${score.toInt()}% match',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scoreColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid card (add to toolkit section) ────────────────────────────────────
class _GridCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onTap;
  const _GridCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = video['title'] ?? 'Video Title';
    final channel = video['channel'] ?? 'Channel';
    final thumbnail = video['thumbnail'] ?? '';
    final score = (video['relevance_score'] ?? 0.0) as num;
    final reason = video['recommended_for'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.md)),
              child: Stack(
                children: [
                  thumbnail.isNotEmpty
                      ? Image.network(thumbnail,
                      width: double.infinity,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _Placeholder(height: 90))
                      : _Placeholder(height: 90),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: 0.55),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Text('${score.toInt()}%',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.play_arrow_rounded,
                            color: _kRed2,
                            size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3)),
                    const Spacer(),
                    if (reason.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                      )
                    else
                      Text(channel,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary)),
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

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _ScoreBar extends StatelessWidget {
  final double score;
  final Color color;
  const _ScoreBar({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (score / 100).clamp(0.0, 1.0);
    return LayoutBuilder(builder: (_, c) {
      return Stack(
        children: [
          Container(height: 3, color: AppColors.border),
          Container(
              height: 3,
              width: c.maxWidth * pct,
              color: color),
        ],
      );
    });
  }
}

class _ChannelAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _ChannelAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          color: _kRed2, shape: BoxShape.circle),
      child: Center(
        child: Text(initial,
            style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

class _ReasonTag extends StatelessWidget {
  final String reason;
  const _ReasonTag({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kRed1.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: _kRed1.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_rounded, size: 11, color: _kRed1),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text('Helps with: $reason',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    color: _kRed1,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _WatchButton extends StatelessWidget {
  const _WatchButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(colors: [_kRed1, _kRed2]),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: _kRed2.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text('Watch',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double height;
  const _Placeholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kRed1.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.play_circle_rounded,
            size: height * 0.3,
            color: _kRed1.withValues(alpha: 0.35)),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

// ── Pulse skeleton box ─────────────────────────────────────────────────────
class _PulseBox extends StatefulWidget {
  final double height;
  final double? width;
  const _PulseBox({required this.height, this.width});

  @override
  State<_PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<_PulseBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100))
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
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.textTertiary
              .withValues(alpha: 0.05 + _a.value * 0.08),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
    );
  }
}