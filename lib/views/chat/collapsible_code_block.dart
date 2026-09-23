import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/chat_selection_tracker.dart';
import '../../core/widgets/hover_animated_button.dart';
import 'code_highlighter.dart';

class CollapsibleCodeBlock extends StatefulWidget {
  const CollapsibleCodeBlock({
    super.key,
    required this.language,
    required this.code,
    this.searchPattern,
  });

  final String language;
  final String code;
  final RegExp? searchPattern;

  @override
  State<CollapsibleCodeBlock> createState() => _CollapsibleCodeBlockState();
}

class _CollapsibleCodeBlockState extends State<CollapsibleCodeBlock> {
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _checkSearchExpansion();
  }

  @override
  void didUpdateWidget(CollapsibleCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkSearchExpansion();
  }

  @override
  void dispose() {
    ChatSelectionTracker.clearSelection(this);
    super.dispose();
  }

  void _checkSearchExpansion() {
    final pattern = widget.searchPattern;
    if (pattern != null && _isCollapsed && pattern.hasMatch(widget.code)) {
      _isCollapsed = false;
    }
  }

  int get _lineCount {
    if (widget.code.isEmpty) {
      return 0;
    }
    return widget.code.split('\n').length;
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA);
    final headerColor = isDark
        ? const Color(0xFF21262D)
        : const Color(0xFFEAEFF2);
    final borderColor = isDark
        ? const Color(0xFF30363D)
        : const Color(0xFFD0D7DE);
    final rawLang = widget.language.trim();
    final label = rawLang.isEmpty ? 'text' : rawLang;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: headerColor,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(9),
              bottom: _isCollapsed ? const Radius.circular(9) : Radius.zero,
            ),
            child: InkWell(
              onTap: () => setState(() => _isCollapsed = !_isCollapsed),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(9),
                bottom: _isCollapsed ? const Radius.circular(9) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _isCollapsed ? 0.0 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: isDark
                            ? AppTheme.textMuted
                            : AppTheme.lightTextMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: AppTheme.monoTextStyle(
                        color: isDark
                            ? const Color(0xFFC9D1D9)
                            : const Color(0xFF24292F),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isCollapsed) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($_lineCount lines hidden)',
                        style: AppTheme.monoTextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    const Spacer(),
                    HoverAnimatedButton(
                      tooltip: _isCollapsed ? 'Expand code' : 'Collapse code',
                      onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                      child: Text(
                        _isCollapsed ? 'Expand' : 'Collapse',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    HoverAnimatedButton(
                      tooltip: 'Copy code',
                      onTap: () => _copyCode(context),
                      child: const Icon(
                        Icons.copy,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: SelectableText.rich(
                CodeHighlighter.highlight(
                  widget.code,
                  widget.language,
                  isDark: isDark,
                  searchPattern: widget.searchPattern,
                ),
                onSelectionChanged: (selection, cause) {
                  if (selection.isCollapsed) {
                    ChatSelectionTracker.clearSelection(this);
                    return;
                  }
                  final expanded = CodeHighlighter.expandTabs(widget.code);
                  final selectedText = ChatSelectionTracker.extractSelectedText(
                    expanded,
                    selection,
                  );
                  ChatSelectionTracker.setSelection(this, selectedText);
                },
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
