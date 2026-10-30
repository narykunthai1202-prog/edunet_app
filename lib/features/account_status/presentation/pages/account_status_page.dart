import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import '../components/admin_suspension_sheet.dart';
import '../components/delete_account_dialog.dart';

class AccountStatusPage extends StatelessWidget {
  const AccountStatusPage({super.key});

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _openAdminPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AdminSuspensionSheet(),
    );
  }

  void _openDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const DeleteAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final AppUser? user = context.watch<AuthCubit>().currentUser;
    final bool isAdmin = user?.role == 'admin';
    final bool isSuspended = user?.isSuspended ?? false;

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
          'Account Status',
          style: TextStyle(
            color: colorScheme.inversePrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title and description
            Text(
              'Account Standing & Health',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Review your account standing, registration records, community permissions, and security options.',
              style: TextStyle(
                fontSize: 13.5,
                color: colorScheme.secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Main Status Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242227) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSuspended
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSuspended ? Colors.red : Colors.green)
                        .withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isSuspended ? Colors.red : Colors.green)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSuspended ? Iconsax.danger : Iconsax.verify,
                          color: isSuspended ? Colors.red : Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isSuspended
                                      ? 'Account Restricted'
                                      : 'In Good Standing',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isSuspended
                                        ? Colors.red
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isSuspended
                                  ? 'Active restrictions on your account'
                                  : 'No strikes or violations recorded',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Standing perks checklist
                  _standingCheckItem(
                    title: 'Full Platform Access',
                    subtitle:
                        'Authorized to post, comment, message, and study in groups.',
                    isActive: !isSuspended,
                  ),
                  const SizedBox(height: 10),
                  _standingCheckItem(
                    title: 'Educational Community Verification',
                    subtitle:
                        'Member of the verified EduNest academic social network.',
                    isActive: true,
                  ),
                  const SizedBox(height: 10),
                  _standingCheckItem(
                    title: 'Zero Content Strikes',
                    subtitle: 'Clean record adhering to our community guidelines.',
                    isActive: !isSuspended,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Details Card
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242227) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  _infoRow(
                    context,
                    label: 'Full Name',
                    value: user?.name ?? 'Student',
                    icon: Iconsax.user,
                  ),
                  const Divider(height: 20),
                  _infoRow(
                    context,
                    label: 'Email Address',
                    value: user?.email ?? 'Unknown',
                    icon: Iconsax.sms,
                  ),
                  const Divider(height: 20),
                  _infoRow(
                    context,
                    label: 'Registered On',
                    value: user?.createdAt != null
                        ? _formatDate(user!.createdAt!)
                        : 'Active Member',
                    icon: Iconsax.calendar_1,
                  ),
                  const Divider(height: 20),
                  _infoRow(
                    context,
                    label: 'User UID',
                    value: user?.uid != null
                        ? '${user!.uid.substring(0, user.uid.length > 12 ? 12 : user.uid.length)}...'
                        : 'N/A',
                    icon: Iconsax.finger_scan,
                    onTap: () {
                      if (user?.uid != null) {
                        Clipboard.setData(ClipboardData(text: user!.uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UID copied to clipboard')),
                        );
                      }
                    },
                    trailing: const Icon(Iconsax.copy, size: 16),
                  ),
                ],
              ),
            ),

            // Admin panel trigger (if user is admin or for testing)
            if (isAdmin) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.security_safe, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator Privileges',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.inversePrimary,
                            ),
                          ),
                          Text(
                            'You have access to account suspension and moderation tools.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () => _openAdminPanel(context),
                      child: const Text('Manage'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Danger Zone: Delete Account
            Text(
              'Account Deletion & Data Privacy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Iconsax.info_circle, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Permanent Account Deletion',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once you delete your account, your published posts, comments, reactions, notifications, and profile data will be permanently wiped.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: colorScheme.inversePrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _openDeleteDialog(context),
                      icon: const Icon(Iconsax.trash, size: 18),
                      label: const Text(
                        'Delete My Account Permanently',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _standingCheckItem({
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: isActive ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.secondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.secondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.inversePrimary,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing,
          ],
        ],
      ),
    );
  }
}
