import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/chat/chat_room_list.dart';
import 'chat_page.dart';

/// Chat Rooms Page
///
/// Lists all chat rooms for the current user
class ChatRoomsPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const ChatRoomsPage({
    super.key,
    this.isTraditionalChinese = false,
  });

  @override
  State<ChatRoomsPage> createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();

    // Connect to socket if not connected
    if (!chatService.isConnected && authService.currentUser != null) {
      await chatService.connect(authService.currentUser!.uid);
    }

    // Load rooms
    await chatService.getChatRooms();
  }

  void _navigateToChat(String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          roomId: roomId,
          isTraditionalChinese: widget.isTraditionalChinese,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<ChatService>();
    final authService = context.watch<AuthService>();

    if (!authService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isTraditionalChinese ? '聊天' : 'Chats'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese ? '請先登入' : 'Please log in',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isTraditionalChinese
                    ? '登入後即可使用聊天功能'
                    : 'Log in to use chat features',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTraditionalChinese ? '聊天' : 'Chats'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chatService.isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  chatService.isConnected
                      ? (widget.isTraditionalChinese ? '在線' : 'Online')
                      : (widget.isTraditionalChinese ? '離線' : 'Offline'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
      body: ChatRoomList(
        rooms: chatService.rooms,
        currentUserId: authService.currentUser?.uid ?? '',
        isTraditionalChinese: widget.isTraditionalChinese,
        onRoomTap: (room) => _navigateToChat(room.roomId),
        onRefresh: _loadRooms,
        isLoading: chatService.isLoading,
      ),
    );
  }
}
