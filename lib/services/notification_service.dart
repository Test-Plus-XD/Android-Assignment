import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart';

// Monochrome small icon used for every locally rendered notification. Matches
// the default_notification_icon meta-data declared in AndroidManifest.xml and
// the icon name the backend sends for standard notification pushes.
const String _pushNotificationIcon = 'ic_stat_pourrice_notification';
// Brand tint applied to the monochrome icon by Android's notification surface.
// Matches the backend's buildAndroidNotificationConfig color (#A4E092).
const Color _pushNotificationColor = Color(0xFFA4E092);

const String _pushNotificationChannelId = 'pourrice_default_notifications';
const String _pushNotificationChannelName = 'PourRice Alerts';
const String _pushNotificationChannelDescription =
    'Chat messages, bookings, and app activity';
const String _generalNotificationChannelId = 'general';
const String _generalNotificationChannelName = 'General Notifications';
const String _generalNotificationChannelDescription =
    'General app notifications and updates';

// Shows a local notification for Android data-only FCM messages received while
// the Flutter UI is in the background or the process is being cold-started.
@pragma('vm:entry-point')
Future<void> showBackgroundFcmNotification(RemoteMessage message) async {
  // Android already renders normal FCM notification payloads in the
  // background, so this helper is only for the backend's data-only path.
  final notificationContent = _buildPushNotificationContent(message);
  if (notificationContent == null) {
    return;
  }
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings(_pushNotificationIcon);
  const initSettings = InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(initSettings);
  await _createPushNotificationChannel(notificationsPlugin);
  await _showPushNotification(
    notificationsPlugin,
    notificationContent,
  );
}

