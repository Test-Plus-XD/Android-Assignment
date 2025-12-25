import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Chat Service
///
/// Manages real-time chat functionality using Socket.IO for real-time events
/// and REST API for message persistence.
class ChatService extends ChangeNotifier {
  AuthService _authService;
  IO.Socket? _socket;

  // State
  List<ChatRoom> _rooms = [];
  Map<String, List<ChatMessage>> _messagesCache = {};
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;

  // Streams for real-time events
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<TypingIndicator>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  ChatService(this._authService);

  // Getters
  List<ChatRoom> get rooms => _rooms;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<TypingIndicator> get typingStream => _typingController.stream;
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  /// Update the AuthService dependency without recreating the service instance
  void updateAuth(AuthService authService) {
    if (_authService != authService) {
      final wasLoggedIn = _authService.isLoggedIn;
      _authService = authService;
      
      if (_authService.isLoggedIn && !wasLoggedIn) {
        // Just logged in, connect to socket
        if (_authService.uid != null) {
          connect(_authService.uid!);
          getChatRooms();
        }
      } else if (!_authService.isLoggedIn && wasLoggedIn) {
        // Logged out, disconnect and clear
        disconnect();
        _rooms.clear();
        _messagesCache.clear();
        notifyListeners();
      }
    }
  }

  /// Get cached messages for a room
  List<ChatMessage> getCachedMessages(String roomId) {
    return _messagesCache[roomId] ?? [];
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
    super.dispose();
  }

  // ============================================================================
  // CONNECTION MANAGEMENT
  // ============================================================================

