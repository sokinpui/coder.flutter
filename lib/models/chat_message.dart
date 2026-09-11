import 'dart:typed_data';

enum MessageAuthor {
  user,
  assistant,
  image,
  pdf,
  command,
  commandResult,
  commandError,
  toolCall,
  toolResult,
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.author,
    required this.content,
    this.reasoning = '',
    this.imagePath,
    this.pdfPath,
    this.pdfName,
    this.imageData,
    this.toolName,
    this.callId,
    this.isGenerating = false,
  });

  final String id;
  MessageAuthor author;
  String content;
  String reasoning;
  final String? imagePath;
  final String? pdfPath;
  final String? pdfName;
  final Uint8List? imageData;
  final String? toolName;
  final String? callId;
  bool isGenerating;
}
