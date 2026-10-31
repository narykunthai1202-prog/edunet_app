import 'package:edunest_app/features/account_status/data/account_status_repo.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminSuspensionSheet extends StatefulWidget {
  const AdminSuspensionSheet({super.key});

  @override
  State<AdminSuspensionSheet> createState() => _AdminSuspensionSheetState();
}

class _AdminSuspensionSheetState extends State<AdminSuspensionSheet> {
  final TextEditingController _targetUidController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final AccountStatusRepo _repo = AccountStatusRepo();

  int _selectedDurationDays = 7; // 7, 30, or -1 (Permanent)
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _targetUidController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _applySuspension() async {
    final targetUid = _targetUidController.text.trim();
    final reason = _reasonController.text.trim();

    if (targetUid.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter the target User ID.';
        _isSuccess = false;
      });
      return;
    }

    if (reason.isEmpty) {
      setState(() {
        _statusMessage = 'Please provide a valid moderation reason.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final DateTime? until = _selectedDurationDays == -1
          ? null
          : DateTime.now().add(Duration(days: _selectedDurationDays));

      await _repo.suspendAccount(
        targetUid: targetUid,
        reason: reason,
        suspendedUntil: until,
      );

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage =
            'User $targetUid has been suspended until ${until != null ? "${until.day}/${until.month}/${until.year}" : "indefinite review"}.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _reinstateUser() async {
    final targetUid = _targetUidController.text.trim();
    if (targetUid.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter the target User ID to reinstate.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await _repo.reinstateAccount(targetUid);
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage =
            'Account for user $targetUid has been successfully reinstated.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242227) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  child: Icon(
                    Iconsax.security_user,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Admin Moderation Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Suspend or reinstate accounts violating student community guidelines.',
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 18),

            // Target UID Input
            TextField(
              controller: _targetUidController,
              decoration: InputDecoration(
                labelText: 'Target User ID (UID)',
                hintText: 'e.g. 5x7Yq9...',
                prefixIcon: const Icon(Iconsax.user, size: 18),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Reason Input
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Suspension Reason',
                hintText: 'e.g. Inappropriate content or harassment',
                prefixIcon: const Icon(Iconsax.note_text, size: 18),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Suspension Duration',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _durationChip(label: '7 Days', days: 7),
                const SizedBox(width: 8),
                _durationChip(label: '30 Days', days: 30),
                const SizedBox(width: 8),
                _durationChip(label: 'Indefinite', days: -1),
              ],
            ),
            const SizedBox(height: 16),

            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Iconsax.tick_circle : Iconsax.danger,
                      color: _isSuccess ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _isSuccess ? Colors.green.shade800 : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _reinstateUser,
                    child: const Text('Reinstate User'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _applySuspension,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Suspend Account'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationChip({required String label, required int days}) {
    final isSelected = _selectedDurationDays == days;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDurationDays = days;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : colorScheme.inversePrimary,
            ),
          ),
        ),
      ),
    );
  }
}
