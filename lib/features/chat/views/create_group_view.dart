// lib/chat/views/create_group_view.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/group_service.dart';
import '../widgets/member_profile_tile.dart';
import 'group_chat_view.dart';
import 'member_picker_view.dart';

class CreateGroupView extends StatefulWidget {
  final String currentUserId;

  const CreateGroupView({super.key, required this.currentUserId});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  // 🎨 Screen colors (edit here to restyle the whole screen)
  static const _plum = Color(0xFF6B4A5B); // main accent
  static const _rose = Color(0xFFE0BCC4); // dusty rose badges
  static const _card = Color(0xFFEEE8E7); // card surface
  static const _border = Color(0xFFDDD2CF); // card border
  static const _field = Color(0xFFE5DFDC); // input / row background
  static const _ring = Color(0xFFF3EDEB); // avatar ring
  static const _textDark = Color(0xFF3A2A32); // dark plum-brown text
  static const _muted = Color(0xFF7A6670); // muted text
  static const _disabled = Color(0xFFCBBFC3); // disabled button
  static const _danger = Color(0xFFC2674B); // remove member

  final GroupService _service = GroupService();
  final TextEditingController _nameController = TextEditingController();

  Uint8List? _photoBytes;
  List<String> _members = [];
  final Map<String, Map<String, dynamic>> _memberProfiles = {};
  bool _creating = false;

  bool get _canCreate =>
      !_creating &&
      _nameController.text.trim().isNotEmpty &&
      _members.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // rebuild so the Create button enables/disables while typing
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --------------------------------------------------------------- actions

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _photoBytes = bytes);
  }

  Future<void> _addMembers() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberPickerView(
          currentUserId: widget.currentUserId,
          excludeIds: _members,
        ),
      ),
    );
    if (result == null || result.isEmpty) return;
    final newMembers = result.where((id) => !_members.contains(id)).toList();
    setState(() => _members = {..._members, ...result}.toList());
    if (newMembers.isEmpty) return;

    try {
      final userCollection = FirebaseFirestore.instance.collection('users');
      final userDocs = await Future.wait(
        newMembers.map((id) => userCollection.doc(id).get()),
      );
      if (!mounted) return;
      setState(() {
        for (final doc in userDocs) {
          if (doc.exists && doc.data() != null) {
            _memberProfiles[doc.id] = doc.data()!;
          }
        }
      });
    } catch (error) {
      _toast('Could not load member profiles: $error');
    }
  }

  void _removeMember(String id) {
    setState(() => _members = _members.where((m) => m != id).toList());
  }

  Future<void> _create() async {
    if (!_canCreate) return;
    setState(() => _creating = true);

    try {
      final groupId = await _service.createGroup(
        creatorId: widget.currentUserId,
        name: _nameController.text.trim(),
        memberIds: _members,
        photoBytes: _photoBytes,
      );
      if (!mounted) return;

      // open the new group right away
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GroupChatView(
            groupId: groupId,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    } catch (e) {
      _toast('Failed to create group: $e');
      if (mounted) setState(() => _creating = false);
    }
  }

  // ------------------------------------------------------------------ build

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
        centerTitle: true,
        title: Text(
          'New group',
          style: GoogleFonts.nunito(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _avatarSection(),
                const SizedBox(height: 22),
                _nameCard(),
                const SizedBox(height: 16),
                _membersCard(),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- avatar section

  Widget _avatarSection() {
    final name = _nameController.text.trim();

    return Column(
      children: [
        GestureDetector(
          onTap: _pickPhoto,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _ring,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _plum.withValues(alpha: 0.15),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: _rose,
                  backgroundImage:
                      _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                  child: _photoBytes == null
                      ? const Icon(Icons.groups_rounded, size: 48, color: _plum)
                      : null,
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _plum,
                    shape: BoxShape.circle,
                    border: Border.all(color: _ring, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name.isEmpty ? 'Group name' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            color: name.isEmpty ? _muted.withValues(alpha: 0.6) : _textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _rose.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_rounded, size: 16, color: _plum),
              const SizedBox(width: 6),
              Text(
                // +1 because you are in the group too
                '${_members.length + 1} members',
                style: GoogleFonts.nunito(
                  color: _plum,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ cards

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: _card,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: _plum.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  Widget _cardTitle(IconData icon, String title, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _rose.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _plum, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _nameCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.edit_rounded, 'Group name'),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            maxLength: 40,
            cursorColor: _plum,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Weekend plans',
              hintStyle: GoogleFonts.nunito(color: _muted.withValues(alpha: 0.7)),
              counterStyle: const TextStyle(color: _muted),
              filled: true,
              fillColor: _field,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _plum, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _membersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            Icons.group_add_rounded,
            'Members',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _rose.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_members.length}',
                style: const TextStyle(
                  color: _plum,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // add members button
          Material(
            color: _field,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _addMembers,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: _plum,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add members',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _plum,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _plum),
                  ],
                ),
              ),
            ),
          ),

          if (_members.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Text(
                'No members yet. Add at least one person to create the group.',
                style: GoogleFonts.nunito(fontSize: 13, color: _muted),
              ),
            )
          else
            ..._members.map(
              (id) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: MemberProfileTile(
                  userId: id,
                  profile: _memberProfiles[id],
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close_rounded, color: _danger),
                    onPressed: () => _removeMember(id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- bottom bar

  Widget _bottomBar() {
    final enabled = _canCreate;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: _plum.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: enabled ? _create : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _plum,
              disabledBackgroundColor: _disabled,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: enabled ? 4 : 0,
              shadowColor: _plum.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _creating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Create group',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}