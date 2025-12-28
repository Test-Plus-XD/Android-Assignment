import 'user.dart';

// Chat room model representing a conversation between users
// Supports both direct (1-on-1) and group chat rooms
// All fields are parsed with null-safety to handle incomplete API responses
class ChatRoom {
  final String roomId;
  final List<String> participants;
  final String? roomName;
  final String type;
  final String? createdBy;
  final DateTime? createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int messageCount;
  final List<User>? participantsData;
  final List<ChatMessage>? recentMessages;

  ChatRoom({
    required this.roomId,
    required this.participants,
    this.roomName,
    required this.type,
    this.createdBy,
    this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.messageCount = 0,
    this.participantsData,
    this.recentMessages,
  });

  // Backward compatibility getter - alias for roomName
  String? get name => roomName;

  // Factory constructor for parsing JSON from the API
  // Handles nullable fields gracefully to prevent type cast errors
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    // Participant user data is parsed if available
    List<User>? participantsData;
    if (json['participantsData'] != null) {
      try {
        participantsData = (json['participantsData'] as List)
            .map((userData) => User.fromJson(userData as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Parsing error is caught to prevent entire room from failing
        participantsData = null;
      }
    }
    // Recent messages are parsed if available
    List<ChatMessage>? recentMessages;
    if (json['recentMessages'] != null) {
      try {
        recentMessages = (json['recentMessages'] as List)
            .map((messageData) => ChatMessage.fromJson(messageData as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Parsing error is caught to prevent entire room from failing
        recentMessages = null;
      }
    }
    // Participants array is safely parsed with fallback to empty list
    List<String> participants = [];
    if (json['participants'] != null) {
      participants = (json['participants'] as List).map((element) => element.toString()).toList();
    }
    // DateTime fields are parsed with null checks
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        createdAt = null;
      }
    }
    DateTime? lastMessageAt;
    if (json['lastMessageAt'] != null) {
      try {
        lastMessageAt = DateTime.parse(json['lastMessageAt'].toString());
      } catch (e) {
        lastMessageAt = null;
      }
    }

    return ChatRoom(
      roomId: json['roomId']?.toString() ?? '',
      participants: participants,
      roomName: json['roomName']?.toString(),
      type: json['type']?.toString() ?? 'direct',
      createdBy: json['createdBy']?.toString(),
      createdAt: createdAt,
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: lastMessageAt,
      messageCount: json['messageCount'] as int? ?? 0,
      participantsData: participantsData,
      recentMessages: recentMessages,
    );
  }

  // Converts the ChatRoom to a JSON map for API requests
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'participants': participants,
      if (roomName != null) 'roomName': roomName,
      'type': type,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
      'messageCount': messageCount,
      if (participantsData != null) 'participantsData': participantsData!.map((user) => user.toJson()).toList(),
      if (recentMessages != null) 'recentMessages': recentMessages!.map((message) => message.toJson()).toList(),
    };
  }

  // Returns a display name for the room based on type and participants
  // For direct chats, shows the other participant's name
  // For group chats, uses the room name or a default label
  String getDisplayName(String currentUserId, bool isTraditionalChinese) {
    if (roomName != null && roomName!.isNotEmpty) {
      return roomName!;
    }

    if (type == 'group') {
      return isTraditionalChinese ? '群組聊天' : 'Group Chat';
    }

    // For direct chat, show the other participant's name
    if (participantsData != null && participantsData!.isNotEmpty) {
      final otherUser = participantsData!.firstWhere(
            (user) => user.uid != currentUserId,
        orElse: () => participantsData!.first,
      );
      return otherUser.displayName ?? otherUser.email ?? (isTraditionalChinese ? '未知用戶' : 'Unknown User');
    }

    return isTraditionalChinese ? '聊天' : 'Chat';
  }
}

// Chat message model representing a single message in a conversation
// All fields are parsed with null-safety to handle incomplete API responses
class ChatMessage {
  final String messageId;
  final String roomId;
  final String userId;
  final String displayName;
  final String message;
  final DateTime timestamp;
  final bool edited;
  final bool deleted;
  final String? imageUrl;

  ChatMessage({
    required this.messageId,
    required this.roomId,
    required this.userId,
    required this.displayName,
    required this.message,
    required this.timestamp,
    this.edited = false,
    this.deleted = false,
    this.imageUrl,
  });

  // Factory constructor for parsing JSON from the API
  // Uses null-coalescing operators to provide default values for missing fields
  // This prevents type cast errors when the API returns null for required fields
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Timestamp is parsed with fallback to current time if missing or invalid
    DateTime timestamp;
    try {
      timestamp = json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now();
    } catch (e) {
      timestamp = DateTime.now();
    }

    return ChatMessage(
      messageId: json['messageId']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Unknown',
      message: json['message']?.toString() ?? '',
      timestamp: timestamp,
      edited: json['edited'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  // Converts the ChatMessage to a JSON map for API requests
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'roomId': roomId,
      'userId': userId,
      'displayName': displayName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'edited': edited,
      'deleted': deleted,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  // Creates a copy of the message with updated fields
  // Used for local cache updates when editing or deleting messages
  ChatMessage copyWith({
    String? messageId,
    String? roomId,
    String? userId,
    String? displayName,
    String? message,
    DateTime? timestamp,
    bool? edited,
    bool? deleted,
    String? imageUrl,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      edited: edited ?? this.edited,
      deleted: deleted ?? this.deleted,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

// Typing indicator model representing a user's typing status in a chat room
// Used for real-time "User is typing..." notifications
class TypingIndicator {
  final String roomId;
  final String userId;
  final String displayName;
  final bool isTyping;

  TypingIndicator({
    required this.roomId,
    required this.userId,
    required this.displayName,
    required this.isTyping,
  });

  // Factory constructor for parsing JSON from the Socket.IO event
  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      roomId: json['roomId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'User',
      isTyping: json['isTyping'] as bool? ?? false,
    );
  }

  // Converts the TypingIndicator to a JSON map for Socket.IO events
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'userId': userId,
      'displayName': displayName,
      'isTyping': isTyping,
    };
  }
}