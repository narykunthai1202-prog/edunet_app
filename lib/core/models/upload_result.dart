class UploadResult {
  final bool success;
  final String? imageUrl;
  final String? publicId;
  final String? error;

  UploadResult({
    required this.success,
    this.imageUrl,
    this.publicId,
    this.error,
  });
}
