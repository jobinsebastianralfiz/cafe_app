import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

/// Analytics Screen - Sales and performance reports for admin
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = 'today';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateDateRange('today');
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 20),

            // Revenue Card
            _buildRevenueCard(),
            const SizedBox(height: 16),

            // Stats Grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Popular Items
            _buildPopularItems(),
            const SizedBox(height: 24),

            // Order Type Distribution
            _buildOrderTypeDistribution(),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PeriodChip(
            label: 'Today',
            isSelected: _selectedPeriod == 'today',
            onTap: () => _updateDateRange('today'),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'This Week',
            isSelected: _selectedPeriod == 'week',
            onTap: () => _updateDateRange('week'),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'This Month',
            isSelected: _selectedPeriod == 'month',
            onTap: () => _updateDateRange('month'),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'This Year',
            isSelected: _selectedPeriod == 'year',
            onTap: () => _updateDateRange('year'),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where('timestamps.deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('timestamps.deliveredAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .snapshots(),
      builder: (context, snapshot) {
        double totalRevenue = 0;
        int orderCount = 0;

        if (snapshot.hasData) {
          orderCount = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
            totalRevenue += (pricing['grandTotal'] ?? 0).toDouble();
          }
        }

        double avgOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.indigo, Colors.deepPurple],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    'Total Revenue',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _RevenueSubStat(
                    label: 'Orders',
                    value: orderCount.toString(),
                  ),
                  const SizedBox(width: 24),
                  _RevenueSubStat(
                    label: 'Avg. Order',
                    value: '₹${avgOrderValue.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            label: 'New Customers',
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
                .snapshots(),
            valueBuilder: (snapshot) => snapshot.data?.docs.length.toString() ?? '0',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            label: 'Reviews',
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
                .snapshots(),
            valueBuilder: (snapshot) => snapshot.data?.docs.length.toString() ?? '0',
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Popular Items',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'delivered')
              .orderBy('timestamps.deliveredAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No order data available')),
                ),
              );
            }

            // Count item occurrences
            Map<String, int> itemCounts = {};
            Map<String, String> itemNames = {};

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final items = (data['items'] as List<dynamic>?) ?? [];

              for (var item in items) {
                final itemData = item as Map<String, dynamic>;
                final id = itemData['id'] ?? itemData['name'];
                final name = itemData['name'] ?? 'Unknown';
                final qty = (itemData['quantity'] ?? 1) as int;

                itemCounts[id] = (itemCounts[id] ?? 0) + qty;
                itemNames[id] = name;
              }
            }

            // Sort by count
            final sortedItems = itemCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final topItems = sortedItems.take(5).toList();

            if (topItems.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No items data')),
                ),
              );
            }

            final maxCount = topItems.first.value;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: topItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final progress = item.value / maxCount;

                    return Padding(
                      padding: EdgeInsets.only(bottom: index < topItems.length - 1 ? 16 : 0),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _getRankColor(index),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                                  itemNames[item.key] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation(_getRankColor(index)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${item.value}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.indigo;
    }
  }

  Widget _buildOrderTypeDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pie_chart, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'Order Types',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('timestamps.placedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
              .snapshots(),
          builder: (context, snapshot) {
            int dineIn = 0, takeaway = 0, delivery = 0;

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                switch (data['orderType']) {
                  case 'dine-in':
                    dineIn++;
                    break;
                  case 'takeaway':
                    takeaway++;
                    break;
                  case 'delivery':
                    delivery++;
                    break;
                }
              }
            }

            final total = dineIn + takeaway + delivery;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _OrderTypeIndicator(
                      icon: Icons.restaurant,
                      label: 'Dine-in',
                      count: dineIn,
                      percentage: total > 0 ? (dineIn / total * 100).round() : 0,
                      color: Colors.blue,
                    ),
                    _OrderTypeIndicator(
                      icon: Icons.shopping_bag,
                      label: 'Takeaway',
                      count: takeaway,
                      percentage: total > 0 ? (takeaway / total * 100).round() : 0,
                      color: Colors.orange,
                    ),
                    _OrderTypeIndicator(
                      icon: Icons.delivery_dining,
                      label: 'Delivery',
                      count: delivery,
                      percentage: total > 0 ? (delivery / total * 100).round() : 0,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .orderBy('timestamps.placedAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No recent activity')),
                ),
              );
            }

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final orderNumber = data['orderNumber'] ?? '#---';
                  final status = data['status'] ?? 'placed';
                  final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
                  final total = pricing['grandTotal'] ?? 0;
                  final timestamps = data['timestamps'] as Map<String, dynamic>? ?? {};
                  final placedAt = timestamps['placedAt'] as Timestamp?;

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt, color: _getStatusColor(status)),
                    ),
                    title: Text(orderNumber),
                    subtitle: Text(
                      placedAt != null
                          ? DateFormat('MMM d, h:mm a').format(placedAt.toDate())
                          : 'Unknown time',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'ready':
        return Colors.teal;
      case 'preparing':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RevenueSubStat extends StatelessWidget {
  final String label;
  final String value;

  const _RevenueSubStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Stream<QuerySnapshot> stream;
  final String Function(AsyncSnapshot<QuerySnapshot>) valueBuilder;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.stream,
    required this.valueBuilder,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                valueBuilder(snapshot),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderTypeIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final int percentage;
  final Color color;

  const _OrderTypeIndicator({
    required this.icon,
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
