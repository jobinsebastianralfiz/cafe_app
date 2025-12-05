import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../venue/viewmodels/venue_viewmodel.dart';

/// Venue Status Banner - Shows if cafe is open/closed
class VenueStatusBanner extends ConsumerWidget {
  const VenueStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueSettings = ref.watch(venueSettingsProvider);
    final isOpenNow = ref.watch(isVenueOpenNowProvider);

    return venueSettings.when(
      data: (settings) {
        if (settings == null) return const SizedBox.shrink();

        final color = isOpenNow ? AppColors.success : AppColors.error;
        final icon = isOpenNow ? Icons.check_circle : Icons.info;
        final statusText = isOpenNow ? 'Open Now' : 'Closed';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.statusMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (isOpenNow) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getTodaySchedule(settings),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getTodaySchedule(settings) {
    final now = DateTime.now();
    final todaySchedule = settings.operatingHours.getScheduleForDay(now);
    if (todaySchedule.isOpen) {
      return 'Today: ${todaySchedule.displayTime}';
    }
    return 'Closed today';
  }
}
