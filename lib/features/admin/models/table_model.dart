import 'package:cloud_firestore/cloud_firestore.dart';

/// Table status enum
enum TableStatus {
  available,
  occupied,
  reserved;

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
    }
  }

  static TableStatus fromString(String? value) {
    switch (value) {
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      default:
        return TableStatus.available;
    }
  }
}

/// Table location enum
enum TableLocation {
  indoor,
  outdoor,
  patio,
  rooftop,
  private;

  String get displayName {
    switch (this) {
      case TableLocation.indoor:
        return 'Indoor';
      case TableLocation.outdoor:
        return 'Outdoor';
      case TableLocation.patio:
        return 'Patio';
      case TableLocation.rooftop:
        return 'Rooftop';
      case TableLocation.private:
        return 'Private';
    }
  }

  static TableLocation fromString(String? value) {
    switch (value) {
      case 'outdoor':
        return TableLocation.outdoor;
      case 'patio':
        return TableLocation.patio;
      case 'rooftop':
        return TableLocation.rooftop;
      case 'private':
        return TableLocation.private;
      default:
        return TableLocation.indoor;
    }
  }
}

/// Table Model for cafe tables
class TableModel {
  final String id;
  final String name;
  final int capacity;
  final TableLocation location;
  final TableStatus status;
  final bool isActive;
  final String? currentOrderId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    this.location = TableLocation.indoor,
    this.status = TableStatus.available,
    this.isActive = true,
    this.currentOrderId,
    required this.createdAt,
    this.updatedAt,
  });

  /// QR code data for this table - web URL for billing page
  String get qrData => 'https://cafeapp-352be.web.app/table-bill?tableId=$id';

  /// Create from Firestore document
  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      name: data['name'] ?? 'Table',
      capacity: data['capacity'] ?? 4,
      location: TableLocation.fromString(data['location']),
      status: TableStatus.fromString(data['status']),
      isActive: data['isActive'] ?? true,
      currentOrderId: data['currentOrderId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'location': location.name,
      'status': status.name,
      'isActive': isActive,
      'currentOrderId': currentOrderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  TableModel copyWith({
    String? id,
    String? name,
    int? capacity,
    TableLocation? location,
    TableStatus? status,
    bool? isActive,
    String? currentOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TableModel(id: $id, name: $name, capacity: $capacity, status: $status)';
  }
}
