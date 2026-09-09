import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/services/settings_service.dart';
import '../core/rpc/coder_rpc_client.dart';
import '../models/chat_message.dart';
import '../models/session_info.dart';

enum ConnectionStateStatus { disconnected, connecting, connected, error }

class CoderState extends ChangeNotifier {
  CoderState() {
    _client.onNotification = _onServerNotification;
    _loadSavedSettingsAndConnect();
  }

  final CoderRpcClient _client = CoderRpcClient();
  final SettingsService _settingsService = SettingsService.create();

  String _serverHost = '127.0.0.1';
  int _serverPort = 9005;
  bool _useTls = kIsWeb && Uri.base.scheme == 'https';
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isSidebarVisible = true;
  String _activeModel = 'default';
  String _sessionTitle = 'New Chat';
  List<String> _availableModels = [];
  bool _isSearchVisible = false;
  List<SessionInfo> _historySessions = [];
  final List<ChatMessage> _messages = [];

  ConnectionStateStatus _connectionStatus = ConnectionStateStatus.disconnected;
  String? _errorMessage;
  bool _isGenerating = false;
  int _tokenCount = 0;

  String get serverHost => _serverHost;
  int get serverPort => _serverPort;
  bool get useTls => _useTls;
  ThemeMode get themeMode => _themeMode;
  bool get isSearchVisible => _isSearchVisible;
  bool get isSidebarVisible => _isSidebarVisible;
  String get activeModel => _activeModel;
  String get sessionTitle => _sessionTitle;
  List<String> get availableModels => _availableModels;
  List<SessionInfo> get historySessions => _historySessions;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ConnectionStateStatus get connectionStatus => _connectionStatus;
  String? get errorMessage => _errorMessage;
  bool get isGenerating => _isGenerating;
  int get tokenCount => _tokenCount;

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
      _themeMode = modeStr == 'light' ? ThemeMode.light : ThemeMode.dark;
    }
    final isSidebar = settings['isSidebarVisible'] as bool?;
    if (isSidebar != null) {
      _isSidebarVisible = isSidebar;
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
      'themeMode': _themeMode == ThemeMode.light ? 'light' : 'dark',
      'isSidebarVisible': _isSidebarVisible,
      'activeModel': _activeModel,
    });
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
    _persistSettings();
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

  Future<void> initConnection() async {
    _connectionStatus = ConnectionStateStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client.connect(websocketUrl);
      _connectionStatus = ConnectionStateStatus.connected;
      notifyListeners();
      await _initializeRemoteSession();
      await fetchModels();
      await fetchHistory();
    } catch (e) {
      _connectionStatus = ConnectionStateStatus.error;
      _errorMessage = 'Failed to connect to Coder server ($websocketUrl): $e';
      notifyListeners();
    }
  }

  Future<void> _initializeRemoteSession() async {
    try {
      final params = <String, dynamic>{'mode': 'chat'};
      if (_activeModel != 'default') {
        params['model'] = _activeModel;
      }
      final res = await _client.request('session/init', params);
      if (res is Map) {
        if (res.containsKey('model')) {
          _activeModel = res['model'] as String;
        }
        if (res.containsKey('tokenCount')) {
          _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? 0;
        }
      }
      _sessionTitle = 'New Chat';
      _messages.clear();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> newChat() async {
    _isGenerating = false;
    _tokenCount = 0;
    _messages.clear();
    _sessionTitle = 'New Chat';
    notifyListeners();
    await _initializeRemoteSession();
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
      await _client.request('session/prompt', params);
    } catch (e) {
      aiMsg.content = 'Error sending prompt: $e';
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
    _isGenerating = false;
    if (_messages.isNotEmpty &&
        _messages.last.author == MessageAuthor.assistant) {
      _messages.last.isGenerating = false;
    }
    notifyListeners();
  }

  Future<void> renameSession(String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _sessionTitle = trimmed;
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
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      return;
    }

    final targetMsg = _messages[index];
    int promptMsgIndex = -1;
    if (targetMsg.author == MessageAuthor.assistant) {
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
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      return;
    }

    try {
      final res = await _client.request('session/branch', {'index': index});
      if (res is Map) {
        _sessionTitle = res['title'] as String? ?? 'Branched Chat';
        if (res.containsKey('tokenCount')) {
          _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? 0;
        }
        _messages.clear();
        _messages.addAll(_parseMessagesFromRaw(res['messages'] as List?));
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
      final typeInt = m['Type'] as int? ?? 0;
      final content = m['Content'] as String? ?? '';
      final isImage = typeInt == 7;
      final isAssistant = typeInt == 1;

      Uint8List? imgData;
      if (isImage && m['Data'] is String && (m['Data'] as String).isNotEmpty) {
        try {
          imgData = base64Decode(m['Data'] as String);
        } catch (_) {}
      }

      result.add(
        ChatMessage(
          id: UniqueKey().toString(),
          author: isImage
              ? MessageAuthor.image
              : (isAssistant ? MessageAuthor.assistant : MessageAuthor.user),
          content: content,
          imagePath: isImage ? content : null,
          imageData: imgData,
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
        return res['summary'] as String?;
      }
    } catch (_) {}
    return null;
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
      final res = await _client.request('history/list');
      if (res is List) {
        _historySessions = res
            .whereType<Map<String, dynamic>>()
            .map(SessionInfo.fromJson)
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadSession(String filename) async {
    try {
      final res = await _client.request('history/load', {'filename': filename});
      if (res is Map) {
        _sessionTitle = res['title'] as String? ?? 'Loaded Chat';
        if (res.containsKey('tokenCount')) {
          _tokenCount = (res['tokenCount'] as num?)?.toInt() ?? 0;
        }
        _messages.clear();
        _messages.addAll(_parseMessagesFromRaw(res['messages'] as List?));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load session: $e';
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

      if (_messages.isNotEmpty &&
          _messages.last.author == MessageAuthor.assistant) {
        final last = _messages.last;
        if (content.isNotEmpty) {
          last.content += content;
        }
        if (reasoning.isNotEmpty) {
          last.reasoning += reasoning;
        }
        if (error != null && error.isNotEmpty) {
          last.content += '\n\n[Error: $error]';
          last.isGenerating = false;
        }
      }

      if (done) {
        _isGenerating = false;
        if (tokenCount != null && tokenCount > 0) {
          _tokenCount = tokenCount;
        }
        if (_messages.isNotEmpty &&
            _messages.last.author == MessageAuthor.assistant) {
          _messages.last.isGenerating = false;
        }
        fetchHistory();
      }
      notifyListeners();
      return;
    }

    if (method == 'session/event' && params is Map) {
      if (params['type'] == 'title' && params.containsKey('title')) {
        _sessionTitle = params['title'] as String;
        fetchHistory();
      }
      notifyListeners();
      return;
    }
  }

  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}
