import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Notification Service - Handles all notification-related Firestore operations
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notificationsRef => _firestore.collection('notifications');

  /// Get user notifications stream
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Get unread notifications stream
  Stream<List<NotificationModel>> getUnreadNotificationsStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Get unread count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Create a notification
  Future<String> createNotification(NotificationModel notification) async {
    final docRef = await _notificationsRef.add(notification.toMap());
    return docRef.id;
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'isRead': true,
      'readAt': Timestamp.now(),
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications')
        .get();

    if (doc.exists) {
      return NotificationPreferences.fromMap(doc.data()!);
    }
    return NotificationPreferences();
  }

  /// Update notification preferences
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications')
        .set(preferences.toMap());
  }

  // ==================== NOTIFICATION HELPERS ====================

  /// Send order update notification
  Future<void> sendOrderUpdateNotification({
    required String userId,
    required String orderId,
    required String orderNumber,
    required String status,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'confirmed':
        title = 'Order Confirmed!';
        body = 'Your order $orderNumber has been confirmed and is being prepared.';
        break;
      case 'preparing':
        title = 'Preparing Your Order';
        body = 'Your order $orderNumber is now being prepared.';
        break;
      case 'out_for_delivery':
        title = 'Out for Delivery';
        body = 'Your order $orderNumber is on its way!';
        break;
      case 'delivered':
        title = 'Order Delivered!';
        body = 'Your order $orderNumber has been delivered. Enjoy!';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order $orderNumber has been cancelled.';
        break;
      default:
        title = 'Order Update';
        body = 'Your order $orderNumber has been updated.';
    }

    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.orderUpdate,
      data: {'orderId': orderId, 'orderNumber': orderNumber, 'status': status},
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Send reservation notification
  Future<void> sendReservationNotification({
    required String userId,
    required String reservationId,
    required String action, // confirmed, reminder, cancelled
    required String date,
    required String time,
  }) async {
    String title;
    String body;

    switch (action) {
      case 'confirmed':
        title = 'Reservation Confirmed!';
        body = 'Your table for $date at $time has been confirmed.';
        break;
      case 'reminder':
        title = 'Reservation Reminder';
        body = 'Your reservation is coming up tomorrow at $time.';
        break;
      case 'cancelled':
        title = 'Reservation Cancelled';
        body = 'Your reservation for $date at $time has been cancelled.';
        break;
      default:
        title = 'Reservation Update';
        body = 'Your reservation has been updated.';
    }

    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.reservation,
      data: {'reservationId': reservationId, 'date': date, 'time': time},
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Send coins notification
  Future<void> sendCoinsNotification({
    required String userId,
    required int coins,
    required String action, // earned, redeemed, bonus
    String? orderId,
  }) async {
    String title;
    String body;

    switch (action) {
      case 'earned':
        title = 'Coins Earned!';
        body = 'You earned $coins coins from your recent order.';
        break;
      case 'redeemed':
        title = 'Coins Redeemed';
        body = 'You redeemed $coins coins on your order.';
        break;
      case 'bonus':
        title = 'Bonus Coins!';
        body = 'You received $coins bonus coins!';
        break;
      default:
        title = 'Coins Update';
        body = 'Your coin balance has been updated.';
    }

    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.coins,
      data: {'coins': coins, 'action': action, 'orderId': orderId},
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Send promotion notification
  Future<void> sendPromotionNotification({
    required String userId,
    required String title,
    required String body,
    String? promoCode,
    String? imageUrl,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.promotion,
      data: {'promoCode': promoCode, 'imageUrl': imageUrl},
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }
}
