import 'package:edunest_app/features/chat/widgets/chat_options_sheet.dart';
import 'package:edunest_app/features/chat/widgets/chat_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_view.dart';
import 'create_group_view.dart';
import 'group_chat_view.dart';

class ChatListView extends StatefulWidget {
  final String currentUserId;

  const ChatListView({super.key, required this.currentUserId});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView>
    with WidgetsBindingObserver {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _activeTab = 'All'; // 'All', 'Unread', 'Favorites'

  @override
  void initState() {
    super.initState();

    // You are "online" while the app is open on this screen
    WidgetsBinding.instance.addObserver(this);
    _chatService.updateUserPresence(widget.currentUserId, true);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatService.updateUserPresence(widget.currentUserId, true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _chatService.updateUserPresence(widget.currentUserId, false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatService.updateUserPresence(widget.currentUserId, false);
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  String _buildChatId(String otherId) {
    final ids = [widget.currentUserId, otherId]..sort();
    return ids.join('_');
  }

  String _targetId(Map<String, dynamic> chatData) {
    final List participants = chatData['participants'] ?? [];
    return participants.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => widget.currentUserId,
    ) as String;
  }

  bool _isGroup(Map<String, dynamic> d) => d['isGroup'] == true;

  /// Groups use their document id; 1-to-1 chats use the sorted user ids.
  String _chatIdFor(String docId, Map<String, dynamic> d) =>
      _isGroup(d) ? docId : _buildChatId(_targetId(d));

  String _nameFor(Map<String, dynamic> d) => _isGroup(d)
      ? (d['groupName'] ?? 'Group') as String
      : (d['receiverName'] ?? _targetId(d)) as String;

  int _unreadOf(Map<String, dynamic> d) =>
      ((d['unreadCount_${widget.currentUserId}'] ?? 0) as num).toInt();

  /// Builds the text shown under each chat in the list.
  /// Sticker/photo previews depend on who sent the last message.
  String _previewText({
    required String lastMessage,
    required String lastSenderId,
    required String otherUserName,
  }) {
    final isMine = lastSenderId == widget.currentUserId;

    if (lastMessage == 'You sent a sticker') {
      return isMine
          ? 'You sent a sticker'
          : '$otherUserName sent you a sticker';
    }
    if (lastMessage == 'You sent a photo') {
      return isMine ? 'You sent a photo' : '$otherUserName sent you a photo';
    }
    return lastMessage;
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: StreamBuilder<Map<String, Map<String, dynamic>>>(
              stream: _chatService.watchChatSettings(widget.currentUserId),
              builder: (context, settingsSnap) {
                final settings = settingsSnap.data ?? {};

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants',
                          arrayContains: widget.currentUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chatDocs = snapshot.data?.docs ?? [];

                    // Every chat that was not deleted (used for the counts)
                    final base = chatDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final s = settings[_chatIdFor(doc.id, data)] ??
                          <String, dynamic>{};
                      return s['deleted'] != true;
                    }).toList();

                    final unreadChats = base
                        .where((d) =>
                            _unreadOf(d.data() as Map<String, dynamic>) > 0)
                        .length;
                    final favoriteChats = base.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return settings[_chatIdFor(d.id, data)]?['favorite'] ==
                          true;
                    }).length;

                    // Filter by search + active tab
                    final visible = base.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final targetUserId =
                          _isGroup(data) ? '' : _targetId(data);
                      final chatId = _chatIdFor(doc.id, data);
                      final s = settings[chatId] ?? <String, dynamic>{};

                      final String realName = _nameFor(data);
                      final String nick =
                          ((s['nickname'] as String?) ?? '').trim();

                      // Search matches nickname, real name, or user id
                      if (_searchQuery.isNotEmpty &&
                          !realName.toLowerCase().contains(_searchQuery) &&
                          !targetUserId.toLowerCase().contains(_searchQuery) &&
                          !nick.toLowerCase().contains(_searchQuery)) {
                        return false;
                      }
                      if (_activeTab == 'Favorites' && s['favorite'] != true) {
                        return false;
                      }
                      if (_activeTab == 'Unread' && _unreadOf(data) == 0) {
                        return false;
                      }
                      return true;
                    }).toList();

                    // Sort: pinned first, then most recent
                    visible.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aPinned =
                          settings[_chatIdFor(a.id, aData)]?['pinned'] == true
                              ? 0
                              : 1;
                      final bPinned =
                          settings[_chatIdFor(b.id, bData)]?['pinned'] == true
                              ? 0
                              : 1;
                      if (aPinned != bPinned) return aPinned.compareTo(bPinned);

