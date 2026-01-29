import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/firebase_constants.dart';
import '../../features/auth/models/user_model.dart';
import 'firebase_service.dart';

/// Seed Service for populating Firebase with sample user roles
/// Use this for development and testing purposes only
class SeedService {
  static final SeedService instance = SeedService._();
  SeedService._();

  final FirebaseAuth _auth = FirebaseService.instance.auth;
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  /// Sample users data for each role
  static final List<Map<String, dynamic>> sampleUsers = [
    // Admin User
    {
      'email': 'admin@cafeapp.com',
      'password': 'Admin@123',
      'name': 'Rajesh Kumar',
      'phone': '+919876543210',
      'role': UserRole.admin,
      'loyaltyTier': 'platinum',
      'coinBalance': 1000,
    },
    // Kitchen Staff
    {
      'email': 'kitchen@cafeapp.com',
      'password': 'Kitchen@123',
      'name': 'Suresh Patel',
      'phone': '+919876543211',
      'role': UserRole.kitchen,
      'loyaltyTier': 'bronze',
      'coinBalance': 0,
    },
    // Waiter
    {
      'email': 'waiter@cafeapp.com',
      'password': 'Waiter@123',
      'name': 'Amit Singh',
      'phone': '+919876543212',
      'role': UserRole.waiter,
      'loyaltyTier': 'bronze',
      'coinBalance': 0,
    },
    // Delivery Rider
    {
      'email': 'delivery@cafeapp.com',
      'password': 'Delivery@123',
      'name': 'Vikram Sharma',
      'phone': '+919876543213',
      'role': UserRole.delivery,
      'loyaltyTier': 'bronze',
      'coinBalance': 0,
    },
    // General Staff
    {
      'email': 'staff@cafeapp.com',
      'password': 'Staff@123',
      'name': 'Priya Verma',
      'phone': '+919876543214',
      'role': UserRole.staff,
      'loyaltyTier': 'bronze',
      'coinBalance': 0,
    },
    // Customer 1 - Bronze tier
    {
      'email': 'customer1@cafeapp.com',
      'password': 'Customer@123',
      'name': 'Ananya Gupta',
      'phone': '+919876543215',
      'role': UserRole.customer,
      'loyaltyTier': 'bronze',
      'coinBalance': 50,


      'addresses': [
        {
          'id': 'addr_1',
          'label': 'Home',
          'addressLine1': '123 MG Road',
          'addressLine2': 'Near Central Mall',
          'city': 'Bangalore',
          'state': 'Karnataka',
          'pincode': '560001',
          'landmark': 'Opposite Metro Station',
          'isDefault': true,
          'latitude': 12.9716,
          'longitude': 77.5946,
        },
      ],
    },
    // Customer 2 - Silver tier
    {
      'email': 'customer2@cafeapp.com',
      'password': 'Customer@123',
      'name': 'Rohan Mehta',
      'phone': '+919876543216',
      'role': UserRole.customer,
      'loyaltyTier': 'silver',
      'coinBalance': 250,
      'addresses': [
        {
          'id': 'addr_2',
          'label': 'Home',
          'addressLine1': '456 Brigade Road',
          'city': 'Bangalore',
          'state': 'Karnataka',
          'pincode': '560025',
          'isDefault': true,
        },
        {
          'id': 'addr_3',
          'label': 'Work',
          'addressLine1': 'Tech Park Tower B',
          'addressLine2': '5th Floor',
          'city': 'Bangalore',
          'state': 'Karnataka',
          'pincode': '560103',
          'landmark': 'Whitefield',
          'isDefault': false,
        },
      ],
    },
    // Customer 3 - Gold tier
    {
      'email': 'customer3@cafeapp.com',
      'password': 'Customer@123',
      'name': 'Sneha Reddy',
      'phone': '+919876543217',
      'role': UserRole.customer,
      'loyaltyTier': 'gold',
      'coinBalance': 500,
    },
  ];

  /// Seed all sample users to Firebase
  /// Creates both Firebase Auth users and Firestore documents
  Future<SeedResult> seedAllUsers() async {
    final result = SeedResult();

    for (final userData in sampleUsers) {
      try {
        final user = await _seedUser(userData);
        result.succeeded.add(user);
        debugPrint('[SeedService] Created user: ${userData['email']} (${userData['role'].displayName})');
      } catch (e) {
        result.failed.add({
          'email': userData['email'],
          'error': e.toString(),
        });
        debugPrint('[SeedService] Failed to create ${userData['email']}: $e');
      }
    }

    return result;
  }

