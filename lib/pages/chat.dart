import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models.dart';

// Chat page with Material Design message bubbles for real-time messaging
class ChatPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final bool isTraditionalChinese;

  const ChatPage({
    required this.roomId,
    required this.roomName,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Text input controller
  final TextEditingController _messageController = TextEditingController();
  // Scroll controller for auto-scrolling to bottom
  final ScrollController _scrollController = ScrollController();
  // Image picker for photo uploads
  final ImagePicker _imagePicker = ImagePicker();
  // Loading state for image upload
  bool _isUploadingImage = false;
  // Focus node for text field
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Join room after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  // Initialises chat connection and joins the room
  Future<void> _initializeChat() async {
    final chatService = context.read<ChatService>();

    // Connect if not already connected
    if (!chatService.isConnected) {
      await chatService.connect();
    }

    // Join the chat room
    await chatService.joinRoom(widget.roomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    // Leave room on dispose
    context.read<ChatService>().leaveRoom();
    super.dispose();
  }

  // Scrolls to the bottom of the message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Sends a text message
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    await context.read<ChatService>().sendMessage(message);
    _scrollToBottom();
  }

  // Picks and uploads an image
  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      // Upload to Firebase Storage
      final file = File(pickedFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final authService = context.read<AuthService>();
      final fileName = 'chat_images/${authService.uid}/$timestamp.jpg';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Send as image message
      await context.read<ChatService>().sendImageMessage(downloadUrl);
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese ? '上傳圖片失敗' : 'Failed to upload image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  // Handles typing indicator
  void _onTypingChanged(String value) {
    final chatService = context.read<ChatService>();
    chatService.setTyping(value.isNotEmpty);
  }

  // Builds a message bubble widget
  Widget _buildMessageBubble(ChatMessage message, bool isOwnMessage) {
    final theme = Theme.of(context);
    final bubbleColor = isOwnMessage
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isOwnMessage
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderPhotoUrl != null
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name for other users
                  if (!isOwnMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                  // Image or text content
                  if (message.isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: message.content,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.error),
                        ),
                      ),
                    )
                  else
                    Text(
                      message.content,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      timeago.format(message.timestamp, locale: 'en_short'),
                      style: TextStyle(
                        fontSize: 10,
                        color: isOwnMessage
                            ? textColor.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the typing indicator
  Widget _buildTypingIndicator(Map<String, String> typingUsers) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final names = typingUsers.values.take(2).join(', ');
    final suffix = typingUsers.length > 2 ? ' +${typingUsers.length - 2}' : '';
    final label = widget.isTraditionalChinese ? '$names$suffix 正在輸入...' : '$names$suffix typing...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  builder: (context, value, child) {
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5 + (value * 0.5)),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUserId = authService.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        elevation: 1,
        actions: [
          // Connection status indicator
          Consumer<ChatService>(
            builder: (context, chatService, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  chatService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: chatService.isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatService>(
        builder: (context, chatService, _) {
          // Show loading state
          if (chatService.isConnecting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    widget.isTraditionalChinese ? '連接中...' : 'Connecting...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Show error state
          if (chatService.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      chatService.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _initializeChat,
                      icon: const Icon(Icons.refresh),
                      label: Text(widget.isTraditionalChinese ? '重試' : 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Auto-scroll when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return Column(
            children: [
              // Message list
              Expanded(
                child: chatService.messages.isEmpty
                    ? Center(
                        child: Text(
                          widget.isTraditionalChinese ? '開始對話...' : 'Start a conversation...',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chatService.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatService.messages[index];
                          final isOwnMessage = message.senderId == currentUserId;
                          return _buildMessageBubble(message, isOwnMessage);
                        },
                      ),
              ),

              // Typing indicator
              _buildTypingIndicator(chatService.typingUsers),

              // Divider
              const Divider(height: 1),

              // Input area
              Container(
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: Row(
                    children: [
                      // Image picker button
                      IconButton(
                        onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                        icon: _isUploadingImage
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image),
                        tooltip: widget.isTraditionalChinese ? '選擇圖片' : 'Pick image',
                      ),

                      // Text input field
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          onChanged: _onTypingChanged,
                          onSubmitted: (_) => _sendMessage(),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: widget.isTraditionalChinese ? '輸入訊息...' : 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Send button
                      FloatingActionButton.small(
                        onPressed: _sendMessage,
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
