import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification Type Enum
enum NotificationType {
  orderUpdate,
  promotion,
  reservation,
  coins,
  general,
  feedback,
  event,
}

extension NotificationTypeExtension on NotificationType {
  String get value => toString().split('.').last;

  String get displayName {
    switch (this) {
      case NotificationType.orderUpdate:
        return 'Order Update';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.reservation:
        return 'Reservation';
      case NotificationType.coins:
        return 'Coins';
      case NotificationType.general:
        return 'General';
      case NotificationType.feedback:
        return 'Feedback';
      case NotificationType.event:
        return 'Event';
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.general,
    );
  }
}

/// Notification Model
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationTypeExtension.fromString(data['type'] ?? 'general'),
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Notification Preferences Model
class NotificationPreferences {
  final bool orderUpdates;
  final bool promotions;
  final bool reservationReminders;
  final bool coinUpdates;
  final bool events;
  final bool emailNotifications;
  final bool pushNotifications;

  NotificationPreferences({
    this.orderUpdates = true,
    this.promotions = true,
    this.reservationReminders = true,
    this.coinUpdates = true,
    this.events = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      orderUpdates: map['orderUpdates'] ?? true,
      promotions: map['promotions'] ?? true,
      reservationReminders: map['reservationReminders'] ?? true,
      coinUpdates: map['coinUpdates'] ?? true,
      events: map['events'] ?? true,
      emailNotifications: map['emailNotifications'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'reservationReminders': reservationReminders,
      'coinUpdates': coinUpdates,
      'events': events,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
    };
  }

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? reservationReminders,
    bool? coinUpdates,
    bool? events,
    bool? emailNotifications,
    bool? pushNotifications,
  }) {
    return NotificationPreferences(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      reservationReminders: reservationReminders ?? this.reservationReminders,
      coinUpdates: coinUpdates ?? this.coinUpdates,
      events: events ?? this.events,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}
