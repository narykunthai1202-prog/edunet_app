// lib/features/chat/services/group_message_ext.dart
// Adds reply / reactions / delete / unsend to GroupService
// WITHOUT editing group_service.dart.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'group_service.dart';

extension GroupMessageExt on GroupService {
  DocumentReference<Map<String, dynamic>> _gChat(String groupId) =>
      FirebaseFirestore.instance.collection('chats').doc(groupId);

  DocumentReference<Map<String, dynamic>> _gMsg(
    String groupId,
    String messageId,
  ) => _gChat(groupId).collection('messages').doc(messageId);

  /// Text message that quotes another message.
  Future<void> sendReply({
    required String groupId,
    required String senderId,
    required String text,
    required String replyToText,
    required String replyToSender,
    required List<String> participants,
  }) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final msgRef = _gChat(groupId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'type': 'text',
      'text': text,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
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
    batch.update(_gChat(groupId), updates);
    await batch.commit();
  }

  /// Add my emoji, or remove it if I already used the same one.
  Future<void> toggleReaction(
    String groupId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    final ref = _gMsg(groupId, messageId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final reactions = snap.data()?['reactions'];
    final current = reactions is Map ? reactions[userId] : null;

    if (current == emoji) {
      await ref.update({'reactions.$userId': FieldValue.delete()});
    } else {
      await ref.update({'reactions.$userId': emoji});
    }
  }

  /// "Delete for me": only hides it for this user.
  Future<void> deleteMessageForMe(
    String groupId,
    String messageId,
    String userId,
  ) => _gMsg(groupId, messageId).update({
    'deletedFor': FieldValue.arrayUnion([userId]),
  });

  /// Deletes the message for EVERYONE. It disappears completely
  /// (no "unsent" placeholder). If it was the newest message, the chat list
  /// preview is moved back to the message before it.
  Future<void> unsendGroupMessage(String groupId, String messageId) async {
    final msgs = _gChat(groupId).collection('messages');

    final before = await msgs
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    final wasLatest =
        before.docs.isNotEmpty && before.docs.first.id == messageId;

    await msgs.doc(messageId).delete();

    if (!wasLatest) return;

    // find the new newest message (ignore old "unsent" placeholders)
    final after = await msgs
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    Map<String, dynamic>? next;
    for (final d in after.docs) {
      if (d.data()['isUnsent'] != true) {
        next = d.data();
        break;
      }
    }

    if (next == null) {
      await _gChat(groupId).update({
        'lastMessage': '',
        'lastMessageSenderId': '',
      });
      return;
    }

    String preview;
    switch (next['type']) {
      case 'image':
        preview = '📷 Photo';
        break;
      case 'audio':
        preview = '🎤 Voice message';
        break;
      case 'sticker':
        preview = '🙂 Sticker';
        break;
      case 'file':
        final n = (next['fileName'] ?? 'File').toString();
        preview = '📎 $n';
        break;
      default:
        preview = (next['text'] ?? '').toString();
    }

    await _gChat(groupId).update({
      'lastMessage': preview,
      'lastMessageSenderId': next['senderId'] ?? '',
      if (next['timestamp'] != null) 'lastMessageTime': next['timestamp'],
    });
  }

  // ---------------------------------------------------------- typing / seen

  /// Typing flag stored on the group document: typing_{userId}: true/false
  Future<void> setGroupTyping(
    String groupId,
    String userId,
    bool typing,
  ) async {
    try {
      await _gChat(groupId).update({'typing_$userId': typing});
    } catch (_) {}
  }

  /// Adds [userId] to seenBy of each message.
  Future<void> markGroupSeen(
    String groupId,
    String userId,
    List<String> messageIds,
  ) async {
    for (final id in messageIds.take(50)) {
      try {
        await _gMsg(groupId, id).update({
          'seenBy': FieldValue.arrayUnion([userId]),
        });
      } catch (_) {}
    }
  }

  // ------------------------------------------------------------------- pin

  Future<void> pinGroupMessage(
    String groupId, {
    required String id,
    required String text,
    required String senderName,
  }) => _gChat(groupId).update({
    'pinnedMessage': {'id': id, 'text': text, 'senderName': senderName},
  });

  Future<void> unpinGroupMessage(String groupId) =>
      _gChat(groupId).update({'pinnedMessage': FieldValue.delete()});

  // -------------------------------------------------------------- mentions

  /// Text message that can carry @mentions and an optional quoted reply.
  Future<void> sendTextWithMentions({
    required String groupId,
    required String senderId,
    required String text,
    required List<String> mentions,
    required List<String> participants,
    String? replyToText,
    String? replyToSender,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final msgRef = _gChat(groupId).collection('messages').doc();
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
    batch.update(_gChat(groupId), updates);
    await batch.commit();
  }
}