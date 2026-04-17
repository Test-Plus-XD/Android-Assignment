import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/notification_route_parser.dart';

// MainShellRouteHandler lets the shell decide whether a notification route can
// be handled immediately. Returning false keeps the route pending until the app
// is ready, which is important during auth restore and profile loading.
typedef MainShellRouteHandler =
    Future<bool> Function(NotificationRouteTarget target);

// AppNavigationService owns the global keys and acts as the bridge between the
// notification pipeline and the currently mounted MainShell instance.
class AppNavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  MainShellRouteHandler? _mainShellRouteHandler;
  NotificationRouteTarget? _pendingTarget;

  // Registers the active MainShell route handler and immediately retries any
  // pending notification route that arrived before the shell was ready.
  void registerMainShellRouteHandler(MainShellRouteHandler handler) {
    _mainShellRouteHandler = handler;
    unawaited(flushPendingTarget());
  }

  // Clears the active handler when MainShell is disposed.
  void unregisterMainShellRouteHandler() {
    _mainShellRouteHandler = null;
  }

  // Sends a parsed notification route to MainShell, or stores it until the app
  // is ready to handle it.
  Future<void> navigateToNotificationTarget(
    NotificationRouteTarget target,
  ) async {
    final handler = _mainShellRouteHandler;
    if (handler == null) {
      _pendingTarget = target;
      return;
    }

    final handled = await handler(target);
    if (!handled) {
      _pendingTarget = target;
    }
  }

  // Retries the pending route after auth/profile/navigation state settles.
  Future<void> flushPendingTarget() async {
    final pendingTarget = _pendingTarget;
    final handler = _mainShellRouteHandler;
    if (pendingTarget == null || handler == null) {
      return;
    }

    _pendingTarget = null;
    final handled = await handler(pendingTarget);
    if (!handled) {
      _pendingTarget = pendingTarget;
    }
  }

  // Shows an in-app notification banner for foreground FCM events and wires the
  // action straight into the route handler.
  void showForegroundBanner({
    required String title,
    required String body,
    required NotificationRouteTarget target,
  }) {
    final scaffoldMessengerState = scaffoldMessengerKey.currentState;
    if (scaffoldMessengerState == null) {
      return;
    }

    scaffoldMessengerState.hideCurrentSnackBar();
    scaffoldMessengerState.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.trim().isNotEmpty) Text(body),
          ],
        ),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            unawaited(navigateToNotificationTarget(target));
          },
        ),
      ),
    );
  }
}
