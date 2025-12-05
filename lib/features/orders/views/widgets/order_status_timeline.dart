import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/order_model.dart';

/// Order Status Timeline - Visual representation of order progress
class OrderStatusTimeline extends StatelessWidget {
  final OrderModel order;

  const OrderStatusTimeline({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = _getStatusesForOrderType(order.orderType);
    final currentIndex = statuses.indexOf(order.status);

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == statuses.length - 1;

        return _TimelineItem(
          icon: _getIconForStatus(status),
          title: _getTitleForStatus(status),
          subtitle: _getSubtitleForStatus(status, order),
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLast: isLast,
        );
      }),
    );
  }

  List<String> _getStatusesForOrderType(String orderType) {
    if (orderType == 'delivery') {
      return ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'];
    } else {
      // For dine-in and takeaway
      return ['placed', 'confirmed', 'preparing', 'delivered'];
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'placed':
        return Icons.receipt_long;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getTitleForStatus(String status) {
    switch (status) {
      case 'placed':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String? _getSubtitleForStatus(String status, OrderModel order) {
    switch (status) {
      case 'placed':
        return _formatDateTime(order.placedAt);
      case 'confirmed':
        if (order.confirmedAt != null) {
          return _formatDateTime(order.confirmedAt!);
        }
        return null;
      case 'preparing':
        if (order.preparingAt != null) {
          return _formatDateTime(order.preparingAt!);
        }
        return null;
      case 'out_for_delivery':
        if (order.outForDeliveryAt != null) {
          return _formatDateTime(order.outForDeliveryAt!);
        }
        return null;
      case 'delivered':
        if (order.deliveredAt != null) {
          return _formatDateTime(order.deliveredAt!);
        }
        return null;
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted || isCurrent
        ? AppColors.primary
        : AppColors.textHint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isCompleted || isCurrent
                      ? Colors.white
                      : AppColors.textHint,
                ),
              ),
              // Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 24,
                top: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: isCompleted || isCurrent
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
