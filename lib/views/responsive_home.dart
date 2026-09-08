import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../core/widgets/hover_animated_button.dart';
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
        title: HoverAnimatedButton(
          tooltip: 'Rename conversation',
          hoverScale: 1.03,
          hoverColor: isDark
              ? AppTheme.surfaceSubtle
              : AppTheme.lightSurfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(width: 6),
              const Icon(
                Icons.edit_outlined,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: state.toggleTheme,
          ),
          HoverAnimatedButton(
            tooltip: 'New Chat',
            hoverScale: 1.15,
            onTap: state.newChat,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add, size: 20),
            ),
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: HoverAnimatedButton(
                tooltip: 'Rename conversation',
                hoverScale: 1.03,
                hoverColor: isDark
                    ? AppTheme.surfaceSubtle
                    : AppTheme.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: state.toggleTheme,
          ),
          HoverAnimatedButton(
            tooltip: 'New Chat',
            hoverScale: 1.15,
            onTap: state.newChat,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add, size: 20),
            ),
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
