import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// User Notifications Stream Provider
final userNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return service.getUserNotificationsStream(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Unread Notifications Stream Provider
final unreadNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return service.getUnreadNotificationsStream(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Unread Count Stream Provider
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(0);
      return service.getUnreadCountStream(user.id);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

// Notification Preferences Provider
final notificationPreferencesProvider = FutureProvider<NotificationPreferences>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  final user = userAsync.valueOrNull;
  if (user == null) return NotificationPreferences();

  return service.getPreferences(user.id);
});

// Notification ViewModel
final notificationViewModelProvider = StateNotifierProvider<NotificationViewModel, NotificationState>((ref) {
  return NotificationViewModel(ref);
});

class NotificationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  NotificationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class NotificationViewModel extends StateNotifier<NotificationState> {
  final Ref _ref;

  NotificationViewModel(this._ref) : super(NotificationState());

  NotificationService get _service => _ref.read(notificationServiceProvider);

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    state = state.copyWith(isLoading: true);

    try {
      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;

      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not logged in');
        return;
      }

      await _service.markAllAsRead(user.id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'All notifications marked as read',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to mark all as read: $e',
      );
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _service.deleteNotification(notificationId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    state = state.copyWith(isLoading: true);

    try {
      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;

      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not logged in');
        return;
      }

      await _service.deleteAllNotifications(user.id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'All notifications deleted',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete notifications: $e',
      );
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    state = state.copyWith(isLoading: true);

    try {
      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;

      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not logged in');
        return;
      }

      await _service.updatePreferences(user.id, preferences);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Preferences updated',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update preferences: $e',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
