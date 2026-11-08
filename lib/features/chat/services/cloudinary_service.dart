import 'dart:async';
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

/// Multipart request that reports how many bytes have been sent.
/// (On Flutter web the browser sends the body in one go, so the progress
/// jumps quickly there. On Android / iOS it is accurate.)
class _ProgressMultipartRequest extends http.MultipartRequest {
  final void Function(int sent, int total) onProgress;

  _ProgressMultipartRequest(
    super.method,
    super.url, {
    required this.onProgress,
  });

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    var sent = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        sent += data.length;
        onProgress(sent, total);
        sink.add(data);
      },
    );
    return http.ByteStream(byteStream.transform(transformer));
  }
}

class CloudinaryService {
  static const _cloudName = 'ox7jq6oz'; // check this on your dashboard
  static const _preset = 'chat_unsigned'; // must be an Unsigned preset

  /// Max allowed file size for chat attachments (10 MB).
  static const maxFileBytes = 10 * 1024 * 1024;

  /// Max allowed size for videos (25 MB). Smaller = faster to send.
  /// Check your Cloudinary plan's limit too.
  static const maxVideoBytes = 25 * 1024 * 1024;

  /// Max video length. Longer clips are cut by the picker.
  static const maxVideoDuration = Duration(minutes: 2);

  /// Picks an image from the gallery and uploads it. Returns the URL or null.
  static Future<String?> pickAndUpload({String? folder}) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return uploadBytes(bytes, picked.name, folder: folder);
  }

  // ---------------------------------------------------------------------
  // VIDEO: step 1 = pick, step 2 = preview (VideoPreviewScreen), step 3 = upload
  // ---------------------------------------------------------------------

  /// STEP 1: Picks a video from the gallery. Does NOT upload.
  /// Returns null if cancelled. Throws an Exception if the video is too large.
  static Future<XFile?> pickVideo() async {
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxVideoDuration,
    );
    if (picked == null) return null;

    final size = await picked.length();
    if (size > maxVideoBytes) {
      final mb = (maxVideoBytes / (1024 * 1024)).round();
      throw Exception('Video too large (max $mb MB)');
    }
    return picked;
  }

  /// STEP 3: Uploads a video that was already picked (and previewed).
  /// [onProgress] gets a value from 0.0 to 1.0.
  static Future<UploadedFile?> uploadVideo(
    XFile video, {
    String? folder,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final bytes = await video.readAsBytes();
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload');

      final request = _ProgressMultipartRequest(
        'POST',
        uri,
        onProgress: (sent, total) {
          if (total > 0) onProgress?.call((sent / total).clamp(0.0, 1.0));
        },
      )
        ..fields['upload_preset'] = _preset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: video.name),
        );
      if (folder != null) request.fields['folder'] = folder;

      final response =
          await request.send().timeout(const Duration(minutes: 5));
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final url = jsonDecode(body)['secure_url'] as String;
        return UploadedFile(url: url, name: video.name, size: bytes.length);
      }
      debugPrint('Cloudinary video error (${response.statusCode}): $body');
      return null;
    } catch (e) {
      debugPrint('Cloudinary video upload failed: $e');
      return null;
    }
  }

  /// Picks ANY file (pdf, doc, zip, ...) and uploads it.
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