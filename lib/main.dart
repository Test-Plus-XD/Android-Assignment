import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/restaurant_service.dart';
import 'services/user_service.dart';
import 'services/review_service.dart';
import 'services/menu_service.dart';
import 'services/image_service.dart';
import 'services/chat_service.dart';
import 'services/gemini_service.dart';
import 'services/store_service.dart';
import 'pages/home.dart';
import 'pages/search.dart';
import 'pages/account.dart';
import 'pages/login.dart';
import 'widgets/drawer.dart';
import 'firebase_options.dart';
import 'config.dart';

/// Understanding the Architecture
/// 
/// This Flutter app follows a layered architecture similar to your Angular app:
/// 
/// 1. Services Layer (Business Logic):
///    - AuthService: Handles authentication (login/logout/register)
///    - UserService: Manages user profiles via your Node.js API
///    - RestaurantService: Searches restaurants via Algolia
/// 
/// 2. State Management (Provider):
///    - Services extend ChangeNotifier (like RxJS BehaviorSubjects in Angular)
///    - Widgets "listen" to services and rebuild when data changes
///    - This is Flutter's equivalent to Angular's reactive programming
/// 
/// 3. UI Layer (Widgets):
///    - Pages display data from services
///    - User interactions trigger service methods
///    - Services notify widgets of state changes
/// 
/// Why Provider?
/// - It's the official recommended state management solution
/// - Simple to understand and use
/// - Automatically handles widget rebuilding
/// - Similar mental model to Angular's dependency injection

// Keys for persisted preferences
const String prefKeyIsDark = 'pourrice_is_dark';
const String prefKeyIsTc = 'pourrice_is_tc';

/// Application State
/// 
/// Manages global UI preferences like theme and language.
class AppState with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isTraditionalChinese = false;
  bool _isLoaded = false;

  bool get isDarkMode => _isDarkMode;
  bool get isTraditionalChinese => _isTraditionalChinese;
  bool get isLoaded => _isLoaded;

  AppState() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(prefKeyIsDark) ?? false;
    _isTraditionalChinese = prefs.getBool(prefKeyIsTc) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsDark, value);
    _isDarkMode = value;
    notifyListeners();
  }

  Future<void> toggleLanguage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsTc, value);
    _isTraditionalChinese = value;
    notifyListeners();
  }
}

/// Main Entry Point
/// Initialisation order matters:
/// 1. Flutter bindings (required for async work before runApp)
/// 2. Firebase
/// 3. Notifications (sets up channels and timezone) [This part is not implemented]
/// 4. Then start the app
void main() async {
  // Ensures Flutter is ready before async work
  WidgetsFlutterBinding.ensureInitialized();
  // Print configuration for debugging
  if (kDebugMode) {
    print('DEBUG MODE ENABLED');
    AppConfig.printConfig();
  }
  // Initialise Firebase with proper error handling
  try {
    // Check if Firebase is already initialised
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialised successfully');
    } else {
      print('Firebase already initialised, using existing instance');
    }
  } catch (e) {
    // If initialisation fails, log the error but don't crash
    print('Firebase Initialisation error: $e');
    // In production, show an error screen here
  }
  
  // Initialise NotificationService with error handling
  // This sets up notification channels and timezone data
  // We do it here once, before the app starts, so notifications work immediately
  final notificationService = NotificationService();
  try {
    await notificationService.initialise();
    print('Notification service initialised successfully');
  } catch (e) {
    print('Notification service Initialisation error: $e');
    // App can still run without notifications, so we continue
  }
  
  // Start the app, passing notification service instance
  runApp(PourRiceApp(notificationService: notificationService));
}

/// Root App Widget
/// 
/// This widget sets up the Provider architecture and initializes services.
/// Think of it as the "root module" in Angular.
/// 
/// Now includes NotificationService and LocationService for native Android features.
class PourRiceApp extends StatelessWidget {
  final NotificationService notificationService;
  
