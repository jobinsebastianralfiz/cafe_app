import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Admin screen for managing Saturday Games sessions and board games library
class GamesManagementScreen extends ConsumerStatefulWidget {
  const GamesManagementScreen({super.key});

  @override
  ConsumerState<GamesManagementScreen> createState() => _GamesManagementScreenState();
}

class _GamesManagementScreenState extends ConsumerState<GamesManagementScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Sessions', icon: Icon(Icons.event)),
            Tab(text: 'Game Library', icon: Icon(Icons.casino)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateSessionDialog(context);
          } else {
            _showAddGameDialog(context);
          }
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'New Session' : 'Add Game'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsTab(),
          _buildGamesLibraryTab(),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('gameSessions')
          .orderBy('date', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No game sessions yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Tap + to create a session', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildSessionCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildSessionCard(String sessionId, Map<String, dynamic> data) {
    final date = data['date'] ?? 'TBD';
    final time = data['time'] ?? '6:00 PM';
    final maxPlayers = data['maxPlayers'] ?? 20;
    final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
    final games = List<Map<String, dynamic>>.from(data['games'] ?? []);

    final isUpcoming = _isUpcomingDate(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUpcoming ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isUpcoming ? 'UPCOMING' : 'PAST',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'delete') {
                      _deleteSession(sessionId);
                    } else if (action == 'edit_games') {
                      _showEditGamesDialog(context, sessionId, games);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit_games', child: Text('Edit Games')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Session', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(time, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${players.length}/$maxPlayers registered', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: games.map((game) => Chip(
                label: Text(game['name'] ?? 'Game', style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.teal.withValues(alpha: 0.1),
              )).toList(),
            ),
            if (players.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Registered Players:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: players.map((p) => Chip(
                  avatar: const CircleAvatar(child: Icon(Icons.person, size: 14)),
                  label: Text(p['name'] ?? 'Unknown', style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGamesLibraryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('boardGames').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.casino, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No games in library', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Tap + to add games', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
                  child: const Icon(Icons.casino, color: Colors.teal),
                ),
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text('${data['players'] ?? '2-4'} players | ${data['duration'] ?? '30 min'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteGame(doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isUpcomingDate(String dateStr) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  void _showCreateSessionDialog(BuildContext context) {
    final dateController = TextEditingController();
    final timeController = TextEditingController(text: '6:00 PM');
    final maxPlayersController = TextEditingController(text: '20');
    DateTime? selectedDate;
    List<Map<String, dynamic>> selectedGames = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Game Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _getNextSaturday(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (date != null) {
                          selectedDate = date;
                          dateController.text = DateFormat('MMM dd, yyyy').format(date);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxPlayersController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Players'),
                ),
                const SizedBox(height: 16),
                const Text('Select Games:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                // Game selection from library
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('boardGames').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final games = snapshot.data!.docs;
                    if (games.isEmpty) {
                      return const Text('Add games to library first', style: TextStyle(color: Colors.grey));
                    }
                    return Wrap(
                      spacing: 8,
                      children: games.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isSelected = selectedGames.any((g) => g['name'] == data['name']);
                        return FilterChip(
                          label: Text(data['name'] ?? ''),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              selectedGames.add(data);
                            } else {
                              selectedGames.removeWhere((g) => g['name'] == data['name']);
                            }
                            setState(() {});
                          },
                        );
                      }).toList(),
                    );
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
                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a date')),
                  );
                  return;
                }

                await _firestore.collection('gameSessions').add({
                  'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
                  'time': timeController.text.trim(),
                  'maxPlayers': int.tryParse(maxPlayersController.text) ?? 20,
                  'games': selectedGames,
                  'players': [],
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session created!')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGameDialog(BuildContext context) {
    final nameController = TextEditingController();
    final playersController = TextEditingController(text: '2-4');
    final durationController = TextEditingController(text: '30-60 min');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Game to Library'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Game Name*'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: playersController,
                decoration: const InputDecoration(labelText: 'Players (e.g., 2-4)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duration (e.g., 30-60 min)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter game name')),
                );
                return;
              }

              await _firestore.collection('boardGames').add({
                'name': nameController.text.trim(),
                'players': playersController.text.trim(),
                'duration': durationController.text.trim(),
                'description': descController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditGamesDialog(BuildContext context, String sessionId, List<Map<String, dynamic>> currentGames) {
    List<Map<String, dynamic>> selectedGames = List.from(currentGames);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Session Games'),
          content: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('boardGames').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final games = snapshot.data!.docs;
              return Wrap(
                spacing: 8,
                children: games.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isSelected = selectedGames.any((g) => g['name'] == data['name']);
                  return FilterChip(
                    label: Text(data['name'] ?? ''),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        selectedGames.add(data);
                      } else {
                        selectedGames.removeWhere((g) => g['name'] == data['name']);
                      }
                      setState(() {});
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('gameSessions').doc(sessionId).update({
                  'games': selectedGames,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Games updated!')),
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

  Future<void> _deleteSession(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text('This will remove the session and all registrations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('gameSessions').doc(sessionId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted')),
        );
      }
    }
  }

  Future<void> _deleteGame(String gameId) async {
    await _firestore.collection('boardGames').doc(gameId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game removed')),
      );
    }
  }

  DateTime _getNextSaturday() {
    var date = DateTime.now();
    while (date.weekday != DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }
}