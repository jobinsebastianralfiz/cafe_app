import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../menu/viewmodels/menu_viewmodel.dart';
import '../../wallet/viewmodels/wallet_viewmodel.dart';
import '../../wallet/models/coin_transaction_model.dart';
import '../../admin/viewmodels/table_viewmodel.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/order_pricing_model.dart';
import '../services/order_service.dart';
import '../../auth/models/user_model.dart';

/// Order Service Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

/// Order ViewModel - Handles order-related business logic
class OrderViewModel extends StateNotifier<AsyncValue<void>> {
  final OrderService _orderService;
  final Ref _ref;

  OrderViewModel(this._orderService, this._ref) : super(const AsyncValue.data(null));

  /// Create a new order
  Future<String?> createOrder({
    required String orderType,
    required AddressModel? deliveryAddress,
    required String paymentMethod,
    String? specialNotes,
    String? tableId,
    int coinsToUse = 0,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Get current user
      final user = await _ref.read(currentUserProvider.future);
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get cart items
      final cartItems = await _ref.read(cartItemsProvider.future);
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Convert cart items to order items
      final orderItems = cartItems
          .map((cartItem) => OrderItemModel(
                itemId: cartItem.itemId,
                itemName: cartItem.name,
                quantity: cartItem.quantity,
                price: cartItem.price,
                subtotal: cartItem.subtotal,
                specialInstructions: cartItem.specialInstructions,
              ))
          .toList();

      // Calculate pricing
      final subtotal =
          cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);

      final deliveryCharges = orderType == 'delivery' ? 40.0 : 0.0;
      final taxAmount = subtotal * 0.05; // 5% tax

      // Calculate coin discount (1 coin = ₹1, max 20% of subtotal)
      final maxCoinsAllowed = (subtotal * 0.2).floor();
      final coinsUsed = coinsToUse > maxCoinsAllowed ? maxCoinsAllowed : coinsToUse;
      final coinDiscount = coinsUsed.toDouble();

      final totalAmount = subtotal + deliveryCharges + taxAmount;
      final finalAmount = totalAmount - coinDiscount;

      // Calculate coins earned (5% of final amount)
      final coinsEarned = (finalAmount * 0.05).floor();

      final pricing = OrderPricingModel(
        subtotal: subtotal,
        deliveryCharges: deliveryCharges,
        taxAmount: taxAmount,
        coinDiscount: coinDiscount,
        totalAmount: totalAmount,
        finalAmount: finalAmount,
      );

      // Generate order number
      final orderNumber = _orderService.generateOrderNumber();

      // Calculate estimated delivery time
      final estimatedDeliveryTime = orderType == 'delivery'
          ? DateTime.now().add(const Duration(minutes: 45))
          : null;

      // Create order
      final order = OrderModel(
        id: '', // Will be set by Firestore
        orderNumber: orderNumber,
        userId: user.id,
        userName: user.name,
        userPhone: user.phone,
        userEmail: user.email,
        items: orderItems,
        pricing: pricing,
        deliveryAddress: deliveryAddress,
        specialNotes: specialNotes,
        orderType: orderType,
        tableId: tableId,
        status: 'placed',
        statusHistory: [
          OrderStatusHistory(
            status: 'placed',
            timestamp: DateTime.now(),
            note: 'Order placed successfully',
          ),
        ],
        payment: PaymentInfo(
          method: paymentMethod,
          status: 'pending',
        ),
        coinsUsed: coinsUsed,
        coinsEarned: coinsEarned,
        placedAt: DateTime.now(),
        estimatedDeliveryTime: estimatedDeliveryTime,
      );

      // Save order to Firestore
      final orderId = await _orderService.createOrder(order);

      // Deduct coins if used
      if (coinsUsed > 0) {
        await _ref.read(walletViewModelProvider.notifier).deductCoins(
              userId: user.id,
              amount: coinsUsed,
              source: TransactionSource.order,
              description: 'Used on order $orderNumber',
              sourceId: orderId,
              metadata: {
                'orderNumber': orderNumber,
                'discount': coinDiscount,
              },
            );
      }

      // Clear cart after successful order
      await _ref.read(cartServiceProvider).clearCart();

      // Mark table as occupied if dine-in with table
      if (orderType == 'dine-in' && tableId != null && tableId.isNotEmpty) {
        await _ref.read(tableViewModelProvider.notifier).occupyTable(tableId, orderId);
        // Clear selected table provider after order
        _ref.read(selectedTableProvider.notifier).state = null;
      }

      state = const AsyncValue.data(null);
      return orderId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
        note: note,
      );

