import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/auth/presentation/components/forgotpassword.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:edunest_app/widget/widget_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

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
  bool phoneLoading = false;


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

      _showSnackBar("Google Login Error: $e", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          googleLoading = false;
        });
      }
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    final userRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        "uid": user.uid,
        "email": user.email ?? "",
        "name": user.displayName ?? "User",
      });
    }
  }


void showPhoneLoginDialog() {
  final formKey = GlobalKey<FormState>();
  String phone = '';

  showDialog<void>(
    context: context,
    barrierDismissible: !phoneLoading,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header icon
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EF),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.phone_iphone_rounded,
                        size: 34,
                        color: Color(0xFF219653),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'Login with phone',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202124),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Choose your country and enter your phone number. '
                    'We will send you a verification code by SMS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF737780),
                    ),
                  ),

                  const SizedBox(height: 26),

                  const Text(
                    'Phone number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF30343B),
                    ),
                  ),

                  const SizedBox(height: 10),

                  IntlPhoneField(
                    initialCountryCode: 'KH',
                    languageCode: 'en',
                    disableLengthCheck: false,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: '12 345 678',
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E5EA),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E5EA),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF219653),
                          width: 1.8,
                        ),
                      ),
                    ),
                    onChanged: (number) {
                      phone = number.completeNumber;
                    },
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 17,
                        color: Color(0xFF737780),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Your number is used to verify your account.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF737780),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Send OTP
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF219653),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        if (phone.isEmpty) return;

                        Navigator.pop(dialogContext);
                        verifyPhoneNumber(phone);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sms_outlined, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Send verification code',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Cancel
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF626873),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}


  String _normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s()-]'), '');
  }

 
