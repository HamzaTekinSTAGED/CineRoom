import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Register user and add to Firestore
  Future<void> createUser({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      if (nickname.isEmpty) {
        throw Exception("Nickname is required.");
      }

      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        await _addUserToFirestore(user, nickname);
      }
    } catch (e) {
      throw Exception("Failed to register user: $e");
    }
  }

  // Login with email and password
  Future<void> signIn({required String email, required String password}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Get current user's UID
  String? getUserId() {
    return currentUser?.uid;
  }

  // Private method to add user information to Firestore
  Future<void> _addUserToFirestore(User user, String nickname) async {
    try {
      await _firestore.collection('Users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'nickname': nickname,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Failed to add user to Firestore: $e");
    }
  }
}
