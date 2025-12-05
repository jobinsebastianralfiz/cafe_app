import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Daily Specials Management Screen
class DailySpecialsScreen extends ConsumerWidget {
  const DailySpecialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Specials'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSpecialDialog(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('dailySpecials')
            .orderBy('date', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No daily specials. Tap + to add.'));
          }

          final specials = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: specials.length,
            itemBuilder: (context, index) {
              final special = specials[index];
              final data = special.data() as Map<String, dynamic>;
              final isToday = data['date'] == today;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isToday ? Colors.red.shade50 : null,
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.red : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    data['date'] ?? 'Unknown Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.red : null,
                    ),
                  ),
                  subtitle: Text(
                    isToday ? "Today's Special" : '',
                    style: const TextStyle(color: Colors.red),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSpecial(context, special.id),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['items'] != null)
                            ...(data['items'] as List).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(item['name'] ?? ''),
                                  ),
                                  Text(
                                    '₹${item['price']?.toString() ?? '0'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (item['originalPrice'] != null)
                                    Text(
                                      ' ₹${item['originalPrice']}',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            )),
                          if (data['description'] != null && data['description'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data['description'],
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSpecialDialog(BuildContext context) {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final descController = TextEditingController();
    final List<Map<String, dynamic>> items = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Daily Special'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      dateController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Special Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                    title: Text(item['name'] ?? ''),
                    subtitle: Text('₹${item['price']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() => items.removeAt(index)),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _showAddItemDialog(context, (item) {
                    setState(() => items.add(item));
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dateController.text.isEmpty || items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill date and add at least one item')),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('dailySpecials')
                    .doc(dateController.text)
                    .set({
                  'date': dateController.text,
                  'description': descController.text,
                  'items': items,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily special added!')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, Function(Map<String, dynamic>) onAdd) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final originalPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Special Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Special Price (₹)'),
            ),
            TextField(
              controller: originalPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Original Price (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                onAdd({
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'originalPrice': double.tryParse(originalPriceController.text),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteSpecial(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Special'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('dailySpecials')
                  .doc(docId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}