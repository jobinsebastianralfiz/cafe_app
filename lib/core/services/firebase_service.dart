import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Core Firebase Service - Provides access to Firebase instances
class FirebaseService {
  FirebaseService._();

  // Singleton instance
  static final FirebaseService instance = FirebaseService._();

  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  // Current user
  User? get currentUser => auth.currentUser;
  String? get currentUserId => currentUser?.uid;
  bool get isAuthenticated => currentUser != null;

  // Auth state stream
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Common Firestore queries
  CollectionReference collection(String path) {
    return firestore.collection(path);
  }

  DocumentReference doc(String path) {
    return firestore.doc(path);
  }

  // Storage references
  Reference storageRef(String path) {
    return storage.ref(path);
  }

  // Batch operations
  WriteBatch batch() {
    return firestore.batch();
  }

  // Transactions
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    return firestore.runTransaction<T>(
      transactionHandler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }

  // Timestamp helpers
  Timestamp get serverTimestamp => Timestamp.now();

  static Timestamp fromDateTime(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  static DateTime toDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  // Field value helpers
  static FieldValue get firestoreServerTimestamp => FieldValue.serverTimestamp();
  static FieldValue arrayUnion(List elements) => FieldValue.arrayUnion(elements);
  static FieldValue arrayRemove(List elements) => FieldValue.arrayRemove(elements);
  static FieldValue increment(num value) => FieldValue.increment(value);
  static FieldValue delete() => FieldValue.delete();
}
