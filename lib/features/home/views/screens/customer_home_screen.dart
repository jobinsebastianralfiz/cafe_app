import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../orders/viewmodels/order_viewmodel.dart';
import '../../../venue/viewmodels/venue_viewmodel.dart';
import '../../../menu/viewmodels/menu_viewmodel.dart';
import '../../../menu/views/widgets/menu_item_grid_card.dart';
import '../widgets/venue_status_banner.dart';
import '../widgets/active_order_card.dart';

/// Bottom nav index provider
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Customer Home Screen - Cafe-style dashboard
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final activeOrders = ref.watch(userActiveOrdersProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context, ref, user),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(userActiveOrdersProvider);
            ref.invalidate(venueSettingsProvider);
            ref.invalidate(currentUserProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      // User Avatar
                      user.when(
                        data: (userData) => GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (userData?.name ?? 'G')[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                        loading: () => const SizedBox(width: 48, height: 48),
                        error: (_, __) => const SizedBox(width: 48, height: 48),
                      ),
                      const SizedBox(width: 12),
                      // Welcome text
                      Expanded(
                        child: user.when(
                          data: (userData) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome,',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                userData?.name ?? 'Guest',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const Text('Welcome'),
                        ),
                      ),
                      // Notification bell
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/menu'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: AppColors.textHint,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Search...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/menu'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Venue Status Banner
                const VenueStatusBanner(),

                // Promo Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.promoBannerGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today Only',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '50% OFF',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Super Discount',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/menu'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.textPrimary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Book Now',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Coffee cup illustration placeholder
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.coffee,
                            size: 50,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _QuickActionItem(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan QR',
                        color: const Color(0xFF5D4037),
                        onTap: () => context.push('/scan-table'),
                      ),
                      _QuickActionItem(
                        icon: Icons.table_restaurant_rounded,
                        label: 'Book Table',
                        color: const Color(0xFF4A6741),
                        onTap: () => context.push('/reservations'),
                      ),
                      _QuickActionItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Wallet',
                        color: const Color(0xFFC8A97E),
                        onTap: () => context.push('/wallet'),
                      ),
                      _QuickActionItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'My Orders',
                        color: const Color(0xFF2196F3),
                        onTap: () => context.push('/orders'),
                      ),
                      _QuickActionItem(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Specials',
                        color: const Color(0xFFFF9800),
                        onTap: () => context.push('/specials'),
                      ),
                      _QuickActionItem(
                        icon: Icons.movie_rounded,
                        label: 'Movie Night',
                        color: const Color(0xFF9C27B0),
                        onTap: () => context.push('/movies'),
                      ),
                      _QuickActionItem(
                        icon: Icons.sports_esports_rounded,
                        label: 'Games',
                        color: const Color(0xFFE53935),
                        onTap: () => context.push('/games'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Active Orders Section
                activeOrders.when(
                  data: (orders) {
                    if (orders.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Active Orders',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/orders'),
                                  child: Text(
                                    'View All',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                return ActiveOrderCard(order: orders[index]);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Category Chips & Products by Category
                categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) return const SizedBox();

                    // Deduplicate categories by name (keep first occurrence)
                    final seen = <String>{};
                    final uniqueCategories = categories.where((c) {
                      final key = c.name.toLowerCase().trim();
                      if (seen.contains(key)) return false;
                      seen.add(key);
                      return true;
                    }).toList();

                    final displayCategories =
                        (selectedCategory != null && selectedCategory.isNotEmpty)
                            ? uniqueCategories
                                .where((c) => c.id == selectedCategory)
                                .toList()
                            : uniqueCategories;

                    return Column(
                      children: [
                        // Category pills
                        Container(
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: uniqueCategories.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                final isSelected = selectedCategory == null ||
                                    selectedCategory.isEmpty;
                                return _CategoryPill(
                                  label: 'All',
                                  isSelected: isSelected,
                                  onTap: () {
                                    ref.read(selectedCategoryProvider.notifier).state =
                                        null;
                                  },
                                );
                              }
                              final category = uniqueCategories[index - 1];
                              return _CategoryPill(
                                label: category.name,
                                isSelected: selectedCategory == category.id,
                                onTap: () {
                                  ref.read(selectedCategoryProvider.notifier).state =
                                      category.id;
                                },
                              );
                            },
                          ),
                        ),

                        // Product sections per category
                        ...displayCategories
                            .map((category) => _CategoryProductsSection(
                                  categoryId: category.id,
                                  categoryName: category.name,
                                )),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, ref, cartItemCount),
    );
  }
}

