import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

/// Feedback Service - Handles all feedback-related Firestore operations
class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reviewsRef => _firestore.collection('reviews');
  CollectionReference get _orderFeedbackRef => _firestore.collection('order_feedback');
  CollectionReference get _menuItemsRef => _firestore.collection('menu_items');

  // ==================== REVIEWS ====================

  /// Create a new review
  Future<String> createReview(ReviewModel review) async {
    final docRef = await _reviewsRef.add(review.toMap());

    // Update menu item rating
    await _updateMenuItemRating(review.menuItemId);

    return docRef.id;
  }

  /// Get reviews for a menu item
  Stream<List<ReviewModel>> getMenuItemReviewsStream(String menuItemId) {
    return _reviewsRef
        .where('menuItemId', isEqualTo: menuItemId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  /// Get reviews by a user
  Stream<List<ReviewModel>> getUserReviewsStream(String userId) {
    return _reviewsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  /// Get top reviews for a menu item
  Future<List<ReviewModel>> getTopReviews(String menuItemId, {int limit = 5}) async {
    final snapshot = await _reviewsRef
        .where('menuItemId', isEqualTo: menuItemId)
        .orderBy('helpfulCount', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }

  /// Update review
  Future<void> updateReview(String reviewId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _reviewsRef.doc(reviewId).update(data);
  }

  /// Delete review
  Future<void> deleteReview(String reviewId, String menuItemId) async {
    await _reviewsRef.doc(reviewId).delete();
    await _updateMenuItemRating(menuItemId);
  }

  /// Mark review as helpful
  Future<void> markAsHelpful(String reviewId) async {
    await _reviewsRef.doc(reviewId).update({
      'helpfulCount': FieldValue.increment(1),
    });
  }

  /// Check if user has reviewed an item
  Future<bool> hasUserReviewed(String userId, String menuItemId) async {
    final snapshot = await _reviewsRef
        .where('userId', isEqualTo: userId)
        .where('menuItemId', isEqualTo: menuItemId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get user's review for an item
  Future<ReviewModel?> getUserReviewForItem(String userId, String menuItemId) async {
    final snapshot = await _reviewsRef
        .where('userId', isEqualTo: userId)
        .where('menuItemId', isEqualTo: menuItemId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ReviewModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  /// Update menu item rating based on reviews
  Future<void> _updateMenuItemRating(String menuItemId) async {
    final snapshot = await _reviewsRef
        .where('menuItemId', isEqualTo: menuItemId)
        .get();

    if (snapshot.docs.isEmpty) {
      await _menuItemsRef.doc(menuItemId).update({
        'averageRating': 0.0,
        'totalRatings': 0,
      });
      return;
    }

    double totalRating = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRating += (data['rating'] ?? 0).toDouble();
    }

    final averageRating = totalRating / snapshot.docs.length;

    await _menuItemsRef.doc(menuItemId).update({
      'averageRating': averageRating,
      'totalRatings': snapshot.docs.length,
    });
  }

  // ==================== ORDER FEEDBACK ====================

  /// Create order feedback
  Future<String> createOrderFeedback(OrderFeedbackModel feedback) async {
    final docRef = await _orderFeedbackRef.add(feedback.toMap());
    return docRef.id;
  }

  /// Get order feedback
  Future<OrderFeedbackModel?> getOrderFeedback(String orderId) async {
    final snapshot = await _orderFeedbackRef
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return OrderFeedbackModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  /// Check if user has given feedback for an order
  Future<bool> hasOrderFeedback(String orderId) async {
    final snapshot = await _orderFeedbackRef
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get all order feedback for a user
  Stream<List<OrderFeedbackModel>> getUserOrderFeedbackStream(String userId) {
    return _orderFeedbackRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderFeedbackModel.fromFirestore(doc))
            .toList());
  }

  /// Get recent feedback (admin)
  Stream<List<OrderFeedbackModel>> getRecentFeedbackStream({int limit = 50}) {
    return _orderFeedbackRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderFeedbackModel.fromFirestore(doc))
            .toList());
  }

  /// Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStats() async {
    final snapshot = await _orderFeedbackRef.get();

    if (snapshot.docs.isEmpty) {
      return {
        'totalFeedback': 0,
        'averageRating': 0.0,
        'recommendationRate': 0.0,
      };
    }

    double totalRating = 0;
    int recommendCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRating += (data['overallRating'] ?? 0).toDouble();
      if (data['wouldRecommend'] == true) recommendCount++;
    }

    return {
      'totalFeedback': snapshot.docs.length,
      'averageRating': totalRating / snapshot.docs.length,
      'recommendationRate': (recommendCount / snapshot.docs.length) * 100,
    };
  }
}
