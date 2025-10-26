import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../services/navigation_service.dart';

class FirebaseMessagingHandler {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _initialized = false;
  static StreamSubscription<QuerySnapshot>? _notificationSubscription;

  Future<void> initialize() async {
    if (!_initialized) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
        announcement: true,
        carPlay: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');

        String? token = await _messaging.getToken();
        print('FCM Token: $token');

        if (token != null && _auth.currentUser != null) {
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update({'fcmToken': token});
        }

        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Listen for FCM token refresh
        _messaging.onTokenRefresh.listen((String token) async {
          print('FCM Token refreshed: $token');
          if (_auth.currentUser != null) {
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .update({'fcmToken': token});
          }
        });

        _initialized = true;
      } else {
        print('User declined permission');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a foreground message: ${message.messageId}');

    try {
      final title =
          message.data['title'] ?? message.notification?.title ?? 'SOS Darurat';
      final body = message.data['message'] ??
          message.data['body'] ??
          message.notification?.body ??
          'Permintaan bantuan masuk.';

      final notificationId = (message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString())
          .hashCode;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId % 2147483647, // ensure fits int32
          channelKey: 'emergency_channel',
          title: title,
          body: body,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          criticalAlert: true,
          fullScreenIntent: true,
          autoDismissible: false,
          displayOnForeground: true,
          displayOnBackground: true,
          payload: {
            'notificationId': message.data['notificationId'] ?? '',
            'senderId': message.data['senderId'] ?? '',
            'senderName': message.data['senderName'] ?? '',
            'teacherPhone': message.data['teacherPhone'] ?? '',
          },
        ),
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');

    if (message.data['notificationId'] != null) {
      NavigationService.navigateToSosNotif(message.data['notificationId']);
    }
  }

  void startNotificationListener() {
    if (_auth.currentUser != null) {
      _notificationSubscription?.cancel();
      _notificationSubscription = _firestore
          .collection('notifications')
          .where('recipientIds', arrayContains: _auth.currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            print('New notification received: ${change.doc.data()}');
          }
        }
      });
    }
  }

  void stopNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  void dispose() {
    stopNotificationListener();
  }
}