  /// Seed a single user
  Future<UserModel> _seedUser(Map<String, dynamic> userData) async {
    final email = userData['email'] as String;
    final password = userData['password'] as String;

    // Check if user already exists in Firestore (by email)
    final existingQuery = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      debugPrint('[SeedService] User $email already exists, skipping...');
      return UserModel.fromFirestore(existingQuery.docs.first);
    }

    // Create Firebase Auth user
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final authUser = credential.user;
    if (authUser == null) {
      throw Exception('Failed to create auth user for $email');
    }

    // Parse addresses if provided
    final addressesData = userData['addresses'] as List<Map<String, dynamic>>?;
    final addresses = addressesData
            ?.map((addr) => AddressModel.fromMap(addr))
            .toList() ??
        [];

    // Create user model
    final userModel = UserModel(
      id: authUser.uid,
      email: email,
      name: userData['name'] as String,
      phone: userData['phone'] as String,
      role: userData['role'] as UserRole,
      loyaltyTier: userData['loyaltyTier'] as String? ?? 'bronze',
      coinBalance: userData['coinBalance'] as int? ?? 0,
      addresses: addresses,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    // Save to Firestore
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(authUser.uid)
        .set(userModel.toMap());

    // Sign out after creating each user
    await _auth.signOut();

    return userModel;
  }

  /// Seed users directly to Firestore only (without Firebase Auth)
  /// Useful when you want to add test data without creating auth accounts
  Future<SeedResult> seedUsersFirestoreOnly() async {
    final result = SeedResult();

    for (int i = 0; i < sampleUsers.length; i++) {
      final userData = sampleUsers[i];
      try {
        final user = await _seedUserFirestoreOnly(userData, 'seed_user_$i');
        result.succeeded.add(user);
        debugPrint('[SeedService] Created Firestore user: ${userData['email']}');
      } catch (e) {
        result.failed.add({
          'email': userData['email'],
          'error': e.toString(),
        });
        debugPrint('[SeedService] Failed: $e');
      }
    }

    return result;
  }

  Future<UserModel> _seedUserFirestoreOnly(
    Map<String, dynamic> userData,
    String docId,
  ) async {
    final email = userData['email'] as String;

    // Check if already exists
    final existingQuery = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      return UserModel.fromFirestore(existingQuery.docs.first);
    }

    // Parse addresses
    final addressesData = userData['addresses'] as List<Map<String, dynamic>>?;
    final addresses = addressesData
            ?.map((addr) => AddressModel.fromMap(addr))
            .toList() ??
        [];

    final userModel = UserModel(
      id: docId,
      email: email,
      name: userData['name'] as String,
      phone: userData['phone'] as String,
      role: userData['role'] as UserRole,
      loyaltyTier: userData['loyaltyTier'] as String? ?? 'bronze',
      coinBalance: userData['coinBalance'] as int? ?? 0,
      addresses: addresses,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(docId)
        .set(userModel.toMap());

    return userModel;
  }

  /// Delete all seeded users (cleanup)
  Future<void> cleanupSeededUsers() async {
    for (final userData in sampleUsers) {
      try {
        final email = userData['email'] as String;

        // Find user in Firestore
        final query = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.delete();
          debugPrint('[SeedService] Deleted Firestore doc for $email');
        }
      } catch (e) {
        debugPrint('[SeedService] Cleanup error: $e');
      }
    }
  }

  /// Get all sample user credentials for testing
  static List<Map<String, String>> getTestCredentials() {
    return sampleUsers.map((user) {
      return {
        'email': user['email'] as String,
        'password': user['password'] as String,
        'role': (user['role'] as UserRole).displayName,
      };
    }).toList();
  }
}

/// Result of seeding operation
class SeedResult {
  final List<UserModel> succeeded = [];
  final List<Map<String, dynamic>> failed = [];

  bool get hasErrors => failed.isNotEmpty;
  int get totalSucceeded => succeeded.length;
  int get totalFailed => failed.length;

  @override
  String toString() {
    return 'SeedResult: $totalSucceeded succeeded, $totalFailed failed';
  }
}