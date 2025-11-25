import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login.dart';

/// Account Page with Proper Async Handling
///
/// This page displays user profile information fetched from your API.
/// The key fix here is using a more robust async pattern that doesn't
/// trigger setState() during the build phase.
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
  /// Track if we've attempted to load the profile
  ///
  /// This prevents repeated loading attempts and helps us
  /// distinguish between "not loaded yet" and "no profile exists"
  bool _hasAttemptedLoad = false;

  @override
  void initState() {
    super.initState();
    // Schedule the profile load to happen after the first frame is built
    // This ensures we're not calling setState() during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileIfNeeded();
    });
  }

  /// Load user profile if needed
  ///
  /// This method checks if we need to load the profile and does so
  /// in a way that doesn't interfere with the widget build cycle.
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

      // Load the profile without waiting for the result
      // The UserService will notify listeners when it's done
      userService.getUserProfile(authService.uid!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Translations
    final String welcomeMessage = widget.isTraditionalChinese ? '歡迎, ' : 'Welcome, ';
    final String emailLabel = widget.isTraditionalChinese ? '電郵: ' : 'Email: ';
    final String phoneLabel = widget.isTraditionalChinese ? '電話: ' : 'Phone: ';
    final String logoutLabel = widget.isTraditionalChinese ? '登出' : 'Logout';
    final String loginPrompt = widget.isTraditionalChinese ? '請先登入' : 'Please log in';
    final String loginButtonLabel = widget.isTraditionalChinese ? '登入' : 'Login';
    final String loadingMessage = widget.isTraditionalChinese ? '載入中...' : 'Loading...';
    final String noProfileMessage = widget.isTraditionalChinese ? '沒有找到用戶資料' : 'No profile found';

    // Early return if not logged in, showing a login prompt.
    if (!widget.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 64),
            const SizedBox(height: 16),
            Text(
              loginPrompt,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => LoginPage(
                    isTraditionalChinese: widget.isTraditionalChinese,
                    isDarkMode: widget.isDarkMode,
                    onThemeChanged: widget.onThemeChanged,
                    onLanguageChanged: widget.onLanguageChanged,
                    onSkip: () => Navigator.of(context).pop(),
                  ),
                ));
              },
              child: Text(loginButtonLabel),
            ),
          ],
        ),
      );
    }

    // Use Consumer to reactively rebuild when UserService changes
    // This is safer than FutureBuilder because it responds to the
    // service's state rather than managing its own async state
    return Consumer<UserService>(
      builder: (context, userService, _) {
        // Show loading indicator whilst fetching profile
        if (userService.isLoading && !_hasAttemptedLoad) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(loadingMessage),
              ],
            ),
          );
        }

        // Show error if profile loading failed
        if (userService.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  userService.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasAttemptedLoad = false;
                    });
                    _loadProfileIfNeeded();
                  },
                  child: Text(widget.isTraditionalChinese ? '重試' : 'Retry'),
                ),
              ],
            ),
          );
        }

        // Get the current profile from the service
        final user = userService.currentProfile;

        // Show message if no profile exists
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 64),
                const SizedBox(height: 16),
                Text(
                  noProfileMessage,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasAttemptedLoad = false;
                    });
                    _loadProfileIfNeeded();
                  },
                  child: Text(widget.isTraditionalChinese ? '重新載入' : 'Reload'),
                ),
              ],
            ),
          );
        }

        // Display the user profile
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile photo
                  if (user.photoURL != null && user.photoURL!.isNotEmpty)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(user.photoURL!),
                      backgroundColor: Colors.transparent,
                    )
                  else
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.account_circle, size: 50),
                    ),

                  const SizedBox(height: 20),

                  // Welcome message with display name
                  Text(
                    '$welcomeMessage${user.displayName ?? 'User'}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 10),

                  // Email
                  if (user.email != null && user.email!.isNotEmpty)
                    Text('$emailLabel${user.email!}'),

                  // Phone number
                  if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                    Text('$phoneLabel${user.phoneNumber!}'),

                  const SizedBox(height: 24),

                  // Edit profile button
                  IconButton(
                    onPressed: () {
                      // TODO: Navigate to edit profile page
                    },
                    icon: const Icon(Icons.edit),
                    tooltip: widget.isTraditionalChinese ? '編輯個人資料' : 'Edit Profile',
                  ),

                  const SizedBox(height: 8),

                  // Logout button
                  ElevatedButton(
                    onPressed: () => widget.onLoginStateChanged(false),
                    child: Text(logoutLabel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
