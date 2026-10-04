import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:edunest_app/widget/widget_support.dart';
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool obscurePassword = true;

  void registration() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    context.read<AuthCubit>().register(name, email, password);
  }

  // ================= SNACKBAR =================

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

  // ================= DISPOSE =================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // ================= SUCCESS =================

        if (state is Authenticated) {
          _showSnackBar("Registered Successfully", Colors.green);
        }
        // ================= ERROR =================
        else if (state is AuthError) {
          String message = state.message;

          // Make Firebase errors easier to understand
          if (message.contains("email-already-in-use")) {
            message = "Account already exists";
          } else if (message.contains("weak-password")) {
            message = "Password is too weak";
          } else if (message.contains("invalid-email")) {
            message = "Invalid email address";
          }

          _showSnackBar(message, Colors.redAccent);
        }
      },

      // ================= SCAFFOLD =================
      child: Scaffold(
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // ================= TOP BACKGROUND =================

              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.white],
                  ),
                ),
              ),

              // ================= WHITE CONTAINER =================
              Container(
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height / 3,
                ),
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
              ),

              // ================= CONTENT =================
              Container(
                margin: const EdgeInsets.only(top: 30, left: 20, right: 20),
                child: Column(
                  children: [
                    // ================= LOGO =================

                    Center(
                      child: Image.asset(
                        "images/edunestlogo.png",
                        width: 300,
                        height: 200,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ================= FORM CARD =================
                    Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),

                              // ================= TITLE =================
                              Text(
                                "Sign up",
                                style: AppWidget.HeadLineTextFeildStyle(),
                              ),

                              const SizedBox(height: 20),

                              // ================= NAME =================
                              TextFormField(
                                controller: nameController,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please Enter Name";
                                  }

                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: "Name",
                                  prefixIcon: Icon(Icons.person_2_outlined),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ================= EMAIL =================
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please Enter E-mail";
                                  }

                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );

                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return "Please enter a valid email address";
                                  }

                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: "Email",
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ================= PASSWORD =================
                              TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  registration();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please Enter Password";
                                  }

                                  if (value.length < 6) {
                                    return "Password must be at least 6 characters";
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Password",
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
                                ),
                              ),

                              const SizedBox(height: 30),

                              // ================= SIGN UP BUTTON =================
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  final bool loading = state is AuthLoading;

                                  return GestureDetector(
                                    onTap: loading ? null : registration,
                                    child: Material(
                                      elevation: 5,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: loading
                                              ? Colors.grey
                                              : const Color.fromARGB(
                                                  255,
                                                  255,
                                                  164,
                                                  158,
                                                ),
                                          borderRadius: BorderRadius.circular(
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
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Text(
                                                  "SIGN UP",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontFamily: "Poppins",
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 15),

                              // ================= OR =================
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

                              // ================= GOOGLE =================
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.g_mobiledata,
                                  size: 28,
                                  color: Colors.red,
                                ),
                                label: const Text("Sign Up with Google"),
                                onPressed: () {
                                  _showSnackBar(
                                    "Google signup is not connected to your AuthRepo yet.",
                                    Colors.orange,
                                  );
                                },
                              ),

                              const SizedBox(height: 10),

                              // ================= PHONE =================
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.phone,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                label: const Text("Sign Up with Phone"),
                                onPressed: () {
                                  _showSnackBar(
                                    "Phone signup is not connected to your AuthRepo yet.",
                                    Colors.orange,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    GestureDetector(
                      onTap: widget.ontap,
                      child: Text(
                        "Already have an account? Login",
                        style: AppWidget.semiBooldTextFeildStyle(),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
