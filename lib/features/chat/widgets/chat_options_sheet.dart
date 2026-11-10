import 'package:edunest_app/features/chat/services/chat_service.dart';
import 'package:flutter/material.dart';

// 🎨 Palette (same as the Profile / Group info screens).
// Edit here to restyle every sheet and dialog in this file.
const Color _kPlum = Color(0xFF6B4A5B); // main accent
const Color _kRose = Color(0xFFE0BCC4); // dusty rose
const Color _kCard = Color(0xFFEEE8E7); // sheet / dialog surface
const Color _kBorder = Color(0xFFDDD2CF); // borders, dividers
const Color _kField = Color(0xFFE5DFDC); // inputs, cancel buttons, tile group
const Color _kTextDark = Color(0xFF3A2A32); // dark plum-brown text
const Color _kMuted = Color(0xFF7A6670); // muted text

// Option icon accents (soft tones that sit well with plum/rose)
const Color _kPinColor = Color(0xFF6B4A5B); // plum
const Color _kFavColor = Color(0xFFB8863B); // muted amber
const Color _kMuteColor = Color(0xFF9A6B80); // mauve

// Delete color used by the "Delete chat" tile AND the confirm dialog.
const Color _kDeleteColor = Color(0xFFC2674B); // warm terracotta

Future<void> showChatOptions(
  BuildContext context, {
  required String currentUserId,
  required String chatId,
  required String title,
  required Map<String, dynamic> settings,
}) async {
  final pinned = settings['pinned'] == true;
  final favorite = settings['favorite'] == true;
  final muted = settings['muted'] == true;
  final service = ChatService();

  await showModalBottomSheet(
    context: context,
    backgroundColor: _kCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _kRose,
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: _kPlum,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark,
                        ),
                      ),
                      const Text(
                        'Chat options',
                        style: TextStyle(fontSize: 13, color: _kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main actions
            Container(
              decoration: BoxDecoration(
                color: _kField,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                children: [
                  _OptionTile(
                    icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: _kPinColor,
                    label: pinned ? 'Unpin chat' : 'Pin chat',
                    onTap: () {
                      Navigator.pop(ctx);
                      service.togglePinChat(currentUserId, chatId, !pinned);
                    },
                  ),
                  const _OptionDivider(),
                  _OptionTile(
                    icon: favorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _kFavColor,
                    label: favorite
                        ? 'Remove from favourites'
                        : 'Add to favourites',
                    onTap: () {
                      Navigator.pop(ctx);
                      service.toggleFavoriteChat(
                          currentUserId, chatId, !favorite);
                    },
                  ),
                  const _OptionDivider(),
                  _OptionTile(
                    icon: muted
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_none_rounded,
                    color: _kMuteColor,
                    label:
                        muted ? 'Unmute notifications' : 'Mute notifications',
                    onTap: () {
                      Navigator.pop(ctx);
                      service.setMuteChat(currentUserId, chatId, !muted);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Delete (separate, destructive)
            Container(
              decoration: BoxDecoration(
                color: _kDeleteColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _kDeleteColor.withValues(alpha: 0.25),
                ),
              ),
              child: _OptionTile(
                icon: Icons.delete_outline_rounded,
                color: _kDeleteColor,
                label: 'Delete chat',
                labelColor: _kDeleteColor,
                showChevron: false,
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _confirmDelete(context, title);
                  if (ok) {
                    service.deleteChatForMe(currentUserId, chatId);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> showNicknameDialog(
  BuildContext context, {
  required String realName,
  String? currentNickname,
}) {
  final controller = TextEditingController(text: currentNickname ?? '');

  return showDialog<String>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Dialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kRose.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded, color: _kPlum, size: 26),
              ),
              const SizedBox(height: 14),
              const Text(
                'Set nickname',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Only you can see this nickname for $realName.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _kMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 30,
                cursorColor: _kPlum,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _kTextDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter nickname',
                  hintStyle: const TextStyle(color: _kMuted),
                  counterText: '',
                  filled: true,
                  fillColor: _kField,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _kPlum, width: 1.5),
                  ),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _kField,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _kTextDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _kPlum,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
    ),
  );
}

// ---------------------------------------------------------------------------
// Delete confirmation dialog (uses the same _kDeleteColor as the tile)
// ---------------------------------------------------------------------------
Future<bool> _confirmDelete(BuildContext context, String title) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Delete',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, _) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(
          opacity: anim,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _kBorder),
                    boxShadow: [
                      BoxShadow(
                        color: _kPlum.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon badge
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _kDeleteColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: _kDeleteColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Delete chat?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: _kMuted,
                          ),
                          children: [
                            const TextSpan(text: 'Your chat with '),
                            TextSpan(
                              text: title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _kTextDark,
                              ),
                            ),
                            const TextSpan(
                                text: ' will be removed from your list.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: _kField,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _kTextDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: _kDeleteColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: labelColor ?? _kTextDark,
        ),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right_rounded, color: _kMuted)
          : null,
    );
  }
}

class _OptionDivider extends StatelessWidget {
  const _OptionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 68, right: 14),
      child: Divider(height: 1, color: _kBorder),
    );
  }
}