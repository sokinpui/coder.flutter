import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../core/theme/app_theme.dart';
import 'collapsible_code_block.dart';

class MarkdownRenderer extends StatelessWidget {
  const MarkdownRenderer({
    super.key,
    required this.content,
    this.searchPattern,
    this.isStreaming = false,
  });

  final String content;
  final RegExp? searchPattern;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultTextStyle = TextStyle(
      color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
      fontSize: 13.5,
      height: 1.45,
    );

    final pattern = searchPattern;

    return SelectionArea(
      child: GptMarkdown(
        content,
        style: defaultTextStyle,
        useDollarSignsForLatex: true,
        isStreaming: isStreaming,
        codeBuilder: (context, name, code, closed) => CollapsibleCodeBlock(
          language: name,
          code: code,
          searchPattern: pattern,
        ),
        inlinePatterns: pattern == null
            ? const []
            : [
                InlinePattern(
                  pattern: pattern,
                  builder: (context, match, style) => TextSpan(
                    text: match.group(0),
                    style: style.copyWith(
                      backgroundColor: const Color(0x66F2CC60),
                      color: isDark ? const Color(0xFFFFF1A8) : const Color(0xFF5A4300),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
      ),
    );
  }
}
