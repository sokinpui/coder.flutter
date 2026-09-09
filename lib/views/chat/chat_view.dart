import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/clipboard_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/staged_attachment.dart';
import '../settings/context_dialog.dart';
import '../settings/model_picker_dialog.dart';
import '../../state/coder_state.dart';
import 'empty_state.dart';
import 'input_bar.dart';
import 'message_bubble.dart';
import 'search_bar.dart';
import 'staged_attachments_preview.dart';

class _SearchOccurrence {
  const _SearchOccurrence({
    required this.messageIndex,
    required this.messageId,
    required this.occurrenceIndexInMessage,
  });
  final int messageIndex;
  final String messageId;
  final int occurrenceIndexInMessage;
}

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
  List<_SearchOccurrence> _searchOccurrences = [];
  RegExp? _activeSearchPattern;
  bool _isPicking = false;
  String? _searchError;
  final List<StagedAttachment> _stagedAttachments = [];
  int _lastMessageCount = 0;

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
    _lastMessageCount = widget.state.messages.length;
  }

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.state.isSearchVisible && widget.state.isSearchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
        if (_searchOccurrences.isNotEmpty) {
          _scrollToCurrentMatch();
        }
      });
      return;
    }

    if (oldWidget.state.isSearchVisible && !widget.state.isSearchVisible) {
      _searchController.clear();
      setState(() {
        _activeSearchPattern = null;
        _searchOccurrences = [];
        _currentMatchIndex = 0;
        _searchError = null;
      });
    }
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

  void _autoScrollToBottomIfAppropriate() {
    if (widget.state.isSearchVisible) return;
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isNearBottom = (maxScroll - currentScroll) <= 150.0;
    if (isNearBottom) {
      _scrollToBottom();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _activeSearchPattern = null;
        _searchOccurrences = [];
        _currentMatchIndex = 0;
        _searchError = null;
      });
      return;
    }

    try {
      final pattern = _isRegex ? query : RegExp.escape(query);
      final regex = RegExp(pattern, caseSensitive: _isCaseSensitive);
      final occurrences = <_SearchOccurrence>[];
      final messages = widget.state.messages;
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        var occInMsg = 0;
        for (final _ in regex.allMatches(msg.content)) {
          occurrences.add(
            _SearchOccurrence(
              messageIndex: i,
              messageId: msg.id,
              occurrenceIndexInMessage: occInMsg++,
            ),
          );
        }
      }

      setState(() {
        _activeSearchPattern = regex;
        _searchOccurrences = occurrences;
        _currentMatchIndex = 0;
        _searchError = null;
      });
      _scrollToCurrentMatch();
    } catch (e) {
      setState(() {
        _activeSearchPattern = null;
        _searchOccurrences = [];
        _currentMatchIndex = 0;
        _searchError = 'Invalid Regex';
      });
    }
  }

  void _scrollToCurrentMatch() {
    if (_searchOccurrences.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _searchOccurrences.isEmpty) return;
      final matchIndex = _currentMatchIndex.clamp(
        0,
        _searchOccurrences.length - 1,
      );
      final occ = _searchOccurrences[matchIndex];
      final messages = widget.state.messages;
      if (occ.messageIndex < 0 || occ.messageIndex >= messages.length) return;

      final targetId = messages[occ.messageIndex].id;
      final key = _messageKeys.putIfAbsent(targetId, () => GlobalKey());

      void performScroll(BuildContext ctx) {
        final activeKey = ValueKey(
          'active_search_${occ.messageId}_${occ.occurrenceIndexInMessage}',
        );
        Element? targetEl;
        void searchElement(Element el) {
          if (el.widget.key == activeKey) {
            targetEl = el;
            return;
          }
          el.visitChildren(searchElement);
        }

        ctx.visitChildElements(searchElement);

        final scrollTarget = targetEl ?? ctx;
        Scrollable.ensureVisible(
          scrollTarget,
          alignment: 0.5,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
        );
      }

      final targetContext = key.currentContext;
      if (targetContext != null) {
        performScroll(targetContext);
        return;
      }

      if (!_scrollController.hasClients || messages.isEmpty) return;
      final total = messages.length > 1 ? messages.length - 1 : 1;
      final fraction = (occ.messageIndex / total).clamp(0.0, 1.0);
      final targetOffset =
          fraction * _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(targetOffset);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final retryContext = _messageKeys[targetId]?.currentContext;
        if (retryContext != null) {
          performScroll(retryContext);
        }
      });
    });
  }

  Future<void> _submit() async {
    final text = _promptController.text.trim();
    if ((text.isEmpty && _stagedAttachments.isEmpty) ||
        widget.state.isGenerating) {
      return;
    }

    if (widget.state.isSearchVisible) {
      _closeSearch();
    }

    final images = _stagedAttachments
        .where((a) => a.type == AttachmentType.image && a.bytes != null)
        .map((a) => a.bytes!)
        .toList();

    final pdfs = _stagedAttachments
        .where((a) => a.type == AttachmentType.pdf)
        .toList();

    _promptController.clear();
    setState(() => _stagedAttachments.clear());

    for (final pdf in pdfs) {
      if (pdf.path != null) {
        await widget.state.addPdf(pdf.path!);
      }
    }

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
        setState(() {
          _stagedAttachments.add(
            StagedAttachment(
              id: UniqueKey().toString(),
              type: AttachmentType.image,
              name: 'image.png',
              bytes: picked,
            ),
          );
        });
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
      final filename = path.split(RegExp(r'[/\\]')).last;
      if (path.toLowerCase().endsWith('.pdf')) {
        final item = StagedAttachment(
          id: UniqueKey().toString(),
          type: AttachmentType.pdf,
          name: filename,
          path: path,
          isUploading: true,
        );
        setState(() => _stagedAttachments.add(item));
        try {
          await widget.state.addPdf(path);
          if (mounted) {
            setState(() => item.isUploading = false);
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              item.isUploading = false;
              item.error = 'Failed to upload PDF';
            });
          }
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
    setState(() {
      _stagedAttachments.add(
        StagedAttachment(
          id: UniqueKey().toString(),
          type: AttachmentType.image,
          name: 'pasted_image.png',
          bytes: img,
        ),
      );
    });
    _maintainInputFocus();
  }

  void _removeStagedAttachment(int index) {
    if (index < 0 || index >= _stagedAttachments.length) return;
    setState(() => _stagedAttachments.removeAt(index));
    _maintainInputFocus();
  }

  void _openModelPicker() {
    showDialog(
      context: context,
      builder: (_) => ModelPickerDialog(
        models: widget.state.availableModels,
        activeModel: widget.state.activeModel,
        onModelSelected: widget.state.setModel,
      ),
    );
  }

  void _openSearch() {
    widget.state.toggleSearch(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
      if (_searchOccurrences.isNotEmpty) {
        _scrollToCurrentMatch();
      }
    });
  }

  void _closeSearch() {
    widget.state.toggleSearch(false);
    _searchController.clear();
    _maintainInputFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final isModifierActive = _isModifierPressed();

    if (event.logicalKey == LogicalKeyboardKey.keyF && isModifierActive) {
      _openSearch();
      return KeyEventResult.handled;
    }

    if (widget.state.isSearchVisible) {
      final isShift = HardwareKeyboard.instance.isShiftPressed;
      if (event.logicalKey == LogicalKeyboardKey.f3) {
        if (isShift) {
          _previousMatch();
        } else {
          _nextMatch();
        }
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.state.isGenerating) {
      widget.state.cancelGeneration();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.state.isSearchVisible) {
      _closeSearch();
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
        _stagedAttachments.isNotEmpty) {
      _removeStagedAttachment(_stagedAttachments.length - 1);
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
    if (messages.length != _lastMessageCount) {
      final wasNewMessage = messages.length > _lastMessageCount;
      _lastMessageCount = messages.length;
      if (wasNewMessage && !widget.state.isSearchVisible) {
        _scrollToBottom();
      }
    } else if (widget.state.isGenerating && !widget.state.isSearchVisible) {
      _autoScrollToBottomIfAppropriate();
    }

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
                    onPressed: () => widget.state.retryLastAction(),
                    child: const Text('Retry'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppTheme.accentPink,
                    onPressed: () => widget.state.clearError(),
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
              totalMatches: _searchOccurrences.length,
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
              onClose: _closeSearch,
              onSubmitted: (_) => _nextMatch(),
            ),
          Expanded(
            child: messages.isEmpty
                ? ChatEmptyState(
                    activeModel: widget.state.activeModel,
                    onCodeAndChat: () {
                      if (widget.state.isSearchVisible) {
                        _closeSearch();
                      }
                      _promptController.text =
                          'Explain the architecture of this project.';
                      _maintainInputFocus();
                    },
                    onApplyItf: () {
                      if (widget.state.isSearchVisible) {
                        _closeSearch();
                      }
                      _promptController.text =
                          'Write unified diffs for the necessary changes.';
                      _maintainInputFocus();
                    },
                    onAttachImage: _handleAttachImage,
                    onAddFileOrPdf: _handleAddFileOrPdf,
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
                      final activeOcc = _searchOccurrences.isNotEmpty
                          ? _searchOccurrences[_currentMatchIndex]
                          : null;
                      final isThisMsgActive = activeOcc?.messageIndex == index;

                      return MessageBubble(
                        key: key,
                        searchPattern: _activeSearchPattern,
                        activeSearchOccurrence: isThisMsgActive
                            ? activeOcc?.occurrenceIndexInMessage
                            : null,
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
          if (_stagedAttachments.isNotEmpty)
            StagedAttachmentsPreview(
              attachments: _stagedAttachments,
              onRemoveAttachment: _removeStagedAttachment,
            ),
          ChatInputBar(
            promptController: _promptController,
            inputFocusNode: _inputFocusNode,
            isGenerating: widget.state.isGenerating,
            activeModel: widget.state.activeModel,
            onOpenModelPicker: _openModelPicker,
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
    if (_searchOccurrences.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _searchOccurrences.length) %
          _searchOccurrences.length;
    });
    _scrollToCurrentMatch();
  }

  void _nextMatch() {
    if (_searchOccurrences.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchOccurrences.length;
    });
    _scrollToCurrentMatch();
  }
}
