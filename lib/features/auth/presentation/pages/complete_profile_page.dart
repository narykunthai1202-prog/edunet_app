import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CompleteProfilePage extends StatefulWidget {
  final AppUser user;

  const CompleteProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState
    extends State<CompleteProfilePage> {
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

    context.read<AuthCubit>().completeGoogleProfile(
      name: _nameController.text,
      major: _majorController.text,
      university: _universityController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete your profile'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to EduNest!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please complete your profile before continuing.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validate,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _majorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Major',
                        hintText: 'e.g. Information Technology',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validate,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _universityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'University',
                        hintText: 'Enter your university name',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validate,
                    ),
                    const SizedBox(height: 24),

                   
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    final isLoading = state is AuthLoading;

    return ElevatedButton(
      onPressed: isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Save and continue'),
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
    );
  }
}