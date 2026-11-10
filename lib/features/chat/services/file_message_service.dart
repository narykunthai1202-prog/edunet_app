import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

const cloudName = 'ox7jq6oz';
const uploadPreset = 'chat_unsigned';
const maxFileBytes = 10 * 1024 * 1024;

Future<String> _uploadToCloudinary(Uint8List bytes, String filename) async {
  final uri =
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
  final req = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset;
  req.files.add(
    http.MultipartFile.fromBytes('file', bytes, filename: filename),
  );

  final res = await req.send().timeout(const Duration(seconds: 60));
  final body = await res.stream.bytesToString();
  if (res.statusCode != 200) {
    throw Exception('Upload failed: $body');
  }
  return jsonDecode(body)['secure_url'] as String;
}

/// Picks a file, uploads it to Cloudinary and saves the message.
///
/// 1-to-1 chat: pass chatId = getChatRoomId(me, other) AND receiverId = other.
/// Group chat:  pass chatId = group id, isGroup = true (receiverId not needed).
Future<void> sendFileMessage({
  required String chatId,
  required String senderId,
  required bool isGroup,
  String? receiverId,
}) async {
  final picked = await FilePicker.pickFile();
  if (picked == null) return;

  final size = await picked.length();
  if (size != null && size > maxFileBytes) {
    throw Exception('File too large (max 10 MB)');
  }

  final bytes = await picked.readAsBytes();
  if (bytes.length > maxFileBytes) {
    throw Exception('File too large (max 10 MB)');
  }

  final url = await _uploadToCloudinary(bytes, picked.name);
  final mime = lookupMimeType(picked.name) ?? 'application/octet-stream';

  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  // 1. The message. Same fields as text/image messages, so the chat screen
  //    and the Files tab can read it.
  await chatRef.collection('messages').add({
    'type': 'file',
    'senderId': senderId,
    'receiverId': ?receiverId,
    'text': url, // kept for old code that reads "text"
    'fileUrl': url,
    'fileName': picked.name,
    'fileSize': bytes.length,
    'mimeType': mime,
    'isGroup': isGroup,
    'status': 'sent',
    'timestamp': FieldValue.serverTimestamp(), // chat screen orders by this
    'createdAt': FieldValue.serverTimestamp(),
    'isSeen': false,
    'reactions': {},
    'isDeleted': false,
    'isForwarded': false,
  });

  // 2. The chat list preview. set(merge) works even if the chat doc
  //    does not exist yet (update() would throw).
  await chatRef.set({
    if (!isGroup && receiverId != null) 'participants': [senderId, receiverId],
    'lastMessage': '📎 ${picked.name}',
    'lastMessageTime': FieldValue.serverTimestamp(),
    'lastMessageAt': FieldValue.serverTimestamp(),
    'lastSenderId': senderId,
    if (!isGroup && receiverId != null)
      'unreadCount_$receiverId': FieldValue.increment(1),
  }, SetOptions(merge: true));
}