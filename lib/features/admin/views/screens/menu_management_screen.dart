import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../menu/models/menu_item_model.dart';
import '../../../menu/models/category_model.dart';

/// Provider to fetch all menu items
final adminMenuItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('menu')
      .doc('items')
      .collection('list')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

/// Provider to fetch all categories
final adminCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('menu')
      .doc('categories')
      .collection('list')
      .orderBy('order')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList());
});

/// Menu Management Screen
class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Items', icon: Icon(Icons.fastfood)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddItemDialog(context, ref);
          } else {
            _showAddCategoryDialog(context);
          }
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ItemsTab(),
          _CategoriesTab(),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddEditItemScreen(categories: ref.read(adminCategoriesProvider).valueOrNull ?? []),

      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final orderController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name*'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Display Order'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter category name')),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('menu')
                  .doc('categories')
                  .collection('list')
                  .add({
                'name': nameController.text.trim(),
                'description': descController.text.trim(),
                'order': int.tryParse(orderController.text) ?? 0,
                'isActive': true,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ItemsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(adminMenuItemsProvider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No menu items. Tap + to add.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: item.photos.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.mainPhoto,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood),
                          ),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fastfood),
                      ),
                title: Row(
                  children: [
                    if (item.isVeg)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Icon(Icons.circle, color: Colors.green, size: 8),
                      ),
                    Expanded(child: Text(item.name)),
                  ],
                ),
                subtitle: Text('₹${item.price.toStringAsFixed(0)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: item.isAvailable,
                      onChanged: (value) async {
                        await FirebaseFirestore.instance
                            .collection('menu')
                            .doc('items')
                            .collection('list')
                            .doc(item.id)
                            .update({'isAvailable': value});
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showEditItemDialog(context, ref, item);
                        } else if (action == 'delete') {
                          _deleteItem(context, item);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showEditItemDialog(BuildContext context, WidgetRef ref, MenuItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddEditItemScreen(
          categories: ref.read(adminCategoriesProvider).valueOrNull ?? [],
          item: item,
        ),
      ),
    );
  }

  void _deleteItem(BuildContext context, MenuItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('menu')
                  .doc('items')
                  .collection('list')
                  .doc(item.id)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('No categories. Tap + to add.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(_getIconData(cat.name), color: AppColors.primary),
                ),
                title: Text(cat.name),
                subtitle: Text('Order: ${cat.order}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'delete') {
                      _deleteCategory(context, cat);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  IconData _getIconData(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('coffee') || lowerName.contains('beverage') || lowerName.contains('drink')) {
      return Icons.coffee;
    } else if (lowerName.contains('pizza')) {
      return Icons.local_pizza;
    } else if (lowerName.contains('burger') || lowerName.contains('fast')) {
      return Icons.fastfood;
    } else if (lowerName.contains('cake') || lowerName.contains('dessert') || lowerName.contains('sweet')) {
      return Icons.cake;
    } else if (lowerName.contains('ice') || lowerName.contains('cream')) {
      return Icons.icecream;
    } else if (lowerName.contains('breakfast')) {
      return Icons.egg_alt;
    } else if (lowerName.contains('lunch') || lowerName.contains('dinner') || lowerName.contains('main')) {
      return Icons.dinner_dining;
    } else if (lowerName.contains('snack')) {
      return Icons.cookie;
    } else {
      return Icons.restaurant;
    }
  }

  void _deleteCategory(BuildContext context, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('menu')
                  .doc('categories')
                  .collection('list')
                  .doc(cat.id)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Full-screen Add/Edit Item Form
class _AddEditItemScreen extends StatefulWidget {
  final List<CategoryModel> categories;
  final MenuItemModel? item; // null for add, non-null for edit

  const _AddEditItemScreen({required this.categories, this.item});

  @override
  State<_AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<_AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _prepTimeController;
  String? _selectedCategory;
  bool _isAvailable = true;
  bool _isVeg = true;
  bool _isLoading = false;
  bool _isUploading = false;
  File? _selectedImage;
  String? _imageUrl;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _priceController = TextEditingController(text: item?.price.toString() ?? '');
    _prepTimeController = TextEditingController(text: item?.preparationTime.toString() ?? '15');
    _selectedCategory = item?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _isAvailable = item?.isAvailable ?? true;
    _isVeg = item?.isVeg ?? true;
    _imageUrl = item?.photos.isNotEmpty == true ? item!.photos.first : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );

      if (picked != null) {
        // Copy to app's temp directory to ensure file persists
        final tempDir = await path_provider.getTemporaryDirectory();
        final fileName = 'picked_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(picked.path).copy('${tempDir.path}/$fileName');

        debugPrint('Image picked and saved to: ${savedImage.path}');
        debugPrint('File exists: ${await savedImage.exists()}');
        debugPrint('File size: ${await savedImage.length()} bytes');

        setState(() {
          _selectedImage = savedImage;
          _imageUrl = null; // Clear existing URL when new image selected
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrl;

    // Check if file exists
    if (!await _selectedImage!.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image file not found')),
        );
      }
      return _imageUrl;
    }

    setState(() => _isUploading = true);
    try {
      final fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('menu_images/$fileName');

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = ref.putFile(_selectedImage!, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      });

      // Wait for completion
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('Upload successful: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return _imageUrl; // Return existing URL if upload fails
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image if a new one was selected
      final uploadedUrl = await _uploadImage();

      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'photos': uploadedUrl != null ? [uploadedUrl] : [],
        'categoryId': _selectedCategory,
        'isAvailable': _isAvailable,
        'isVeg': _isVeg,
        'preparationTime': int.tryParse(_prepTimeController.text) ?? 15,
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('menu')
            .doc('items')
            .collection('list')
            .doc(widget.item!.id)
            .update(data);
      } else {
        data['tags'] = [];
        data['ingredients'] = [];
        data['averageRating'] = 0.0;
        data['totalRatings'] = 0;
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('menu')
            .doc('items')
            .collection('list')
            .add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Item updated!' : 'Item added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ))
          else
            TextButton(
              onPressed: _saveItem,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Preview & Picker
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : _imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                ),
                child: _selectedImage == null && _imageUrl == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text('Tap to add image', style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                          if (_isUploading)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Item Name *',
                prefixIcon: const Icon(Icons.fastfood),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Price & Prep Time Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price *',
                      prefixText: '₹ ',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Prep Time',
                      suffixText: 'mins',
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              items: widget.categories.map((cat) => DropdownMenuItem(
                value: cat.id,
                child: Text(cat.name),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 24),

            // Toggle Cards
            Row(
              children: [
                Expanded(
                  child: _ToggleCard(
                    title: 'Available',
                    subtitle: _isAvailable ? 'In stock' : 'Out of stock',
                    icon: _isAvailable ? Icons.check_circle : Icons.cancel,
                    color: _isAvailable ? Colors.green : Colors.red,
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ToggleCard(
                    title: 'Vegetarian',
                    subtitle: _isVeg ? 'Veg' : 'Non-Veg',
                    icon: Icons.eco,
                    color: _isVeg ? Colors.green : Colors.red,
                    value: _isVeg,
                    onChanged: (v) => setState(() => _isVeg = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'UPDATE ITEM' : 'ADD ITEM', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}