Future<void> verifyPhoneNumber(String phone) async {
  if (phoneLoading) return;

  setState(() => phoneLoading = true);

  try {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,

      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await FirebaseAuth.instance
              .signInWithCredential(credential);

          final user = userCredential.user;
          if (user == null) {
            throw StateError('Phone sign-in did not return a user.');
          }

          await _ensureUserDocument(user);

          if (!mounted) return;
          context.read<AuthCubit>().checkAuth();
        } on FirebaseAuthException catch (e) {
          if (!mounted) return;
          _showSnackBar(
            'Phone login failed: ${e.message ?? e.code}',
            Colors.redAccent,
          );
        } catch (e) {
          if (!mounted) return;
          _showSnackBar('Phone login failed: $e', Colors.redAccent);
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        _showSnackBar(
          'Phone verification failed: ${e.message ?? e.code}',
          Colors.redAccent,
        );
      },

      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        showOtpDialog(verificationId);
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('Phone OTP auto-retrieval timed out.');
      },
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    _showSnackBar(
      'Phone login failed: ${e.message ?? e.code}',
      Colors.redAccent,
    );
  } catch (e) {
    if (!mounted) return;
    _showSnackBar('Phone login failed: $e', Colors.redAccent);
  } finally {
    if (mounted) {
      setState(() => phoneLoading = false);
    }
  }
}


  // ============================================================
  // OTP DIALOG
  // ============================================================

  void showOtpDialog(String verificationId) {
    final TextEditingController otpController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var verifying = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Enter OTP Code"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: "6-digit OTP",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (errorMessage != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: verifying
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: verifying
                    ? null
                    : () async {
                        final otp = otpController.text.trim();
                        if (otp.length != 6) {
                          setDialogState(
                            () => errorMessage = "Enter the 6-digit code.",
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Verify"),
              ),
            ],
          ),
        );
      },
    ).whenComplete(otpController.dispose);
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive values
    final bool isDesktop = screenWidth >= 700;

    final double logoWidth = isDesktop ? 280 : 220;
    final double logoHeight = isDesktop ? 150 : 130;

    final double cardWidth = isDesktop ? 520 : screenWidth - 40;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // --------------------------------------------------------
        // LOGIN SUCCESS
        // --------------------------------------------------------

        if (state is Authenticated) {
          _showSnackBar("Login Successfully", Colors.green);
        }
        // --------------------------------------------------------
        // LOGIN ERROR
        // --------------------------------------------------------
        else if (state is AuthError) {
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

          _showSnackBar(message, Colors.redAccent);
        }
      },

      child: Scaffold(
        backgroundColor: Colors.white,

        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 900,
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical,
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 30 : 20,
                    vertical: 20,
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      // ==================================================
                      // LOGO
                      // ==================================================

                      Image.asset(
                        "images/edunestlogo.png",
                        width: logoWidth,
                        height: logoHeight,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // LOGIN CARD
                      // ==================================================
                      SizedBox(
                        width: cardWidth,

                        child: Material(
                          elevation: 5,
                          borderRadius: BorderRadius.circular(20),

                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 35 : 20,
                              vertical: 25,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Form(
                              key: _formKey,

                              child: Column(
                                children: [
                                  // ==================================================
                                  // TITLE
                                  // ==================================================

                                  Text(
                                    "Login",
                                    style: AppWidget.HeadLineTextFeildStyle(),
                                  ),

                                  const SizedBox(height: 20),

                                  // ==================================================
                                  // EMAIL
                                  // ==================================================
                                  TextFormField(
                                    controller: emailController,

                                    keyboardType: TextInputType.emailAddress,

                                    textInputAction: TextInputAction.next,

                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Please Enter Email";
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
                                      hintText: "Email",

                                      hintStyle:
                                          AppWidget.semiBooldTextFeildStyle(),

                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),

                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // ==================================================
                                  // PASSWORD
                                  // ==================================================
                                  TextFormField(
                                    controller: passwordController,

                                    obscureText: obscurePassword,

                                    textInputAction: TextInputAction.done,

                                    onFieldSubmitted: (_) {
                                      userLogin();
                                    },

                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please Enter Password";
                                      }

                                      return null;
                                    },

                                    decoration: InputDecoration(
                                      hintText: "Password",

                                      hintStyle:
                                          AppWidget.semiBooldTextFeildStyle(),

                                      prefixIcon: const Icon(
                                        Icons.password_outlined,
                                      ),

                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },

                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                      ),

                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ==================================================
                                  // FORGOT PASSWORD
                                  // ==================================================
                                  Align(
                                    alignment: Alignment.centerRight,

                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ForgotPassword(),
                                          ),
                                        );
                                      },

                                      child: Text(
                                        "Forgot Password?",

                                        style:
                                            AppWidget.semiBooldTextFeildStyle(),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // ==================================================
                                  // LOGIN BUTTON
                                  // ==================================================
                                  BlocBuilder<AuthCubit, AuthState>(
                                    builder: (context, state) {
                                      final bool loading = state is AuthLoading;

                                      return GestureDetector(
                                        onTap: loading ? null : userLogin,

                                        child: Material(
                                          elevation: 5,

                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),

                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),

                                            width: isDesktop ? 220 : 200,

                                            decoration: BoxDecoration(
                                              color: loading
                                                  ? Colors.grey
                                                  : const Color.fromARGB(
                                                      255,
                                                      255,
                                                      164,
                                                      158,
                                                    ),

                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),

                                            child: Center(
                                              child: loading
                                                  ? const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : const Text(
                                                      "LOGIN",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontFamily: "Poppins",
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 15),

                                  // ==================================================
                                  // OR
                                  // ==================================================
                                  const Row(
                                    children: [
                                      Expanded(child: Divider()),

                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),

                                        child: Text(
                                          "OR",

                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),

                                      Expanded(child: Divider()),
                                    ],
                                  ),

                                  const SizedBox(height: 15),

                                  // ==================================================
                                  // GOOGLE
                                  // ==================================================
                                  SizedBox(
                                    width: double.infinity,

                                    height: 45,

                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),

                                      icon: googleLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.g_mobiledata,
                                              size: 28,
                                              color: Colors.red,
                                            ),

                                      label: Text(
                                        googleLoading
                                            ? "Signing in..."
                                            : "Continue with Google",
                                      ),

                                      onPressed: googleLoading
                                          ? null
                                          : signInWithGoogle,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ==================================================
                                  // PHONE
                                  // ==================================================
                                  SizedBox(
                                    width: double.infinity,

                                    height: 45,

                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),

                                      icon: const Icon(
                                        Icons.phone,
                                        size: 20,
                                        color: Colors.green,
                                      ),

                                      label: const Text("Continue with Phone"),

                                      onPressed: phoneLoading
                                          ? null
                                          : showPhoneLoginDialog,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // REGISTER
                      // ==================================================
                      GestureDetector(
                        onTap: widget.ontap,

                        child: Text(
                          "Don't have an account? Sign up",

                          style: AppWidget.semiBooldTextFeildStyle(),
                        ),
                      ),

                      const SizedBox(height: 20),
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
