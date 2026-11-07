import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:edunest_app/features/account_status/presentation/pages/account_status_page.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import '../../data/firebase_security_privacy_repo.dart';
import '../components/blocked_users_sheet.dart';
import '../components/change_email_dialog.dart';
import '../components/change_password_dialog.dart';
import '../components/privacy_policy_sheet.dart';

class SecurityPrivacyPage extends StatefulWidget {
  const SecurityPrivacyPage({super.key});

  @override
  State<SecurityPrivacyPage> createState() => _SecurityPrivacyPageState();
}

class _SecurityPrivacyPageState extends State<SecurityPrivacyPage>  with WidgetsBindingObserver {
  final FirebaseSecurityPrivacyRepo _repo = FirebaseSecurityPrivacyRepo();
  Map<String, dynamic> _privacySettings = {
    'profileVisibility': 'Public',
    'defaultPostPrivacy': 'Public',
    'allowTagging': true,
  };
  bool _isLoading = true;

  User? get _firebaseUser => FirebaseAuth.instance.currentUser;
  bool get _isGoogleUser =>
      _firebaseUser?.providerData.any((p) => p.providerId == 'google.com') ??
      false;
      

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrivacySettings();
    _syncEmailChange();
  }
 @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _refreshEmailStatus();
    _syncEmailChange();
  }
}

Future<void> _syncEmailChange() async {
  final updated = await _repo.syncVerifiedEmailChange();

  if (!mounted) return;

  if (updated) {
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your email address has been successfully updated!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

  Future<void> _loadPrivacySettings() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;

    try {
      final settings = await _repo.fetchPrivacySettings(uid);
      if (!mounted) return;
      setState(() {
        _privacySettings = settings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }
Future<void> _updateSetting(String key, dynamic val) async {
  final uid = _firebaseUser?.uid;
  if (uid == null) return;

  // Create a new map instead of modifying the existing map.
  final updatedSettings = Map<String, dynamic>.from(_privacySettings);
  updatedSettings[key] = val;

  setState(() {
    _privacySettings = updatedSettings;
  });

  try {
    await _repo.updatePrivacySettings(uid, updatedSettings);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy setting updated.'),
        duration: Duration(seconds: 1),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update: $e')),
    );
  }
}
  Future<void> _sendEmailVerification() async {
    try {
      await _repo.sendEmailVerificationLink();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Please check your inbox.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar( content: Text(
          e.toString().replaceAll('Exception: ', ''),),
        backgroundColor: Colors.red,),
      );
    }
  }
  Future<void> _refreshEmailStatus() async {
  await FirebaseAuth.instance.currentUser?.reload();

  if (!mounted) return;

  setState(() {});
}


  void _openChangePassword() {
    if (_isGoogleUser) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Google Sign-In Account'),
          content: const Text(
            'You signed in with your Google Account. Your password and 2-step verification are managed securely through your Google Account settings.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => const ChangePasswordDialog(),
    );
  }

  void _openChangeEmail() {
    showDialog(
      context: context,
      builder: (ctx) => const ChangeEmailDialog(),
    );
  }


  void _openBlockedUsers() {
    final uid = _firebaseUser?.uid ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlockedUsersSheet(currentUserId: uid),
    );
  }

  void _openPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PrivacyPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = context.watch<AuthCubit>().currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.inversePrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy and Security',
          style: TextStyle(
            color: colorScheme.inversePrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security & Data Controls',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your login security, password, email verification, post audiences, and blocked peers.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Section 1: Login Security
                  _sectionTitle('Login & Credentials'),
                  const SizedBox(height: 10),
                  _cardContainer(
                    children: [
                      _settingsTile(
                        icon: Iconsax.lock,
                        title: 'Change Password',
                        subtitle: _isGoogleUser
                            ? 'Managed via Google Sign-In'
                            : 'Update your account password',
                        onTap: _openChangePassword,
                      ),
                      const Divider(height: 1),
                      _settingsTile(
                        icon: Iconsax.sms,
                        title: 'Change Email Address',
                        subtitle: _firebaseUser?.email ??
    currentUser?.email ??
    'Unknown',
                        onTap: _openChangeEmail,
                      ),
                      const Divider(height: 1),
                    _settingsTile(
  icon: Iconsax.shield_tick,
  title: 'Email Security Verification',
  subtitle: _firebaseUser?.emailVerified == true
      ? 'Your email is verified'
      : 'Send a verification link to your email',
  onTap: _sendEmailVerification,
),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Privacy Controls
                  _sectionTitle('Privacy & Audience'),
                  const SizedBox(height: 10),
                  _cardContainer(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.eye,
                              size: 20,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Infomation Visibility',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.inversePrimary,
                                    ),
                                  ),
                                  Text(
                                    'Controls who can view your academic information and profile details',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                           DropdownButton<String>(
  value: ['Public', 'Friend', 'private'].contains(
    _privacySettings['profileVisibility'],
  )
      ? _privacySettings['profileVisibility'] as String
      : 'Public',
  underline: const SizedBox(),
  dropdownColor: isDark
      ? const Color(0xFF242227)
      : Colors.white,
  items: const [
    DropdownMenuItem(
      value: 'Public',
      child: Text('Public'),
    ),
    DropdownMenuItem(
      value: 'Friend',
      child: Text('Friends'),
    ),
    DropdownMenuItem(
      value: 'private',
      child: Text('Only Me'),
    ),
  ],
  onChanged: (val) {
    if (val != null) {
      _updateSetting('profileVisibility', val);
    }
  },
),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.document_text,
                              size: 20,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Default Post Audience',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.inversePrimary,
                                    ),
                                  ),
                                  Text(
                                    'Default privacy when drafting a post',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownButton<String>(
                              value: _privacySettings['defaultPostPrivacy'] ??
                                  'Public',
                              underline: const SizedBox(),
                              dropdownColor: isDark
                                  ? const Color(0xFF242227)
                                  : Colors.white,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Public',
                                  child: Text('Public'),
                                ),
                                DropdownMenuItem(
                                  value: 'Friend',
                                  child: Text('Friends'),
                                ),
                                DropdownMenuItem(
                                  value: 'private',
                                  child: Text('Only Me'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  _updateSetting('defaultPostPrivacy', val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      _settingsTile(
                        icon: Iconsax.user_minus,
                        title: 'Reported Content',
                        subtitle: 'Review and manage unblocking peers',
                        onTap: _openBlockedUsers,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Data & Compliance
                  _sectionTitle('Compliance & Transparency'),
                  const SizedBox(height: 10),
                  _cardContainer(
                    children: [
                      _settingsTile(
                        icon: Iconsax.info_circle,
                        title: 'EduNest Privacy Policy',
                        subtitle: 'How academic and personal data is handled',
                        onTap: _openPrivacyPolicy,
                      ),
                      const Divider(height: 1),
                      _settingsTile(
                        icon: Iconsax.status,
                        title: 'Account Status & Deletion',
                        subtitle: 'View standing and permanent erasure',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountStatusPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: colorScheme.inversePrimary,
      ),
    );
  }
  

  Widget _cardContainer({required List<Widget> children}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242227) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
  

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.inversePrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.secondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: colorScheme.secondary,
      ),
      onTap: onTap,
    );
  }
}