  const PourRiceApp({
    required this.notificationService,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    /// MultiProvider Setup
    /// 
    /// MultiProvider is like Angular's dependency injection container.
    /// It creates service instances and makes them available to all child widgets.
    /// 
    /// Order matters here:
    /// 1. NotificationService comes first (pre-initialised, passed from main)
    /// 2. LocationService is independent (no dependencies)
    /// 3. AuthService is independent (no dependencies)
    /// 4. UserService depends on AuthService (needs auth tokens)
    /// 5. RestaurantService is independent
    /// 6. BookingService depends on AuthService (needs auth tokens)
    /// 
    /// This is the same pattern as your Angular services with inject()
    return MultiProvider(
      providers: [
        // AppState - handles global UI preferences
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),

        // NotificationService - already initialised in main()
        ChangeNotifierProvider.value(
          value: notificationService,
        ),
        
        // LocationService - handles GPS and distance calculations
        ChangeNotifierProvider(
          create: (_) => LocationService(),
        ),
        
        // AuthService - handles authentication
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
        
        // UserService - needs AuthService for tokens
        ChangeNotifierProxyProvider<AuthService, UserService>(
          create: (context) => UserService(
            context.read<AuthService>(),
          ),
          update: (context, authService, previous) =>
              previous ?? UserService(authService),
        ),
        
        // RestaurantService - independent
        ChangeNotifierProvider(
          create: (_) => RestaurantService(),
        ),
        
        // BookingService - needs AuthService for tokens
        ChangeNotifierProxyProvider<AuthService, BookingService>(
          create: (context) => BookingService(
            context.read<AuthService>(),
          ),
          update: (context, authService, previous) =>
              previous ?? BookingService(authService),
        ),

        // ReviewService - needs AuthService for tokens
        ChangeNotifierProxyProvider<AuthService, ReviewService>(
          create: (context) => ReviewService(
            context.read<AuthService>(),
          ),
          update: (context, authService, previous) =>
              previous ?? ReviewService(authService),
        ),

        // MenuService - needs AuthService for tokens
        ChangeNotifierProxyProvider<AuthService, MenuService>(
          create: (context) => MenuService(
            context.read<AuthService>(),
          ),
          update: (context, authService, previous) =>
              previous ?? MenuService(authService),
        ),

        // ImageService - needs AuthService for tokens (image upload)
        ChangeNotifierProxyProvider<AuthService, ImageService>(
          create: (context) => ImageService(
            context.read<AuthService>(),
          ),
          update: (context, authService, previous) =>
              previous ?? ImageService(authService),
        ),

        // ChatService - needs AuthService for tokens (real-time chat)
        ChangeNotifierProxyProvider<AuthService, ChatService>(
          create: (context) => ChatService(
            context.read<AuthService>(),
          ),
          update: (context, authService, previous) =>
              previous ?? ChatService(authService),
        ),

        // GeminiService - AI assistant (no auth required)
        ChangeNotifierProvider(
          create: (_) => GeminiService(),
        ),

        // StoreService - restaurant owner management (needs AuthService)
        ChangeNotifierProxyProvider<AuthService, StoreService>(
          create: (context) => StoreService(
            context.read<AuthService>(),
          ),
          update: (context, authService, previous) =>
              previous ?? StoreService(authService),
        ),
      ],
      child: const AppRoot(),
    );
  }
}

