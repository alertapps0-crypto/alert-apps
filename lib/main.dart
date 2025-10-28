import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wireless_calling_system/ui/login_security.dart';
import 'firebase_options.dart';
import 'models/notifikasi.dart';
import 'services/firebase_messaging_handler.dart';
import 'services/notification_handler.dart' as app_notif;
import 'services/navigation_service.dart';

import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/notification_state.dart';
import 'ui/confirm_sos.dart';
import 'ui/dashboard_guru.dart';
import 'ui/dashboard_ortu.dart';
import 'ui/detail_sos.dart';
import 'ui/sign_up_guru.dart';
import 'ui/sign_up_security.dart';
import 'ui/sos_notif.dart';
import 'ui/login_guru.dart';
import 'ui/login_ortu.dart';
import 'ui/role_select.dart';
import 'ui/sign_up_ortu.dart';
import 'ui/splash_screen.dart';

// Fungsi untuk menginisialisasi semua services
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background messages
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Got a background message: ${message.messageId}');

  // Save notification to Firestore
  try {
    // Normalize recipientIds: accept comma-separated string or list
    final dynamic recIdsRaw = message.data['recipientIds'];
    final List<String> recIds = recIdsRaw is String
        ? recIdsRaw
            .split(',')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList()
        : (recIdsRaw is List ? List<String>.from(recIdsRaw) : <String>[]);

    // Ensure we always have a notificationId that we can attach to the
    // displayed notification. Prefer an explicit data['notificationId'] if
    // present, otherwise fallback to messageId or a generated timestamp.
    final String notifId = message.data['notificationId'] ??
        message.messageId ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final notification = Notifikasi(
      id: notifId,
      senderId: message.data['senderId'] ?? '',
      recipientIds: recIds,
      // Prefer any explicit data fields, then notification payload, then a
      // safe default.
      message: message.data['message'] ??
          message.data['body'] ??
          message.notification?.body ??
          '',
      timestamp: message.sentTime ?? DateTime.now(),
      senderName:
          message.data['senderName'] ?? message.data['teacherName'] ?? '',
      teacherPhone: message.data['teacherPhone'] ?? '',
    );

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());

    // Resolve title/body with a wide set of fallbacks so the created
    // notification always has readable content.
    final String title = (message.data['title'] as String?) ??
        (message.notification?.title) ??
        'SOS Darurat';

    final String body = (message.data['message'] as String?) ??
        (message.data['body'] as String?) ??
        (message.notification?.body) ??
        'Permintaan bantuan masuk.';

    // If the system already produced a notification (message.notification !=
    // null) there is a chance the platform will show a second notification
    // (system + our local). To reduce duplicates we attempt to dismiss any
    // existing local notifications before creating ours. Note: this cannot
    // reliably cancel system notifications produced by FCM, so the ideal
    // fix is to send DATA-only messages from the server. This change makes
    // the background handling safer and ensures the created notification
    // always includes a notificationId, title and body.
    try {
      await AwesomeNotifications().dismissAllNotifications();
    } catch (e) {
      debugPrint('Error dismissing existing notifications: $e');
    }

    // Use a 32-bit-safe int id for AwesomeNotifications
    final int awId = notification.id.hashCode & 0x7fffffff;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: awId,
        channelKey: 'emergency_channel',
        title: title,
        body: body,
        category: NotificationCategory.Alarm,
        displayOnBackground: true,
        displayOnForeground: true,
        wakeUpScreen: true,
        criticalAlert: true,
        fullScreenIntent: true,
        autoDismissible: false,
        payload: {
          'notificationId': notification.id,
          'senderId': notification.senderId,
          'senderName': notification.senderName,
          'teacherPhone': notification.teacherPhone,
        },
      ),
    );

    debugPrint('Background notification saved to Firestore');
  } catch (e) {
    debugPrint('Error saving background notification to Firestore: $e');
  }
}

