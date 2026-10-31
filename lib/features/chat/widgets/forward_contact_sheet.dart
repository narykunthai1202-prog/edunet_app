import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// "Forward to..." bottom sheet.
/// Shows ONLY the people you already have a 1-to-1 chat with
/// (the same people that appear in your chat list), newest chat first.
class ForwardContactSheet extends StatefulWidget {
  const ForwardContactSheet({
    super.key,
    required this.currentUserId,
    required this.onSelectUser,
  });

  final String currentUserId;
  final void Function(String targetUserId, String targetUserName)
      onSelectUser;

  @override
  State<ForwardContactSheet> createState() => _ForwardContactSheetState();
}

class _Contact {
  final String id;
  final String lastMessage;
  String name;
  String? photoUrl; // profile picture (loaded from the users collection)
  _Contact(this.id, this.lastMessage) : name = id;
}

class _ForwardContactSheetState extends State<ForwardContactSheet> {
  // 🎨 Sheet colors (change these to restyle the whole sheet)
  static const _bg = Color(0xFFD9C3CB); // light dusty rose background
  static const _card = Color(0xFFEFE3E6); // softer cards / search bar
  static const _accent = Color(0xFF6B4A5B); // plum: ring, icons, send button
  static const _textMain = Color(0xFF3A2A32); // dark plum text
  static const _textMuted = Color(0xFF7A6670); // muted text

  final TextEditingController _search = TextEditingController();
  late final Future<List<_Contact>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Finds every 1-to-1 chat of the current user and returns the other person.
  Future<List<_Contact>> _load() async {
    final db = FirebaseFirestore.instance;

    final snap = await db
        .collection('chats')
        .where('participants', arrayContains: widget.currentUserId)
        .get();

    // 1-to-1 chats only (groups are skipped)
    final chats = snap.docs.where((d) => d.data()['isGroup'] != true).toList();

    DateTime timeOf(Map<String, dynamic> d) {
      final t = d['lastMessageTime'];
      return t is Timestamp ? t.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
    }

    chats.sort((a, b) => timeOf(b.data()).compareTo(timeOf(a.data())));

    final seen = <String>{};
    final contacts = <_Contact>[];

    for (final doc in chats) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? []);
      final peer = participants.firstWhere(
        (p) => p != widget.currentUserId,
        orElse: () => '',
      );
      if (peer.isEmpty || !seen.add(peer)) continue;
      contacts.add(_Contact(peer, (data['lastMessage'] ?? '') as String));
    }

    // Look up each person's display name AND profile picture.
    // If no name is found, the user id is shown instead.
    await Future.wait(contacts.map((c) async {
      try {
        final u = await db.collection('users').doc(c.id).get();
        final d = u.data();
        if (d == null) return;

        for (final key in const ['name', 'displayName', 'username', 'userName']) {
          final v = d[key];
          if (v is String && v.trim().isNotEmpty) {
            c.name = v.trim();
            break;
          }
        }

        // 'profileImageUrl' is the field your chat screen uses; the others
        // are common alternatives, just in case.
        for (final key in const [
          'profileImageUrl',
          'photoUrl',
          'photoURL',
          'avatar',
          'imageUrl',
        ]) {
          final v = d[key];
          if (v is String && v.trim().isNotEmpty) {
            c.photoUrl = v.trim();
            break;
          }
        }
      } catch (_) {}
    }));

    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Drag handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 6),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.forward_rounded, color: _accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forward to',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textMain,
                          ),
                        ),
                        Text(
                          'Choose a chat to send this message',
                          style: TextStyle(fontSize: 12, color: _textMuted),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: _card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: _textMain,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: TextField(
                controller: _search,
                style: const TextStyle(color: _textMain),
                cursorColor: _accent,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: const TextStyle(color: _textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: _accent),
                  filled: true,
                  fillColor: _card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: FutureBuilder<List<_Contact>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accent,
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load your chats.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _textMuted),
                        ),
                      ),
                    );
                  }

                  final all = snap.data ?? [];
                  final list = _query.isEmpty
                      ? all
                      : all
                          .where((c) =>
                              c.name.toLowerCase().contains(_query) ||
                              c.id.toLowerCase().contains(_query))
                          .toList();

                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        all.isEmpty
                            ? 'No chats yet'
                            : 'No chats match your search',
                        style: const TextStyle(color: _textMuted),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = list[i];
                      final initial =
                          c.name.isEmpty ? '?' : c.name[0].toUpperCase();
                      final hasPhoto =
                          c.photoUrl != null && c.photoUrl!.isNotEmpty;

                      return Material(
                        color: _card,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => widget.onSelectUser(c.id, c.name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                // Avatar with colored ring + profile picture
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _accent,
                                      width: 1.6,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        _accent.withValues(alpha: 0.15),
                                    backgroundImage: hasPhoto
                                        ? NetworkImage(c.photoUrl!)
                                        : null,
                                    // If the picture fails to load, fall back
                                    // to the letter below.
                                    onBackgroundImageError:
                                        hasPhoto ? (_, _) {} : null,
                                    child: hasPhoto
                                        ? null
                                        : Text(
                                            initial,
                                            style: const TextStyle(
                                              color: _accent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: _textMain,
                                        ),
                                      ),
                                      if (c.lastMessage.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            c.lastMessage,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _textMuted,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Filled round send button
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: _accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}