import 'package:flutter/material.dart';
import 'login.dart';

class AppNavDrawer extends StatelessWidget {
  final bool isDarkMode;
  final bool isTraditionalChinese;
  final bool isLoggedIn;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onLoginStateChanged;
  final ValueChanged<int> onSelectItem;

  const AppNavDrawer({
    required this.isDarkMode,
    required this.isTraditionalChinese,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.isLoggedIn,
    required this.onLoginStateChanged,
    required this.onSelectItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor),
                  child: Image.asset(
                    isDarkMode ? 'assets/images/App-Dark.png' : 'assets/images/App-Light.png',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text(isTraditionalChinese ? '主頁' : 'Home'),
                  onTap: () {
                    onSelectItem(0);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(isTraditionalChinese ? '所有餐廳' : 'All Restaurants'),
                  onTap: () {
                    onSelectItem(1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text(isTraditionalChinese ? '我的帳戶' : 'My Account'),
                  onTap: () {
                    onSelectItem(2);
                  },
                ),
                const Divider(),
                if (!isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: Text(isTraditionalChinese ? '登錄/註冊' : 'Login / Register'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(
                            onLoginStateChanged: onLoginStateChanged,
                            isTraditionalChinese: isTraditionalChinese,
                            isDarkMode: isDarkMode,
                            onThemeChanged: () => onThemeChanged(!isDarkMode),
                            onLanguageChanged: () => onLanguageChanged(!isTraditionalChinese),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: Text(isTraditionalChinese ? '深色模式' : 'Dark Mode'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: onThemeChanged,
            ),
            onTap: () => onThemeChanged(!isDarkMode),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(isTraditionalChinese ? 'Switch to English' : '切換中文'),
            trailing: Switch(
              value: isTraditionalChinese,
              onChanged: onLanguageChanged,
            ),
            onTap: () => onLanguageChanged(!isTraditionalChinese),
          ),
        ],
      ),
    );
  }
}