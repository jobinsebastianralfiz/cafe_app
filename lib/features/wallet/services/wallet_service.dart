import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../models/coin_transaction_model.dart';

/// Wallet Service - Manages coin transactions
class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reference to transactions collection
  CollectionReference get _transactionsRef =>
      _firestore.collection(FirebaseConstants.coinsCollection);

  // Get reference to users collection
  CollectionReference get _usersRef =>
      _firestore.collection(FirebaseConstants.usersCollection);

  /// Add coins to user wallet
  Future<String> addCoins({
    required String userId,
    required int amount,
    required String source,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get current balance
      final userDoc = await _usersRef.doc(userId).get();
      final currentBalance =
          (userDoc.data() as Map<String, dynamic>)['coinBalance'] ?? 0;
      final newBalance = currentBalance + amount;

      // Create transaction
      final transaction = CoinTransactionModel(
        id: '', // Will be set by Firestore
        userId: userId,
        type: TransactionType.earned,
        amount: amount,
        source: source,
        sourceId: sourceId,
        description: description,
        balanceAfter: newBalance,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Use Firestore transaction to ensure atomicity
      final transactionId = await _firestore.runTransaction((txn) async {
        // Update user balance
        txn.update(_usersRef.doc(userId), {
          'coinBalance': newBalance,
        });

        // Add transaction record
        final transactionRef = _transactionsRef.doc();
        txn.set(transactionRef, transaction.toMap());

        return transactionRef.id;
      });

      return transactionId;
    } catch (e) {
      throw Exception('Failed to add coins: $e');
    }
  }

  /// Deduct coins from user wallet
  Future<String> deductCoins({
    required String userId,
    required int amount,
    required String source,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get current balance
      final userDoc = await _usersRef.doc(userId).get();
      final currentBalance =
          (userDoc.data() as Map<String, dynamic>)['coinBalance'] ?? 0;

      // Check if sufficient balance
      if (currentBalance < amount) {
        throw Exception('Insufficient coin balance');
      }

      final newBalance = currentBalance - amount;

      // Create transaction (negative amount)
      final transaction = CoinTransactionModel(
        id: '',
        userId: userId,
        type: TransactionType.redeemed,
        amount: -amount, // Negative for deduction
        source: source,
        sourceId: sourceId,
        description: description,
        balanceAfter: newBalance,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Use Firestore transaction to ensure atomicity
      final transactionId = await _firestore.runTransaction((txn) async {
        // Update user balance
        txn.update(_usersRef.doc(userId), {
          'coinBalance': newBalance,
        });

        // Add transaction record
        final transactionRef = _transactionsRef.doc();
        txn.set(transactionRef, transaction.toMap());

        return transactionRef.id;
      });

      return transactionId;
    } catch (e) {
      throw Exception('Failed to deduct coins: $e');
    }
  }

  /// Refund coins to user wallet
  Future<String> refundCoins({
    required String userId,
    required int amount,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await addCoins(
        userId: userId,
        amount: amount,
        source: TransactionSource.order,
        description: description,
        sourceId: sourceId,
        metadata: {'type': 'refund', ...?metadata},
      );
    } catch (e) {
      throw Exception('Failed to refund coins: $e');
    }
  }

  /// Give bonus coins
  Future<String> giveBonusCoins({
    required String userId,
    required int amount,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await addCoins(
        userId: userId,
        amount: amount,
        source: TransactionSource.admin,
        description: description,
        sourceId: sourceId,
        metadata: {'type': 'bonus', ...?metadata},
      );
    } catch (e) {
      throw Exception('Failed to give bonus coins: $e');
    }
  }

  /// Get user transactions
  Future<List<CoinTransactionModel>> getUserTransactions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => CoinTransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  /// Stream user transactions (real-time)
  Stream<List<CoinTransactionModel>> streamUserTransactions(
    String userId, {
    int limit = 50,
  }) {
    return _transactionsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoinTransactionModel.fromFirestore(doc))
            .toList());
  }

  /// Get transactions by type
  Future<List<CoinTransactionModel>> getTransactionsByType(
    String userId,
    String type, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => CoinTransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions by type: $e');
    }
  }

  /// Get transactions by source
  Future<List<CoinTransactionModel>> getTransactionsBySource(
    String userId,
    String source, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .where('source', isEqualTo: source)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => CoinTransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions by source: $e');
    }
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics(
      String userId) async {
    try {
      final transactions = await getUserTransactions(userId, limit: 1000);

      final totalEarned = transactions
          .where((t) => t.isCredit)
          .fold<int>(0, (total, t) => total + t.amount);

      final totalRedeemed = transactions
          .where((t) => t.isDebit)
          .fold<int>(0, (total, t) => total + t.amount.abs());

      final transactionsBySource = <String, int>{};
      for (final transaction in transactions) {
        transactionsBySource[transaction.source] =
            (transactionsBySource[transaction.source] ?? 0) + 1;
      }

      final transactionsByType = <String, int>{};
      for (final transaction in transactions) {
        transactionsByType[transaction.type] =
            (transactionsByType[transaction.type] ?? 0) + 1;
      }

      return {
        'totalTransactions': transactions.length,
        'totalEarned': totalEarned,
        'totalRedeemed': totalRedeemed,
        'transactionsBySource': transactionsBySource,
        'transactionsByType': transactionsByType,
      };
    } catch (e) {
      throw Exception('Failed to get transaction statistics: $e');
    }
  }

  /// Check if user has sufficient balance
  Future<bool> hasSufficientBalance(String userId, int amount) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      final currentBalance =
          (userDoc.data() as Map<String, dynamic>)['coinBalance'] ?? 0;
      return currentBalance >= amount;
    } catch (e) {
      throw Exception('Failed to check balance: $e');
    }
  }

  /// Get current balance
  Future<int> getCurrentBalance(String userId) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      return (userDoc.data() as Map<String, dynamic>)['coinBalance'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get current balance: $e');
    }
  }
}
