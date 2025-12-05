import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/table_model.dart';
import '../../viewmodels/table_viewmodel.dart';
import '../widgets/table_card.dart';
import '../widgets/table_qr_dialog.dart';

/// Table Management Screen for Admin
class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(allTablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLegendDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTableDialog(context, ref),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Table', style: TextStyle(color: Colors.white)),
      ),
      body: tablesAsync.when(
        data: (tables) {
          if (tables.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return TableCard(
                table: table,
                onTap: () => _showTableDetails(context, table),
                onQrTap: () => showTableQrDialog(context, table),
                onEditTap: () => _showEditTableDialog(context, ref, table),
                onDeleteTap: () => _confirmDeleteTable(context, ref, table),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(allTablesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Tables Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first table to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTableDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Table'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(Colors.green, 'Available', 'Ready for customers'),
            const SizedBox(height: 12),
            _legendItem(Colors.red, 'Occupied', 'Has active order'),
            const SizedBox(height: 12),
            _legendItem(Colors.orange, 'Reserved', 'Reserved for later'),
            const SizedBox(height: 12),
            _legendItem(Colors.grey, 'Inactive', 'Not available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddTableDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    int capacity = 4;
    TableLocation location = TableLocation.indoor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Table'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Table Name',
                    hintText: 'e.g., Table 1, Patio A',
                    prefixIcon: Icon(Icons.table_restaurant),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Text('Capacity:'),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        if (capacity > 1) setState(() => capacity--);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$capacity',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => setState(() => capacity++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TableLocation>(
                  value: location,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: TableLocation.values.map((loc) {
                    return DropdownMenuItem(
                      value: loc,
                      child: Text(loc.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => location = value);
                  },
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a table name')),
                  );
                  return;
                }

                final result = await ref.read(tableViewModelProvider.notifier).createTable(
                  name: name,
                  capacity: capacity,
                  location: location,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name added successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add table')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTableDialog(BuildContext context, WidgetRef ref, TableModel table) {
    final nameController = TextEditingController(text: table.name);
    int capacity = table.capacity;
    TableLocation location = table.location;
    bool isActive = table.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Table'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Table Name',
                    prefixIcon: Icon(Icons.table_restaurant),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Text('Capacity:'),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        if (capacity > 1) setState(() => capacity--);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$capacity',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => setState(() => capacity++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TableLocation>(
                  value: location,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: TableLocation.values.map((loc) {
                    return DropdownMenuItem(
                      value: loc,
                      child: Text(loc.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => location = value);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: Text(isActive ? 'Table is available' : 'Table is hidden'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a table name')),
                  );
                  return;
                }

                final result = await ref.read(tableViewModelProvider.notifier).updateTable(
                  tableId: table.id,
                  name: name,
                  capacity: capacity,
                  location: location,
                  isActive: isActive,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result ? 'Table updated' : 'Failed to update'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTable(BuildContext context, WidgetRef ref, TableModel table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Are you sure you want to delete "${table.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await ref.read(tableViewModelProvider.notifier).deleteTable(table.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result ? 'Table deleted' : 'Failed to delete'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTableDetails(BuildContext context, TableModel table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_restaurant, size: 40, color: Colors.teal),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        table.status.displayName,
                        style: TextStyle(
                          color: table.status == TableStatus.available
                              ? Colors.green
                              : table.status == TableStatus.occupied
                                  ? Colors.red
                                  : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _detailRow(Icons.people, 'Capacity', '${table.capacity} seats'),
            const SizedBox(height: 12),
            _detailRow(Icons.location_on, 'Location', table.location.displayName),
            const SizedBox(height: 12),
            _detailRow(
              Icons.circle,
              'Status',
              table.isActive ? 'Active' : 'Inactive',
            ),
            if (table.currentOrderId != null) ...[
              const SizedBox(height: 12),
              _detailRow(Icons.receipt, 'Current Order', table.currentOrderId!),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showTableQrDialog(context, table);
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('View QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
