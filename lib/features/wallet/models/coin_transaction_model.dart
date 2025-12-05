import 'package:cloud_firestore/cloud_firestore.dart';

/// Coin Transaction Model - Track all coin transactions
class CoinTransactionModel {
  final String id;
  final String userId;
  final String type; // earned, redeemed, bonus, refund
  final int amount; // Positive for earned, negative for redeemed
  final String source; // order, signup, referral, feedback, game, etc.
  final String? sourceId; // Order ID, Game ID, etc.
  final String description;
  final int balanceAfter; // Balance after this transaction
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Additional info

  CoinTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.source,
    this.sourceId,
    required this.description,
    required this.balanceAfter,
    required this.createdAt,
    this.metadata,
  });

  // From Firestore
  factory CoinTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CoinTransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      amount: data['amount'] ?? 0,
      source: data['source'] ?? '',
      sourceId: data['sourceId'],
      description: data['description'] ?? '',
      balanceAfter: data['balanceAfter'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'amount': amount,
      'source': source,
      'sourceId': sourceId,
      'description': description,
      'balanceAfter': balanceAfter,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  // Helper methods
  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  String get formattedAmount {
    if (isCredit) {
      return '+$amount';
    } else {
      return '$amount'; // Already negative
    }
  }

  String get transactionIcon {
    switch (source) {
      case 'order':
        return isCredit ? '🎁' : '💰';
      case 'signup':
        return '🎉';
      case 'referral':
        return '👥';
      case 'feedback':
        return '⭐';
      case 'game':
        return '🎮';
      case 'refund':
        return '↩️';
      case 'bonus':
        return '🎁';
      default:
        return '💫';
    }
  }

  // Copy with
  CoinTransactionModel copyWith({
    String? id,
    String? userId,
    String? type,
    int? amount,
    String? source,
    String? sourceId,
    String? description,
    int? balanceAfter,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return CoinTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      description: description ?? this.description,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Transaction type constants
class TransactionType {
  static const String earned = 'earned';
  static const String redeemed = 'redeemed';
  static const String bonus = 'bonus';
  static const String refund = 'refund';
}

/// Transaction source constants
class TransactionSource {
  static const String order = 'order';
  static const String signup = 'signup';
  static const String referral = 'referral';
  static const String feedback = 'feedback';
  static const String game = 'game';
  static const String movieNight = 'movie_night';
  static const String event = 'event';
  static const String admin = 'admin';
}
