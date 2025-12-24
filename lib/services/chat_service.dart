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
///
/// Features:
/// - Real-time messaging with Socket.IO
/// - Message persistence via REST API
/// - Typing indicators
/// - Online/offline status
/// - Chat room management
/// - Message editing and deletion
class ChatService extends ChangeNotifier {
  final AuthService _authService;
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

    // Online/offline events
    _socket!.on('user_online', (data) {
      if (kDebugMode) print('ChatService: User online: $data');
      // Could update user status here
      notifyListeners();
    });

    _socket!.on('user_offline', (data) {
      if (kDebugMode) print('ChatService: User offline: $data');
      // Could update user status here
      notifyListeners();
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
      final url = AppConfig.getEndpoint('/API/Chat/Rooms');

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

        // Sort by last message time
        _rooms.sort((a, b) {
          if (a.lastMessageAt == null) return 1;
          if (b.lastMessageAt == null) return -1;
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        });

        if (kDebugMode) print('ChatService: Loaded ${_rooms.length} rooms');
      } else {
        _error = 'Failed to load chat rooms: ${response.statusCode}';
        if (kDebugMode) print('ChatService: $_error - ${response.body}');
      }
    } catch (e) {
      _error = 'Error loading chat rooms: $e';
      if (kDebugMode) print('ChatService: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get single chat room details
  Future<ChatRoom?> getChatRoom(String roomId) async {
    if (!_authService.isLoggedIn) {
      _error = 'Not authenticated';
      notifyListeners();
      return null;
    }

    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('/API/Chat/Rooms/$roomId');

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
      } else {
        _error = 'Failed to load room: ${response.statusCode}';
        if (kDebugMode) print('ChatService: $_error - ${response.body}');
      }
    } catch (e) {
      _error = 'Error loading room: $e';
      if (kDebugMode) print('ChatService: $_error');
    }
    return null;
  }

  /// Create new chat room
  Future<String?> createChatRoom(
    List<String> participants, {
    String? roomName,
    String type = 'direct',
  }) async {
    if (!_authService.isLoggedIn) {
      _error = 'Not authenticated';
      notifyListeners();
      return null;
    }

    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('/API/Chat/Rooms');

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

        if (kDebugMode) print('ChatService: Room created: $roomId');

        // Refresh rooms list
        await getChatRooms();

        return roomId;
      } else {
        _error = 'Failed to create room: ${response.statusCode}';
        if (kDebugMode) print('ChatService: $_error - ${response.body}');
      }
    } catch (e) {
      _error = 'Error creating room: $e';
      if (kDebugMode) print('ChatService: $_error');
    }
    return null;
  }

  /// Join a chat room (Socket.IO)
  Future<void> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      if (kDebugMode) print('ChatService: Not connected, cannot join room');
      return;
    }

    if (kDebugMode) print('ChatService: Joining room $roomId');
    _socket!.emit('join_room', {'roomId': roomId});
  }

  /// Leave a chat room (Socket.IO)
  Future<void> leaveRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      if (kDebugMode) print('ChatService: Not connected, cannot leave room');
      return;
    }

    if (kDebugMode) print('ChatService: Leaving room $roomId');
    _socket!.emit('leave_room', {'roomId': roomId});
  }

  // ============================================================================
  // MESSAGE OPERATIONS
  // ============================================================================

  /// Get messages for a room
  Future<List<ChatMessage>> getMessages(String roomId, {int limit = 50}) async {
    if (!_authService.isLoggedIn) {
      _error = 'Not authenticated';
      notifyListeners();
      return [];
    }

    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('/API/Chat/Rooms/$roomId/Messages?limit=$limit');

      if (kDebugMode) print('ChatService: Fetching messages from $url');

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

        // Cache messages
        _messagesCache[roomId] = messages;
        notifyListeners();

        if (kDebugMode) print('ChatService: Loaded ${messages.length} messages');
        return messages;
      } else {
        _error = 'Failed to load messages: ${response.statusCode}';
        if (kDebugMode) print('ChatService: $_error - ${response.body}');
      }
    } catch (e) {
      _error = 'Error loading messages: $e';
      if (kDebugMode) print('ChatService: $_error');
    }
    return [];
  }

  /// Send a message (real-time via Socket.IO + save via API)
  Future<void> sendMessage(String roomId, String message, {String? imageUrl}) async {
    if (!_authService.isLoggedIn) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final messageData = {
        'roomId': roomId,
        'userId': user.uid,
        'displayName': user.displayName ?? user.email ?? 'Anonymous',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      // Send via Socket.IO for real-time delivery
      if (_isConnected && _socket != null) {
        if (kDebugMode) print('ChatService: Sending message via Socket.IO');
        _socket!.emit('send_message', messageData);
      }

      // Also save to database via API
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('/API/Chat/Rooms/$roomId/Messages');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': message,
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        if (kDebugMode) print('ChatService: Failed to save message: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Error sending message: $e';
      if (kDebugMode) print('ChatService: $_error');
      notifyListeners();
    }
  }

  /// Edit a message
  Future<void> editMessage(String roomId, String messageId, String newMessage) async {
    if (!_authService.isLoggedIn) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('/API/Chat/Rooms/$roomId/Messages/$messageId');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
        body: json.encode({'message': newMessage}),
      );

      if (response.statusCode == 200) {
        // Update cached message
        if (_messagesCache.containsKey(roomId)) {
          final index = _messagesCache[roomId]!.indexWhere((m) => m.messageId == messageId);
          if (index != -1) {
            _messagesCache[roomId]![index] = _messagesCache[roomId]![index].copyWith(
              message: newMessage,
              edited: true,
            );
            notifyListeners();
          }
        }

        if (kDebugMode) print('ChatService: Message edited successfully');
      } else {
        _error = 'Failed to edit message: ${response.statusCode}';
        if (kDebugMode) print('ChatService: $_error - ${response.body}');
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error editing message: $e';
      if (kDebugMode) print('ChatService: $_error');
      notifyListeners();
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String roomId, String messageId) async {
    if (!_authService.isLoggedIn) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    try {
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('/API/Chat/Rooms/$roomId/Messages/$messageId');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Remove from cache or mark as deleted
        if (_messagesCache.containsKey(roomId)) {
          _messagesCache[roomId]!.removeWhere((m) => m.messageId == messageId);
          notifyListeners();
        }

        if (kDebugMode) print('ChatService: Message deleted successfully');
      } else {
        _error = 'Failed to delete message: ${response.statusCode}';
        if (kDebugMode) print('ChatService: $_error - ${response.body}');
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error deleting message: $e';
      if (kDebugMode) print('ChatService: $_error');
      notifyListeners();
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(String roomId, bool isTyping) {
    if (!_isConnected || _socket == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    _socket!.emit('typing', {
      'roomId': roomId,
      'userId': user.uid,
      'displayName': user.displayName ?? user.email ?? 'Anonymous',
      'isTyping': isTyping,
    });
  }
}
