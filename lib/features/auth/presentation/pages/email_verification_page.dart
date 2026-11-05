import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
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

                  return Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF219653,
                              ).withValues(alpha: .1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 48,
                              color: Color(0xFF219653),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202124),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We sent a verification link to:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Color(0xFF6D727A),
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF30343B),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Text(
                            'Open the link in your inbox to verify your account. '
                            'If you do not see it, check your spam folder. '
                            'You must verify before entering EduNest.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF6D727A),
                            ),
                          ),
                          if (pending?.message != null) ...[
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFF4E5,
                                ).withValues(alpha: .8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pending!.message!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF805400),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => context
                                  .read<AuthCubit>()
                                  .checkEmailVerification(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF219653),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('I Have Verified My Email'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => context
                                  .read<AuthCubit>()
                                  .resendVerificationEmail(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF219653),
                                side: const BorderSide(
                                  color: Color(0xFF219653),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Resend Verification Email'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                context.read<AuthCubit>().logout(),
                            child: const Text('Change Email / Return to Login'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
