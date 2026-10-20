import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Result of picking + uploading a file.
class UploadedFile {
  final String url;
  final String name;
  final int size;
  const UploadedFile({
    required this.url,
    required this.name,
    required this.size,
  });
}

class CloudinaryService {
  static const _cloudName = 'ox7jq6oz'; // check this on your dashboard
  static const _preset = 'chat_unsigned'; // must be an Unsigned preset

  /// Max allowed file size for chat attachments (10 MB).
  static const maxFileBytes = 10 * 1024 * 1024;

  /// Picks an image from the gallery and uploads it. Returns the URL or null.
  static Future<String?> pickAndUpload({String? folder}) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return uploadBytes(bytes, picked.name, folder: folder);
  }

  /// NEW: Picks ANY file (pdf, doc, zip, ...) and uploads it.
  /// Returns null if cancelled or failed. Throws an Exception with a
  /// readable message if the file is too large.
  static Future<UploadedFile?> pickAndUploadFile({String? folder}) async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;

    final size = await file.length();
    if (size != null && size > maxFileBytes) {
      throw Exception('File too large (max 10 MB)');
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > maxFileBytes) {
      throw Exception('File too large (max 10 MB)');
    }

    final url = await uploadBytes(bytes, file.name, folder: folder);
    if (url == null) return null;

    return UploadedFile(url: url, name: file.name, size: bytes.length);
  }

  /// Uploads any bytes (image, audio or file). Returns the URL or null.
  static Future<String?> uploadBytes(List<int> bytes, String filename,
      {String? folder}) async {
    try {
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _preset
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename));
      if (folder != null) request.fields['folder'] = folder;

      final response =
          await request.send().timeout(const Duration(seconds: 60));
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(body)['secure_url'] as String;
      }
      debugPrint('Cloudinary error (${response.statusCode}): $body');
      return null;
    } catch (e) {
      // network error, timeout, bad response, etc.
      debugPrint('Cloudinary upload failed: $e');
      return null;
    }
  }
}