import 'package:flutter/material.dart';
import '../../models/table_model.dart';

/// Table Card Widget for grid display
class TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback? onTap;
  final VoidCallback? onQrTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const TableCard({
    super.key,
    required this.table,
    this.onTap,
    this.onQrTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  Color get _statusColor {
    switch (table.status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
    }
  }

  IconData get _locationIcon {
    switch (table.location) {
      case TableLocation.indoor:
        return Icons.home;
      case TableLocation.outdoor:
        return Icons.park;
      case TableLocation.patio:
        return Icons.deck;
      case TableLocation.rooftop:
        return Icons.roofing;
      case TableLocation.private:
        return Icons.meeting_room;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: table.isActive ? _statusColor : Colors.grey,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header with menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location icon
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(_locationIcon, size: 14, color: Colors.grey[700]),
                  ),
                  // Menu
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        switch (value) {
                          case 'qr':
                            onQrTap?.call();
                            break;
                          case 'edit':
                            onEditTap?.call();
                            break;
                          case 'delete':
                            onDeleteTap?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'qr',
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, size: 20),
                              SizedBox(width: 8),
                              Text('View QR'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Table icon and name
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 32,
                    color: table.isActive ? _statusColor : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    table.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              // Footer with capacity and status
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${table.capacity}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: table.isActive ? _statusColor : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      table.isActive ? table.status.displayName : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
