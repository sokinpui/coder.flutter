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
    final isSelected = state.isSessionSelected(session);
    final isLoadingThis =
        state.isLoadingSession && state.loadingSessionFilename == session.filename;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: isDark
            ? AppTheme.surfaceSubtle
            : AppTheme.lightSurfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        leading: isLoadingThis
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              )
            : Icon(
                isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
                size: 16,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? AppTheme.primary
                : (isDark ? AppTheme.textMain : AppTheme.lightTextMain),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 15, color: AppTheme.textMuted),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Rename',
          onPressed: () => _showRenameDialog(context),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
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
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty || newTitle == session.title) return;
              if (!state.isSessionSelected(session)) {
                await state.loadSession(session.filename);
              }
              await state.renameSession(newTitle);
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