/// Category pill widget matching the design
class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick action item widget
class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Category section showing items in a horizontal scroll
class _CategoryProductsSection extends ConsumerWidget {
  final String categoryId;
  final String categoryName;

  const _CategoryProductsSection({
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(menuItemsByCategoryProvider(categoryId));

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(selectedCategoryProvider.notifier).state =
                            categoryId;
                        context.push('/menu');
                      },
                      child: Text(
                        'See All',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Horizontal product list
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 14),
                      child: MenuItemGridCard(
                        item: items[index],
                        onTap: () {
                          context.push('/menu/item/${items[index].id}');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Build drawer
Widget _buildDrawer(BuildContext context, WidgetRef ref, AsyncValue user) {
  return Drawer(
    backgroundColor: AppColors.surface,
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent, AppColors.accentDark],
            ),
          ),
          child: user.when(
            data: (userData) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (userData?.name ?? 'G')[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userData?.name ?? 'Guest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userData?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (_, __) => const Text('Error'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: const Text('Home'),
          onTap: () {
            Navigator.pop(context);
            context.go('/');
          },
        ),
        ListTile(
          leading: const Icon(Icons.restaurant_menu),
          title: const Text('Menu'),
          onTap: () {
            Navigator.pop(context);
            context.push('/menu');
          },
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('My Orders'),
          onTap: () {
            Navigator.pop(context);
            context.push('/orders');
          },
        ),
        ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: const Text('Wallet'),
          onTap: () {
            Navigator.pop(context);
            context.push('/wallet');
          },
        ),
        const Divider(color: AppColors.divider),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Profile'),
          onTap: () {
            Navigator.pop(context);
            context.push('/profile');
          },
        ),
        ListTile(
          leading: const Icon(Icons.qr_code_scanner),
          title: const Text('Scan Table QR'),
          onTap: () {
            Navigator.pop(context);
            context.push('/scan-table');
          },
        ),
        ListTile(
          leading: const Icon(Icons.table_restaurant_outlined),
          title: const Text('Book Table'),
          onTap: () {
            Navigator.pop(context);
            context.push('/reservations');
          },
        ),
        const Divider(color: AppColors.divider),
        ListTile(
          leading: const Icon(Icons.movie_outlined),
          title: const Text('Movie Night'),
          onTap: () {
            Navigator.pop(context);
            context.push('/movies');
          },
        ),
        ListTile(
          leading: const Icon(Icons.sports_esports_outlined),
          title: const Text('Saturday Games'),
          onTap: () {
            Navigator.pop(context);
            context.push('/games');
          },
        ),
        ListTile(
          leading: const Icon(Icons.local_fire_department_outlined),
          title: const Text('Daily Specials'),
          onTap: () {
            Navigator.pop(context);
            context.push('/specials');
          },
        ),
        const Divider(color: AppColors.divider),
        ListTile(
          leading: Icon(Icons.logout, color: AppColors.error),
          title: Text('Logout', style: TextStyle(color: AppColors.error)),
          onTap: () {
            Navigator.pop(context);
            ref.read(authViewModelProvider.notifier).signOut();
            context.go('/login');
          },
        ),
      ],
    ),
  );
}

/// Build bottom navigation - cafe style
Widget _buildBottomNav(BuildContext context, WidgetRef ref, int cartCount) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: true,
              onTap: () => context.go('/'),
            ),
            _buildNavItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Cart',
              isSelected: false,
              badge: cartCount > 0 ? cartCount.toString() : null,
              onTap: () => context.push('/cart'),
            ),
            _buildNavItem(
              icon: Icons.favorite_outline,
              label: 'Favorites',
              isSelected: false,
              onTap: () => context.push('/menu'),
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              isSelected: false,
              onTap: () => context.push('/profile'),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildNavItem({
  required IconData icon,
  required String label,
  required bool isSelected,
  String? badge,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.textPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textHint,
                size: 22,
              ),
              if (badge != null)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}