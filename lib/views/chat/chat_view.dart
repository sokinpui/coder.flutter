import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/clipboard_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/hover_animated_button.dart';
import '../../core/theme/app_theme.dart';
import '../settings/context_dialog.dart';
import '../../state/coder_state.dart';
import 'message_bubble.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.state});

  final CoderState state;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final Map<String, GlobalKey> _messageKeys = {};
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final ClipboardService _clipboardService = ClipboardService.create();

  bool _isRegex = false;
  bool _isCaseSensitive = false;
  int _currentMatchIndex = 0;
  List<int> _matchedMessageIndices = [];
  RegExp? _activeSearchPattern;
  bool _isPicking = false;
  String? _searchError;
  final List<Uint8List> _stagedImages = [];
  StreamSubscription<Uint8List>? _pastedImageSub;

  bool get _isMac =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool _isModifierPressed() {
    try {
      if (_isMac) {
        return HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.metaLeft,
            ) ||
            HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.metaRight,
            );
      }
      return HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isLogicalKeyPressed(
            LogicalKeyboardKey.controlLeft,
          ) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(
            LogicalKeyboardKey.controlRight,
          );
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _pastedImageSub = _clipboardService.onImagePasted.listen((bytes) {
      if (!mounted) return;
      setState(() => _stagedImages.add(bytes));
      _maintainInputFocus();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pastedImageSub?.cancel();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _maintainInputFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _inputFocusNode.canRequestFocus) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _activeSearchPattern = null;
        _matchedMessageIndices = [];
        _currentMatchIndex = 0;
        _searchError = null;
      });
      return;
    }

    try {
      final pattern = _isRegex ? query : RegExp.escape(query);
      final regex = RegExp(pattern, caseSensitive: _isCaseSensitive);
      final matches = <int>[];
      final messages = widget.state.messages;
      for (var i = 0; i < messages.length; i++) {
        if (regex.hasMatch(messages[i].content) ||
            (messages[i].reasoning.isNotEmpty &&
                regex.hasMatch(messages[i].reasoning))) {
          matches.add(i);
        }
      }

      setState(() {
        _activeSearchPattern = regex;
        _matchedMessageIndices = matches;
        _currentMatchIndex = 0;
        _searchError = null;
      });

      if (matches.isNotEmpty) {
        _scrollToMessage(matches[0]);
      }
    } catch (e) {
      setState(() {
        _activeSearchPattern = null;
        _matchedMessageIndices = [];
        _currentMatchIndex = 0;
        _searchError = 'Invalid Regex';
      });
    }
  }

  void _scrollToMessage(int index) {
    final messages = widget.state.messages;
    if (index < 0 || index >= messages.length) return;
    final key = _messageKeys[messages[index].id];
    final targetContext = key?.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submit() {
    final text = _promptController.text.trim();
    if ((text.isEmpty && _stagedImages.isEmpty) || widget.state.isGenerating) {
      return;
    }
    final images = List<Uint8List>.from(_stagedImages);
    _promptController.clear();
    setState(() => _stagedImages.clear());
    widget.state.sendPrompt(text, images: images);
    _scrollToBottom();
    _maintainInputFocus();
  }

  Future<void> _handleAttachImage() async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final picked = await _clipboardService.pickImage();
      if (picked != null && mounted) {
        setState(() => _stagedImages.add(picked));
      }
    } finally {
      _isPicking = false;
      _maintainInputFocus();
    }
  }

  Future<void> _handleAddFileOrPdf() async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final path = await _clipboardService.pickFilePath();
      if (path == null || path.isEmpty || !mounted) {
        return;
      }
      if (path.toLowerCase().endsWith('.pdf')) {
        final res = await widget.state.addPdf(path);
        if (mounted && res != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res), duration: const Duration(seconds: 2)),
          );
        }
        return;
      }
      await widget.state.addContextPaths([path]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $path to context'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _isPicking = false;
      _maintainInputFocus();
    }
  }

  Future<void> _pasteClipboardImage() async {
    final img = await _clipboardService.getClipboardImage();
    if (img == null || !mounted) {
      _maintainInputFocus();
      return;
    }
    setState(() => _stagedImages.add(img));
    _maintainInputFocus();
  }

  void _removeStagedImage(int index) {
    if (index < 0 || index >= _stagedImages.length) {
      return;
    }
    setState(() => _stagedImages.removeAt(index));
    _maintainInputFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isModifierActive = _isModifierPressed();

    if (event.logicalKey == LogicalKeyboardKey.keyF && isModifierActive) {
      widget.state.toggleSearch(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.state.isGenerating) {
      widget.state.cancelGeneration();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.state.isSearchVisible) {
      widget.state.toggleSearch(false);
      _maintainInputFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyV && isModifierActive) {
      _pasteClipboardImage();
      _maintainInputFocus();
    }

    final isBackspaceOrDelete =
        event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete;
    if (isBackspaceOrDelete &&
        _promptController.text.isEmpty &&
        _stagedImages.isNotEmpty) {
      _removeStagedImage(_stagedImages.length - 1);
      return KeyEventResult.handled;
    }

    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;

    if (isEnter && _inputFocusNode.hasFocus && isModifierActive) {
      _submit();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.state.messages;
    _scrollToBottom();

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          if (widget.state.errorMessage != null)
            Container(
              color: AppTheme.accentPink.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.accentPink,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.state.errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.accentPink,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.state.initConnection(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (widget.state.isSearchVisible) _buildSearchBar(),
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final key = _messageKeys.putIfAbsent(
                        msg.id,
                        () => GlobalKey(),
                      );
                      final isTargetMatch =
                          _matchedMessageIndices.isNotEmpty &&
                          _matchedMessageIndices[_currentMatchIndex] == index;
                      return MessageBubble(
                        key: key,
                        searchPattern: _activeSearchPattern,
                        isSearchMatch: isTargetMatch,
                        message: msg,
                        onDelete: () => widget.state.deleteMessage(msg.id),
                        onBranch: () => widget.state.branchFrom(msg.id),
                        onEdit: (newContent) =>
                            widget.state.editMessage(msg.id, newContent),
                        onRegenerate: () => widget.state.regenerateFrom(msg.id),
                        onApplyItf: (content) async {
                          final summary = await widget.state.applyItf(
                            content: content,
                          );
                          if (summary != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(summary),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        onUndoItf: () async {
                          final summary = await widget.state.undoItf();
                          if (summary != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(summary),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          if (_stagedImages.isNotEmpty) _buildStagedImagePreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMatches = _matchedMessageIndices.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceSubtle : AppTheme.lightSurfaceSubtle,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Find in conversation (supports regex)...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onSubmitted: (_) {
                if (!hasMatches) return;
                setState(() {
                  _currentMatchIndex =
                      (_currentMatchIndex + 1) % _matchedMessageIndices.length;
                });
                _scrollToMessage(_matchedMessageIndices[_currentMatchIndex]);
              },
            ),
          ),
          HoverAnimatedButton(
            tooltip: 'Match Case (Alt+C)',
            hoverScale: 1.1,
            onTap: () {
              setState(() => _isCaseSensitive = !_isCaseSensitive);
              _onSearchChanged();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _isCaseSensitive
                    ? AppTheme.primary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isCaseSensitive
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          HoverAnimatedButton(
            tooltip: 'Use Regular Expression (Alt+R)',
            hoverScale: 1.1,
            onTap: () {
              setState(() => _isRegex = !_isRegex);
              _onSearchChanged();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _isRegex
                    ? AppTheme.primary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '.*',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isRegex ? AppTheme.primary : AppTheme.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _searchError ??
                (_searchController.text.isEmpty
                    ? ''
                    : (hasMatches
                          ? '${_currentMatchIndex + 1} of ${_matchedMessageIndices.length}'
                          : 'No results')),
            style: TextStyle(
              fontSize: 11.5,
              color: _searchError != null
                  ? AppTheme.accentPink
                  : AppTheme.textMuted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 16),
            tooltip: 'Previous match (Shift+Enter)',
            onPressed: !hasMatches
                ? null
                : () {
                    setState(() {
                      _currentMatchIndex =
                          (_currentMatchIndex -
                              1 +
                              _matchedMessageIndices.length) %
                          _matchedMessageIndices.length;
                    });
                    _scrollToMessage(
                      _matchedMessageIndices[_currentMatchIndex],
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 16),
            tooltip: 'Next match (Enter)',
            onPressed: !hasMatches
                ? null
                : () {
                    setState(() {
                      _currentMatchIndex =
                          (_currentMatchIndex + 1) %
                          _matchedMessageIndices.length;
                    });
                    _scrollToMessage(
                      _matchedMessageIndices[_currentMatchIndex],
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Close (Esc)',
            onPressed: () {
              widget.state.toggleSearch(false);
              _maintainInputFocus();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Explore Coder & Models',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Active Model: ${widget.state.activeModel}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildExploreCard(
                    icon: Icons.code,
                    title: 'Code and Chat',
                    desc:
                        'Build features, inspect repositories, and query methods.',
                    onTap: () {
                      _promptController.text =
                          'Explain the architecture of this project.';
                      _maintainInputFocus();
                    },
                  ),
                  _buildExploreCard(
                    icon: Icons.auto_fix_high,
                    title: 'Apply ITF Changes',
                    desc:
                        'Parse markdown diff blocks and patch code directly to files.',
                    onTap: () {
                      _promptController.text =
                          'Write unified diffs for the necessary changes.';
                      _maintainInputFocus();
                    },
                  ),
                  _buildExploreCard(
                    icon: Icons.image_outlined,
                    title: 'Image & UI Vision',
                    desc:
                        'Paste or attach screenshots for UI review and feedback.',
                    onTap: _handleAttachImage,
                  ),
                  _buildExploreCard(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'PDF & Vision Docs',
                    desc:
                        'Add PDF documents to context for automatic page rendering with pti.',
                    onTap: _handleAddFileOrPdf,
                  ),
                  _buildExploreCard(
                    icon: Icons.terminal,
                    title: 'Context & Shell',
                    desc:
                        'Add project files to context with /file and inspect with /list.',
                    onTap: () {
                      _promptController.text = '/list';
                      _maintainInputFocus();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.textMain
                          : AppTheme.lightTextMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStagedImagePreview() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : AppTheme.lightSurface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _stagedImages.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.memory(
                              _stagedImages[i],
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _StagedImageDeleteButton(
                          onDelete: () => _removeStagedImage(i),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = Responsive.isCompact(context);

    final horizontalMargin = isCompact ? 10.0 : 16.0;
    final bottomMargin = isCompact ? 8.0 : 16.0;

    return SafeArea(
      top: false,
      child: Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 840),
        margin: EdgeInsets.fromLTRB(horizontalMargin, 6, horizontalMargin, bottomMargin),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12, vertical: isCompact ? 8 : 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _promptController,
              focusNode: _inputFocusNode,
              maxLines: isCompact ? 5 : 8,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
              ),
              decoration: InputDecoration(
                hintText: isCompact
                    ? 'Message Coder...'
                    : 'Start typing a prompt... (${_isMac ? 'Cmd+Enter' : 'Ctrl+Enter'} to send)',
                hintStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 20,
                  ),
                  tooltip: 'Attach Image / Paste',
                  onPressed: _handleAttachImage,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file_outlined, size: 20),
                  tooltip: 'Add File / PDF to Context',
                  onPressed: _handleAddFileOrPdf,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surfaceSubtle
                        : AppTheme.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.memory,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.state.activeModel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.state.tokenCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.surfaceSubtle
                          : AppTheme.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.toll_outlined,
                          size: 12,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '≈${widget.state.tokenCount}',
                          style: AppTheme.monoTextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.state.contextDocuments.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => ContextDialog(state: widget.state),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceSubtle
                            : AppTheme.lightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 12,
                            color: AppTheme.accentYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.state.contextDocuments.length} doc${widget.state.contextDocuments.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (widget.state.contextFiles.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => ContextDialog(state: widget.state),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceSubtle
                            : AppTheme.lightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            size: 12,
                            color: AppTheme.accentCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.state.contextFiles.length} file${widget.state.contextFiles.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.state.isGenerating)
                  HoverAnimatedButton(
                    tooltip: 'Cancel (Esc)',
                    hoverScale: 1.10,
                    onTap: widget.state.cancelGeneration,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stop,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  HoverAnimatedButton(
                    tooltip: 'Send (${_isMac ? 'Cmd+Enter' : 'Ctrl+Enter'})',
                    hoverScale: 1.12,
                    onTap: _submit,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _StagedImageDeleteButton extends StatefulWidget {
  const _StagedImageDeleteButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  State<_StagedImageDeleteButton> createState() =>
      _StagedImageDeleteButtonState();
}

class _StagedImageDeleteButtonState extends State<_StagedImageDeleteButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF453A);
    final buttonColor = _isHovered ? activeColor : AppTheme.accentPink;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onDelete,
        child: Tooltip(
          message: 'Remove image',
          waitDuration: const Duration(milliseconds: 400),
          child: AnimatedScale(
            scale: _isPressed ? 0.88 : (_isHovered ? 1.18 : 1.0),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedRotation(
              turns: _isHovered ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withOpacity(_isHovered ? 0.5 : 0.28),
                      blurRadius: _isHovered ? 6 : 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
