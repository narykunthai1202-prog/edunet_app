// lib/chat/views/group_info_view.dart
import 'dart:async';

import 'package:edunest_app/features/chat/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/group_service.dart';
import '../widgets/group_avatar.dart';
import '../widgets/shared_media_tabs.dart';
import 'member_picker_view.dart';

class GroupInfoView extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  const GroupInfoView({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  State<GroupInfoView> createState() => _GroupInfoViewState();
}

class _GroupInfoViewState extends State<GroupInfoView> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  final GroupService _service = GroupService();
  bool _busy = false;
  late final Stream<List<MessageModel>> _messagesStream;
  late final StreamSubscription _messagesSub;
  @override
  void initState() {
    super.initState();
    // The group's messages (chats/{groupId}/messages) for the
    // Media / Files / Links card.
    _messagesStream = _service.watchMessages(widget.groupId).map(
          (snap) => snap.docs
              .map((d) => MessageModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }
  @override
void dispose() {
  _messagesSub.cancel();
  super.dispose();
}

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --------------------------------------------------------------- actions

  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final bytes = await picked.readAsBytes();
      await _service.updatePhoto(widget.groupId, bytes, widget.currentUserId);
    } catch (e) {
      _toast('Failed to upload photo: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _editName(String current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit group name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == current) return;
    try {
      await _service.renameGroup(widget.groupId, newName, widget.currentUserId);
    } catch (e) {
      _toast('Failed to rename: $e');
    }
  }

  Future<void> _addMembers(List<String> existing) async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberPickerView(
          currentUserId: widget.currentUserId,
          excludeIds: existing,
        ),
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await _service.addMembers(widget.groupId, result, widget.currentUserId);
    } catch (e) {
      _toast('Failed to add members: $e');
    }
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave group?'),
        content:
            const Text('You will no longer receive messages from this group.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.leaveGroup(widget.groupId, widget.currentUserId);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _toast('Failed to leave: $e');
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
          'Group info',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _service.watchGroup(widget.groupId),
        builder: (context, snap) {
          final data = snap.data?.data();
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final name = (data['groupName'] ?? 'Group') as String;
          final photo = data['groupPhotoUrl'] as String?;
          final participants = List<String>.from(data['participants'] ?? []);
          final admins = List<String>.from(data['adminIds'] ?? []);
          final isAdmin = admins.contains(widget.currentUserId);

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(name, photo, participants),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SharedMediaTabs(
                  messages: _messagesStream,
                  currentUserId: widget.currentUserId,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _membersCard(participants, admins, isAdmin),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _leaveButton(),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- header

  Widget _header(String name, String? photo, List<String> participants) {
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 6, 20, 26),
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
          // avatar with white ring + camera button
          Stack(
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
                child: GroupAvatar(name: name, photoUrl: photo, radius: 52),
              ),
              if (_busy)
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _busy ? null : _changePhoto,
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
              ),
            ],
          ),
          const SizedBox(height: 14),

          // name + edit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_rounded,
                    size: 19, color: Colors.white70),
                onPressed: () => _editName(name),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // members chip
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
                  '${participants.length} members',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _action(Icons.person_add_alt_1_rounded, 'Add',
                  () => _addMembers(participants)),
              _action(Icons.photo_camera_rounded, 'Photo',
                  _busy ? null : _changePhoto),
              _action(Icons.edit_rounded, 'Rename', () => _editName(name)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- members

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

  Widget _membersCard(
      List<String> participants, List<String> admins, bool isAdmin) {
    // you first, then admins, then everybody else
    final sorted = [...participants]..sort((a, b) {
        int rank(String id) => id == widget.currentUserId
            ? 0
            : admins.contains(id)
                ? 1
                : 2;
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.compareTo(b);
      });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: const Icon(Icons.group_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Members',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${participants.length}',
                  style: const TextStyle(
                      color: _blue, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // add members button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _addMembers(participants),
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
          const SizedBox(height: 6),

          // member rows
          ...sorted.map((id) => _memberRow(id, admins, isAdmin)),
        ],
      ),
    );
  }

  Widget _memberRow(String id, List<String> admins, bool isAdmin) {
    final isMe = id == widget.currentUserId;
    final isMemberAdmin = admins.contains(id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GroupAvatar(name: id, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14.5, color: _ink),
                ),
                if (isMe)
                  const Text('You',
                      style: TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
          if (isMemberAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800),
              ),
            ),
          if (isAdmin && !isMe)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove from group',
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  color: Color(0xFFEF4444)),
              onPressed: () => _service.removeMember(
                  widget.groupId, id, widget.currentUserId),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ leave

  Widget _leaveButton() {
    return Material(
      color:Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _leave,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                'Leave group',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}