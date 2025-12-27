import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/chat/chat_room_list.dart';
import 'chat_room_page.dart';

// Note: ChatService uses lazy initialisation via ensureConnected()
// Socket.IO connection is only established when user visits this page

/// Chat Page
///
/// Lists all chat rooms for the current user
class ChatPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const ChatPage({
    super.key,
    this.isTraditionalChinese = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    // Defer loading to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRooms();
    });
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;

    final chatService = context.read<ChatService>();

    // Use ensureConnected for lazy initialisation
    // This connects to Socket.IO and loads rooms only when needed
    await chatService.ensureConnected();
  }

  void _navigateToChat(String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          roomId: roomId,
          isTraditionalChinese: widget.isTraditionalChinese,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatService = context.watch<ChatService>();
    final authService = context.watch<AuthService>();
    final userService = context.watch<UserService>();
    final userType = userService.currentProfile?.type ?? 'Diner';

    if (!authService.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.login,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isTraditionalChinese ? '請先登入' : 'Please Log In',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isTraditionalChinese
                          ? '請登入以使用聊天功能並與餐廳溝通。'
                          : 'Please log in to use the chat feature and communicate with restaurants.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        // Navigate to login
                        Navigator.of(context).pushNamed('/login');
                      },
                      icon: const Icon(Icons.login),
                      label: Text(widget.isTraditionalChinese ? '登入' : 'Log In'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: chatService.rooms.isEmpty && !chatService.isLoading
          ? Column(
              children: [
                // Empty state - not expanded, just takes needed space
                _buildEmptyState(theme, userType),
                
                // Small spacing instead of Spacer
                const SizedBox(height: 24),
                
                // Usage flow info card
                _buildUsageInfoCard(theme, userType),
              ],
            )
          : ChatRoomList(
              rooms: chatService.rooms,
              currentUserId: authService.currentUser?.uid ?? '',
              isTraditionalChinese: widget.isTraditionalChinese,
              onRoomTap: (room) => _navigateToChat(room.roomId),
              onRefresh: _loadRooms,
              isLoading: chatService.isLoading,
            ),
    );
  }

  /// Builds empty state with no conversations message
  Widget _buildEmptyState(ThemeData theme, String userType) {
    final isRestaurant = userType == 'Restaurant';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRestaurant ? Icons.storefront : Icons.chat_bubble_outline,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isTraditionalChinese ? '沒有對話' : 'No Conversations',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getEmptyStateMessage(isRestaurant),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  // Navigate based on user type
                  if (isRestaurant) {
                    // Restaurant owners go to store dashboard
                    Navigator.of(context).pushNamed('/store');
                  } else {
                    // Diners go to search page
                    Navigator.of(context).pushNamed('/search');
                  }
                },
                icon: Icon(isRestaurant ? Icons.store : Icons.search),
                label: Text(
                  isRestaurant
                      ? (widget.isTraditionalChinese ? '前往商店管理' : 'Go to Store Dashboard')
                      : (widget.isTraditionalChinese ? '搜尋餐廳' : 'Search Restaurants'),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gets empty state message based on user type
  String _getEmptyStateMessage(bool isRestaurant) {
    if (widget.isTraditionalChinese) {
      return isRestaurant
          ? '您還沒有任何顧客對話。請確保您的餐廳資料已設定完成，顧客就可以通過餐廳頁面與您聯繫。'
          : '您還沒有任何對話。瀏覽餐廳並使用聊天按鈕開始與餐廳老闆溝通。';
    } else {
      return isRestaurant
          ? 'You don\'t have any customer conversations yet. Make sure your restaurant profile is set up so customers can reach you through your restaurant page.'
          : 'You don\'t have any conversations yet. Browse restaurants and use the chat button to start communicating with restaurant owners.';
    }
  }

  /// Builds usage flow information card based on user type
  Widget _buildUsageInfoCard(ThemeData theme, String userType) {
    final isDiner = userType == 'Diner';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDiner
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDiner
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.secondary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDiner
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: isDiner
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isTraditionalChinese
                      ? (isDiner ? '給食客的提示' : '給餐廳老闆的提示')
                      : (isDiner ? 'For Diners' : 'For Restaurant Owners'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDiner
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.chat_bubble,
                  color: isDiner
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getUsageFlowText(isDiner),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gets usage flow text based on user type and language
  String _getUsageFlowText(bool isDiner) {
    if (widget.isTraditionalChinese) {
      return isDiner
          ? '您可以在每個餐廳頁面與餐廳老闆聊天。尋找浮動聊天按鈕，與餐廳直接溝通，詢問菜單、預訂或任何問題。'
          : '您將在您的餐廳頁面收到來自顧客的查詢。當顧客有問題或想要預訂時，他們可以使用聊天功能與您聯繫。請及時回覆以提供最佳服務！';
    } else {
      return isDiner
          ? 'You can chat with restaurant owners on each restaurant page. Look for the floating chat button to communicate directly with restaurants about menus, reservations, or any questions you may have.'
          : 'You will receive customer queries on your restaurant page. When customers have questions or want to make reservations, they can reach you through the chat feature. Please respond promptly to provide the best service!';
    }
  }
}
