import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/order_viewmodel.dart';

/// Order Type Selector - Choose delivery, dine-in, or takeaway
class OrderTypeSelector extends ConsumerWidget {
  const OrderTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedOrderTypeProvider);

    return Row(
      children: [
        Expanded(
          child: _OrderTypeOption(
            icon: Icons.delivery_dining,
            label: 'Delivery',
            value: 'delivery',
            selectedValue: selectedType,
            onTap: () {
              ref.read(selectedOrderTypeProvider.notifier).state = 'delivery';
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OrderTypeOption(
            icon: Icons.restaurant,
            label: 'Dine-In',
            value: 'dine-in',
            selectedValue: selectedType,
            onTap: () {
              ref.read(selectedOrderTypeProvider.notifier).state = 'dine-in';
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OrderTypeOption(
            icon: Icons.shopping_bag,
            label: 'Takeaway',
            value: 'takeaway',
            selectedValue: selectedType,
            onTap: () {
              ref.read(selectedOrderTypeProvider.notifier).state = 'takeaway';
            },
          ),
        ),
      ],
    );
  }
}

class _OrderTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String selectedValue;
  final VoidCallback onTap;

  const _OrderTypeOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
