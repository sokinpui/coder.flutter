import 'package:flutter/services.dart';

class ChatSelectionTracker {
  static String? _selectedText;
  static Object? _activeSource;

  static String? get selectedText => _selectedText;
  static bool get hasSelection =>
      _selectedText != null && _selectedText!.isNotEmpty;

  static void setSelection(Object source, String? text) {
    if (text == null || text.isEmpty) {
      if (_activeSource == source) {
        _selectedText = null;
        _activeSource = null;
      }
      return;
    }

    _selectedText = text;
    _activeSource = source;
  }

  static void clearSelection(Object source) {
    if (_activeSource == source) {
      _selectedText = null;
      _activeSource = null;
    }
  }

  static void clear() {
    _selectedText = null;
    _activeSource = null;
  }

  static String extractSelectedText(String fullText, TextSelection selection) {
    if (selection.isCollapsed) {
      return '';
    }

    final start = selection.start.clamp(0, fullText.length);
    final end = selection.end.clamp(0, fullText.length);
    if (start >= end) {
      return '';
    }

    return fullText.substring(start, end);
  }
}
