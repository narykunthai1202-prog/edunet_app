import 'package:edunest_app/core/theme/app_colors.dart';
import 'package:edunest_app/core/theme/app_text_styles.dart';
import 'package:edunest_app/core/widgets/custom_rounded_button.dart';
import 'package:edunest_app/core/widgets/gradient_background.dart';
import 'package:edunest_app/core/widgets/rounded_card.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: GradientBackground(
        showFloatingOrbs: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final pending = state is EmailVerificationPending
                        ? state
                        : null;
                    final email = pending?.email ?? '';

                    return RoundedCard(
                      borderRadius: 28,
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.displayMedium.copyWith(
                              fontSize: 24,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'We sent a verification link to:',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.cardSubtle,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                email,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            'Open the link in your inbox to verify your account. If you do not see it, please check your spam folder.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),
                          if (pending?.message != null) ...[
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : const Color(0xFFFFF4E5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFFB74D),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                pending!.message!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFFFB74D) : const Color(0xFF805400),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          CustomRoundedButton(
                            text: 'I Have Verified My Email',
                            onPressed: () => context
                                .read<AuthCubit>()
                                .checkEmailVerification(),
                            variant: ButtonVariant.primary,
                            height: 52,
                            borderRadius: 26,
                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 12),
                          CustomRoundedButton(
                            text: 'Resend Verification Email',
                            onPressed: () => context
                                .read<AuthCubit>()
                                .resendVerificationEmail(),
                            variant: ButtonVariant.secondary,
                            height: 50,
                            borderRadius: 25,
                            icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () =>
                                context.read<AuthCubit>().logout(),
                            child: Text(
                              'Change Email / Return to Login',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
