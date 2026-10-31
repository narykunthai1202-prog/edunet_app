import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberProfileTile extends StatelessWidget {
  final String userId;
  final Map<String, dynamic>? profile;
  final Widget? trailing;
  final ValueChanged<bool?>? onChanged;
  final bool selected;

  const MemberProfileTile({
    super.key,
    required this.userId,
    required this.profile,
    this.trailing,
    this.onChanged,
    this.selected = false,
  });

  // 🎨 Tile colors (edit here to restyle every member row)
  static const _plum = Color(0xFF6B4A5B); // checkbox, selected border
  static const _rose = Color(0xFFE0BCC4); // avatar background, selected tint
  static const _surface = Color(0xFFF6F2F1); // tile background
  static const _border = Color(0xFFDDD2CF); // tile border
  static const _textDark = Color(0xFF3A2A32); // dark plum-brown text
  static const _muted = Color(0xFF7A6670); // muted text

  String? _textValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final name = _textValue(profile?['name']) ?? userId;
    final bio = _textValue(profile?['bio']);
    final major = _textValue(profile?['major']);
    final university = _textValue(profile?['university']);
    final subtitle = bio ?? [?major, ?university].join(' · ');
    final photoUrl = _textValue(profile?['profileImageUrl']);

    final avatar = CircleAvatar(
      radius: 22,
      backgroundColor: _rose,
      backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
      child: photoUrl == null
          ? Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: GoogleFonts.nunito(
                color: _plum,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );

    final title = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _textDark,
      ),
    );

    final subtitleWidget = subtitle.isEmpty
        ? null
        : Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(color: _muted, fontSize: 12.5),
          );

    // Rounded card look; turns rose-tinted with a plum border when selected
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: selected ? _plum : _border,
        width: selected ? 1.5 : 1,
      ),
    );
    final bg = selected ? _rose.withValues(alpha: 0.35) : _surface;

    // ✅ Picker mode (checkbox)
    if (onChanged != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: bg,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: CheckboxListTile(
            value: selected,
            title: title,
            subtitle: subtitleWidget,
            secondary: avatar,
            onChanged: onChanged,
            activeColor: _plum,
            checkColor: Colors.white,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
          ),
        ),
      );
    }

    // 👤 Display mode (member with an optional trailing button)
    return Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: avatar,
        title: title,
        subtitle: subtitleWidget,
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}