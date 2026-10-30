// lib/chat/views/member_picker_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/member_profile_tile.dart';

/// Lets the user pick members from people they already chat with,
/// or add someone by typing their user ID.
/// Returns a list of selected user IDs via Navigator.pop.
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
  final Map<String, Map<String, dynamic>> _profiles = {};
  bool _loading = true;
  Object? _loadError;

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
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
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

      final userCollection = FirebaseFirestore.instance.collection('users');
      final userDocs = await Future.wait(
        ids.map((id) => userCollection.doc(id).get()),
      );
      final profiles = <String, Map<String, dynamic>>{
        for (final doc in userDocs)
          if (doc.exists && doc.data() != null) doc.id: doc.data()!,
      };

      if (!mounted) return;
      setState(() {
        _contacts = ids.toList()..sort();
        _profiles
          ..clear()
          ..addAll(profiles);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _addById() async {
    final id = _idController.text.trim();
    if (!_allowed(id)) return;
    setState(() {
      if (!_contacts.contains(id)) _contacts.insert(0, id);
      _selected.add(id);
      _idController.clear();
    });
    if (_profiles.containsKey(id)) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      if (!mounted || !doc.exists || doc.data() == null) return;
      setState(() => _profiles[id] = doc.data()!);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load user profile: $error')),
      );
    }
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
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Could not load members: $_loadError'),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loadContacts,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _contacts.isEmpty
                ? const Center(
                    child: Text(
                      'No contacts yet. Add a user ID above.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, i) {
                      final id = _contacts[i];
                      return MemberProfileTile(
                        userId: id,
                        profile: _profiles[id],
                        selected: _selected.contains(id),
                        onChanged: (value) => setState(() {
                          if (value == true) {
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
