import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hover_animated_button.dart';
import '../../models/chat_message.dart';

class MessageActionBar extends StatelessWidget {
  const MessageActionBar({
    super.key,
    required this.message,
    required this.isUser,
    this.onEdit,
    this.onApplyItf,
    this.onUndoItf,
    this.onBranch,
    this.onRegenerate,
    this.onDelete,
  });

  final ChatMessage message;
  final bool isUser;
  final VoidCallback? onEdit;
  final Future<void> Function(String content)? onApplyItf;
  final Future<void> Function()? onUndoItf;
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
      message.author == MessageAuthor.commandError;

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
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          if (message.author == MessageAuthor.user && onEdit != null)
            HoverAnimatedButton(
              tooltip: 'Edit Message',
              hoverScale: 1.15,
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          if (!isUser && _hasDiff && onApplyItf != null)
            IconButton(
              icon: const Icon(
                Icons.auto_fix_high,
                size: 15,
                color: AppTheme.accentCyan,
              ),
              tooltip: 'Apply Changes (ITF)',
              onPressed: () => onApplyItf!(message.content),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          if (!isUser && onUndoItf != null)
            IconButton(
              icon: const Icon(Icons.undo, size: 15, color: AppTheme.textMuted),
              tooltip: 'Undo Last Applied Changes',
              onPressed: onUndoItf,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          if (onBranch != null)
            IconButton(
              icon: const Icon(
                Icons.fork_right_outlined,
                size: 15,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Branch Conversation Here',
              onPressed: onBranch,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          if (onRegenerate != null && !_isCommand)
            IconButton(
              icon: const Icon(
                Icons.refresh,
                size: 15,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Regenerate Turn',
              onPressed: onRegenerate,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14, color: AppTheme.textMuted),
            tooltip: 'Copy Message',
            onPressed: () => _copyContent(context),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 15,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Delete Message',
              onPressed: () => _confirmDelete(context),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
