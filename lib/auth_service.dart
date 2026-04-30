import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<String?> signUp(String email, String password, String confirmPassword) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return 'Email and password cannot be empty';
      }
      if (password != confirmPassword) {
        return 'Passwords do not match';
      }
      if (password.length < 6) {
        return 'Password must be at least 6 characters';
      }

      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return 'Email and password cannot be empty';
      }

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Email not found';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password';
      }
      return e.message ?? 'An error occurred';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return 'Email cannot be empty';
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }

  Future<String?> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }
}