Future<void> _createPushNotificationChannel(
  FlutterLocalNotificationsPlugin notificationsPlugin,
) async {
  const pushChannel = AndroidNotificationChannel(
    _pushNotificationChannelId,
    _pushNotificationChannelName,
    description: _pushNotificationChannelDescription,
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(pushChannel);
}

String? _normaliseNotificationText(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

String _resolveNotificationTag(Map<String, dynamic> data, String? messageId) {
  final explicitTag = _normaliseNotificationText(data['notificationTag']);
  if (explicitTag != null) {
    return explicitTag;
  }

  final explicitMessageId = _normaliseNotificationText(data['messageId']);
  if (explicitMessageId != null) {
    return explicitMessageId;
  }

  final firebaseMessageId = _normaliseNotificationText(messageId);
  if (firebaseMessageId != null) {
    return firebaseMessageId;
  }

  return DateTime.now().microsecondsSinceEpoch.toString();
}

String? _resolveNotificationPayload(Map<String, dynamic> data) {
  return _normaliseNotificationText(data['route']) ??
      _normaliseNotificationText(data['url']);
}

_PushNotificationContent? _buildPushNotificationContent(RemoteMessage message) {
  if (message.notification != null) {
    return null;
  }

  final data = message.data;
  final title = _normaliseNotificationText(data['title']);
  final body = _normaliseNotificationText(data['body']);

  if (title == null && body == null) {
    return null;
  }

  final notificationTag = _resolveNotificationTag(data, message.messageId);
  return _PushNotificationContent(
    title: title ?? 'PourRice',
    body: body ?? '',
    notificationTag: notificationTag,
    notificationId: _stableNotificationId(notificationTag),
    payload: _resolveNotificationPayload(data),
  );
}

Future<void> _showPushNotification(
  FlutterLocalNotificationsPlugin notificationsPlugin,
  _PushNotificationContent notificationContent,
) async {
  final androidDetails = AndroidNotificationDetails(
    _pushNotificationChannelId,
    _pushNotificationChannelName,
    channelDescription: _pushNotificationChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.message,
    icon: _pushNotificationIcon,
    color: _pushNotificationColor,
    styleInformation: BigTextStyleInformation(notificationContent.body),
    tag: notificationContent.notificationTag,
  );
  final notificationDetails = NotificationDetails(android: androidDetails);

  await notificationsPlugin.show(
    notificationContent.notificationId,
    notificationContent.title,
    notificationContent.body,
    notificationDetails,
    payload: notificationContent.payload,
  );
}

int _stableNotificationId(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }

  return hash == 0 ? 1 : hash;
}

/// This function is designed to be run in a separate isolate to avoid blocking the UI thread.
/// It initializes the timezone database, which can be a time-consuming operation.
void _initializeTimezones(void _) {
  // Initialise the timezone database.
  initializeTimeZones();
  // Set the local timezone for the application.
  tz.setLocalLocation(tz.getLocation('Asia/Hong_Kong'));
}

/// Notification Service - Bilingual Local Notifications
///
/// This service manages local notifications with full Traditional Chinese and
/// English language support, integrating with your existing LanguageService.
///
/// Understanding Local vs Push Notifications:
///
/// Local notifications are scheduled on the device itself. Think of them like
/// setting an alarm clock - you tell your phone "remind me at 3pm" and it does,
/// even if you're offline. The notification lives entirely on your device.
///
/// Push notifications come from a server through Firebase Cloud Messaging.
/// They're like receiving a text message - someone else sends it to you.
/// For this assignment, local notifications are perfect because they:
/// - Don't require server infrastructure
/// - Work offline
/// - Are simpler to implement and demonstrate
/// - Still show native Android features
///
/// Why Notification Channels Matter:
///
/// Android 8.0+ requires notification channels. These are categories that let
/// users control notification behaviour per category. For example:
/// - Booking reminders: High priority, sound enabled
/// - Promotional offers: Low priority, no sound
///
/// Users can customize these in their system settings (Settings > Apps >
/// Your App > Notifications), giving them fine-grained control. This is actually
/// a good thing for UX - users who have control are less likely to disable
/// all notifications entirely.
class NotificationService with ChangeNotifier {
  // The plugin instance that communicates with Android's notification system
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Track whether service is initialised
  bool _isInitialised = false;

  // Track whether notifications are enabled (user permission)
  bool _notificationsEnabled = false;

  // Error message if something goes wrong
  String? _errorMessage;
  // The notification tap handler lets higher-level coordinators own routing.
  void Function(String? payload)? _notificationTapHandler;
  String? _pendingLaunchPayload;

  // GETTERS
  bool get isInitialised => _isInitialised;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get errorMessage => _errorMessage;

  // Shows a tray notification for a foreground FCM message without
  // reinitialising the singleton plugin and clearing its tap callback.
  Future<void> showForegroundFcmNotification(RemoteMessage message) async {
    if (!_isInitialised) {
      throw StateError(
        'NotificationService not initialised. Call initialise() first.',
      );
    }

    final notificationContent = _buildPushNotificationContent(message);
    if (notificationContent == null) {
      return;
    }

    await _createPushNotificationChannel(_notificationsPlugin);
    await _showPushNotification(_notificationsPlugin, notificationContent);
  }

  // Registers a callback for local-notification taps.
  void setNotificationTapHandler(void Function(String? payload) handler) {
    _notificationTapHandler = handler;
    final pendingLaunchPayload = _pendingLaunchPayload;
    if (pendingLaunchPayload == null) {
      return;
    }

    _pendingLaunchPayload = null;
    handler(pendingLaunchPayload);
  }

  /// Initialise the notification system
  ///
  /// This method does three critical things:
  /// 1. Initialises timezone data (needed for scheduling)
  /// 2. Sets up Android notification settings
  /// 3. Creates notification channels
  ///
  /// Call this once when your app starts, ideally in main.dart
  /// before runApp() is called, so notifications are ready immediately.
  Future<void> initialise() async {
    try {
      if (_isInitialised) {
        if (kDebugMode) {
          print('NotificationService: Already initialised, skipping');
        }
        return;
      }
      if (kDebugMode) print('NotificationService: Starting initialisation');

      // Step 1: Initialise timezone database in a background isolate
      // This is a heavy operation and can cause the app to hang on startup.
      // We use Flutter's `compute` function to run it in a separate isolate.
      await compute(_initializeTimezones, null);

      // Step 2: Configure Android-specific settings
      // The AndroidInitializationSettings takes a drawable resource name.
      // We use the monochrome 'ic_stat_pourrice_notification' vector drawable
      // under android/app/src/main/res/drawable/ so small icons render as a
      // proper silhouette on Android 5+ instead of a blank white square.
      const androidSettings = AndroidInitializationSettings(
        _pushNotificationIcon,
      );

      // InitializationSettings combines settings for all platforms
      // If you add iOS support later, add iOS settings here too
      const initSettings = InitializationSettings(android: androidSettings);

      // Initialise the plugin with these settings
      await _notificationsPlugin.initialize(
        initSettings,
        // This callback runs when user taps a notification
        // You can use it to navigate to specific screens
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _captureLaunchPayloadIfNeeded();

      // Step 3: Create notification channels
      // Android requires channels, but it's actually helpful UX
      await _createNotificationChannels();

      // Step 4: Check if we have permission
      // On Android 13+, apps need explicit permission for notifications
      await _checkNotificationPermission();

      _isInitialised = true;
      _errorMessage = null;
      notifyListeners();

      if (kDebugMode) {
        print('NotificationService: Initialised successfully');
      }
    } catch (e) {
      _errorMessage = 'Failed to initialise notifications: $e';
      _isInitialised = false;
      notifyListeners();

      if (kDebugMode) {
        print('NotificationService: Initialisation error - $e');
      }
    }
  }

  /// Create notification channels
  ///
  /// This sets up different categories of notifications. Each channel has:
  /// - Unique ID (to reference it when sending notifications)
  /// - User-visible name (appears in system settings)
  /// - Description (explains what it's for)
  /// - Importance level (affects sound, vibration, popup behaviour)
  ///
  /// Think of channels like radio stations - each has a purpose and users
  /// can tune in (enable) or tune out (disable) individual stations.
  Future<void> _createNotificationChannels() async {
    // Channel 1: Booking Reminders
    // High importance because users really need to know about their bookings
    const bookingChannel = AndroidNotificationChannel(
      'booking_reminders', // ID - use in code
      'Booking Reminders', // Name - user sees in settings
      description: 'Notifications for upcoming restaurant bookings',
      importance: Importance.high, // Shows as pop-up notification
      enableVibration: true, // Device vibrates
      playSound: true, // Plays default notification sound
    );

    // Channel 2: General Notifications
    // Default importance for less urgent messages
    const generalChannel = AndroidNotificationChannel(
      _generalNotificationChannelId,
      _generalNotificationChannelName,
      description: _generalNotificationChannelDescription,
      importance: Importance.defaultImportance,
      enableVibration: false,
      playSound: true,
    );

    // Register channels with Android system
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(bookingChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(generalChannel);

    await _createPushNotificationChannel(_notificationsPlugin);
  }

  /// Check notification permission (Android 13+)
  ///
  /// Android 13 introduced runtime permission for notifications.
  /// Before that, notifications were always allowed unless user disabled
  /// them in settings. Now apps must request permission explicitly.
  ///
  /// This method checks if we have permission and updates our state.
  Future<void> _checkNotificationPermission() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // Check current permission status
      final granted = await androidImplementation.areNotificationsEnabled();
      _notificationsEnabled = granted ?? false;

      if (kDebugMode) {
        print(
          'NotificationService: Notifications enabled = $_notificationsEnabled',
        );
      }
    }
  }

  /// Request notification permission (Android 13+)
  ///
  /// Shows a system dialog asking user to allow notifications.
  /// Returns true if granted, false if denied.
  Future<bool> requestPermission() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      _notificationsEnabled = granted ?? false;
      notifyListeners();
      return _notificationsEnabled;
    }
    return false;
  }

  /// Immediately show a notification right now (useful for foreground FCM messages)
  ///
  /// This schedules a notification to display immediately using the 'general' channel.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialised) {
        throw Exception(
          'NotificationService not initialised. Call initialise() first.',
        );
      }

      // Use the general channel for immediate, in-app messages
      const androidDetails = AndroidNotificationDetails(
        _generalNotificationChannelId, // Must match channel ID we created
        _generalNotificationChannelName, // Channel name
        channelDescription: _generalNotificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: _pushNotificationIcon,
        color: _pushNotificationColor,
        ticker: 'Immediate Notification',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id, // Unique ID for this notification
        title, // Notification title
        body, // Notification body
        notificationDetails, // How to show it
        payload: payload,
      );

      if (kDebugMode) {
        print('NotificationService: Immediately showed notification ID $id');
      }
    } catch (e) {
      _errorMessage = 'Failed to show immediate notification: $e';
      notifyListeners();

      if (kDebugMode)
        print('NotificationService: Error showing immediate notification - $e');
      rethrow;
    }
  }

  /// Schedule a booking reminder notification
  ///
  /// This is the main method you'll use. It creates a notification that
  /// appears before a booking, reminding the user about their reservation.
  ///
  /// Parameters explained:
  /// - id: Unique number for this notification (use booking ID hash)
  /// - restaurantName: Name of restaurant (in both languages)
  /// - bookingDateTime: When the booking is
  /// - notificationTime: When to show the notification (e.g., 2 hours before)
  /// - isTraditionalChinese: User's language preference
  ///
  /// How timing works:
  /// If booking is at 7:00 PM and notificationTime is 5:00 PM,
  /// Android will show the notification at exactly 5:00 PM, even if
  /// your app is closed or phone is locked.
  Future<void> scheduleBookingReminder({
    required int id,
    required String restaurantNameEn,
    required String restaurantNameTc,
    required DateTime bookingDateTime,
    required DateTime notificationTime,
    required bool isTraditionalChinese,
  }) async {
    try {
      // Verify initialisation
      if (!_isInitialised) {
        throw Exception(
          'NotificationService not initialised. Call initialise() first.',
        );
      }

      // Verify permission
      if (!_notificationsEnabled) {
        throw Exception('Notification permission not granted.');
      }

      // Verify notification time is in future
      if (notificationTime.isBefore(DateTime.now())) {
        throw Exception('Notification time must be in the future.');
      }

      // Choose appropriate language for notification text
      final restaurantName = isTraditionalChinese
          ? restaurantNameTc
          : restaurantNameEn;

      // Format booking time for display
      // Example: "7:00 PM" or "下午7:00"
      final timeString = _formatTime(bookingDateTime, isTraditionalChinese);
      _formatDate(bookingDateTime, isTraditionalChinese);

      // Build notification title and body based on language
      final title = isTraditionalChinese ? '預訂提醒' : 'Booking Reminder';

      final body = isTraditionalChinese
          ? '您在 $restaurantName 的預訂將於 $timeString 開始'
          : 'Your booking at $restaurantName is at $timeString';

      // Configure notification appearance
      final androidDetails = AndroidNotificationDetails(
        'booking_reminders', // Must match channel ID we created
        'Booking Reminders', // Must match channel name
        channelDescription: 'Notifications for upcoming restaurant bookings',
        importance: Importance.high,
        priority: Priority.high,
        icon: _pushNotificationIcon,
        color: _pushNotificationColor,
        // Show date/time in notification
        when: bookingDateTime.millisecondsSinceEpoch,
        // Enable alert (pop-up banner on screen)
        ticker: isTraditionalChinese ? '預訂提醒' : 'Booking Reminder',
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      // Convert notification time to timezone-aware format
      final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

      // Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        id, // Unique ID for this notification
        title, // Notification title
        body, // Notification body
        scheduledDate, // When to show it
        notificationDetails, // How to show it
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      if (kDebugMode) {
        print(
          'NotificationService: Scheduled notification ID $id for $scheduledDate',
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to schedule notification: $e';
      notifyListeners();

      if (kDebugMode) {
        print('NotificationService: Error scheduling notification - $e');
      }

      rethrow;
    }
  }

  /// Cancel a specific notification
  ///
  /// Use this when a booking is cancelled or rescheduled.
  /// The notification won't appear anymore.
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);

      if (kDebugMode) {
        print('NotificationService: Cancelled notification ID $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error cancelling notification - $e');
      }
    }
  }

  /// Cancel all notifications
  ///
  /// Nuclear option - removes all scheduled notifications from this app.
  /// Useful for logout or "clear all" functionality.
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();

      if (kDebugMode) {
        print('NotificationService: Cancelled all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error cancelling all notifications - $e');
      }
    }
  }

  /// Get list of pending notifications
  ///
  /// Useful for debugging or showing users "you have 3 upcoming reminders".
  /// Returns list of scheduled notifications that haven't fired yet.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Format time for notification (language-aware)
  String _formatTime(DateTime dateTime, bool isTraditionalChinese) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (isTraditionalChinese) {
      // Traditional Chinese uses 12-hour format with 上午/下午
      final period = hour < 12 ? '上午' : '下午';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$period$hour12:$minute';
    } else {
      // English uses 12-hour format with AM/PM
      final period = hour < 12 ? 'AM' : 'PM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    }
  }

  /// Format date for notification (language-aware)
  String _formatDate(DateTime dateTime, bool isTraditionalChinese) {
    final months = isTraditionalChinese
        ? [
            '一月',
            '二月',
            '三月',
            '四月',
            '五月',
            '六月',
            '七月',
            '八月',
            '九月',
            '十月',
            '十一月',
            '十二月',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];

    if (isTraditionalChinese) {
      return '${dateTime.year}年${months[dateTime.month - 1]}${dateTime.day}日';
    } else {
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }
  }

  /// Captures a local-notification payload that launched the app from a
  /// terminated state before the notification coordinator has been constructed.
  Future<void> _captureLaunchPayloadIfNeeded() async {
    final launchDetails = await _notificationsPlugin
        .getNotificationAppLaunchDetails();
    final payload = launchDetails?.didNotificationLaunchApp == true
        ? launchDetails?.notificationResponse?.payload
        : null;
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    final handler = _notificationTapHandler;
    if (handler != null) {
      handler(payload);
      return;
    }
    _pendingLaunchPayload = payload;
  }

  /// Callback when user taps a notification
  ///
  /// This is called when user taps a notification in their notification tray.
  /// You can parse the payload to determine which screen to navigate to.
  ///
  /// For example, if user taps a booking reminder, navigate to booking details.
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('NotificationService: Notification tapped - ${response.payload}');
    }

    _notificationTapHandler?.call(response.payload);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class _PushNotificationContent {
  final String title;
  final String body;
  final String notificationTag;
  final int notificationId;
  final String? payload;

  const _PushNotificationContent({
    required this.title,
    required this.body,
    required this.notificationTag,
    required this.notificationId,
    required this.payload,
  });
}
