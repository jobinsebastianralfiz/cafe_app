import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/razorpay_service.dart';
import '../../../auth/models/user_model.dart';
import '../../../menu/viewmodels/menu_viewmodel.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../admin/viewmodels/table_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../widgets/order_type_selector.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/order_summary_card.dart';

/// Checkout Screen - Complete order placement
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _specialNotesController = TextEditingController();
  late RazorpayService _razorpayService;
  bool _isProcessing = false;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();

    // Initialize delivery address from user's first address
    Future.microtask(() async {
      final user = await ref.read(currentUserProvider.future);
      if (user != null && user.addresses.isNotEmpty) {
        ref.read(selectedDeliveryAddressProvider.notifier).state =
            user.addresses.first;
      }
    });
  }

  @override
  void dispose() {
    _specialNotesController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final selectedTable = ref.read(selectedTableProvider);
    final orderType = selectedTable != null ? 'dine-in' : ref.read(selectedOrderTypeProvider);
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final deliveryAddress = ref.read(selectedDeliveryAddressProvider);
    // Use table from QR scan, or manual entry
    final tableId = selectedTable?.id ?? ref.read(selectedTableIdProvider);
    final coinsToUse = ref.read(coinsToUseProvider);

    // Validate delivery address for delivery orders
    if (orderType == 'delivery' && deliveryAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isProcessing = false);
      return;
    }

    // Validate table ID for dine-in orders (only if not from QR)
    if (orderType == 'dine-in' && selectedTable == null && (tableId == null || tableId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a table'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // Create order with pending payment status
      final orderId = await ref.read(orderViewModelProvider.notifier).createOrder(
            orderType: orderType,
            deliveryAddress: deliveryAddress,
            paymentMethod: paymentMethod,
            specialNotes: _specialNotesController.text.trim(),
            tableId: tableId,
            coinsToUse: coinsToUse,
          );

      if (orderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create order'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      _pendingOrderId = orderId;

      // Check if online payment is required
      if (paymentMethod == 'cash') {
        // Cash payment - order is placed, navigate to confirmation
        if (mounted) {
          context.go('/order-confirmation/$orderId');
        }
      } else {
        // Online payment (UPI, Card, Wallet) - initiate Razorpay
        await _initiateRazorpayPayment(orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _initiateRazorpayPayment(String orderId) async {
    try {
      final user = await ref.read(currentUserProvider.future);
      final orderPricing = ref.read(orderPricingPreviewProvider);

      if (user == null) {
        throw Exception('User not found');
      }

      await _razorpayService.initiatePayment(
        amount: orderPricing.finalAmount,
        orderId: orderId,
        userEmail: user.email,
        userName: user.name,
        userPhone: user.phone,
        onSuccess: _handlePaymentSuccess,
        onError: _handlePaymentError,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initiation failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    try {
      // Update order payment status
      if (_pendingOrderId != null) {
        await ref.read(orderViewModelProvider.notifier).updatePaymentStatus(
              orderId: _pendingOrderId!,
              paymentStatus: 'completed',
              transactionId: response.paymentId,
            );

        if (mounted) {
          setState(() => _isProcessing = false);
          context.go('/order-confirmation/$_pendingOrderId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating payment status: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    setState(() => _isProcessing = false);

    String errorMessage = 'Payment failed';
    if (response.message != null) {
      errorMessage = response.message!;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );

    // Optionally update order payment status to failed
    if (_pendingOrderId != null) {
      ref.read(orderViewModelProvider.notifier).updatePaymentStatus(
            orderId: _pendingOrderId!,
            paymentStatus: 'failed',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartItemsProvider);
    final orderPricing = ref.watch(orderPricingPreviewProvider);
    final selectedTable = ref.watch(selectedTableProvider);
    // Force dine-in if table is from QR
    final orderType = selectedTable != null ? 'dine-in' : ref.watch(selectedOrderTypeProvider);
    final user = ref.watch(currentUserProvider);
    final coinsToUse = ref.watch(coinsToUseProvider);
    final maxCoinsAllowed = ref.watch(maxCoinsAllowedProvider);
    final coinsToEarn = ref.watch(coinsToEarnProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: cartItems.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/menu'),
                    child: const Text('Browse Menu'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If table is pre-selected via QR, show table info banner
                if (selectedTable != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.table_restaurant,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dine-In Order',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedTable.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${selectedTable.capacity} seats • ${selectedTable.location.displayName}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code, size: 16, color: Colors.teal.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'QR',
                                style: TextStyle(
                                  color: Colors.teal.shade600,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  // Order Type Selection (only if no table pre-selected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Type',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const OrderTypeSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Delivery Address (for delivery orders)
                if (orderType == 'delivery') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery Address',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final currentAddress = ref.read(selectedDeliveryAddressProvider);
                                final selectedAddress = await context.push<AddressModel>(
                                  '/profile/addresses',
                                  extra: {'selectionMode': true, 'selectedAddressId': currentAddress?.id},
                                );
                                if (selectedAddress != null) {
                                  ref.read(selectedDeliveryAddressProvider.notifier).state = selectedAddress;
                                }
                              },
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        user.when(
                          data: (userData) {
                            if (userData != null && userData.addresses.isNotEmpty) {
                              final address = userData.addresses.first;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            address.label,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            address.fullAddress,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return ElevatedButton.icon(
                                onPressed: () {
                                  context.push('/profile/addresses/add');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Delivery Address'),
                              );
                            }
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Error loading address'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Table Selection (for dine-in orders - only if no QR table)
                if (orderType == 'dine-in' && selectedTable == null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table Number',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter table number or name',
                            prefixIcon: const Icon(Icons.table_restaurant),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            ref.read(selectedTableIdProvider.notifier).state =
                                value;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Or scan table QR code for automatic table selection',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Payment Method
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const PaymentMethodSelector(),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Coins Usage
                user.when(
                  data: (userData) {
                    if (userData != null && userData.coinBalance > 0) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Use Coins',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  'Available: ${userData.coinBalance}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: coinsToUse.toDouble(),
                                    min: 0,
                                    max: maxCoinsAllowed
                                        .toDouble()
                                        .clamp(0, userData.coinBalance.toDouble()),
                                    divisions: maxCoinsAllowed > 0
                                        ? maxCoinsAllowed.clamp(1, userData.coinBalance)
                                        : 1,
                                    label: coinsToUse.toString(),
                                    onChanged: (value) {
                                      ref
                                          .read(coinsToUseProvider.notifier)
                                          .state = value.toInt();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$coinsToUse',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (maxCoinsAllowed > 0)
                              Text(
                                'You can use up to $maxCoinsAllowed coins (20% of order)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textHint,
                                    ),
                              ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 8),

                // Special Notes
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Special Instructions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _specialNotesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any special requests? (optional)',
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Order Summary
                OrderSummaryCard(pricing: orderPricing),

                // Coins Earned Info
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.1),
                        AppColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You will earn $coinsToEarn coins from this order!',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      bottomNavigationBar: cartItems.when(
        data: (items) {
          if (items.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        orderPricing.formattedFinalAmount,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
