import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/core/theme/app_colors.dart';
import 'package:edunest_app/core/theme/app_text_styles.dart';
import 'package:edunest_app/core/widgets/custom_rounded_button.dart';
import 'package:edunest_app/core/widgets/gradient_background.dart';
import 'package:edunest_app/core/widgets/rounded_card.dart';
import 'package:edunest_app/features/auth/presentation/components/forgotpassword.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class LoginPage extends StatefulWidget {
  final void Function()? ontap;

  const LoginPage({super.key, required this.ontap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool googleLoading = false;

  void userLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    context.read<AuthCubit>().login(email, password);
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        googleLoading = true;
      });

      await context.read<AuthCubit>().signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Google Login Error: $e", AppColors.error);
    } finally {
      if (mounted) {
        setState(() {
          googleLoading = false;
        });
      }
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    final userRef =
        FirebaseFirestore.instance.collection("users").doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        "uid": user.uid,
        "email": user.email ?? "",
        "name": user.displayName ?? "User",
      });
    }
  }

  void showOtpDialog(String verificationId) {
    final TextEditingController otpController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        var verifying = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            title: Text(
              "Enter OTP Code",
              style: AppTextStyles.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "We sent a 6-digit verification code to your phone.",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 8, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "••••••",
                    counterText: "",
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.background,
                    border: OutlineInputBorder(
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
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: verifying ? null : () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: verifying
                    ? null
                    : () async {
                        final otp = otpController.text.trim();
                        if (otp.length != 6) {
                          setDialogState(
                            () => errorMessage = "Enter the complete 6-digit code.",
                          );
                          return;
                        }

                        setDialogState(() {
                          verifying = true;
                          errorMessage = null;
                        });

                        try {
                          final credential = PhoneAuthProvider.credential(
                            verificationId: verificationId,
                            smsCode: otp,
                          );
                          final userCredential = await FirebaseAuth.instance
                              .signInWithCredential(credential);
                          final user = userCredential.user;
                          if (user == null) {
                            throw StateError(
                              'Phone sign-in did not return a user.',
                            );
                          }

                          await _ensureUserDocument(user);
                          if (!mounted || !dialogContext.mounted) return;

                          context.read<AuthCubit>().checkAuth();
                          Navigator.pop(dialogContext);
                        } on FirebaseAuthException catch (e) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            verifying = false;
                            errorMessage = e.message ?? e.code;
                          });
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            verifying = false;
                            errorMessage = e.toString();
                          });
                        }
                      },
                child: verifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("Verify"),
              ),
            ],
          ),
        );
      },
    ).whenComplete(otpController.dispose);
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 700;
    final cardWidth = isDesktop ? 480.0 : double.infinity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          _showSnackBar("Login Successfully", AppColors.success);
        } else if (state is AuthError) {
          String message = state.message;
          if (message.contains("user-not-found")) {
            message = "No user found for that email.";
          } else if (message.contains("wrong-password")) {
            message = "Wrong password.";
          } else if (message.contains("invalid-credential")) {
            message = "Invalid email or password.";
          } else if (message.contains("invalid-email")) {
            message = "Invalid email address.";
          } else if (message.contains("too-many-requests")) {
            message = "Too many attempts. Please try again later.";
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Crest / Logo Header
                      Container(
                        width: 72,
                        height: 72,
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
                          Icons.school_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'EduNest',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Welcome back to your academic network',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Main Login Card
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
                                "Sign In",
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Enter your credentials to continue",
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),

                              const SizedBox(height: 22),

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
                                    return "Please enter email";
                                  }
                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return "Please enter a valid email";
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
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => userLogin(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter password";
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

                              const SizedBox(height: 10),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPassword(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Forgot Password?",
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Login Button
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  final bool loading = state is AuthLoading;

                                  return CustomRoundedButton(
                                    text: "Sign In",
                                    onPressed: loading ? null : userLogin,
                                    isLoading: loading,
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
                                      "OR CONTINUE WITH",
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                                        letterSpacing: 0.8,
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

                              // Social Login Buttons (Google & Phone)
                              Row(
                                children: [
                                  // Google Button
                                  Expanded(
                                    child: Container(
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
                                          onTap: googleLoading ? null : signInWithGoogle,
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
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Google",
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
                                  ),

                          
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Sign Up Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.ontap,
                            child: Text(
                              "Sign Up",
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
}
