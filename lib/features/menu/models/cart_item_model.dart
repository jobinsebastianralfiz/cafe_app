import 'package:hive/hive.dart';
import 'menu_item_model.dart';

part 'cart_item_model.g.dart';

/// Cart Item Model with Hive Persistence
@HiveType(typeId: 0)
class CartItemModel extends HiveObject {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  final bool isVeg;

  @HiveField(6)
  int quantity;

  @HiveField(7)
  final String? specialInstructions;

  CartItemModel({
    required this.itemId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isVeg,
    this.quantity = 1,
    this.specialInstructions,
  });

  // Create from MenuItem
  factory CartItemModel.fromMenuItem(MenuItemModel item) {
    return CartItemModel(
      itemId: item.id,
      name: item.name,
      description: item.description,
      price: item.price,
      imageUrl: item.mainPhoto,
      isVeg: item.isVeg,
      quantity: 1,
    );
  }

  // Calculate subtotal
  double get subtotal => price * quantity;

  // Format subtotal
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(0)}';

  // Format price
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  // To map for order
  Map<String, dynamic> toOrderMap() {
    return {
      'itemId': itemId,
      'itemName': name,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'specialInstructions': specialInstructions,
    };
  }

  // Copy with
  CartItemModel copyWith({
    String? itemId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isVeg,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItemModel(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isVeg: isVeg ?? this.isVeg,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}
