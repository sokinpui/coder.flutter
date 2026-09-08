import 'package:flutter/material.dart';

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
        blocks.add(
          _MdBlock(
            type: _BlockType.code,
            content: codeLines.join('\n'),
            language: lang,
          ),
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
          child: SelectableText.rich(_parseInlineSpans(context, block.content)),
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
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: baseColor,
          height: 1.3,
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
      child: SelectableText.rich(_parseInlineSpans(context, quote)),
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
                  child: SelectableText.rich(_parseInlineSpans(context, item)),
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

  TextSpan _parseInlineSpans(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = TextStyle(
      color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
      fontSize: 13.5,
      height: 1.45,
    );
    final spans = <InlineSpan>[];

    final inlineRegex = RegExp(
      r'(`([^`]+)`)' // code
      r'|(\*\*([^*]+)\*\*)' // bold
      r'|(\*([^*]+)\*)' // italic
      r'|(~~([^~]+)~~)', // strike
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
          TextSpan(
            text: match.group(4)!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (match.group(6) != null) {
        spans.add(
          TextSpan(
            text: match.group(6)!,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(8) != null) {
        spans.add(
          TextSpan(
            text: match.group(8)!,
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
        );
      }
      lastIdx = match.end;
    }

    if (lastIdx < text.length) {
      spans.add(TextSpan(text: text.substring(lastIdx)));
    }

    return TextSpan(style: defaultStyle, children: spans);
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
