import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';

/// Kitchen Home Screen - Kitchen Display System (KDS)
class KitchenHomeScreen extends ConsumerStatefulWidget {
  const KitchenHomeScreen({super.key});

  @override
  ConsumerState<KitchenHomeScreen> createState() => _KitchenHomeScreenState();
}

class _KitchenHomeScreenState extends ConsumerState<KitchenHomeScreen> {
  String _selectedFilter = 'all';
  late Stream<QuerySnapshot> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kitchen Display',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All', Colors.purple),
                  const SizedBox(width: 12),
                  _buildFilterChip('pending', 'New', Colors.orange),
                  const SizedBox(width: 12),
                  _buildFilterChip('preparing', 'Preparing', Colors.blue),
                  const SizedBox(width: 12),
                  _buildFilterChip('ready', 'Ready', Colors.green),
                ],
              ),
            ),
          ),

          // Status info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF16213E),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Showing: ${_selectedFilter == 'pending' ? 'confirmed' : _selectedFilter} orders',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),

          // Orders Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                // Debug: Show connection state
                debugPrint('Kitchen StreamBuilder state: ${snapshot.connectionState}');
                debugPrint('Kitchen StreamBuilder hasData: ${snapshot.hasData}');
                debugPrint('Kitchen StreamBuilder hasError: ${snapshot.hasError}');

                if (snapshot.hasError) {
                  debugPrint('Kitchen error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading orders',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          'Loading orders...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                debugPrint('Kitchen total docs: ${allDocs.length}');

                if (allDocs.isEmpty) {
                  return _buildEmptyState(message: 'No orders in database');
                }

                // Filter based on selected filter - show all kitchen-relevant orders
                final targetStatus = _selectedFilter == 'pending' ? 'confirmed' : _selectedFilter;

                // Get status counts for debugging
                final statusCounts = <String, int>{};
                for (final doc in allDocs) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final status = data['status'] as String? ?? 'unknown';
                  statusCounts[status] = (statusCounts[status] ?? 0) + 1;
                }
                debugPrint('Kitchen status counts: $statusCounts');

                // Filter orders - for kitchen, show confirmed, preparing, ready
                final kitchenStatuses = ['confirmed', 'preparing', 'ready', 'placed'];
                final orders = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final status = data['status'] ?? '';
                  if (_selectedFilter == 'all') {
                    return kitchenStatuses.contains(status);
                  }
                  return status == targetStatus;
                }).toList();

                debugPrint('Kitchen filtered orders ($targetStatus): ${orders.length}');

                // Sort by placedAt time
                orders.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = (aData['timestamps'] as Map?)?['placedAt'] as Timestamp?;
                  final bTime = (bData['timestamps'] as Map?)?['placedAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return aTime.compareTo(bTime); // ascending (oldest first)
                });

                if (orders.isEmpty) {
                  return _buildEmptyState(
                    message: 'No "$targetStatus" orders',
                    totalOrders: allDocs.length,
                    statusInfo: statusCounts.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _KitchenOrderCard(orderDoc: orders[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    String message = 'No orders in queue',
    int totalOrders = 0,
    String? statusInfo,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (totalOrders > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$totalOrders total orders in database',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
            if (statusInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Statuses: $statusInfo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Create orders from Waiter or Customer app',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final DocumentSnapshot orderDoc;

  const _KitchenOrderCard({required this.orderDoc});

  @override
  Widget build(BuildContext context) {
    final data = orderDoc.data() as Map<String, dynamic>? ?? {};
    final orderNumber = data['orderNumber'] ?? '#---';
    final status = data['status'] ?? 'confirmed';
    final orderType = data['orderType'] ?? 'delivery';
    final tableName = data['tableName'] as String?;

    // Handle items safely
    List<dynamic> items = [];
    if (data['items'] != null && data['items'] is List) {
      items = data['items'] as List<dynamic>;
    }

    final specialNotes = data['specialNotes'] as String?;
    final timestamps = data['timestamps'] as Map<String, dynamic>? ?? {};
    final placedAt = timestamps['placedAt'] as Timestamp?;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.orange;
        statusText = 'NEW';
        break;
      case 'preparing':
        statusColor = Colors.blue;
        statusText = 'PREPARING';
        break;
      case 'ready':
        statusColor = Colors.green;
        statusText = 'READY';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status.toUpperCase();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    orderNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order Type and Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  orderType == 'dine-in'
                      ? Icons.restaurant
                      : orderType == 'takeaway'
                          ? Icons.shopping_bag
                          : Icons.delivery_dining,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  orderType.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (placedAt != null)
                  Text(
                    DateFormat('hh:mm a').format(placedAt.toDate()),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Items
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No items',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] is Map<String, dynamic>
                          ? items[index] as Map<String, dynamic>
                          : <String, dynamic>{};
                      final itemName = item['name'] ?? item['itemName'] ?? 'Unknown';
                      final qty = item['quantity'] ?? 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                itemName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Special Notes
          if (specialNotes != null && specialNotes.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      specialNotes,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _getActionText(status),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionText(String status) {
    switch (status) {
      case 'placed':
        return 'Accept Order';
      case 'confirmed':
        return 'Start Preparing';
      case 'preparing':
        return 'Mark Ready';
      case 'ready':
        return 'Served';
      default:
        return 'Update';
    }
  }

  Future<void> _updateOrderStatus(BuildContext context) async {
    final data = orderDoc.data() as Map<String, dynamic>? ?? {};
    final currentStatus = data['status'] ?? 'placed';

    String newStatus;
    String timestampField;

    switch (currentStatus) {
      case 'placed':
        newStatus = 'confirmed';
        timestampField = 'confirmedAt';
        break;
      case 'confirmed':
        newStatus = 'preparing';
        timestampField = 'preparingAt';
        break;
      case 'preparing':
        newStatus = 'ready';
        timestampField = 'readyAt';
        break;
      case 'ready':
        newStatus = 'delivered';
        timestampField = 'deliveredAt';
        break;
      default:
        debugPrint('Unknown status: $currentStatus');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot update status: $currentStatus'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
    }

    try {
      debugPrint('Updating order ${orderDoc.id} from $currentStatus to $newStatus');
      await orderDoc.reference.update({
        'status': newStatus,
        'timestamps.$timestampField': Timestamp.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to $newStatus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to update order: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
