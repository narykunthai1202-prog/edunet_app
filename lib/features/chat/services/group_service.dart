// lib/chat/services/group_service.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloudinary_service.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _chat(String id) =>
      _db.collection('chats').doc(id);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGroup(String id) =>
      _chat(id).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String id) =>
      _chat(id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();

  /// Uploads the group photo to Cloudinary and returns its URL.
  Future<String> _uploadPhoto(String groupId, Uint8List bytes) async {
    final url = await CloudinaryService.uploadBytes(
      bytes,
      'group_${DateTime.now().millisecondsSinceEpoch}.jpg',
      folder: 'group_photos/$groupId',
    );
    if (url == null) throw Exception('Photo upload failed');
    return url;
  }

  Future<String> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
    Uint8List? photoBytes,
  }) async {
    final ref = _db.collection('chats').doc();
    String? photoUrl;
    if (photoBytes != null) {
      photoUrl = await _uploadPhoto(ref.id, photoBytes);
    }
    final participants = <String>{creatorId, ...memberIds}.toList();

    await ref.set({
      'isGroup': true,
      'groupName': name,
      'groupPhotoUrl': photoUrl,
      'participants': participants,
      'adminIds': [creatorId],
      'createdBy': creatorId,
      'lastMessage': 'Group created',
      'lastMessageSenderId': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      for (final id in participants) 'unreadCount_$id': 0,
    });
    return ref.id;
  }

  Future<void> _logSystem(String groupId, String text) async {
    await _chat(groupId).collection('messages').add({
      'type': 'system',
      'text': text,
      'senderId': '',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _chat(groupId).update({
      'lastMessage': text,
      'lastMessageSenderId': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> renameGroup(String groupId, String newName, String byUser) async {
    await _chat(groupId).update({'groupName': newName});
    await _logSystem(groupId, '$byUser renamed the group to "$newName"');
  }

  Future<void> updatePhoto(
      String groupId, Uint8List bytes, String byUser) async {
    final url = await _uploadPhoto(groupId, bytes);
    await _chat(groupId).update({'groupPhotoUrl': url});
    await _logSystem(groupId, '$byUser changed the group photo');
  }

  Future<void> addMembers(
      String groupId, List<String> ids, String byUser) async {
    if (ids.isEmpty) return;
    await _chat(groupId).update({
      'participants': FieldValue.arrayUnion(ids),
      for (final id in ids) 'unreadCount_$id': 0,
    });
    await _logSystem(groupId, '$byUser added ${ids.join(', ')}');
  }

  Future<void> removeMember(String groupId, String userId, String byUser) async {
    await _chat(groupId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
    });
    await _logSystem(groupId, '$byUser removed $userId');
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    final snap = await _chat(groupId).get();
    final data = snap.data() ?? {};
    final participants = List<String>.from(data['participants'] ?? [])
      ..remove(userId);
    final admins = List<String>.from(data['adminIds'] ?? [])..remove(userId);

    // If the last admin leaves, promote the first remaining member.
    if (admins.isEmpty && participants.isNotEmpty) {
      admins.add(participants.first);
    }

    // Log first: after the update the user is no longer a participant
    // and may not be allowed to write to the group any more.
    if (participants.isNotEmpty) {
      await _logSystem(groupId, '$userId left the group');
    }
    await _chat(groupId).update({
      'participants': participants,
      'adminIds': admins,
      'typing_$userId': FieldValue.delete(),
    });
  }

  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String text,
    required List<String> participants,
  }) async {
    final batch = _db.batch();
    final msgRef = _chat(groupId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'type': 'text',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final updates = <String, dynamic>{
      'lastMessage': text,
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };
    for (final id in participants) {
      if (id != senderId) {
        updates['unreadCount_$id'] = FieldValue.increment(1);
      }
    }
    batch.update(_chat(groupId), updates);
    await batch.commit();
  }

  /// Text message with optional @mentions and an optional reply quote.
  Future<void> sendTextWithMentions({
    required String groupId,
    required String senderId,
    required String text,
    required List<String> mentions,
    required List<String> participants,
    String? replyToText,
    String? replyToSender,
  }) async {
    final batch = _db.batch();
    final msgRef = _chat(groupId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'type': 'text',
      'text': text,
      if (mentions.isNotEmpty) 'mentions': mentions,
      'replyToText': ?replyToText,
      'replyToSender': ?replyToSender,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final updates = <String, dynamic>{
      'lastMessage': text,
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };
    for (final id in participants) {
      if (id != senderId) {
        updates['unreadCount_$id'] = FieldValue.increment(1);
      }
    }
    batch.update(_chat(groupId), updates);
    await batch.commit();
  }

  /// Generic sender for non-text messages (image, audio, sticker, file, video...).
  /// [content] is stored in `text` (image/audio/file/video URL or sticker asset path),
  /// [preview] is what the chat list shows (e.g. '📷 Photo').
  /// [duration] is the length in seconds for voice messages.
  /// [fileName] and [fileSize] are used for file and video messages.
  Future<void> sendMedia({
    required String groupId,
    required String senderId,
    required String type,
    required String content,
    required String preview,
    required List<String> participants,
    int? duration,
    String? fileName,
    int? fileSize,
  }) async {
    final batch = _db.batch();
    final msgRef = _chat(groupId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'type': type,
      'text': content,
      'duration': ?duration,
      'fileName': ?fileName,
      'fileSize': ?fileSize,
      if (type == 'file' || type == 'video') 'fileUrl': content,
      if (type == 'video') 'videoUrl': content,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final updates = <String, dynamic>{
      'lastMessage': preview,
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };
    for (final id in participants) {
      if (id != senderId) {
        updates['unreadCount_$id'] = FieldValue.increment(1);
      }
    }
    batch.update(_chat(groupId), updates);
    await batch.commit();
  }

  /// Old method kept so other screens that call it still compile.
  /// Now uploads to Cloudinary instead of Firebase Storage.
  Future<void> sendImage({
    required String groupId,
    required String senderId,
    required Uint8List bytes,
    required List<String> participants,
  }) async {
    final url = await CloudinaryService.uploadBytes(
      bytes,
      'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
      folder: 'chat/$groupId',
    );
    if (url == null) throw Exception('Image upload failed');
    await sendMedia(
      groupId: groupId,
      senderId: senderId,
      type: 'image',
      content: url,
      preview: '📷 Photo',
      participants: participants,
    );
  }

  /// Sends an already-uploaded file (url from Cloudinary) to the group.
  Future<void> sendFile({
    required String groupId,
    required String senderId,
    required String url,
    required String name,
    required int size,
    required List<String> participants,
  }) =>
      sendMedia(
        groupId: groupId,
        senderId: senderId,
        type: 'file',
        content: url,
        preview: '📎 $name',
        participants: participants,
        fileName: name,
        fileSize: size,
      );

  /// Sends an already-uploaded video (url from Cloudinary) to the group.
  Future<void> sendVideo({
    required String groupId,
    required String senderId,
    required String url,
    required List<String> participants,
    String? fileName,
    int? fileSize,
  }) =>
      sendMedia(
        groupId: groupId,
        senderId: senderId,
        type: 'video',
        content: url,
        preview: '🎥 Video',
        participants: participants,
        fileName: fileName,
        fileSize: fileSize,
      );

  Future<void> sendSticker({
    required String groupId,
    required String senderId,
    required String stickerPath,
    required List<String> participants,
  }) =>
      sendMedia(
        groupId: groupId,
        senderId: senderId,
        type: 'sticker',
        content: stickerPath,
        preview: '🙂 Sticker',
        participants: participants,
      );

  Future<void> markRead(String groupId, String userId) =>
      _chat(groupId).update({'unreadCount_$userId': 0});

  // ------------------------------------------------------------------ block

  /// Personal block list, stored on the user's own doc as `blockedUsers`.
  Future<void> blockUser(String myId, String targetId) =>
      _db.collection('users').doc(myId).set({
        'blockedUsers': FieldValue.arrayUnion([targetId]),
      }, SetOptions(merge: true));

  Future<void> unblockUser(String myId, String targetId) =>
      _db.collection('users').doc(myId).set({
        'blockedUsers': FieldValue.arrayRemove([targetId]),
      }, SetOptions(merge: true));

  Stream<List<String>> watchBlocked(String myId) =>
      _db.collection('users').doc(myId).snapshots().map((d) {
        final raw = d.data()?['blockedUsers'];
        return raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
      });

  // ------------------------------------------------------------------ typing

  /// Stored on the group doc as `typing_<uid>: true/false`.
  Future<void> setGroupTyping(
      String groupId, String userId, bool typing) async {
    try {
      await _chat(groupId).update({'typing_$userId': typing});
    } catch (_) {}
  }

  // -------------------------------------------------------------------- pins

  Future<void> pinGroupMessage(
    String groupId, {
    required String id,
    required String text,
    required String senderName,
  }) =>
      _chat(groupId).update({
        'pinnedMessage': {
          'id': id,
          'text': text,
          'senderName': senderName,
          'pinnedAt': FieldValue.serverTimestamp(),
        },
      });

  Future<void> unpinGroupMessage(String groupId) =>
      _chat(groupId).update({'pinnedMessage': FieldValue.delete()});

  // -------------------------------------------------------------------- seen

  /// Adds [userId] to `seenBy` on each of the given messages.
  Future<void> markGroupSeen(
    String groupId,
    String userId,
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final id in messageIds) {
        batch.update(_chat(groupId).collection('messages').doc(id), {
          'seenBy': FieldValue.arrayUnion([userId]),
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  // --------------------------------------------------------------- reactions

  /// One reaction per user. Tapping the same emoji again removes it.
  Future<void> toggleReaction(
    String groupId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    final ref = _chat(groupId).collection('messages').doc(messageId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final reactions = snap.data()?['reactions'];
      final current = reactions is Map ? reactions[userId] : null;
      if (current == emoji) {
        tx.update(ref, {'reactions.$userId': FieldValue.delete()});
      } else {
        tx.update(ref, {'reactions.$userId': emoji});
      }
    });
  }

  // ---------------------------------------------------------- unsend / delete

  /// Builds the chat-list text for a raw message map.
  String _previewFor(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎙️ Voice message';
      case 'sticker':
        return '🙂 Sticker';
      case 'file':
        final name = (m['fileName'] ?? '').toString();
        return '📎 ${name.isEmpty ? 'File' : name}';
      case 'poll':
        return '📊 ${m['text'] ?? ''}';
      default:
        return (m['text'] ?? '').toString();
    }
  }

  /// Rewrites the chat-list preview from the newest message that is not
  /// unsent. Call it after "delete for everyone".
  Future<void> _refreshLastMessage(String groupId) async {
    try {
      final snap = await _chat(groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      Map<String, dynamic>? latest;
      for (final doc in snap.docs) {
        final m = doc.data();
        if (m['isUnsent'] == true) continue;
        if (m['isDeleted'] == true) continue;
        latest = m;
        break;
      }

      if (latest == null) {
        await _chat(groupId).update({
          'lastMessage': '',
          'lastMessageSenderId': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
        return;
      }

      await _chat(groupId).update({
        'lastMessage': _previewFor(latest),
        'lastMessageSenderId': latest['senderId'] ?? '',
        'lastMessageTime': latest['timestamp'] ?? FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Never let a preview refresh break the delete itself.
    }
  }

  /// "Delete for everyone". The chat screen hides messages with isUnsent == true.
  Future<void> unsendGroupMessage(String groupId, String messageId) async {
    await _chat(groupId).collection('messages').doc(messageId).update({
      'isUnsent': true,
      'text': '',
    });
    // Fix the chat-list preview so the unsent message no longer shows.
    await _refreshLastMessage(groupId);
  }

  /// "Delete for me". The chat screen filters out messages whose
  /// `deletedFor` list contains the current user.
  Future<void> deleteMessageForMe(
    String groupId,
    String messageId,
    String userId,
  ) =>
      _chat(groupId).collection('messages').doc(messageId).update({
        'deletedFor': FieldValue.arrayUnion([userId]),
      });

  // ------------------------------------------------------------------- polls

  Future<void> sendPoll({
    required String groupId,
    required String senderId,
    required String question,
    required List<String> options,
    required List<String> participants,
  }) async {
    final batch = _db.batch();
    final msgRef = _chat(groupId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'type': 'poll',
      'text': question,
      'pollOptions': options,
      'votes': <String, dynamic>{}, // uid -> option index
      'timestamp': FieldValue.serverTimestamp(),
    });

    final updates = <String, dynamic>{
      'lastMessage': '📊 $question',
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };
    for (final id in participants) {
      if (id != senderId) {
        updates['unreadCount_$id'] = FieldValue.increment(1);
      }
    }
    batch.update(_chat(groupId), updates);
    await batch.commit();
  }

  /// Cast or change a vote. Tapping your current choice removes the vote.
  Future<void> votePoll(
    String groupId,
    String messageId,
    String userId,
    int optionIndex,
  ) async {
    final ref = _chat(groupId).collection('messages').doc(messageId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final votes = snap.data()?['votes'];
      final current = votes is Map ? votes[userId] : null;
      if (current is num && current.toInt() == optionIndex) {
        tx.update(ref, {'votes.$userId': FieldValue.delete()});
      } else {
        tx.update(ref, {'votes.$userId': optionIndex});
      }
    });
  }
}