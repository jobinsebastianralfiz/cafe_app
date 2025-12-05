import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/constants/firebase_constants.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';

/// Menu Service - Handles menu data from Firestore
class MenuService {
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // Get all active categories (ordered)
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection(FirebaseConstants.menuCollection)
        .doc('categories')
        .collection('list')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  // Get all categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.menuCollection)
          .doc('categories')
          .collection('list')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Get menu items by category
  Stream<List<MenuItemModel>> getMenuItemsByCategoryStream(String categoryId) {
    return _firestore
        .collection(FirebaseConstants.menuCollection)
        .doc('items')
        .collection('list')
        .where('categoryId', isEqualTo: categoryId)
        .where('isAvailable', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  // Get all menu items
  Stream<List<MenuItemModel>> getAllMenuItemsStream() {
    return _firestore
        .collection(FirebaseConstants.menuCollection)
        .doc('items')
        .collection('list')
        .where('isAvailable', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  // Get menu item by ID
  Future<MenuItemModel?> getMenuItem(String itemId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.menuCollection)
          .doc('items')
          .collection('list')
          .doc(itemId)
          .get();

      if (!doc.exists) return null;

      return MenuItemModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch menu item: $e');
    }
  }

  // Search menu items
  Future<List<MenuItemModel>> searchMenuItems(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection(FirebaseConstants.menuCollection)
          .doc('items')
          .collection('list')
          .where('isAvailable', isEqualTo: true)
          .get();

      final allItems = snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();

      // Filter by name or description containing query (case-insensitive)
      final searchQuery = query.toLowerCase();
      return allItems.where((item) {
        return item.name.toLowerCase().contains(searchQuery) ||
            item.description.toLowerCase().contains(searchQuery) ||
            item.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search menu items: $e');
    }
  }

  // Get popular items
  Stream<List<MenuItemModel>> getPopularItemsStream() {
    return _firestore
        .collection(FirebaseConstants.menuCollection)
        .doc('items')
        .collection('list')
        .where('isAvailable', isEqualTo: true)
        .where('averageRating', isGreaterThanOrEqualTo: 4.0)
        .orderBy('averageRating', descending: true)
        .orderBy('totalRatings', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  // Get veg items only
  Stream<List<MenuItemModel>> getVegItemsStream() {
    return _firestore
        .collection(FirebaseConstants.menuCollection)
        .doc('items')
        .collection('list')
        .where('isAvailable', isEqualTo: true)
        .where('isVeg', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  // Get new items (added within last 7 days)
  Stream<List<MenuItemModel>> getNewItemsStream() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection(FirebaseConstants.menuCollection)
        .doc('items')
        .collection('list')
        .where('isAvailable', isEqualTo: true)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  // Admin: Add category
  Future<void> addCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection(FirebaseConstants.menuCollection)
          .doc('categories')
          .collection('list')
          .add(category.toMap());
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // Admin: Update category
  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirebaseConstants.menuCollection)
          .doc('categories')
          .collection('list')
          .doc(categoryId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Admin: Add menu item
  Future<void> addMenuItem(MenuItemModel item) async {
    try {
      await _firestore
          .collection(FirebaseConstants.menuCollection)
          .doc('items')
          .collection('list')
          .add(item.toMap());
    } catch (e) {
      throw Exception('Failed to add menu item: $e');
    }
  }

  // Admin: Update menu item
  Future<void> updateMenuItem(String itemId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(FirebaseConstants.menuCollection)
          .doc('items')
          .collection('list')
          .doc(itemId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  // Admin: Delete menu item (soft delete - set isAvailable to false)
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await updateMenuItem(itemId, {'isAvailable': false});
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }

  // Update item rating
  Future<void> updateItemRating(String itemId, double newRating) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore
            .collection(FirebaseConstants.menuCollection)
            .doc('items')
            .collection('list')
            .doc(itemId);

        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw Exception('Item not found');
        }

        final currentRating = (doc.data()?['averageRating'] ?? 0).toDouble();
        final totalRatings = (doc.data()?['totalRatings'] ?? 0) as int;

        // Calculate new average
        final newTotal = totalRatings + 1;
        final newAverage = ((currentRating * totalRatings) + newRating) / newTotal;

        transaction.update(docRef, {
          'averageRating': newAverage,
          'totalRatings': newTotal,
        });
      });
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }
}
