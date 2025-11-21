import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

// 1. Convert to StatefulWidget
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
  // 2. Create the State class
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // 3. Declare a Future to hold the profile data
  late Future<UserProfile?> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    // 4. Fetch the data only once, in initState
    // We use context.read which is like Provider.of(context, listen: false)
    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();

    // Check if logged in before making the call
    if (widget.isLoggedIn && authService.uid != null) {
      _userProfileFuture = userService.getUserProfile(authService.uid!);
    } else {
      // If not logged in, create a future that completes with null
      _userProfileFuture = Future.value(null);
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
    final String errorLabel = widget.isTraditionalChinese ? '載入用戶數據時出錯' : 'Error loading user data';

    if (!widget.isLoggedIn) {
      return Center(child: Text(loginPrompt));
    }

    // 5. Use the pre-fetched future in the FutureBuilder
    return FutureBuilder<UserProfile?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // It's good practice to log the error
          print('Error in AccountPage FutureBuilder: ${snapshot.error}');
          return Center(child: Text(errorLabel));
        }
        // Use a single check for no data or null data
        if (!snapshot.hasData || snapshot.data == null) {
           // This can happen if the profile doesn't exist yet for a new user
          return Center(child: Text(loginPrompt));
        }

        final user = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (user.photoURL != null && user.photoURL!.isNotEmpty)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(user.photoURL!),
                      backgroundColor: Colors.transparent,
                    ),
                  const SizedBox(height: 20),
                  Text('$welcomeMessage${user.displayName ?? 'User'}!', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  if (user.email != null) Text('$emailLabel${user.email!}'),
                  if (user.phoneNumber != null) Text('$phoneLabel${user.phoneNumber!}'),
                  const SizedBox(height: 24),
                  IconButton(
                    onPressed: () {
                      // TODO: Handle edit profile action
                    },
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Profile',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    // Use the callback from the widget
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
