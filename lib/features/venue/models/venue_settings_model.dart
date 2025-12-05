import 'package:cloud_firestore/cloud_firestore.dart';

/// Venue Settings Model - Cafe operating status and settings
class VenueSettingsModel {
  final String id;
  final String venueName;
  final bool isOpen;
  final String status; // open, closed, busy
  final String? closedReason;
  final OperatingHours operatingHours;
  final String address;
  final String phone;
  final String email;
  final double deliveryRadius; // in km
  final double minimumOrderAmount;
  final int estimatedDeliveryTime; // in minutes
  final bool acceptingOrders;
  final bool acceptingDelivery;
  final bool acceptingDineIn;
  final bool acceptingTakeaway;
  final DateTime updatedAt;

  VenueSettingsModel({
    required this.id,
    required this.venueName,
    required this.isOpen,
    required this.status,
    this.closedReason,
    required this.operatingHours,
    required this.address,
    required this.phone,
    required this.email,
    this.deliveryRadius = 5.0,
    this.minimumOrderAmount = 100.0,
    this.estimatedDeliveryTime = 45,
    this.acceptingOrders = true,
    this.acceptingDelivery = true,
    this.acceptingDineIn = true,
    this.acceptingTakeaway = true,
    required this.updatedAt,
  });

  // From Firestore
  factory VenueSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VenueSettingsModel(
      id: doc.id,
      venueName: data['venueName'] ?? 'Ralfiz Cafe',
      isOpen: data['isOpen'] ?? false,
      status: data['status'] ?? 'closed',
      closedReason: data['closedReason'],
      operatingHours: OperatingHours.fromMap(
          data['operatingHours'] as Map<String, dynamic>? ?? {}),
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      deliveryRadius: (data['deliveryRadius'] ?? 5.0).toDouble(),
      minimumOrderAmount: (data['minimumOrderAmount'] ?? 100.0).toDouble(),
      estimatedDeliveryTime: data['estimatedDeliveryTime'] ?? 45,
      acceptingOrders: data['acceptingOrders'] ?? true,
      acceptingDelivery: data['acceptingDelivery'] ?? true,
      acceptingDineIn: data['acceptingDineIn'] ?? true,
      acceptingTakeaway: data['acceptingTakeaway'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'venueName': venueName,
      'isOpen': isOpen,
      'status': status,
      'closedReason': closedReason,
      'operatingHours': operatingHours.toMap(),
      'address': address,
      'phone': phone,
      'email': email,
      'deliveryRadius': deliveryRadius,
      'minimumOrderAmount': minimumOrderAmount,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'acceptingOrders': acceptingOrders,
      'acceptingDelivery': acceptingDelivery,
      'acceptingDineIn': acceptingDineIn,
      'acceptingTakeaway': acceptingTakeaway,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  bool get canAcceptOrders => isOpen && acceptingOrders;

  String get statusMessage {
    if (!isOpen) {
      return closedReason ?? 'We are currently closed';
    }

    switch (status) {
      case 'open':
        return 'We are open and accepting orders!';
      case 'busy':
        return 'We are busy. Delivery might take longer.';
      case 'closed':
        return closedReason ?? 'We are currently closed';
      default:
        return 'Status unknown';
    }
  }

  // Copy with
  VenueSettingsModel copyWith({
    String? id,
    String? venueName,
    bool? isOpen,
    String? status,
    String? closedReason,
    OperatingHours? operatingHours,
    String? address,
    String? phone,
    String? email,
    double? deliveryRadius,
    double? minimumOrderAmount,
    int? estimatedDeliveryTime,
    bool? acceptingOrders,
    bool? acceptingDelivery,
    bool? acceptingDineIn,
    bool? acceptingTakeaway,
    DateTime? updatedAt,
  }) {
    return VenueSettingsModel(
      id: id ?? this.id,
      venueName: venueName ?? this.venueName,
      isOpen: isOpen ?? this.isOpen,
      status: status ?? this.status,
      closedReason: closedReason ?? this.closedReason,
      operatingHours: operatingHours ?? this.operatingHours,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      acceptingOrders: acceptingOrders ?? this.acceptingOrders,
      acceptingDelivery: acceptingDelivery ?? this.acceptingDelivery,
      acceptingDineIn: acceptingDineIn ?? this.acceptingDineIn,
      acceptingTakeaway: acceptingTakeaway ?? this.acceptingTakeaway,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Operating Hours - Daily operating schedule
class OperatingHours {
  final DaySchedule monday;
  final DaySchedule tuesday;
  final DaySchedule wednesday;
  final DaySchedule thursday;
  final DaySchedule friday;
  final DaySchedule saturday;
  final DaySchedule sunday;

  OperatingHours({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory OperatingHours.fromMap(Map<String, dynamic> map) {
    return OperatingHours(
      monday: DaySchedule.fromMap(map['monday'] as Map<String, dynamic>? ?? {}),
      tuesday: DaySchedule.fromMap(map['tuesday'] as Map<String, dynamic>? ?? {}),
      wednesday: DaySchedule.fromMap(map['wednesday'] as Map<String, dynamic>? ?? {}),
      thursday: DaySchedule.fromMap(map['thursday'] as Map<String, dynamic>? ?? {}),
      friday: DaySchedule.fromMap(map['friday'] as Map<String, dynamic>? ?? {}),
      saturday: DaySchedule.fromMap(map['saturday'] as Map<String, dynamic>? ?? {}),
      sunday: DaySchedule.fromMap(map['sunday'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monday': monday.toMap(),
      'tuesday': tuesday.toMap(),
      'wednesday': wednesday.toMap(),
      'thursday': thursday.toMap(),
      'friday': friday.toMap(),
      'saturday': saturday.toMap(),
      'sunday': sunday.toMap(),
    };
  }

  DaySchedule getScheduleForDay(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        return monday;
    }
  }

  // Default operating hours (10 AM - 10 PM)
  factory OperatingHours.defaultHours() {
    final defaultSchedule = DaySchedule(
      isOpen: true,
      openTime: '10:00',
      closeTime: '22:00',
    );

    return OperatingHours(
      monday: defaultSchedule,
      tuesday: defaultSchedule,
      wednesday: defaultSchedule,
      thursday: defaultSchedule,
      friday: defaultSchedule,
      saturday: defaultSchedule,
      sunday: defaultSchedule,
    );
  }
}

/// Day Schedule - Schedule for a specific day
class DaySchedule {
  final bool isOpen;
  final String openTime; // HH:mm format
  final String closeTime; // HH:mm format

  DaySchedule({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      isOpen: map['isOpen'] ?? true,
      openTime: map['openTime'] ?? '10:00',
      closeTime: map['closeTime'] ?? '22:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  String get displayTime => '$openTime - $closeTime';
}
