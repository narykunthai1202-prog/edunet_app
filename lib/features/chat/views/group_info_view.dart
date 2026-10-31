// lib/chat/views/group_info_view.dart
import 'dart:async';

import 'package:edunest_app/features/chat/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
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
  // 🎨 Screen colors (edit here to restyle the whole screen)
  static const _plum = Color(0xFF6B4A5B); // main accent
  static const _rose = Color(0xFFE0BCC4); // dusty rose
  static const _card = Color(0xFFEEE8E7); // card / dialog surface
  static const _border = Color(0xFFDDD2CF); // card border
  static const _field = Color(0xFFE5DFDC); // inputs, cancel buttons, rows
  static const _ring = Color(0xFFF3EDEB); // avatar ring
  static const _textDark = Color(0xFF3A2A32); // dark plum-brown text
  static const _muted = Color(0xFF7A6670); // muted text
  static const _danger = Color(0xFFC2674B); // leave / remove (terracotta)

  final GroupService _service = GroupService();
  bool _busy = false;
  late final Stream<List<MessageModel>> _messagesStream;

  // Member profiles (users/{uid}) cached by uid
  final Map<String, Map<String, dynamic>> _profiles = {};
  final Set<String> _requested = {};

  // Users I blocked (personal block list)
  Set<String> _blocked = {};
  StreamSubscription<List<String>>? _blockSub;

  // Used to give the app bar a background once content scrolls under it
  final ScrollController _scrollController = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    // The group's messages (chats/{groupId}/messages) for the
    // Media / Files / Links card.
    _messagesStream = _service
        .watchMessages(widget.groupId)
        .map(
          (snap) => snap.docs
              .map((d) => MessageModel.fromMap(d.data(), d.id))
              .where((m) => !m.isHiddenFor(widget.currentUserId))
              .toList(),
        );

    _blockSub = _service.watchBlocked(widget.currentUserId).listen((ids) {
      if (mounted) setState(() => _blocked = ids.toSet());
    });

    _scrollController.addListener(() {
      final scrolled = _scrollController.hasClients &&
          _scrollController.offset > 80;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _blockSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -------------------------------------------------------------- profiles

  /// Loads users/{uid} for every id not requested yet (whereIn max = 10).
  Future<void> _loadProfiles(List<String> ids) async {
    final missing = ids.where((id) => !_requested.contains(id)).toList();
    if (missing.isEmpty) return;
    _requested.addAll(missing);

    try {
      for (var i = 0; i < missing.length; i += 10) {
        final chunk = missing.sublist(
          i,
          i + 10 > missing.length ? missing.length : i + 10,
        );
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          _profiles[doc.id] = doc.data();
        }
      }
    } catch (e) {
      // permission-denied etc. shows up here
      debugPrint('Failed to load member profiles: $e');
    }
    if (mounted) setState(() {});
  }

  /// Display name for a uid. Tries a few common field names.
  String _nameFor(String id) {
    final p = _profiles[id];
    if (p == null) return 'Loading...';
    for (final key in const ['name', 'username', 'displayName']) {
      final v = p[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return 'Unknown user';
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

  ButtonStyle get _cancelStyle => TextButton.styleFrom(
    backgroundColor: _field,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  Future<void> _editName(String current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _rose.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: _plum,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit group name',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 40,
                cursorColor: _plum,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _field,
                  counterStyle: const TextStyle(color: _muted),
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: _cancelStyle,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _plum,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  /// Block / unblock a member (personal: hides their messages for me).
  Future<void> _toggleBlock(String id) async {
    final wasBlocked = _blocked.contains(id);
    final name = _nameFor(id);
    try {
      if (wasBlocked) {
        await _service.unblockUser(widget.currentUserId, id);
        _toast('Unblocked $name');
      } else {
        await _service.blockUser(widget.currentUserId, id);
        _toast('Blocked $name');
      }
    } catch (e) {
      _toast('Failed: $e');
    }
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: _danger, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                'Leave group?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You will no longer receive messages from this group.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: _muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: _cancelStyle,
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Leave',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textDark,
        centerTitle: true,
        // Solid background fades in once content scrolls under the bar,
        // so the title no longer overlaps the cards.
        flexibleSpace: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: _scrolled ? colors.surface : Colors.transparent,
        ),
        title: Text(
          'Group info',
          style: GoogleFonts.nunito(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _service.watchGroup(widget.groupId),
        builder: (context, snap) {
          final data = snap.data?.data();
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(color: _plum),
            );
          }

          final name = (data['groupName'] ?? 'Group') as String;
          final photo = data['groupPhotoUrl'] as String?;
          final participants = List<String>.from(data['participants'] ?? []);
          final admins = List<String>.from(data['adminIds'] ?? []);
          final isAdmin = admins.contains(widget.currentUserId);

          // Fetch profiles for any members we haven't loaded yet
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _loadProfiles(participants),
          );

          return ListView(
            controller: _scrollController,
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
              // Every member (and admin) can leave.
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
          colors: [Color(0xFFF2E2E6), _rose, Color(0xFFD3A9B4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          // avatar with soft ring + camera button
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _ring,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _plum.withValues(alpha: 0.18),
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
                  style: GoogleFonts.nunito(
                    color: _textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_rounded, size: 19, color: _plum),
                onPressed: () => _editName(name),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // members chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_rounded, size: 16, color: _plum),
                const SizedBox(width: 6),
                Text(
                  '${participants.length} members',
                  style: GoogleFonts.nunito(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _action(
                Icons.person_add_alt_1_rounded,
                'Add',
                () => _addMembers(participants),
              ),
              _action(
                Icons.photo_camera_rounded,
                'Photo',
                _busy ? null : _changePhoto,
              ),
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
              color: Colors.white.withValues(alpha: 0.65),
              shape: BoxShape.circle,
              border: Border.all(
                color: _plum.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(icon, color: _plum, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: _textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- members

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

  Widget _membersCard(
    List<String> participants,
    List<String> admins,
    bool isAdmin,
  ) {
    // you first, then admins, then everybody else (alphabetical by name)
    final sorted = [...participants]
      ..sort((a, b) {
        int rank(String id) => id == widget.currentUserId
            ? 0
            : admins.contains(id)
            ? 1
            : 2;
        final r = rank(a).compareTo(rank(b));
        return r != 0
            ? r
            : _nameFor(a).toLowerCase().compareTo(_nameFor(b).toLowerCase());
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _rose.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_rounded, color: _plum, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Members',
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _rose.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${participants.length}',
                  style: const TextStyle(
                    color: _plum,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // add members button
          Material(
            color: _field,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _addMembers(participants),
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
    final isBlocked = _blocked.contains(id);
    final displayName = _nameFor(id);
    final photoUrl = _profiles[id]?['profileImageUrl']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GroupAvatar(
            name: displayName,
            photoUrl: (photoUrl == null || photoUrl.isEmpty) ? null : photoUrl,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _textDark,
                  ),
                ),
                if (isMe)
                  Text(
                    'You',
                    style: GoogleFonts.nunito(fontSize: 12.5, color: _muted),
                  )
                else if (isBlocked)
                  Text(
                    'Blocked',
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _danger,
                    ),
                  ),
              ],
            ),
          ),
          if (isMemberAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _rose.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Admin',
                style: GoogleFonts.nunito(
                  color: _plum,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          // Block / unblock: every member and admin can do this.
          if (!isMe)
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert_rounded, color: _muted),
              onSelected: (_) => _toggleBlock(id),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(isBlocked ? 'Unblock' : 'Block'),
                ),
              ],
            ),
          if (isAdmin && !isMe)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove from group',
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: _danger,
              ),
              onPressed: () => _service.removeMember(
                widget.groupId,
                id,
                widget.currentUserId,
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ leave

  Widget _leaveButton() {
    return Material(
      color: _danger.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _leave,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _danger.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: _danger, size: 20),
              const SizedBox(width: 8),
              Text(
                'Leave group',
                style: GoogleFonts.nunito(
                  color: _danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}