/// App Root Widget
/// 
/// This widget manages theme, language, and navigation.
/// It's similar to your Angular AppComponent.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isSkipped = false;

  void _skipLogin() {
    setState(() {
      _isSkipped = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Wait for preferences to load
    if (!appState.isLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    /// Theme Configuration
    /// 
    /// Updated with a professional vegan green aesthetic.
    /// Key color theory concepts:
    /// - Green evokes nature, health, and sustainability (perfect for vegan theme)
    /// - We use various shades of green for depth and visual interest
    /// - Light theme: Fresh, bright greens with white backgrounds
    /// - Dark theme: Deep, rich greens with dark backgrounds
    /// - All colors pass WCAG accessibility standards for contrast
    
    // Light theme green palette
    const Color lightPrimary = Color(0xFF2E7D32);      // Forest green
    const Color lightSecondary = Color(0xFF66BB6A);    // Light green
    const Color lightSurface = Color(0xFFF1F8E9);      // Very light green tint
    const Color lightBackground = Colors.white;         // Pure white for main content
    
    // Dark theme green palette
    const Color darkPrimary = Color(0xFF66BB6A);       // Light green (primary in dark)
    const Color darkSecondary = Color(0xFF81C784);     // Lighter green
    const Color darkSurface = Color(0xFF1B5E20);       // Dark forest green
    const Color darkBackground = Color(0xFF0D1F0E);    // Very dark green-black

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.light,
      ).copyWith(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightPrimary,
        elevation: 1,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: Colors.black54,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        onPrimary: Colors.black87,
        onSurface: Colors.white70,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

    /// Authentication Flow
    /// 
    /// Consumer widget listens to AuthService.
    /// When auth state changes, it rebuilds and shows appropriate screen.
    /// 
    /// Flow:
    /// 1. App starts, AuthService checks if user is logged in
    /// 2. If logged in -> show MainShell (home screen)
    /// 3. If not logged in -> show LoginPage
    /// 4. After login, AuthService notifies listeners, UI rebuilds
    return MaterialApp(
      title: 'PourRice',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Consumer listens to AuthService and rebuilds on changes
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          // Show loading while checking auth state
          if (authService.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // User is logged in -> show main app
          if (authService.isLoggedIn || _isSkipped) {
            return MainShell(
              isDarkMode: appState.isDarkMode,
              isTraditionalChinese: appState.isTraditionalChinese,
              onThemeChanged: appState.toggleTheme,
              onLanguageChanged: appState.toggleLanguage,
            );
          }
          
          // User not logged in -> show login page
          return LoginPage(
            isTraditionalChinese: appState.isTraditionalChinese,
            isDarkMode: appState.isDarkMode,
            onThemeChanged: () => appState.toggleTheme(!appState.isDarkMode),
            onLanguageChanged: () => appState.toggleLanguage(!appState.isTraditionalChinese),
            onSkip: _skipLogin,
          );
        },
      ),
    );
  }
}

/// Main Shell
/// 
/// The main navigation structure of the app.
/// Contains bottom navigation and drawer.
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
  int currentIndex = 0;

  void _onSelectItem(int index) {
    setState(() => currentIndex = index);
    Navigator.pop(context);
  }

  void _onNavTapped(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pageTitles = widget.isTraditionalChinese
        ? ['主頁', '餐廳列表', '我的帳戶']
        : ['Home', 'Restaurants', 'My Account'];

    final authService = context.read<AuthService>();
    void onLoginStateChanged(loggedIn) {
      if (!loggedIn) authService.logout();
    }

    final pages = [
      FrontPage(
        isTraditionalChinese: widget.isTraditionalChinese,
        onNavigate: (index) => setState(() => currentIndex = index),
      ),
      SearchPage(isTraditionalChinese: widget.isTraditionalChinese),
      AccountPage(
        isDarkMode: widget.isDarkMode,
        isTraditionalChinese: widget.isTraditionalChinese,
        onThemeChanged: () => widget.onThemeChanged(!widget.isDarkMode),
        onLanguageChanged: () => widget.onLanguageChanged(!widget.isTraditionalChinese),
        isLoggedIn: authService.isLoggedIn,
        onLoginStateChanged: onLoginStateChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[currentIndex]),
      ),
      drawer: AppNavDrawer(
        isTraditionalChinese: widget.isTraditionalChinese,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
        onSelectItem: _onSelectItem,
        isLoggedIn: authService.isLoggedIn,
        onLoginStateChanged: onLoginStateChanged,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onNavTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: widget.isTraditionalChinese ? '主頁' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant),
            label: widget.isTraditionalChinese ? '餐廳' : 'Restaurants',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: widget.isTraditionalChinese ? '帳戶' : 'Account',
          ),
        ],
      ),
    );
  }
}
