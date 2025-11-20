import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AccountPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userService = Provider.of<UserService>(context);

    final String welcomeMessage = isTraditionalChinese ? '歡迎, ' : 'Welcome, ';
    final String emailLabel = isTraditionalChinese ? '電郵: ' : 'Email: ';
    final String phoneLabel = isTraditionalChinese ? '電話: ' : 'Phone: ';
    final String logoutLabel = isTraditionalChinese ? '登出' : 'Logout';
    final String loginPrompt = isTraditionalChinese ? '請先登入' : 'Please log in';
    final String errorLabel = isTraditionalChinese ? '載入用戶數據時出錯' : 'Error loading user data';

    if (!isLoggedIn) {
      return Center(child: Text(loginPrompt));
    }

    return FutureBuilder<UserProfile?>(
      future: userService.getUserProfile(authService.uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(errorLabel));
        }
        if (!snapshot.hasData || snapshot.data == null) {
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
                    onPressed: () => onLoginStateChanged(false),
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
