import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models.dart';

/// Chat Bubble Widget
///
/// Displays a single chat message with:
/// - User avatar
/// - Message content
/// - Timestamp
/// - Optional image attachment
/// - Edit/delete menu for own messages
/// - Edited indicator
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool isTraditionalChinese;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isTraditionalChinese = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isCurrentUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isCurrentUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Sender name (only show for other users)
          if (!isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 4),
              child: Text(
                message.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // Message bubble
          Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar (for other users)
              if (!isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      message.displayName.isNotEmpty ? message.displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Message content
              Flexible(
                child: GestureDetector(
                  onLongPress: isCurrentUser && (onEdit != null || onDelete != null)
                      ? () => _showMessageMenu(context)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                        bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message text
                        if (!message.deleted)
                          Text(
                            message.message,
                            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                          )
                        else
                          Text(
                            isTraditionalChinese ? '訊息已刪除' : 'Message deleted',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                        // Image attachment
                        if (message.imageUrl != null && !message.deleted) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: message.imageUrl!,
                              width: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 200,
                                height: 150,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 200,
                                height: 150,
                                color: theme.colorScheme.errorContainer,
                                child: Icon(
                                  Icons.broken_image,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Timestamp and edited indicator
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeago.format(
                                message.timestamp,
                                locale: isTraditionalChinese ? 'zh' : 'en',
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            if (message.edited && !message.deleted) ...[
                              const SizedBox(width: 4),
                              Text(
                                '•',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isTraditionalChinese ? '已編輯' : 'edited',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: textColor.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show message menu (edit/delete)
  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null && !message.deleted)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(isTraditionalChinese ? '編輯訊息' : 'Edit message'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(isTraditionalChinese ? '刪除訊息' : 'Delete message'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}