Future<void> _initializeServices() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'emergency_channel',
          channelName: 'Emergency Notifications',
          channelDescription: 'Channel for emergency notifications',
          defaultColor: Color(0xFF9D50DD),
          importance: NotificationImportance.Max,
          playSound: true,
          criticalAlerts: true,
          locked: true,
          enableLights: true,
          enableVibration: true,
        ),
      ],
    );

    // Register notification listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod:
          app_notif.NotificationHandler.onActionReceivedMethod,
      onNotificationCreatedMethod:
          app_notif.NotificationHandler.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          app_notif.NotificationHandler.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          app_notif.NotificationHandler.onDismissActionReceivedMethod,
    );

    // Request notification permissions
    await AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
        NotificationPermission.CriticalAlert,
      ],
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set the background message handler before initializing Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize the Firebase Messaging Handler
    final messagingHandler = FirebaseMessagingHandler();
    await messagingHandler.initialize();

    // Handle the case where the app is opened via a terminated-state notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final notifId = initialMessage.data['notificationId'];
      if (notifId != null) {
        // Delay navigation until the app has a navigator
        Future.delayed(const Duration(milliseconds: 400), () {
          NavigationService.navigateToNotificationDetail(notifId);
        });
      }
    }
  } catch (e) {
    print('Error during service initialization: $e');
    rethrow;
  }
}

void main() async {
  // ... (Kode runZonedGuarded Anda) ...
  runZonedGuarded(() async {
    await _initializeServices();
    runApp(MainApp()); // Ubah ke MainApp
  }, (error, stackTrace) {
    print('Error caught by runZonedGuarded: $error');
    print('Stack trace: $stackTrace');
  });
}

class MainApp extends StatelessWidget {
  final AuthService _authService = AuthService();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider 1: Menyediakan status autentikasi
        StreamProvider<User?>(
          create: (_) => _authService.authStateChanges,
          initialData: null,
        ),

        // Provider 2: Notification State Management
        ChangeNotifierProvider(
          create: (_) => NotificationState(),
        ),

        // Provider 3: Firebase Messaging Handler
        Provider<FirebaseMessagingHandler>(
          create: (_) => FirebaseMessagingHandler(),
          dispose: (_, handler) => handler.dispose(),
        ),

        // Provider 4: Notification Service
        Provider<NotificationService>(
          create: (context) => NotificationService(context),
        ),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: "Wireless Calling System",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xffc8d9e6),
          ),
          useMaterial3: true,
          textTheme: TextTheme(
            headlineMedium: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            labelMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            labelSmall: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
        routes: {
          "/roleselect": (context) => const RoleSelect(),
          "/loginguru": (context) => const LoginGuru(),
          "/loginsecurity": (context) => const LoginSecurity(),
          "/loginortu": (context) => const LoginOrtu(),
          '/detailsos': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as String;
            return DetailSos(notificationId: args);
          },
          '/sosnotif': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final String notifId = args is String ? args : '';
            return SosNotif(notificationId: notifId);
          },
          "/confirmsos": (context) => const ConfirmSos(),
          "/signuportu": (context) => const SignUpOrtu(),
          "/signupguru": (context) => const SignUpGuru(),
          "/signupsecurity": (context) => const SignUpSecurity(),
        },
        home: Consumer<User?>(
          builder: (context, user, child) {
            if (user == null) {
              // Jika tidak ada user, tampilkan SplashScreen
              return const SplashScreen();
            }

            // Jika ada user, cek rolenya (logika Anda sudah benar)
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get()
                  .timeout(
                    const Duration(seconds: 10),
                    onTimeout: () =>
                        throw TimeoutException('Firebase operation timed out'),
                  ),
              builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  // Ensure the logged-in user has an up-to-date FCM token
                  // This prevents cases where initialize() ran before login and token wasn't saved
                  Future.microtask(() async {
                    try {
                      final token = await FirebaseMessaging.instance.getToken();
                      if (token != null) {
                        final existing = userData['fcmToken'];
                        if (existing != token) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .set(
                                  {'fcmToken': token}, SetOptions(merge: true));
                        }
                      }
                    } catch (e) {
                      debugPrint('Failed to ensure FCM token: $e');
                    }
                  });

                  // Get the Firebase Messaging Handler
                  final handler = context.read<FirebaseMessagingHandler>();
                  if (userData['role'] == 'parent') {
                    // Only parents need to listen for notifications
                    handler.startNotificationListener();
                  } else {
                    // Teachers don't need to listen for notifications
                    handler.stopNotificationListener();
                  }

                  if (userData['role'] == 'teacher') {
                    return DashboardGuru(
                      teacherId: user.uid,
                      teacherName: userData['name'] ?? '',
                      teacherEmail: userData['email'] ?? '',
                      teacherPhone: userData['phoneNumber'] ?? '',
                    );
                  } else {
                    return DashboardOrtu(
                      parentId: user.uid,
                      parentName: userData['name'] ?? '',
                      parentEmail: userData['email'] ?? '',
                    );
                  }
                }

                // Jika data user tidak ada (error/dll), kembali ke splash
                // (atau sebaiknya ke halaman login/error)
                return const SplashScreen();
              },
            );
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
