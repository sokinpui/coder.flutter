import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/highlight.dart' as hl;

import '../../core/theme/app_theme.dart';

class CodeHighlighter {
  static List<String> get fontFallbacks => AppTheme.monoFontFamilyFallback;

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
    RegExp? searchPattern,
    double fontSize = 14.0,
  }) {
    final code = expandTabs(rawCode);
    final normalizedLang = language.trim().toLowerCase();

    final TextSpan baseSpan;
    if (_isDiffLanguage(normalizedLang)) {
      baseSpan = _highlightDiff(code, isDark, fontSize: fontSize);
    } else {
      final theme = isDark ? atomOneDarkTheme : githubTheme;
      final fallbackColor = isDark
          ? const Color(0xFFE6EDF3)
          : const Color(0xFF24292F);
      final spans = _parseHighlight(code, normalizedLang, theme);

      baseSpan = TextSpan(
        style: AppTheme.monoTextStyle(
          fontSize: fontSize,
          height: 1.5,
          color: fallbackColor,
        ),
        children: spans,
      );
    }

    if (searchPattern == null) {
      return baseSpan;
    }
    return _applySearchHighlight(baseSpan, searchPattern, isDark);
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

  static TextSpan _highlightDiff(
    String code,
    bool isDark, {
    double fontSize = 14.0,
  }) {
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
          style: AppTheme.monoTextStyle(
            color: color,
            backgroundColor: background,
            fontWeight: weight,
          ),
        ),
      );
    }

    return TextSpan(
      style: AppTheme.monoTextStyle(
        fontSize: fontSize,
        height: 1.5,
        color: plainColor,
      ),
      children: children,
    );
  }

  static TextSpan _applySearchHighlight(
    TextSpan span,
    RegExp pattern,
    bool isDark,
  ) {
    final text = span.text;
    final children = span.children;

    if (text != null && text.isNotEmpty && pattern.hasMatch(text)) {
      final newChildren = <InlineSpan>[];
      var lastEnd = 0;
      for (final match in pattern.allMatches(text)) {
        if (match.start > lastEnd) {
          newChildren.add(
            TextSpan(
              text: text.substring(lastEnd, match.start),
              style: span.style,
            ),
          );
        }
        newChildren.add(
          TextSpan(
            text: match.group(0),
            style: (span.style ?? AppTheme.monoTextStyle()).copyWith(
              backgroundColor: const Color(0x66F2CC60),
              color: isDark ? const Color(0xFFFFF1A8) : const Color(0xFF5A4300),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        lastEnd = match.end;
      }
      if (lastEnd < text.length) {
        newChildren.add(
          TextSpan(text: text.substring(lastEnd), style: span.style),
        );
      }
      return TextSpan(style: span.style, children: newChildren);
    }

    if (children != null && children.isNotEmpty) {
      final newChildren = children.map((child) {
        if (child is TextSpan) {
          return _applySearchHighlight(child, pattern, isDark);
        }
        return child;
      }).toList();
      return TextSpan(style: span.style, children: newChildren);
    }

    return span;
  }
}
