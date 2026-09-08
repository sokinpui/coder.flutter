import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../state/coder_state.dart';
import 'chat/chat_view.dart';
import 'sidebar/session_sidebar.dart';

class ResponsiveHome extends StatelessWidget {
  const ResponsiveHome({super.key, required this.state});

  final CoderState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Responsive.compactBreakpoint) {
          return _buildCompactLayout(context);
        }
        return _buildExpandedLayout(context);
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.sessionTitle, overflow: TextOverflow.ellipsis),
            Text(
              'Model: ${state.activeModel}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: state.newChat,
          ),
        ],
      ),
      drawer: Drawer(
        child: SessionSidebar(
          state: state,
          onSessionSelected: () => Navigator.of(context).pop(),
        ),
      ),
      body: ChatView(state: state),
    );
  }

  Widget _buildExpandedLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SessionSidebar(state: state),
          const VerticalDivider(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                const Divider(),
                Expanded(child: ChatView(state: state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              state.sessionTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.memory, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  state.activeModel,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
