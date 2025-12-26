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
  ///
  /// Establishes a WebSocket connection to the Railway Socket server and prepares
  /// for user registration. The connection flow is:
  /// 1. Retrieve Firebase authentication token
  /// 2. Initialise Socket.IO client with WebSocket transport
  /// 3. Set up event listeners for real-time communication
  /// 4. Connect to server (registration happens in onConnect handler)
  Future<void> connect(String userId) async {
    if (_isConnected) return;

    try {
      if (kDebugMode) print('ChatService: Connecting to ${AppConfig.socketIOUrl}...');

      // Firebase authentication token is required for server-side user verification
      final authToken = await _authService.getIdToken();
      if (authToken == null || authToken.isEmpty) {
        if (kDebugMode) print('ChatService: No auth token available');
        _error = 'Authentication token not available';
        notifyListeners();
        return;
      }

      // Socket.IO client is configured with WebSocket-only transport for real-time communication
      // Auto-connect is disabled to allow listener setup before connection
      _socket = IO.io(
        AppConfig.socketIOUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'userId': userId})
            .build(),
      );

      // Event listeners must be configured before establishing the connection
      // to ensure no events are missed during the initial handshake
      _setupSocketListeners();

      // Connection is initiated; the onConnect handler will handle user registration
      _socket!.connect();

      if (kDebugMode) print('ChatService: Connection initiated for user: $userId');

      // User registration occurs automatically in the onConnect event handler
      // once the WebSocket connection is successfully established
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
  ///
  /// Configures all real-time event handlers for the Socket.IO connection.
  /// Listeners are organised into categories:
  /// - Connection lifecycle (connect, disconnect, errors)
  /// - User registration and authentication
  /// - Real-time messaging (new messages, typing indicators)
  /// - Room management (join/leave confirmations)
  /// - Presence tracking (user online/offline status)
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection lifecycle: When the WebSocket connection is successfully established
    _socket!.onConnect((_) async {
      if (kDebugMode) print('ChatService: Connected to server');

      // User registration is performed immediately after connection
      // The Railway Socket server requires this authentication step before
      // accepting any room joins or message sends from the client
      final userId = _authService.uid;
      final displayName = _authService.currentUser?.displayName ?? 'User';
      final authToken = await _authService.getIdToken();

      if (userId != null && authToken != null) {
        if (kDebugMode) print('ChatService: Registering user: $userId');
        // Registration data is sent to the server for verification
        _socket!.emit('register', {
          'userId': userId,
          'displayName': displayName,
          'authToken': authToken,
        });
      }

      // Connection state is updated and UI listeners are notified
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

    // Registration confirmation: Server responds to our registration attempt
    _socket!.on('registered', (data) {
      if (kDebugMode) print('ChatService: Registration response: $data');
      try {
        final response = data as Map<String, dynamic>;
        if (response['success'] == true) {
          if (kDebugMode) print('ChatService: User registered successfully');
        } else {
          // Registration failure indicates invalid credentials or server error
          if (kDebugMode) print('ChatService: Registration failed: ${response['error']}');
          _error = response['error'] as String?;
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) print('ChatService: Error parsing registration response: $e');
      }
    });

    // Real-time messages: Server broadcasts new messages to all participants in a room
    // The 'new-message' event is emitted when any user sends a message via Socket.IO
    _socket!.on('new-message', (data) {
      if (kDebugMode) print('ChatService: New message received: $data');
      try {
        final message = ChatMessage.fromJson(data as Map<String, dynamic>);

        // Message is added to the local cache for immediate UI display
        if (!_messagesCache.containsKey(message.roomId)) {
          _messagesCache[message.roomId] = [];
        }
        _messagesCache[message.roomId]!.add(message);

        // Room metadata is updated to reflect the latest message
        // This ensures the room list shows current activity
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

        // Message stream notifies the UI to display the new message
        _messageController.add(message);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) print('ChatService: Error parsing message: $e');
      }
    });

    // Typing indicators: Server broadcasts when users start or stop typing
    // The 'user-typing' event includes the user's ID, display name, and typing state
    _socket!.on('user-typing', (data) {
      if (kDebugMode) print('ChatService: User typing event: $data');
      try {
        final indicator = TypingIndicator.fromJson(data as Map<String, dynamic>);
        // Typing indicator stream allows the UI to show "User is typing..." messages
        _typingController.add(indicator);
      } catch (e) {
        if (kDebugMode) print('ChatService: Error parsing typing indicator: $e');
      }
    });

    // Room join confirmation: Server acknowledges successful room entry
    _socket!.on('joined-room', (data) {
      if (kDebugMode) print('ChatService: Joined room: $data');
    });

    // Presence tracking: Server notifies when users come online
    _socket!.on('user-online', (data) {
      if (kDebugMode) print('ChatService: User online: $data');
    });

    // Presence tracking: Server notifies when users go offline
    _socket!.on('user-offline', (data) {
      if (kDebugMode) print('ChatService: User offline: $data');
    });
  }

  // ============================================================================
  // ROOM OPERATIONS
  // ============================================================================

  /// Get all chat rooms for current user
  ///
  /// Retrieves the user's chat room list from the Vercel API, including:
  /// - Room metadata (ID, name, type, participants)
  /// - Participant user profiles (display names, photos)
  /// - Recent message history (last 50 messages per room)
  ///
  /// The /API/Chat/Records/:uid endpoint provides a complete chat overview
  /// in a single request, reducing API calls and improving performance.
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
      final userId = _authService.uid;

      if (userId == null) {
        _error = 'User ID not available';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // The Chat/Records endpoint returns comprehensive room data including recent messages
      // This matches the Ionic app implementation for consistent behaviour across platforms
      final url = AppConfig.getEndpoint('Chat/Records/$userId');

      if (kDebugMode) print('ChatService: Fetching chat records from $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Response structure: { userId: string, totalRooms: number, rooms: ChatRoom[] }
        // Each room includes participantsData and recentMessages arrays
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> roomsData = responseData['rooms'] ?? [];

        if (kDebugMode) print('ChatService: Received ${roomsData.length} rooms from API');

        _rooms = roomsData.map((json) => ChatRoom.fromJson(json)).toList();

        // Rooms are sorted by most recent activity to show active conversations first
        _rooms.sort((a, b) {
          if (a.lastMessageAt == null) return 1;
          if (b.lastMessageAt == null) return -1;
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        });

        // Recent messages from each room are cached locally to avoid redundant API calls
        // When opening a chat, these cached messages display immediately while fresh data loads
        for (final room in _rooms) {
          if (room.recentMessages != null && room.recentMessages!.isNotEmpty) {
            _messagesCache[room.roomId] = room.recentMessages!;
            if (kDebugMode) {
              print('ChatService: Cached ${room.recentMessages!.length} messages for room ${room.roomId}');
            }
          }
        }

        if (kDebugMode) print('ChatService: Loaded ${_rooms.length} rooms with cached messages');
      } else {
        if (kDebugMode) print('ChatService: API error ${response.statusCode}: ${response.body}');
        _error = 'Failed to load chat rooms (${response.statusCode})';
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error loading chat rooms: $e');
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
  ///
  /// Subscribes the current user to a chat room's real-time events.
  /// Once joined, the client will receive:
  /// - New messages sent to this room
  /// - Typing indicators from other participants
  /// - User join/leave notifications
  ///
  /// The server acknowledges the join with a 'joined-room' event.
  Future<void> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      if (kDebugMode) print('ChatService: Cannot join room - not connected');
      return;
    }

    final userId = _authService.uid;
    if (userId == null) {
      if (kDebugMode) print('ChatService: Cannot join room - no user ID');
      return;
    }

    if (kDebugMode) print('ChatService: Joining room $roomId');

    // The 'join-room' event subscribes this socket to the specified room's broadcast channel
    _socket!.emit('join-room', {
      'roomId': roomId,
      'userId': userId,
    });
  }

  /// Leave a chat room (Socket.IO)
  ///
  /// Unsubscribes the current user from a chat room's real-time events.
  /// After leaving, the client will no longer receive messages or notifications
  /// from this room. This is called automatically when the user navigates away
  /// from a chat page to conserve bandwidth and reduce server load.
  Future<void> leaveRoom(String roomId) async {
    if (!_isConnected || _socket == null) return;

    final userId = _authService.uid;
    if (userId == null) return;

    if (kDebugMode) print('ChatService: Leaving room $roomId');

    // The 'leave-room' event unsubscribes this socket from the room's broadcast channel
    _socket!.emit('leave-room', {
      'roomId': roomId,
      'userId': userId,
    });
  }

  // ============================================================================
  // MESSAGE OPERATIONS
  // ============================================================================

  /// Get messages for a room
  ///
  /// Retrieves message history for a chat room using a two-tier approach:
  /// 1. First checks local cache (populated by getChatRooms with recent messages)
  /// 2. If cache miss, fetches from API with configurable message limit
  ///
  /// This strategy provides instant message display when opening frequently-used
  /// chats whilst still supporting full history access for older conversations.
  Future<List<ChatMessage>> getMessages(String roomId, {int limit = 50}) async {
    try {
      // Cached messages provide instant display without network delay
      // These are populated by the initial getChatRooms call which includes recent messages
      if (_messagesCache.containsKey(roomId) && _messagesCache[roomId]!.isNotEmpty) {
        if (kDebugMode) {
          print('ChatService: Returning ${_messagesCache[roomId]!.length} cached messages for $roomId');
        }
        return _messagesCache[roomId]!;
      }

      // Cache miss: fetch full message history from the API
      final token = await _authService.getIdToken();
      final url = AppConfig.getEndpoint('Chat/Rooms/$roomId/Messages?limit=$limit');

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
        // Response structure: { roomId: string, count: number, messages: ChatMessage[] }
        // Messages are returned in chronological order (oldest first) for natural display
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> messagesData = responseData['messages'] ?? [];

        final messages = messagesData.map((json) => ChatMessage.fromJson(json)).toList();
        _messagesCache[roomId] = messages;
        notifyListeners();

        if (kDebugMode) print('ChatService: Loaded ${messages.length} messages from API');
        return messages;
      } else {
        if (kDebugMode) print('ChatService: API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error loading messages: $e');
    }
    return [];
  }

  /// Send a message
  ///
  /// Transmits a message to all participants in a chat room using a hybrid approach:
  ///
  /// Primary path (Socket.IO):
  /// - Message is sent via WebSocket for instant delivery to online users
  /// - Railway Socket server receives the 'send-message' event
  /// - Server broadcasts to all room participants via 'new-message' event
  /// - Server persists message to Firestore via Vercel API automatically
  ///
  /// Fallback path (Direct API):
  /// - If Socket.IO connection is unavailable, message saves directly to API
  /// - Ensures message delivery even during network issues or reconnection
  /// - Messages are retrieved on next room entry
  Future<bool> sendMessage(String roomId, String text, {String? imageUrl}) async {
    try {
      final userId = _authService.uid;
      final displayName = _authService.currentUser?.displayName ?? 'User';

      if (userId == null) {
        if (kDebugMode) print('ChatService: Cannot send message - no user ID');
        return false;
      }

      if (kDebugMode) print('ChatService: Sending message to room $roomId via Socket.IO');

      // Primary delivery: Real-time WebSocket transmission
      // The Railway Socket server handles both broadcast and persistence
      if (_socket != null && _isConnected) {
        final messageData = {
          'roomId': roomId,
          'userId': userId,
          'displayName': displayName,
          'message': text,
          if (imageUrl != null) 'imageUrl': imageUrl,
        };

        _socket!.emit('send-message', messageData);

        if (kDebugMode) print('ChatService: Message sent via Socket.IO');
        return true;
      } else {
        if (kDebugMode) print('ChatService: Socket not connected, using API fallback');

        // Fallback delivery: Direct API persistence when WebSocket is unavailable
        // This ensures messages are never lost due to connectivity issues
        final token = await _authService.getIdToken();
        final url = AppConfig.getEndpoint('Chat/Rooms/$roomId/Messages');

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'x-api-passcode': AppConfig.apiPasscode,
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'message': text,
            'displayName': displayName,
            if (imageUrl != null) 'imageUrl': imageUrl,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          if (kDebugMode) print('ChatService: Message saved via API fallback');
          // Message history is refreshed to include the newly persisted message
          await getMessages(roomId);
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error sending message: $e');
    }
    return false;
  }

  /// Edit a message
  ///
  /// Modifies an existing message's content. The API enforces ownership verification
  /// by requiring the userId in the request body, ensuring users can only edit their
  /// own messages. The edited flag is set to true and an editedAt timestamp is recorded.
  ///
  /// Local cache is updated immediately for instant UI feedback whilst the server
  /// processes the edit request.
  Future<bool> editMessage(String roomId, String messageId, String newText) async {
    try {
      final token = await _authService.getIdToken();
      final userId = _authService.uid;

      if (userId == null) {
        if (kDebugMode) print('ChatService: Cannot edit message - no user ID');
        return false;
      }

      final url = AppConfig.getEndpoint('Chat/Rooms/$roomId/Messages/$messageId');

      if (kDebugMode) print('ChatService: Editing message $messageId');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
        // The API verifies userId matches the message author before allowing edits
        // This prevents users from modifying other participants' messages
        body: json.encode({
          'message': newText,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        // Local cache is updated to reflect the edit immediately
        // This provides instant UI feedback without waiting for a server broadcast
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
        if (kDebugMode) print('ChatService: Message edited successfully');
        return true;
      } else {
        if (kDebugMode) print('ChatService: Edit failed ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error editing message: $e');
    }
    return false;
  }

  /// Delete a message
  ///
  /// Performs a soft delete on a message. The message content is replaced with
  /// "[Message deleted]" and the deleted flag is set to true. The API enforces
  /// ownership verification by requiring the userId in the request body.
  ///
  /// Note: DELETE requests with body content require special handling in Dart's
  /// http package using the Request class instead of the convenience methods.
  Future<bool> deleteMessage(String roomId, String messageId) async {
    try {
      final token = await _authService.getIdToken();
      final userId = _authService.uid;

      if (userId == null) {
        if (kDebugMode) print('ChatService: Cannot delete message - no user ID');
        return false;
      }

      final url = AppConfig.getEndpoint('Chat/Rooms/$roomId/Messages/$messageId');

      if (kDebugMode) print('ChatService: Deleting message $messageId');

      // Dart's http package requires the Request class for DELETE operations with a body
      // The standard http.delete() method doesn't support request bodies
      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'x-api-passcode': AppConfig.apiPasscode,
        'Content-Type': 'application/json',
      });
      // The API verifies userId matches the message author before allowing deletion
      request.body = json.encode({'userId': userId});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Local cache is updated to show the soft delete immediately
        // The message remains in the list but displays as "[Message deleted]"
        if (_messagesCache.containsKey(roomId)) {
          final index = _messagesCache[roomId]!.indexWhere((m) => m.messageId == messageId);
          if (index != -1) {
            _messagesCache[roomId]![index] = _messagesCache[roomId]![index].copyWith(
              deleted: true,
              message: '[Message deleted]',
            );
            notifyListeners();
          }
        }
        if (kDebugMode) print('ChatService: Message deleted successfully');
        return true;
      } else {
        if (kDebugMode) print('ChatService: Delete failed ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('ChatService: Error deleting message: $e');
    }
    return false;
  }

  /// Emit typing indicator
  ///
  /// Broadcasts the user's typing status to other participants in the room.
  /// The server relays this to all other clients via the 'user-typing' event,
  /// allowing them to display "User is typing..." indicators in real-time.
  ///
  /// The isTyping flag should be:
  /// - true when the user starts typing (first character entered)
  /// - false when the user stops typing or sends a message
  void sendTypingIndicator(String roomId, bool isTyping) {
    if (!_isConnected || _socket == null) return;

    final userId = _authService.uid;
    final displayName = _authService.currentUser?.displayName ?? 'User';

    if (userId == null) return;

    // The typing event includes display name so other clients can show
    // "John is typing..." without needing to fetch user profiles
    _socket!.emit('typing', {
      'roomId': roomId,
      'userId': userId,
      'displayName': displayName,
      'isTyping': isTyping,
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
