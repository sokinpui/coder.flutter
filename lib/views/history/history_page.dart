import 'package:flutter/material.dart';

import '../../core/utils/fuzzy_matcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/session_info.dart';
import '../../state/coder_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.state});

  final CoderState state;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _refreshHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _refreshHistory() async {
    setState(() => _isRefreshing = true);
    try {
      await widget.state.fetchHistory();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  List<SessionInfo> _filterSessions(List<SessionInfo> sessions) {
    return FuzzyMatcher.match<SessionInfo>(
      query: _searchController.text,
      items: sessions,
      targetSelector: (session) => [session.title, session.filename],
    );
  }

  Future<void> _selectSession(SessionInfo session) async {
    await widget.state.loadSession(session.filename);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showRenameDialog(SessionInfo session) {
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
          onSubmitted: (val) {
            _handleRename(session, val);
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
              _handleRename(session, controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRename(SessionInfo session, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty || trimmed == session.title) return;
    await widget.state.renameSession(trimmed);
    await _refreshHistory();
  }

  String _formatTimestamp(SessionInfo session) {
    final date = session.modifiedAt ?? session.createdAt;
    if (date == null) {
      return session.filename;
    }
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minute';
    }
    if (difference.inDays == 1) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Yesterday, $hour:$minute';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;
    final allSessions = widget.state.historySessions;
    final filteredSessions = _filterSessions(allSessions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: _isRefreshing ? null : _refreshHistory,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(fontSize: 13.5, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Fuzzy search conversations...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.surface
                        : AppTheme.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      '${filteredSessions.length} conversation${filteredSessions.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _buildBody(
                  isDark: isDark,
                  textColor: textColor,
                  theme: theme,
                  allSessions: allSessions,
                  filteredSessions: filteredSessions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color textColor,
    required ThemeData theme,
    required List<SessionInfo> allSessions,
    required List<SessionInfo> filteredSessions,
  }) {
    if (allSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_outlined,
              size: 48,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No conversation history yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 44,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No conversations match "${_searchController.text.trim()}"',
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredSessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        final timeLabel = _formatTimestamp(session);

        return Material(
          color: isDark ? AppTheme.surface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _selectSession(session),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    tooltip: 'Rename conversation',
                    onPressed: () => _showRenameDialog(session),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
