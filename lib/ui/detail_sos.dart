import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/notifikasi.dart';

class DetailSos extends StatelessWidget {
  final String notificationId;

  const DetailSos({
    Key? key,
    required this.notificationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: Color(0xfff5f5f5),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('emergency_notifications')
            .doc(notificationId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Notification not found'));
          }

          final notification =
              Notifikasi.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "SOS dari ${notification.senderName}",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xfffefefe),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(notification.timestamp),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xfffefefe),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    TextButton(
                      onPressed: () async {
                        String phoneNumber = notification.teacherPhone;

                        // Pesan otomatis (opsional)
                        String message = 'Halo, saya ingin bertanya sesuatu.';

                        // Meng-encode pesan agar aman untuk URL
                        String encodedMessage = Uri.encodeComponent(message);

                        // Membuat URL wa.me
                        // Format: https://wa.me/NOMOR?text=PESAN
                        final Uri waUrl = Uri.parse(
                          'https://wa.me/62$phoneNumber?text=$encodedMessage',
                        );

                        try {
                          // Mencoba membuka URL
                          // mode: LaunchMode.externalApplication digunakan agar
                          // tautan dibuka di aplikasi WhatsApp, bukan di browser internal.
                          if (!await launchUrl(waUrl,
                              mode: LaunchMode.externalApplication)) {
                            // Jika gagal (misal: WhatsApp tidak terinstal)
                            throw 'Tidak dapat membuka $waUrl';
                          }
                        } catch (e) {
                          // Anda bisa menampilkan SnackBar atau dialog di sini
                          debugPrint('Error: $e');
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xff007AFF),
                        foregroundColor: Color(0xfffefefe),
                        fixedSize:
                            Size(MediaQuery.of(context).size.width * 0.9, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 15,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/icons/whatsapp.png'),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Balas Via WhatsApp",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
