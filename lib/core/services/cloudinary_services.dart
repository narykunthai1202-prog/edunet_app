import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/cloudinary_constants.dart';
import '../models/upload_result.dart';

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  Future<UploadResult> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse(CloudinaryConstants.uploadUrl),
      );

      request.fields["upload_preset"] = CloudinaryConstants.uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath("file", imageFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final json = jsonDecode(await response.stream.bytesToString());

        return UploadResult(
          success: true,
          imageUrl: json["secure_url"],
          publicId: json["public_id"],
        );
      }

      return UploadResult(success: false, error: "Upload failed");
    } catch (e) {
      return UploadResult(success: false, error: e.toString());
    }
  }

  Future<List<String>> uploadImages(List<File> images) async {
    List<String> urls = [];

    for (final image in images) {
      final result = await uploadImage(image);

      if (result.success) {
        urls.add(result.imageUrl!);
      }
    }

    return urls;
  }
}
