import 'package:edunest_app/core/theme/app_colors.dart';
import 'package:edunest_app/core/theme/app_text_styles.dart';
import 'package:edunest_app/core/widgets/custom_rounded_button.dart';
import 'package:edunest_app/core/widgets/gradient_background.dart';
import 'package:edunest_app/core/widgets/rounded_card.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CompleteProfilePage extends StatefulWidget {
  final AppUser user;

  const CompleteProfilePage({super.key, required this.user});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final _majorController = TextEditingController();
  final _universityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().completeProfile(
      name: _nameController.text.trim(),
      major: _majorController.text.trim(),
      university: _universityController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final message = context.select<AuthCubit, String?>((cubit) {
      final state = cubit.state;
      return state is NeedsProfileCompletion ? state.message : null;
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Complete Profile',
          style: AppTextStyles.titleMedium.copyWith(
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
                constraints: const BoxConstraints(maxWidth: 480),
                child: RoundedCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
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
                            child: const Icon(
                              Icons.school_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome to EduNest!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tell us a bit about your studies to personalize your experience.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        if (message != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.warning),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Full name
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Full name',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
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
                          validator: _validate,
                        ),
                        const SizedBox(height: 16),

                        // Major
                        TextFormField(
                          controller: _majorController,
                          textCapitalization: TextCapitalization.words,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Major (e.g. Computer Science, Law)',
                            prefixIcon: const Icon(Icons.auto_stories_outlined, size: 20),
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
                          validator: _validate,
                        ),
                        const SizedBox(height: 16),

                        // University
                        TextFormField(
                          controller: _universityController,
                          textCapitalization: TextCapitalization.words,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'University / Institution',
                            prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
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
                          validator: _validate,
                        ),
                        const SizedBox(height: 26),

                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;

                            return CustomRoundedButton(
                              text: 'Save and Continue',
                              onPressed: isLoading ? null : _submit,
                              isLoading: isLoading,
                              height: 52,
                              borderRadius: 26,
                            );
                          },
                        ),
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
