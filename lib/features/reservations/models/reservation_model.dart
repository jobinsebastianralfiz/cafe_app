import 'package:cloud_firestore/cloud_firestore.dart';

/// Table Model - Represents a table in the restaurant
class TableModel {
  final String id;
  final String name;
  final int capacity;
  final String location; // indoor, outdoor, private
  final bool isActive;
  final List<String> features; // window view, corner, etc.

  TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.location,
    this.isActive = true,
    this.features = const [],
  });

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 2,
      location: data['location'] ?? 'indoor',
      isActive: data['isActive'] ?? true,
      features: List<String>.from(data['features'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'location': location,
      'isActive': isActive,
      'features': features,
    };
  }

  String get locationDisplay {
    switch (location) {
      case 'outdoor':
        return 'Outdoor';
      case 'private':
        return 'Private Room';
      default:
        return 'Indoor';
    }
  }
}

/// Reservation Status Enum
enum ReservationStatus {
  pending,
  confirmed,
  seated,
  completed,
  cancelled,
  noShow,
}

extension ReservationStatusExtension on ReservationStatus {
  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.seated:
        return 'Seated';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.noShow:
        return 'No Show';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReservationStatus.pending,
    );
  }
}

/// Reservation Model - Represents a table reservation
class ReservationModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String? tableId;
  final String? tableName;
  final DateTime reservationDate;
  final String timeSlot; // "12:00 PM - 1:00 PM"
  final int partySize;
  final String? specialRequests;
  final ReservationStatus status;
  final String? occasion; // birthday, anniversary, business, etc.
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    this.tableId,
    this.tableName,
    required this.reservationDate,
    required this.timeSlot,
    required this.partySize,
    this.specialRequests,
    this.status = ReservationStatus.pending,
    this.occasion,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userEmail: data['userEmail'] ?? '',
      tableId: data['tableId'],
      tableName: data['tableName'],
      reservationDate: (data['reservationDate'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      partySize: data['partySize'] ?? 2,
      specialRequests: data['specialRequests'],
      status: ReservationStatusExtension.fromString(data['status'] ?? 'pending'),
      occasion: data['occasion'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'tableId': tableId,
      'tableName': tableName,
      'reservationDate': Timestamp.fromDate(reservationDate),
      'timeSlot': timeSlot,
      'partySize': partySize,
      'specialRequests': specialRequests,
      'status': status.value,
      'occasion': occasion,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
    };
  }

  bool get isPending => status == ReservationStatus.pending;
  bool get isConfirmed => status == ReservationStatus.confirmed;
  bool get isSeated => status == ReservationStatus.seated;
  bool get isCompleted => status == ReservationStatus.completed;
  bool get isCancelled => status == ReservationStatus.cancelled;
  bool get isNoShow => status == ReservationStatus.noShow;
  bool get isActive => !isCompleted && !isCancelled && !isNoShow;

  bool get isUpcoming {
    final now = DateTime.now();
    return reservationDate.isAfter(now) && isActive;
  }

  bool get isPast {
    final now = DateTime.now();
    return reservationDate.isBefore(now);
  }

  ReservationModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? tableId,
    String? tableName,
    DateTime? reservationDate,
    String? timeSlot,
    int? partySize,
    String? specialRequests,
    ReservationStatus? status,
    String? occasion,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      reservationDate: reservationDate ?? this.reservationDate,
      timeSlot: timeSlot ?? this.timeSlot,
      partySize: partySize ?? this.partySize,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      occasion: occasion ?? this.occasion,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

/// Time Slot Model - Available time slots for reservations
class TimeSlotModel {
  final String id;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  TimeSlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  String get display => '$startTime - $endTime';

  static List<TimeSlotModel> getDefaultSlots() {
    return [
      TimeSlotModel(id: '1', startTime: '11:00 AM', endTime: '12:00 PM'),
      TimeSlotModel(id: '2', startTime: '12:00 PM', endTime: '1:00 PM'),
      TimeSlotModel(id: '3', startTime: '1:00 PM', endTime: '2:00 PM'),
      TimeSlotModel(id: '4', startTime: '2:00 PM', endTime: '3:00 PM'),
      TimeSlotModel(id: '5', startTime: '3:00 PM', endTime: '4:00 PM'),
      TimeSlotModel(id: '6', startTime: '6:00 PM', endTime: '7:00 PM'),
      TimeSlotModel(id: '7', startTime: '7:00 PM', endTime: '8:00 PM'),
      TimeSlotModel(id: '8', startTime: '8:00 PM', endTime: '9:00 PM'),
      TimeSlotModel(id: '9', startTime: '9:00 PM', endTime: '10:00 PM'),
    ];
  }
}
