import 'package:edunest_app/core/theme/app_colors.dart';
import 'package:edunest_app/core/theme/app_text_styles.dart';
import 'package:edunest_app/core/widgets/custom_rounded_button.dart';
import 'package:edunest_app/core/widgets/gradient_background.dart';
import 'package:edunest_app/core/widgets/rounded_card.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _emailSent = false;

  Future<void> _sendResetLink() async {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().sendPasswordResetEmail(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _emailSent = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back to login',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: GradientBackground(
        showFloatingOrbs: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: RoundedCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _emailSent
                                ? Icons.mark_email_read_rounded
                                : Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _emailSent ? 'Check your email' : 'Reset password',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _emailSent
                              ? 'If an account exists for ${_emailController.text.trim()}, a password reset link has been sent. Follow the link in your inbox to choose a new password.'
                              : 'Enter the email address associated with your EduNest account. We will send you a secure password reset link.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                        if (!_emailSent) ...[
                          const SizedBox(height: 26),
                          TextFormField(
                            controller: _emailController,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _sendResetLink(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Enter your email address.';
                              }
                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(email)) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: isDark ? AppColors.darkSurface : AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkDivider : AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkDivider : AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomRoundedButton(
                            text: 'Send reset link',
                            onPressed: _loading ? null : _sendResetLink,
                            isLoading: _loading,
                            height: 52,
                            borderRadius: 26,
                          ),
                        ] else ...[
                          const SizedBox(height: 26),
                          CustomRoundedButton(
                            text: 'Return to login',
                            onPressed: () => Navigator.of(context).maybePop(),
                            height: 52,
                            borderRadius: 26,
                          ),
                        ],
                        if (!_emailSent) ...[
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: Text(
                              'Return to login',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
