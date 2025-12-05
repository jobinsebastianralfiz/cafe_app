import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';

/// Waiter Home Screen - Table management and order taking
class WaiterHomeScreen extends ConsumerStatefulWidget {
  const WaiterHomeScreen({super.key});

  @override
  ConsumerState<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends ConsumerState<WaiterHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.room_service, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waiter App',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  user.valueOrNull?.name ?? 'Staff',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tables', icon: Icon(Icons.table_restaurant)),
            Tab(text: 'Orders', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Ready', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TablesView(),
          _OrdersView(),
          _ReadyOrdersView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Quick order functionality
          _showQuickOrderDialog(context);
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Order', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showQuickOrderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickOrderSheet(
        onOrderCreated: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

class _QuickOrderSheet extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const _QuickOrderSheet({required this.onOrderCreated});

  @override
  State<_QuickOrderSheet> createState() => _QuickOrderSheetState();
}

class _QuickOrderSheetState extends State<_QuickOrderSheet> {
  String? _selectedTableId;
  String? _selectedTableName;
  final Map<String, _OrderItem> _orderItems = {};
  String _searchQuery = '';
  bool _isLoading = false;

  double get _total {
    return _orderItems.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Quick Order',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (_orderItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${_total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Table Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tables')
                  .where('isActive', isEqualTo: true)
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                final tables = snapshot.data?.docs ?? [];

