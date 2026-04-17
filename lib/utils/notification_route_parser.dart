// Notification route types supported by the app-wide notification pipeline.
enum NotificationRouteType { booking, chat }

// NotificationRouteTarget represents a parsed app route from an FCM payload.
//
// This keeps the notification pipeline route-first, with legacy URL schemes
// handled only as a backwards-compatible fallback during migration.
class NotificationRouteTarget {
  final NotificationRouteType type;
  final String route;
  final String? roomId;
  final String? messageId;

  const NotificationRouteTarget._({
    required this.type,
    required this.route,
    this.roomId,
    this.messageId,
  });

  // Booking notifications open the role-specific bookings experience.
  const NotificationRouteTarget.booking({String? messageId})
    : this._(
        type: NotificationRouteType.booking,
        route: '/booking',
        messageId: messageId,
      );

  // Chat notifications open the requested room directly.
  const NotificationRouteTarget.chat({
    required String roomId,
    String? messageId,
  }) : this._(
         type: NotificationRouteType.chat,
         route: '/chat/$roomId',
         roomId: roomId,
         messageId: messageId,
       );

  bool get isBooking => type == NotificationRouteType.booking;
  bool get isChat => type == NotificationRouteType.chat;

  // The de-duplication key prefers the server-provided messageId when present,
  // then falls back to the canonical route for non-chat notifications.
  String get dedupeKey =>
      messageId != null && messageId!.isNotEmpty ? messageId! : route;
}

// NotificationRouteParser normalises route-first payloads and legacy URL
// fallbacks into the app's supported notification targets.
class NotificationRouteParser {
  // Parses the FCM data payload into a supported route target.
  static NotificationRouteTarget? fromData(Map<String, dynamic> data) {
    final routeValue = _normaliseRoute(
      data['route']?.toString(),
      data['url']?.toString(),
    );
    final messageId = _normaliseValue(data['messageId']?.toString());

    if (routeValue == null) {
      return null;
    }

    if (routeValue == '/booking') {
      return NotificationRouteTarget.booking(messageId: messageId);
    }

    final chatMatch = RegExp(r'^/chat/([^/?#]+)$').firstMatch(routeValue);
    if (chatMatch != null) {
      final roomId = chatMatch.group(1);
      if (roomId != null && roomId.isNotEmpty) {
        return NotificationRouteTarget.chat(
          roomId: roomId,
          messageId: messageId,
        );
      }
    }

    return null;
  }

  // Parses a payload string saved in a local notification.
  static NotificationRouteTarget? fromPayload(String? payload) {
    final routeValue = _normaliseValue(payload);
    if (routeValue == null) {
      return null;
    }

    return fromData({'route': routeValue});
  }

  // Normalises the modern route field first, then the legacy custom scheme.
  static String? _normaliseRoute(String? route, String? legacyUrl) {
    final normalisedRoute = _normaliseValue(route);
    if (normalisedRoute != null && normalisedRoute.startsWith('/')) {
      return normalisedRoute;
    }

    final normalisedUrl = _normaliseValue(legacyUrl);
    if (normalisedUrl == null) {
      return null;
    }

    Uri? uri;
    try {
      uri = Uri.parse(normalisedUrl);
    } catch (_) {
      return null;
    }

    if (uri.scheme != 'pourrice') {
      return null;
    }

    if (uri.host == 'bookings' || uri.host == 'booking') {
      return '/booking';
    }

    if (uri.host == 'chat' && uri.pathSegments.isNotEmpty) {
      return '/chat/${uri.pathSegments.first}';
    }

    return null;
  }

  // Removes empty-string values so the parser can treat them as missing.
  static String? _normaliseValue(String? value) {
    if (value == null) {
      return null;
    }

    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    return trimmedValue;
  }
}
