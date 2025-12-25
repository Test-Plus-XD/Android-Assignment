import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../pages/home_page.dart';
import '../../pages/search_page.dart';
import '../../pages/account_page.dart';
import '../../pages/chat_rooms_page.dart';
import '../../pages/bookings_page.dart';
import '../../pages/store_dashboard_page.dart';
import '../drawer.dart';

/// Main Shell
///
/// The main navigation structure of the app with dynamic bottom navigation.
/// Navigation changes based on user authentication and account type:
///
/// Not logged in (Guest):
/// - Home (left)
/// - Search (middle)
/// - Account (right)
///
/// Logged in as Diner:
/// - Home (left)
/// - Search (middle-left)
/// - Chat (middle-right)
/// - Bookings (right)
///
/// Logged in as Restaurant:
/// - Home (left)
/// - Search (middle-left)
/// - Chat (middle-right)
/// - Store Dashboard (right)
class MainShell extends StatefulWidget {
  final bool isDarkMode;
  final bool isTraditionalChinese;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;

  const MainShell({
    required this.isDarkMode,
    required this.isTraditionalChinese,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    super.key,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle Drawer Item Selection
  ///
  /// Updates the current page and closes the drawer.
  void _onSelectItem(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
    Navigator.pop(context); // Close drawer
  }

  /// Handle Bottom Navigation Tap
  ///
  /// Updates the current page with smooth animation.
  void _onNavTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Build Navigation Items Based on User Type
  ///
  /// Returns different navigation items depending on whether the user is:
  /// - Not logged in (Guest): Home, Search, Account
  /// - Diner: Home, Search, Chat, Bookings
  /// - Restaurant: Home, Search, Chat, Store Dashboard
  List<BottomBarItem> _buildNavItems(bool isLoggedIn, String? userType) {
    final isTC = widget.isTraditionalChinese;

    // Guest navigation (not logged in)
    if (!isLoggedIn) {
      return [
        BottomBarItem(
          icon: const Icon(Icons.home),
          selectedIcon: const Icon(Icons.home),
          selectedColor: Theme.of(context).colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '主頁' : 'Home'),
        ),
        BottomBarItem(
          icon: const Icon(Icons.restaurant),
          selectedIcon: const Icon(Icons.restaurant),
          selectedColor: Theme.of(context).colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '餐廳' : 'Restaurants'),
        ),
        BottomBarItem(
          icon: const Icon(Icons.account_circle),
          selectedIcon: const Icon(Icons.account_circle),
          selectedColor: Theme.of(context).colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '帳戶' : 'Account'),
        ),
      ];
    }

