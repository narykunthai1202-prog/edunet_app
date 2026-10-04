import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/auth/presentation/components/forgotpassword.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:edunest_app/widget/widget_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  final void Function()? ontap;

  const LoginPage({
    super.key,
    required this.ontap,
  });

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

  // ============================================================
  // EMAIL / PASSWORD LOGIN
  // ============================================================

  void userLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    context.read<AuthCubit>().login(email, password);
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        googleLoading = true;
      });

      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        return;
      }

      // Check if user already exists in Firestore
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      // Create Firestore document for new Google user
      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "uid": user.uid,
          "email": user.email ?? "",
          "name": user.displayName ?? "User",
        });
      }

      if (!mounted) return;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showSnackBar(
        "Google Login Error: ${e.message ?? e.code}",
        Colors.redAccent,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        "Google Login Error: $e",
        Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() {
          googleLoading = false;
        });
      }
    }
  }

  // ============================================================
  // PHONE LOGIN
  // ============================================================

  void showPhoneLoginDialog() {
    final TextEditingController phoneController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Login with Phone Number"),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: "+855 12 345 678",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final phone = phoneController.text.trim();

                if (phone.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext);

                verifyPhoneNumber(phone);
              },
              child: const Text("Send OTP"),
            ),
          ],
        );
      },
    );
  }

  Future<void> verifyPhoneNumber(String phone) async {
    try {
      setState(() {
        phoneLoading = true;
      });

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,

        // Automatic verification
        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance
                .signInWithCredential(credential);

            if (!mounted) return;
          } catch (e) {
            if (!mounted) return;

            _showSnackBar(
              "Phone Login Error: $e",
              Colors.redAccent,
            );
          }
        },

        // Verification failed
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;

          _showSnackBar(
            "Phone Auth Failed: ${e.message}",
            Colors.redAccent,
          );
        },

        // OTP sent
        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          if (!mounted) return;

          showOtpDialog(verificationId);
        },

        // Timeout
        codeAutoRetrievalTimeout:
            (String verificationId) {},
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        "Phone Login Error: $e",
        Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() {
          phoneLoading = false;
        });
      }
    }
  }

  // ============================================================
  // OTP DIALOG
  // ============================================================

  void showOtpDialog(String verificationId) {
    final TextEditingController otpController =
        TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Enter OTP Code"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: "6-digit OTP",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final otp = otpController.text.trim();

                if (otp.isEmpty) {
                  return;
                }

                try {
                  final PhoneAuthCredential credential =
                      PhoneAuthProvider.credential(
                    verificationId: verificationId,
                    smsCode: otp,
                  );

                  final UserCredential userCredential =
                      await FirebaseAuth.instance
                          .signInWithCredential(
                    credential,
                  );

                  if (userCredential.user == null) {
                    return;
                  }

                  // Create Firestore user if necessary
                  final user = userCredential.user!;

                  final userDoc =
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(user.uid)
                          .get();

                  if (!userDoc.exists) {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .set({
                      "uid": user.uid,
                      "email": user.email ?? "",
                      "name": user.displayName ?? "User",
                    });
                  }

                  if (!mounted) return;

                  Navigator.pop(dialogContext);
                } on FirebaseAuthException catch (e) {
                  if (!mounted) return;

                  _showSnackBar(
                    "Invalid OTP: ${e.message ?? e.code}",
                    Colors.redAccent,
                  );
                } catch (e) {
                  if (!mounted) return;

                  _showSnackBar(
                    "OTP Error: $e",
                    Colors.redAccent,
                  );
                }
              },
              child: const Text("Verify"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
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

    final double cardWidth =
        isDesktop ? 520 : screenWidth - 40;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // --------------------------------------------------------
        // LOGIN SUCCESS
        // --------------------------------------------------------

        if (state is Authenticated) {
          _showSnackBar(
            "Login Successfully",
            Colors.green,
          );
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
            message =
                "Too many attempts. Please try again later.";
          }

          _showSnackBar(
            message,
            Colors.redAccent,
          );
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
                    mainAxisAlignment:
                        MainAxisAlignment.center,

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
                          borderRadius:
                              BorderRadius.circular(20),

                          child: Container(
                            padding:
                                EdgeInsets.symmetric(
                              horizontal:
                                  isDesktop ? 35 : 20,
                              vertical: 25,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius:
                                  BorderRadius.circular(20),
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
                                    style: AppWidget
                                        .HeadLineTextFeildStyle(),
                                  ),

                                  const SizedBox(height: 20),

                                  // ==================================================
                                  // EMAIL
                                  // ==================================================

                                  TextFormField(
                                    controller:
                                        emailController,

                                    keyboardType:
                                        TextInputType
                                            .emailAddress,

                                    textInputAction:
                                        TextInputAction.next,

                                    validator: (value) {
                                      if (value == null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return "Please Enter Email";
                                      }

                                      final emailRegex =
                                          RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      );

                                      if (!emailRegex
                                          .hasMatch(
                                        value.trim(),
                                      )) {
                                        return "Please enter a valid email";
                                      }

                                      return null;
                                    },

                                    decoration:
                                        InputDecoration(
                                      hintText: "Email",

                                      hintStyle: AppWidget
                                          .semiBooldTextFeildStyle(),

                                      prefixIcon:
                                          const Icon(
                                        Icons
                                            .email_outlined,
                                      ),

                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          15,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // ==================================================
                                  // PASSWORD
                                  // ==================================================

                                  TextFormField(
                                    controller:
                                        passwordController,

                                    obscureText:
                                        obscurePassword,

                                    textInputAction:
                                        TextInputAction.done,

                                    onFieldSubmitted: (_) {
                                      userLogin();
                                    },

                                    validator: (value) {
                                      if (value == null ||
                                          value.isEmpty) {
                                        return "Please Enter Password";
                                      }

                                      return null;
                                    },

                                    decoration:
                                        InputDecoration(
                                      hintText: "Password",

                                      hintStyle: AppWidget
                                          .semiBooldTextFeildStyle(),

                                      prefixIcon:
                                          const Icon(
                                        Icons
                                            .password_outlined,
                                      ),

                                      suffixIcon:
                                          IconButton(
                                        onPressed: () {
                                          setState(() {
                                            obscurePassword =
                                                !obscurePassword;
                                          });
                                        },

                                        icon: Icon(
                                          obscurePassword
                                              ? Icons
                                                  .visibility
                                              : Icons
                                                  .visibility_off,
                                        ),
                                      ),

                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          15,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ==================================================
                                  // FORGOT PASSWORD
                                  // ==================================================

                                  Align(
                                    alignment:
                                        Alignment.centerRight,

                                    child:
                                        GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const ForgotPassword(),
                                          ),
                                        );
                                      },

                                      child: Text(
                                        "Forgot Password?",

                                        style: AppWidget
                                            .semiBooldTextFeildStyle(),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // ==================================================
                                  // LOGIN BUTTON
                                  // ==================================================

                                  BlocBuilder<
                                      AuthCubit,
                                      AuthState>(
                                    builder:
                                        (context, state) {
                                      final bool loading =
                                          state
                                              is AuthLoading;

                                      return GestureDetector(
                                        onTap: loading
                                            ? null
                                            : userLogin,

                                        child: Material(
                                          elevation: 5,

                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            20,
                                          ),

                                          child:
                                              Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              vertical: 12,
                                            ),

                                            width:
                                                isDesktop
                                                    ? 220
                                                    : 200,

                                            decoration:
                                                BoxDecoration(
                                              color: loading
                                                  ? Colors
                                                      .grey
                                                  : const Color
                                                      .fromARGB(
                                                      255,
                                                      255,
                                                      164,
                                                      158,
                                                    ),

                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                20,
                                              ),
                                            ),

                                            child: Center(
                                              child: loading
                                                  ? const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth:
                                                            2,
                                                        color: Colors
                                                            .white,
                                                      ),
                                                    )
                                                  : const Text(
                                                      "LOGIN",
                                                      style:
                                                          TextStyle(
                                                        color: Colors
                                                            .white,
                                                        fontSize:
                                                            18,
                                                        fontFamily:
                                                            "Poppins",
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
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
                                      Expanded(
                                        child: Divider(),
                                      ),

                                      Padding(
                                        padding:
                                            EdgeInsets
                                                .symmetric(
                                          horizontal: 8,
                                        ),

                                        child: Text(
                                          "OR",

                                          style: TextStyle(
                                            color:
                                                Colors.grey,
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child: Divider(),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 15),

                                  // ==================================================
                                  // GOOGLE
                                  // ==================================================

                                  SizedBox(
                                    width:
                                        double.infinity,

                                    height: 45,

                                    child:
                                        OutlinedButton.icon(
                                      style: OutlinedButton
                                          .styleFrom(
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            20,
                                          ),
                                        ),
                                      ),

                                      icon: googleLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .g_mobiledata,
                                              size: 28,
                                              color: Colors.red,
                                            ),

                                      label: Text(
                                        googleLoading
                                            ? "Signing in..."
                                            : "Continue with Google",
                                      ),

                                      onPressed:
                                          googleLoading
                                              ? null
                                              : signInWithGoogle,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ==================================================
                                  // PHONE
                                  // ==================================================

                                  SizedBox(
                                    width:
                                        double.infinity,

                                    height: 45,

                                    child:
                                        OutlinedButton.icon(
                                      style: OutlinedButton
                                          .styleFrom(
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            20,
                                          ),
                                        ),
                                      ),

                                      icon: const Icon(
                                        Icons.phone,
                                        size: 20,
                                        color: Colors.green,
                                      ),

                                      label: const Text(
                                        "Continue with Phone",
                                      ),

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

                          style: AppWidget
                              .semiBooldTextFeildStyle(),
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
