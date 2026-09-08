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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _showRenameDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      state.sessionTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            Text(
              'Model: ${state.activeModel}${state.tokenCount > 0 ? ' • ≈${state.tokenCount} tokens' : ''}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: state.toggleTheme,
          ),
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
          if (state.isSidebarVisible) ...[
            SessionSidebar(state: state),
            const VerticalDivider(),
          ],
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                const Divider(),
                Expanded(child: ChatView(state: state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              state.isSidebarVisible ? Icons.view_sidebar_outlined : Icons.menu,
            ),
            tooltip: state.isSidebarVisible
                ? 'Collapse Sidebar'
                : 'Expand Sidebar',
            onPressed: state.toggleSidebar,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showRenameDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      state.sessionTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (state.tokenCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surfaceSubtle
                    : AppTheme.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.toll_outlined,
                    size: 13,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '≈${state.tokenCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppTheme.textMain
                          : AppTheme.lightTextMain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceSubtle
                  : AppTheme.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.memory, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  state.activeModel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: state.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'New Chat',
            onPressed: state.newChat,
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: state.sessionTitle);
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
            labelText: 'Title',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (val) {
            state.renameSession(val);
            Navigator.of(ctx).pop();
          },
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
