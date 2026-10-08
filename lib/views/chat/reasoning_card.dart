import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/chat_selection_tracker.dart';

class ReasoningCard extends StatefulWidget {
  const ReasoningCard({
    super.key,
    required this.reasoning,
    required this.isDark,
    this.isGenerating = false,
  });

  final String reasoning;
  final bool isDark;
  final bool isGenerating;

  @override
  State<ReasoningCard> createState() => _ReasoningCardState();
}

class _ReasoningCardState extends State<ReasoningCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isGenerating;
  }

  @override
  void didUpdateWidget(ReasoningCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isGenerating && widget.isGenerating) {
      _isExpanded = true;
    }
  }

  @override
  void dispose() {
    ChatSelectionTracker.clearSelection(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? AppTheme.background.withOpacity(0.7)
        : AppTheme.lightSurfaceSubtle.withOpacity(0.7);
    final borderColor = (widget.isDark ? AppTheme.border : AppTheme.lightBorder)
        .withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.psychology_outlined,
                    color: AppTheme.accentYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Thought Process',
                    style: TextStyle(
                      color: AppTheme.accentYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.isGenerating) ...[
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 9,
                      height: 9,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.accentYellow,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: SelectableText(
                widget.reasoning,
                style: AppTheme.monoTextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
                onSelectionChanged: (selection, cause) {
                  if (selection.isCollapsed) {
                    ChatSelectionTracker.clearSelection(this);
                    return;
                  }
                  final selectedText = ChatSelectionTracker.extractSelectedText(
                    widget.reasoning,
                    selection,
                  );
                  ChatSelectionTracker.setSelection(this, selectedText);
                },
              ),
            ),
        ],
      ),
    );
  }
}
