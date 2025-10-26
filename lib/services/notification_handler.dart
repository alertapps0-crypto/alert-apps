import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'navigation_service.dart';

class NotificationHandler {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('onNotificationCreatedMethod');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('onNotificationDisplayedMethod');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('onDismissActionReceivedMethod');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('onActionReceivedMethod');

    // Dismiss the tapped notification to remove it from the tray
    final int? id = receivedAction.id;
    if (id != null) {
      try {
        await AwesomeNotifications().dismiss(id);
      } catch (e) {
        debugPrint('Failed to dismiss notification id=$id: $e');
      }
    }

    String? notificationId = receivedAction.payload?['notificationId'];
    if (notificationId != null) {
      NavigationService.navigateToSosNotif(notificationId);
    }
  }
}
