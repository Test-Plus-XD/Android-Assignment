import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models.dart';

/// Chat Bubble Widget
///
/// Displays a single chat message with:
/// - User avatar with Firebase Auth profile picture (photoURL)
/// - Message content
/// - Timestamp
/// - Optional image attachment (from imageUrl field or detected in message text)
/// - Edit/delete menu for own messages
/// - Edited indicator
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool isTraditionalChinese;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? userPhotoUrl; // Firebase Auth photoURL

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isTraditionalChinese = false,
    this.onEdit,
    this.onDelete,
    this.userPhotoUrl, // Optional photoURL from Firebase Auth
  });

  /// Regular expression to detect image URLs in message text
  /// Matches URLs ending with common image extensions or Firebase Storage URLs
  static final RegExp _imageUrlRegex = RegExp(
    r'(https?://[^\s]+\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^\s]*)?)|'
    r'(https?://firebasestorage\.googleapis\.com/[^\s]+)',
    caseSensitive: false,
  );

  /// Extracts image URLs from message text
  List<String> _extractImageUrls(String text) {
    final matches = _imageUrlRegex.allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Returns the message text with image URLs removed (for cleaner display)
  String _getTextWithoutImageUrls(String text) {
    return text.replaceAll(_imageUrlRegex, '').trim();
  }

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
              // Avatar (for other users) with Firebase Auth photoURL
              if (!isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: CachedNetworkImageProvider(userPhotoUrl!),
                          backgroundColor: theme.colorScheme.primary,
                          onBackgroundImageError: (_, __) {
                            // Fallback to initials if image fails to load
                          },
                          child: Container(), // Empty container to show background image
                        )
                      : CircleAvatar(
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
                    child: Builder(
                      builder: (context) {
                        // Extract image URLs from message text
                        final detectedImageUrls = message.deleted ? <String>[] : _extractImageUrls(message.message);
                        final textWithoutUrls = message.deleted ? '' : _getTextWithoutImageUrls(message.message);

                        // Combine imageUrl field with detected URLs (avoid duplicates)
                        final allImageUrls = <String>[
                          if (message.imageUrl != null) message.imageUrl!,
                          ...detectedImageUrls.where((url) => url != message.imageUrl),
                        ];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Message text (without image URLs for cleaner display)
                            if (!message.deleted && textWithoutUrls.isNotEmpty)
                              Text(
                                textWithoutUrls,
                                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                              )
                            else if (message.deleted)
                              Text(
                                isTraditionalChinese ? '訊息已刪除' : 'Message deleted',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),

                            // Display all images (from imageUrl field and detected in text)
                            if (allImageUrls.isNotEmpty && !message.deleted)
                              ...allImageUrls.map((imageUrl) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () => _showFullScreenImage(context, imageUrl),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
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
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              color: theme.colorScheme.onErrorContainer,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isTraditionalChinese ? '無法載入圖片' : 'Failed to load',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onErrorContainer,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )),

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
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                if (message.edited && !message.deleted) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '•',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: textColor.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isTraditionalChinese ? '已編輯' : 'edited',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: textColor.withValues(alpha: 0.7),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      },
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

  /// Shows the image in full screen dialog
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Full screen image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.white),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
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
