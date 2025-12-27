import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/image_service.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/chat/typing_indicator.dart';

/// Chat Room Page
///
/// Full chat interface showing:
/// - Message list with auto-scroll
/// - Real-time message updates
/// - Typing indicators
/// - Message input
/// - Image attachments
/// - Edit/delete functionality
class ChatRoomPage extends StatelessWidget {
  final String roomId;
  final bool isTraditionalChinese;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    this.isTraditionalChinese = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChatRoomPageContent(
      roomId: roomId,
      isTraditionalChinese: isTraditionalChinese,
    );
  }
}

class _ChatRoomPageContent extends StatefulWidget {
  final String roomId;
  final bool isTraditionalChinese;

  const _ChatRoomPageContent({
    required this.roomId,
    required this.isTraditionalChinese,
  });

  @override
  State<_ChatRoomPageContent> createState() => _ChatRoomPageContentState();
}

class _ChatRoomPageContentState extends State<_ChatRoomPageContent> {
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  ChatRoom? _room;
  final Map<String, bool> _typingUsers = {};
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<TypingIndicator>? _typingSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _scrollController.dispose();

    // Leave room on dispose
    try {
      final chatService = context.read<ChatService>();
      chatService.leaveRoom(widget.roomId);
    } catch (e) {
      // Context might not be available
    }

    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final chatService = context.read<ChatService>();

    // Join room
    await chatService.joinRoom(widget.roomId);

    // Load room details
    final room = await chatService.getChatRoom(widget.roomId);
    if (mounted && room != null) {
      setState(() => _room = room);
    }

    // Load messages
    final messages = await chatService.getMessages(widget.roomId);
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _setupListeners() {
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final currentUserId = authService.currentUser?.uid;

    // Listen for new messages
    _messageSubscription = chatService.messageStream.listen((message) {
      if (message.roomId == widget.roomId) {
        if (mounted) {
          setState(() {
            // Avoid duplicates
            if (!_messages.any((m) => m.messageId == message.messageId)) {
              _messages.add(message);
            }
          });

          // Always scroll to bottom for any new message (not just current user)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    });

    // Listen for typing indicators
    _typingSubscription = chatService.typingStream.listen((indicator) {
      if (indicator.roomId == widget.roomId && indicator.userId != currentUserId) {
        if (mounted) {
          setState(() {
            _typingUsers[indicator.userId] = indicator.isTyping;
          });
        }

        // Remove typing indicator after 3 seconds
        if (indicator.isTyping) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _typingUsers.remove(indicator.userId);
              });
            }
          });
        }
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage(String message, {String? imageUrl}) async {
    final chatService = context.read<ChatService>();
    await chatService.sendMessage(widget.roomId, message, imageUrl: imageUrl);
    if (mounted) {
      _scrollToBottom();
    }
  }

  void _handleTypingChanged(bool isTyping) {
    final chatService = context.read<ChatService>();
    chatService.sendTypingIndicator(widget.roomId, isTyping);
  }

  Future<void> _handleEditMessage(ChatMessage message) async {
    final chatService = context.read<ChatService>();
    final controller = TextEditingController(text: message.message);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '編輯訊息' : 'Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(
            hintText: widget.isTraditionalChinese ? '輸入訊息...' : 'Type a message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(widget.isTraditionalChinese ? '儲存' : 'Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && result != message.message) {
      await chatService.editMessage(widget.roomId, message.messageId, result);

      if (mounted) {
        // Update local message
        setState(() {
          final index = _messages.indexWhere((m) => m.messageId == message.messageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              message: result,
              edited: true,
            );
          }
        });
      }
    }
  }

  Future<void> _handleDeleteMessage(ChatMessage message) async {
    final chatService = context.read<ChatService>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '刪除訊息' : 'Delete message'),
        content: Text(
          widget.isTraditionalChinese
              ? '確定要刪除此訊息嗎？'
              : 'Are you sure you want to delete this message?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(widget.isTraditionalChinese ? '刪除' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await chatService.deleteMessage(widget.roomId, message.messageId);

      if (mounted) {
        // Remove from local list
        setState(() {
          _messages.removeWhere((m) => m.messageId == message.messageId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final userService = context.watch<UserService>();
    final imageService = context.watch<ImageService>();
    final currentUserId = authService.currentUser?.uid ?? '';
    final userType = userService.currentProfile?.type ?? 'Diner';

    // Get room title
    final roomTitle = _room?.getDisplayName(currentUserId, widget.isTraditionalChinese) ??
        (widget.isTraditionalChinese ? '聊天' : 'Chat');

    // Role-based placeholder messages
    String getEmptyStateTitle() {
      if (widget.isTraditionalChinese) {
        return userType == 'Restaurant' ? '沒有顧客訊息' : '沒有訊息';
      } else {
        return userType == 'Restaurant' ? 'No customer messages' : 'No messages yet';
      }
    }

    String getEmptyStateSubtitle() {
      if (widget.isTraditionalChinese) {
        return userType == 'Restaurant'
            ? '當顧客向您發送查詢時，訊息將會顯示在這裡'
            : '開始對話吧！';
      } else {
        return userType == 'Restaurant'
            ? 'Messages from customers will appear here'
            : 'Start the conversation!';
      }
    }

    // Get typing users
    final typingUsersList = _typingUsers.entries
        .where((entry) => entry.value)
        .map((entry) {
          // Find user display name from room participants
          if (_room?.participantsData != null) {
            final user = _room!.participantsData!.firstWhere(
              (u) => u.uid == entry.key,
              orElse: () => User(
                uid: entry.key,
                displayName: widget.isTraditionalChinese ? '用戶' : 'User',
                emailVerified: false,
              ),
            );
            return user.displayName ?? user.email ?? (widget.isTraditionalChinese ? '用戶' : 'User');
          }
          return widget.isTraditionalChinese ? '用戶' : 'User';
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(roomTitle),
            if (_room?.participants != null)
              Text(
                widget.isTraditionalChinese
                    ? '${_room!.participants.length} 位成員'
                    : '${_room!.participants.length} participants',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              userType == 'Restaurant' ? Icons.storefront : Icons.chat_bubble_outline,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              getEmptyStateTitle(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              getEmptyStateSubtitle(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length + (typingUsersList.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show typing indicators at the end
                          if (index == _messages.length && typingUsersList.isNotEmpty) {
                            return TypingIndicatorWidget(
                              displayName: typingUsersList.first,
                              isTraditionalChinese: widget.isTraditionalChinese,
                            );
                          }

                          final message = _messages[index];
                          final isCurrentUser = message.userId == currentUserId;

                          // Get photoURL from participantsData for this message's sender
                          String? photoUrl;
                          if (_room?.participantsData != null) {
                            final sender = _room!.participantsData!.firstWhere(
                              (u) => u.uid == message.userId,
                              orElse: () => User(
                                uid: message.userId,
                                displayName: message.displayName,
                                emailVerified: false,
                              ),
                            );
                            photoUrl = sender.photoURL;
                          }

                          return ChatBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            isTraditionalChinese: widget.isTraditionalChinese,
                            onEdit: isCurrentUser && !message.deleted
                                ? () => _handleEditMessage(message)
                                : null,
                            onDelete: isCurrentUser ? () => _handleDeleteMessage(message) : null,
                            userPhotoUrl: photoUrl, // Pass Firebase Auth photoURL
                          );
                        },
                      ),
          ),

          // Message input
          ChatInput(
            onSend: _handleSendMessage,
            onTypingChanged: _handleTypingChanged,
            isTraditionalChinese: widget.isTraditionalChinese,
            imageService: imageService,
          ),
        ],
      ),
    );
  }
}