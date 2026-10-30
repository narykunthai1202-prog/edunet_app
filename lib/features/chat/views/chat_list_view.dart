import 'dart:async';

import 'package:edunest_app/features/chat/widgets/chat_options_sheet.dart';
import 'package:edunest_app/features/chat/widgets/chat_palette.dart';
import 'package:edunest_app/features/chat/widgets/chat_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import 'chat_view.dart';
import 'create_group_view.dart';
import 'group_chat_view.dart';
import 'new_chat_view.dart';

class ChatListView extends StatefulWidget {
  final String currentUserId;

  const ChatListView({super.key, required this.currentUserId});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView>
    with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;
  String? _activeUserId;

  String _searchQuery = '';
  String _activeTab = 'All'; // 'All', 'Unread', 'Favorites'
  String get _currentUserId => _activeUserId ?? '';

  @override
  void initState() {
    super.initState();

    // You are "online" while the app is open on this screen
    WidgetsBinding.instance.addObserver(this);
    _activeUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_activeUserId != null) {
      _chatService.updateUserPresence(_activeUserId!, true);
    }
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      final previousUserId = _activeUserId;
      if (previousUserId != null && previousUserId != user?.uid) {
        _chatService.updateUserPresence(previousUserId, false);
      }
      _activeUserId = user?.uid;
      if (_activeUserId != null) {
        _chatService.updateUserPresence(_activeUserId!, true);
      }
      if (mounted) setState(() {});
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_currentUserId.isNotEmpty) {
        _chatService.updateUserPresence(_currentUserId, true);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_currentUserId.isNotEmpty) {
        _chatService.updateUserPresence(_currentUserId, false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    if (_currentUserId.isNotEmpty) {
      _chatService.updateUserPresence(_currentUserId, false);
    }
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  String _buildChatId(String otherId) {
    final ids = [_currentUserId, otherId]..sort();
    return ids.join('_');
  }

  String _targetId(Map<String, dynamic> chatData) {
    final List participants = chatData['participants'] ?? [];
    return participants.firstWhere(
      (id) => id != _currentUserId,
      orElse: () => _currentUserId,
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
      ((d['unreadCount_$_currentUserId'] ?? 0) as num).toInt();

  /// Builds the text shown under each chat in the list.
  /// Sticker/photo previews depend on who sent the last message.
  String _previewText({
    required String lastMessage,
    required String lastSenderId,
    required String otherUserName,
  }) {
    final isMine = lastSenderId == _currentUserId;

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
    final palette = ChatPalette.of(context);

    if (_currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view chats.')),
      );
    }

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: StreamBuilder<Map<String, Map<String, dynamic>>>(
              stream: _chatService.watchChatSettings(_currentUserId),
              builder: (context, settingsSnap) {
                final settings = settingsSnap.data ?? {};

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: _currentUserId)
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
                      final s =
                          settings[_chatIdFor(doc.id, data)] ??
                          <String, dynamic>{};
                      return s['deleted'] != true;
                    }).toList();

                    final unreadChats = base
                        .where(
                          (d) =>
                              _unreadOf(d.data() as Map<String, dynamic>) > 0,
                        )
                        .length;
                    final favoriteChats = base.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return settings[_chatIdFor(d.id, data)]?['favorite'] ==
                          true;
                    }).length;

                    // Filter by search + active tab
                    final visible = base.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final targetUserId = _isGroup(data)
                          ? ''
                          : _targetId(data);
                      final chatId = _chatIdFor(doc.id, data);
                      final s = settings[chatId] ?? <String, dynamic>{};

                      final String realName = _nameFor(data);
                      final String nick = ((s['nickname'] as String?) ?? '')
                          .trim();

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
    final palette = ChatPalette.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 10, 20, 16),
      decoration: BoxDecoration(
        gradient: palette.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .snapshots(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data?.data();
          final userName = profile?['name']?.toString().trim();
          final photoUrl = profile?['profileImageUrl']?.toString().trim();
          final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

          return Column(
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
                          userName == null || userName.isEmpty
                              ? 'Your conversations'
                              : 'Welcome back, $userName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPhoto) ...[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      backgroundImage: NetworkImage(photoUrl),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Tooltip(
                    message: 'New message',
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NewChatView(currentUserId: _currentUserId),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.edit_square,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                            builder: (_) =>
                                CreateGroupView(currentUserId: _currentUserId),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.group_add_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 15, color: palette.ink),
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(color: palette.muted),
                  prefixIcon: Icon(Icons.search_rounded, color: palette.plum),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: palette.muted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: palette.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          );
        },
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
          _chip('All', all),
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
    final palette = ChatPalette.of(context);

    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.plum : palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? palette.plum : palette.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.plum.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? palette.onSelected : palette.ink,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? palette.onSelected : palette.plum,
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
    final palette = ChatPalette.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: palette.unreadSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: palette.plum),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 9),
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
    final String storedName = _nameFor(chatData);
    final String nick = ((s['nickname'] as String?) ?? '').trim();

    // Preview text (handles "user1 sent you a sticker")
    final String rawLastMessage = chatData['lastMessage'] ?? 'No messages yet';
    final String lastSenderId =
        (chatData['lastMessageSenderId'] ?? '') as String;
    final DateTime? lastTime = (chatData['lastMessageTime'] as Timestamp?)
        ?.toDate();

    Widget buildTile({required String realName, required String? photoUrl}) {
      final displayName = nick.isNotEmpty ? nick : realName;
      final lastMessage = isGroup
          ? (lastSenderId.isEmpty
                ? rawLastMessage
                : '${lastSenderId == _currentUserId ? 'You' : lastSenderId}: $rawLastMessage')
          : _previewText(
              lastMessage: rawLastMessage,
              lastSenderId: lastSenderId,
              otherUserName: displayName,
            );

      return ChatTile(
        displayName: displayName,
        photoUrl: photoUrl,
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
                  currentUserId: _currentUserId,
                ),
              ),
            );
            return;
          }
          _chatService.markAsRead(_currentUserId, targetUserId);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatView(
                currentUserId: _currentUserId,
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
          currentUserId: _currentUserId,
          chatId: chatId,
          title: displayName,
          settings: s,
        ),
      );
    }

    if (isGroup) {
      return buildTile(
        realName: storedName,
        photoUrl: chatData['groupPhotoUrl'] as String?,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .snapshots(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data?.data();
        final profileName = profile?['name']?.toString().trim();
        final fallbackName = storedName.trim();
        final realName =
            profileName != null &&
                profileName.isNotEmpty &&
                profileName != targetUserId
            ? profileName
            : fallbackName.isNotEmpty && fallbackName != targetUserId
            ? fallbackName
            : 'User';
        final photoUrl = profile?['profileImageUrl']?.toString().trim();
        return buildTile(
          realName: realName,
          photoUrl: photoUrl == null || photoUrl.isEmpty ? null : photoUrl,
        );
      },
    );
  }
}
