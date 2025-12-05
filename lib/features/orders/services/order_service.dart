import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../models/order_model.dart';
import 'dart:math';

/// Order Service - Handles all order operations with Firestore
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reference to orders collection
  CollectionReference get _ordersRef =>
      _firestore.collection(FirebaseConstants.ordersCollection);

  /// Generate a fun order number like #Goku947
  String generateOrderNumber() {
    final random = Random();
    final prefix = AppConstants.orderIdPrefixes[
        random.nextInt(AppConstants.orderIdPrefixes.length)];
    final number = random.nextInt(900) + 100; // 3-digit number (100-999)
    return '#$prefix$number';
  }

  /// Create a new order
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await _ordersRef.add(order.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get order by ID
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Stream order by ID (real-time updates)
  Stream<OrderModel?> streamOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get user's orders
  Future<List<OrderModel>> getUserOrders(String userId,
      {int limit = 20}) async {
    try {
      final querySnapshot = await _ordersRef
          .where('userId', isEqualTo: userId)
          .orderBy('timestamps.placedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  /// Stream user's orders (real-time updates)
  Stream<List<OrderModel>> streamUserOrders(String userId, {int limit = 20}) {
    return _ordersRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamps.placedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  /// Get user's active orders (not delivered or cancelled)
  Stream<List<OrderModel>> streamUserActiveOrders(String userId) {
    return _ordersRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          'placed',
          'confirmed',
          'preparing',
          'out_for_delivery'
        ])
        .orderBy('timestamps.placedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  /// Get orders by status (for staff/admin)
  Stream<List<OrderModel>> streamOrdersByStatus(String status,
      {int limit = 50}) {
    return _ordersRef
        .where('status', isEqualTo: status)
        .orderBy('timestamps.placedAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  /// Get all active orders (for kitchen/staff)
  Stream<List<OrderModel>> streamActiveOrders({int limit = 100}) {
    return _ordersRef
        .where('status', whereIn: [
          'placed',
          'confirmed',
          'preparing',
          'out_for_delivery'
        ])
        .orderBy('timestamps.placedAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  /// Get delivery orders (for delivery staff)
  Stream<List<OrderModel>> streamDeliveryOrders({String? riderId}) {
    Query query = _ordersRef
        .where('orderType', isEqualTo: 'delivery')
        .where('status', whereIn: ['confirmed', 'preparing', 'out_for_delivery']);

    if (riderId != null) {
      query = query.where('assignedRiderId', isEqualTo: riderId);
    }

    return query
        .orderBy('timestamps.placedAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  /// Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) async {
    try {
      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'status': newStatus,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'timestamp': Timestamp.fromDate(now),
            'note': note,
          }
        ]),
      };

      // Update appropriate timestamp based on status
      switch (newStatus) {
        case 'confirmed':
          updateData['timestamps.confirmedAt'] = Timestamp.fromDate(now);
          break;
        case 'preparing':
          updateData['timestamps.preparingAt'] = Timestamp.fromDate(now);
          break;
        case 'out_for_delivery':
          updateData['timestamps.outForDeliveryAt'] = Timestamp.fromDate(now);
          break;
        case 'delivered':
          updateData['timestamps.deliveredAt'] = Timestamp.fromDate(now);
          updateData['actualDeliveryTime'] = Timestamp.fromDate(now);
          break;
        case 'cancelled':
          updateData['timestamps.cancelledAt'] = Timestamp.fromDate(now);
          break;
      }

      await _ordersRef.doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Assign rider to order
  Future<void> assignRider({
    required String orderId,
    required String riderId,
    required String riderName,
    required String riderPhone,
  }) async {
    try {
      await _ordersRef.doc(orderId).update({
        'assignedRiderId': riderId,
        'riderName': riderName,
        'riderPhone': riderPhone,
      });
    } catch (e) {
      throw Exception('Failed to assign rider: $e');
    }
  }

  /// Update estimated delivery time
  Future<void> updateEstimatedDeliveryTime({
    required String orderId,
    required DateTime estimatedTime,
  }) async {
    try {
      await _ordersRef.doc(orderId).update({
        'estimatedDeliveryTime': Timestamp.fromDate(estimatedTime),
      });
    } catch (e) {
      throw Exception('Failed to update estimated delivery time: $e');
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String? transactionId,
    DateTime? paidAt,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'payment.status': paymentStatus,
      };

      if (transactionId != null) {
        updateData['payment.transactionId'] = transactionId;
      }

      if (paidAt != null) {
        updateData['payment.paidAt'] = Timestamp.fromDate(paidAt);
      }

      await _ordersRef.doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Cancel order
  Future<void> cancelOrder({
    required String orderId,
    String? cancellationReason,
  }) async {
    try {
      await updateOrderStatus(
        orderId: orderId,
        newStatus: 'cancelled',
        note: cancellationReason ?? 'Order cancelled',
      );
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Get order statistics (for admin)
  Future<Map<String, dynamic>> getOrderStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _ordersRef;

      if (startDate != null) {
        query = query.where('timestamps.placedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamps.placedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final orders =
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      // Calculate statistics
      final totalOrders = orders.length;
      final totalRevenue =
          orders.fold<double>(0, (total, order) => total + order.pricing.finalAmount);
      final completedOrders =
          orders.where((order) => order.status == 'delivered').length;
      final cancelledOrders =
          orders.where((order) => order.status == 'cancelled').length;

      final ordersByStatus = <String, int>{};
      for (final order in orders) {
        ordersByStatus[order.status] =
            (ordersByStatus[order.status] ?? 0) + 1;
      }

      final ordersByType = <String, int>{};
      for (final order in orders) {
        ordersByType[order.orderType] =
            (ordersByType[order.orderType] ?? 0) + 1;
      }

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
        'ordersByStatus': ordersByStatus,
        'ordersByType': ordersByType,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }

  /// Search orders by order number
  Future<List<OrderModel>> searchOrdersByNumber(String orderNumber) async {
    try {
      final snapshot = await _ordersRef
          .where('orderNumber', isEqualTo: orderNumber)
          .limit(1)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }

  /// Get today's orders count
  Future<int> getTodayOrdersCount() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _ordersRef
          .where('timestamps.placedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamps.placedAt',
              isLessThan: Timestamp.fromDate(endOfDay))
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get today\'s orders count: $e');
    }
  }
}
