import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../utils/notification_route_parser.dart';
import 'app_navigation_service.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'notification_service.dart';
import 'user_service.dart';

// NotificationCoordinatorService owns the app-wide FCM lifecycle.
//
// It keeps token registration tied to authentication state, handles foreground
// banners, routes notification taps, and suppresses chat banners when the
// relevant chat room is already open on screen.
class NotificationCoordinatorService with ChangeNotifier {
  AuthService _authService;
  UserService _userService;
  ChatService _chatService;
  NotificationService _notificationService;
  AppNavigationService _appNavigationService;

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _notificationOpenSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  final Set<String> _recentNotificationKeys = <String>{};
  final Queue<String> _recentNotificationOrder = Queue<String>();

  bool _isInitialised = false;
  bool _isRegisteringToken = false;
  String? _lastRegisteredToken;
  String? _lastRegisteredUid;

  NotificationCoordinatorService(
    this._authService,
    this._userService,
    this._chatService,
    this._notificationService,
    this._appNavigationService,
  ) {
    _bindAuthService(_authService);
    _notificationService.setNotificationTapHandler(_handleLocalNotificationTap);
  }

  // Updates provider-backed dependencies without recreating the coordinator.
  void updateDependencies(
    AuthService authService,
    UserService userService,
    ChatService chatService,
    NotificationService notificationService,
    AppNavigationService appNavigationService,
  ) {
    final authServiceChanged = !identical(_authService, authService);

    if (authServiceChanged) {
      _unbindAuthService(_authService);
      _authService = authService;
      _bindAuthService(_authService);
    }

    _userService = userService;
    _chatService = chatService;
    _notificationService = notificationService;
    _appNavigationService = appNavigationService;
    _notificationService.setNotificationTapHandler(_handleLocalNotificationTap);

    // Only re-attempt token registration when the AuthService instance itself
    // was swapped out. For regular state changes, _handleAuthChanged already
    // reacts via the AuthService listener, so firing again here would cause
    // one FCM token round-trip per ChatService notify (every incoming socket
    // message, typing indicator, reconnect, etc.).
    if (authServiceChanged && _isInitialised && _authService.isLoggedIn) {
      unawaited(_attemptTokenRegistration(reason: 'dependency-update'));
    }
  }

