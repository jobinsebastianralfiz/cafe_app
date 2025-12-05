import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/models/user_model.dart';
import '../features/auth/viewmodels/auth_viewmodel.dart';
import '../features/auth/views/screens/splash_screen.dart';
import '../features/auth/views/screens/login_screen.dart';
import '../features/auth/views/screens/signup_screen.dart';
import '../features/auth/views/screens/forgot_password_screen.dart';
import '../features/menu/views/screens/menu_screen.dart';
import '../features/menu/views/screens/menu_item_detail_screen.dart';
import '../features/menu/views/screens/cart_screen.dart';
import '../features/menu/views/screens/qr_scanner_screen.dart';
import '../features/orders/views/screens/checkout_screen.dart';
import '../features/orders/views/screens/order_confirmation_screen.dart';
import '../features/orders/views/screens/order_history_screen.dart';
import '../features/home/views/screens/customer_home_screen.dart';
import '../features/wallet/views/screens/wallet_screen.dart';
import '../features/profile/views/screens/profile_screen.dart';
import '../features/profile/views/screens/address_list_screen.dart';
import '../features/profile/views/screens/add_edit_address_screen.dart';

// Admin screens
import '../features/admin/views/screens/admin_home_screen.dart';
import '../features/admin/views/screens/user_management_screen.dart';
import '../features/admin/views/screens/menu_management_screen.dart';
import '../features/admin/views/screens/admin_orders_screen.dart';
import '../features/admin/views/screens/venue_settings_screen.dart';
import '../features/admin/views/screens/daily_specials_screen.dart';
import '../features/admin/views/screens/analytics_screen.dart';
import '../features/admin/views/screens/table_management_screen.dart';
import '../features/admin/views/screens/movie_management_screen.dart';
import '../features/admin/views/screens/games_management_screen.dart';

// Customer entertainment screens
import '../features/entertainment/views/screens/movie_night_screen.dart';
import '../features/entertainment/views/screens/saturday_games_screen.dart';

// Reservation screens
import '../features/reservations/views/screens/reservation_screen.dart';
import '../features/reservations/views/screens/reservation_history_screen.dart';

// Notification screens
import '../features/notifications/views/screens/notifications_screen.dart';
import '../features/notifications/views/screens/notification_settings_screen.dart';

// Feedback screens
import '../features/feedback/views/screens/submit_review_screen.dart';
import '../features/feedback/views/screens/order_feedback_screen.dart';

// Daily Specials screens
import '../features/daily_specials/views/screens/specials_screen.dart';

// Role-based screens
import '../features/kitchen/views/screens/kitchen_home_screen.dart';
import '../features/waiter/views/screens/waiter_home_screen.dart';
import '../features/delivery/views/screens/delivery_home_screen.dart';
import '../features/staff/views/screens/staff_home_screen.dart';

// Billing screens (web-accessible)
import '../features/billing/views/screens/table_bill_screen.dart';

