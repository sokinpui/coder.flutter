import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_icon_widget.dart';
import '../../core/widgets/hover_animated_button.dart';
import '../../state/coder_state.dart';
import '../settings/server_settings_dialog.dart';
import 'session_list_item.dart';
import '../settings/context_dialog.dart';

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
          _buildContextSection(context),
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

  Widget _buildContextSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filesCount = state.contextFiles.length;
    final docsCount = state.contextDocuments.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: HoverAnimatedButton(
        tooltip: 'Manage Project Context & Documents',
        hoverScale: 1.02,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => ContextDialog(state: state),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.surfaceSubtle
                : AppTheme.lightSurfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.layers_outlined,
                size: 16,
                color: AppTheme.accentCyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Context ($filesCount files, $docsCount docs)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
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
                AppIconWidget(size: 22),
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
      child: HoverAnimatedButton(
        tooltip: 'Start new chat session',
        hoverScale: 1.03,
        onTap: () {
          state.newChat();
          onSessionSelected?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.surfaceSubtle
                : AppTheme.lightSurfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                'New Chat',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ],
          ),
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
        return SessionListItem(
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
