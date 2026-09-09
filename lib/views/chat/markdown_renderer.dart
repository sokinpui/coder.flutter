import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../core/theme/app_theme.dart';
import 'collapsible_code_block.dart';

class MarkdownRenderer extends StatelessWidget {
  const MarkdownRenderer({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseMarkdownBlocks(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) => _renderBlock(context, b)).toList(),
    );
  }

  List<_MdBlock> _parseMarkdownBlocks(String raw) {
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_MdBlock>[];

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmedLine = line.trim();

      final fenceMatch = RegExp(r'^(`{3,}|~{3,})(.*)$').firstMatch(trimmedLine);
      if (fenceMatch != null) {
        final fence = fenceMatch.group(1)!;
        final lang = fenceMatch.group(2)!.trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith(fence)) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++;
        final lowerLang = lang.toLowerCase();
        if (lowerLang == 'math' || lowerLang == 'latex' || lowerLang == 'tex') {
          final codeContent = codeLines.join('\n').trim();
          if (!codeContent.contains(r'\documentclass') &&
              !codeContent.contains(r'\begin{document}')) {
            blocks.add(
              _MdBlock(type: _BlockType.mathBlock, content: codeContent),
            );
            continue;
          }
        }

        blocks.add(
          _MdBlock(
            type: _BlockType.code,
            content: codeLines.join('\n'),
            language: lang,
          ),
        );
        continue;
      }

      if (trimmedLine.startsWith(r'$$')) {
        if (trimmedLine.length >= 4 && trimmedLine.endsWith(r'$$')) {
          final mathContent = trimmedLine
              .substring(2, trimmedLine.length - 2)
              .trim();
          blocks.add(
            _MdBlock(type: _BlockType.mathBlock, content: mathContent),
          );
          i++;
          continue;
        }

        final mathLines = <String>[];
        final firstLineRest = trimmedLine.substring(2).trim();
        if (firstLineRest.isNotEmpty) {
          mathLines.add(firstLineRest);
        }
        i++;
        while (i < lines.length && !lines[i].trim().endsWith(r'$$')) {
          mathLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) {
          final endLine = lines[i].trim();
          final beforeEnd = endLine.substring(0, endLine.length - 2).trim();
          if (beforeEnd.isNotEmpty) {
            mathLines.add(beforeEnd);
          }
          i++;
        }
        blocks.add(
          _MdBlock(type: _BlockType.mathBlock, content: mathLines.join('\n').trim()),
        );
        continue;
      }

      if (trimmedLine.startsWith(r'\[')) {
        if (trimmedLine.length >= 4 && trimmedLine.endsWith(r'\]')) {
          final mathContent = trimmedLine
              .substring(2, trimmedLine.length - 2)
              .trim();
          blocks.add(
            _MdBlock(type: _BlockType.mathBlock, content: mathContent),
          );
          i++;
          continue;
        }

        final mathLines = <String>[];
        final firstLineRest = trimmedLine.substring(2).trim();
        if (firstLineRest.isNotEmpty) {
          mathLines.add(firstLineRest);
        }
        i++;
        while (i < lines.length && !lines[i].trim().endsWith(r'\]')) {
          mathLines.add(lines[i]);
          i++;
        }
        blocks.add(
          _MdBlock(type: _BlockType.mathBlock, content: mathLines.join('\n').trim()),
        );
        continue;
      }

      if (line.trim().startsWith('|') && line.trim().endsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length &&
            lines[i].trim().startsWith('|') &&
            lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        blocks.add(
          _MdBlock(type: _BlockType.table, content: tableLines.join('\n')),
        );
        continue;
      }

      if (line.trim().startsWith('>')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          quoteLines.add(lines[i].trim().substring(1).trim());
          i++;
        }
        blocks.add(
          _MdBlock(type: _BlockType.quote, content: quoteLines.join('\n')),
        );
        continue;
      }

      if (RegExp(r'^(#{1,6})\s+(.*)$').hasMatch(line)) {
        final match = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line)!;
        blocks.add(
          _MdBlock(
            type: _BlockType.heading,
            content: match.group(2)!,
            level: match.group(1)!.length,
          ),
        );
        i++;
        continue;
      }

      if (RegExp(r'^[-*]\s+(.*)$').hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length &&
            RegExp(r'^[-*]\s+(.*)$').hasMatch(lines[i])) {
          final m = RegExp(r'^[-*]\s+(.*)$').firstMatch(lines[i])!;
          items.add(m.group(1)!);
          i++;
        }
        blocks.add(
          _MdBlock(type: _BlockType.unorderedList, content: items.join('\n')),
        );
        continue;
      }

      if (RegExp(r'^\d+\.\s+(.*)$').hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length &&
            RegExp(r'^\d+\.\s+(.*)$').hasMatch(lines[i])) {
          final m = RegExp(r'^\d+\.\s+(.*)$').firstMatch(lines[i])!;
          items.add(m.group(1)!);
          i++;
        }
        blocks.add(
          _MdBlock(type: _BlockType.orderedList, content: items.join('\n')),
        );
        continue;
      }

      if (RegExp(r'^(\*{3,}|-{3,}|_{3,})$').hasMatch(line.trim())) {
        blocks.add(_MdBlock(type: _BlockType.divider, content: ''));
        i++;
        continue;
      }

      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      final paraLines = <String>[];
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !lines[i].trim().startsWith('```') &&
          !lines[i].trim().startsWith(r'$$') &&
          !lines[i].trim().startsWith(r'\[') &&
          !lines[i].trim().startsWith('#') &&
          !lines[i].trim().startsWith('>') &&
          !lines[i].trim().startsWith('|') &&
          !RegExp(r'^[-*]\s+').hasMatch(lines[i]) &&
          !RegExp(r'^\d+\.\s+').hasMatch(lines[i])) {
        paraLines.add(lines[i]);
        i++;
      }
      blocks.add(
        _MdBlock(type: _BlockType.paragraph, content: paraLines.join('\n')),
      );
    }

    return blocks;
  }

  Widget _renderBlock(BuildContext context, _MdBlock block) {
    switch (block.type) {
      case _BlockType.heading:
        return _renderHeading(context, block.content, block.level);
      case _BlockType.code:
        return CollapsibleCodeBlock(
          language: block.language,
          code: block.content,
        );
      case _BlockType.mathBlock:
        return _renderMathBlock(context, block.content);
      case _BlockType.quote:
        return _renderQuote(context, block.content);
      case _BlockType.unorderedList:
        return _renderList(
          context,
          block.content.split('\n'),
          isOrdered: false,
        );
      case _BlockType.orderedList:
        return _renderList(context, block.content.split('\n'), isOrdered: true);
      case _BlockType.table:
        return _renderTable(context, block.content);
      case _BlockType.divider:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(),
        );
      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SelectionArea(
            child: Text.rich(_parseInlineSpans(context, block.content)),
          ),
        );
    }
  }

  Widget _renderHeading(BuildContext context, String text, int level) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;

    double size = 15;
    FontWeight weight = FontWeight.w600;
    if (level == 1) {
      size = 20;
      weight = FontWeight.bold;
    } else if (level == 2) {
      size = 17;
      weight = FontWeight.bold;
    } else if (level == 3) {
      size = 15;
      weight = FontWeight.w600;
    }

    return Padding(
      padding: EdgeInsets.only(top: level == 1 ? 14 : 10, bottom: 4),
      child: SelectionArea(
        child: Text.rich(
          _parseInlineSpans(
            context,
            text,
            overrideStyle: TextStyle(
              fontSize: size,
              fontWeight: weight,
              color: baseColor,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderMathBlock(BuildContext context, String tex) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? AppTheme.textMain : AppTheme.lightTextMain;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceSubtle.withOpacity(0.6)
            : AppTheme.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectionArea(
          child: Math.tex(
            tex.trim(),
            mathStyle: MathStyle.display,
            textStyle: TextStyle(
              fontSize: 14.5,
              color: color,
            ),
            onErrorFallback: (err) => Text(
              '\$\$\n$tex\n\$\$',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.accentPink,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderQuote(BuildContext context, String quote) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.primary, width: 3)),
      ),
      child: SelectionArea(
        child: Text.rich(_parseInlineSpans(context, quote)),
      ),
    );
  }

  Widget _renderList(
    BuildContext context,
    List<String> items, {
    required bool isOrdered,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bulletColor = isDark ? AppTheme.accentCyan : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final prefix = isOrdered ? '${idx + 1}. ' : '• ';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefix,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: bulletColor,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: SelectionArea(
                    child: Text.rich(_parseInlineSpans(context, item)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _renderTable(BuildContext context, String rawTable) {
    final theme = Theme.of(context);
    final rows = rawTable
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (rows.length < 2) {
      return const SizedBox.shrink();
    }

    List<String> parseCells(String line) {
      final stripped = line.startsWith('|') ? line.substring(1) : line;
      final trimmed = stripped.endsWith('|')
          ? stripped.substring(0, stripped.length - 1)
          : stripped;
      return trimmed.split('|').map((c) => c.trim()).toList();
    }

    final headers = parseCells(rows[0]);
    final contentRows = rows.skip(2).map(parseCells).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 48,
          columns: headers
              .map(
                (h) => DataColumn(
                  label: Text(
                    h,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .toList(),
          rows: contentRows.map((row) {
            return DataRow(
              cells: row.map((cell) {
                return DataCell(
                  SelectableText(cell, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  InlineSpan _buildMathSpan({
    required BuildContext context,
    required String expression,
    required bool isDisplay,
    TextStyle? textStyle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;
    final effectiveStyle = (textStyle ??
            TextStyle(
              color: baseColor,
              fontSize: 13.5,
            ))
        .copyWith(color: textStyle?.color ?? baseColor);

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDisplay ? 4.0 : 1.5,
          vertical: isDisplay ? 4.0 : 0.0,
        ),
        child: Math.tex(
          expression.trim(),
          mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
          textStyle: effectiveStyle,
          onErrorFallback: (err) => Text(
            isDisplay ? '\$\$$expression\$\$' : '\$$expression\$',
            style: effectiveStyle.copyWith(
              fontFamily: 'monospace',
              color: AppTheme.accentPink,
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _parseInlineSpans(
    BuildContext context,
    String text, {
    TextStyle? overrideStyle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = TextStyle(
      color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
      fontSize: 13.5,
      height: 1.45,
    );
    final effectiveStyle = overrideStyle ?? defaultStyle;
    final spans = <InlineSpan>[];

    final inlineRegex = RegExp(
      r'(`([^`]+)`)' // 1, 2: code
      r'|(\$\$([^\$]+?)\$\$)' // 3, 4: display math $$
      r'|(\\\[([\s\S]+?)\\\])' // 5, 6: display math \[ \]
      r'|(\\\(([\s\S]+?)\\\))' // 7, 8: inline math \( \)
      r'|(\$([^\$\s](?:[^\$]*?[^\$\s])?)\$(?!\d))' // 9, 10: inline math $
      r'|(\*\*([^*]+)\*\*)' // 11, 12: bold
      r'|(\*([^*]+)\*)' // 13, 14: italic
      r'|(~~([^~]+)~~)', // 15, 16: strike
    );

    var lastIdx = 0;
    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > lastIdx) {
        spans.add(TextSpan(text: text.substring(lastIdx, match.start)));
      }

      if (match.group(2) != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surfaceSubtle
                    : const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.dividerColor, width: 0.8),
              ),
              child: Text(
                match.group(2)!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark ? AppTheme.accentCyan : const Color(0xFF0F5B66),
                ),
              ),
            ),
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          _buildMathSpan(
            context: context,
            expression: match.group(4)!,
            isDisplay: true,
            textStyle: effectiveStyle,
          ),
        );
      } else if (match.group(6) != null) {
        spans.add(
          _buildMathSpan(
            context: context,
            expression: match.group(6)!,
            isDisplay: true,
            textStyle: effectiveStyle,
          ),
        );
      } else if (match.group(8) != null) {
        spans.add(
          _buildMathSpan(
            context: context,
            expression: match.group(8)!,
            isDisplay: false,
            textStyle: effectiveStyle,
          ),
        );
      } else if (match.group(10) != null) {
        spans.add(
          _buildMathSpan(
            context: context,
            expression: match.group(10)!,
            isDisplay: false,
            textStyle: effectiveStyle,
          ),
        );
      } else if (match.group(12) != null) {
        spans.add(
          _parseInlineSpans(
            context,
            match.group(12)!,
            overrideStyle: effectiveStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else if (match.group(14) != null) {
        spans.add(
          _parseInlineSpans(
            context,
            match.group(14)!,
            overrideStyle: effectiveStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(16) != null) {
        spans.add(
          _parseInlineSpans(
            context,
            match.group(16)!,
            overrideStyle: effectiveStyle.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
        );
      }
      lastIdx = match.end;
    }

    if (lastIdx < text.length) {
      spans.add(TextSpan(text: text.substring(lastIdx)));
    }

    return TextSpan(style: effectiveStyle, children: spans);
  }
}

enum _BlockType {
  heading,
  paragraph,
  code,
  quote,
  unorderedList,
  orderedList,
  table,
  divider,
  mathBlock,
}

class _MdBlock {
  _MdBlock({
    required this.type,
    required this.content,
    this.language = '',
    this.level = 1,
  });

  final _BlockType type;
  final String content;
  final String language;
  final int level;
}
