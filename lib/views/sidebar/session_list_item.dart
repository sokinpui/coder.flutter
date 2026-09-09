import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/session_info.dart';
import '../../state/coder_state.dart';

class SessionListItem extends StatelessWidget {
  const SessionListItem({
    super.key,
    required this.session,
    required this.state,
    required this.onTap,
  });

  final SessionInfo session;
  final CoderState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      leading: const Icon(
        Icons.chat_bubble_outline,
        size: 16,
        color: AppTheme.textMuted,
      ),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, size: 16, color: AppTheme.textMuted),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () => _showSessionOptions(context),
      ),
      onTap: onTap,
    );
  }

  void _showSessionOptions(BuildContext context) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Rename Conversation',
          style: TextStyle(fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New Title',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              state.renameSession(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
