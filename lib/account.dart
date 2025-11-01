import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';

class AccountPage extends StatefulWidget {
  final bool isLoggedIn;
  final ValueChanged<bool> onLoginStateChanged;
  final bool isDarkMode;
  final bool isTraditionalChinese;
  final VoidCallback onThemeChanged;
  final VoidCallback onLanguageChanged;

  const AccountPage({
    required this.isLoggedIn,
    required this.onLoginStateChanged,
    required this.isDarkMode,
    required this.isTraditionalChinese,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    super.key,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<User> _loadUser() async {
    final String data = await rootBundle.loadString('assets/sample_users.json');
    final List<dynamic> users = json.decode(data);
    return User.fromJson(users.first as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final String welcomeMessage = widget.isTraditionalChinese ? '歡迎, ' : 'Welcome, ';
    final String emailLabel = widget.isTraditionalChinese ? '電郵: ' : 'Email: ';
    final String phoneLabel = widget.isTraditionalChinese ? '電話: ' : 'Phone: ';
    final String logoutLabel = widget.isTraditionalChinese ? '登出' : 'Logout';
    final String loginPrompt = widget.isTraditionalChinese ? '請先登入' : 'Please log in';
    final String errorLabel = widget.isTraditionalChinese ? '載入用戶數據時出錯' : 'Error loading user data';

    // If not logged in, show a simple prompt.
    if (!widget.isLoggedIn) {
      return Center(child: Text(loginPrompt));
    }

    // If logged in, show user details and settings.
    return FutureBuilder<User>(
      future: _loadUser(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(errorLabel));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
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
                    // Edit Icon
                    IconButton(
                        onPressed: () {
                          // TODO: Handle edit profile action
                        },
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Profile',
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
        }
        // Fallback for any other state.
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
