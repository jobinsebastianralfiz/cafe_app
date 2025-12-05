import 'package:cloud_firestore/cloud_firestore.dart';

/// Menu Item Model
class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final List<String> photos;
  final bool isAvailable;
  final bool isVeg;
  final List<String> tags;
  final int? calories;
  final List<String> ingredients;
  final double averageRating;
  final int totalRatings;
  final int preparationTime; // in minutes
  final DateTime createdAt;
  final DateTime? updatedAt;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.photos = const [],
    this.isAvailable = true,
    required this.isVeg,
    this.tags = const [],
    this.calories,
    this.ingredients = const [],
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.preparationTime = 15,
    required this.createdAt,
    this.updatedAt,
  });

  // From Firestore
  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MenuItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      isVeg: data['isVeg'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      calories: data['calories'],
      ingredients: List<String>.from(data['ingredients'] ?? []),
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      preparationTime: data['preparationTime'] ?? 15,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'photos': photos,
      'isAvailable': isAvailable,
      'isVeg': isVeg,
      'tags': tags,
      'calories': calories,
      'ingredients': ingredients,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'preparationTime': preparationTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Get main photo
  String get mainPhoto =>
      photos.isNotEmpty ? photos.first : 'https://via.placeholder.com/400';

  // Check if item is popular
  bool get isPopular => totalRatings >= 50 && averageRating >= 4.0;

  // Check if item is new (added within last 7 days)
  bool get isNew {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 7;
  }

  // Get preparation time string
  String get prepTimeString {
    if (preparationTime < 60) {
      return '$preparationTime mins';
    } else {
      final hours = preparationTime ~/ 60;
      final mins = preparationTime % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }

  // Format price
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  // Copy with
  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    List<String>? photos,
    bool? isAvailable,
    bool? isVeg,
    List<String>? tags,
    int? calories,
    List<String>? ingredients,
    double? averageRating,
    int? totalRatings,
    int? preparationTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      photos: photos ?? this.photos,
      isAvailable: isAvailable ?? this.isAvailable,
      isVeg: isVeg ?? this.isVeg,
      tags: tags ?? this.tags,
      calories: calories ?? this.calories,
      ingredients: ingredients ?? this.ingredients,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      preparationTime: preparationTime ?? this.preparationTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
