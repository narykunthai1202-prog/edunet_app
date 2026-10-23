import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/chat/widgets/chat_palette.dart';
import 'package:edunest_app/features/chat/views/chat_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewChatView extends StatefulWidget {
  final String currentUserId;

  const NewChatView({super.key, required this.currentUserId});

  @override
  State<NewChatView> createState() => _NewChatViewState();
}

class _NewChatViewState extends State<NewChatView> {
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;
  String? _activeUserId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeUserId = FirebaseAuth.instance.currentUser?.uid;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) setState(() => _activeUserId = user?.uid);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startChat(
    String currentUserId,
    String receiverId,
    String receiverName,
  ) {
    final ids = [currentUserId, receiverId]..sort();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatView(
          currentUserId: currentUserId,
          receiverId: receiverId,
          receiverName: receiverName,
          chatId: ids.join('_'),
          peerId: receiverId,
        ),
      ),
    );
  }

  String _displayName(Map<String, dynamic> data) {
    final name = data['name']?.toString().trim();
    return name == null || name.isEmpty ? 'User' : name;
  }

  String? _username(Map<String, dynamic> data) {
    for (final key in const ['username', 'userName']) {
      final username = data[key]?.toString().trim();
      if (username != null && username.isNotEmpty) {
        return username.startsWith('@') ? username : '@$username';
      }
    }
    return null;
  }

  Widget _header() {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 20),
      decoration: const BoxDecoration(
        gradient: ChatPalette.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New message',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Start a conversation with a friend',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
            style: const TextStyle(
              color: ChatPalette.ink,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Search friends or usernames',
              hintStyle: const TextStyle(color: ChatPalette.muted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: ChatPalette.plum,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: ChatPalette.muted,
                        size: 19,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: ChatPalette.surface,
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

  Widget _emptyFriends({required bool hasFriends}) {
    final title = hasFriends
        ? 'No friends found'
        : 'Your chat list starts here';
    final subtitle = hasFriends
        ? 'Try another name or username.'
        : 'Follow each other to become friends and start chatting.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: ChatPalette.rose.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 34,
                color: ChatPalette.plum,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ChatPalette.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ChatPalette.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _activeUserId;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: ChatPalette.canvas,
        appBar: AppBar(
          backgroundColor: ChatPalette.canvas,
          title: const Text('New message'),
        ),
        body: const Center(child: Text('Please sign in to start a chat.')),
      );
    }

    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);

    return Scaffold(
      backgroundColor: ChatPalette.canvas,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: currentUserRef.snapshots(),
              builder: (context, currentUserSnapshot) {
                if (currentUserSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load friends: ${currentUserSnapshot.error}',
                    ),
                  );
                }
                if (currentUserSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentUserData = currentUserSnapshot.data?.data();
                if (currentUserData == null) {
                  return const Center(
                    child: Text('Your account profile could not be found.'),
                  );
                }
                final followingIds =
                    (currentUserData['following'] as List<dynamic>? ?? [])
                        .whereType<String>()
                        .toSet();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('following', arrayContains: currentUserId)
                      .snapshots(),
                  builder: (context, friendsSnapshot) {
                    if (friendsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load friends: ${friendsSnapshot.error}',
                        ),
                      );
                    }
                    if (friendsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final friends =
                        friendsSnapshot.data!.docs
                            .where((friend) {
                              return friend.id != currentUserId &&
                                  followingIds.contains(friend.id);
                            })
                            .where((friend) {
                              final data = friend.data();
                              final name = _displayName(data).toLowerCase();
                              final username =
                                  _username(data)?.toLowerCase() ?? '';
                              return _searchQuery.isEmpty ||
                                  name.contains(_searchQuery) ||
                                  username.contains(_searchQuery);
                            })
                            .toList()
                          ..sort((a, b) {
                            final nameA = _displayName(a.data());
                            final nameB = _displayName(b.data());
                            return nameA.toLowerCase().compareTo(
                              nameB.toLowerCase(),
                            );
                          });

                    if (friends.isEmpty) {
                      return _emptyFriends(hasFriends: followingIds.isNotEmpty);
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Your friends',
                                  style: TextStyle(
                                    color: ChatPalette.ink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: ChatPalette.rose.withValues(
                                    alpha: 0.35,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${friends.length}',
                                  style: const TextStyle(
                                    color: ChatPalette.plum,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                            itemCount: friends.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 9),
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              final friendData = friend.data();
                              final name = _displayName(friendData);
                              final username = _username(friendData);
                              final photoUrl = friendData['profileImageUrl']
                                  ?.toString()
                                  .trim();
                              final hasPhoto =
                                  photoUrl != null && photoUrl.isNotEmpty;

                              return Material(
                                color: ChatPalette.surface,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _startChat(
                                    currentUserId,
                                    friend.id,
                                    name,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor: ChatPalette.rose
                                              .withValues(alpha: 0.35),
                                          backgroundImage: hasPhoto
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: hasPhoto
                                              ? null
                                              : Text(
                                                  name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: ChatPalette.plum,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 13),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: ChatPalette.ink,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                username ??
                                                    'Tap to start chatting',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: ChatPalette.muted,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: ChatPalette.rose.withValues(
                                              alpha: 0.28,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.chat_bubble_rounded,
                                            color: ChatPalette.plum,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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
}
