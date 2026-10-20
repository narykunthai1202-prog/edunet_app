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

    await _chat(groupId).update({
      'participants': participants,
      'adminIds': admins,
    });
    if (participants.isNotEmpty) {
      await _logSystem(groupId, '$userId left the group');
    }
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

  /// Generic sender for non-text messages (image, audio, sticker, file...).
  /// [content] is stored in `text` (image/audio/file URL or sticker asset path),
  /// [preview] is what the chat list shows (e.g. '📷 Photo').
  /// [duration] is the length in seconds for voice messages.
  /// [fileName] and [fileSize] are only used for file messages.
  Future<void> sendMedia({
    required String groupId,
    required String senderId,
    required String type,
    required String content,
    required String preview,
    required List<String> participants,
    int? duration,
    String? fileName, // NEW
    int? fileSize, // NEW
  }) async {
    final batch = _db.batch();
    final msgRef = _chat(groupId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'type': type,
      'text': content,
      if (duration != null) 'duration': duration,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (type == 'file') 'fileUrl': content,
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

  /// NEW: sends an already-uploaded file (url from Cloudinary) to the group.
  /// Goes through sendMedia, so the chat list "last message" and the unread
  /// counters are updated like every other message type.
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
}