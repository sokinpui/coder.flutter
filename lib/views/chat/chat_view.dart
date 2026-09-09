import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/clipboard_service.dart';
import '../../core/theme/app_theme.dart';
import '../settings/context_dialog.dart';
import '../../state/coder_state.dart';
import 'empty_state.dart';
import 'input_bar.dart';
import 'message_bubble.dart';
import 'search_bar.dart';
import 'staged_images_preview.dart';

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
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
          if (widget.state.isSearchVisible)
            ChatSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isRegex: _isRegex,
              isCaseSensitive: _isCaseSensitive,
              currentMatchIndex: _currentMatchIndex,
              totalMatches: _matchedMessageIndices.length,
              searchError: _searchError,
              onToggleCaseSensitive: () {
                setState(() => _isCaseSensitive = !_isCaseSensitive);
                _onSearchChanged();
              },
              onToggleRegex: () {
                setState(() => _isRegex = !_isRegex);
                _onSearchChanged();
              },
              onPreviousMatch: _previousMatch,
              onNextMatch: _nextMatch,
              onClose: () {
                widget.state.toggleSearch(false);
                _maintainInputFocus();
              },
              onSubmitted: (_) => _nextMatch(),
            ),
          Expanded(
            child: messages.isEmpty
                ? ChatEmptyState(
                    activeModel: widget.state.activeModel,
                    onCodeAndChat: () {
                      _promptController.text =
                          'Explain the architecture of this project.';
                      _maintainInputFocus();
                    },
                    onApplyItf: () {
                      _promptController.text =
                          'Write unified diffs for the necessary changes.';
                      _maintainInputFocus();
                    },
                    onAttachImage: _handleAttachImage,
                    onAddFileOrPdf: _handleAddFileOrPdf,
                    onContextAndShell: () {
                      _promptController.text = '/list';
                      _maintainInputFocus();
                    },
                  )
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
          if (_stagedImages.isNotEmpty)
            ChatStagedImagesPreview(
              images: _stagedImages,
              onRemoveImage: _removeStagedImage,
            ),
          ChatInputBar(
            promptController: _promptController,
            inputFocusNode: _inputFocusNode,
            isGenerating: widget.state.isGenerating,
            activeModel: widget.state.activeModel,
            tokenCount: widget.state.tokenCount,
            contextDocumentsCount: widget.state.contextDocuments.length,
            contextFilesCount: widget.state.contextFiles.length,
            isMac: _isMac,
            onAttachImage: _handleAttachImage,
            onAddFileOrPdf: _handleAddFileOrPdf,
            onOpenContextDialog: () => showDialog(
              context: context,
              builder: (_) => ContextDialog(state: widget.state),
            ),
            onCancelGeneration: widget.state.cancelGeneration,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  void _previousMatch() {
    if (_matchedMessageIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchedMessageIndices.length) %
          _matchedMessageIndices.length;
    });
    _scrollToMessage(_matchedMessageIndices[_currentMatchIndex]);
  }

  void _nextMatch() {
    if (_matchedMessageIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex + 1) % _matchedMessageIndices.length;
    });
    _scrollToMessage(_matchedMessageIndices[_currentMatchIndex]);
  }
}
