import 'dart:typed_data';

enum MessageAuthor { user, assistant, system, image }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.author,
    required this.content,
    this.reasoning = '',
    this.imagePath,
    this.imageData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final MessageAuthor author;
  String content;
  String reasoning;
  final String? imagePath;
  final Uint8List? imageData;
  final DateTime timestamp;
}
