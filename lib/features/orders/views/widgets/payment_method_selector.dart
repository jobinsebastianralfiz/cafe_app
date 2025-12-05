import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/order_viewmodel.dart';

/// Payment Method Selector - Choose payment method
class PaymentMethodSelector extends ConsumerWidget {
  const PaymentMethodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);

    return Column(
      children: [
        _PaymentMethodOption(
          icon: Icons.money,
          label: 'Cash on Delivery',
          subtitle: 'Pay when you receive',
          value: 'cash',
          selectedValue: selectedMethod,
          onTap: () {
            ref.read(selectedPaymentMethodProvider.notifier).state = 'cash';
          },
        ),
        const SizedBox(height: 12),
        _PaymentMethodOption(
          icon: Icons.qr_code_scanner,
          label: 'UPI',
          subtitle: 'PhonePe, Google Pay, Paytm',
          value: 'upi',
          selectedValue: selectedMethod,
          onTap: () {
            ref.read(selectedPaymentMethodProvider.notifier).state = 'upi';
          },
        ),
        const SizedBox(height: 12),
        _PaymentMethodOption(
          icon: Icons.credit_card,
          label: 'Card',
          subtitle: 'Credit/Debit Card',
          value: 'card',
          selectedValue: selectedMethod,
          onTap: () {
            ref.read(selectedPaymentMethodProvider.notifier).state = 'card';
          },
        ),
        const SizedBox(height: 12),
        _PaymentMethodOption(
          icon: Icons.account_balance_wallet,
          label: 'Wallet',
          subtitle: 'Paytm, PhonePe, etc.',
          value: 'wallet',
          selectedValue: selectedMethod,
          onTap: () {
            ref.read(selectedPaymentMethodProvider.notifier).state = 'wallet';
          },
        ),
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String value;
  final String selectedValue;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.icon,
    required this.label,
    required this.subtitle,
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
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
