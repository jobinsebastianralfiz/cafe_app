import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/razorpay_service.dart';

/// Table Bill Screen - Web-accessible bill for dine-in customers
/// URL: /table-bill?tableId=xxx
class TableBillScreen extends ConsumerStatefulWidget {
  final String tableId;

  const TableBillScreen({super.key, required this.tableId});

  @override
  ConsumerState<TableBillScreen> createState() => _TableBillScreenState();
}

class _TableBillScreenState extends ConsumerState<TableBillScreen> {
  bool _isProcessingPayment = false;
  RazorpayService? _razorpayService;
  double _currentTotal = 0;
  List<QueryDocumentSnapshot> _currentOrders = [];

  @override
  void initState() {
    super.initState();
    // Only initialize Razorpay on mobile platforms
    if (!kIsWeb) {
      _razorpayService = RazorpayService();
    }
  }

  @override
  void dispose() {
    _razorpayService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        // Get active orders for this table
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('tableId', isEqualTo: widget.tableId)
            .where('status', whereIn: ['placed', 'confirmed', 'preparing', 'ready', 'delivered'])
            .snapshots(),
        builder: (context, ordersSnapshot) {
          // Also get table info
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tables')
                .doc(widget.tableId)
                .snapshots(),
            builder: (context, tableSnapshot) {
              if (ordersSnapshot.connectionState == ConnectionState.waiting ||
                  tableSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (ordersSnapshot.hasError || tableSnapshot.hasError) {
                return _buildErrorState('Unable to load bill. Please try again.');
              }

              final tableData = tableSnapshot.data?.data() as Map<String, dynamic>?;
              final tableName = tableData?['name'] ?? 'Table';
              final orders = ordersSnapshot.data?.docs ?? [];

              if (orders.isEmpty) {
                return _buildNoOrdersState(tableName);
              }

              // Calculate totals from all orders
              double subtotal = 0;
              List<Map<String, dynamic>> allItems = [];

              for (final orderDoc in orders) {
                final orderData = orderDoc.data() as Map<String, dynamic>;
                final items = orderData['items'] as List<dynamic>? ?? [];

                for (final item in items) {
                  final itemMap = item as Map<String, dynamic>;
                  allItems.add({
                    ...itemMap,
                    'orderId': orderDoc.id,
                  });
                  final price = (itemMap['price'] ?? 0).toDouble();
                  final qty = (itemMap['quantity'] ?? 1);
                  subtotal += price * qty;
                }
              }

              final tax = subtotal * 0.05; // 5% GST
              final total = subtotal + tax;

              return _buildBillContent(
                tableName: tableName,
                items: allItems,
                subtotal: subtotal,
                tax: tax,
                total: total,
                orders: orders,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBillContent({
    required String tableName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required List<QueryDocumentSnapshot> orders,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your Bill',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tableName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Items Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final name = item['name'] ?? item['itemName'] ?? 'Item';
                          final qty = item['quantity'] ?? 1;
                          final price = (item['price'] ?? 0).toDouble();
                          final itemTotal = price * qty;

                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$qty',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '₹${price.toStringAsFixed(0)} each',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${itemTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Totals Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTotalRow('Subtotal', subtotal),
                      const SizedBox(height: 8),
                      _buildTotalRow('GST (5%)', tax),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingPayment
                        ? null
                        : () => _initiatePayment(total, orders),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isProcessingPayment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.payment, color: Colors.white),
                    label: Text(
                      _isProcessingPayment ? 'Processing...' : 'Pay ₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Pay at Counter Option
                TextButton.icon(
                  onPressed: () => _showPayAtCounterDialog(total),
                  icon: Icon(Icons.point_of_sale, color: Colors.grey[700]),
                  label: Text(
                    'Pay at Counter',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Download App Prompt
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Get 10% off your next order!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Download our app for rewards & offers',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Link to app store
                        },
                        child: const Text('Get App'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildNoOrdersState(String tableName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no pending orders for $tableName',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to menu for ordering
                context.go('/menu?tableId=${widget.tableId}');
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('View Menu & Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiatePayment(double amount, List<QueryDocumentSnapshot> orders) async {
    setState(() => _isProcessingPayment = true);

    try {
      // TODO: Integrate Razorpay payment
      // For now, show payment options dialog
      await _showPaymentOptionsDialog(amount, orders);
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _showPaymentOptionsDialog(double amount, List<QueryDocumentSnapshot> orders) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildPaymentOption(
              icon: Icons.account_balance,
              title: 'UPI',
              subtitle: 'Google Pay, PhonePe, Paytm',
              onTap: () => _processPayment('upi', amount, orders),
            ),
            _buildPaymentOption(
              icon: Icons.credit_card,
              title: 'Card',
              subtitle: 'Credit or Debit Card',
              onTap: () => _processPayment('card', amount, orders),
            ),
            _buildPaymentOption(
              icon: Icons.account_balance_wallet,
              title: 'Wallet',
              subtitle: 'Pay from app wallet',
              onTap: () => _processPayment('wallet', amount, orders),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _processPayment(String method, double amount, List<QueryDocumentSnapshot> orders) async {
    Navigator.pop(context); // Close bottom sheet

    _currentTotal = amount;
    _currentOrders = orders;

    if (kIsWeb) {
      // Web: Show UPI payment instructions
      _showWebPaymentDialog(amount, orders);
    } else {
      // Mobile: Use Razorpay
      if (method == 'upi' || method == 'card') {
        await _initiateRazorpayPayment(amount, orders);
      } else {
        // Wallet or other methods - simulate for now
        await _simulatePayment(amount, orders);
      }
    }
  }

  Future<void> _initiateRazorpayPayment(double amount, List<QueryDocumentSnapshot> orders) async {
    if (_razorpayService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment service not available')),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      // Generate a simple order reference
      final orderRef = 'TBL_${widget.tableId}_${DateTime.now().millisecondsSinceEpoch}';

      await _razorpayService!.initiatePayment(
        amount: amount,
        orderId: orderRef,
        userEmail: 'guest@cafe.com',
        userName: 'Guest Customer',
        userPhone: '9999999999',
        onSuccess: _handlePaymentSuccess,
        onError: _handlePaymentError,
      );
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Update all orders as paid
      for (final order in _currentOrders) {
        await order.reference.update({
          'payment.status': 'completed',
          'payment.method': 'razorpay',
          'payment.transactionId': response.paymentId,
          'payment.paidAt': Timestamp.now(),
        });
      }

      // Free the table
      await FirebaseFirestore.instance
          .collection('tables')
          .doc(widget.tableId)
          .update({'status': 'available'});

      if (mounted) {
        Navigator.pop(context); // Close loading
        setState(() => _isProcessingPayment = false);
        _showPaymentSuccessDialog(_currentTotal);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: ${e.toString()}')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    setState(() => _isProcessingPayment = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message ?? 'Payment failed'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showWebPaymentDialog(double amount, List<QueryDocumentSnapshot> orders) {
    // For web, show UPI ID or QR code option
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pay via UPI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.account_balance, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'UPI ID',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const SelectableText(
                    'ralfiz@upi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount: ₹${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pay using any UPI app and show the confirmation to our staff',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
              Navigator.pop(context);
              await _simulatePayment(amount, orders);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('I have paid', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _simulatePayment(double amount, List<QueryDocumentSnapshot> orders) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    // Update all orders as paid
    for (final order in orders) {
      await order.reference.update({
        'payment.status': 'completed',
        'payment.method': 'upi',
        'payment.paidAt': Timestamp.now(),
      });
    }

    // Free the table
    await FirebaseFirestore.instance
        .collection('tables')
        .doc(widget.tableId)
        .update({'status': 'available'});

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      _showPaymentSuccessDialog(amount);
    }
  }

  void _showPaymentSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(0)} paid',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for dining with us!',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Optionally navigate to feedback screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayAtCounterDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pay at Counter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.point_of_sale, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Please pay ₹${amount.toStringAsFixed(0)} at the counter',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Show this screen to the cashier',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
