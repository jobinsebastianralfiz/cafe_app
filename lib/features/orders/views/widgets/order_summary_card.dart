import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/order_pricing_model.dart';

/// Order Summary Card - Shows pricing breakdown
class OrderSummaryCard extends StatelessWidget {
  final OrderPricingModel pricing;

  const OrderSummaryCard({
    super.key,
    required this.pricing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Text(
            'Bill Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          _PricingRow(
            label: 'Item Total',
            value: pricing.formattedSubtotal,
          ),
          if (pricing.deliveryCharges > 0) ...[
            const SizedBox(height: 8),
            _PricingRow(
              label: 'Delivery Charges',
              value: pricing.formattedDeliveryCharges,
            ),
          ],
          const SizedBox(height: 8),
          _PricingRow(
            label: 'Taxes & Charges',
            value: pricing.formattedTaxAmount,
          ),
          if (pricing.coinDiscount > 0) ...[
            const SizedBox(height: 8),
            _PricingRow(
              label: 'Coin Discount',
              value: pricing.formattedCoinDiscount,
              valueColor: AppColors.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _PricingRow(
            label: 'Total Amount',
            value: pricing.formattedFinalAmount,
            isBold: true,
            labelColor: AppColors.textPrimary,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? labelColor;
  final Color? valueColor;

  const _PricingRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.labelColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: labelColor ?? AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
