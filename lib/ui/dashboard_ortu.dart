import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_state.dart';
import 'detail_sos.dart';
import 'riwayat_pesan.dart';
import 'role_select.dart';

class DashboardOrtu extends StatefulWidget {
  final String parentId;
  final String parentName;
  final String parentEmail;

  const DashboardOrtu({
    Key? key,
    required this.parentId,
    required this.parentName,
    required this.parentEmail,
  }) : super(key: key);

  @override
  State<DashboardOrtu> createState() => _DashboardOrtuState();
}

class _DashboardOrtuState extends State<DashboardOrtu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: Color(0xfff5f5f5),
        centerTitle: true,
        title: Text(
          "Wireless Calling System",
          overflow: TextOverflow.visible,
          softWrap: true,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.parentName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                widget.parentEmail,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xff007AFF),
                child: Text(
                  widget.parentName.toString().isNotEmpty
                      ? widget.parentName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Color(0xfffefefe),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                size: 30,
              ),
              title: Text(
                'Riwayat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RiwayatPesan(
                      userId: widget.parentId,
                    ),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.red,
                size: 30,
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => RoleSelect()),
                  (Route<dynamic> route) =>
                      false, // hapus semua halaman sebelumnya
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                child: Text(
                  "Selamat Datang, Bapak/Ibu ${widget.parentName}",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    "Pesan Terbaru",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RiwayatPesan(
                          userId: widget.parentId,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Text(
                      "See All",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Consumer<NotificationState>(
              builder: (context, notificationState, _) {
                if (notificationState.isLoading) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (notificationState.error != null) {
                  return Expanded(
                    child: Center(
                      child: Text('Error: ${notificationState.error}'),
                    ),
                  );
                }

                final notifications = notificationState.notifications;

                return Expanded(
                  child: ListView.builder(
                    itemCount: 5,
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dateTime.day)}/${pad(dateTime.month)}/${dateTime.year} ${pad(dateTime.hour)}:${pad(dateTime.minute)}';
  }
}
