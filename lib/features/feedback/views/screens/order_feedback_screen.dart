import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/feedback_model.dart';
import '../../viewmodels/feedback_viewmodel.dart';

/// Order Feedback Screen - Submit feedback for an order
class OrderFeedbackScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderNumber;

  const OrderFeedbackScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  ConsumerState<OrderFeedbackScreen> createState() => _OrderFeedbackScreenState();
}

class _OrderFeedbackScreenState extends ConsumerState<OrderFeedbackScreen> {
  double _overallRating = 0;
  double _foodRating = 0;
  double _serviceRating = 0;
  double _deliveryRating = 0;
  bool _wouldRecommend = true;
  final _commentController = TextEditingController();
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackState = ref.watch(feedbackViewModelProvider);

    ref.listen<FeedbackState>(feedbackViewModelProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(feedbackViewModelProvider.notifier).clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(feedbackViewModelProvider.notifier).clearMessages();
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate Your Order'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Order ${widget.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Overall Rating
            _buildRatingSection(
              title: 'Overall Experience',
              rating: _overallRating,
              onRatingChanged: (value) => setState(() => _overallRating = value),
              isMain: true,
            ),
            const SizedBox(height: 24),

            // Detailed Ratings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate specific aspects',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSmallRatingRow(
                    label: 'Food Quality',
                    icon: Icons.restaurant,
                    rating: _foodRating,
                    onRatingChanged: (value) => setState(() => _foodRating = value),
                  ),
                  const Divider(height: 24),
                  _buildSmallRatingRow(
                    label: 'Service',
                    icon: Icons.room_service,
                    rating: _serviceRating,
                    onRatingChanged: (value) => setState(() => _serviceRating = value),
                  ),
                  const Divider(height: 24),
                  _buildSmallRatingRow(
                    label: 'Delivery',
                    icon: Icons.delivery_dining,
                    rating: _deliveryRating,
                    onRatingChanged: (value) => setState(() => _deliveryRating = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Feedback Tags
            Text(
              'What did you like?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FeedbackTags.positiveTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Would Recommend
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Would you recommend us?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help others discover great food',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _wouldRecommend = true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _wouldRecommend
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.thumb_up,
                            color: _wouldRecommend ? AppColors.success : AppColors.textHint,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _wouldRecommend = false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !_wouldRecommend
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.thumb_down,
                            color: !_wouldRecommend ? AppColors.error : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Comment
            Text(
              'Additional comments (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Tell us more about your experience...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _overallRating > 0 && !feedbackState.isLoading
                    ? () => _submitFeedback()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: feedbackState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required double rating,
    required ValueChanged<double> onRatingChanged,
    bool isMain = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isMain ? 18 : 15,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(starValue.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    rating >= starValue ? Icons.star : Icons.star_border,
                    size: isMain ? 48 : 36,
                    color: rating >= starValue ? AppColors.ratingGold : AppColors.textHint,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallRatingRow({
    required String label,
    required IconData icon,
    required double rating,
    required ValueChanged<double> onRatingChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => onRatingChanged(starValue.toDouble()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  rating >= starValue ? Icons.star : Icons.star_border,
                  size: 24,
                  color: rating >= starValue ? AppColors.ratingGold : AppColors.textHint,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    await ref.read(feedbackViewModelProvider.notifier).submitOrderFeedback(
          orderId: widget.orderId,
          orderNumber: widget.orderNumber,
          overallRating: _overallRating,
          foodRating: _foodRating,
          serviceRating: _serviceRating,
          deliveryRating: _deliveryRating,
          comment: _commentController.text.isNotEmpty ? _commentController.text : null,
          tags: _selectedTags.toList(),
          wouldRecommend: _wouldRecommend,
        );
  }
}
