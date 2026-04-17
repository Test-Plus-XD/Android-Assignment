import 'package:android_assignment/main.dart';
import 'package:android_assignment/services/app_navigation_service.dart';
import 'package:android_assignment/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PourRiceApp can be constructed with the required services', () {
    expect(
      () => PourRiceApp(
        notificationService: NotificationService(),
        appNavigationService: AppNavigationService(),
      ),
      returnsNormally,
    );
  });
}
