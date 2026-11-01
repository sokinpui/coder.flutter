import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';

class MessageActionBar extends StatelessWidget {
  const MessageActionBar({
    super.key,
    required this.message,
    required this.isUser,
    this.onEdit,
    this.onApplyItf,
    this.onBranch,
    this.onRegenerate,
    this.onDelete,
  });

  final ChatMessage message;
  final bool isUser;
  final VoidCallback? onEdit;
  final Future<void> Function(String content)? onApplyItf;
  final VoidCallback? onBranch;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;

  bool get _hasDiff =>
      message.content.contains('```diff') ||
      message.content.contains('```rename') ||
      message.content.contains('```delete');

  bool get _isCommand =>
      message.author == MessageAuthor.command ||
      message.author == MessageAuthor.commandResult ||
      message.author == MessageAuthor.commandError ||
      message.author == MessageAuthor.toolCall ||
      message.author == MessageAuthor.toolResult;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?', style: TextStyle(fontSize: 16)),
        content: const Text('Are you sure you want to remove this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentPink),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete?.call();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _copyContent(BuildContext context) {
    final textToCopy = message.imageData != null ? '[Image]' : message.content;
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = message.author == MessageAuthor.user && onEdit != null;
    final canBranch = onBranch != null;
    final canRegenerate = onRegenerate != null && !_isCommand;
    final canApplyItf = !isUser && _hasDiff && onApplyItf != null;
    final canDelete = onDelete != null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (canBranch)
            _TwitterActionButton(
              icon: Icons.fork_right_rounded,
              tooltip: 'Branch conversation',
              hoverColor: AppTheme.accentCyan,
              onTap: onBranch,
            ),
          if (canRegenerate)
            _TwitterActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Regenerate response',
              hoverColor: AppTheme.primary,
              onTap: onRegenerate,
            ),
          if (canApplyItf)
            _TwitterActionButton(
              icon: Icons.auto_fix_high_rounded,
              label: 'Apply ITF',
              tooltip: 'Apply diff changes',
              hoverColor: AppTheme.accentCyan,
              onTap: () => onApplyItf!(message.content),
            ),
          if (canEdit)
            _TwitterActionButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit message',
              hoverColor: AppTheme.accentYellow,
              onTap: onEdit,
            ),
          _TwitterActionButton(
            icon: Icons.copy_rounded,
            tooltip: 'Copy content',
            hoverColor: AppTheme.primary,
            onTap: () => _copyContent(context),
          ),
          if (canDelete)
            _TwitterActionButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete message',
              hoverColor: AppTheme.accentPink,
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
    );
  }
}

class _TwitterActionButton extends StatefulWidget {
  const _TwitterActionButton({
    required this.icon,
    required this.tooltip,
    required this.hoverColor,
    this.onTap,
    this.onPressed,
    this.label,
  });

  final IconData icon;
  final String tooltip;
  final Color hoverColor;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final String? label;

  @override
  State<_TwitterActionButton> createState() => _TwitterActionButtonState();
}

class _TwitterActionButtonState extends State<_TwitterActionButton> {
  bool _isHovered = false;

  VoidCallback? get _effectiveAction => widget.onTap ?? widget.onPressed;

  @override
  Widget build(BuildContext context) {
    final activeColor = _isHovered ? widget.hoverColor : AppTheme.textMuted;
    final bgColor = _isHovered
        ? widget.hoverColor.withOpacity(0.12)
        : Colors.transparent;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: _effectiveAction != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _effectiveAction,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(
              horizontal: widget.label != null ? 8 : 6,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    widget.icon,
                    size: 14.5,
                    color: activeColor,
                  ),
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _isHovered
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: activeColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
