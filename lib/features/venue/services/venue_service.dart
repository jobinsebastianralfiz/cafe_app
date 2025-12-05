import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../models/venue_settings_model.dart';

/// Venue Service - Manages venue settings and status
class VenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reference to venue settings collection
  CollectionReference get _venueRef =>
      _firestore.collection(FirebaseConstants.venueCollection);

  /// Get current venue settings
  Future<VenueSettingsModel?> getVenueSettings() async {
    try {
      // Get the main venue document (assuming single venue with ID 'main')
      final doc = await _venueRef.doc('main').get();
      if (doc.exists) {
        return VenueSettingsModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get venue settings: $e');
    }
  }

  /// Stream venue settings (real-time updates)
  Stream<VenueSettingsModel?> streamVenueSettings() {
    return _venueRef.doc('main').snapshots().map((doc) {
      if (doc.exists) {
        return VenueSettingsModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update venue status (admin only)
  Future<void> updateVenueStatus({
    required bool isOpen,
    required String status,
    String? closedReason,
  }) async {
    try {
      await _venueRef.doc('main').update({
        'isOpen': isOpen,
        'status': status,
        'closedReason': closedReason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update venue status: $e');
    }
  }

  /// Update accepting orders flag (admin only)
  Future<void> updateAcceptingOrders({
    required bool acceptingOrders,
    required bool acceptingDelivery,
    required bool acceptingDineIn,
    required bool acceptingTakeaway,
  }) async {
    try {
      await _venueRef.doc('main').update({
        'acceptingOrders': acceptingOrders,
        'acceptingDelivery': acceptingDelivery,
        'acceptingDineIn': acceptingDineIn,
        'acceptingTakeaway': acceptingTakeaway,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update accepting orders: $e');
    }
  }

  /// Update venue settings (admin only)
  Future<void> updateVenueSettings(VenueSettingsModel settings) async {
    try {
      await _venueRef.doc('main').set(
            settings.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to update venue settings: $e');
    }
  }

  /// Initialize default venue settings
  Future<void> initializeDefaultSettings() async {
    try {
      final doc = await _venueRef.doc('main').get();
      if (!doc.exists) {
        final defaultSettings = VenueSettingsModel(
          id: 'main',
          venueName: 'Ralfiz Cafe',
          isOpen: true,
          status: 'open',
          operatingHours: OperatingHours.defaultHours(),
          address: 'Ralfiz Cafe Location',
          phone: '+91 1234567890',
          email: 'info@ralfizcafe.com',
          updatedAt: DateTime.now(),
        );

        await _venueRef.doc('main').set(defaultSettings.toMap());
      }
    } catch (e) {
      throw Exception('Failed to initialize venue settings: $e');
    }
  }

  /// Check if venue is currently open based on operating hours
  bool isOpenNow(VenueSettingsModel settings) {
    if (!settings.isOpen) return false;

    final now = DateTime.now();
    final todaySchedule = settings.operatingHours.getScheduleForDay(now);

    if (!todaySchedule.isOpen) return false;

    // Parse open and close times
    final openParts = todaySchedule.openTime.split(':');
    final closeParts = todaySchedule.closeTime.split(':');

    final openTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(openParts[0]),
      int.parse(openParts[1]),
    );

    final closeTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(closeParts[0]),
      int.parse(closeParts[1]),
    );

    return now.isAfter(openTime) && now.isBefore(closeTime);
  }
}
