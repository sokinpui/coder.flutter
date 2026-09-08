import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/session_info.dart';
import '../../state/coder_state.dart';
import '../settings/server_settings_dialog.dart';

class SessionSidebar extends StatelessWidget {
  const SessionSidebar({super.key, required this.state, this.onSessionSelected});

  final CoderState state;
  final VoidCallback? onSessionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          _buildNewChatButton(),
          _buildModelSelector(),
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

  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: OutlinedButton.icon(
        onPressed: () {
          state.newChat();
          onSessionSelected?.call();
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New Chat'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textMain,
          side: const BorderSide(color: AppTheme.border),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildModelSelector() {
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
        value: state.availableModels.contains(state.activeModel) ? state.activeModel : null,
        isDense: true,
        decoration: InputDecoration(
          labelText: 'Active Model',
          labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        dropdownColor: AppTheme.surfaceSubtle,
        style: const TextStyle(color: AppTheme.textMain, fontSize: 12),
        items: state.availableModels.map((m) {
          return DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis));
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
          onTap: () {
            state.loadSession(session.filename);
            onSessionSelected?.call();
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isConnected = state.connectionStatus == ConnectionStateStatus.connected;
    final statusColor = isConnected ? Colors.green : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
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
            icon: const Icon(Icons.refresh, size: 16, color: AppTheme.textMuted),
            tooltip: 'Reconnect',
            onPressed: () => state.initConnection(),
          ),
        ],
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  const _SessionItem({required this.session, required this.onTap});

  final SessionInfo session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      leading: const Icon(Icons.chat_bubble_outline, size: 16, color: AppTheme.textMuted),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
      ),
      onTap: onTap,
    );
  }
}