/// App Router with Role-Based Navigation
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // On web, don't set initialLocation to let URL determine route
    // On mobile, start at splash screen
    initialLocation: kIsWeb ? null : '/splash',

    // Redirect logic
    redirect: (context, state) {
      final path = state.uri.path;

      // Public routes that don't require auth
      final publicRoutes = ['/table-bill', '/login', '/signup', '/forgot-password', '/splash'];

      // If it's a public route, allow it
      if (publicRoutes.any((route) => path.startsWith(route))) {
        return null;
      }

      // On web, if at root and not logged in, let the '/' route handle it
      // On mobile, the splash screen will handle auth check
      return null;
    },

    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Role-Based Home Routes
      GoRoute(
        path: '/',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final userAsync = ref.watch(currentUserProvider);

              return userAsync.when(
                data: (user) {
                  debugPrint('=== HOME ROUTE ===');
                  debugPrint('User data: $user');
                  if (user == null) {
                    debugPrint('User is null, showing CustomerHomeScreen');
                    return const CustomerHomeScreen();
                  }
                  debugPrint('User role: ${user.role}');
                  return _getRoleBasedHomeScreen(user);
                },
                loading: () {
                  debugPrint('currentUserProvider is loading...');
                  return const CustomerHomeScreen();
                },
                error: (e, __) {
                  debugPrint('currentUserProvider error: $e');
                  return const CustomerHomeScreen();
                },
              );
            },
          );
        },
      ),

      // Customer Routes
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/menu/item/:itemId',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          return MenuItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/scan-table',
        builder: (context, state) => const QrScannerScreen(),
      ),

      // Table Bill Route (Web-accessible for QR scanning)
      GoRoute(
        path: '/table-bill',
        builder: (context, state) {
          final tableId = state.uri.queryParameters['tableId'] ?? '';
          return TableBillScreen(tableId: tableId);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-confirmation/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-tracking/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Profile / Address Routes
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isSelectionMode = extra?['selectionMode'] as bool? ?? false;
          final selectedAddressId = extra?['selectedAddressId'] as String?;
          return AddressListScreen(
            isSelectionMode: isSelectionMode,
            selectedAddressId: selectedAddressId,
          );
        },
      ),
      GoRoute(
        path: '/profile/addresses/add',
        builder: (context, state) => const AddEditAddressScreen(),
      ),
      GoRoute(
        path: '/profile/addresses/edit',
        builder: (context, state) {
          final address = state.extra as AddressModel?;
          return AddEditAddressScreen(address: address);
        },
      ),

      // Customer Entertainment Routes
      GoRoute(
        path: '/specials',
        builder: (context, state) => const SpecialsScreen(),
      ),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const MovieNightScreen(),
      ),
      GoRoute(
        path: '/games',
        builder: (context, state) => const SaturdayGamesScreen(),
      ),

      // Reservation Routes
      GoRoute(
        path: '/reservations',
        builder: (context, state) => const ReservationScreen(),
      ),
      GoRoute(
        path: '/reservations/history',
        builder: (context, state) => const ReservationHistoryScreen(),
      ),

      // Notification Routes
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notifications/settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Feedback Routes
      GoRoute(
        path: '/review/:menuItemId',
        builder: (context, state) {
          final menuItemId = state.pathParameters['menuItemId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return SubmitReviewScreen(
            menuItemId: menuItemId,
            menuItemName: extra?['menuItemName'] ?? 'Item',
            orderId: extra?['orderId'],
          );
        },
      ),
      GoRoute(
        path: '/feedback/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return OrderFeedbackScreen(
            orderId: orderId,
            orderNumber: extra?['orderNumber'] ?? '#---',
          );
        },
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/admin/menu',
        builder: (context, state) => const MenuManagementScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/venue',
        builder: (context, state) => const VenueSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/specials',
        builder: (context, state) => const DailySpecialsScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/tables',
        builder: (context, state) => const TableManagementScreen(),
      ),
      GoRoute(
        path: '/admin/movies',
        builder: (context, state) => const MovieManagementScreen(),
      ),
      GoRoute(
        path: '/admin/games',
        builder: (context, state) => const GamesManagementScreen(),
      ),
    ],
  );
});

/// Get role-based home screen widget
Widget _getRoleBasedHomeScreen(UserModel user) {
  debugPrint('=== ROLE CHECK ===');
  debugPrint('User: ${user.name}');
  debugPrint('Role: ${user.role}');
  debugPrint('==================');

  switch (user.role) {
    case UserRole.customer:
      return const CustomerHomeScreen();

    case UserRole.admin:
      return const AdminHomeScreen();

    case UserRole.kitchen:
      return const KitchenHomeScreen();

    case UserRole.waiter:
      return const WaiterHomeScreen();

    case UserRole.delivery:
      return const DeliveryHomeScreen();

    case UserRole.staff:
      return const StaffHomeScreen();
  }
}
