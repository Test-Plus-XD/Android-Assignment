import 'user.dart';

/// Chat room model representing a conversation between users
///
/// Supports both direct (1-on-1) and group chat rooms
class ChatRoom {
  final String roomId;
  final List<String> participants;
  final String? roomName;
  final String type; // 'direct' or 'group'
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

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    List<User>? participantsData;
    if (json['participantsData'] != null) {
      participantsData = (json['participantsData'] as List)
          .map((userData) => User.fromJson(userData as Map<String, dynamic>))
          .toList();
    }

    List<ChatMessage>? recentMessages;
    if (json['recentMessages'] != null) {
      recentMessages = (json['recentMessages'] as List)
          .map((messageData) => ChatMessage.fromJson(messageData as Map<String, dynamic>))
          .toList();
    }

    return ChatRoom(
      roomId: json['roomId'] as String,
      participants: (json['participants'] as List).map((e) => e.toString()).toList(),
      roomName: json['roomName'] as String?,
      type: json['type'] as String? ?? 'direct',
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt'] as String) : null,
      messageCount: json['messageCount'] as int? ?? 0,
      participantsData: participantsData,
      recentMessages: recentMessages,
    );
  }

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
      if (participantsData != null) 'participantsData': participantsData!.map((u) => u.toJson()).toList(),
      if (recentMessages != null) 'recentMessages': recentMessages!.map((m) => m.toJson()).toList(),
    };
  }

  /// Get room display name based on type and participants
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

/// Chat message model
///
/// Represents a single message in a chat conversation
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] as String,
      roomId: json['roomId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      edited: json['edited'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
    );
  }

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

  /// Create a copy with updated fields
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

/// Typing indicator model
///
/// Represents a user's typing status in a chat room
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

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      roomId: json['roomId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      isTyping: json['isTyping'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'userId': userId,
      'displayName': displayName,
      'isTyping': isTyping,
    };
  }
}
