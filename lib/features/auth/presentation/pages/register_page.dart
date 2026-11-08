import 'package:edunest_app/core/theme/app_colors.dart';
import 'package:edunest_app/core/theme/app_text_styles.dart';
import 'package:edunest_app/core/widgets/custom_rounded_button.dart';
import 'package:edunest_app/core/widgets/gradient_background.dart';
import 'package:edunest_app/core/widgets/rounded_card.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatefulWidget {
  final void Function() ontap;
  const RegisterPage({super.key, required this.ontap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool loading = false;
  bool googleLoading = false;

  // Password validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);
    confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  void _onPasswordChanged() {
    final text = passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUppercase = text.contains(RegExp(r'[A-Z]'));
      _hasLowercase = text.contains(RegExp(r'[a-z]'));
      _hasDigit = text.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _passwordsMatch =
          confirmPasswordController.text.isNotEmpty &&
          text == confirmPasswordController.text;
    });
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      _passwordsMatch =
          confirmPasswordController.text.isNotEmpty &&
          passwordController.text == confirmPasswordController.text;
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasDigit &&
      _hasSpecialChar;

  Future<void> registration() async {
    if (loading || !_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPasswordValid) {
      _showSnackBar(
        "Please meet all password requirements before continuing.",
        AppColors.warning,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar("Passwords do not match.", AppColors.error);
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final authCubit = context.read<AuthCubit>();

    setState(() => loading = true);
    try {
      await authCubit.register(name, email, password);
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          error.toString().replaceFirst('Exception: ', ''),
          AppColors.error,
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    try {
      setState(() => googleLoading = true);
      await context.read<AuthCubit>().signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Google Sign-In Error: $e", AppColors.error);
    } finally {
      if (mounted) setState(() => googleLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    passwordController.removeListener(_onPasswordChanged);
    confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 700;
    final cardWidth = isDesktop ? 500.0 : double.infinity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          _showSnackBar("Registered Successfully", AppColors.success);
        } else if (state is AuthError) {
          String message = state.message;
          if (message.contains("email-already-in-use")) {
            message = "An account already exists for this email.";
          } else if (message.contains("weak-password")) {
            message = "The password provided is too weak.";
          } else if (message.contains("invalid-email")) {
            message = "Invalid email address format.";
          }
          _showSnackBar(message, AppColors.error);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: GradientBackground(
          showFloatingOrbs: true,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : 22,
                  vertical: 24,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header App Crest
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Join EduNest',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Create an account to connect with students',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Registration Form Card
                      RoundedCard(
                        borderRadius: 26,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Create Account",
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Fill in the details below to get started",
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Full Name Field
                              TextFormField(
                                controller: nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter your full name";
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Full Name",
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
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

                              const SizedBox(height: 16),

                              // Email Field
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter your email address";
                                  }
                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return "Please enter a valid email address";
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Email address",
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

                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                textInputAction: TextInputAction.next,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter a password";
                                  }
                                  if (value.length < 8) {
                                    return "Password must be at least 8 characters";
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: AppColors.secondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
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

                              const SizedBox(height: 16),

                              // Confirm Password Field
                              TextFormField(
                                controller: confirmPasswordController,
                                obscureText: obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => registration(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please confirm your password";
                                  }
                                  if (value != passwordController.text) {
                                    return "Passwords do not match";
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Confirm Password",
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: AppColors.secondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureConfirmPassword =
                                            !obscureConfirmPassword;
                                      });
                                    },
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

                              // Password Requirements Checklist Card
                              if (passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : AppColors.cardSubtle,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Password Requirements:",
                                        style: AppTextStyles.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRequirementRow("At least 8 characters", _hasMinLength, isDark),
                                      _buildRequirementRow("At least one uppercase letter (A-Z)", _hasUppercase, isDark),
                                      _buildRequirementRow("At least one lowercase letter (a-z)", _hasLowercase, isDark),
                                      _buildRequirementRow("At least one number (0-9)", _hasDigit, isDark),
                                      _buildRequirementRow("At least one special symbol (!@#\$%^&*)", _hasSpecialChar, isDark),
                                      if (confirmPasswordController.text.isNotEmpty)
                                        _buildRequirementRow("Passwords match", _passwordsMatch, isDark),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Register Button
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  final bool isLoading =
                                      loading || state is AuthLoading;

                                  return CustomRoundedButton(
                                    text: "Create Account",
                                    onPressed: isLoading ? null : registration,
                                    isLoading: isLoading,
                                    variant: ButtonVariant.primary,
                                    height: 52,
                                    borderRadius: 26,
                                  );
                                },
                              ),

                              const SizedBox(height: 22),

                              // OR Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text(
                                      "OR",
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Google Sign-Up Button
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.cardSubtle,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(25),
                                    onTap: googleLoading ? null : _signUpWithGoogle,
                                    child: Center(
                                      child: googleLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppColors.primary,
                                                ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.g_mobiledata_rounded,
                                                  size: 26,
                                                  color: Color(0xFFEA4335),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "Sign Up with Google",
                                                  style: AppTextStyles.labelMedium.copyWith(
                                                    color: isDark
                                                        ? AppColors.darkTextPrimary
                                                        : AppColors.textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Sign In Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.ontap,
                            child: Text(
                              "Sign In",
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: met ? AppColors.success : (isDark ? Colors.white30 : AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: met
                    ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                fontWeight: met ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
