import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/reservation_model.dart';
import '../../viewmodels/reservation_viewmodel.dart';

/// Reservation Screen - Book a table
class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({super.key});

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  final _specialRequestsController = TextEditingController();
  String? _selectedOccasion;

  final List<String> _occasions = [
    'Birthday',
    'Anniversary',
    'Date Night',
    'Business Meeting',
    'Family Gathering',
    'Friends Meetup',
    'Other',
  ];

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
    final partySize = ref.watch(partySizeProvider);
    final timeSlotsAsync = ref.watch(availableTimeSlotsProvider);
    final reservationState = ref.watch(reservationViewModelProvider);

    // Listen for state changes
    ref.listen<ReservationState>(reservationViewModelProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(reservationViewModelProvider.notifier).clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(reservationViewModelProvider.notifier).clearMessages();
        context.push('/reservations/history');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book a Table'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Party Size Section
            _buildSectionTitle('Party Size'),
            const SizedBox(height: 12),
            _buildPartySizeSelector(partySize),
            const SizedBox(height: 24),

            // Date Selection Section
            _buildSectionTitle('Select Date'),
            const SizedBox(height: 12),
            _buildDateSelector(selectedDate),
            const SizedBox(height: 24),

            // Time Slot Section
            _buildSectionTitle('Select Time'),
            const SizedBox(height: 12),
            timeSlotsAsync.when(
              data: (slots) => _buildTimeSlotGrid(slots, selectedTimeSlot),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading time slots: $e'),
            ),
            const SizedBox(height: 24),

            // Occasion Section
            _buildSectionTitle('Occasion (Optional)'),
            const SizedBox(height: 12),
            _buildOccasionSelector(),
            const SizedBox(height: 24),

            // Special Requests Section
            _buildSectionTitle('Special Requests (Optional)'),
            const SizedBox(height: 12),
            TextField(
              controller: _specialRequestsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any dietary requirements, seating preferences, etc.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (selectedDate != null && selectedTimeSlot != null && !reservationState.isLoading)
                    ? () => _handleBooking()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: reservationState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Book Table',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // View History Link
            Center(
              child: TextButton(
                onPressed: () => context.push('/reservations/history'),
                child: const Text('View My Reservations'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildPartySizeSelector(int currentSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentSize > 1
                ? () => ref.read(partySizeProvider.notifier).state = currentSize - 1
                : null,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentSize > 1 ? AppColors.primary : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove,
                color: currentSize > 1 ? Colors.white : AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              Text(
                currentSize.toString(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
              ),
              Text(
                currentSize == 1 ? 'Guest' : 'Guests',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          IconButton(
            onPressed: currentSize < 20
                ? () => ref.read(partySizeProvider.notifier).state = currentSize + 1
                : null,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentSize < 20 ? AppColors.primary : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: currentSize < 20 ? Colors.white : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(DateTime? selectedDate) {
    final now = DateTime.now();
    final dates = List.generate(14, (index) => now.add(Duration(days: index)));

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = selectedDate != null &&
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = date;
              ref.read(selectedTimeSlotProvider.notifier).state = null;
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<TimeSlotModel> slots, String? selectedSlot) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: slots.map((slot) {
        final isSelected = selectedSlot == slot.display;
        final isAvailable = slot.isAvailable;

        return GestureDetector(
          onTap: isAvailable
              ? () => ref.read(selectedTimeSlotProvider.notifier).state = slot.display
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isAvailable
                      ? Colors.white
                      : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: !isSelected && isAvailable
                  ? Border.all(color: AppColors.divider)
                  : null,
            ),
            child: Text(
              slot.display,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isAvailable
                        ? AppColors.textPrimary
                        : AppColors.textHint,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOccasionSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _occasions.map((occasion) {
        final isSelected = _selectedOccasion == occasion;

        return GestureDetector(
          onTap: () => setState(() => _selectedOccasion = isSelected ? null : occasion),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: !isSelected ? Border.all(color: AppColors.divider) : null,
            ),
            child: Text(
              occasion,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleBooking() async {
    final selectedDate = ref.read(selectedDateProvider);
    final selectedTimeSlot = ref.read(selectedTimeSlotProvider);
    final partySize = ref.read(partySizeProvider);

    if (selectedDate == null || selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    await ref.read(reservationViewModelProvider.notifier).createReservation(
          date: selectedDate,
          timeSlot: selectedTimeSlot,
          partySize: partySize,
          specialRequests: _specialRequestsController.text.isNotEmpty
              ? _specialRequestsController.text
              : null,
          occasion: _selectedOccasion,
        );
  }
}
