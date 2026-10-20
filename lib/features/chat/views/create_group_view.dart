// lib/chat/views/create_group_view.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/group_service.dart';
import '../widgets/group_avatar.dart';
import 'group_chat_view.dart';
import 'member_picker_view.dart';

class CreateGroupView extends StatefulWidget {
  final String currentUserId;

  const CreateGroupView({super.key, required this.currentUserId});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  final GroupService _service = GroupService();
  final TextEditingController _nameController = TextEditingController();

  Uint8List? _photoBytes;
  List<String> _members = [];
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
    setState(() => _members = {..._members, ...result}.toList());
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'New group',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _nameCard(),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _membersCard(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- header

  Widget _header() {
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;
    final name = _nameController.text.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 6, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFFDBEAFE),
                    backgroundImage:
                        _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                    child: _photoBytes == null
                        ? const Icon(Icons.groups_rounded,
                            size: 48, color: _blue)
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 16, color: Colors.white),
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
            style: TextStyle(
              color: name.isEmpty ? Colors.white60 : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  // +1 because you are in the group too
                  '${_members.length + 1} members',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ cards

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  Widget _cardTitle(IconData icon, String title, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
          ),
        ),
        if (trailing != null) trailing,
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
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. Weekend plans',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _blue, width: 1.5),
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
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_members.length}',
                style: const TextStyle(
                    color: _blue, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // add members button
          Material(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _addMembers,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add members',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: _blue),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _blue),
                  ],
                ),
              ),
            ),
          ),

          if (_members.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Text(
                'No members yet. Add at least one person to create the group.',
                style: TextStyle(fontSize: 12.5, color: _muted),
              ),
            )
          else
            ..._members.map(
              (id) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    GroupAvatar(name: id, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: _ink),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFFEF4444)),
                      onPressed: () => _removeMember(id),
                    ),
                  ],
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
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
              backgroundColor: _blue,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: enabled ? 4 : 0,
              shadowColor: _blue.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: _creating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create group',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}