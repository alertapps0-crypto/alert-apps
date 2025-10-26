import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_config.dart';
import '../models/notifikasi.dart';
import '../providers/notification_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isListening = false;
  final BuildContext context;

  NotificationService(this.context);

  bool _isFirstBatch = true;

  // Initialize notifications
  Future<void> _initializeFcmAndToken(String userId) async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("FCM permissions granted");

        _fcm.onTokenRefresh.listen((String token) async {
          // Kirim userId ke method update token
          await _updateFcmToken(token, userId);
        });

        final token = await _fcm.getToken();
        if (token != null) {
          print("FCM Token obtained: $token");
          // Kirim userId ke method update token
          await _updateFcmToken(token, userId);
        }
      }

      // HAPUS SEMUA KODE AwesomeNotifications().initialize DARI SINI
      // Kita pindahkan ke main.dart
    } catch (e) {
      print("Error initializing FCM: $e");
    }
  }

  void startListeningToNotifications(String userId) async {
    if (_isListening) return;
    _isListening = true;
    _isFirstBatch = true; // Reset flag setiap kali listener baru dimulai

    print("NotificationService: Mulai mendengarkan untuk user $userId");

    // Panggil inisialisasi FCM di sini, KARENA kita sudah pasti punya userId
    await _initializeFcmAndToken(userId);

    final now = DateTime.now();
    final thirtyMinutesAgo = now.subtract(Duration(minutes: 30));

    // 4. PERBAIKI QUERY (LEBIH EFISIEN)
    // Kita filter 'recipientIds' di server, bukan di aplikasi
    Query query = _firestore
        .collection('emergency_notifications')
        .where('recipientIds', arrayContains: userId) // <-- INI PENTING
        .where('timestamp', isGreaterThan: thirtyMinutesAgo)
        .orderBy('timestamp', descending: true);

    _notificationSubscription = query.snapshots().listen(
      (snapshot) async {
        // 5. TAMBAHKAN LOGIKA _isFirstBatch
        // Ini untuk mencegah semua pesan 30 menit terakhir
        // memicu notifikasi saat baru login.
        if (_isFirstBatch) {
          print("NotificationService: Menerima batch data awal, diabaikan.");
          _isFirstBatch = false;
          return; // Abaikan data pertama
        }

        print("NotificationService: Menerima perubahan baru...");

        for (var change in snapshot.docChanges) {
          // Hanya tangani notifikasi yang BARU DITAMBAHKAN
          // (setelah listener aktif)
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;

            // 6. HAPUS PENGECEKAN 'recipientIds.contains(currentUser.uid)'
            // Pengecekan sudah dilakukan oleh query Firestore di atas

            final String senderName = data['senderName'] ?? 'Unknown';
            final String message = data['message'] ?? 'Emergency Alert';
            final String notificationId = change.doc.id;
            final List<String> recipientIds =
                List<String>.from(data['recipientIds'] ?? []);

            final uniqueId = DateTime.now().millisecondsSinceEpoch % 100000;

            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: uniqueId,
                channelKey: 'emergency_channel', // Pastikan channel ini ada
                title: 'Emergency Alert from $senderName',
                body: message,
                category: NotificationCategory.Alarm,
                wakeUpScreen: true,
                criticalAlert: true,
                fullScreenIntent: true,
                autoDismissible: false,
                displayOnForeground: true,
                displayOnBackground: true,
                payload: {
                  'notificationId': notificationId,
                  'recipientIds': recipientIds.join(','),
                },
              ),
            );
          }
        }
      },
      onError: (error) {
        print('Error listening to notifications: $error');
        _isListening = false;
      },
    );
  }

  // Update FCM token in Firestore
  Future<void> _updateFcmToken(String token, String userId) async {
    // Kita tidak bisa pakai FirebaseAuth.instance.currentUser di sini
    // karena bisa jadi race condition. Gunakan userId yang di-pass.
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      print("FCM Token updated for user $userId");
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  void dispose() {
    print("NotificationService: Berhenti mendengarkan.");
    _notificationSubscription?.cancel();
    _isListening = false;
  }

  // Send emergency notification
  Future<void> sendEmergencyNotification({
    required String teacherId,
    required String teacherName,
    required List<String> parentIds,
    required String message,
    required String teacherPhone,
  }) async {
    try {
      // Create notification object
      final notification = Notifikasi(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: teacherId,
        recipientIds: parentIds,
        message: message,
        timestamp: DateTime.now(),
        senderName: teacherName,
        teacherPhone: teacherPhone,
      );

      // First, save notification to Firestore
      await _firestore
          .collection('emergency_notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // Get FCM tokens and send notifications
      for (String recipientId in parentIds) {
        try {
          final recipientDoc =
              await _firestore.collection('users').doc(recipientId).get();

          if (recipientDoc.exists) {
            final String? fcmToken = recipientDoc.data()?['fcmToken'];
            if (fcmToken != null) {
              // Prefer external HTTPS sender when configured (Spark plan friendly)
              if (USE_EXTERNAL_FCM_SENDER && EXTERNAL_FCM_ENDPOINT.isNotEmpty) {
                try {
                  final uri = Uri.parse(EXTERNAL_FCM_ENDPOINT);
                  // IMPORTANT: FCM data payload must be a map of string -> string.
                  // Convert any non-string values and arrays to strings to avoid 400 INVALID_ARGUMENT.
                  final recipientIdsStr = parentIds.join(',');
                  final payload = {
                    'to': fcmToken,
                    // Send DATA-ONLY to avoid system notification duplicates on Android background.
                    // Title/body are included inside data for our Awesome handler to display.
                    'data': {
                      'type': 'emergency',
                      'title': 'Emergency Alert from $teacherName',
                      'body': message,
                      'senderName': teacherName,
                      'teacherPhone': teacherPhone,
                      'notificationId': notification.id,
                      'senderId': teacherId,
                      'recipientIds': recipientIdsStr,
                      'message': message,
                    }
                  };

                  final headers = {
                    'Content-Type': 'application/json',
                    if (EXTERNAL_FCM_API_KEY.isNotEmpty)
                      'X-Api-Key': EXTERNAL_FCM_API_KEY,
                  };

                  final resp = await http
                      .post(uri, headers: headers, body: jsonEncode(payload))
                      .timeout(const Duration(seconds: 10));

                  if (resp.statusCode < 200 || resp.statusCode >= 300) {
                    throw Exception(
                        'External sender error: ${resp.statusCode} ${resp.body}');
                  }
                } catch (e) {
                  // As a fallback, try callable if available (won't work on Spark deploy)
                  try {
                    final callable =
                        FirebaseFunctions.instanceFor(region: 'us-central1')
                            .httpsCallable('sendEmergencyNotification');
                    await callable.call({
                      'title': 'Emergency Alert from $teacherName',
                      'body': message,
                      'recipientToken': fcmToken,
                      'teacherName': teacherName,
                      'teacherPhone': teacherPhone,
                      'notificationId': notification.id,
                    });
                  } catch (cfErr) {
                    print('Both external and callable send failed: $cfErr');
                    rethrow;
                  }
                }
              } else {
                // No external endpoint configured: try callable (requires Blaze deploy)
                final callable =
                    FirebaseFunctions.instanceFor(region: 'us-central1')
                        .httpsCallable('sendEmergencyNotification');

                await callable.call({
                  'title': 'Emergency Alert from $teacherName',
                  'body': message,
                  'recipientToken': fcmToken,
                  'teacherName': teacherName,
                  'teacherPhone': teacherPhone,
                  'notificationId': notification.id,
                });
              }

              // Update recipient's last notification time
              await recipientDoc.reference.update({
                'lastNotificationReceived': DateTime.now(),
              });

              print('Notification sent to recipient $recipientId');
            } else {
              print('No FCM token found for recipient $recipientId');
            }
          }
        } catch (e) {
          print('Error sending notification to recipient $recipientId: $e');
        }
      }

      // Show confirmation to sender using AwesomeNotifications
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          channelKey: 'emergency_channel',
          title: 'Emergency Alert Sent',
          body:
              'Your emergency alert has been sent to ${parentIds.length} recipients',
          category: NotificationCategory.Status,
          displayOnBackground: true,
          displayOnForeground: true,
          wakeUpScreen: true,
        ),
      );
    } catch (e) {
      print('Failed to send emergency notification: $e');
      throw Exception('Failed to send emergency notification: $e');
    }
  }

  // Get notification history for a user
  void getNotificationHistory(String userId) {
    try {
      print('Getting notification history for user: $userId'); // Debug log
      _notificationSubscription?.cancel();

      // Set loading state in next frame
      Future.microtask(() {
        if (!context.mounted) return;
        context.read<NotificationState>().setLoading(true);
      });

      print('Creating Firestore query...'); // Debug log

      // Query untuk mengambil semua riwayat notifikasi, diurutkan dari yang terbaru
      _notificationSubscription = _firestore
          .collection('emergency_notifications')
          .where('recipientIds', arrayContains: userId)
          .orderBy('timestamp',
              descending:
                  true) // descending = true berarti dari yang terbaru ke yang lama
          .snapshots()
          .listen(
        (snapshot) {
          if (!context.mounted) return;

          print(
              'Received ${snapshot.docs.length} notifications from Firestore'); // Debug log

          final notifications = snapshot.docs.map((doc) {
            print('Processing document ${doc.id}:'); // Debug log
            print('Document data: ${doc.data()}'); // Debug log
            return Notifikasi.fromMap(doc.data());
          }).toList();

          // Update notifications in next frame
          Future.microtask(() {
            if (!context.mounted) return;
            print(
                'Updating NotificationState with ${notifications.length} notifications'); // Debug log
            context.read<NotificationState>()
              ..setLoading(false)
              ..updateNotifications(notifications);
          });
        },
        onError: (error) {
          if (!context.mounted) return;

          // Handle error in next frame
          Future.microtask(() {
            if (!context.mounted) return;
            context.read<NotificationState>()
              ..setLoading(false)
              ..setError(error.toString());
          });
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      // Handle error in next frame
      Future.microtask(() {
        if (!context.mounted) return;
        context.read<NotificationState>()
          ..setLoading(false)
          ..setError(e.toString());
      });
    }
  }
}