      // Award coins when order is delivered
      if (newStatus == 'delivered' || newStatus == 'completed') {
        final order = await _orderService.getOrder(orderId);
        if (order != null) {
          // Award coins
          if (order.coinsEarned > 0 && newStatus == 'delivered') {
            await _ref.read(walletViewModelProvider.notifier).addCoins(
                  userId: order.userId,
                  amount: order.coinsEarned,
                  source: TransactionSource.order,
                  description: 'Earned from order ${order.orderNumber}',
                  sourceId: orderId,
                  metadata: {
                    'orderNumber': order.orderNumber,
                    'orderAmount': order.pricing.finalAmount,
                  },
                );
          }

          // Release table if dine-in order
          if (order.orderType == 'dine-in' && order.tableId != null) {
            await _ref.read(tableViewModelProvider.notifier).releaseTable(order.tableId!);
          }
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Cancel order
  Future<void> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _orderService.cancelOrder(
        orderId: orderId,
        cancellationReason: reason,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String? transactionId,
  }) async {
    try {
      await _orderService.updatePaymentStatus(
        orderId: orderId,
        paymentStatus: paymentStatus,
        transactionId: transactionId,
        paidAt: paymentStatus == 'completed' ? DateTime.now() : null,
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Order ViewModel Provider
final orderViewModelProvider =
    StateNotifierProvider<OrderViewModel, AsyncValue<void>>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return OrderViewModel(orderService, ref);
});

/// Stream user's active orders
final userActiveOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  final orderService = ref.watch(orderServiceProvider);
  return orderService.streamUserActiveOrders(user.uid);
});

/// Stream user's order history
final userOrderHistoryProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  final orderService = ref.watch(orderServiceProvider);
  return orderService.streamUserOrders(user.uid);
});

/// Stream specific order by ID
final orderByIdProvider =
    StreamProvider.autoDispose.family<OrderModel?, String>((ref, orderId) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.streamOrder(orderId);
});

/// Stream orders by status (for staff)
final ordersByStatusProvider =
    StreamProvider.autoDispose.family<List<OrderModel>, String>((ref, status) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.streamOrdersByStatus(status);
});

/// Stream all active orders (for kitchen/staff)
final allActiveOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.streamActiveOrders();
});

/// Stream delivery orders (for delivery staff)
final deliveryOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final orderService = ref.watch(orderServiceProvider);

  // If user is delivery staff, filter by their ID
  final riderId = user?.uid;
  return orderService.streamDeliveryOrders(riderId: riderId);
});

/// Get order statistics (for admin)
final orderStatisticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getOrderStatistics();
});

/// Active orders count
final activeOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final activeOrdersAsync = ref.watch(userActiveOrdersProvider);
  return activeOrdersAsync.when(
    data: (orders) => orders.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Checkout State Providers

/// Selected delivery address
final selectedDeliveryAddressProvider =
    StateProvider.autoDispose<AddressModel?>((ref) => null);

/// Selected payment method
final selectedPaymentMethodProvider =
    StateProvider.autoDispose<String>((ref) => 'cash');

/// Selected order type
final selectedOrderTypeProvider =
    StateProvider.autoDispose<String>((ref) => 'delivery');

/// Special notes for order
final orderSpecialNotesProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Table ID for dine-in orders
final selectedTableIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Coins to use for order
final coinsToUseProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Calculate maximum coins that can be used
final maxCoinsAllowedProvider = Provider.autoDispose<int>((ref) {
  final cartTotal = ref.watch(cartTotalProvider);
  final maxCoins = (cartTotal * 0.2).floor(); // Max 20% of cart total
  return maxCoins;
});

/// Calculate final order pricing with all charges
final orderPricingPreviewProvider =
    Provider.autoDispose<OrderPricingModel>((ref) {
  final cartTotal = ref.watch(cartTotalProvider);
  final orderType = ref.watch(selectedOrderTypeProvider);
  final coinsToUse = ref.watch(coinsToUseProvider);
  final maxCoinsAllowed = ref.watch(maxCoinsAllowedProvider);

  final subtotal = cartTotal;
  final deliveryCharges = orderType == 'delivery' ? 40.0 : 0.0;
  final taxAmount = subtotal * 0.05; // 5% tax

  // Ensure coins used doesn't exceed max allowed
  final coinsUsed = coinsToUse > maxCoinsAllowed ? maxCoinsAllowed : coinsToUse;
  final coinDiscount = coinsUsed.toDouble();

  final totalAmount = subtotal + deliveryCharges + taxAmount;
  final finalAmount = totalAmount - coinDiscount;

  return OrderPricingModel(
    subtotal: subtotal,
    deliveryCharges: deliveryCharges,
    taxAmount: taxAmount,
    coinDiscount: coinDiscount,
    totalAmount: totalAmount,
    finalAmount: finalAmount,
  );
});

/// Coins that will be earned from this order
final coinsToEarnProvider = Provider.autoDispose<int>((ref) {
  final orderPricing = ref.watch(orderPricingPreviewProvider);
  return (orderPricing.finalAmount * 0.05).floor(); // 5% cashback in coins
});
