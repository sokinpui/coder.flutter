import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class PickerItem<T> {
  const PickerItem({
    required this.id,
    required this.title,
    this.description,
    this.badge,
    this.searchText,
    required this.data,
  });

  final String id;
  final String title;
  final String? description;
  final String? badge;
  final String? searchText;
  final T data;
}

class _ScoredPickerItem<T> {
  const _ScoredPickerItem({
    required this.item,
    required this.score,
    required this.index,
  });

  final PickerItem<T> item;
  final int score;
  final int index;
}

class GenericPickerDialog<T> extends StatefulWidget {
  const GenericPickerDialog({
    super.key,
    required this.title,
    required this.items,
    this.activeId,
    required this.onSelected,
    this.titleIcon = Icons.list,
    this.searchPlaceholder = 'Fuzzy search... (↑/↓ navigate, Enter select)',
    this.emptyMessage = 'No matching items found',
    this.width = 540,
    this.maxHeight = 460,
  });

  final String title;
  final List<PickerItem<T>> items;
  final String? activeId;
  final ValueChanged<PickerItem<T>> onSelected;
  final IconData titleIcon;
  final String searchPlaceholder;
  final String emptyMessage;
  final double width;
  final double maxHeight;

  @override
  State<GenericPickerDialog<T>> createState() => _GenericPickerDialogState<T>();
}

class _GenericPickerDialogState<T> extends State<GenericPickerDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<PickerItem<T>> _filteredItems = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    final activeIndex = widget.items.indexWhere(
      (item) => item.id == widget.activeId,
    );
    _selectedIndex = activeIndex != -1 ? activeIndex : 0;
    _searchController.addListener(_onFilterChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
      if (_selectedIndex > 0) {
        _scrollToIndex(_selectedIndex);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items;
        _selectedIndex = 0;
      });
      return;
    }

    final scored = <_ScoredPickerItem<T>>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final score = _scoreItem(query, item);
      if (score != null) {
        scored.add(_ScoredPickerItem(item: item, score: score, index: i));
      }
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.index.compareTo(b.index);
    });

    setState(() {
      _filteredItems = scored.map((s) => s.item).toList();
      _selectedIndex = 0;
    });
  }

  static int? _scoreItem(String query, PickerItem item) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return 0;

    final primary = item.title.toLowerCase();
    final secondary =
        (item.searchText ??
                (item.description != null
                    ? '${item.title} ${item.description}'
                    : ''))
            .toLowerCase();

    final terms = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return 0;

    var totalScore = 0;
    for (final term in terms) {
      final primaryScore = _computeFuzzyScore(term, primary);
      final secondaryScore = secondary.isNotEmpty && secondary != primary
          ? _computeFuzzyScore(term, secondary)
          : null;

      if (primaryScore == null && secondaryScore == null) {
        return null;
      }

      final bestTermScore = (primaryScore != null && secondaryScore != null)
          ? (primaryScore >= secondaryScore ? primaryScore : secondaryScore)
          : (primaryScore ?? secondaryScore!);

      totalScore += bestTermScore;
    }

    return totalScore;
  }

  static int? _computeFuzzyScore(String query, String target) {
    if (query.isEmpty) return 0;
    if (target.isEmpty) return null;

    if (query == target) return 10000;
    if (target.startsWith(query)) {
      return 5000 + (100 - target.length.clamp(0, 100));
    }
    final subIndex = target.indexOf(query);
    if (subIndex != -1) {
      return 3000 - subIndex * 10 + (100 - target.length.clamp(0, 100));
    }

    var qIdx = 0;
    var tIdx = 0;
    var score = 0;
    var consecutive = 0;
    var firstMatchIdx = -1;
    var lastMatchIdx = -1;

    while (qIdx < query.length && tIdx < target.length) {
      if (query[qIdx] == target[tIdx]) {
        if (firstMatchIdx == -1) firstMatchIdx = tIdx;
        lastMatchIdx = tIdx;

        var charScore = 10;
        if (tIdx == 0) {
          charScore += 30;
        } else {
          final prev = target[tIdx - 1];
          if (prev == '/' ||
              prev == '-' ||
              prev == '_' ||
              prev == '.' ||
              prev == ' ') {
            charScore += 25;
          }
        }

        if (consecutive > 0) {
          charScore += consecutive * 15;
        }
        consecutive++;
        score += charScore;
        qIdx++;
      } else {
        consecutive = 0;
      }
      tIdx++;
    }

    if (qIdx < query.length) {
      return null;
    }

    final spread = (lastMatchIdx - firstMatchIdx + 1) - query.length;
    score -= spread * 2;
    return score;
  }

  void _selectItem(PickerItem<T> item) {
    widget.onSelected(item);
    Navigator.of(context).pop();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_filteredItems.isEmpty) return;
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _filteredItems.length;
      });
      _scrollToIndex(_selectedIndex);
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_filteredItems.isEmpty) return;
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + _filteredItems.length) %
            _filteredItems.length;
      });
      _scrollToIndex(_selectedIndex);
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_filteredItems.isNotEmpty &&
          _selectedIndex >= 0 &&
          _selectedIndex < _filteredItems.length) {
        _selectItem(_filteredItems[_selectedIndex]);
      }
      return;
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    const itemHeight = 38.0;
    final targetOffset = index * itemHeight;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              width: widget.width,
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Icon(widget.titleIcon, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    style: TextStyle(fontSize: 13, color: textColor),
                    decoration: InputDecoration(
                      hintText: widget.searchPlaceholder,
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.surfaceSubtle
                          : AppTheme.lightSurfaceSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Flexible(
                  child: _filteredItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              widget.emptyMessage,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isActive = item.id == widget.activeId;
                            final isHighlighted = index == _selectedIndex;

                            return InkWell(
                              onTap: () => _selectItem(item),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? AppTheme.primary.withOpacity(0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.check
                                          : (isHighlighted
                                                ? Icons.arrow_right
                                                : Icons.circle_outlined),
                                      size: 14,
                                      color: isActive
                                          ? AppTheme.primary
                                          : (isHighlighted
                                                ? AppTheme.primary
                                                : AppTheme.textMuted
                                                      .withOpacity(0.5)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (item.badge != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppTheme.surfaceSubtle
                                              : AppTheme.lightSurfaceSubtle,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          item.badge!,
                                          style: AppTheme.monoTextStyle(
                                            fontSize: 10.5,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isActive
                                              ? AppTheme.primary
                                              : textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (item.description != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        item.description!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'active',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredItems.length} items',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const Text(
                        'Esc to cancel',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}
