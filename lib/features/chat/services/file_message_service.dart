import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

const cloudName = 'ox7jq6oz';
const uploadPreset = 'chat_unsigned';
const maxFileBytes = 10 * 1024 * 1024;

Future<String> _uploadToCloudinary(Uint8List bytes, String filename) async {
  final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
  final req = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset;
  req.files.add(
    http.MultipartFile.fromBytes('file', bytes, filename: filename),
  );

  final res = await req.send();
  final body = await res.stream.bytesToString();
  if (res.statusCode != 200) {
    throw Exception('Upload failed: $body');
  }
  return jsonDecode(body)['secure_url'] as String;
}

Future<void> sendFileMessage({
  required String chatId,   // 1-to-1 chat id OR group id
  required String senderId,
  required bool isGroup,
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

  await chatRef.collection('messages').add({
    'type': 'file',
    'senderId': senderId,
    'fileUrl': url,
    'fileName': picked.name,
    'fileSize': bytes.length,
    'mimeType': mime,
    'isGroup': isGroup,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await chatRef.update({
    'lastMessage': '📎 ${picked.name}',
    'lastMessageAt': FieldValue.serverTimestamp(),
  });
}