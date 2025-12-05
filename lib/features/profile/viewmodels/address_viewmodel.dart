import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../services/address_service.dart';

/// Provider for AddressService
final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService();
});

/// Provider for user addresses stream
final userAddressesProvider = StreamProvider<List<AddressModel>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final addressService = ref.watch(addressServiceProvider);
  final userId = authService.currentFirebaseUser?.uid;

  if (userId == null) {
    return Stream.value([]);
  }

  return addressService.getAddresses(userId);
});

/// StateNotifier for address management
class AddressViewModel extends StateNotifier<AsyncValue<void>> {
  final AddressService _addressService;
  final String userId;

  AddressViewModel(this._addressService, this.userId)
      : super(const AsyncValue.data(null));

  /// Add a new address
  Future<void> addAddress({
    required String label,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String addressState,
    required String pincode,
    String? landmark,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncValue.loading();

    try {
      final address = AddressModel(
        id: const Uuid().v4(),
        label: label,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: addressState,
        pincode: pincode,
        landmark: landmark,
        isDefault: isDefault,
        latitude: latitude,
        longitude: longitude,
      );

      await _addressService.addAddress(
        userId: userId,
        address: address,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update an existing address
  Future<void> updateAddress(AddressModel address) async {
    state = const AsyncValue.loading();

    try {
      await _addressService.updateAddress(
        userId: userId,
        address: address,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId) async {
    state = const AsyncValue.loading();

    try {
      await _addressService.deleteAddress(
        userId: userId,
        addressId: addressId,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Set an address as default
  Future<void> setDefaultAddress(String addressId) async {
    state = const AsyncValue.loading();

    try {
      await _addressService.setDefaultAddress(
        userId: userId,
        addressId: addressId,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for AddressViewModel
final addressViewModelProvider =
    StateNotifierProvider<AddressViewModel, AsyncValue<void>>((ref) {
  final addressService = ref.watch(addressServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentFirebaseUser?.uid ?? '';

  return AddressViewModel(addressService, userId);
});
