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
  _Contact(this.id, this.lastMessage) : name = id;
}

class _ForwardContactSheetState extends State<ForwardContactSheet> {
  static const _blue = Color(0xFF2563EB);

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

    // Look up each person's display name. If no name is found,
    // the user id is shown instead (same as a missing name in the chat list).
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
      } catch (_) {}
    }));

    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.7;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Forward to...',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  prefixIcon: const Icon(Icons.search, color: _blue),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_Contact>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load your chats.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
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
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, i) {
                      final c = list[i];
                      final initial =
                          c.name.isEmpty ? '?' : c.name[0].toUpperCase();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDBEAFE),
                          child: Text(
                            initial,
                            style: const TextStyle(
                                color: _blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: c.lastMessage.isEmpty
                            ? null
                            : Text(
                                c.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                        trailing: const Icon(Icons.send_rounded, color: _blue),
                        onTap: () => widget.onSelectUser(c.id, c.name),
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