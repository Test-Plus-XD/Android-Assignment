import 'package:flutter/material.dart';
import 'account.dart';
import 'login.dart';
import 'restaurants.dart';

// Navigation drawer with theme and language toggles and in-drawer app icon.
class AppNavDrawer extends StatelessWidget {
  final bool isTraditionalChinese;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;

  const AppNavDrawer({
    required this.isTraditionalChinese,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String homeLabel = isTraditionalChinese ? '主頁' : 'Home';
    final String allLabel = isTraditionalChinese ? '所有餐廳' : 'All Restaurants';
    final String accountLabel = isTraditionalChinese ? '我的帳戶' : 'My Account';
    final String loginLabel = isTraditionalChinese ? '登入 / 註冊' : 'Login / Register';
    final String themeLabel = isTraditionalChinese ? '深色模式' : 'Dark theme';
    final String languageLabel = isTraditionalChinese ? 'EN|TC' : '英|繁';

    // Choose the app icon image to display in the drawer header.
    final String appIconPath = isDarkMode ? 'assets/images/App-Dark.png' : 'assets/images/App-Light.png';

    return Drawer(
      child: Column(
        children: [
          // DrawerHeader with icon image and app title; use BoxFit.contain to keep square image intact.
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.5)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App icon displayed inside a square container without cropping.
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(appIconPath, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.home), title: Text(homeLabel), onTap: () => Navigator.popUntil(context, (route) => route.isFirst)),
          ListTile(leading: const Icon(Icons.restaurant), title: Text(allLabel), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantsPage(isTraditionalChinese: isTraditionalChinese)));
          }),
          ListTile(leading: const Icon(Icons.account_circle), title: Text(accountLabel), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage()));
          }),
          ListTile(leading: const Icon(Icons.login), title: Text(loginLabel), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          }),
          const Spacer(),
          // Theme toggle persisted by root via callback.
          SwitchListTile(value: isDarkMode, title: Text(themeLabel), secondary: const Icon(Icons.brightness_6), onChanged: onThemeChanged),
          // Language toggle persisted by root via callback.
          SwitchListTile(value: isTraditionalChinese, title: Text(languageLabel), secondary: const Icon(Icons.language), onChanged: onLanguageChanged),
        ],
      ),
    );
  }
}