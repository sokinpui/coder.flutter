import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hover_animated_button.dart';

class ChatSearchBar extends StatelessWidget {
  const ChatSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isRegex,
    required this.isCaseSensitive,
    required this.currentMatchIndex,
    required this.totalMatches,
    this.searchError,
    required this.onToggleCaseSensitive,
    required this.onToggleRegex,
    required this.onPreviousMatch,
    required this.onNextMatch,
    required this.onClose,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isRegex;
  final bool isCaseSensitive;
  final int currentMatchIndex;
  final int totalMatches;
  final String? searchError;
  final VoidCallback onToggleCaseSensitive;
  final VoidCallback onToggleRegex;
  final VoidCallback onPreviousMatch;
  final VoidCallback onNextMatch;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMatches = totalMatches > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceSubtle : AppTheme.lightSurfaceSubtle,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Find in conversation (supports regex)...',
                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          HoverAnimatedButton(
            tooltip: 'Match Case (Alt+C)',
            hoverScale: 1.1,
            onTap: onToggleCaseSensitive,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isCaseSensitive
                    ? AppTheme.primary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCaseSensitive
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          HoverAnimatedButton(
            tooltip: 'Use Regular Expression (Alt+R)',
            hoverScale: 1.1,
            onTap: onToggleRegex,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isRegex
                    ? AppTheme.primary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '.*',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isRegex ? AppTheme.primary : AppTheme.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            searchError ??
                (controller.text.isEmpty
                    ? ''
                    : (hasMatches
                          ? '${currentMatchIndex + 1} of $totalMatches'
                          : 'No results')),
            style: TextStyle(
              fontSize: 11.5,
              color: searchError != null
                  ? AppTheme.accentPink
                  : AppTheme.textMuted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 16),
            tooltip: 'Previous match (Shift+Enter)',
            onPressed: !hasMatches ? null : onPreviousMatch,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 16),
            tooltip: 'Next match (Enter)',
            onPressed: !hasMatches ? null : onNextMatch,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Close (Esc)',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
