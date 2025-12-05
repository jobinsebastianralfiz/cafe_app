import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/special_model.dart';
import '../services/special_service.dart';

// Special Service Provider
final specialServiceProvider = Provider<SpecialService>((ref) {
  return SpecialService();
});

// Active Specials Stream Provider
final activeSpecialsProvider = StreamProvider<List<SpecialModel>>((ref) {
  final service = ref.watch(specialServiceProvider);
  return service.getActiveSpecialsStream();
});

// All Specials Stream Provider (Admin)
final allSpecialsProvider = StreamProvider<List<SpecialModel>>((ref) {
  final service = ref.watch(specialServiceProvider);
  return service.getAllSpecialsStream();
});

// Today's Specials Stream Provider
final todaySpecialsProvider = StreamProvider<List<SpecialModel>>((ref) {
  final service = ref.watch(specialServiceProvider);
  return service.getTodaySpecialsStream();
});

// Specials by Type Provider
final specialsByTypeProvider = StreamProvider.family<List<SpecialModel>, SpecialType>(
  (ref, type) {
    final service = ref.watch(specialServiceProvider);
    return service.getSpecialsByTypeStream(type);
  },
);

// Special ViewModel
final specialViewModelProvider = StateNotifierProvider<SpecialViewModel, SpecialState>((ref) {
  return SpecialViewModel(ref);
});

class SpecialState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final SpecialModel? validatedPromo;

  SpecialState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.validatedPromo,
  });

  SpecialState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    SpecialModel? validatedPromo,
  }) {
    return SpecialState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      validatedPromo: validatedPromo,
    );
  }
}

class SpecialViewModel extends StateNotifier<SpecialState> {
  final Ref _ref;

  SpecialViewModel(this._ref) : super(SpecialState());

  SpecialService get _service => _ref.read(specialServiceProvider);

  /// Validate a promo code
  Future<bool> validatePromoCode(String promoCode) async {
    if (promoCode.isEmpty) {
      state = state.copyWith(error: 'Please enter a promo code');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final special = await _service.validatePromoCode(promoCode);

      if (special == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid or expired promo code',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        validatedPromo: special,
        successMessage: 'Promo code applied! ${special.discountText}',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to validate promo code: $e',
      );
      return false;
    }
  }

  /// Create a new special (admin)
  Future<bool> createSpecial(SpecialModel special) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.createSpecial(special);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Special created successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create special: $e',
      );
      return false;
    }
  }

  /// Update a special (admin)
  Future<bool> updateSpecial(String specialId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateSpecial(specialId, data);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Special updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update special: $e',
      );
      return false;
    }
  }

  /// Delete a special (admin)
  Future<bool> deleteSpecial(String specialId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.deleteSpecial(specialId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Special deleted',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete special: $e',
      );
      return false;
    }
  }

  /// Toggle special status (admin)
  Future<void> toggleStatus(String specialId, bool isActive) async {
    try {
      await _service.toggleSpecialStatus(specialId, isActive);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update status: $e');
    }
  }

  void clearPromo() {
    state = state.copyWith(validatedPromo: null);
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
