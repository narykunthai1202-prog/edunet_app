import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242227) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.shield_security, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Data Privacy Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _policySection(
                    title: '1. Academic Information Collected',
                    body:
                        'EduNest collects student profile details including your name, academic email, university affiliation, major, and course level to facilitate peer-to-peer study collaboration and relevant curriculum feeds.',
                  ),
                  _policySection(
                    title: '2. Post & Communication Visibility',
                    body:
                        'Public posts are visible to the EduNest educational community. Friend posts are strictly restricted to verified mutual followers. Private messages and voice notes are stored securely and accessible only to participants in that chat.',
                  ),
                  _policySection(
                    title: '3. Data Retention & Soft Deletion',
                    body:
                        'When you delete a post, it is safely retained in your private Archive for 30 days before permanent deletion. You retain the ability to restore or erase it immediately during this period.',
                  ),
                  _policySection(
                    title: '4. Security & Cryptographic Storage',
                    body:
                        'Security tokens, passwords, and one-time verification codes are salted and hashed using industry-standard SHA-256 algorithms. Plaintext passwords or verification codes are never stored on our servers.',
                  ),
                  _policySection(
                    title: '5. Account Erasure & Data Rights',
                    body:
                        'You have the fundamental right to permanently delete your account and all associated publications, study comments, messages, and profile documents at any time via Account Status > Delete Account.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policySection({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
