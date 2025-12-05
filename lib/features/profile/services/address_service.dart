import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';

/// Service for managing user addresses
class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new address to user's profile
  Future<void> addAddress({
    required String userId,
    required AddressModel address,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final addresses = (userData['addresses'] as List<dynamic>?)
              ?.map((addr) => AddressModel.fromMap(addr as Map<String, dynamic>))
              .toList() ??
          [];

      // If this is the first address or marked as default, make it default
      final isOnlyAddress = addresses.isEmpty;
      final addressToAdd = address.copyWith(
        isDefault: address.isDefault || isOnlyAddress,
      );

      // If new address is default, unset other defaults
      if (addressToAdd.isDefault) {
        addresses.forEach((addr) {
          if (addr.isDefault) {
            final index = addresses.indexOf(addr);
            addresses[index] = addr.copyWith(isDefault: false);
          }
        });
      }

      addresses.add(addressToAdd);

      await userRef.update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  /// Update an existing address
  Future<void> updateAddress({
    required String userId,
    required AddressModel address,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final addresses = (userData['addresses'] as List<dynamic>?)
              ?.map((addr) => AddressModel.fromMap(addr as Map<String, dynamic>))
              .toList() ??
          [];

      final index = addresses.indexWhere((addr) => addr.id == address.id);
      if (index == -1) {
        throw Exception('Address not found');
      }

      // If updating to default, unset other defaults
      if (address.isDefault) {
        for (var i = 0; i < addresses.length; i++) {
          if (i != index && addresses[i].isDefault) {
            addresses[i] = addresses[i].copyWith(isDefault: false);
          }
        }
      }

      addresses[index] = address;

      await userRef.update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  /// Delete an address
  Future<void> deleteAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final addresses = (userData['addresses'] as List<dynamic>?)
              ?.map((addr) => AddressModel.fromMap(addr as Map<String, dynamic>))
              .toList() ??
          [];

      addresses.removeWhere((addr) => addr.id == addressId);

      // If we deleted the default address and there are still addresses, make the first one default
      if (addresses.isNotEmpty && !addresses.any((addr) => addr.isDefault)) {
        addresses[0] = addresses[0].copyWith(isDefault: true);
      }

      await userRef.update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  /// Set an address as default
  Future<void> setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final addresses = (userData['addresses'] as List<dynamic>?)
              ?.map((addr) => AddressModel.fromMap(addr as Map<String, dynamic>))
              .toList() ??
          [];

      // Unset all defaults and set the new one
      for (var i = 0; i < addresses.length; i++) {
        addresses[i] = addresses[i].copyWith(
          isDefault: addresses[i].id == addressId,
        );
      }

      await userRef.update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  /// Get all addresses for a user
  Stream<List<AddressModel>> getAddresses(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data()!;
      return (data['addresses'] as List<dynamic>?)
              ?.map((addr) => AddressModel.fromMap(addr as Map<String, dynamic>))
              .toList() ??
          [];
    });
  }
}
