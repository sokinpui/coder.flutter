import 'dart:typed_data';

enum MessageAuthor {
  user,
  assistant,
  image,
  command,
  commandResult,
  commandError,
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.author,
    required this.content,
    this.reasoning = '',
    this.imagePath,
    this.imageData,
    this.isGenerating = false,
  });

  final String id;
  MessageAuthor author;
  String content;
  String reasoning;
  final String? imagePath;
  final Uint8List? imageData;
  bool isGenerating;
}