  /// Connect to Socket.IO server
  Future<void> connect(String userId) async {
    if (_isConnected) return;

    try {
      if (kDebugMode) print('ChatService: Connecting to ${AppConfig.socketIOUrl}...');

      _socket = IO.io(
        AppConfig.socketIOUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'userId': userId})
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();

      if (kDebugMode) print('ChatService: Connection initiated');
    } catch (e) {
      if (kDebugMode) print('ChatService: Connection error: $e');
      _error = 'Failed to connect to chat server';
      notifyListeners();
    }
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      if (kDebugMode) print('ChatService: Disconnecting...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _connectionController.add(false);
      notifyListeners();
    }
  }

  /// Setup Socket.IO event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      if (kDebugMode) print('ChatService: Connected to server');
      _isConnected = true;
      _error = null;
      _connectionController.add(true);
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) print('ChatService: Disconnected from server');
      _isConnected = false;
      _connectionController.add(false);
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      if (kDebugMode) print('ChatService: Connection error: $error');
      _error = 'Connection error';
      _isConnected = false;
      _connectionController.add(false);
      notifyListeners();
    });

    // Message events
    _socket!.on('message_received', (data) {
      if (kDebugMode) print('ChatService: Message received: $data');
      try {
        final message = ChatMessage.fromJson(data as Map<String, dynamic>);

        // Add to cache
        if (!_messagesCache.containsKey(message.roomId)) {
          _messagesCache[message.roomId] = [];
        }
        _messagesCache[message.roomId]!.add(message);

        // Update room's last message
        final roomIndex = _rooms.indexWhere((r) => r.roomId == message.roomId);
        if (roomIndex != -1) {
          final updatedRoom = ChatRoom(
            roomId: _rooms[roomIndex].roomId,
            participants: _rooms[roomIndex].participants,
            roomName: _rooms[roomIndex].roomName,
            type: _rooms[roomIndex].type,
            createdBy: _rooms[roomIndex].createdBy,
            createdAt: _rooms[roomIndex].createdAt,
            lastMessage: message.message,
            lastMessageAt: message.timestamp,
            messageCount: _rooms[roomIndex].messageCount + 1,
            participantsData: _rooms[roomIndex].participantsData,
          );
          _rooms[roomIndex] = updatedRoom;
        }

        _messageController.add(message);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) print('ChatService: Error parsing message: $e');
      }
    });

    // Typing events
    _socket!.on('typing', (data) {
      if (kDebugMode) print('ChatService: Typing event: $data');
      try {
        final indicator = TypingIndicator.fromJson(data as Map<String, dynamic>);
        _typingController.add(indicator);
      } catch (e) {
        if (kDebugMode) print('ChatService: Error parsing typing indicator: $e');
      }
    });
  }

  // ============================================================================
  // ROOM OPERATIONS
  // ============================================================================

  /// Get all chat rooms for current user
  Future<void> getChatRooms() async {
    if (!_authService.isLoggedIn) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('Chat/Rooms');

      if (kDebugMode) print('ChatService: Fetching rooms from $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _rooms = data.map((json) => ChatRoom.fromJson(json)).toList();

        _rooms.sort((a, b) {
          if (a.lastMessageAt == null) return 1;
          if (b.lastMessageAt == null) return -1;
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        });

        if (kDebugMode) print('ChatService: Loaded ${_rooms.length} rooms');
      } else {
        _error = 'Failed to load chat rooms';
      }
    } catch (e) {
      _error = 'Error loading chat rooms: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get single chat room details
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('Chat/Rooms/$roomId');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return ChatRoom.fromJson(json.decode(response.body));
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error loading room: $e');
    }
    return null;
  }

  /// Create new chat room
  Future<String?> createChatRoom(
    List<String> participants, {
    String? roomName,
    String type = 'direct',
  }) async {
    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('Chat/Rooms');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'participants': participants,
          if (roomName != null) 'roomName': roomName,
          'type': type,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final roomId = data['roomId'] as String;
        await getChatRooms();
        return roomId;
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error creating room: $e');
    }
    return null;
  }

  /// Join a chat room (Socket.IO)
  Future<void> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('join_room', {'roomId': roomId});
  }

  /// Leave a chat room (Socket.IO)
  Future<void> leaveRoom(String roomId) async {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('leave_room', {'roomId': roomId});
  }

  // ============================================================================
  // MESSAGE OPERATIONS
  // ============================================================================

  /// Get messages for a room
  Future<List<ChatMessage>> getMessages(String roomId, {int limit = 50}) async {
    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('Chat/Rooms/$roomId/Messages?limit=$limit');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((json) => ChatMessage.fromJson(json)).toList();
        _messagesCache[roomId] = messages;
        notifyListeners();
        return messages;
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error loading messages: $e');
    }
    return [];
  }

  /// Send a message
  Future<bool> sendMessage(String roomId, String text, {String type = 'text', String? imageUrl}) async {
    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('Chat/Rooms/$roomId/Messages');

      final messageData = {
        'message': text,
        'type': type,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
        body: json.encode(messageData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = ChatMessage.fromJson(data);
        
        if (_socket != null && _isConnected) {
          _socket!.emit('send_message', data);
        }

        if (!_messagesCache.containsKey(roomId)) {
          _messagesCache[roomId] = [];
        }
        _messagesCache[roomId]!.add(message);
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error sending message: $e');
    }
    return false;
  }

  /// Edit a message
  Future<bool> editMessage(String roomId, String messageId, String newText) async {
    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('Chat/Rooms/$roomId/Messages/$messageId');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
        body: json.encode({'message': newText}),
      );

      if (response.statusCode == 200) {
        // Update local cache
        if (_messagesCache.containsKey(roomId)) {
          final index = _messagesCache[roomId]!.indexWhere((m) => m.messageId == messageId);
          if (index != -1) {
            _messagesCache[roomId]![index] = _messagesCache[roomId]![index].copyWith(
              message: newText,
              edited: true,
            );
            notifyListeners();
          }
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error editing message: $e');
    }
    return false;
  }

  /// Delete a message
  Future<bool> deleteMessage(String roomId, String messageId) async {
    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('Chat/Rooms/$roomId/Messages/$messageId');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200) {
        // Update local cache
        if (_messagesCache.containsKey(roomId)) {
          _messagesCache[roomId]!.removeWhere((m) => m.messageId == messageId);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error deleting message: $e');
    }
    return false;
  }

  /// Emit typing indicator
  void sendTypingIndicator(String roomId, bool isTyping) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
      'userId': _authService.uid,
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
