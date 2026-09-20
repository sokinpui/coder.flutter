import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_icon_widget.dart';
import '../../core/widgets/hover_animated_button.dart';
import '../../state/coder_state.dart';
import '../settings/server_settings_dialog.dart';
import 'session_list_item.dart';

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
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(
          children: [
            const AppIconWidget(size: 22),
            const SizedBox(width: 8),
            const Text(
              'CODER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.view_sidebar_outlined,
                size: 18,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Collapse Sidebar',
              onPressed: () {
                if (Responsive.isCompact(context)) {
                  Navigator.of(context).maybePop();
                  return;
                }
                state.toggleSidebar();
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
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => ServerSettingsDialog(state: state),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Text(
                isConnected
                    ? '${state.useTls ? 'wss' : 'ws'}://${state.serverHost}:${state.serverPort}'
                    : 'Disconnected',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.settings_outlined,
              size: 16,
              color: AppTheme.textMuted,
            ),
            tooltip: 'Server Settings',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ServerSettingsDialog(state: state),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 16,
            ),
            tooltip: isDark ? 'Light Theme' : 'Dark Theme',
            onPressed: state.toggleTheme,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
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
