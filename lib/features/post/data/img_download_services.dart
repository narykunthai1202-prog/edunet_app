import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

class ImageDownloadService {
  static Future<void> downloadImage(String imageUrl) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Invalid image URL');
    }

    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw Exception('Gallery permission denied');
      }
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Image download failed (HTTP ${response.statusCode})');
    }
    if (response.bodyBytes.isEmpty) {
      throw Exception('Downloaded image is empty');
    }

    await Gal.putImageBytes(
      response.bodyBytes,
      name: 'edunest_${DateTime.now().microsecondsSinceEpoch}',
    );
  }
}
