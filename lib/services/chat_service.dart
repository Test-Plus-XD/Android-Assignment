import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

// Chat service for real-time messaging using Socket.IO and REST API persistence
class ChatService with ChangeNotifier {
  // Reference to AuthService for user authentication
  final AuthService _authService;
  // Socket.IO client instance
  io.Socket? _socket;
  // Current chat room ID
  String? _currentRoomId;
  // Message list for current room
  List<ChatMessage> _messages = [];
  // Users currently typing in the room
  final Map<String, String> _typingUsers = {};
  // Connection state tracking
  bool _isConnected = false;
  bool _isConnecting = false;
  // Error message for UI display
  String? _errorMessage;

  // Getters for UI consumption
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Map<String, String> get typingUsers => Map.unmodifiable(_typingUsers);
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentRoomId => _currentRoomId;
  String? get errorMessage => _errorMessage;

  ChatService(this._authService);

  // Gets HTTP headers with authentication for REST API calls
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.idToken;
    return {
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Initialises Socket.IO connection to Railway server
  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create Socket.IO client with configuration
      _socket = io.io(
        AppConfig.socketServerUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );

      // Set up event listeners
      _setupSocketListeners();

      // Wait for connection with timeout
      await Future.any([
        _waitForConnection(),
        Future.delayed(const Duration(seconds: 10), () {
          throw TimeoutException('Connection timeout');
        }),
      ]);

      // Register user with socket server
      if (_authService.isLoggedIn && _authService.uid != null) {
        _registerUser();
      }

      _isConnecting = false;
      _isConnected = true;
      notifyListeners();

      if (kDebugMode) print('ChatService: Connected to Socket.IO server');
    } catch (error) {
      _isConnecting = false;
      _isConnected = false;
      _errorMessage = 'Failed to connect: $error';
      notifyListeners();
      if (kDebugMode) print('ChatService: Connection error - $error');
    }
  }

  // Waits for socket connection to be established
  Future<void> _waitForConnection() {
    final completer = Completer<void>();
    _socket?.onConnect((_) {
      if (!completer.isCompleted) completer.complete();
    });
    _socket?.onConnectError((error) {
      if (!completer.isCompleted) completer.completeError(error);
    });
    return completer.future;
  }

  // Sets up all Socket.IO event listeners
  void _setupSocketListeners() {
    // Connection events
    _socket?.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      _errorMessage = null;
      notifyListeners();
      if (kDebugMode) print('ChatService: Socket connected');
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      if (kDebugMode) print('ChatService: Socket disconnected');
    });

    _socket?.onConnectError((error) {
      _isConnected = false;
      _isConnecting = false;
      _errorMessage = 'Connection error: $error';
      notifyListeners();
      if (kDebugMode) print('ChatService: Connection error - $error');
    });

    // Registration confirmation
    _socket?.on('registered', (data) {
      if (kDebugMode) print('ChatService: User registered - $data');
    });

    // Room join confirmation
    _socket?.on('joined-room', (data) {
      if (kDebugMode) print('ChatService: Joined room - $data');
    });

    // New message received
    _socket?.on('new-message', (data) {
      if (kDebugMode) print('ChatService: New message received - $data');
      _handleNewMessage(data);
    });

    // User typing indicator
    _socket?.on('user-typing', (data) {
      _handleTypingIndicator(data);
    });

    // User online/offline status
    _socket?.on('user-online', (data) {
      if (kDebugMode) print('ChatService: User online - $data');
    });

    _socket?.on('user-offline', (data) {
      if (kDebugMode) print('ChatService: User offline - $data');
    });
  }

  // Registers current user with Socket.IO server
  void _registerUser() {
    if (_socket == null || !_authService.isLoggedIn) return;
    _socket?.emit('register', {
      'userId': _authService.uid,
      'displayName': _authService.currentUser?.displayName ?? 'User',
    });
  }

  // Joins a specific chat room and loads message history
  Future<void> joinRoom(String roomId) async {
    if (_currentRoomId == roomId) return;

    // Leave previous room if any
    if (_currentRoomId != null) {
      leaveRoom();
    }

    _currentRoomId = roomId;
    _messages = [];
    _typingUsers.clear();
    notifyListeners();

    // Emit join room event
    _socket?.emit('join-room', {
      'roomId': roomId,
      'userId': _authService.uid,
    });

    // Load message history from REST API
    await loadMessageHistory(roomId);

    if (kDebugMode) print('ChatService: Joined room $roomId');
  }

  // Leaves the current chat room
  void leaveRoom() {
    if (_currentRoomId == null) return;

    _socket?.emit('leave-room', {
      'roomId': _currentRoomId,
      'userId': _authService.uid,
    });

    _currentRoomId = null;
    _messages = [];
    _typingUsers.clear();
    notifyListeners();

    if (kDebugMode) print('ChatService: Left room');
  }

  // Sends a text message to the current room
  Future<void> sendMessage(String content) async {
    if (_currentRoomId == null || content.trim().isEmpty) return;

    final message = ChatMessage(
      roomId: _currentRoomId!,
      senderId: _authService.uid ?? '',
      senderName: _authService.currentUser?.displayName ?? 'User',
      content: content.trim(),
      timestamp: DateTime.now(),
      senderPhotoUrl: _authService.currentUser?.photoURL,
    );

    // Emit message via Socket.IO for real-time delivery
    _socket?.emit('send-message', {
      'roomId': _currentRoomId,
      'userId': _authService.uid,
      'displayName': message.senderName,
      'message': message.content,
    });

    // Add message to local list optimistically
    _messages.add(message);
    notifyListeners();

    // Persist message to REST API
    await _persistMessage(message);

    // Stop typing indicator
    setTyping(false);
  }

  // Sends an image message to the current room
  Future<void> sendImageMessage(String imageUrl) async {
    if (_currentRoomId == null || imageUrl.isEmpty) return;

    final message = ChatMessage(
      roomId: _currentRoomId!,
      senderId: _authService.uid ?? '',
      senderName: _authService.currentUser?.displayName ?? 'User',
      content: imageUrl,
      timestamp: DateTime.now(),
      isImage: true,
      senderPhotoUrl: _authService.currentUser?.photoURL,
    );

    // Emit message via Socket.IO
    _socket?.emit('send-message', {
      'roomId': _currentRoomId,
      'userId': _authService.uid,
      'displayName': message.senderName,
      'message': imageUrl,
    });

    // Add to local list
    _messages.add(message);
    notifyListeners();

    // Persist to API
    await _persistMessage(message);
  }

  // Sets the typing indicator for current user
  void setTyping(bool isTyping) {
    if (_currentRoomId == null) return;

    _socket?.emit('typing', {
      'roomId': _currentRoomId,
      'userId': _authService.uid,
      'displayName': _authService.currentUser?.displayName ?? 'User',
      'isTyping': isTyping,
    });
  }

  // Handles incoming message from Socket.IO
  void _handleNewMessage(dynamic data) {
    if (data == null) return;

    try {
      final messageData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      final message = ChatMessage.fromJson(messageData);

      // Only add if message is for current room and not from self
      if (message.roomId == _currentRoomId && message.senderId != _authService.uid) {
        _messages.add(message);
        notifyListeners();
      }
    } catch (error) {
      if (kDebugMode) print('ChatService: Error parsing message - $error');
    }
  }

  // Handles typing indicator from Socket.IO
  void _handleTypingIndicator(dynamic data) {
    if (data == null) return;

    try {
      final typingData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      final userId = typingData['userId'] as String?;
      final displayName = typingData['displayName'] as String?;
      final isTyping = typingData['isTyping'] as bool? ?? false;

      if (userId != null && userId != _authService.uid) {
        if (isTyping && displayName != null) {
          _typingUsers[userId] = displayName;
        } else {
          _typingUsers.remove(userId);
        }
        notifyListeners();
      }
    } catch (error) {
      if (kDebugMode) print('ChatService: Error parsing typing indicator - $error');
    }
  }

  // Loads message history from REST API
  Future<void> loadMessageHistory(String roomId, {int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConfig.getChatRoomEndpoint(roomId)}?limit=$limit');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messageList = data is List ? data : (data['messages'] as List? ?? []);
        _messages = messageList.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
        // Sort by timestamp ascending
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        notifyListeners();
        if (kDebugMode) print('ChatService: Loaded ${_messages.length} messages');
      } else {
        if (kDebugMode) print('ChatService: Failed to load messages - ${response.statusCode}');
      }
    } catch (error) {
      if (kDebugMode) print('ChatService: Error loading messages - $error');
    }
  }

  // Persists a message to the REST API for offline access
  Future<void> _persistMessage(ChatMessage message) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(AppConfig.getChatRoomEndpoint(message.roomId));
      await http.post(
        url,
        headers: headers,
        body: jsonEncode(message.toJson()),
      );
    } catch (error) {
      if (kDebugMode) print('ChatService: Error persisting message - $error');
    }
  }

  // Disconnects from Socket.IO server
  void disconnect() {
    leaveRoom();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
    if (kDebugMode) print('ChatService: Disconnected');
  }

  // Clears any error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
