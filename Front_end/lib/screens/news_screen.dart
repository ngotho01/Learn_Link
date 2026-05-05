import 'package:LearnLink/services/api_service.dart';
import 'package:LearnLink/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<dynamic> _articles = [];
  bool _isLoading = false;
  String? _userField;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadUserFieldAndNews();
  }

  Future<void> _loadUserFieldAndNews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!mounted) return;
        if (doc.exists) _userField = doc.data()?['field'];
      }
      await _loadNews();
    } catch (e) {
      print('Error loading user field and news: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNews() async {
    try {
      final articles = await _apiService.getIndustryNews(
        field: _userField ?? 'technology',
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
      _listController.forward(from: 0);
    } catch (e) {
      print('Error loading news: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load news. Please try again.')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _openArticle(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening URL: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open article')),
      );
    }
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

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
                  ? _buildLoadingSkeleton()
                  : _articles.isEmpty
                  ? _buildEmptyState()
                  : _buildNewsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(Icons.newspaper_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Industry News',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trending in ${_userField ?? 'your industry'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_articles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(AppBorderRadius.xl),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${_articles.length} articles',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (_, i) => _SkeletonCard(delay: i * 120),
    );
  }

  Widget _buildNewsList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _listController,
              curve: Interval(
                (index * 0.05).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            ),
          );
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(anim),
              child: _buildNewsCard(article, index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article, int index) {
    final articleUrl = article['url'] ?? '';
    final thumbnail = article['thumbnail'] ?? '';
    final section = article['section'] ?? '';
    final title = article['title'] ?? 'Article Title';
    final summary = article['summary'] ?? '';
    final publishedDate = article['published_date'] ?? '';

    final bool isFeatured = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isFeatured ? 0.08 : 0.04),
            blurRadius: isFeatured ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          onTap: () => _openArticle(articleUrl),
          splashColor: AppColors.primary.withValues(alpha: 0.05),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thumbnail.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppBorderRadius.lg)),
                  child: Stack(
                    children: [
                      Image.network(
                        thumbnail,
                        width: double.infinity,
                        height: isFeatured ? 200 : 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildThumbnailPlaceholder(isFeatured),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isFeatured)
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary
                                ],
                              ),
                              borderRadius:
                              BorderRadius.circular(AppBorderRadius.xl),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded,
                                    size: 11, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'TOP STORY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                _buildThumbnailPlaceholder(isFeatured),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (section.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                              AppColors.accent.withValues(alpha: 0.1),
                              borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                            ),
                            child: Text(
                              section.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 11, color: AppColors.textTertiary),
                            const SizedBox(width: 3),
                            Text(
                              _formatDate(publishedDate),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isFeatured ? 18 : 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                      maxLines: isFeatured ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      height: 1,
                      color: AppColors.divider,
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Live article',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(
                                AppBorderRadius.xl),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Read More',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 11, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(bool isFeatured) {
    return Container(
      height: isFeatured ? 200 : 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.lg)),
      ),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.accent.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.newspaper_outlined,
                size: 44,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No articles yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Check back soon for the latest\nnews in your field.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _loadNews,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius:
                  BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Recently';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }
}

class _SkeletonCard extends StatefulWidget {
  final int delay;
  const _SkeletonCard({required this.delay});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final alpha = (0.04 + _anim.value * 0.07);
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: alpha),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppBorderRadius.lg)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerLine(60, alpha),
                    const SizedBox(height: AppSpacing.sm),
                    _shimmerLine(double.infinity, alpha),
                    const SizedBox(height: 6),
                    _shimmerLine(double.infinity, alpha),
                    const SizedBox(height: 6),
                    _shimmerLine(200, alpha),
                    const SizedBox(height: AppSpacing.md),
                    _shimmerLine(100, alpha),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerLine(double width, double alpha) => Container(
    width: width,
    height: 12,
    decoration: BoxDecoration(
      color: AppColors.textTertiary.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}