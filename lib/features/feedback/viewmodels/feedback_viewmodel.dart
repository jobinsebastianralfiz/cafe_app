import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';

// Feedback Service Provider
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

// Menu Item Reviews Stream Provider
final menuItemReviewsProvider = StreamProvider.family<List<ReviewModel>, String>(
  (ref, menuItemId) {
    final service = ref.watch(feedbackServiceProvider);
    return service.getMenuItemReviewsStream(menuItemId);
  },
);

// User Reviews Stream Provider
final userReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  final service = ref.watch(feedbackServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return service.getUserReviewsStream(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Check if user has reviewed item
final hasUserReviewedProvider = FutureProvider.family<bool, String>(
  (ref, menuItemId) async {
    final service = ref.watch(feedbackServiceProvider);
    final userAsync = ref.watch(currentUserProvider);

    final user = userAsync.valueOrNull;
    if (user == null) return false;

    return service.hasUserReviewed(user.id, menuItemId);
  },
);

// Check if order has feedback
final hasOrderFeedbackProvider = FutureProvider.family<bool, String>(
  (ref, orderId) async {
    final service = ref.watch(feedbackServiceProvider);
    return service.hasOrderFeedback(orderId);
  },
);

// Feedback ViewModel
final feedbackViewModelProvider = StateNotifierProvider<FeedbackViewModel, FeedbackState>((ref) {
  return FeedbackViewModel(ref);
});

class FeedbackState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  FeedbackState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  FeedbackState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return FeedbackState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class FeedbackViewModel extends StateNotifier<FeedbackState> {
  final Ref _ref;

  FeedbackViewModel(this._ref) : super(FeedbackState());

  FeedbackService get _service => _ref.read(feedbackServiceProvider);

  /// Submit a review for a menu item
  Future<bool> submitReview({
    required String menuItemId,
    required String menuItemName,
    required double rating,
    String? comment,
    List<String> photos = const [],
    String? orderId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;

      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Please login to submit a review');
        return false;
      }

      // Check if already reviewed
      final hasReviewed = await _service.hasUserReviewed(user.id, menuItemId);
      if (hasReviewed) {
        state = state.copyWith(
          isLoading: false,
          error: 'You have already reviewed this item',
        );
        return false;
      }

      final review = ReviewModel(
        id: '',
        userId: user.id,
        userName: user.name,
        userPhoto: user.profilePhoto,
        menuItemId: menuItemId,
        menuItemName: menuItemName,
        orderId: orderId,
        rating: rating,
        comment: comment,
        photos: photos,
        isVerifiedPurchase: orderId != null,
        createdAt: DateTime.now(),
      );

      await _service.createReview(review);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Review submitted successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit review: $e',
      );
      return false;
    }
  }

  /// Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required double rating,
    String? comment,
    List<String>? photos,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateReview(reviewId, {
        'rating': rating,
        'comment': comment,
        if (photos != null) 'photos': photos,
      });

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Review updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update review: $e',
      );
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId, String menuItemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.deleteReview(reviewId, menuItemId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Review deleted',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete review: $e',
      );
      return false;
    }
  }

  /// Mark a review as helpful
  Future<void> markAsHelpful(String reviewId) async {
    try {
      await _service.markAsHelpful(reviewId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark as helpful');
    }
  }

  /// Submit order feedback
  Future<bool> submitOrderFeedback({
    required String orderId,
    required String orderNumber,
    required double overallRating,
    double foodRating = 0,
    double serviceRating = 0,
    double deliveryRating = 0,
    String? comment,
    List<String> tags = const [],
    bool wouldRecommend = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;

      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Please login to submit feedback');
        return false;
      }

      // Check if already submitted
      final hasFeedback = await _service.hasOrderFeedback(orderId);
      if (hasFeedback) {
        state = state.copyWith(
          isLoading: false,
          error: 'You have already submitted feedback for this order',
        );
        return false;
      }

      final feedback = OrderFeedbackModel(
        id: '',
        orderId: orderId,
        orderNumber: orderNumber,
        userId: user.id,
        userName: user.name,
        overallRating: overallRating,
        foodRating: foodRating,
        serviceRating: serviceRating,
        deliveryRating: deliveryRating,
        comment: comment,
        tags: tags,
        wouldRecommend: wouldRecommend,
        createdAt: DateTime.now(),
      );

      await _service.createOrderFeedback(feedback);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Thank you for your feedback!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit feedback: $e',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
