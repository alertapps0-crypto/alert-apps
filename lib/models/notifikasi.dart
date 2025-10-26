import 'package:cloud_firestore/cloud_firestore.dart';

class Notifikasi {
  final String id;
  final String senderId; // Teacher's ID
  final List<String> recipientIds; // List of parent IDs
  final String message;
  final DateTime timestamp;
  final String senderName;
  final String teacherPhone;

  Notifikasi({
    required this.id,
    required this.senderId,
    required this.recipientIds,
    required this.message,
    required this.timestamp,
    required this.senderName,
    required this.teacherPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientIds': recipientIds,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'senderName': senderName,
      'teacherPhone': teacherPhone,
    };
  }

  factory Notifikasi.fromMap(Map<String, dynamic> map) {
    // Handle berbagai format timestamp dari Firestore
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else {
        return DateTime.now(); // fallback jika format tidak dikenali
      }
    }

    return Notifikasi(
      id: map['id'],
      senderId: map['senderId'],
      recipientIds: List<String>.from(map['recipientIds']),
      message: map['message'],
      timestamp: parseTimestamp(map['timestamp']),
      senderName: map['senderName'],
      teacherPhone: map['teacherPhone'],
    );
  }
}
