import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFE0E7FF),
      backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
      child: photoUrl == null
          ? Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF3730A3),
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
    final title = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
    final subtitleWidget = subtitle.isEmpty
        ? null
        : Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          );

    if (onChanged != null) {
      return CheckboxListTile(
        value: selected,
        title: title,
        subtitle: subtitleWidget,
        secondary: avatar,
        onChanged: onChanged,
      );
    }

    return ListTile(
      leading: avatar,
      title: title,
      subtitle: subtitleWidget,
      trailing: trailing,
    );
  }
}
