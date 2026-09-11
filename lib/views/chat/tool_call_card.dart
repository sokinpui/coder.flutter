import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hover_animated_button.dart';

class ToolCallCard extends StatefulWidget {
  const ToolCallCard({
    super.key,
    this.toolName,
    this.callId,
    required this.content,
    required this.isResult,
    this.isExecuting = false,
    required this.isDark,
    this.searchPattern,
  });

  final String? toolName;
  final String? callId;
  final String content;
  final bool isResult;
  final bool isExecuting;
  final bool isDark;
  final RegExp? searchPattern;

  @override
  State<ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<ToolCallCard> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _checkSearchExpansion();
  }

  @override
  void didUpdateWidget(ToolCallCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkSearchExpansion();
  }

  void _checkSearchExpansion() {
    final pattern = widget.searchPattern;
    if (pattern != null && !_isExpanded && pattern.hasMatch(widget.content)) {
      _isExpanded = true;
    }
  }

  void _copyContent(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isResult ? const Color(0xFF7EE787) : AppTheme.accentCyan;
    final bgColor = widget.isDark
        ? AppTheme.surfaceSubtle.withOpacity(0.5)
        : AppTheme.lightSurfaceSubtle.withOpacity(0.8);
    final borderColor =
        (widget.isDark ? AppTheme.border : AppTheme.lightBorder)
            .withOpacity(0.7);

    final titlePrefix = widget.isResult ? 'Tool Result' : 'Tool Call';
    final nameDisplay = widget.toolName != null && widget.toolName!.isNotEmpty
        ? (widget.isResult ? ' [${widget.toolName}]' : ': ${widget.toolName}')
        : '';
    final title = '$titlePrefix$nameDisplay';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(9),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(9),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    widget.isResult
                        ? Icons.check_circle_outline
                        : Icons.build_circle_outlined,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.callId != null && widget.callId!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.callId!,
                        style: AppTheme.monoTextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                  if (widget.isExecuting) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Running...',
                      style: TextStyle(
                        fontSize: 11,
                        color: accentColor.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.content.isNotEmpty)
                    HoverAnimatedButton(
                      tooltip: 'Copy',
                      onTap: () => _copyContent(context),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.copy,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: widget.content.isEmpty
                  ? Text(
                      widget.isResult ? '(empty output)' : '(no arguments)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? const Color(0xFF10141B)
                            : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: borderColor.withOpacity(0.5),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            widget.content,
                            style: AppTheme.monoTextStyle(
                              fontSize: 11.5,
                              color: widget.isDark
                                  ? AppTheme.textMain
                                  : AppTheme.lightTextMain,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