  // Starts the global FCM listeners once for the app lifetime.
  Future<void> initialise() async {
    if (_isInitialised) {
      return;
    }

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) {
      unawaited(_handleForegroundMessage(message));
    });
    _notificationOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        unawaited(_handleNotificationOpen(message));
      },
    );
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen((token) {
          unawaited(
            _attemptTokenRegistration(
              reason: 'token-refresh',
              forcedToken: token,
              force: true,
            ),
          );
        });

    _isInitialised = true;
    await _handleInitialMessage();
    await _attemptTokenRegistration(reason: 'initialise');
  }

  // Reacts to auth changes so token registration happens after auth restore and
  // after explicit sign-in, rather than only during app startup.
  void _handleAuthChanged() {
    if (_authService.isLoggedIn) {
      unawaited(_attemptTokenRegistration(reason: 'auth-change'));
      return;
    }

    _lastRegisteredToken = null;
    _lastRegisteredUid = null;
  }

  // Removes the currently registered token before Firebase sign-out clears the
  // caller's auth state.
  Future<void> _handleBeforeLogout() async {
    await _removeRegisteredToken(reason: 'logout');
  }

  // Handles a notification opened from the terminated state.
  Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage == null) {
      return;
    }

    await _handleNotificationOpen(initialMessage);
  }

  // Shows a foreground banner for supported notifications, unless the user is
  // already inside the relevant chat room and the message would be redundant.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final target = NotificationRouteParser.fromData(message.data);
    if (target == null) {
      return;
    }

    await _primeUserProfileIfNeeded();

    final notificationKey = _buildNotificationKey(message, target);
    if (_hasSeenNotificationKey(notificationKey)) {
      return;
    }
    _rememberNotificationKey(notificationKey);

    if (_shouldSuppressForegroundBanner(target)) {
      if (kDebugMode) {
        print(
          'NotificationCoordinator: Suppressed foreground chat banner for ${target.route}',
        );
      }
      return;
    }

    final title = _resolveNotificationTitle(message, target);
    final body = _resolveNotificationBody(message, target);

    // Render a tray entry even when the app is in the foreground, because the
    // Phase 19 backend sends data-only pushes for android-native tokens and
    // FCM therefore never auto-renders one. Use the already-initialised local
    // notifications singleton so tap callbacks remain wired for later opens.
    await _notificationService.showForegroundFcmNotification(message);

    _appNavigationService.showForegroundBanner(
      title: title,
      body: body,
      target: target,
    );
  }

  // Routes notification taps from background or terminated states.
  Future<void> _handleNotificationOpen(RemoteMessage message) async {
    final target = NotificationRouteParser.fromData(message.data);
    if (target == null) {
      return;
    }

    await _primeUserProfileIfNeeded();

    _rememberNotificationKey(_buildNotificationKey(message, target));
    await _appNavigationService.navigateToNotificationTarget(target);
  }

  // Routes taps on locally displayed notifications, such as scheduled booking
  // reminders that include a payload in future.
  void _handleLocalNotificationTap(String? payload) {
    final target = NotificationRouteParser.fromPayload(payload);
    if (target == null) {
      return;
    }

    unawaited(_appNavigationService.navigateToNotificationTarget(target));
  }

  // Registers the FCM token with the shared backend when auth and permission
  // state allow it.
  Future<void> _attemptTokenRegistration({
    required String reason,
    String? forcedToken,
    bool force = false,
  }) async {
    if (!_authService.isLoggedIn || _isRegisteringToken) {
      return;
    }

    _isRegisteringToken = true;

    try {
      final permissionGranted =
          _notificationService.notificationsEnabled ||
          await _notificationService.requestPermission();
      if (!permissionGranted) {
        if (kDebugMode) {
          print(
            'NotificationCoordinator: Notification permission not granted during $reason',
          );
        }
        return;
      }

      final userId = _authService.uid;
      final idToken = await _authService.getIdToken();
      final deviceToken =
          forcedToken ?? await FirebaseMessaging.instance.getToken();

      if (userId == null || idToken == null || idToken.isEmpty) {
        return;
      }

      if (deviceToken == null || deviceToken.isEmpty) {
        if (kDebugMode) {
          print(
            'NotificationCoordinator: No FCM token available during $reason',
          );
        }
        return;
      }

      if (!force &&
          _lastRegisteredUid == userId &&
          _lastRegisteredToken == deviceToken) {
        if (kDebugMode) {
          print(
            'NotificationCoordinator: Skipped duplicate token registration during $reason',
          );
        }
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.getEndpoint('API/Messaging/register-token')),
        headers: {
          'Authorization': 'Bearer $idToken',
          'x-api-passcode': AppConfig.apiPasscode,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': deviceToken,
          'platform': AppConfig.notificationPlatform,
          'appId': AppConfig.nativeAndroidAppId,
        }),
      );

      if (response.statusCode == 200) {
        _lastRegisteredUid = userId;
        _lastRegisteredToken = deviceToken;

        if (kDebugMode) {
          print('NotificationCoordinator: Registered FCM token during $reason');
        }
        return;
      }

      if (kDebugMode) {
        print(
          'NotificationCoordinator: Failed to register token during $reason '
          '(${response.statusCode}) ${response.body}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        print(
          'NotificationCoordinator: Error registering token during $reason - $error',
        );
      }
    } finally {
      _isRegisteringToken = false;
    }
  }

  // Removes the current token using the documented query-string contract.
  Future<void> _removeRegisteredToken({required String reason}) async {
    final registeredToken = _lastRegisteredToken;
    if (registeredToken == null || registeredToken.isEmpty) {
      return;
    }

    try {
      final idToken = await _authService.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        return;
      }

      final endpoint = Uri.parse(
        AppConfig.getEndpoint('API/Messaging/register-token'),
      ).replace(queryParameters: {'token': registeredToken});

      final response = await http.delete(
        endpoint,
        headers: {
          'Authorization': 'Bearer $idToken',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200) {
        _lastRegisteredToken = null;
        _lastRegisteredUid = null;

        if (kDebugMode) {
          print('NotificationCoordinator: Removed FCM token during $reason');
        }
        return;
      }

      if (kDebugMode) {
        print(
          'NotificationCoordinator: Failed to remove token during $reason '
          '(${response.statusCode}) ${response.body}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        print(
          'NotificationCoordinator: Error removing token during $reason - $error',
        );
      }
    }
  }

  // Suppresses in-app chat banners when the user is already looking at the
  // same room, because the socket-driven chat UI is already the primary surface.
  bool _shouldSuppressForegroundBanner(NotificationRouteTarget target) {
    if (!target.isChat || target.roomId == null) {
      return false;
    }

    return _chatService.activeRoomId == target.roomId;
  }

  // Uses the server-provided identifiers first so duplicate chat/socket events
  // do not show repeated foreground banners.
  String _buildNotificationKey(
    RemoteMessage message,
    NotificationRouteTarget target,
  ) {
    final messageId = target.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      return messageId;
    }

    if (message.messageId != null && message.messageId!.isNotEmpty) {
      return message.messageId!;
    }

    final title = _resolveNotificationTitle(message, target);
    final body = _resolveNotificationBody(message, target);
    return '${target.route}|$title|$body';
  }

  // Tracks a small in-memory window of recently displayed notification keys.
  void _rememberNotificationKey(String notificationKey) {
    if (notificationKey.isEmpty ||
        _recentNotificationKeys.contains(notificationKey)) {
      return;
    }

    _recentNotificationKeys.add(notificationKey);
    _recentNotificationOrder.addLast(notificationKey);

    while (_recentNotificationOrder.length > 50) {
      final oldestKey = _recentNotificationOrder.removeFirst();
      _recentNotificationKeys.remove(oldestKey);
    }
  }

  bool _hasSeenNotificationKey(String notificationKey) {
    return _recentNotificationKeys.contains(notificationKey);
  }

  // Falls back to a sensible title when the push payload omits notification UI.
  String _resolveNotificationTitle(
    RemoteMessage message,
    NotificationRouteTarget target,
  ) {
    final title = message.notification?.title?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    final dataTitle = message.data['title']?.toString().trim();
    if (dataTitle != null && dataTitle.isNotEmpty) {
      return dataTitle;
    }

    if (target.isChat) {
      return 'New message';
    }
    return 'Booking update';
  }

  // Falls back to body text that still gives the user a meaningful action cue.
  String _resolveNotificationBody(
    RemoteMessage message,
    NotificationRouteTarget target,
  ) {
    final body = message.notification?.body?.trim();
    if (body != null && body.isNotEmpty) {
      return body;
    }

    final dataBody = message.data['body']?.toString().trim();
    if (dataBody != null && dataBody.isNotEmpty) {
      return dataBody;
    }

    if (target.isChat) {
      return 'Open the chat to read the latest message.';
    }

    return 'Open bookings to view the latest status.';
  }

  // Hooks auth listeners into whichever AuthService instance is current.
  void _bindAuthService(AuthService authService) {
    authService.addListener(_handleAuthChanged);
    authService.addBeforeLogoutCallback(_handleBeforeLogout);
  }

  // Makes sure role-based booking routing has a profile available as early as
  // possible after auth restore or notification tap.
  Future<void> _primeUserProfileIfNeeded() async {
    final userId = _authService.uid;
    if (userId == null ||
        _userService.currentProfile != null ||
        _userService.isLoading) {
      return;
    }

    await _userService.getUserProfile(userId);
  }

  // Removes auth listeners before the provider swaps in a new AuthService.
  void _unbindAuthService(AuthService authService) {
    authService.removeListener(_handleAuthChanged);
    authService.removeBeforeLogoutCallback(_handleBeforeLogout);
  }

  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    _notificationOpenSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _unbindAuthService(_authService);
    super.dispose();
  }
}
