import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/fuzzy_matcher.dart';
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
    setState(() {
      _filteredItems = FuzzyMatcher.match<PickerItem<T>>(
        query: _searchController.text,
        items: widget.items,
        targetSelector: (item) {
          final targets = [item.title];
          if (item.searchText != null) {
            targets.add(item.searchText!);
          } else if (item.description != null) {
            targets.add('${item.title} ${item.description}');
          }
          return targets;
        },
      );
      _selectedIndex = 0;
    });
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
                          Icon(
                            widget.titleIcon,
                            size: 18,
                            color: AppTheme.primary,
                          ),
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                              color: AppTheme.primary
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
