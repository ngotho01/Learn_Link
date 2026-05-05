import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_button.dart';
import '../widgets/input_field.dart';
import '../utils/constants.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;
  bool _isLoading = false;

  late AnimationController _slideController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call for password reset
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
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
              const SizedBox(height: AppSpacing.xl),

              // Header
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOut,
                )),
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Iconsax.key,
                          color: AppColors.warning,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        _emailSent ? 'Check your email' : 'Forgot Password?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        _emailSent
                            ? 'We\'ve sent a password reset link to ${_emailController.text}'
                            : 'No worries! Enter your email address and we\'ll send you a reset link.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              if (!_emailSent) ...[
                // Email Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      InputField(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        isRequired: true,
                        prefixIcon: const Icon(
                          Iconsax.sms,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      CustomButton(
                        text: 'Send Reset Link',
                        onPressed: _handleResetPassword,
                        isLoading: _isLoading,
                        icon: Iconsax.send_1,
                      ),
                    ],
                  ),
                ).animate().slideY(
                  begin: 0.2,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ).fadeIn(delay: 200.ms),
              ] else ...[
                // Success Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Iconsax.tick_circle,
                        color: AppColors.success,
                        size: 48,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Reset link sent!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Please check your email and follow the instructions to reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ).fadeIn(delay: 200.ms),

                const SizedBox(height: AppSpacing.xl),

                CustomButton(
                  text: 'Back to Login',
                  onPressed: () => Navigator.of(context).pop(),
                  isOutlined: true,
                  icon: Iconsax.arrow_left,
                ).animate().slideY(
                  begin: 0.2,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ).fadeIn(delay: 400.ms),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Help Text
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Didn\'t receive the email?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _emailSent
                          ? () {
                        setState(() {
                          _emailSent = false;
                          _emailController.clear();
                        });
                      }
                          : null,
                      child: Text(
                        _emailSent ? 'Try again' : 'Check your spam folder',
                        style: TextStyle(
                          color: _emailSent ? AppColors.primary : AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}