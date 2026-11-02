import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../core/services/settings_service.dart';
import '../core/rpc/coder_rpc_client.dart';
import '../models/chat_message.dart';
import '../models/session_info.dart';

enum ConnectionStateStatus { disconnected, connecting, connected, error }

class CoderState extends ChangeNotifier {
  CoderState() {
    _client.onNotification = _onServerNotification;
    _client.onDisconnected = _handleUnexpectedDisconnect;
    _loadSavedSettingsAndConnect();
  }

  final CoderRpcClient _client = CoderRpcClient();
  final SettingsService _settingsService = SettingsService.create();

  String _serverHost = '127.0.0.1';
  int _serverPort = 9005;
  bool _useTls = false;
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);
  bool _isSidebarVisible = true;
  String _mode = 'chat';
  String _activeModel = 'default';
  String _sessionTitle = 'New Chat';
  String? _currentSessionFilename;
  List<String> _availableModels = [];
  bool _isSearchVisible = false;
  List<String> _contextFiles = [];
  List<String> _contextDocuments = [];
  List<SessionInfo> _historySessions = [];
  final List<ChatMessage> _messages = [];

  ConnectionStateStatus _connectionStatus = ConnectionStateStatus.disconnected;
  String? _errorMessage;
  Future<void> Function()? _lastFailedAction;
  bool _isGenerating = false;
  int _tokenCount = 0;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isAutoReconnecting = false;
  String _pendingContent = '';
  String _pendingReasoning = '';
  Timer? _smoothStreamTimer;
  bool _isStreamDonePending = false;
  int _streamTokenCount = 0;
  bool _hasAttemptedConnection = false;
  Set<String> _previousSessionFilenames = {};
  bool _isLoadingSession = false;
  String? _loadingSessionFilename;

  String get serverHost => _serverHost;
  int get serverPort => _serverPort;
  bool get useTls => _useTls;
  ThemeMode get themeMode => themeModeNotifier.value;
  String get mode => _mode;
  bool get isSearchVisible => _isSearchVisible;
  bool get isSidebarVisible => _isSidebarVisible;
  String get activeModel => _activeModel;
  String get sessionTitle => _sessionTitle;
  String? get currentSessionFilename => _currentSessionFilename;
  List<String> get availableModels => _availableModels;
  List<String> get contextFiles => List.unmodifiable(_contextFiles);
  List<String> get contextDocuments => List.unmodifiable(_contextDocuments);
  List<SessionInfo> get historySessions => _historySessions;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ConnectionStateStatus get connectionStatus => _connectionStatus;
  String? get errorMessage => _errorMessage;
  bool get isGenerating => _isGenerating;
  bool get isAutoReconnecting => _isAutoReconnecting;
  int get tokenCount => _tokenCount;
  bool get hasAttemptedConnection => _hasAttemptedConnection;
  bool get isLoadingSession => _isLoadingSession;
  String? get loadingSessionFilename => _loadingSessionFilename;

  bool isSessionSelected(SessionInfo session) {
    if (_loadingSessionFilename != null) {
      return _loadingSessionFilename == session.filename;
    }
    if (_currentSessionFilename != null) {
      return _currentSessionFilename == session.filename;
    }
    if (_messages.isEmpty) {
      return false;
    }
    if (_sessionTitle.isNotEmpty && _sessionTitle != 'New Chat') {
      return session.title == _sessionTitle;
    }
    if (_historySessions.isNotEmpty) {
      return _historySessions.first.filename == session.filename;
    }
    return false;
  }

  String get httpBaseUrl {
    final scheme = _useTls ? 'https' : 'http';
    return '$scheme://$_serverHost:$_serverPort';
  }

  String get pdfUploadUrl => '$httpBaseUrl/upload/pdf';

  String get websocketUrl {
    final scheme = _useTls ? 'wss' : 'ws';
    return '$scheme://$_serverHost:$_serverPort/ws';
  }

  Future<void> _loadSavedSettingsAndConnect() async {
    final settings = await _settingsService.loadSettings();
    final host = settings['serverHost'] as String?;
    if (host != null && host.isNotEmpty) {
      _serverHost = host;
    }
    final port = (settings['serverPort'] as num?)?.toInt();
    if (port != null && port > 0) {
      _serverPort = port;
    }
    final tls = settings['useTls'] as bool?;
    if (tls != null) {
      _useTls = tls;
    }
    final modeStr = settings['themeMode'] as String?;
    if (modeStr != null) {
      themeModeNotifier.value =
          modeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    final isSidebar = settings['isSidebarVisible'] as bool?;
    if (isSidebar != null) {
      _isSidebarVisible = isSidebar;
    }
    final savedMode = settings['mode'] as String?;
    if (savedMode != null && savedMode.isNotEmpty && savedMode != 'coder') {
      _mode = savedMode;
    } else {
      _mode = 'chat';
    }
    final modelStr = settings['activeModel'] as String?;
    if (modelStr != null && modelStr.isNotEmpty) {
      _activeModel = modelStr;
    }
    notifyListeners();
    await initConnection();
  }

  Future<void> _persistSettings() async {
    await _settingsService.saveSettings({
      'serverHost': _serverHost,
      'serverPort': _serverPort,
      'useTls': _useTls,
      'themeMode': themeMode == ThemeMode.light ? 'light' : 'dark',
      'isSidebarVisible': _isSidebarVisible,
      'activeModel': _activeModel,
      'mode': _mode,
    });
  }

  void toggleTheme() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
    _persistSettings();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> retryLastAction() async {
    final action = _lastFailedAction;
    _errorMessage = null;
    notifyListeners();
    if (action != null) {
      await action();
      return;
    }
    await initConnection(preserveSession: true);
  }

  void _handleUnexpectedDisconnect() {
    _flushSmoothStream();
    if (_connectionStatus == ConnectionStateStatus.disconnected) return;
    _connectionStatus = ConnectionStateStatus.disconnected;
    _isAutoReconnecting = true;
    notifyListeners();
    _scheduleAutoReconnect();
  }

  void _scheduleAutoReconnect() {
    _reconnectTimer?.cancel();
    final delay = (_reconnectAttempts < 4)
        ? Duration(seconds: 2 * (_reconnectAttempts + 1))
        : const Duration(seconds: 12);
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () async {
      if (_connectionStatus == ConnectionStateStatus.connected) return;
      await initConnection(preserveSession: true);
    });
  }

  void toggleSidebar() {
    _isSidebarVisible = !_isSidebarVisible;
    notifyListeners();
    _persistSettings();
  }

  void toggleSearch([bool? visible]) {
    final next = visible ?? !_isSearchVisible;
    if (_isSearchVisible == next) return;
    _isSearchVisible = next;
    notifyListeners();
  }

  Future<void> updateServerAddress(
    String host,
    int port, {
    bool? useTls,
  }) async {
    var cleanedHost = host.trim();
    var tls = useTls ?? _useTls;
    if (cleanedHost.startsWith('ws://')) {
      tls = false;
      cleanedHost = cleanedHost.substring(5);
    } else if (cleanedHost.startsWith('wss://')) {
      tls = true;
      cleanedHost = cleanedHost.substring(6);
    }
    _serverHost = cleanedHost;
    _serverPort = port;
    _useTls = tls;
    notifyListeners();
    await _persistSettings();
    await initConnection();
  }

  Future<void> initConnection({bool preserveSession = false}) async {
    _hasAttemptedConnection = true;
    _reconnectTimer?.cancel();
    _connectionStatus = ConnectionStateStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client.connect(websocketUrl);
      _reconnectAttempts = 0;
      _isAutoReconnecting = false;
      _connectionStatus = ConnectionStateStatus.connected;
      notifyListeners();

      if (!preserveSession || _messages.isEmpty) {
        await _initializeRemoteSession();
      } else {
        await fetchContext();
      }
      await fetchModels();
      await fetchHistory();
    } catch (e) {
      _connectionStatus = ConnectionStateStatus.error;
      _errorMessage = 'Failed to connect to Coder server ($websocketUrl): $e';
      _lastFailedAction = () =>
          initConnection(preserveSession: preserveSession);
      _isAutoReconnecting = true;
      _scheduleAutoReconnect();
      notifyListeners();
    }
  }

  void cancelAutoReconnect() {
    _reconnectTimer?.cancel();
    _isAutoReconnecting = false;
    notifyListeners();
  }

  Future<void> _initializeRemoteSession() async {
    try {
      _currentSessionFilename = null;
      _previousSessionFilenames = _historySessions.map((s) => s.filename).toSet();
      _mode = 'chat';
      final params = <String, dynamic>{'mode': _mode};
      if (_activeModel != 'default') {
        params['model'] = _activeModel;
      }
      final res = await _client.request('session/init', params);
      if (res is Map && res.containsKey('mode') && res['mode'] != null) {
        _mode = res['mode'] as String;
      }
      if (res is Map) {
        final fn = res['filename']?.toString() ??
            res['id']?.toString() ??
            res['sessionFilename']?.toString() ??
            res['session_filename']?.toString() ??
            res['sessionId']?.toString();
        if (fn != null && fn.isNotEmpty) {
          _currentSessionFilename = fn;
        }
        if (res.containsKey('model')) {
          _activeModel = res['model'] as String;
        }
        if (res.containsKey('tokenCount')) {
          _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? 0;
        }
        if (res.containsKey('contextFiles')) {
          _contextFiles =
              (res['contextFiles'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
        if (res.containsKey('contextDocuments')) {
          _contextDocuments =
              (res['contextDocuments'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
      }
      _sessionTitle = 'New Chat';
      _messages.clear();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> newChat() async {
    _flushSmoothStream();
    _isStreamDonePending = false;
    _streamTokenCount = 0;
    _isSearchVisible = false;
    _currentSessionFilename = null;
    _previousSessionFilenames = _historySessions.map((s) => s.filename).toSet();
    _isGenerating = false;
    _tokenCount = 0;
    _messages.clear();
    _contextFiles.clear();
    _contextDocuments.clear();
    _sessionTitle = 'New Chat';
    _mode = 'chat';
    _isLoadingSession = true;
    _loadingSessionFilename = null;
    notifyListeners();
    try {
      await _initializeRemoteSession();
      await fetchHistory();
    } finally {
      _isLoadingSession = false;
      notifyListeners();
    }
  }

  Future<void> sendPrompt(String text, {List<Uint8List>? images}) async {
    final prompt = text.trim();
    final hasImages = images != null && images.isNotEmpty;
    if (prompt.isEmpty && !hasImages) {
      return;
    }
    if (_isGenerating) {
      return;
    }
    _flushSmoothStream();
    _isStreamDonePending = false;
    _streamTokenCount = 0;
    _isSearchVisible = false;

    final effectivePrompt = prompt.isEmpty && hasImages
        ? 'What is in this image?'
        : prompt;
    final baseTimestamp = DateTime.now().millisecondsSinceEpoch;
    var offset = 0;

    if (hasImages) {
      for (final img in images) {
        _messages.add(
          ChatMessage(
            id: (baseTimestamp + offset++).toString(),
            author: MessageAuthor.image,
            content: 'Image',
            imageData: img,
          ),
        );
      }
    }

    final userMsg = ChatMessage(
      id: (baseTimestamp + offset++).toString(),
      author: MessageAuthor.user,
      content: effectivePrompt,
    );
    _messages.add(userMsg);

    final aiMsg = ChatMessage(
      id: (baseTimestamp + offset++).toString(),
      author: MessageAuthor.assistant,
      content: '',
      reasoning: '',
      isGenerating: true,
    );
    _messages.add(aiMsg);

    _isGenerating = true;
    notifyListeners();

    try {
      final params = <String, dynamic>{'content': effectivePrompt};
      if (hasImages) {
        params['images'] = images.map(base64Encode).toList();
      }
      final res = await _client.request('session/prompt', params);
      if (res is Map) {
        final fn = res['filename']?.toString() ??
            res['id']?.toString() ??
            res['sessionFilename']?.toString() ??
            res['sessionId']?.toString();
        if (fn != null && fn.isNotEmpty) {
          _currentSessionFilename = fn;
        }
      }
    } catch (e) {
      aiMsg.content = 'Error sending prompt: $e';
      _lastFailedAction = () => sendPrompt(text, images: images);
      aiMsg.isGenerating = false;
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> cancelGeneration() async {
    if (!_isGenerating) {
      return;
    }
    try {
      await _client.request('session/cancel');
    } catch (_) {}
    _flushSmoothStream();
    _isStreamDonePending = false;
    _streamTokenCount = 0;
    _isGenerating = false;
    for (final m in _messages) {
      m.isGenerating = false;
    }
    if (_messages.isNotEmpty &&
        _messages.last.author == MessageAuthor.assistant &&
        _messages.last.content.isEmpty &&
        _messages.last.reasoning.isEmpty) {
      _messages.removeLast();
    }
    notifyListeners();
  }

  Future<void> renameSession(String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _sessionTitle = trimmed;
    if (_currentSessionFilename != null) {
      final idx = _historySessions.indexWhere(
        (s) => s.filename == _currentSessionFilename,
      );
      if (idx != -1) {
        final old = _historySessions[idx];
        _historySessions[idx] = SessionInfo(
          filename: old.filename,
          title: trimmed,
          createdAt: old.createdAt,
          modifiedAt: DateTime.now(),
        );
      }
    }
    notifyListeners();
    try {
      await _client.request('session/rename', {'title': trimmed});
      await fetchHistory();
    } catch (_) {}
  }

  Future<void> deleteMessage(String id) async {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index == -1) {
      return;
    }
    _messages.removeAt(index);
    notifyListeners();
    try {
      final res = await _client.request('session/message/delete', {
        'index': index,
      });
      if (res is Map && res.containsKey('messages')) {
        final parsed = _parseMessagesFromRaw(res['messages'] as List?);
        _messages.clear();
        _messages.addAll(parsed);
      }
      if (res is Map && res.containsKey('tokenCount')) {
        _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? _tokenCount;
        notifyListeners();
      }
      await fetchHistory();
    } catch (_) {}
  }

  Future<void> regenerateFrom(String messageId) async {
    if (_isGenerating) {
      return;
    }
    _flushSmoothStream();
    _isStreamDonePending = false;
    _streamTokenCount = 0;
    _isSearchVisible = false;
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      return;
    }

    final targetMsg = _messages[index];
    int promptMsgIndex = -1;
    if (targetMsg.author == MessageAuthor.assistant ||
        targetMsg.author == MessageAuthor.toolCall ||
        targetMsg.author == MessageAuthor.toolResult) {
      for (var i = index - 1; i >= 0; i--) {
        if (_messages[i].author == MessageAuthor.user) {
          promptMsgIndex = i;
          break;
        }
      }
    } else if (targetMsg.author == MessageAuthor.user) {
      promptMsgIndex = index;
    } else if (targetMsg.author == MessageAuthor.image) {
      for (var i = index + 1; i < _messages.length; i++) {
        if (_messages[i].author == MessageAuthor.user) {
          promptMsgIndex = i;
          break;
        }
      }
    }

    if (promptMsgIndex == -1) {
      return;
    }

    _messages.removeRange(promptMsgIndex + 1, _messages.length);

    final aiMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: MessageAuthor.assistant,
      content: '',
      reasoning: '',
      isGenerating: true,
    );
    _messages.add(aiMsg);
    _isGenerating = true;
    notifyListeners();

    try {
      await _client.request('session/regenerate', {'index': promptMsgIndex});
    } catch (e) {
      aiMsg.content = 'Error regenerating: $e';
      aiMsg.isGenerating = false;
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> editMessage(String id, String newContent) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final index = _messages.indexWhere((m) => m.id == id);
    if (index == -1) {
      return;
    }

    _messages[index].content = trimmed;
    notifyListeners();

    try {
      final res = await _client.request('session/message/edit', {
        'index': index,
        'content': trimmed,
      });
      if (res is Map && res.containsKey('tokenCount')) {
        _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? _tokenCount;
        notifyListeners();
      }
      await fetchHistory();
    } catch (_) {}
  }

  Future<void> branchFrom(String messageId) async {
    if (_isGenerating) {
      return;
    }
    _flushSmoothStream();
    _isStreamDonePending = false;
    _streamTokenCount = 0;
    _pendingContent = '';
    _pendingReasoning = '';
    _isSearchVisible = false;
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      return;
    }

    try {
      final res = await _client.request('session/branch', {'index': index});
      if (res is Map) {
        final parsed = _parseMessagesFromRaw(res['messages'] as List?);
        _sessionTitle = res['title'] as String? ?? 'Branched Chat';
        final fn = res['filename']?.toString() ??
            res['id']?.toString() ??
            res['sessionFilename']?.toString() ??
            res['sessionId']?.toString();
        if (fn != null && fn.isNotEmpty) {
          _currentSessionFilename = fn;
        }
        if (res.containsKey('tokenCount')) {
          _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? 0;
        }
        if (res.containsKey('contextFiles')) {
          _contextFiles =
              (res['contextFiles'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
        if (res.containsKey('contextDocuments')) {
          _contextDocuments =
              (res['contextDocuments'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
        _messages.clear();
        _messages.addAll(parsed);
        notifyListeners();
        await fetchHistory();
      }
    } catch (e) {
      _errorMessage = 'Failed to branch session: $e';
      notifyListeners();
    }
  }

  List<ChatMessage> _parseMessagesFromRaw(List? rawMsgs) {
    if (rawMsgs == null) return [];
    final result = <ChatMessage>[];
    for (final m in rawMsgs) {
      if (m is! Map) continue;
      final typeInt = m['Type'] as int? ?? m['type'] as int? ?? 0;
      final content = m['Content'] as String? ?? m['content'] as String? ?? '';
      if (typeInt == 8 || typeInt == 9 || typeInt == 5 || typeInt == 6) {
        continue;
      }

      final isImage = typeInt == 7;
      final isAssistant = typeInt == 1;
      final isToolCall = typeInt == 20;
      final isToolResult = typeInt == 21;

      if (isToolCall) {
        final toolCalls = (m['ToolCalls'] ?? m['tool_calls']) as List?;
        if (toolCalls != null && toolCalls.isNotEmpty) {
          for (final tc in toolCalls) {
            if (tc is Map) {
              final id = tc['id'] as String? ?? tc['ID'] as String?;
              final name = tc['name'] as String? ?? tc['Name'] as String?;
              final args = tc['arguments'] as String? ?? tc['Arguments'] as String? ?? '';
              result.add(
                ChatMessage(
                  id: UniqueKey().toString(),
                  author: MessageAuthor.toolCall,
                  content: args,
                  toolName: name,
                  callId: id,
                ),
              );
            }
          }
          continue;
        }
      }

      Uint8List? imgData;
      final rawData = m['Data'] ?? m['data'];
      if (isImage && rawData is String && rawData.isNotEmpty) {
        try {
          imgData = base64Decode(rawData);
        } catch (_) {}
      }

      final callId = m['call_id'] as String? ?? m['CallID'] as String? ?? m['tool_call_id'] as String? ?? m['ToolCallID'] as String?;
      var toolName = m['tool_name'] as String? ?? m['ToolName'] as String?;

      if (isToolResult && (toolName == null || toolName.isEmpty)) {
        if (callId != null && callId.isNotEmpty) {
          for (var i = result.length - 1; i >= 0; i--) {
            if (result[i].callId == callId && result[i].toolName != null) {
              toolName = result[i].toolName;
              break;
            }
          }
        }
      }

      MessageAuthor author;
      if (isImage) {
        author = MessageAuthor.image;
      } else if (isAssistant) {
        author = MessageAuthor.assistant;
      } else if (isToolCall) {
        author = MessageAuthor.toolCall;
      } else if (isToolResult) {
        author = MessageAuthor.toolResult;
      } else if (typeInt == 2 ||
          typeInt == 10 ||
          typeInt == 12 ||
          typeInt == 14 ||
          typeInt == 17) {
        author = MessageAuthor.command;
      } else if (typeInt == 3 ||
          typeInt == 11 ||
          typeInt == 13 ||
          typeInt == 15 ||
          typeInt == 18 ||
          typeInt == 22) {
        author = MessageAuthor.commandResult;
      } else if (typeInt == 4 || typeInt == 16 || typeInt == 19) {
        author = MessageAuthor.commandError;
      } else {
        author = MessageAuthor.user;
      }

      result.add(
        ChatMessage(
          id: UniqueKey().toString(),
          author: author,
          content: content,
          imagePath: isImage ? content : null,
          imageData: imgData,
          toolName: toolName,
          callId: callId,
        ),
      );
    }
    return result;
  }

  Future<String?> applyItf({String? content}) async {
    try {
      final params = <String, dynamic>{};
      if (content != null && content.isNotEmpty) {
        params['content'] = content;
      }
      final res = await _client.request('session/itf/apply', params);
      if (res is Map && res.containsKey('summary')) {
        await fetchContext();
        return res['summary'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> undoItf() async {
    try {
      final res = await _client.request('session/itf/undo');
      if (res is Map && res.containsKey('summary')) {
        await fetchContext();
        return res['summary'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> uploadPdfAndAdd({
    required String filename,
    required List<int> bytes,
    String? pages,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(pdfUploadUrl));
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) {
        _errorMessage =
            'Upload failed (${response.statusCode}): ${response.body}';
        notifyListeners();
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['path'] == null) {
        _errorMessage = 'Invalid response from server during upload';
        notifyListeners();
        return null;
      }

      final remotePath = decoded['path'] as String;
      return await addPdf(remotePath, pages: pages);
    } catch (e) {
      _errorMessage = 'Failed to upload PDF: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> addPdf(String path, {String? pages}) async {
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final filename = file.uri.pathSegments.last;
      return uploadPdfAndAdd(filename: filename, bytes: bytes, pages: pages);
    }
    try {
      final params = <String, dynamic>{'path': path};
      if (pages != null && pages.trim().isNotEmpty) {
        params['pages'] = pages.trim();
      }
      final res = await _client.request('session/pdf/add', params);
      if (res is Map) {
        if (res.containsKey('tokenCount')) {
          _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? _tokenCount;
        }
        await fetchContext();
        final pagesAdded = res['pagesAdded'] as int? ?? 0;
        return 'Added PDF ($pagesAdded page${pagesAdded == 1 ? '' : 's'}) to context';
      }
    } catch (e) {
      _errorMessage = 'Failed to add PDF: $e';
      _lastFailedAction = () => addPdf(path, pages: pages);
      notifyListeners();
    }
    return null;
  }

  Future<void> addContextPaths(List<String> paths) async {
    try {
      await _client.request('session/context/add', {'paths': paths});
      await fetchContext();
    } catch (_) {}
  }

  Future<void> excludeContextPaths(List<String> paths) async {
    try {
      await _client.request('session/context/exclude', {'paths': paths});
      await fetchContext();
    } catch (_) {}
  }

  Future<void> fetchContext() async {
    try {
      final res = await _client.request('session/context/get');
      if (res is Map) {
        if (res.containsKey('contextFiles')) {
          _contextFiles =
              (res['contextFiles'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
        if (res.containsKey('contextDocuments')) {
          _contextDocuments =
              (res['contextDocuments'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
        if (res.containsKey('tokenCount')) {
          _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? _tokenCount;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setModel(String model) async {
    try {
      final res = await _client.request('session/model', {'model': model});
      if (res is Map && res.containsKey('model')) {
        _activeModel = res['model'] as String;
      } else {
        _activeModel = model;
      }
      notifyListeners();
      await _persistSettings();
    } catch (_) {}
  }

  Future<void> fetchModels() async {
    try {
      final res = await _client.request('models/list');
      if (res is Map && res.containsKey('models')) {
        final list = res['models'] as List?;
        if (list != null) {
          _availableModels = list.map((e) => e.toString()).toList();
        }
        if (res.containsKey('current') && _activeModel == 'default') {
          _activeModel = res['current'] as String;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchHistory() async {
    try {
      final res = await _client.request('history/list', {'mode': _mode});
      dynamic data = res;
      if (data is Map && data.containsKey('items')) {
        data = data['items'];
      } else if (data is Map && data.containsKey('sessions')) {
        data = data['sessions'];
      }
      if (data is List) {
        _historySessions = data
            .whereType<Map>()
            .map((e) => SessionInfo.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _resolveCurrentSessionFilename();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchHistory failed: $e');
    }
  }

  void _resolveCurrentSessionFilename() {
    if (_currentSessionFilename != null) {
      final exists = _historySessions.any(
        (s) => s.filename == _currentSessionFilename,
      );
      if (exists) return;
    }

    if (_messages.isEmpty) return;

    if (_sessionTitle.isNotEmpty && _sessionTitle != 'New Chat') {
      final matchedByTitle = _historySessions.where(
        (s) => s.title == _sessionTitle,
      ).firstOrNull;
      if (matchedByTitle != null) {
        _currentSessionFilename = matchedByTitle.filename;
        _previousSessionFilenames.add(matchedByTitle.filename);
        return;
      }
    }

    final newSession = _historySessions.where(
      (s) => !_previousSessionFilenames.contains(s.filename),
    ).firstOrNull;
    if (newSession != null) {
      _currentSessionFilename = newSession.filename;
      _previousSessionFilenames.add(newSession.filename);
      return;
    }

    _currentSessionFilename = _historySessions.firstOrNull?.filename;
  }

  Future<void> loadSession(String filename) async {
    if (_isLoadingSession && _loadingSessionFilename == filename) return;
    _flushSmoothStream();
    _isGenerating = false;
    _isStreamDonePending = false;
    _streamTokenCount = 0;
    _pendingContent = '';
    _pendingReasoning = '';
    _isSearchVisible = false;
    _isLoadingSession = true;
    _loadingSessionFilename = filename;
    notifyListeners();
    try {
      final res = await _client.request('history/load', {'filename': filename});
      if (res is Map) {
        final parsed = _parseMessagesFromRaw(res['messages'] as List?);
        if (res.containsKey('mode') && res['mode'] != null) {
          _mode = res['mode'] as String;
        }
        _previousSessionFilenames = _historySessions.map((s) => s.filename).toSet();
        _currentSessionFilename = filename;
        _sessionTitle = res['title'] as String? ?? 'Loaded Chat';
        if (res.containsKey('tokenCount')) {
          _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? 0;
        }
        if (res.containsKey('contextFiles')) {
          _contextFiles =
              (res['contextFiles'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
        if (res.containsKey('contextDocuments')) {
          _contextDocuments =
              (res['contextDocuments'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
        _messages.clear();
        _messages.addAll(parsed);
        await fetchHistory();
      }
    } catch (e) {
      _errorMessage = 'Failed to load session: $e';
    } finally {
      _isLoadingSession = false;
      _loadingSessionFilename = null;
      notifyListeners();
    }
  }

  void _onServerNotification(String method, dynamic params) {
    if (method == 'session/chunk' && params is Map) {
      final content = params['content'] as String? ?? '';
      final reasoning = params['reasoningContent'] as String? ?? '';
      final done = params['done'] as bool? ?? false;
      final tokenCount = (params['tokenCount'] as num?)?.toInt();
      final error = params['error'] as String?;
      final toolCall = params['toolCall'] as Map?;
      final toolResult = params['toolResult'] as Map?;

      if (toolCall != null ||
          toolResult != null ||
          (error != null && error.isNotEmpty)) {
        _flushSmoothStream();
      }

      if (toolCall != null) {
        final callId = toolCall['call_id']?.toString();
        final name = toolCall['name']?.toString() ?? 'tool';
        final args = toolCall['arguments']?.toString() ?? '';

        if (_messages.isNotEmpty &&
            _messages.last.author == MessageAuthor.assistant &&
            _messages.last.content.isEmpty &&
            _messages.last.reasoning.isEmpty) {
          _messages.removeLast();
        }

        _messages.add(
          ChatMessage(
            id: UniqueKey().toString(),
            author: MessageAuthor.toolCall,
            content: args,
            toolName: name,
            callId: callId,
            isGenerating: true,
          ),
        );
      }

      if (toolResult != null) {
        final callId = toolResult['call_id']?.toString();
        final name = toolResult['name']?.toString() ?? 'tool';
        final output = toolResult['output']?.toString() ?? '';

        for (var i = _messages.length - 1; i >= 0; i--) {
          if (_messages[i].author == MessageAuthor.toolCall) {
            _messages[i].isGenerating = false;
            break;
          }
        }

        _messages.add(
          ChatMessage(
            id: UniqueKey().toString(),
            author: MessageAuthor.toolResult,
            content: output,
            toolName: name,
            callId: callId,
          ),
        );
      }

      if (content.isNotEmpty) {
        _pendingContent += content;
      }
      if (reasoning.isNotEmpty) {
        _pendingReasoning += reasoning;
      }

      if (done) {
        _isStreamDonePending = true;
        if (tokenCount != null && tokenCount > 0) {
          _streamTokenCount = tokenCount;
        }
      }

      if (error != null && error.isNotEmpty) {
        _flushSmoothStream();
        _isGenerating = false;
        _isStreamDonePending = false;
        for (final m in _messages) {
          m.isGenerating = false;
        }
        if (_messages.isNotEmpty &&
            _messages.last.author == MessageAuthor.assistant) {
          _messages.last.content += '\n\n[Error: $error]';
        } else {
          _messages.add(
            ChatMessage(
              id: UniqueKey().toString(),
              author: MessageAuthor.assistant,
              content: '[Error: $error]',
              isGenerating: false,
            ),
          );
        }
        fetchContext();
        fetchHistory();
        notifyListeners();
        return;
      }

      _ensureSmoothStreamTimer();
      return;
    }

    if (method == 'session/event' && params is Map) {
      final fn = params['filename']?.toString() ??
          params['id']?.toString() ??
          params['sessionFilename']?.toString() ??
          params['session_filename']?.toString() ??
          params['sessionId']?.toString();
      if (fn != null && fn.isNotEmpty) {
        _currentSessionFilename = fn;
      }
      if (params['type'] == 'title' && params.containsKey('title')) {
        _sessionTitle = params['title'] as String;
      } else if (params.containsKey('payload') && params['payload'] != null) {
        final payload = params['payload'].toString();
        if (_messages.isNotEmpty &&
            _messages.last.author == MessageAuthor.assistant &&
            _messages.last.content.isEmpty) {
          _messages.last.content = payload;
          _messages.last.author = MessageAuthor.commandResult;
        }
        fetchContext();
      }
      fetchHistory();
      notifyListeners();
      return;
    }
  }

  void _ensureSmoothStreamTimer() {
    if (_smoothStreamTimer != null && _smoothStreamTimer!.isActive) {
      return;
    }
    _smoothStreamTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      _onSmoothStreamTick,
    );
    _onSmoothStreamTick(_smoothStreamTimer!);
  }

  void _onSmoothStreamTick(Timer timer) {
    if (_pendingReasoning.isNotEmpty || _pendingContent.isNotEmpty) {
      if (_messages.isEmpty ||
          _messages.last.author != MessageAuthor.assistant) {
        _messages.add(
          ChatMessage(
            id: UniqueKey().toString(),
            author: MessageAuthor.assistant,
            content: '',
            reasoning: '',
            isGenerating: true,
          ),
        );
        notifyListeners();
      }
    }

    if (_messages.isNotEmpty &&
        _messages.last.author == MessageAuthor.assistant) {
      final last = _messages.last;

      if (_pendingReasoning.isNotEmpty) {
        final step = _calculateStep(_pendingReasoning.length);
        final safeLen = _safeSubstringLength(_pendingReasoning, step);
        final chunk = _pendingReasoning.substring(0, safeLen);
        _pendingReasoning = _pendingReasoning.substring(safeLen);
        last.appendReasoning(chunk);
      } else if (_pendingContent.isNotEmpty) {
        final step = _calculateStep(_pendingContent.length);
        final safeLen = _safeSubstringLength(_pendingContent, step);
        final chunk = _pendingContent.substring(0, safeLen);
        _pendingContent = _pendingContent.substring(safeLen);
        last.appendContent(chunk);
      }
    }

    final hasPending =
        _pendingReasoning.isNotEmpty || _pendingContent.isNotEmpty;

    if (!hasPending && _isStreamDonePending) {
      _smoothStreamTimer?.cancel();
      _smoothStreamTimer = null;
      _isStreamDonePending = false;
      _isGenerating = false;
      if (_streamTokenCount > 0) {
        _tokenCount = _streamTokenCount;
        _streamTokenCount = 0;
      }
      for (final m in _messages) {
        m.isGenerating = false;
      }
      if (_messages.isNotEmpty &&
          _messages.last.author == MessageAuthor.assistant &&
          _messages.last.content.isEmpty &&
          _messages.last.reasoning.isEmpty) {
        _messages.removeLast();
      }
      fetchContext();
      fetchHistory();
      notifyListeners();
      return;
    }

    if (!hasPending && !_isStreamDonePending) {
      _smoothStreamTimer?.cancel();
      _smoothStreamTimer = null;
      notifyListeners();
    }
  }

  int _calculateStep(int backlogLength) {
    if (backlogLength <= 0) return 0;
    if (backlogLength <= 8) return 1;
    if (backlogLength <= 20) return 2;
    if (backlogLength <= 50) return 3;
    if (backlogLength <= 120) return 5;
    return math.min(backlogLength, (backlogLength / 20).ceil());
  }

  int _safeSubstringLength(String text, int desiredLength) {
    var len = desiredLength.clamp(0, text.length);
    if (len > 0 && len < text.length) {
      final codeUnit = text.codeUnitAt(len - 1);
      if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        len++;
      }
    }
    return len;
  }

  void _flushSmoothStream() {
    _smoothStreamTimer?.cancel();
    _smoothStreamTimer = null;
  }

  @override
  void dispose() {
    _flushSmoothStream();
    themeModeNotifier.dispose();
    _reconnectTimer?.cancel();
    _client.disconnect();
    super.dispose();
  }
}
