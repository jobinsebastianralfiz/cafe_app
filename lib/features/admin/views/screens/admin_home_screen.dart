import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';

/// Admin Home Screen - Dashboard for admin users
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: user.when(
                data: (userData) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome, ${userData?.name ?? "Admin"}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your cafe from here',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(color: Colors.white),
                error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),

            // Admin Actions Grid
            Text(
              'Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _AdminCard(
                  icon: Icons.people,
                  title: 'User Management',
                  subtitle: 'Manage staff & roles',
                  color: Colors.blue,
                  onTap: () => context.push('/admin/users'),
                ),
                _AdminCard(
                  icon: Icons.restaurant_menu,
                  title: 'Menu Management',
                  subtitle: 'Items & categories',
                  color: Colors.orange,
                  onTap: () => context.push('/admin/menu'),
                ),
                _AdminCard(
                  icon: Icons.receipt_long,
                  title: 'Orders',
                  subtitle: 'View all orders',
                  color: Colors.green,
                  onTap: () => context.push('/admin/orders'),
                ),
                _AdminCard(
                  icon: Icons.store,
                  title: 'Venue Settings',
                  subtitle: 'Hours & tables',
                  color: Colors.teal,
                  onTap: () => context.push('/admin/venue'),
                ),
                _AdminCard(
                  icon: Icons.local_fire_department,
                  title: 'Daily Specials',
                  subtitle: 'Manage specials',
                  color: Colors.red,
                  onTap: () => context.push('/admin/specials'),
                ),
                _AdminCard(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'Sales & reports',
                  color: Colors.indigo,
                  onTap: () => context.push('/admin/analytics'),
                ),
                _AdminCard(
                  icon: Icons.table_restaurant,
                  title: 'Tables',
                  subtitle: 'Manage & QR codes',
                  color: Colors.cyan,
                  onTap: () => context.push('/admin/tables'),
                ),
                _AdminCard(
                  icon: Icons.movie,
                  title: 'Movie Night',
                  subtitle: 'Polls & screenings',
                  color: Colors.deepPurple,
                  onTap: () => context.push('/admin/movies'),
                ),
                _AdminCard(
                  icon: Icons.casino,
                  title: 'Saturday Games',
                  subtitle: 'Sessions & library',
                  color: Colors.teal,
                  onTap: () => context.push('/admin/games'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seed Data Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _seedSampleData(context),
                icon: const Icon(Icons.data_saver_on),
                label: const Text('Load Sample Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedSampleData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Sample Data?'),
        content: const Text('This will add sample categories and menu items to your database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Load')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final firestore = FirebaseFirestore.instance;

      // Sample Categories
      final categories = [
        {'name': 'Coffee & Beverages', 'description': 'Hot and cold drinks', 'order': 1, 'isActive': true},
        {'name': 'Breakfast', 'description': 'Morning favorites', 'order': 2, 'isActive': true},
        {'name': 'Main Course', 'description': 'Lunch and dinner items', 'order': 3, 'isActive': true},
        {'name': 'Snacks', 'description': 'Light bites', 'order': 4, 'isActive': true},
        {'name': 'Desserts', 'description': 'Sweet treats', 'order': 5, 'isActive': true},
      ];

      Map<String, String> categoryIds = {};
      for (var cat in categories) {
        final docRef = await firestore
            .collection('menu')
            .doc('categories')
            .collection('list')
            .add({
          ...cat,
          'createdAt': FieldValue.serverTimestamp(),
        });
        categoryIds[cat['name'] as String] = docRef.id;
      }

      // Sample Menu Items
      final items = [
        {'name': 'Espresso', 'description': 'Strong Italian coffee', 'price': 80.0, 'categoryId': categoryIds['Coffee & Beverages'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 5},
        {'name': 'Cappuccino', 'description': 'Espresso with steamed milk foam', 'price': 120.0, 'categoryId': categoryIds['Coffee & Beverages'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 5},
        {'name': 'Latte', 'description': 'Smooth coffee with milk', 'price': 130.0, 'categoryId': categoryIds['Coffee & Beverages'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 5},
        {'name': 'Cold Brew', 'description': 'Slow-steeped cold coffee', 'price': 150.0, 'categoryId': categoryIds['Coffee & Beverages'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 3},
        {'name': 'Fresh Orange Juice', 'description': 'Freshly squeezed oranges', 'price': 100.0, 'categoryId': categoryIds['Coffee & Beverages'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 5},

        {'name': 'Eggs Benedict', 'description': 'Poached eggs on English muffin with hollandaise', 'price': 220.0, 'categoryId': categoryIds['Breakfast'], 'isVeg': false, 'isAvailable': true, 'preparationTime': 15},
        {'name': 'Avocado Toast', 'description': 'Smashed avocado on sourdough', 'price': 180.0, 'categoryId': categoryIds['Breakfast'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 10},
        {'name': 'Pancakes', 'description': 'Fluffy pancakes with maple syrup', 'price': 160.0, 'categoryId': categoryIds['Breakfast'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 12},
        {'name': 'Masala Omelette', 'description': 'Spiced omelette with onions and tomatoes', 'price': 120.0, 'categoryId': categoryIds['Breakfast'], 'isVeg': false, 'isAvailable': true, 'preparationTime': 10},

        {'name': 'Grilled Chicken Sandwich', 'description': 'Juicy grilled chicken with veggies', 'price': 250.0, 'categoryId': categoryIds['Main Course'], 'isVeg': false, 'isAvailable': true, 'preparationTime': 15},
        {'name': 'Paneer Tikka', 'description': 'Marinated cottage cheese grilled to perfection', 'price': 220.0, 'categoryId': categoryIds['Main Course'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 20},
        {'name': 'Pasta Alfredo', 'description': 'Creamy white sauce pasta', 'price': 240.0, 'categoryId': categoryIds['Main Course'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 18},
        {'name': 'Chicken Biryani', 'description': 'Fragrant rice with spiced chicken', 'price': 280.0, 'categoryId': categoryIds['Main Course'], 'isVeg': false, 'isAvailable': true, 'preparationTime': 25},

        {'name': 'French Fries', 'description': 'Crispy golden fries', 'price': 100.0, 'categoryId': categoryIds['Snacks'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 8},
        {'name': 'Samosa', 'description': 'Crispy pastry with spiced potato filling', 'price': 40.0, 'categoryId': categoryIds['Snacks'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 5},
        {'name': 'Chicken Wings', 'description': 'Spicy buffalo wings', 'price': 200.0, 'categoryId': categoryIds['Snacks'], 'isVeg': false, 'isAvailable': true, 'preparationTime': 15},

        {'name': 'Chocolate Brownie', 'description': 'Rich chocolate brownie with ice cream', 'price': 150.0, 'categoryId': categoryIds['Desserts'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 5},
        {'name': 'Gulab Jamun', 'description': 'Sweet milk dumplings in sugar syrup', 'price': 80.0, 'categoryId': categoryIds['Desserts'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 3},
        {'name': 'Cheesecake', 'description': 'New York style cheesecake', 'price': 180.0, 'categoryId': categoryIds['Desserts'], 'isVeg': true, 'isAvailable': true, 'preparationTime': 5},
      ];

      for (var item in items) {
        await firestore
            .collection('menu')
            .doc('items')
            .collection('list')
            .add({
          ...item,
          'photos': [],
          'tags': [],
          'ingredients': [],
          'averageRating': 0.0,
          'totalRatings': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // ===== ENTERTAINMENT DATA =====

      // Sample Board Games
      final boardGames = [
        {'name': 'Catan', 'players': '3-4', 'duration': '60-90 min', 'description': 'Build settlements and trade resources'},
        {'name': 'Ticket to Ride', 'players': '2-5', 'duration': '45-60 min', 'description': 'Collect train cards and claim railway routes'},
        {'name': 'Uno', 'players': '2-10', 'duration': '20-30 min', 'description': 'Classic card matching game'},
        {'name': 'Chess', 'players': '2', 'duration': '30-60 min', 'description': 'Classic strategy board game'},
        {'name': 'Scrabble', 'players': '2-4', 'duration': '60-90 min', 'description': 'Word building game'},
        {'name': 'Monopoly', 'players': '2-6', 'duration': '60-180 min', 'description': 'Buy properties and bankrupt opponents'},
        {'name': 'Codenames', 'players': '4-8', 'duration': '15-20 min', 'description': 'Team-based word guessing game'},
      ];

      for (var game in boardGames) {
        await firestore.collection('boardGames').add({
          ...game,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Sample Game Session (next Saturday)
      var nextSaturday = DateTime.now();
      while (nextSaturday.weekday != DateTime.saturday) {
        nextSaturday = nextSaturday.add(const Duration(days: 1));
      }

      await firestore.collection('gameSessions').add({
        'date': DateFormat('yyyy-MM-dd').format(nextSaturday),
        'time': '6:00 PM',
        'maxPlayers': 20,
        'games': boardGames.take(5).toList(),
        'players': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sample Movie Poll
      await firestore.collection('moviePolls').add({
        'isActive': true,
        'eventDate': DateFormat('MMM dd, yyyy').format(nextSaturday.add(const Duration(days: 7))),
        'movies': [
          {'name': 'Inception', 'votes': 5},
          {'name': 'The Dark Knight', 'votes': 8},
          {'name': 'Interstellar', 'votes': 3},
          {'name': 'The Matrix', 'votes': 4},
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sample Past Screenings
      await firestore.collection('movieScreenings').add({
        'movieName': 'Dune',
        'date': DateFormat('MMM dd, yyyy').format(DateTime.now().subtract(const Duration(days: 14))),
        'attendees': 25,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample data loaded! Menu, games & movie poll added.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}