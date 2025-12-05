import 'package:cloud_firestore/cloud_firestore.dart';

/// Special Type Enum
enum SpecialType {
  dailyDeal,
  happyHour,
  weekendSpecial,
  festiveOffer,
  comboOffer,
  newArrival,
}

extension SpecialTypeExtension on SpecialType {
  String get value => toString().split('.').last;

  String get displayName {
    switch (this) {
      case SpecialType.dailyDeal:
        return 'Daily Deal';
      case SpecialType.happyHour:
        return 'Happy Hour';
      case SpecialType.weekendSpecial:
        return 'Weekend Special';
      case SpecialType.festiveOffer:
        return 'Festive Offer';
      case SpecialType.comboOffer:
        return 'Combo Offer';
      case SpecialType.newArrival:
        return 'New Arrival';
    }
  }

  static SpecialType fromString(String value) {
    return SpecialType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SpecialType.dailyDeal,
    );
  }
}

/// Special Model - Daily specials and offers
class SpecialModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final SpecialType type;
  final double? originalPrice;
  final double specialPrice;
  final int? discountPercentage;
  final String? menuItemId;
  final List<String> menuItemIds; // for combos
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final String? dayOfWeek; // monday, tuesday, etc. for daily deals
  final String? timeStart; // for happy hours
  final String? timeEnd;
  final String? promoCode;
  final int? usageLimit;
  final int usageCount;
  final DateTime createdAt;

  SpecialModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.type,
    this.originalPrice,
    required this.specialPrice,
    this.discountPercentage,
    this.menuItemId,
    this.menuItemIds = const [],
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    this.dayOfWeek,
    this.timeStart,
    this.timeEnd,
    this.promoCode,
    this.usageLimit,
    this.usageCount = 0,
    required this.createdAt,
  });

  factory SpecialModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpecialModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      type: SpecialTypeExtension.fromString(data['type'] ?? 'dailyDeal'),
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      specialPrice: (data['specialPrice'] ?? 0).toDouble(),
      discountPercentage: data['discountPercentage'],
      menuItemId: data['menuItemId'],
      menuItemIds: List<String>.from(data['menuItemIds'] ?? []),
      isActive: data['isActive'] ?? true,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      dayOfWeek: data['dayOfWeek'],
      timeStart: data['timeStart'],
      timeEnd: data['timeEnd'],
      promoCode: data['promoCode'],
      usageLimit: data['usageLimit'],
      usageCount: data['usageCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.value,
      'originalPrice': originalPrice,
      'specialPrice': specialPrice,
      'discountPercentage': discountPercentage,
      'menuItemId': menuItemId,
      'menuItemIds': menuItemIds,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'dayOfWeek': dayOfWeek,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'promoCode': promoCode,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(startDate) || now.isAfter(endDate)) return false;

    // Check day of week for daily deals
    if (dayOfWeek != null) {
      final currentDay = _getDayName(now.weekday);
      if (currentDay.toLowerCase() != dayOfWeek!.toLowerCase()) return false;
    }

    // Check time for happy hours
    if (timeStart != null && timeEnd != null) {
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      if (currentTime.compareTo(timeStart!) < 0 || currentTime.compareTo(timeEnd!) > 0) {
        return false;
      }
    }

    return true;
  }

  bool get hasReachedLimit => usageLimit != null && usageCount >= usageLimit!;

  String get formattedOriginalPrice => '₹${originalPrice?.toStringAsFixed(0) ?? '0'}';
  String get formattedSpecialPrice => '₹${specialPrice.toStringAsFixed(0)}';

  String get discountText {
    if (discountPercentage != null) {
      return '$discountPercentage% OFF';
    }
    if (originalPrice != null && originalPrice! > specialPrice) {
      final discount = ((originalPrice! - specialPrice) / originalPrice! * 100).round();
      return '$discount% OFF';
    }
    return '';
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

  SpecialModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    SpecialType? type,
    double? originalPrice,
    double? specialPrice,
    int? discountPercentage,
    String? menuItemId,
    List<String>? menuItemIds,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? dayOfWeek,
    String? timeStart,
    String? timeEnd,
    String? promoCode,
    int? usageLimit,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return SpecialModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      originalPrice: originalPrice ?? this.originalPrice,
      specialPrice: specialPrice ?? this.specialPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemIds: menuItemIds ?? this.menuItemIds,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      promoCode: promoCode ?? this.promoCode,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
