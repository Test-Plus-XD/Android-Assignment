import 'package:flutter/material.dart';
import 'login.dart';

class AccountPage extends StatelessWidget {
  final bool isLoggedIn;
  final ValueChanged<bool> onLoginStateChanged;
  final bool isTraditionalChinese;
  final bool isDarkMode;
  final VoidCallback onThemeChanged;
  final VoidCallback onLanguageChanged;


  const AccountPage({
    super.key,
    required this.isLoggedIn,
    required this.onLoginStateChanged,
    required this.isTraditionalChinese,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String accountDetailsLabel = isTraditionalChinese ? '帳戶詳細資料' : 'Account Details';
    final String logOutLabel = isTraditionalChinese ? '登出' : 'Log Out';

    if (isLoggedIn) {
      // ... (your existing code for when the user is logged in)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(accountDetailsLabel),
            ElevatedButton(
              onPressed: () {
                onLoginStateChanged(false);
              },
              child: Text(logOutLabel),
            ),
          ],
        ),
      );
    } else {
      // 3. Now the variables are defined and can be passed down to LoginPage
      return LoginPage(
        onLoginStateChanged: onLoginStateChanged,
        isTraditionalChinese: isTraditionalChinese,
        isDarkMode: isDarkMode,
        onThemeChanged: onThemeChanged,
        onLanguageChanged: onLanguageChanged,
      );
    }
  }
}