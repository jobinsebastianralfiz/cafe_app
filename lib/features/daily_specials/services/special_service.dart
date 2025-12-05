import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/special_model.dart';

/// Special Service - Handles all special/offer-related Firestore operations
class SpecialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _specialsRef => _firestore.collection('specials');

  /// Get all active specials
  Stream<List<SpecialModel>> getActiveSpecialsStream() {
    final now = DateTime.now();
    return _specialsRef
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpecialModel.fromFirestore(doc))
            .where((special) => special.isCurrentlyActive)
            .toList());
  }

  /// Get all specials (admin)
  Stream<List<SpecialModel>> getAllSpecialsStream() {
    return _specialsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SpecialModel.fromFirestore(doc)).toList());
  }

  /// Get specials by type
  Stream<List<SpecialModel>> getSpecialsByTypeStream(SpecialType type) {
    final now = DateTime.now();
    return _specialsRef
        .where('isActive', isEqualTo: true)
        .where('type', isEqualTo: type.value)
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpecialModel.fromFirestore(doc))
            .where((special) => special.isCurrentlyActive)
            .toList());
  }

  /// Get today's specials
  Stream<List<SpecialModel>> getTodaySpecialsStream() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);

    return _specialsRef
        .where('isActive', isEqualTo: true)
        .where('dayOfWeek', isEqualTo: dayName)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpecialModel.fromFirestore(doc))
            .where((special) => special.isCurrentlyActive)
            .toList());
  }

  /// Get a special by ID
  Future<SpecialModel?> getSpecialById(String specialId) async {
    final doc = await _specialsRef.doc(specialId).get();
    if (doc.exists) {
      return SpecialModel.fromFirestore(doc);
    }
    return null;
  }

  /// Create a new special (admin)
  Future<String> createSpecial(SpecialModel special) async {
    final docRef = await _specialsRef.add(special.toMap());
    return docRef.id;
  }

  /// Update a special (admin)
  Future<void> updateSpecial(String specialId, Map<String, dynamic> data) async {
    await _specialsRef.doc(specialId).update(data);
  }

  /// Delete a special (admin)
  Future<void> deleteSpecial(String specialId) async {
    await _specialsRef.doc(specialId).delete();
  }

  /// Toggle special active status (admin)
  Future<void> toggleSpecialStatus(String specialId, bool isActive) async {
    await _specialsRef.doc(specialId).update({'isActive': isActive});
  }

  /// Increment usage count
  Future<void> incrementUsageCount(String specialId) async {
    await _specialsRef.doc(specialId).update({
      'usageCount': FieldValue.increment(1),
    });
  }

  /// Validate promo code
  Future<SpecialModel?> validatePromoCode(String promoCode) async {
    final snapshot = await _specialsRef
        .where('promoCode', isEqualTo: promoCode.toUpperCase())
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final special = SpecialModel.fromFirestore(snapshot.docs.first);

    // Check if still valid
    if (!special.isCurrentlyActive) return null;
    if (special.hasReachedLimit) return null;

    return special;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return '';
    }
  }
}
