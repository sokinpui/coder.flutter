import 'dart:typed_data';

enum AttachmentType { image, pdf }

class StagedAttachment {
  StagedAttachment({
    required this.id,
    required this.type,
    required this.name,
    this.bytes,
    this.path,
    this.sizeBytes,
    this.isUploading = false,
    this.error,
  });

  final String id;
  final AttachmentType type;
  final String name;
  final Uint8List? bytes;
  final String? path;
  final int? sizeBytes;
  bool isUploading;
  String? error;

  String get formattedSize {
    if (sizeBytes == null || sizeBytes! <= 0) {
      if (bytes != null && bytes!.isNotEmpty) {
        return _formatBytes(bytes!.length);
      }
      return '';
    }
    return _formatBytes(sizeBytes!);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
