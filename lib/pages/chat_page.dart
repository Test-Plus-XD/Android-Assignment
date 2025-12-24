import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/image_service.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/chat/typing_indicator.dart';

/// Chat Page
///
/// Full chat interface showing:
/// - Message list with auto-scroll
/// - Real-time message updates
/// - Typing indicators
/// - Message input
/// - Image attachments
/// - Edit/delete functionality
class ChatPage extends StatelessWidget {
  final String roomId;
  final bool isTraditionalChinese;

  const ChatPage({
    super.key,
    required this.roomId,
    this.isTraditionalChinese = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChatPageContent(
      roomId: roomId,
      isTraditionalChinese: isTraditionalChinese,
    );
  }
}

class _ChatPageContent extends StatefulWidget {
  final String roomId;
  final bool isTraditionalChinese;

  const _ChatPageContent({
    required this.roomId,
    required this.isTraditionalChinese,
  });

  @override
  State<_ChatPageContent> createState() => _ChatPageContentState();
}

class _ChatPageContentState extends State<_ChatPageContent> {
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
    final chatService = context.read<ChatService>();
    chatService.leaveRoom(widget.roomId);

    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final chatService = context.read<ChatService>();

    // Join room
    await chatService.joinRoom(widget.roomId);

    // Load room details
    final room = await chatService.getChatRoom(widget.roomId);
    if (room != null) {
      setState(() => _room = room);
    }

    // Load messages
    final messages = await chatService.getMessages(widget.roomId);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _setupListeners() {
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final currentUserId = authService.currentUser?.uid;

    // Listen for new messages
    _messageSubscription = chatService.messageStream.listen((message) {
      if (message.roomId == widget.roomId) {
        setState(() {
          // Avoid duplicates
          if (!_messages.any((m) => m.messageId == message.messageId)) {
            _messages.add(message);
          }
        });

        // Scroll to bottom if message is from current user
        if (message.userId == currentUserId) {
          _scrollToBottom();
        }
      }
    });

    // Listen for typing indicators
    _typingSubscription = chatService.typingStream.listen((indicator) {
      if (indicator.roomId == widget.roomId && indicator.userId != currentUserId) {
        setState(() {
          _typingUsers[indicator.userId] = indicator.isTyping;
        });

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
    _scrollToBottom();
  }

  void _handleTypingChanged(bool isTyping) {
    final chatService = context.read<ChatService>();
    chatService.sendTypingIndicator(widget.roomId, isTyping);
  }

  Future<void> _handleEditMessage(ChatMessage message) async {
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
      final chatService = context.read<ChatService>();
      await chatService.editMessage(widget.roomId, message.messageId, result);

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

  Future<void> _handleDeleteMessage(ChatMessage message) async {
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
      final chatService = context.read<ChatService>();
      await chatService.deleteMessage(widget.roomId, message.messageId);

      // Remove from local list
      setState(() {
        _messages.removeWhere((m) => m.messageId == message.messageId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final imageService = context.watch<ImageService>();
    final currentUserId = authService.currentUser?.uid ?? '';

    // Get room title
    final roomTitle = _room?.getDisplayName(currentUserId, widget.isTraditionalChinese) ??
        (widget.isTraditionalChinese ? '聊天' : 'Chat');

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
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.isTraditionalChinese ? '沒有訊息' : 'No messages yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isTraditionalChinese
                                  ? '開始對話吧！'
                                  : 'Start the conversation!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
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

                          return ChatBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            isTraditionalChinese: widget.isTraditionalChinese,
                            onEdit: isCurrentUser && !message.deleted
                                ? () => _handleEditMessage(message)
                                : null,
                            onDelete: isCurrentUser ? () => _handleDeleteMessage(message) : null,
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
