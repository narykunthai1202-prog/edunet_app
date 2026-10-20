// lib/chat/views/member_picker_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lets the user pick members from people they already chat with,
/// or add someone by typing their user ID.
/// Returns List<String> of selected user IDs via Navigator.pop.
class MemberPickerView extends StatefulWidget {
  final String currentUserId;
  final List<String> excludeIds; // already in the group
  final List<String> initiallySelected;

  const MemberPickerView({
    super.key,
    required this.currentUserId,
    this.excludeIds = const [],
    this.initiallySelected = const [],
  });

  @override
  State<MemberPickerView> createState() => _MemberPickerViewState();
}

class _MemberPickerViewState extends State<MemberPickerView> {
  final TextEditingController _idController = TextEditingController();
  final Set<String> _selected = {};
  List<String> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initiallySelected);
    _loadContacts();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  bool _allowed(String id) =>
      id.isNotEmpty &&
      id != widget.currentUserId &&
      !widget.excludeIds.contains(id);

  Future<void> _loadContacts() async {
    final snap = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: widget.currentUserId)
        .get();

    final ids = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isGroup'] == true) continue;
      for (final p in List<String>.from(data['participants'] ?? [])) {
        if (_allowed(p)) ids.add(p);
      }
    }
    for (final id in _selected) {
      if (_allowed(id)) ids.add(id);
    }

    if (!mounted) return;
    setState(() {
      _contacts = ids.toList()..sort();
      _loading = false;
    });
  }

  void _addById() {
    final id = _idController.text.trim();
    if (!_allowed(id)) return;
    setState(() {
      if (!_contacts.contains(id)) _contacts.insert(0, id);
      _selected.add(id);
      _idController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select members'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: Text('Done (${_selected.length})'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    onSubmitted: (_) => _addById(),
                    decoration: InputDecoration(
                      hintText: 'Add by user ID (e.g. user3)',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Color(0xFF2563EB)),
                  onPressed: _addById,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? const Center(
                        child: Text('No contacts yet. Add a user ID above.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, i) {
                          final id = _contacts[i];
                          return CheckboxListTile(
                            value: _selected.contains(id),
                            title: Text(id),
                            secondary: CircleAvatar(
                              backgroundColor: const Color(0xFFE0E7FF),
                              child: Text(id[0].toUpperCase()),
                            ),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(id);
                              } else {
                                _selected.remove(id);
                              }
                            }),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}