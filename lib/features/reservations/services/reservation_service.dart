import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

/// Reservation Service - Handles all reservation-related Firestore operations
class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _reservationsRef => _firestore.collection('reservations');
  CollectionReference get _tablesRef => _firestore.collection('tables');

  // ==================== TABLE OPERATIONS ====================

  /// Get all active tables
  Stream<List<TableModel>> getTablesStream() {
    return _tablesRef
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TableModel.fromFirestore(doc)).toList());
  }

  /// Get tables by capacity
  Stream<List<TableModel>> getTablesByCapacityStream(int minCapacity) {
    return _tablesRef
        .where('isActive', isEqualTo: true)
        .where('capacity', isGreaterThanOrEqualTo: minCapacity)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TableModel.fromFirestore(doc)).toList());
  }

  /// Add a new table (admin)
  Future<String> addTable(TableModel table) async {
    final docRef = await _tablesRef.add(table.toMap());
    return docRef.id;
  }

  /// Update table (admin)
  Future<void> updateTable(String tableId, Map<String, dynamic> data) async {
    await _tablesRef.doc(tableId).update(data);
  }

  /// Delete table (admin) - soft delete
  Future<void> deleteTable(String tableId) async {
    await _tablesRef.doc(tableId).update({'isActive': false});
  }

  // ==================== RESERVATION OPERATIONS ====================

  /// Create a new reservation
  Future<String> createReservation(ReservationModel reservation) async {
    final docRef = await _reservationsRef.add(reservation.toMap());
    return docRef.id;
  }

  /// Get user's reservations
  Stream<List<ReservationModel>> getUserReservationsStream(String userId) {
    return _reservationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('reservationDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromFirestore(doc))
            .toList());
  }

  /// Get upcoming reservations for a user
  Stream<List<ReservationModel>> getUpcomingReservationsStream(String userId) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return _reservationsRef
        .where('userId', isEqualTo: userId)
        .where('reservationDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('reservationDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromFirestore(doc))
            .toList());
  }

  /// Get past reservations for a user
  Stream<List<ReservationModel>> getPastReservationsStream(String userId) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return _reservationsRef
        .where('userId', isEqualTo: userId)
        .where('reservationDate', isLessThan: Timestamp.fromDate(startOfToday))
        .orderBy('reservationDate', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromFirestore(doc))
            .toList());
  }

  /// Get all reservations for a date (admin)
  Stream<List<ReservationModel>> getReservationsByDateStream(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _reservationsRef
        .where('reservationDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('reservationDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('reservationDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromFirestore(doc))
            .toList());
  }

  /// Get all pending reservations (admin)
  Stream<List<ReservationModel>> getPendingReservationsStream() {
    return _reservationsRef
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromFirestore(doc))
            .toList());
  }

  /// Get reservation by ID
  Future<ReservationModel?> getReservationById(String reservationId) async {
    final doc = await _reservationsRef.doc(reservationId).get();
    if (doc.exists) {
      return ReservationModel.fromFirestore(doc);
    }
    return null;
  }

  /// Update reservation status
  Future<void> updateReservationStatus(
    String reservationId,
    ReservationStatus status, {
    String? cancellationReason,
  }) async {
    final updates = <String, dynamic>{
      'status': status.value,
    };

    if (status == ReservationStatus.confirmed) {
      updates['confirmedAt'] = Timestamp.now();
    } else if (status == ReservationStatus.cancelled) {
      updates['cancelledAt'] = Timestamp.now();
      if (cancellationReason != null) {
        updates['cancellationReason'] = cancellationReason;
      }
    }

    await _reservationsRef.doc(reservationId).update(updates);
  }

  /// Assign table to reservation
  Future<void> assignTable(
    String reservationId,
    String tableId,
    String tableName,
  ) async {
    await _reservationsRef.doc(reservationId).update({
      'tableId': tableId,
      'tableName': tableName,
      'status': ReservationStatus.confirmed.value,
      'confirmedAt': Timestamp.now(),
    });
  }

  /// Cancel reservation
  Future<void> cancelReservation(
    String reservationId, {
    String? reason,
  }) async {
    await updateReservationStatus(
      reservationId,
      ReservationStatus.cancelled,
      cancellationReason: reason,
    );
  }

  /// Check if time slot is available
  Future<bool> isTimeSlotAvailable(
    DateTime date,
    String timeSlot,
    int partySize,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get reservations for the date and time slot
    final snapshot = await _reservationsRef
        .where('reservationDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('reservationDate', isLessThan: Timestamp.fromDate(endOfDay))
        .where('timeSlot', isEqualTo: timeSlot)
        .where('status', whereIn: ['pending', 'confirmed', 'seated'])
        .get();

    // Get available tables for the party size
    final tablesSnapshot = await _tablesRef
        .where('isActive', isEqualTo: true)
        .where('capacity', isGreaterThanOrEqualTo: partySize)
        .get();

    // Check if there are more tables than reservations
    return snapshot.docs.length < tablesSnapshot.docs.length;
  }

  /// Get available time slots for a date
  Future<List<TimeSlotModel>> getAvailableTimeSlots(
    DateTime date,
    int partySize,
  ) async {
    final allSlots = TimeSlotModel.getDefaultSlots();
    final availableSlots = <TimeSlotModel>[];

    for (final slot in allSlots) {
      final isAvailable = await isTimeSlotAvailable(date, slot.display, partySize);
      availableSlots.add(TimeSlotModel(
        id: slot.id,
        startTime: slot.startTime,
        endTime: slot.endTime,
        isAvailable: isAvailable,
      ));
    }

    return availableSlots;
  }

  /// Get reservation count for today (admin)
  Future<int> getTodayReservationCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _reservationsRef
        .where('reservationDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('reservationDate', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['pending', 'confirmed', 'seated'])
        .get();

    return snapshot.docs.length;
  }
}
