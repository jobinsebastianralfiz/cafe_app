import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/menu_service.dart';
import '../services/cart_service.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/cart_item_model.dart';

// Menu Service Provider
final menuServiceProvider = Provider<MenuService>((ref) => MenuService());

// Cart Service Provider
final cartServiceProvider = Provider<CartService>((ref) {
  final service = CartService();
  // init() is sync-safe since box is already opened in main.dart
  service.init();
  return service;
});

// Categories Stream Provider
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.getCategoriesStream();
});

// All Menu Items Stream Provider
final allMenuItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.getAllMenuItemsStream();
});

// Menu Items by Category Provider
final menuItemsByCategoryProvider = StreamProvider.family<List<MenuItemModel>, String>(
  (ref, categoryId) {
    final menuService = ref.watch(menuServiceProvider);
    return menuService.getMenuItemsByCategoryStream(categoryId);
  },
);

// Popular Items Provider
final popularItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.getPopularItemsStream();
});

// Veg Items Provider
final vegItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.getVegItemsStream();
});

// New Items Provider
final newItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.getNewItemsStream();
});

// Selected Category Provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Menu Items Provider (based on search and category)
final filteredMenuItemsProvider = Provider<AsyncValue<List<MenuItemModel>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  // If search query exists, filter all items
  if (searchQuery.isNotEmpty) {
    final allItems = ref.watch(allMenuItemsProvider);
    return allItems.whenData((items) {
      final query = searchQuery.toLowerCase();
      return items.where((item) {
        final matchesSearch = item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.tags.any((tag) => tag.toLowerCase().contains(query));

        final matchesCategory = selectedCategory == null ||
            selectedCategory.isEmpty ||
            item.categoryId == selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // If category is selected, show items from that category
  if (selectedCategory != null && selectedCategory.isNotEmpty) {
    return ref.watch(menuItemsByCategoryProvider(selectedCategory));
  }

  // Otherwise show all items
  return ref.watch(allMenuItemsProvider);
});

// Cart Items Provider (from Hive)
final cartItemsProvider = StreamProvider<List<CartItemModel>>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  return cartService.watchCart();
});

// Cart Item Count Provider
final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartItemsProvider);
  return cartItems.maybeWhen(
    data: (items) => items.fold<int>(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

// Cart Total Provider
final cartTotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartItemsProvider);
  return cartItems.maybeWhen(
    data: (items) => items.fold<double>(0.0, (sum, item) => sum + item.subtotal),
    orElse: () => 0.0,
  );
});

// Is In Cart Provider
final isInCartProvider = Provider.family<bool, String>((ref, itemId) {
  final cartItems = ref.watch(cartItemsProvider);
  return cartItems.maybeWhen(
    data: (items) => items.any((item) => item.itemId == itemId),
    orElse: () => false,
  );
});

// Item Quantity in Cart Provider
final itemQuantityInCartProvider = Provider.family<int, String>((ref, itemId) {
  final cartItems = ref.watch(cartItemsProvider);
  return cartItems.maybeWhen(
    data: (items) {
      final item = items.where((item) => item.itemId == itemId).firstOrNull;
      return item?.quantity ?? 0;
    },
    orElse: () => 0,
  );
});

// Cart Actions Provider
final cartActionsProvider = Provider<CartActions>((ref) {
  return CartActions(ref);
});

/// Cart Actions Class
class CartActions {
  final Ref ref;

  CartActions(this.ref);

  Future<void> addToCart(MenuItemModel item) async {
    final cartService = ref.read(cartServiceProvider);
    await cartService.addToCart(item);
  }

  Future<void> removeFromCart(String itemId) async {
    final cartService = ref.read(cartServiceProvider);
    await cartService.removeFromCart(itemId);
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    final cartService = ref.read(cartServiceProvider);
    await cartService.updateQuantity(itemId, quantity);
  }

  Future<void> incrementQuantity(String itemId) async {
    final cartService = ref.read(cartServiceProvider);
    await cartService.incrementQuantity(itemId);
  }

  Future<void> decrementQuantity(String itemId) async {
    final cartService = ref.read(cartServiceProvider);
    await cartService.decrementQuantity(itemId);
  }

  Future<void> clearCart() async {
    final cartService = ref.read(cartServiceProvider);
    await cartService.clearCart();
  }

  Future<void> addSpecialInstructions(String itemId, String instructions) async {
    final cartService = ref.read(cartServiceProvider);
    await cartService.addSpecialInstructions(itemId, instructions);
  }
}
