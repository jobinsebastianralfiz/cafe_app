import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/models/user_model.dart';

/// Profile Stats Card - Display user statistics
class ProfileStatsCard extends ConsumerWidget {
  final UserModel user;

  const ProfileStatsCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars,
                color: AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Coins Balance
              Expanded(
                child: _buildStatItem(
                  icon: Icons.monetization_on,
                  label: 'Coins',
                  value: user.coinBalance.toString(),
                  color: AppColors.accent,
                ),
              ),

              // Total Orders
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: user.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final orderCount = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;

                    return _buildStatItem(
                      icon: Icons.shopping_bag,
                      label: 'Orders',
                      value: orderCount.toString(),
                      color: Colors.white,
                    );
                  },
                ),
              ),

              // Active Orders
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: user.id)
                      .where('status', whereIn: ['pending', 'preparing', 'ready', 'on_the_way'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    final activeCount = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;

                    return _buildStatItem(
                      icon: Icons.local_shipping,
                      label: 'Active',
                      value: activeCount.toString(),
                      color: Colors.white70,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
