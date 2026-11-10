// lib/chat/widgets/media_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

/// Photo / Video chooser, same style as the group chat.
///
/// showMediaPickerSheet(
///   context,
///   onPhoto: _pickPhoto,
///   onVideo: _pickVideo,
/// );
Future<void> showMediaPickerSheet(
  BuildContext context, {
  required VoidCallback onPhoto,
  required VoidCallback onVideo,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFFF7F1F0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MediaTile(
              icon: Icons.photo_rounded,
              title: 'Send a photo',
              subtitle: 'Pick an image from your gallery',
              onTap: () {
                Navigator.pop(ctx);
                onPhoto();
              },
            ),
            const SizedBox(height: 10),
            _MediaTile(
              icon: Icons.videocam_rounded,
              title: 'Send a video',
              subtitle: 'Up to 25 MB and 2 minutes',
              onTap: () {
                Navigator.pop(ctx);
                onVideo();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _MediaTile extends StatelessWidget {
  static const _plum = Color(0xFF6B4A5B);
  static const _textDark = Color(0xFF3A2A32);
  static const _muted = Color(0xFF7A6670);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MediaTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _plum.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0BCC4).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _plum, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _plum),
            ],
          ),
        ),
      ),
    );
  }
}