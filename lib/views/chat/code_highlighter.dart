import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/highlight.dart' as hl;

class CodeHighlighter {
  static const List<String> fontFallbacks = [
    'Menlo',
    'Consolas',
    'DejaVu Sans Mono',
    'Courier New',
    'monospace',
  ];

  static String expandTabs(String code, {int tabSize = 4}) {
    final buffer = StringBuffer();
    final lines = code.replaceAll('\r\n', '\n').split('\n');

    for (var l = 0; l < lines.length; l++) {
      final line = lines[l];
      var col = 0;
      for (var i = 0; i < line.length; i++) {
        final ch = line[i];
        if (ch == '\t') {
          final spaces = tabSize - (col % tabSize);
          buffer.write(' ' * spaces);
          col += spaces;
          continue;
        }
        buffer.write(ch);
        col++;
      }
      if (l < lines.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  static TextSpan highlight(
    String rawCode,
    String language, {
    required bool isDark,
  }) {
    final code = expandTabs(rawCode);
    final normalizedLang = language.trim().toLowerCase();

    if (_isDiffLanguage(normalizedLang)) {
      return _highlightDiff(code, isDark);
    }

    final theme = isDark ? atomOneDarkTheme : githubTheme;
    final fallbackColor = isDark
        ? const Color(0xFFE6EDF3)
        : const Color(0xFF24292F);
    final spans = _parseHighlight(code, normalizedLang, theme);

    return TextSpan(
      style: TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: fontFallbacks,
        fontSize: 12.5,
        height: 1.45,
        color: fallbackColor,
      ),
      children: spans,
    );
  }

  static bool _isDiffLanguage(String lang) {
    return lang == 'diff' ||
        lang == 'patch' ||
        lang == 'rename' ||
        lang == 'delete';
  }

  static List<TextSpan> _parseHighlight(
    String code,
    String lang,
    Map<String, TextStyle> theme,
  ) {
    try {
      final result = hl.highlight.parse(
        code,
        language: lang.isEmpty ? null : lang,
        autoDetection: lang.isEmpty,
      );
      final nodes = result.nodes;
      if (nodes == null || nodes.isEmpty) {
        return [TextSpan(text: code)];
      }
      return _traverseNodes(nodes, theme);
    } catch (_) {
      return [TextSpan(text: code)];
    }
  }

  static List<TextSpan> _traverseNodes(
    List<hl.Node> nodes,
    Map<String, TextStyle> theme,
  ) {
    final spans = <TextSpan>[];
    for (final node in nodes) {
      final value = node.value;
      final children = node.children;
      final style = node.className != null ? theme[node.className!] : null;

      if (value != null) {
        spans.add(TextSpan(text: value, style: style));
      } else if (children != null && children.isNotEmpty) {
        final childSpans = _traverseNodes(children, theme);
        spans.add(TextSpan(children: childSpans, style: style));
      }
    }
    return spans;
  }

  static TextSpan _highlightDiff(String code, bool isDark) {
    final lines = code.split('\n');
    final children = <TextSpan>[];

    final addColor = isDark ? const Color(0xFF7EE787) : const Color(0xFF1A7F37);
    final addBg = isDark ? const Color(0x262EA043) : const Color(0x221F883D);
    final removeColor = isDark
        ? const Color(0xFFFF7B72)
        : const Color(0xFFCF222E);
    final removeBg = isDark ? const Color(0x26F85149) : const Color(0x1CE5534B);
    final hunkColor = isDark
        ? const Color(0xFF79C0FF)
        : const Color(0xFF0969DA);
    final metaColor = isDark
        ? const Color(0xFF8B949E)
        : const Color(0xFF57606A);
    final plainColor = isDark
        ? const Color(0xFFE6EDF3)
        : const Color(0xFF24292F);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      Color color = plainColor;
      Color? background;
      FontWeight weight = FontWeight.normal;

      if (line.startsWith('+++') ||
          line.startsWith('---') ||
          line.startsWith('diff --git')) {
        color = metaColor;
        weight = FontWeight.w600;
      } else if (line.startsWith('+') && !line.startsWith('+++')) {
        color = addColor;
        background = addBg;
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        color = removeColor;
        background = removeBg;
      } else if (line.startsWith('@@')) {
        color = hunkColor;
        weight = FontWeight.w600;
      }

      final lineText = i < lines.length - 1 ? '$line\n' : line;
      children.add(
        TextSpan(
          text: lineText,
          style: TextStyle(
            color: color,
            backgroundColor: background,
            fontWeight: weight,
            fontFamily: 'monospace',
            fontFamilyFallback: fontFallbacks,
          ),
        ),
      );
    }

    return TextSpan(
      style: TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: fontFallbacks,
        fontSize: 12.5,
        height: 1.45,
        color: plainColor,
      ),
      children: children,
    );
  }
}
