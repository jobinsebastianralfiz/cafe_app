import 'package:hive/hive.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

/// Cart Service - Handles cart persistence with Hive
class CartService {
  static const String _cartBoxName = 'cart';
  Box<CartItemModel>? _cartBox;

  // Initialize cart box
  Future<void> init() async {
    if (!Hive.isBoxOpen(_cartBoxName)) {
      _cartBox = await Hive.openBox<CartItemModel>(_cartBoxName);
    } else {
      _cartBox = Hive.box<CartItemModel>(_cartBoxName);
    }
  }

  // Get cart box - auto-initialize if already open
  Box<CartItemModel> get _box {
    if (_cartBox == null || !_cartBox!.isOpen) {
      // Try to get the already-open box (opened in main.dart)
      if (Hive.isBoxOpen(_cartBoxName)) {
        _cartBox = Hive.box<CartItemModel>(_cartBoxName);
      } else {
        throw Exception('Cart box not initialized. Call init() first.');
      }
    }
    return _cartBox!;
  }

  // Get all cart items
  List<CartItemModel> getCartItems() {
    try {
      return _box.values.toList();
    } catch (e) {
      return [];
    }
  }

  // Get cart items as stream (emits current items first, then changes)
  Stream<List<CartItemModel>> watchCart() async* {
    // Emit current items immediately
    yield _box.values.toList();
    // Then listen for changes
    await for (final _ in _box.watch()) {
      yield _box.values.toList();
    }
  }

  // Add item to cart
  Future<void> addToCart(MenuItemModel item) async {
    try {
      // Check if item already exists
      final existingIndex = _box.values.toList().indexWhere(
            (cartItem) => cartItem.itemId == item.id,
          );

      if (existingIndex != -1) {
        // Item exists, increment quantity
        final existingItem = _box.getAt(existingIndex)!;
        existingItem.quantity++;
        await existingItem.save();
      } else {
        // New item, add to cart
        final cartItem = CartItemModel.fromMenuItem(item);
        await _box.add(cartItem);
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    try {
      final items = _box.values.toList();
      final index = items.indexWhere((item) => item.itemId == itemId);

      if (index != -1) {
        await _box.deleteAt(index);
      }
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(itemId);
        return;
      }

      final items = _box.values.toList();
      final index = items.indexWhere((item) => item.itemId == itemId);

      if (index != -1) {
        final item = _box.getAt(index)!;
        item.quantity = quantity;
        await item.save();
      }
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  // Increment quantity
  Future<void> incrementQuantity(String itemId) async {
    try {
      final items = _box.values.toList();
      final index = items.indexWhere((item) => item.itemId == itemId);

      if (index != -1) {
        final item = _box.getAt(index)!;
        item.quantity++;
        await item.save();
      }
    } catch (e) {
      throw Exception('Failed to increment quantity: $e');
    }
  }

  // Decrement quantity
  Future<void> decrementQuantity(String itemId) async {
    try {
      final items = _box.values.toList();
      final index = items.indexWhere((item) => item.itemId == itemId);

      if (index != -1) {
        final item = _box.getAt(index)!;
        if (item.quantity > 1) {
          item.quantity--;
          await item.save();
        } else {
          await removeFromCart(itemId);
        }
      }
    } catch (e) {
      throw Exception('Failed to decrement quantity: $e');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      await _box.clear();
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Get cart item count
  int getItemCount() {
    return _box.values.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  // Get cart total
  double getCartTotal() {
    return _box.values.fold<double>(0.0, (sum, item) => sum + item.subtotal);
  }

  // Check if item is in cart
  bool isInCart(String itemId) {
    return _box.values.any((item) => item.itemId == itemId);
  }

  // Get item quantity in cart
  int getItemQuantity(String itemId) {
    final item = _box.values.firstWhere(
      (item) => item.itemId == itemId,
      orElse: () => CartItemModel(
        itemId: '',
        name: '',
        description: '',
        price: 0,
        imageUrl: '',
        isVeg: true,
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Add special instructions to item
  Future<void> addSpecialInstructions(
    String itemId,
    String instructions,
  ) async {
    try {
      final items = _box.values.toList();
      final index = items.indexWhere((item) => item.itemId == itemId);

      if (index != -1) {
        final item = _box.getAt(index)!;
        final updatedItem = item.copyWith(specialInstructions: instructions);
        await _box.putAt(index, updatedItem);
      }
    } catch (e) {
      throw Exception('Failed to add special instructions: $e');
    }
  }

  // Close cart box
  Future<void> close() async {
    if (_cartBox != null && _cartBox!.isOpen) {
      await _cartBox!.close();
    }
  }
}
