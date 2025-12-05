import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Venue Settings Screen
class VenueSettingsScreen extends ConsumerStatefulWidget {
  const VenueSettingsScreen({super.key});

  @override
  ConsumerState<VenueSettingsScreen> createState() => _VenueSettingsScreenState();
}

class _VenueSettingsScreenState extends ConsumerState<VenueSettingsScreen> {
  bool _isLoading = true;
  bool _isOpen = true;
  String _openTime = '09:00';
  String _closeTime = '22:00';
  String _cafeName = 'Ralfiz Cafe';
  String _address = '';
  String _phone = '';
  int _tableCount = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('venue')
          .doc('settings')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isOpen = data['isOpen'] ?? true;
          _openTime = data['openTime'] ?? '09:00';
          _closeTime = data['closeTime'] ?? '22:00';
          _cafeName = data['name'] ?? 'Ralfiz Cafe';
          _address = data['address'] ?? '';
          _phone = data['phone'] ?? '';
          _tableCount = data['tableCount'] ?? 10;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('venue')
          .doc('settings')
          .set({
        'isOpen': _isOpen,
        'openTime': _openTime,
        'closeTime': _closeTime,
        'name': _cafeName,
        'address': _address,
        'phone': _phone,
        'tableCount': _tableCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cafe Status
                  Card(
                    child: SwitchListTile(
                      title: const Text('Cafe Status'),
                      subtitle: Text(_isOpen ? 'Open' : 'Closed'),
                      value: _isOpen,
                      activeColor: Colors.green,
                      onChanged: (value) => setState(() => _isOpen = value),
                      secondary: Icon(
                        _isOpen ? Icons.store : Icons.store_mall_directory,
                        color: _isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Operating Hours
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Operating Hours',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: const Text('Open'),
                                  subtitle: Text(_openTime),
                                  leading: const Icon(Icons.access_time),
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: int.parse(_openTime.split(':')[0]),
                                        minute: int.parse(_openTime.split(':')[1]),
                                      ),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _openTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                      });
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: const Text('Close'),
                                  subtitle: Text(_closeTime),
                                  leading: const Icon(Icons.access_time),
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: int.parse(_closeTime.split(':')[0]),
                                        minute: int.parse(_closeTime.split(':')[1]),
                                      ),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _closeTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cafe Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cafe Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Cafe Name',
                              prefixIcon: Icon(Icons.store),
                            ),
                            controller: TextEditingController(text: _cafeName),
                            onChanged: (value) => _cafeName = value,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            controller: TextEditingController(text: _address),
                            onChanged: (value) => _address = value,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            controller: TextEditingController(text: _phone),
                            keyboardType: TextInputType.phone,
                            onChanged: (value) => _phone = value,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table Management
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Table Management',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.table_restaurant),
                              const SizedBox(width: 16),
                              const Text('Number of Tables:'),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  if (_tableCount > 1) {
                                    setState(() => _tableCount--);
                                  }
                                },
                                icon: const Icon(Icons.remove_circle),
                              ),
                              Text(
                                '$_tableCount',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _tableCount++),
                                icon: const Icon(Icons.add_circle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
