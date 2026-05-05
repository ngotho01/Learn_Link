import 'package:LearnLink/screens/main_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_services.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';

class SkillsCoursePage extends StatefulWidget {
  final String name;
  final XFile? profileImage;

  const SkillsCoursePage({
    super.key,
    required this.name,
    this.profileImage,
  });

  @override
  State<SkillsCoursePage> createState() => _SkillsCoursePageState();
}

class _SkillsCoursePageState extends State<SkillsCoursePage>
    with TickerProviderStateMixin {
  String? _selectedField;
  final Set<String> _selectedSkills = <String>{};

  late AnimationController _progressController;
  late AnimationController _slideController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController.animateTo(0.66); // Step 3 of 3
    _slideController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<String> _getSkillsForField(String field) {
    switch (field) {
      case 'Technology':
        return AppConstants.technologySkills;
      case 'Business':
        return AppConstants.businessSkills;
      case 'Film & Media':
        return AppConstants.filmMediaSkills;
      case 'Healthcare':
        return AppConstants.healthcareSkills;
      case 'Engineering':
        return AppConstants.engineeringSkills;
      case 'Design':
        return AppConstants.designSkills;
      case 'Marketing':
        return AppConstants.marketingSkills;
      case 'Finance':
        return AppConstants.financeSkills;
      case 'Education':
        return AppConstants.educationSkills;
      case 'Arts':
        return AppConstants.artsSkills;
      default:
        return [...AppConstants.technologySkills, ...AppConstants.businessSkills]
            .take(15)
            .toList();
    }
  }

  Future<void> _completeRegistration() async {
    if (_selectedField == null || _selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a field and at least one skill'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.completeProfile(
      name: widget.name,
      field: _selectedField!,
      skills: _selectedSkills.toList(),
      profilePictureUrl: widget.profileImage?.path,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Complete progress animation
      await _progressController.animateTo(1.0);

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const MainHomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                )),
                child: child,
              ),
            );
          },
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOut,
                )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 3 of 3',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressController.value,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 6,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Header
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOut,
                )),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your interests',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Select your field of study and skills to get personalized recommendations.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Field Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Field of Interest',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: AppConstants.courseFields.map((field) {
                      final isSelected = _selectedField == field;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedField = field;
                            _selectedSkills.clear(); // Reset skills when field changes
                          });
                        },
                        child: AnimatedContainer(
                          duration: AppAnimations.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                                : null,
                          ),
                          child: Text(
                            field,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ).animate().slideY(
                begin: 0.2,
                duration: 600.ms,
                curve: Curves.easeOut,
              ).fadeIn(delay: 200.ms),

              const SizedBox(height: AppSpacing.xl),

              // Skills Selection
              if (_selectedField != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Skills',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Text(
                            '${_selectedSkills.length} selected',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Select at least 3 skills you have or want to learn',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _getSkillsForField(_selectedField!).map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedSkills.remove(skill);
                              } else {
                                _selectedSkills.add(skill);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: AppAnimations.fast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.1)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(
                                    Iconsax.tick_circle,
                                    color: AppColors.accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                Text(
                                  skill,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ).animate().slideY(
                  begin: 0.2,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ).fadeIn(delay: 400.ms),

                const SizedBox(height: AppSpacing.xxl),

                // Complete Button
                CustomButton(
                  text: 'Complete Setup',
                  onPressed: _completeRegistration,
                  isLoading: _isLoading,
                  icon: Iconsax.tick_circle,
                ).animate().slideY(
                  begin: 0.2,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ).fadeIn(delay: 600.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
