import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';

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
    final baseColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;

    final generator = MarkdownGenerator(
      inlineSyntaxList: [LatexSyntax()],
      generators: [
        SpanNodeGeneratorWithTag(
          tag: 'latex',
          generator: (e, config, visitor) =>
              LatexNode(e.attributes, e.textContent, config, isDark),
        ),
      ],
      textGenerator: (node, config, visitor) => CustomSearchTextNode(
        node.textContent,
        searchPattern,
        isDark,
      ),
    );

    final markdownConfig = (isDark
            ? MarkdownConfig.darkConfig
            : MarkdownConfig.defaultConfig)
        .copy(
      configs: [
        CodeConfig(
          style: AppTheme.monoTextStyle(
            fontSize: 13.0,
            color: isDark ? const Color(0xFFFF7B72) : const Color(0xFFCF222E),
            backgroundColor: isDark
                ? const Color(0x266E7681)
                : const Color(0x1A1F2328),
          ),
        ),
        PConfig(
          textStyle: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: baseColor,
          ),
        ),
        H1Config(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: baseColor,
          ),
        ),
        H2Config(
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: baseColor,
          ),
        ),
        H3Config(
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: baseColor,
          ),
        ),
        H4Config(
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: baseColor,
          ),
        ),
        PreConfig(
          wrapper: (child, code, language) => CollapsibleCodeBlock(
            language: language,
            code: code,
            searchPattern: searchPattern,
          ),
        ),
        ListConfig(
          marginLeft: 16.0,
          marginBottom: 2.0,
          marker: (isOrdered, depth, index) {
            if (isOrdered) {
              return Text(
                '${index + 1}. ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.accentCyan : AppTheme.primary,
                ),
              );
            }
            return Container(
              margin: const EdgeInsets.only(right: 6, top: 6),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.accentCyan : AppTheme.primary,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ],
    );

    return SelectionArea(
      child: MarkdownBlock(
        data: content,
        config: markdownConfig,
        generator: generator,
      ),
    );
  }
}

class LatexSyntax extends m.InlineSyntax {
  LatexSyntax()
      : super(r'(\$\$[\s\S]+?\$\$)|(\$.+?\$)|(\\\[[\s\S]+?\\\])|(\\\([\s\S]+?\\\))');

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final input = match.input;
    final matchValue = input.substring(match.start, match.end);
    String content = '';
    bool isInline = true;

    if (matchValue.startsWith(r'$$') &&
        matchValue.endsWith(r'$$') &&
        matchValue.length >= 4) {
      content = matchValue.substring(2, matchValue.length - 2).trim();
      isInline = false;
    } else if (matchValue.startsWith(r'\[') &&
        matchValue.endsWith(r'\]') &&
        matchValue.length >= 4) {
      content = matchValue.substring(2, matchValue.length - 2).trim();
      isInline = false;
    } else if (matchValue.startsWith(r'\(') &&
        matchValue.endsWith(r'\)') &&
        matchValue.length >= 4) {
      content = matchValue.substring(2, matchValue.length - 2).trim();
      isInline = true;
    } else if (matchValue.startsWith(r'$') &&
        matchValue.endsWith(r'$') &&
        matchValue.length >= 2) {
      content = matchValue.substring(1, matchValue.length - 1).trim();
      isInline = true;
    }

    final el = m.Element.text('latex', matchValue);
    el.attributes['content'] = content;
    el.attributes['isInline'] = '$isInline';
    parser.addNode(el);
    return true;
  }
}

class LatexNode extends SpanNode {
  LatexNode(this.attributes, this.textContent, this.config, this.isDark);

  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;
  final bool isDark;

  @override
  InlineSpan build() {
    final content = attributes['content'] ?? '';
    final isInline = attributes['isInline'] == 'true';
    final baseColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;
    final style = (parentStyle ?? config.p.textStyle).copyWith(color: baseColor);

    if (content.isEmpty) {
      return TextSpan(style: style, text: textContent);
    }

    final latex = Math.tex(
      content,
      mathStyle: isInline ? MathStyle.text : MathStyle.display,
      textStyle: TextStyle(
        fontSize: isInline ? 13.5 : 14.5,
        color: baseColor,
      ),
      onErrorFallback: (err) => Text(
        isInline ? '\$$content\$' : '\$\$\n$content\n\$\$',
        style: style.copyWith(
          fontFamily: AppTheme.monoFontFamily,
          fontFamilyFallback: AppTheme.monoFontFamilyFallback,
          color: AppTheme.accentPink,
        ),
      ),
    );

    if (isInline) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: latex,
        ),
      );
    }

    return WidgetSpan(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.surfaceSubtle.withOpacity(0.6)
              : AppTheme.lightSurfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isDark ? AppTheme.border : AppTheme.lightBorder)
                .withOpacity(0.6),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: latex,
        ),
      ),
    );
  }
}

class CustomSearchTextNode extends SpanNode {
  CustomSearchTextNode(this.text, this.searchPattern, this.isDark);

  final String text;
  final RegExp? searchPattern;
  final bool isDark;

  @override
  InlineSpan build() {
    final style = parentStyle ?? const TextStyle();
    final pattern = searchPattern;
    if (pattern == null || text.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final spans = <InlineSpan>[];
    var lastIdx = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIdx) {
        spans.add(TextSpan(
          text: text.substring(lastIdx, match.start),
          style: style,
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: style.copyWith(
          backgroundColor: const Color(0x66F2CC60),
          color: isDark ? const Color(0xFFFFF1A8) : const Color(0xFF5A4300),
          fontWeight: FontWeight.bold,
        ),
      ));
      lastIdx = match.end;
    }

    if (lastIdx < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIdx),
        style: style,
      ));
    }

    return TextSpan(children: spans);
  }
}
