import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../core/widgets/hover_animated_button.dart';
import '../core/utils/responsive.dart';
import '../state/coder_state.dart';
import 'chat/chat_view.dart';
import 'sidebar/session_sidebar.dart';
import 'widgets/disconnected_floating_window.dart';

class ResponsiveHome extends StatefulWidget {
  const ResponsiveHome({super.key, required this.state});

  final CoderState state;

  @override
  State<ResponsiveHome> createState() => _ResponsiveHomeState();
}

class _ResponsiveHomeState extends State<ResponsiveHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _chatViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < Responsive.compactBreakpoint) {
              return _buildCompactLayout(context);
            }
            return _buildExpandedLayout(context);
          },
        ),
        DisconnectedFloatingWindow(state: widget.state),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
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
                  widget.state.sessionTitle,
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
              widget.state.isSearchVisible ? Icons.search_off : Icons.search,
            ),
            tooltip: 'Find in chat (Cmd+F / Ctrl+F)',
            onPressed: widget.state.toggleSearch,
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: widget.state.toggleTheme,
          ),
          HoverAnimatedButton(
            tooltip: 'New Chat',
            hoverScale: 1.15,
            onTap: widget.state.newChat,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add, size: 20),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SessionSidebar(
          state: widget.state,
          onSessionSelected: () => Navigator.of(context).pop(),
        ),
      ),
      body: ChatView(key: _chatViewKey, state: widget.state),
      );
  }


  Widget _buildExpandedLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: widget.state.isSidebarVisible ? 280.0 : 0.0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 280.0,
                maxWidth: 280.0,
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    Expanded(child: SessionSidebar(state: widget.state)),
                    const VerticalDivider(width: 1),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                const Divider(),
                Expanded(child: ChatView(key: _chatViewKey, state: widget.state)),
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
              widget.state.isSidebarVisible
                  ? Icons.view_sidebar_outlined
                  : Icons.menu,
            ),
            tooltip: widget.state.isSidebarVisible
                ? 'Collapse Sidebar'
                : 'Expand Sidebar',
            onPressed: widget.state.toggleSidebar,
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
                        widget.state.sessionTitle,
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
              widget.state.isSearchVisible ? Icons.search_off : Icons.search,
            ),
            tooltip: 'Find in chat (Cmd+F / Ctrl+F)',
            onPressed: widget.state.toggleSearch,
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: widget.state.toggleTheme,
          ),
          HoverAnimatedButton(
            tooltip: 'New Chat',
            onTap: widget.state.newChat,
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
    final controller = TextEditingController(text: widget.state.sessionTitle);
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
            widget.state.renameSession(val);
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
              widget.state.renameSession(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
