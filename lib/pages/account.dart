import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login.dart';

/// Account Page with Enhanced Aesthetics
///
/// This page displays user profile information fetched from the Vercel API.
/// The design follows modern UI principles with card-based layouts and
/// clear visual hierarchy.
///
/// Vercel API integration:
/// - Profile data is fetched via getUserProfile() endpoint
/// - Updates are sent via updateUserProfile() endpoint
/// - Login metadata is tracked for analytics
///
/// Design improvements:
/// - Professional card-based layout
/// - Smooth loading states with skeletons
/// - Clear information hierarchy
/// - Action buttons with icons
/// - Responsive to different screen sizes
class AccountPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isTraditionalChinese;
  final VoidCallback onThemeChanged;
  final VoidCallback onLanguageChanged;
  final bool isLoggedIn;
  final ValueChanged<bool> onLoginStateChanged;

  const AccountPage({
    required this.isDarkMode,
    required this.isTraditionalChinese,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.isLoggedIn,
    required this.onLoginStateChanged,
    super.key,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  /// Track if profile load has been attempted
  /// Prevents repeated loading and helps distinguish states
  bool _hasAttemptedLoad = false;

  @override
  void initState() {
    super.initState();

    /// Schedule profile load after first frame
    /// This ensures we don't call setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileIfNeeded();
    });
  }

  /// Loads user profile if not already loaded
  ///
  /// This method uses the Vercel API via UserService to fetch
  /// the complete profile data. The service handles caching
  /// and state management automatically.
  Future<void> _loadProfileIfNeeded() async {
    if (!mounted) return;
    if (!widget.isLoggedIn) return;
    if (_hasAttemptedLoad) return;

    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();

    if (authService.uid != null) {
      setState(() {
        _hasAttemptedLoad = true;
      });

      /// Load profile via Vercel API
      /// UserService will notify listeners when complete
      userService.getUserProfile(authService.uid!);
    }
  }

  /// Builds a skeleton loading card
  ///
  /// Provides visual feedback whilst data is being fetched
  Widget _buildLoadingSkeleton() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            /// Avatar skeleton
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),

            /// Name skeleton
            Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            /// Email skeleton
            Container(
              height: 16,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds profile information card
  ///
  /// Displays user data in a visually appealing card layout
  Widget _buildProfileCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Builds action button
  ///
  /// Consistent styled button for actions like logout and edit
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isDestructive
              ? Colors.red.shade700
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Localised strings
    final welcomeMessage = widget.isTraditionalChinese ? '歡迎' : 'Welcome';
    final emailLabel = widget.isTraditionalChinese ? '電郵' : 'Email';
    final phoneLabel = widget.isTraditionalChinese ? '電話' : 'Phone';
    final logoutLabel = widget.isTraditionalChinese ? '登出' : 'Logout';
    final editProfileLabel = widget.isTraditionalChinese ? '編輯個人資料' : 'Edit Profile';
    final loginPrompt = widget.isTraditionalChinese ? '請先登入' : 'Please log in';
    final loginButtonLabel = widget.isTraditionalChinese ? '登入' : 'Login';
    final loadingMessage = widget.isTraditionalChinese ? '載入中...' : 'Loading...';
    final noProfileMessage = widget.isTraditionalChinese ? '沒有找到用戶資料' : 'No profile found';
    final retryLabel = widget.isTraditionalChinese ? '重試' : 'Retry';
    final reloadLabel = widget.isTraditionalChinese ? '重新載入' : 'Reload';

    /// Early return if not logged in
    if (!widget.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loginPrompt,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoginPage(
                            isTraditionalChinese: widget.isTraditionalChinese,
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                            onLanguageChanged: widget.onLanguageChanged,
                            onSkip: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: Text(loginButtonLabel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    /// Use Consumer to reactively rebuild when UserService changes
    return Consumer<UserService>(
      builder: (context, userService, _) {
        /// Show loading skeleton whilst fetching profile
        if (userService.isLoading && !_hasAttemptedLoad) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildLoadingSkeleton(),
              ],
            ),
          );
        }

        /// Show error if profile loading failed
        if (userService.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        userService.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasAttemptedLoad = false;
                          });
                          _loadProfileIfNeeded();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(retryLabel),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        /// Get the current profile from the service
        final user = userService.currentProfile;
        /// Show message if no profile exists
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        noProfileMessage,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasAttemptedLoad = false;
                          });
                          _loadProfileIfNeeded();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(reloadLabel),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        /// Display the user profile
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              /// Profile header card
              Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      /// Profile photo
                      if (user.photoURL != null && user.photoURL!.isNotEmpty)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(user.photoURL!),
                          backgroundColor: Colors.transparent,
                        )
                      else
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          child: Icon(
                            Icons.account_circle,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),

                      const SizedBox(height: 20),

                      /// Welcome message with display name
                      Text(
                        '$welcomeMessage, ${user.displayName ?? 'User'}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      /// Email verification badge
                      if (!user.emailVerified) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.isTraditionalChinese
                                    ? '電郵未驗證'
                                    : 'Email not verified',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              /// Profile information cards
              if (user.email != null && user.email!.isNotEmpty)
                _buildProfileCard(emailLabel, user.email!, Icons.email),
              if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                _buildProfileCard(phoneLabel, user.phoneNumber!, Icons.phone),
              const SizedBox(height: 24),

              /// Action buttons
              _buildActionButton(
                label: editProfileLabel,
                icon: Icons.edit,
                onPressed: () {
                  /// TODO: Navigate to edit profile page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.isTraditionalChinese
                            ? '編輯功能即將推出'
                            : 'Edit feature coming soon',
                      ),
                    ),
                  );
                },
              ),

              _buildActionButton(
                label: logoutLabel,
                icon: Icons.logout,
                onPressed: () {
                  /// Show confirmation dialogue
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        widget.isTraditionalChinese ? '確認登出' : 'Confirm Logout',
                      ),
                      content: Text(
                        widget.isTraditionalChinese
                            ? '您確定要登出嗎？'
                            : 'Are you sure you want to logout?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            widget.isTraditionalChinese ? '取消' : 'Cancel',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onLoginStateChanged(false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          child: Text(
                            widget.isTraditionalChinese ? '登出' : 'Logout',
                          ),
                        ),
                      ],
                    ),
                  );
                },
                isDestructive: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}