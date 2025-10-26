import 'package:flutter/foundation.dart';
import '../models/notifikasi.dart';

class NotificationState extends ChangeNotifier {
  List<Notifikasi> _notifications = [];
  String? _error;
  bool _isLoading = false;

  List<Notifikasi> get notifications => _notifications;
  String? get error => _error;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void updateNotifications(List<Notifikasi> newNotifications) {
    _notifications = newNotifications;
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
