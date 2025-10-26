import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> navigateToNotificationDetail(
      String notificationId) async {
    navigatorKey.currentState?.pushNamed(
      '/detailsos',
      arguments: notificationId,
    );
  }

  static Future<void> navigateToSosNotif(String notificationId) async {
    navigatorKey.currentState?.pushNamed(
      '/sosnotif',
      arguments: notificationId,
    );
  }
}
