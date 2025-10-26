import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_state.dart';
import '../services/notification_service.dart';
import 'detail_sos.dart';

class RiwayatPesan extends StatefulWidget {
  final String userId;

  const RiwayatPesan({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _RiwayatPesanState createState() => _RiwayatPesanState();
}

class _RiwayatPesanState extends State<RiwayatPesan> {
  @override
  void initState() {
    super.initState();
    print('RiwayatPesan initialized with userId: ${widget.userId}');

    // Schedule the notification history fetch for after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Fetching notification history...');
      final notificationService = context.read<NotificationService?>();
      if (notificationService == null) {
        print('ERROR: NotificationService is null!');
        return;
      }
      notificationService.getNotificationHistory(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xfff5f5f5),
        title: const Text(
          'Riwayat Pesan Darurat',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<NotificationState>(
        builder: (context, notificationState, child) {
          print(
              'NotificationState update - Loading: ${notificationState.isLoading}, '
              'Error: ${notificationState.error}, '
              'Notifications count: ${notificationState.notifications.length}');

          if (notificationState.error != null) {
            return Center(
              child: Text('Error: ${notificationState.error}'),
            );
          }

          if (notificationState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications = notificationState.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Text('Belum ada pesan darurat'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailSos(
                          notificationId: notification.id,
                        ),
                      ),
                    );
                  },
                  title: Text(
                    'Pengirim: ${notification.senderName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Pesan: ${notification.message}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waktu Terkirim: ${_formatDateTime(notification.timestamp)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dateTime.day)}/${pad(dateTime.month)}/${dateTime.year} ${pad(dateTime.hour)}:${pad(dateTime.minute)}';
  }
}