                      final aTime = aData['lastMessageTime'] as Timestamp?;
                      final bTime = bData['lastMessageTime'] as Timestamp?;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime);
                    });

                    return Column(
                      children: [
                        _chips(base.length, unreadChats, favoriteChats),
                        Expanded(
                          child: _content(
                            allEmpty: base.isEmpty,
                            visible: visible,
                            settings: settings,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- header

  Widget _header() {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 10, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.currentUserId,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'New group',
                child: Material(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateGroupView(
                            currentUserId: widget.currentUserId),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.group_add_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // search bar
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search chats...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, color: _blue),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 19, color: _muted),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ chips

  Widget _chips(int all, int unread, int favorites) {
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        children: [
          _chip('All', 0),
          const SizedBox(width: 8),
          _chip('Unread', unread),
          const SizedBox(width: 8),
          _chip('Favorites', 0),
        ],
      ),
    );
  }

  Widget _chip(String label, int count) {
    final selected = _activeTab == label;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _blue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _muted,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : _blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- content

  Widget _empty(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: _blue),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _muted)),
        ],
      ),
    );
  }

  Widget _content({
    required bool allEmpty,
    required List<QueryDocumentSnapshot> visible,
    required Map<String, Map<String, dynamic>> settings,
  }) {
    if (allEmpty) {
      return _empty(
        Icons.chat_bubble_outline_rounded,
        'No conversations yet',
        'Start chatting with a friend or\ncreate a group with the button above.',
      );
    }
    if (visible.isEmpty) {
      return _empty(
        Icons.search_off_rounded,
        'No chats found',
        _searchQuery.isNotEmpty
            ? 'Nothing matches "$_searchQuery".'
            : 'There are no chats in this filter.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: visible.length,
      itemBuilder: (context, i) => _buildTile(visible[i], settings),
    );
  }

  Widget _buildTile(
    QueryDocumentSnapshot doc,
    Map<String, Map<String, dynamic>> settings,
  ) {
    final chatData = doc.data() as Map<String, dynamic>;
    final bool isGroup = _isGroup(chatData);
    final String groupId = doc.id;
    final targetUserId = isGroup ? '' : _targetId(chatData);
    final chatId = _chatIdFor(groupId, chatData);
    final s = settings[chatId] ?? <String, dynamic>{};

    // Real name + optional nickname
    final String realName = _nameFor(chatData);
    final String nick = ((s['nickname'] as String?) ?? '').trim();
    final String displayName = nick.isNotEmpty ? nick : realName;

    // Preview text (handles "user1 sent you a sticker")
    final String rawLastMessage =
        chatData['lastMessage'] ?? 'No messages yet';
    final String lastSenderId =
        (chatData['lastMessageSenderId'] ?? '') as String;
    final String lastMessage = isGroup
        ? (lastSenderId.isEmpty
            ? rawLastMessage
            : '${lastSenderId == widget.currentUserId ? 'You' : lastSenderId}: $rawLastMessage')
        : _previewText(
            lastMessage: rawLastMessage,
            lastSenderId: lastSenderId,
            otherUserName: displayName,
          );

    final DateTime? lastTime =
        (chatData['lastMessageTime'] as Timestamp?)?.toDate();

    return ChatTile(
      displayName: displayName,
      photoUrl: isGroup ? chatData['groupPhotoUrl'] as String? : null,
      lastMessage: lastMessage,
      lastMessageTime: lastTime,
      unreadCount: _unreadOf(chatData),
      isPinned: s['pinned'] == true,
      isFavorite: s['favorite'] == true,
      isMuted: s['muted'] == true,
      peerId: isGroup ? null : targetUserId,
      onTap: () {
        if (isGroup) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupChatView(
                groupId: groupId,
                currentUserId: widget.currentUserId,
              ),
            ),
          );
          return;
        }
        _chatService.markAsRead(widget.currentUserId, targetUserId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatView(
              currentUserId: widget.currentUserId,
              receiverId: targetUserId,
              receiverName: realName,
              chatId: chatId,
              peerId: targetUserId,
            ),
          ),
        );
      },
      onLongPress: () => showChatOptions(
        context,
        currentUserId: widget.currentUserId,
        chatId: chatId,
        title: displayName,
        settings: s,
      ),
    );
  }
}