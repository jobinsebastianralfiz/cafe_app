import 'package:cloud_firestore/cloud_firestore.dart';

/// User Model with Role-based Access
class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? profilePhoto;
  final List<AddressModel> addresses;
  final int coinBalance;
  final String loyaltyTier; // bronze, silver, gold, platinum
  final UserRole role; // Role-based access
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.profilePhoto,
    this.addresses = const [],
    this.coinBalance = 0,
    this.loyaltyTier = 'bronze',
    this.role = UserRole.customer,
    required this.createdAt,
    required this.lastActive,
  });

  // Check role permissions
  bool get isCustomer => role == UserRole.customer;
  bool get isStaff => role == UserRole.staff;
  bool get isWaiter => role == UserRole.waiter;
  bool get isKitchen => role == UserRole.kitchen;
  bool get isDelivery => role == UserRole.delivery;
  bool get isAdmin => role == UserRole.admin;

  // Check if user has staff privileges (any staff role)
  bool get hasStaffAccess =>
      isStaff || isWaiter || isKitchen || isDelivery || isAdmin;

  // Check if user has admin privileges
  bool get hasAdminAccess => isAdmin;

  // Factory constructor from Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      profilePhoto: data['profilePhoto'],
      addresses: (data['addresses'] as List<dynamic>?)
              ?.map((addr) => AddressModel.fromMap(addr as Map<String, dynamic>))
              .toList() ??
          [],
      coinBalance: data['coinBalance'] ?? 0,
      loyaltyTier: data['loyaltyTier'] ?? 'bronze',
      role: UserRole.fromString(data['role'] ?? 'customer'),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'coinBalance': coinBalance,
      'loyaltyTier': loyaltyTier,
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  // Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profilePhoto,
    List<AddressModel>? addresses,
    int? coinBalance,
    String? loyaltyTier,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      addresses: addresses ?? this.addresses,
      coinBalance: coinBalance ?? this.coinBalance,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

/// User Role Enum - Role-based Access Control
enum UserRole {
  customer('customer'),
  staff('staff'),
  waiter('waiter'),
  kitchen('kitchen'),
  delivery('delivery'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'staff':
        return UserRole.staff;
      case 'waiter':
        return UserRole.waiter;
      case 'kitchen':
        return UserRole.kitchen;
      case 'delivery':
        return UserRole.delivery;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer; // Default to customer
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.staff:
        return 'Staff';
      case UserRole.waiter:
        return 'Waiter';
      case UserRole.kitchen:
        return 'Kitchen Staff';
      case UserRole.delivery:
        return 'Delivery Rider';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// Address Model
class AddressModel {
  final String id;
  final String label; // Home, Work, Other
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  AddressModel({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  // From map
  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      label: map['label'] ?? 'Other',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      landmark: map['landmark'],
      isDefault: map['isDefault'] ?? false,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Full address as string
  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null) addressLine2!,
      if (landmark != null) landmark!,
      city,
      state,
      pincode,
    ];
    return parts.join(', ');
  }

  // Copy with
  AddressModel copyWith({
    String? id,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
