import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_messaging_handler.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email & password
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) throw Exception('Registration failed');

      // Create user model
      final UserModel userModel = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        role: 'parent',
        fcmToken: null,
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login with email & password
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login for email: $email');
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) throw Exception('Login Gagal!');
      print('Firebase Auth successful for user: ${user.uid}');

      print('Fetching user data from Firestore');
      // Get user data from Firestore
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        print('User document not found in Firestore');
        throw Exception('Data user tidak ditemukan');
      }
      print('Firestore document exists');

      // Get the existing data
      final data = doc.data();
      print('Raw Firestore data type: ${data.runtimeType}');
      print('Raw Firestore data: $data');

      if (data == null) {
        throw Exception('Data user kosong');
      }

      // Initialize Firebase Messaging Handler
      final messagingHandler = FirebaseMessagingHandler();
      await messagingHandler.initialize();

      // Create a new Map with only the fields we need and explicit type checking
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'name': data['name'] is String
            ? data['name']
            : data['name']?.toString() ?? '',
        'phoneNumber': data['phoneNumber'] is String
            ? data['phoneNumber']
            : data['phoneNumber']?.toString() ?? '',
        'role': data['role'] is String
            ? data['role']
            : data['role']?.toString() ?? '',
        'fcmToken':
            data['fcmToken'], // Use existing token, will be updated by handler
      };

      // Token will be updated by FirebaseMessagingHandler after initialization
      print(
          "User data prepared for ${user.uid}. FCM token will be updated by messaging handler.");

      return UserModel.fromMap(userData);
    } catch (e) {
      print('Login error: $e'); // Debug print
      throw Exception('Login Gagal: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Remove FCM token from Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': null,
        });
      }

      final messagingHandler = FirebaseMessagingHandler();
      messagingHandler.stopNotificationListener();
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      throw Exception('Logout Gagal: $e');
    }
  }
}
