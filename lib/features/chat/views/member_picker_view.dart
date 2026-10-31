// lib/chat/views/member_picker_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  // 🎨 Screen colors (edit here to restyle the whole screen)
  static const _plum = Color(0xFF6B4A5B); // main accent
  static const _rose = Color(0xFFE0BCC4); // dusty rose
  static const _field = Color(0xFFE5DFDC); // input background
  static const _textDark = Color(0xFF3A2A32); // dark plum-brown text
  static const _muted = Color(0xFF7A6670); // muted text

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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _textDark,
        title: Text(
          'Select members',
          style: GoogleFonts.nunito(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: _plum,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context, _selected.toList()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Done (${_selected.length})',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    cursorColor: _plum,
                    onSubmitted: (_) => _addById(),
                    style: GoogleFonts.nunito(
                      color: _textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add by user ID (e.g. user3)',
                      hintStyle: GoogleFonts.nunito(
                        color: _muted.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _plum,
                      ),
                      filled: true,
                      fillColor: _field,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: const BorderSide(color: _plum, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: _rose.withValues(alpha: 0.8),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _addById,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        color: _plum,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _plum),
                  )
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load members: $_loadError',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(color: _muted),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: _plum),
                            onPressed: _loadContacts,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _contacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _rose.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_outline_rounded,
                            size: 32,
                            color: _plum.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No contacts yet. Add a user ID above.',
                          style: GoogleFonts.nunito(
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
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