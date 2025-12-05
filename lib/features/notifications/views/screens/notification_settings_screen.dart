import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';
import '../../viewmodels/notification_viewmodel.dart';

/// Notification Settings Screen - Manage notification preferences
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefsAsync = await ref.read(notificationPreferencesProvider.future);
    setState(() {
      _preferences = prefsAsync;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_preferences == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Push Notifications Section
          _buildSectionTitle('Push Notifications'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive push notifications on your device',
              value: _preferences!.pushNotifications,
              onChanged: (value) => _updatePreference(
                _preferences!.copyWith(pushNotifications: value),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Notification Types Section
          _buildSectionTitle('Notification Types'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Order Updates',
              subtitle: 'Get notified about your order status',
              value: _preferences!.orderUpdates,
              onChanged: (value) => _updatePreference(
                _preferences!.copyWith(orderUpdates: value),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Promotions & Offers',
              subtitle: 'Receive special deals and discounts',
              value: _preferences!.promotions,
              onChanged: (value) => _updatePreference(
                _preferences!.copyWith(promotions: value),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Reservation Reminders',
              subtitle: 'Get reminded about upcoming reservations',
              value: _preferences!.reservationReminders,
              onChanged: (value) => _updatePreference(
                _preferences!.copyWith(reservationReminders: value),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Coin Updates',
              subtitle: 'Know when you earn or spend coins',
              value: _preferences!.coinUpdates,
              onChanged: (value) => _updatePreference(
                _preferences!.copyWith(coinUpdates: value),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Events & Entertainment',
              subtitle: 'Movie nights, games, and special events',
              value: _preferences!.events,
              onChanged: (value) => _updatePreference(
                _preferences!.copyWith(events: value),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Email Notifications Section
          _buildSectionTitle('Email Notifications'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: _preferences!.emailNotifications,
              onChanged: (value) => _updatePreference(
                _preferences!.copyWith(emailNotifications: value),
              ),
            ),
          ]),
          const SizedBox(height: 32),

          // Info Text
          Center(
            child: Text(
              'You can always adjust these settings later',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
            ),
          ),
        ],
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

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _updatePreference(NotificationPreferences newPreferences) {
    setState(() {
      _preferences = newPreferences;
    });
    ref.read(notificationViewModelProvider.notifier).updatePreferences(newPreferences);
  }
}
