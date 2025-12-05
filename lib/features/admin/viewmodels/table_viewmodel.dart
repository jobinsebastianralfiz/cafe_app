import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';

/// Provider for all tables (real-time)
final allTablesProvider = StreamProvider<List<TableModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('tables')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TableModel.fromFirestore(doc))
          .toList());
});

/// Provider for active tables only
final activeTablesProvider = StreamProvider<List<TableModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('tables')
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TableModel.fromFirestore(doc))
          .toList());
});

/// Provider for available tables only
final availableTablesProvider = StreamProvider<List<TableModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('tables')
      .where('isActive', isEqualTo: true)
      .where('status', isEqualTo: 'available')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TableModel.fromFirestore(doc))
          .toList());
});

/// Provider for a single table by ID
final tableByIdProvider = StreamProvider.family<TableModel?, String>((ref, tableId) {
  return FirebaseFirestore.instance
      .collection('tables')
      .doc(tableId)
      .snapshots()
      .map((doc) => doc.exists ? TableModel.fromFirestore(doc) : null);
});

/// Selected table provider (for QR ordering flow)
final selectedTableProvider = StateProvider<TableModel?>((ref) => null);

/// Table ViewModel for CRUD operations
class TableViewModel extends StateNotifier<AsyncValue<void>> {
  TableViewModel() : super(const AsyncValue.data(null));

  final _firestore = FirebaseFirestore.instance;
  CollectionReference get _tables => _firestore.collection('tables');

  /// Create a new table
  Future<String?> createTable({
    required String name,
    required int capacity,
    required TableLocation location,
  }) async {
    state = const AsyncValue.loading();
    try {
      final docRef = await _tables.add({
        'name': name,
        'capacity': capacity,
        'location': location.name,
        'status': TableStatus.available.name,
        'isActive': true,
        'currentOrderId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
      return docRef.id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update an existing table
  Future<bool> updateTable({
    required String tableId,
    String? name,
    int? capacity,
    TableLocation? location,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) updates['name'] = name;
      if (capacity != null) updates['capacity'] = capacity;
      if (location != null) updates['location'] = location.name;
      if (isActive != null) updates['isActive'] = isActive;

      await _tables.doc(tableId).update(updates);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Update table status
  Future<bool> updateTableStatus({
    required String tableId,
    required TableStatus status,
    String? orderId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (orderId != null) {
        updates['currentOrderId'] = orderId;
      } else if (status == TableStatus.available) {
        updates['currentOrderId'] = null;
      }

      await _tables.doc(tableId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a table
  Future<bool> deleteTable(String tableId) async {
    state = const AsyncValue.loading();
    try {
      await _tables.doc(tableId).delete();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Toggle table active status
  Future<bool> toggleTableActive(String tableId, bool isActive) async {
    try {
      await _tables.doc(tableId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get table by ID (one-time fetch)
  Future<TableModel?> getTableById(String tableId) async {
    try {
      final doc = await _tables.doc(tableId).get();
      if (doc.exists) {
        return TableModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if table is available for ordering
  Future<bool> isTableAvailable(String tableId) async {
    try {
      final doc = await _tables.doc(tableId).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      return data['isActive'] == true && data['status'] == 'available';
    } catch (e) {
      return false;
    }
  }

  /// Mark table as occupied with order
  Future<bool> occupyTable(String tableId, String orderId) async {
    return updateTableStatus(
      tableId: tableId,
      status: TableStatus.occupied,
      orderId: orderId,
    );
  }

  /// Release table (mark as available)
  Future<bool> releaseTable(String tableId) async {
    return updateTableStatus(
      tableId: tableId,
      status: TableStatus.available,
    );
  }
}

/// Provider for TableViewModel
final tableViewModelProvider = StateNotifierProvider<TableViewModel, AsyncValue<void>>((ref) {
  return TableViewModel();
});
