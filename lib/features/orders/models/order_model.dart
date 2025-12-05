import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/auth/models/user_model.dart';
import 'order_item_model.dart';
import 'order_pricing_model.dart';

/// Order Model - Complete order information
class OrderModel {
  final String id;
  final String orderNumber; // Fun ID like #Goku947
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;

  final List<OrderItemModel> items;
  final OrderPricingModel pricing;

  final AddressModel? deliveryAddress;
  final String? specialNotes;
  final String orderType; // delivery, dine-in, takeaway
  final String? tableId;

  final String status; // placed, confirmed, preparing, out_for_delivery, delivered, cancelled
  final List<OrderStatusHistory> statusHistory;

  final PaymentInfo payment;

  final String? assignedRiderId;
  final String? riderName;
  final String? riderPhone;

  final int coinsUsed;
  final int coinsEarned;

  final DateTime placedAt;
  final DateTime? confirmedAt;
  final DateTime? preparingAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.items,
    required this.pricing,
    this.deliveryAddress,
    this.specialNotes,
    required this.orderType,
    this.tableId,
    required this.status,
    this.statusHistory = const [],
    required this.payment,
    this.assignedRiderId,
    this.riderName,
    this.riderPhone,
    this.coinsUsed = 0,
    this.coinsEarned = 0,
    required this.placedAt,
    this.confirmedAt,
    this.preparingAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
  });

  // From Firestore
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userEmail: data['userEmail'] ?? '',
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      pricing: OrderPricingModel.fromMap(data['pricing'] as Map<String, dynamic>),
      deliveryAddress: data['deliveryAddress'] != null
          ? AddressModel.fromMap(data['deliveryAddress'] as Map<String, dynamic>)
          : null,
      specialNotes: data['specialNotes'],
      orderType: data['orderType'] ?? 'delivery',
      tableId: data['tableId'],
      status: data['status'] ?? 'placed',
      statusHistory: (data['statusHistory'] as List<dynamic>?)
              ?.map((history) => OrderStatusHistory.fromMap(history as Map<String, dynamic>))
              .toList() ??
          [],
      payment: PaymentInfo.fromMap(data['payment'] as Map<String, dynamic>),
      assignedRiderId: data['assignedRiderId'],
      riderName: data['riderName'],
      riderPhone: data['riderPhone'],
      coinsUsed: data['coinsUsed'] ?? 0,
      coinsEarned: data['coinsEarned'] ?? 0,
      placedAt: (data['timestamps']['placedAt'] as Timestamp).toDate(),
      confirmedAt: data['timestamps']['confirmedAt'] != null
          ? (data['timestamps']['confirmedAt'] as Timestamp).toDate()
          : null,
      preparingAt: data['timestamps']['preparingAt'] != null
          ? (data['timestamps']['preparingAt'] as Timestamp).toDate()
          : null,
      outForDeliveryAt: data['timestamps']['outForDeliveryAt'] != null
          ? (data['timestamps']['outForDeliveryAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['timestamps']['deliveredAt'] != null
          ? (data['timestamps']['deliveredAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['timestamps']['cancelledAt'] != null
          ? (data['timestamps']['cancelledAt'] as Timestamp).toDate()
          : null,
      estimatedDeliveryTime: data['estimatedDeliveryTime'] != null
          ? (data['estimatedDeliveryTime'] as Timestamp).toDate()
          : null,
      actualDeliveryTime: data['actualDeliveryTime'] != null
          ? (data['actualDeliveryTime'] as Timestamp).toDate()
          : null,
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'pricing': pricing.toMap(),
      'deliveryAddress': deliveryAddress?.toMap(),
      'specialNotes': specialNotes,
      'orderType': orderType,
      'tableId': tableId,
      'status': status,
      'statusHistory': statusHistory.map((history) => history.toMap()).toList(),
      'payment': payment.toMap(),
      'assignedRiderId': assignedRiderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'coinsUsed': coinsUsed,
      'coinsEarned': coinsEarned,
      'timestamps': {
        'placedAt': Timestamp.fromDate(placedAt),
        'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
        'preparingAt': preparingAt != null ? Timestamp.fromDate(preparingAt!) : null,
        'outForDeliveryAt': outForDeliveryAt != null ? Timestamp.fromDate(outForDeliveryAt!) : null,
        'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
        'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      },
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'actualDeliveryTime': actualDeliveryTime != null
          ? Timestamp.fromDate(actualDeliveryTime!)
          : null,
    };
  }

  // Helper methods
  bool get isDelivery => orderType == 'delivery';
  bool get isDineIn => orderType == 'dine-in';
  bool get isTakeaway => orderType == 'takeaway';

  bool get isPlaced => status == 'placed';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  bool get isActive => !isDelivered && !isCancelled;
  bool get isCompleted => isDelivered || isCancelled;

  int get totalItems => items.fold<int>(0, (total, item) => total + item.quantity);

  // Copy with
  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    List<OrderItemModel>? items,
    OrderPricingModel? pricing,
    AddressModel? deliveryAddress,
    String? specialNotes,
    String? orderType,
    String? tableId,
    String? status,
    List<OrderStatusHistory>? statusHistory,
    PaymentInfo? payment,
    String? assignedRiderId,
    String? riderName,
    String? riderPhone,
    int? coinsUsed,
    int? coinsEarned,
    DateTime? placedAt,
    DateTime? confirmedAt,
    DateTime? preparingAt,
    DateTime? outForDeliveryAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      items: items ?? this.items,
      pricing: pricing ?? this.pricing,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      specialNotes: specialNotes ?? this.specialNotes,
      orderType: orderType ?? this.orderType,
      tableId: tableId ?? this.tableId,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      payment: payment ?? this.payment,
      assignedRiderId: assignedRiderId ?? this.assignedRiderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      coinsUsed: coinsUsed ?? this.coinsUsed,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      placedAt: placedAt ?? this.placedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      preparingAt: preparingAt ?? this.preparingAt,
      outForDeliveryAt: outForDeliveryAt ?? this.outForDeliveryAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
    );
  }
}

/// Order Status History - Track status changes
class OrderStatusHistory {
  final String status;
  final DateTime timestamp;
  final String? note;

  OrderStatusHistory({
    required this.status,
    required this.timestamp,
    this.note,
  });

  factory OrderStatusHistory.fromMap(Map<String, dynamic> map) {
    return OrderStatusHistory(
      status: map['status'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}

/// Payment Info - Payment details
class PaymentInfo {
  final String method; // cash, upi, card, wallet
  final String status; // pending, completed, failed, refunded
  final String? transactionId;
  final DateTime? paidAt;

  PaymentInfo({
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      method: map['method'] ?? 'cash',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      paidAt: map['paidAt'] != null ? (map['paidAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';

  PaymentInfo copyWith({
    String? method,
    String? status,
    String? transactionId,
    DateTime? paidAt,
  }) {
    return PaymentInfo(
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
