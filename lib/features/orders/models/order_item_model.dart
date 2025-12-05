/// Order Item Model - Items in an order
class OrderItemModel {
  final String itemId;
  final String itemName;
  final int quantity;
  final double price;
  final double subtotal;
  final String? specialInstructions;

  OrderItemModel({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.specialInstructions,
  });

  // From map
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      specialInstructions: map['specialInstructions'],
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'specialInstructions': specialInstructions,
    };
  }

  // Format price
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(0)}';
}
