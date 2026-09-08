import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../core/rpc/coder_rpc_client.dart';
import '../models/chat_message.dart';
import '../models/session_info.dart';

enum ConnectionStateStatus { disconnected, connecting, connected, error }

class CoderState extends ChangeNotifier {
  CoderState() {
    _client.onNotification = _onServerNotification;
    initConnection();
  }

  final CoderRpcClient _client = CoderRpcClient();

  String _serverHost = '127.0.0.1';
  int _serverPort = 9005;
  bool _useTls = kIsWeb && Uri.base.scheme == 'https';
  String _activeModel = 'default';
  String _sessionTitle = 'New Chat';
  List<String> _availableModels = [];
  List<SessionInfo> _historySessions = [];
  final List<ChatMessage> _messages = [];

  ConnectionStateStatus _connectionStatus = ConnectionStateStatus.disconnected;
  String? _errorMessage;
  bool _isGenerating = false;
  int _tokenCount = 0;

  String get serverHost => _serverHost;
  int get serverPort => _serverPort;
  bool get useTls => _useTls;
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

  Future<void> updateServerAddress(String host, int port, {bool? useTls}) async {
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
      final res = await _client.request('session/init', {
        'mode': 'chat',
      });
      if (res is Map && res.containsKey('model')) {
        _activeModel = res['model'] as String;
      }
      _sessionTitle = 'New Chat';
      _messages.clear();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> newChat() async {
    _isGenerating = false;
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

    final effectivePrompt = prompt.isEmpty && hasImages ? 'What is in this image?' : prompt;
    final baseTimestamp = DateTime.now().millisecondsSinceEpoch;
    var offset = 0;

    if (hasImages) {
      for (final img in images) {
        _messages.add(ChatMessage(
          id: (baseTimestamp + offset++).toString(),
          author: MessageAuthor.image,
          content: 'Image',
          imageData: img,
        ));
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
    );
    _messages.add(aiMsg);

    _isGenerating = true;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'content': effectivePrompt,
      };
      if (hasImages) {
        params['images'] = images.map(base64Encode).toList();
      }
      await _client.request('session/prompt', params);
    } catch (e) {
      aiMsg.content = 'Error sending prompt: $e';
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
    notifyListeners();
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
        if (res.containsKey('current')) {
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
        _messages.clear();

        final rawMsgs = res['messages'] as List?;
        if (rawMsgs != null) {
          for (final m in rawMsgs) {
            if (m is! Map) continue;
            final typeInt = m['Type'] as int? ?? 0;
            final content = m['Content'] as String? ?? '';
            
            MessageAuthor author;
            String? imagePath;
            Uint8List? imageData;
            if (typeInt == 1) {
              author = MessageAuthor.assistant;
            } else if (typeInt == 7) {
              author = MessageAuthor.image;
              imagePath = content;
              final rawData = m['Data'];
              if (rawData is String && rawData.isNotEmpty) {
                try {
                  imageData = base64Decode(rawData);
                } catch (_) {}
              }
            } else {
              author = MessageAuthor.user;
            }

            _messages.add(ChatMessage(
              id: UniqueKey().toString(),
              author: author,
              content: content,
              imagePath: imagePath,
              imageData: imageData,
            ));
          }
        }
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
      final error = params['error'] as String?;

      if (_messages.isNotEmpty && _messages.last.author == MessageAuthor.assistant) {
        final last = _messages.last;
        if (content.isNotEmpty) {
          last.content += content;
        }
        if (reasoning.isNotEmpty) {
          last.reasoning += reasoning;
        }
        if (error != null && error.isNotEmpty) {
          last.content += '\n\n[Error: $error]';
        }
      }

      if (done) {
        _isGenerating = false;
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
