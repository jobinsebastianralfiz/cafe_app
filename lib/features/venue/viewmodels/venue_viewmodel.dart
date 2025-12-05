import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/venue_settings_model.dart';
import '../services/venue_service.dart';

/// Venue Service Provider
final venueServiceProvider = Provider<VenueService>((ref) {
  return VenueService();
});

/// Stream venue settings (real-time)
final venueSettingsProvider =
    StreamProvider.autoDispose<VenueSettingsModel?>((ref) {
  final venueService = ref.watch(venueServiceProvider);
  return venueService.streamVenueSettings();
});

/// Check if venue is open now
final isVenueOpenNowProvider = Provider.autoDispose<bool>((ref) {
  final venueSettings = ref.watch(venueSettingsProvider);
  return venueSettings.when(
    data: (settings) {
      if (settings == null) return false;
      final venueService = ref.watch(venueServiceProvider);
      return venueService.isOpenNow(settings);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Venue status message
final venueStatusMessageProvider = Provider.autoDispose<String>((ref) {
  final venueSettings = ref.watch(venueSettingsProvider);
  return venueSettings.when(
    data: (settings) {
      if (settings == null) return 'Loading venue status...';
      return settings.statusMessage;
    },
    loading: () => 'Loading venue status...',
    error: (_, __) => 'Unable to load venue status',
  );
});

/// Venue ViewModel - Manages venue settings
class VenueViewModel extends StateNotifier<AsyncValue<void>> {
  final VenueService _venueService;

  VenueViewModel(this._venueService) : super(const AsyncValue.data(null));

  /// Update venue status (admin only)
  Future<void> updateVenueStatus({
    required bool isOpen,
    required String status,
    String? closedReason,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _venueService.updateVenueStatus(
        isOpen: isOpen,
        status: status,
        closedReason: closedReason,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update accepting orders (admin only)
  Future<void> updateAcceptingOrders({
    required bool acceptingOrders,
    required bool acceptingDelivery,
    required bool acceptingDineIn,
    required bool acceptingTakeaway,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _venueService.updateAcceptingOrders(
        acceptingOrders: acceptingOrders,
        acceptingDelivery: acceptingDelivery,
        acceptingDineIn: acceptingDineIn,
        acceptingTakeaway: acceptingTakeaway,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Initialize default settings
  Future<void> initializeDefaultSettings() async {
    try {
      await _venueService.initializeDefaultSettings();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Venue ViewModel Provider
final venueViewModelProvider =
    StateNotifierProvider<VenueViewModel, AsyncValue<void>>((ref) {
  final venueService = ref.watch(venueServiceProvider);
  return VenueViewModel(venueService);
});
