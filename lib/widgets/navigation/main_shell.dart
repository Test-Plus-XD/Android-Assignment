import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../pages/home_page.dart';
import '../../pages/search_page.dart';
import '../../pages/account_page.dart';
import '../../pages/chat_page.dart';
import '../../pages/bookings_page.dart';
import '../../pages/store_page.dart';
import '../../pages/gemini_page.dart';
import '../drawer.dart';
import '../account/account_type_selector.dart';

/// Main Shell
///
/// The main navigation structure of the app with dynamic bottom navigation.
/// Navigation order: Chat - Search - Home - Account - Bookings/Store
///
/// Navigation changes based on user authentication and account type:
///
/// Not logged in (Guest):
/// - Search (middle-left)
/// - Home (centre, emphasised with FAB in notch)
/// - Account (middle-right)
///
/// Logged in as Diner:
/// - Chat (far left)
/// - Search (left)
/// - Home (centre, emphasised with FAB in notch)
/// - Account (right)
/// - Bookings (far right)
///
/// Logged in as Restaurant:
/// - Chat (far left)
/// - Search (left)
/// - Home (centre, emphasised with FAB in notch)
/// - Account (right)
/// - Store Dashboard (far right)
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

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Cache pages to avoid rebuilding on every frame
  List<Widget>? _cachedPages;
  String? _lastUserType;
  bool? _lastLoginState;
  bool? _lastLanguage; // Track language changes
  bool _initialIndexSet = false; // Track to set the initial index

  // Gemini FAB animation controller
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _fabSlideAnimation;
  bool _showGeminiFab = true;

  // Track if we're showing the account type selector for new users
  bool _showingAccountTypeSelector = false;

  @override
  void initState() {
    super.initState();

    // Initialize FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(_fabAnimation);
    
    _fabAnimationController.forward();

    // Auto-hide FAB after 3 seconds of no interaction
    _startFabAutoHideTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _startFabAutoHideTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showGeminiFab) {
        setState(() {
          _showGeminiFab = false;
          _fabAnimationController.reverse();
        });
      }
    });
  }

  void _showFab() {
    if (!_showGeminiFab) {
      setState(() {
        _showGeminiFab = true;
        _fabAnimationController.forward();
      });
    }
    _startFabAutoHideTimer();
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
  /// For guests, maps navigation indices to correct page indices.
  void _onNavTapped(int index) {
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.isLoggedIn;
    
    int pageIndex = index;
    
    // For guests, map navigation indices to page indices
    // Nav items: [Search(0), Account(1)] -> Pages: [Search(0), Home(1), Account(2)]
    if (!isLoggedIn) {
      if (index == 1) {
        pageIndex = 2; // Account nav item (1) -> Account page (2)
      }
      // index 0 (Search) stays as 0
    }
    
    setState(() => _currentIndex = pageIndex);
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _showFab(); // Show FAB on interaction
  }

  /// Map page index back to navigation index for display
  ///
  /// For guests: Pages [Search(0), Home(1), Account(2)] -> Nav [Search(0), Account(1)]
  int _getNavIndexFromPageIndex(int pageIndex, bool isLoggedIn) {
    if (!isLoggedIn) {
      if (pageIndex == 0) return 0; // Search page -> Search nav
      if (pageIndex == 2) return 1; // Account page -> Account nav
      return 0; // Default to Search for Home page (not in nav)
    }
    return pageIndex; // For logged in users, indices match
  }

  /// Build Navigation Items Based on User Type
  ///
  /// Order: Chat - Search - Home - Account - Bookings/Store
  /// Chat and Bookings/Store are only shown when logged in.
  List<BottomBarItem> _buildNavItems(bool isLoggedIn, String? userType) {
    final isTC = widget.isTraditionalChinese;
    final theme = Theme.of(context);

    // Guest navigation (not logged in): Search - Account (no Home since FAB handles it)
    if (!isLoggedIn) {
      return [
        BottomBarItem(
          icon: const Icon(Icons.restaurant_outlined),
          selectedIcon: const Icon(Icons.restaurant),
          selectedColor: theme.colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '餐廳' : 'Search'),
        ),
        BottomBarItem(
          icon: const Icon(Icons.account_circle_outlined),
          selectedIcon: const Icon(Icons.account_circle),
          selectedColor: theme.colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '帳戶' : 'Account'),
        ),
      ];
    }

    // Logged in navigation: Chat - Search - Home - Account - Bookings/Store
    return [
      // Chat (far left)
      BottomBarItem(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        selectedColor: theme.colorScheme.primary,
        unSelectedColor: Colors.grey,
        title: Text(isTC ? '聊天' : 'Chat'),
      ),
      // Search (left)
      BottomBarItem(
        icon: const Icon(Icons.restaurant_outlined),
        selectedIcon: const Icon(Icons.restaurant),
        selectedColor: theme.colorScheme.primary,
        unSelectedColor: Colors.grey,
        title: Text(isTC ? '餐廳' : 'Search'),
      ),
      // Home (centre, emphasised)
      BottomBarItem(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        selectedColor: theme.colorScheme.primary,
        unSelectedColor: Colors.grey,
        title: Text(isTC ? '主頁' : 'Home'),
      ),
      // Account (right)
      BottomBarItem(
        icon: const Icon(Icons.account_circle_outlined),
        selectedIcon: const Icon(Icons.account_circle),
        selectedColor: theme.colorScheme.primary,
        unSelectedColor: Colors.grey,
        title: Text(isTC ? '帳戶' : 'Account'),
      ),
      // Bookings/Store (far right, based on user type)
      if (userType == 'Restaurant')
        BottomBarItem(
          icon: const Icon(Icons.store_outlined),
          selectedIcon: const Icon(Icons.store),
          selectedColor: theme.colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '商店' : 'Store'),
        )
      else
        BottomBarItem(
          icon: const Icon(Icons.calendar_today_outlined),
          selectedIcon: const Icon(Icons.calendar_today),
          selectedColor: theme.colorScheme.primary,
          unSelectedColor: Colors.grey,
          title: Text(isTC ? '預訂' : 'Bookings'),
        ),
    ];
  }

  /// Build Pages Based on User Type
  ///
  /// Order matches navigation: Chat - Search - Home - Account - Bookings/Store
  List<Widget> _buildPages(bool isLoggedIn, String? userType) {
    final isTC = widget.isTraditionalChinese;

    // Guest pages (not logged in): Search - Home - Account (Home not in nav but accessible via FAB)
    if (!isLoggedIn) {
      return [
        SearchPage(isTraditionalChinese: isTC),
        FrontPage(
          isTraditionalChinese: isTC,
          onNavigate: (index) => _onNavTapped(index),
        ),
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

    // Logged in pages: Chat - Search - Home - Account - Bookings/Store
    final authService = context.read<AuthService>();
    void onLoginStateChanged(loggedIn) {
      if (!loggedIn) authService.logout();
    }

    return [
      // Chat
      ChatPage(
        isTraditionalChinese: isTC,
        onNavigate: (index) => _onNavTapped(index),
      ),
      // Search
      SearchPage(isTraditionalChinese: isTC),
      // Home
      FrontPage(
        isTraditionalChinese: isTC,
        onNavigate: (index) => _onNavTapped(index),
      ),
      // Account
      AccountPage(
        isDarkMode: widget.isDarkMode,
        isTraditionalChinese: isTC,
        onThemeChanged: () => widget.onThemeChanged(!widget.isDarkMode),
        onLanguageChanged: () => widget.onLanguageChanged(!isTC),
        isLoggedIn: true,
        onLoginStateChanged: onLoginStateChanged,
      ),
      // Bookings (Diner) or Store Dashboard (Restaurant)
      if (userType == 'Restaurant')
        StorePage(isTraditionalChinese: isTC)
      else
        BookingsPage(isTraditionalChinese: isTC),
    ];
  }

  /// Build Page Titles Based on User Type
  ///
  /// Order: Chat - Search - Home - Account - Bookings/Store
  List<String> _buildPageTitles(bool isLoggedIn, String? userType) {
    final isTC = widget.isTraditionalChinese;

    // Guest titles: Search - Home - Account (Home not in nav but accessible via FAB)
    if (!isLoggedIn) {
      return isTC
          ? ['餐廳列表', '主頁', '我的帳戶']
          : ['Restaurants', 'Home', 'My Account'];
    }

    // Logged in titles: Chat - Search - Home - Account - Bookings/Store
    if (userType == 'Restaurant') {
      return isTC
          ? ['聊天', '餐廳列表', '主頁', '我的帳戶', '商店管理']
          : ['Chat', 'Restaurants', 'Home', 'My Account', 'Store'];
    } else {
      return isTC
          ? ['聊天', '餐廳列表', '主頁', '我的帳戶', '我的預訂']
          : ['Chat', 'Restaurants', 'Home', 'My Account', 'Bookings'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, UserService>(
      builder: (context, authService, userService, _) {
        final isLoggedIn = authService.isLoggedIn;
        final userType = userService.currentProfile?.type;

        // Show account type selector for new users who haven't selected their type
        if (isLoggedIn &&
            userService.needsAccountTypeSelection &&
            !_showingAccountTypeSelector &&
            !userService.isLoading) {
          // Use post frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_showingAccountTypeSelector) {
              setState(() => _showingAccountTypeSelector = true);
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => AccountTypeSelectorDialog(
                    isTraditionalChinese: widget.isTraditionalChinese,
                    onComplete: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _showingAccountTypeSelector = false;
                        _currentIndex = 3; // Redirect to Account page (index 3)
                        // Reset page cache to rebuild with new user type
                        _cachedPages = null;
                      });
                      
                      // Jump to the account page after the pop and state update
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(3);
                        }
                      });
                    },
                  ),
                ),
              );
            }
          });
        }

        // Only rebuild pages if login state, user type, or language changed
        if (_cachedPages == null ||
            _lastLoginState != isLoggedIn ||
            _lastUserType != userType ||
            _lastLanguage != widget.isTraditionalChinese) {
          _cachedPages = _buildPages(isLoggedIn, userType);
          _lastLoginState = isLoggedIn;
          _lastUserType = userType;
          _lastLanguage = widget.isTraditionalChinese;

          // Set initial index on first load or when login state changes
          if (!_initialIndexSet || _lastLoginState != isLoggedIn) {
            _currentIndex = isLoggedIn ? 2 : 1; // Home page for both, different indices
            _initialIndexSet = true;
            
            // Jump to Home page without animation on initial load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(_currentIndex);
              }
            });
          }
          
          // Reset index if pages changed and current index is out of bounds
          else if (_currentIndex >= _cachedPages!.length) {
            _currentIndex = isLoggedIn ? 2 : 1;
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_currentIndex);
            }
          }
        }

        final pages = _cachedPages!;
        final pageTitles = _buildPageTitles(isLoggedIn, userType);
        final navItems = _buildNavItems(isLoggedIn, userType);

        void onLoginStateChanged(loggedIn) {
          if (!loggedIn) {
            authService.logout();
            // Reset to home page when logging out
            setState(() => _currentIndex = isLoggedIn ? 2 : 1);
            _pageController.jumpToPage(_currentIndex);
          }
        }

        return GestureDetector(
          onTap: _showFab, // Show FAB on screen tap
          onPanDown: (_) => _showFab(), // Show FAB on any touch interaction
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            extendBody: true, // Required to make the notch look clean
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
            body: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    _showFab(); // Show FAB on page change
                  },
                  children: pages,
                ),
                // Gemini AI Floating Button (only for logged-in users)
                if (isLoggedIn)
                  Positioned(
                    left: 16,
                    bottom: 100, // Position above the bottom bar
                    child: SlideTransition(
                      position: _fabSlideAnimation,
                      child: FadeTransition(
                        opacity: _fabAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12), // Square with rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GeminiChatRoomPage(
                                      isTraditionalChinese: widget.isTraditionalChinese,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: StylishBottomBar(
              option: AnimatedBarOptions(
                iconSize: 28,
                barAnimation: BarAnimation.transform3D, // Changed to transform3D
                iconStyle: IconStyle.animated,           // Kept animated
                opacity: 0.3,
              ),
              items: navItems,
              hasNotch: true, // Enabled notch for centre emphasis
              fabLocation: StylishBarFabLocation.center, // Aligns items around the centre
              currentIndex: _getNavIndexFromPageIndex(_currentIndex, isLoggedIn),
              onTap: _onNavTapped,
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            ),
            // The Home FAB in the centre notch
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Navigate directly to Home page index (2 for logged in, 1 for guest)
                final homePageIndex = isLoggedIn ? 2 : 1;
                setState(() => _currentIndex = homePageIndex);
                _pageController.animateToPage(
                  homePageIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _showFab(); // Show FAB on interaction
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.home,
                color: Colors.white,
                size: 30,
              ),
            ),
            // Positions the Home button into the notch
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          ),
        );
      },
    );
  }
}