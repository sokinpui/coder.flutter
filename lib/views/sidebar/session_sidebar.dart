import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/session_info.dart';
import '../../state/coder_state.dart';
import '../settings/server_settings_dialog.dart';

class SessionSidebar extends StatelessWidget {
  const SessionSidebar({
    super.key,
    required this.state,
    this.onSessionSelected,
  });

  final CoderState state;
  final VoidCallback? onSessionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 280,
      color: isDark ? AppTheme.surface : AppTheme.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          _buildNewChatButton(context),
          _buildModelSelector(context),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'CONVERSATIONS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(child: _buildSessionList()),
          const Divider(),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.terminal, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'CODER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              tooltip: 'Server Settings',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ServerSettingsDialog(state: state),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewChatButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: FilledButton.tonalIcon(
        onPressed: () {
          state.newChat();
          onSessionSelected?.call();
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? AppTheme.surfaceSubtle
              : AppTheme.lightSurfaceSubtle,
          foregroundColor: textColor,
          side: BorderSide(color: theme.dividerColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;

    if (state.availableModels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          'Model: ${state.activeModel}',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: state.availableModels.contains(state.activeModel)
            ? state.activeModel
            : null,
        isDense: true,
        decoration: InputDecoration(
          labelText: 'Active Model',
          labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
        dropdownColor: isDark ? AppTheme.surfaceSubtle : AppTheme.lightSurface,
        style: TextStyle(color: textColor, fontSize: 12),
        items: state.availableModels.map((m) {
          return DropdownMenuItem(
            value: m,
            child: Text(
              m,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: (model) {
          if (model != null) {
            state.setModel(model);
          }
        },
      ),
    );
  }

  Widget _buildSessionList() {
    if (state.historySessions.isEmpty) {
      return const Center(
        child: Text(
          'No history yet',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: state.historySessions.length,
      itemBuilder: (context, index) {
        final session = state.historySessions[index];
        return _SessionItem(
          session: session,
          state: state,
          onTap: () {
            state.loadSession(session.filename);
            onSessionSelected?.call();
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isConnected =
        state.connectionStatus == ConnectionStateStatus.connected;
    final statusColor = isConnected ? Colors.green : Colors.redAccent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected
                  ? '${state.useTls ? 'wss' : 'ws'}://${state.serverHost}:${state.serverPort}'
                  : 'Disconnected',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 16,
            ),
            tooltip: isDark ? 'Light Theme' : 'Dark Theme',
            onPressed: state.toggleTheme,
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              size: 16,
              color: AppTheme.textMuted,
            ),
            tooltip: 'Reconnect',
            onPressed: () => state.initConnection(),
          ),
        ],
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  const _SessionItem({
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
