import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/constants/firebase_constants.dart';
import '../models/user_model.dart';

/// Authentication Service with Role-Based Access Control
class AuthService {
  final FirebaseAuth _auth = FirebaseService.instance.auth;
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user data with role
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) return null;

      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Stream current user data
  Stream<UserModel?> get userStream {
    return authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      return await getCurrentUser();
    });
  }

  // Sign up with email and password (default role: customer)
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    UserRole role = UserRole.customer, // Default to customer
  }) async {
    try {
      debugPrint('[AuthService] Creating Firebase Auth user...');
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }
      debugPrint('[AuthService] Firebase Auth user created: ${user.uid}');

      // Create user document in Firestore
      final userModel = UserModel(
        id: user.uid,
        email: email,
        name: name,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      debugPrint('[AuthService] Writing user to Firestore...');
      debugPrint('[AuthService] User data: ${userModel.toMap()}');

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      debugPrint('[AuthService] User written to Firestore successfully!');
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      debugPrint('[AuthService] Error: $e');
      debugPrint('[AuthService] Stack: $stackTrace');
      throw Exception('Signup failed: $e');
    }
  }

  // Sign in with email and password (with role check)
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Login failed');
      }

      // Get user data with role from Firestore
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userModel = UserModel.fromFirestore(userDoc);

      // Update last active timestamp
      await _updateLastActive(user.uid);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Sign in with phone number (Firebase Phone Auth)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(FirebaseAuthException error) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw Exception('Phone verification failed: $e');
    }
  }

  // Verify OTP and sign in
  Future<UserModel> verifyOTPAndSignIn({
    required String verificationId,
    required String otp,
    required String name,
    required String phone,
    UserRole role = UserRole.customer,
  }) async {
    try {
      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Sign in failed');
      }

      // Check if user document exists
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // User exists, return existing data
        return UserModel.fromFirestore(userDoc);
      } else {
        // New user, create document
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: name,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Update user role (Admin only)
  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({'role': newRole.value});
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Check if user has specific role
  Future<bool> hasRole(UserRole role) async {
    try {
      final user = await getCurrentUser();
      return user?.role == role;
    } catch (e) {
      return false;
    }
  }

  // Check if user has admin access
  Future<bool> hasAdminAccess() async {
    try {
      final user = await getCurrentUser();
      return user?.hasAdminAccess ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if user has staff access
  Future<bool> hasStaffAccess() async {
    try {
      final user = await getCurrentUser();
      return user?.hasStaffAccess ?? false;
    } catch (e) {
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profilePhoto,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (profilePhoto != null) updateData['profilePhoto'] = profilePhoto;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) throw Exception('No user signed in');

      // Delete user document from Firestore
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .delete();

      // Delete Firebase Auth user
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Private helper: Update last active timestamp
  Future<void> _updateLastActive(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Private helper: Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address. Please check and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-verification-code':
        return 'Invalid OTP code. Please try again.';
      case 'invalid-verification-id':
        return 'Verification failed. Please request a new code.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }
}
