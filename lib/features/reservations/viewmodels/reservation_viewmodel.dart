import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';

// Reservation Service Provider
final reservationServiceProvider = Provider<ReservationService>((ref) {
  return ReservationService();
});

// Tables Stream Provider
final tablesProvider = StreamProvider<List<TableModel>>((ref) {
  final service = ref.watch(reservationServiceProvider);
  return service.getTablesStream();
});

// User Reservations Stream Provider
final userReservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  final service = ref.watch(reservationServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return service.getUserReservationsStream(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Upcoming Reservations Stream Provider
final upcomingReservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  final service = ref.watch(reservationServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return service.getUpcomingReservationsStream(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Past Reservations Stream Provider
final pastReservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  final service = ref.watch(reservationServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return service.getPastReservationsStream(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Pending Reservations Stream Provider (Admin)
final pendingReservationsProvider = StreamProvider<List<ReservationModel>>((ref) {
  final service = ref.watch(reservationServiceProvider);
  return service.getPendingReservationsStream();
});

// Selected Date Provider for Booking
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

// Selected Time Slot Provider for Booking
final selectedTimeSlotProvider = StateProvider<String?>((ref) => null);

// Party Size Provider for Booking
final partySizeProvider = StateProvider<int>((ref) => 2);

// Available Time Slots Provider
final availableTimeSlotsProvider = FutureProvider<List<TimeSlotModel>>((ref) async {
  final service = ref.watch(reservationServiceProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final partySize = ref.watch(partySizeProvider);

  if (selectedDate == null) {
    return TimeSlotModel.getDefaultSlots();
  }

  return service.getAvailableTimeSlots(selectedDate, partySize);
});

// Reservations by Date Provider (Admin)
final reservationsByDateProvider = StreamProvider.family<List<ReservationModel>, DateTime>(
  (ref, date) {
    final service = ref.watch(reservationServiceProvider);
    return service.getReservationsByDateStream(date);
  },
);

// Reservation ViewModel
final reservationViewModelProvider = StateNotifierProvider<ReservationViewModel, ReservationState>((ref) {
  return ReservationViewModel(ref);
});

class ReservationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  ReservationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ReservationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ReservationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class ReservationViewModel extends StateNotifier<ReservationState> {
  final Ref _ref;

  ReservationViewModel(this._ref) : super(ReservationState());

  ReservationService get _service => _ref.read(reservationServiceProvider);

  /// Create a new reservation
  Future<String?> createReservation({
    required DateTime date,
    required String timeSlot,
    required int partySize,
    String? specialRequests,
    String? occasion,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;

      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Please login to make a reservation');
        return null;
      }

      // Check availability
      final isAvailable = await _service.isTimeSlotAvailable(date, timeSlot, partySize);
      if (!isAvailable) {
        state = state.copyWith(
          isLoading: false,
          error: 'Sorry, this time slot is no longer available',
        );
        return null;
      }

      final reservation = ReservationModel(
        id: '',
        userId: user.id,
        userName: user.name,
        userPhone: user.phone,
        userEmail: user.email,
        reservationDate: date,
        timeSlot: timeSlot,
        partySize: partySize,
        specialRequests: specialRequests,
        occasion: occasion,
        createdAt: DateTime.now(),
      );

      final reservationId = await _service.createReservation(reservation);

      // Reset selections
      _ref.read(selectedDateProvider.notifier).state = null;
      _ref.read(selectedTimeSlotProvider.notifier).state = null;
      _ref.read(partySizeProvider.notifier).state = 2;

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Reservation created successfully!',
      );

      return reservationId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create reservation: $e',
      );
      return null;
    }
  }

  /// Cancel a reservation
  Future<bool> cancelReservation(String reservationId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.cancelReservation(reservationId, reason: reason);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Reservation cancelled successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel reservation: $e',
      );
      return false;
    }
  }

  /// Confirm a reservation (Admin)
  Future<bool> confirmReservation(String reservationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateReservationStatus(
        reservationId,
        ReservationStatus.confirmed,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Reservation confirmed',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to confirm reservation: $e',
      );
      return false;
    }
  }

  /// Assign table to reservation (Admin)
  Future<bool> assignTable(
    String reservationId,
    String tableId,
    String tableName,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.assignTable(reservationId, tableId, tableName);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Table assigned successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to assign table: $e',
      );
      return false;
    }
  }

  /// Mark reservation as seated (Admin)
  Future<bool> markAsSeated(String reservationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateReservationStatus(
        reservationId,
        ReservationStatus.seated,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Guest marked as seated',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update status: $e',
      );
      return false;
    }
  }

  /// Mark reservation as completed (Admin)
  Future<bool> markAsCompleted(String reservationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateReservationStatus(
        reservationId,
        ReservationStatus.completed,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Reservation completed',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update status: $e',
      );
      return false;
    }
  }

  /// Mark as no-show (Admin)
  Future<bool> markAsNoShow(String reservationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateReservationStatus(
        reservationId,
        ReservationStatus.noShow,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Marked as no-show',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update status: $e',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
