import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/clipboard_service.dart';
import '../../core/theme/app_theme.dart';
import '../../state/coder_state.dart';
import 'message_bubble.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.state});

  final CoderState state;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final ClipboardService _clipboardService = ClipboardService.create();
  final List<Uint8List> _stagedImages = [];
  StreamSubscription<Uint8List>? _pastedImageSub;

  @override
  void initState() {
    super.initState();
    _pastedImageSub = _clipboardService.onImagePasted.listen((imageBytes) {
      if (!mounted) return;
      setState(() => _stagedImages.add(imageBytes));
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _pastedImageSub?.cancel();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
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
    _inputFocusNode.requestFocus();
  }

  Future<void> _handleAttachImage() async {
    final clipImg = await _clipboardService.getClipboardImage();
    if (clipImg != null) {
      if (mounted) setState(() => _stagedImages.add(clipImg));
      return;
    }
    final picked = await _clipboardService.pickImage();
    if (picked != null && mounted) {
      setState(() => _stagedImages.add(picked));
    }
    _inputFocusNode.requestFocus();
  }

  Future<void> _pasteClipboardImage() async {
    final img = await _clipboardService.getClipboardImage();
    if (img == null || !mounted) {
      return;
    }
    setState(() => _stagedImages.add(img));
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape && widget.state.isGenerating) {
      widget.state.cancelGeneration();
      return KeyEventResult.handled;
    }

    final isMac = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    bool isPasteModifier = false;
    try {
      isPasteModifier = isMac
          ? HardwareKeyboard.instance.isMetaPressed ||
              HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) ||
              HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaRight)
          : HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
              HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight);
    } catch (_) {}

    if (event.logicalKey == LogicalKeyboardKey.keyV && isPasteModifier) {
      _pasteClipboardImage();
    }

    if (event.logicalKey == LogicalKeyboardKey.enter && _inputFocusNode.hasFocus) {
      bool isShiftPressed = false;
      try {
        isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      } catch (_) {}
      if (!isShiftPressed) {
        _submit();
        return KeyEventResult.handled;
      }
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
                  const Icon(Icons.error_outline, color: AppTheme.accentPink, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.state.errorMessage!,
                      style: const TextStyle(color: AppTheme.accentPink, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.state.initConnection(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: messages[index]);
                    },
                  ),
          ),
          if (_stagedImages.isNotEmpty) _buildStagedImagePreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.terminal, color: AppTheme.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            widget.state.sessionTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ready to assist. Send your prompt below.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStagedImagePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _stagedImages.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _stagedImages[i],
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _stagedImages.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 22, color: AppTheme.textMuted),
              tooltip: 'Attach Image / Paste',
              onPressed: _handleAttachImage,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _promptController,
                focusNode: _inputFocusNode,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textMain),
                  decoration: const InputDecoration(
                    hintText: 'Ask anything... (Enter to send, Shift+Enter for newline)',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
              ),
            ),
            ),
            const SizedBox(width: 8),
            if (widget.state.isGenerating)
              IconButton.filled(
                onPressed: widget.state.cancelGeneration,
                icon: const Icon(Icons.stop, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.accentPink,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Cancel (Esc)',
              )
            else
              IconButton.filled(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_upward, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                ),
                tooltip: 'Send',
              ),
          ],
        ),
      ),
    );
  }
}