                return DropdownButtonFormField<String>(
                  value: _selectedTableId,
                  decoration: InputDecoration(
                    labelText: 'Select Table',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.table_restaurant),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'takeaway',
                      child: Text('Takeaway (No Table)'),
                    ),
                    ...tables.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Table'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTableId = value;
                      if (value == 'takeaway') {
                        _selectedTableName = 'Takeaway';
                      } else {
                        final table = tables.firstWhere((t) => t.id == value);
                        _selectedTableName = (table.data() as Map<String, dynamic>)['name'];
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Menu Items
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menu')
                  .doc('items')
                  .collection('list')
                  .where('isAvailable', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var items = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty ? 'No menu items' : 'No items found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final itemId = doc.id;
                    final name = data['name'] ?? 'Unknown';
                    final price = (data['price'] ?? 0).toDouble();
                    final isVeg = data['isVeg'] ?? true;
                    final quantity = _orderItems[itemId]?.quantity ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: quantity > 0
                            ? const BorderSide(color: Colors.blue, width: 2)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isVeg ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isVeg ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('₹${price.toStringAsFixed(0)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (quantity > 0) ...[
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    if (quantity == 1) {
                                      _orderItems.remove(itemId);
                                    } else {
                                      _orderItems[itemId]!.quantity--;
                                    }
                                  });
                                },
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: () {
                                setState(() {
                                  if (_orderItems.containsKey(itemId)) {
                                    _orderItems[itemId]!.quantity++;
                                  } else {
                                    _orderItems[itemId] = _OrderItem(
                                      id: itemId,
                                      name: name,
                                      price: price,
                                      quantity: 1,
                                    );
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Bar
          if (_orderItems.isNotEmpty)
            Container(
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
                  children: [
                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_orderItems.values.fold(0, (sum, item) => sum + item.quantity)} items',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const Spacer(),
                              Text(
                                _selectedTableName ?? 'No table selected',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            children: [
                              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(
                                '₹${_total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Create Order Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedTableId == null || _isLoading
                            ? null
                            : () => _createOrder(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Order',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _createOrder() async {
    if (_selectedTableId == null || _orderItems.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final orderNumber = '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final items = _orderItems.values.map((item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'total': item.price * item.quantity,
      }).toList();

      await FirebaseFirestore.instance.collection('orders').add({
        'orderNumber': orderNumber,
        'orderType': _selectedTableId == 'takeaway' ? 'takeaway' : 'dine-in',
        'tableId': _selectedTableId == 'takeaway' ? null : _selectedTableId,
        'tableName': _selectedTableName,
        'items': items,
        'pricing': {
          'subtotal': _total,
          'tax': _total * 0.05,
          'grandTotal': _total * 1.05,
        },
        'status': 'confirmed',
        'payment': {
          'method': 'cash',
          'status': 'pending',
        },
        'timestamps': {
          'placedAt': Timestamp.now(),
          'confirmedAt': Timestamp.now(),
        },
        'createdBy': 'waiter',
      });

      // Update table status if dine-in
      if (_selectedTableId != 'takeaway') {
        await FirebaseFirestore.instance
            .collection('tables')
            .doc(_selectedTableId)
            .update({'status': 'occupied'});
      }

      widget.onOrderCreated();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _OrderItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  _OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class _TablesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tables')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading tables',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyTables();
        }

        // Sort locally by name to avoid composite index
        final tables = snapshot.data!.docs.toList();
        tables.sort((a, b) {
          final aName = (a.data() as Map<String, dynamic>)['name'] ?? '';
          final bName = (b.data() as Map<String, dynamic>)['name'] ?? '';
          return aName.toString().compareTo(bName.toString());
        });

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final tableData = tables[index].data() as Map<String, dynamic>;
            return _TableCard(
              tableId: tables[index].id,
              tableName: tableData['name'] ?? 'Table ${index + 1}',
              capacity: tableData['capacity'] ?? 4,
              status: tableData['status'] ?? 'available',
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyTables() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tables configured',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add tables from admin panel',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final String tableId;
  final String tableName;
  final int capacity;
  final String status;

  const _TableCard({
    required this.tableId,
    required this.tableName,
    required this.capacity,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'occupied':
        statusColor = Colors.red;
        statusIcon = Icons.people;
        break;
      case 'reserved':
        statusColor = Colors.orange;
        statusIcon = Icons.event;
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check;
    }

    return GestureDetector(
      onTap: () => _showTableOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_restaurant, color: statusColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              tableName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTableOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tableName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Status: ${status.toUpperCase()} • Capacity: $capacity',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            if (status == 'occupied') ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Available'),
                subtitle: const Text('Free this table for new customers'),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('tables')
                      .doc(tableId)
                      .update({'status': 'available'});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Table marked as available'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
            if (status == 'available') ...[
              ListTile(
                leading: const Icon(Icons.people, color: Colors.orange),
                title: const Text('Mark as Occupied'),
                subtitle: const Text('Reserve for walk-in customers'),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('tables')
                      .doc(tableId)
                      .update({'status': 'occupied'});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Table marked as occupied'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: const Text('Mark as Reserved'),
                subtitle: const Text('Reserve for upcoming booking'),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('tables')
                      .doc(tableId)
                      .update({'status': 'reserved'});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Table marked as reserved'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                },
              ),
            ],
            if (status == 'reserved') ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Available'),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('tables')
                      .doc(tableId)
                      .update({'status': 'available'});
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.orange),
                title: const Text('Seat Guests (Mark Occupied)'),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('tables')
                      .doc(tableId)
                      .update({'status': 'occupied'});
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _OrdersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Query all active orders without complex filters
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No active orders',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter for active statuses locally
        final allDocs = snapshot.data!.docs.toList();
        final activeStatuses = ['placed', 'confirmed', 'preparing'];
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final status = data['status'] as String? ?? '';
          return activeStatuses.contains(status);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No active orders',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${allDocs.length} total orders in database',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Sort by placedAt locally
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['timestamps'] as Map?)?['placedAt'] as Timestamp?;
          final bTime = (bData['timestamps'] as Map?)?['placedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final orderDoc = docs[index];
            return _WaiterOrderCard(orderDoc: orderDoc);
          },
        );
      },
    );
  }
}

class _WaiterOrderCard extends StatelessWidget {
  final DocumentSnapshot orderDoc;

  const _WaiterOrderCard({required this.orderDoc});

  @override
  Widget build(BuildContext context) {
    final data = orderDoc.data() as Map<String, dynamic>? ?? {};
    final orderNumber = data['orderNumber'] ?? '#---';
    final status = data['status'] ?? 'placed';
    final tableName = data['tableName'] as String?;
    final tableId = data['tableId'] as String?;

    // Handle items - could be List or null
    List<dynamic> items = [];
    if (data['items'] != null && data['items'] is List) {
      items = data['items'] as List<dynamic>;
    }

    // Handle pricing - could be Map or null
    Map<String, dynamic> pricing = {};
    if (data['pricing'] != null && data['pricing'] is Map) {
      pricing = data['pricing'] as Map<String, dynamic>;
    }
    final total = pricing['grandTotal'] ?? pricing['finalAmount'] ?? 0;

    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      case 'preparing':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt, color: statusColor),
            ),
            title: Text(
              orderNumber,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              tableName ?? (tableId != null ? 'Table: $tableId' : 'Takeaway'),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isEmpty)
                  Text(
                    'No items in this order',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  )
                else ...[
                  ...items.take(3).map((item) {
                    final itemData = item is Map<String, dynamic> ? item : <String, dynamic>{};
                    final qty = itemData['quantity'] ?? 1;
                    final name = itemData['name'] ?? itemData['itemName'] ?? 'Unknown item';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${qty}x ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Expanded(child: Text(name)),
                        ],
                      ),
                    );
                  }),
                  if (items.length > 3)
                    Text(
                      '+${items.length - 3} more items',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  'Total: ₹${(total is num ? total : 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyOrdersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ready')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading ready orders',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No ready orders',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        // Sort locally to avoid composite index requirement
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['timestamps'] as Map?)?['readyAt'] as Timestamp?;
          final bTime = (bData['timestamps'] as Map?)?['readyAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final orderDoc = docs[index];
            final data = orderDoc.data() as Map<String, dynamic>;
            final orderNumber = data['orderNumber'] ?? '#---';
            final tableName = data['tableName'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white),
                ),
                title: Text(
                  orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(tableName != null ? 'Table: $tableName' : 'Pickup'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    // Just mark order as delivered/served
                    // Table stays occupied - waiter manually frees it when customer leaves
                    await orderDoc.reference.update({
                      'status': 'delivered',
                      'timestamps.deliveredAt': Timestamp.now(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Serve', style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
