/// Order Pricing Model - Pricing breakdown for orders
class OrderPricingModel {
  final double subtotal;
  final double deliveryCharges;
  final double taxAmount;
  final double coinDiscount;
  final double totalAmount;
  final double finalAmount;

  OrderPricingModel({
    required this.subtotal,
    required this.deliveryCharges,
    required this.taxAmount,
    required this.coinDiscount,
    required this.totalAmount,
    required this.finalAmount,
  });

  // From map
  factory OrderPricingModel.fromMap(Map<String, dynamic> map) {
    return OrderPricingModel(
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryCharges: (map['deliveryCharges'] ?? 0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0).toDouble(),
      coinDiscount: (map['coinDiscount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      finalAmount: (map['finalAmount'] ?? 0).toDouble(),
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'deliveryCharges': deliveryCharges,
      'taxAmount': taxAmount,
      'coinDiscount': coinDiscount,
      'totalAmount': totalAmount,
      'finalAmount': finalAmount,
    };
  }

  // Format amounts
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(0)}';
  String get formattedDeliveryCharges => '₹${deliveryCharges.toStringAsFixed(0)}';
  String get formattedTaxAmount => '₹${taxAmount.toStringAsFixed(0)}';
  String get formattedCoinDiscount => '-₹${coinDiscount.toStringAsFixed(0)}';
  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(0)}';
  String get formattedFinalAmount => '₹${finalAmount.toStringAsFixed(0)}';

  // Copy with
  OrderPricingModel copyWith({
    double? subtotal,
    double? deliveryCharges,
    double? taxAmount,
    double? coinDiscount,
    double? totalAmount,
    double? finalAmount,
  }) {
    return OrderPricingModel(
      subtotal: subtotal ?? this.subtotal,
      deliveryCharges: deliveryCharges ?? this.deliveryCharges,
      taxAmount: taxAmount ?? this.taxAmount,
      coinDiscount: coinDiscount ?? this.coinDiscount,
      totalAmount: totalAmount ?? this.totalAmount,
      finalAmount: finalAmount ?? this.finalAmount,
    );
  }
}
