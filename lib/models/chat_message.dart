import 'package:flutter/foundation.dart';
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

class ChatMessage extends ChangeNotifier {
  ChatMessage({
    required this.id,
    required this.author,
    required String content,
    String reasoning = '',
    this.imagePath,
    this.pdfPath,
    this.pdfName,
    this.pdfPageCount,
    this.imageData,
    this.toolName,
    this.callId,
    bool isGenerating = false,
  })  : _content = content,
        _reasoning = reasoning,
        _isGenerating = isGenerating;

  final String id;
  MessageAuthor author;
  final String? imagePath;
  final String? pdfPath;
  final String? pdfName;
  final int? pdfPageCount;
  final Uint8List? imageData;
  final String? toolName;
  final String? callId;

  String _content;
  String _reasoning;
  bool _isGenerating;

  String get content => _content;
  set content(String value) {
    if (_content == value) return;
    _content = value;
    notifyListeners();
  }

  String get reasoning => _reasoning;
  set reasoning(String value) {
    if (_reasoning == value) return;
    _reasoning = value;
    notifyListeners();
  }

  bool get isGenerating => _isGenerating;
  set isGenerating(bool value) {
    if (_isGenerating == value) return;
    _isGenerating = value;
    notifyListeners();
  }

  void appendContent(String chunk) {
    if (chunk.isEmpty) return;
    _content += chunk;
    notifyListeners();
  }

  void appendReasoning(String chunk) {
    if (chunk.isEmpty) return;
    _reasoning += chunk;
    notifyListeners();
  }
}
