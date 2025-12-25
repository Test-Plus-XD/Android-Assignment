import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/app_state.dart';
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
import 'widgets/navigation/app_root.dart';
import 'firebase_options.dart';
import 'config.dart';

/// Understanding the Architecture
///
/// This Flutter app follows a layered architecture similar to Angular:
///
/// 1. Services Layer (Business Logic):
///    - AuthService: Handles authentication (login/logout/register)
///    - UserService: Manages user profiles via REST API
///    - RestaurantService: Searches restaurants via Algolia
///    - BookingService: Manages table bookings
///    - ReviewService: Handles restaurant reviews
///    - MenuService: Manages menu items
///    - ChatService: Real-time chat with Socket.IO
///    - GeminiService: AI assistant with Google Gemini
///    - StoreService: Restaurant owner dashboard
///    - LocationService: GPS and distance calculations
///    - NotificationService: Local notification scheduling
///    - ImageService: Image upload to Firebase Storage
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

/// Main Entry Point
///
/// Initialization order matters:
/// 1. Flutter bindings (required for async work before runApp)
/// 2. Firebase (authentication and database)
/// 3. Notifications (sets up channels and timezone)
/// 4. Then start the app
void main() async {
  // Ensures Flutter is ready before async work
  WidgetsFlutterBinding.ensureInitialized();

  // Print configuration for debugging
  if (kDebugMode) {
    print('DEBUG MODE ENABLED');
    AppConfig.printConfig();
  }

  // Initialize Firebase with proper error handling
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } else {
      print('Firebase already initialized, using existing instance');
    }
  } catch (e) {
    // If initialization fails, log the error but don't crash
    print('Firebase Initialization error: $e');
    // In production, show an error screen here
  }

  // Initialize NotificationService with error handling
  // This sets up notification channels and timezone data
  // We do it here once, before the app starts, so notifications work immediately
  final notificationService = NotificationService();
  try {
    await notificationService.initialise();
    print('Notification service initialized successfully');
  } catch (e) {
    print('Notification service Initialization error: $e');
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
/// Provider Dependency Graph:
/// - AppState: Global UI preferences (independent)
/// - NotificationService: Pre-initialized (independent)
/// - LocationService: GPS functionality (independent)
/// - AuthService: Authentication (independent)
/// - UserService: Depends on AuthService (needs auth tokens)
/// - RestaurantService: Search and discovery (independent)
/// - BookingService: Depends on AuthService (needs auth tokens)
/// - ReviewService: Depends on AuthService (needs auth tokens)
/// - MenuService: Depends on AuthService (needs auth tokens)
/// - ImageService: Image upload (independent)
/// - ChatService: Depends on AuthService (needs auth tokens)
/// - GeminiService: AI assistant (independent, no auth required)
/// - StoreService: Depends on AuthService (needs auth tokens)
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
    /// 1. Independent services first (AppState, NotificationService, LocationService, AuthService, etc.)
    /// 2. Dependent services after (UserService, BookingService, etc. that need AuthService)
    ///
    /// ChangeNotifierProvider: Creates a new service instance
    /// ChangeNotifierProvider.value: Uses an existing instance (e.g., pre-initialized NotificationService)
    /// ChangeNotifierProxyProvider: Creates a service that depends on another service
    return MultiProvider(
      providers: [
        // AppState - handles global UI preferences (theme, language)
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),

        // NotificationService - already initialized in main()
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

        // ImageService - independent (no auth required for image operations)
        ChangeNotifierProvider(create: (_) => ImageService()),

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
