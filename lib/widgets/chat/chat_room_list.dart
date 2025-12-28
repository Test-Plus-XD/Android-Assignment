import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models.dart';
import '../common/loading_indicator.dart';

/// Chat Room List Widget
///
/// Displays list of chat rooms with:
/// - Room avatar
/// - Room name
/// - Last message preview
/// - Timestamp
/// - Unread count (if available)
class ChatRoomList extends StatelessWidget {
  final List<ChatRoom> rooms;
  final String currentUserId;
  final bool isTraditionalChinese;
  final Function(ChatRoom room) onRoomTap;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const ChatRoomList({
    super.key,
    required this.rooms,
    required this.currentUserId,
    required this.onRoomTap,
    this.isTraditionalChinese = false,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CenteredLoadingIndicator();
    }

    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isTraditionalChinese ? '沒有聊天記錄' : 'No chat rooms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isTraditionalChinese
                  ? '開始與餐廳或其他用戶聊天'
                  : 'Start a conversation with a restaurant or other users',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return ChatRoomListItem(
            room: room,
            currentUserId: currentUserId,
            isTraditionalChinese: isTraditionalChinese,
            onTap: () => onRoomTap(room),
          );
        },
      ),
    );
  }
}

/// Chat Room List Item Widget
class ChatRoomListItem extends StatelessWidget {
  final ChatRoom room;
  final String currentUserId;
  final bool isTraditionalChinese;
  final VoidCallback onTap;

  const ChatRoomListItem({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onTap,
    this.isTraditionalChinese = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomName = room.getDisplayName(currentUserId, isTraditionalChinese);

    // Get avatar letter
    String avatarLetter = '?';
    if (room.type == 'group') {
      avatarLetter = room.roomName?.isNotEmpty == true ? room.roomName![0].toUpperCase() : 'G';
    } else {
      // For direct chat, use other participant's initial
      if (room.participantsData != null && room.participantsData!.isNotEmpty) {
        final otherUser = room.participantsData!.firstWhere(
          (user) => user.uid != currentUserId,
          orElse: () => room.participantsData!.first,
        );
        final name = otherUser.displayName ?? otherUser.email ?? '';
        avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
      }
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: room.type == 'group'
            ? Icon(
                Icons.group,
                color: theme.colorScheme.onPrimaryContainer,
              )
            : Text(
                avatarLetter,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      title: Text(
        roomName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: room.lastMessage != null
          ? Text(
              room.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Text(
              isTraditionalChinese ? '沒有訊息' : 'No messages yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (room.lastMessageAt != null)
            Text(
              timeago.format(
                room.lastMessageAt!,
                locale: isTraditionalChinese ? 'zh' : 'en',
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          // Could add unread count badge here
        ],
      ),
    );
  }
}