    // Logged in navigation (Diner or Restaurant)
    final navItems = <BottomBarItem>[
      // Home (always first)
      BottomBarItem(
        icon: const Icon(Icons.home),
        selectedIcon: const Icon(Icons.home),
        selectedColor: Theme.of(context).colorScheme.primary,
        unSelectedColor: Colors.grey,
        title: Text(isTC ? '主頁' : 'Home'),
      ),
      // Search (always second)
      BottomBarItem(
        icon: const Icon(Icons.restaurant),
        selectedIcon: const Icon(Icons.restaurant),
        selectedColor: Theme.of(context).colorScheme.primary,
        unSelectedColor: Colors.grey,
        title: Text(isTC ? '餐廳' : 'Restaurants'),
      ),
      // Chat (always third when logged in)
      BottomBarItem(
        icon: const Icon(Icons.chat),
        selectedIcon: const Icon(Icons.chat),
        selectedColor: Theme.of(context).colorScheme.primary,
        unSelectedColor: Colors.grey,
        title: Text(isTC ? '聊天' : 'Chat'),
      ),
      // Fourth item depends on user type
      if (userType == 'Restaurant')
        BottomBarItem(
          icon: const Icon(Icons.store),
          selectedIcon: const Icon(Icons.store),
          selectedColor: Theme.of(context).colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '商店' : 'Store'),
        )
      else
        BottomBarItem(
          icon: const Icon(Icons.calendar_today),
          selectedIcon: const Icon(Icons.calendar_today),
          selectedColor: Theme.of(context).colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '預訂' : 'Bookings'),
        ),
    ];

    return navItems;
  }

  /// Build Pages Based on User Type
  ///
  /// Returns different page lists depending on user authentication and type.
  List<Widget> _buildPages(bool isLoggedIn, String? userType) {
    final isTC = widget.isTraditionalChinese;

    // Guest pages (not logged in)
    if (!isLoggedIn) {
      return [
        FrontPage(
          isTraditionalChinese: isTC,
          onNavigate: (index) => _onNavTapped(index),
        ),
        SearchPage(isTraditionalChinese: isTC),
        AccountPage(
          isDarkMode: widget.isDarkMode,
          isTraditionalChinese: isTC,
          onThemeChanged: () => widget.onThemeChanged(!widget.isDarkMode),
          onLanguageChanged: () => widget.onLanguageChanged(!isTC),
          isLoggedIn: false,
          onLoginStateChanged: (_) {},
        ),
      ];
    }

    // Logged in pages
    final authService = context.read<AuthService>();
    void onLoginStateChanged(loggedIn) {
      if (!loggedIn) authService.logout();
    }

    return [
      // Home
      FrontPage(
        isTraditionalChinese: isTC,
        onNavigate: (index) => _onNavTapped(index),
      ),
      // Search
      SearchPage(isTraditionalChinese: isTC),
      // Chat
      ChatRoomsPage(isTraditionalChinese: isTC),
      // Bookings (Diner) or Store Dashboard (Restaurant)
      if (userType == 'Restaurant')
        StoreDashboardPage(isTraditionalChinese: isTC)
      else
        BookingsPage(isTraditionalChinese: isTC),
    ];
  }

  /// Build Page Titles Based on User Type
  ///
  /// Returns appropriate titles for the app bar.
  List<String> _buildPageTitles(bool isLoggedIn, String? userType) {
    final isTC = widget.isTraditionalChinese;

    // Guest titles
    if (!isLoggedIn) {
      return isTC
          ? ['主頁', '餐廳列表', '我的帳戶']
          : ['Home', 'Restaurants', 'My Account'];
    }

    // Logged in titles
    if (userType == 'Restaurant') {
      return isTC
          ? ['主頁', '餐廳列表', '聊天室', '商店管理']
          : ['Home', 'Restaurants', 'Chat', 'Store'];
    } else {
      return isTC
          ? ['主頁', '餐廳列表', '聊天室', '我的預訂']
          : ['Home', 'Restaurants', 'Chat', 'Bookings'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, UserService>(
      builder: (context, authService, userService, _) {
        final isLoggedIn = authService.isLoggedIn;
        final userType = userService.currentProfile?.type;

        final pages = _buildPages(isLoggedIn, userType);
        final pageTitles = _buildPageTitles(isLoggedIn, userType);
        final navItems = _buildNavItems(isLoggedIn, userType);

        // Ensure current index is within bounds
        if (_currentIndex >= pages.length) {
          _currentIndex = 0;
        }

        void onLoginStateChanged(loggedIn) {
          if (!loggedIn) {
            authService.logout();
            // Reset to first page when logging out
            setState(() => _currentIndex = 0);
            _pageController.jumpToPage(0);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(pageTitles[_currentIndex]),
          ),
          drawer: AppNavDrawer(
            isTraditionalChinese: widget.isTraditionalChinese,
            isDarkMode: widget.isDarkMode,
            onThemeChanged: widget.onThemeChanged,
            onLanguageChanged: widget.onLanguageChanged,
            onSelectItem: _onSelectItem,
            isLoggedIn: isLoggedIn,
            onLoginStateChanged: onLoginStateChanged,
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: pages,
          ),
          bottomNavigationBar: StylishBottomBar(
            option: AnimatedBarOptions(
              iconSize: 28,
              barAnimation: BarAnimation.fade,
              iconStyle: IconStyle.animated,
              opacity: 0.3,
            ),
            items: navItems,
            hasNotch: true,
            fabLocation: StylishBarFabLocation.center,
            currentIndex: _currentIndex,
            onTap: _onNavTapped,
            backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          ),
        );
      },
    );
  }
}
