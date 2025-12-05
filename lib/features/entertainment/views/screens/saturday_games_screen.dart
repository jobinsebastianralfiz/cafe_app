import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';

/// Saturday Games Screen - Board games and activities at the cafe
class SaturdayGamesScreen extends ConsumerWidget {
  const SaturdayGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saturday Games'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.teal],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.casino, size: 60, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Saturday Game Night',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us every Saturday for board games & fun!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Upcoming Games Session
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('gameSessions')
                    .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()))
                    .orderBy('date')
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildNoSession(context);
                  }

                  final session = snapshot.data!.docs.first;
                  final data = session.data() as Map<String, dynamic>;
                  final date = data['date'] ?? 'TBA';
                  final time = data['time'] ?? '6:00 PM';
                  final games = (data['games'] as List<dynamic>?) ?? [];
                  final maxPlayers = data['maxPlayers'] ?? 20;
                  final currentPlayers = (data['players'] as List<dynamic>?)?.length ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Next Session',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.calendar_today, color: Colors.green),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Time: $time',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentPlayers < maxPlayers
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$currentPlayers/$maxPlayers',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (games.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text(
                                  'Games Available:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: games.map((game) {
                                    return Chip(
                                      avatar: const Icon(Icons.extension, size: 18),
                                      label: Text(game.toString()),
                                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: user.valueOrNull == null || currentPlayers >= maxPlayers
                                      ? null
                                      : () => _registerForSession(
                                            context,
                                            session.id,
                                            user.valueOrNull!.id,
                                            user.valueOrNull!.name,
                                          ),
                                  icon: const Icon(Icons.person_add),
                                  label: Text(
                                    currentPlayers >= maxPlayers ? 'Session Full' : 'Register',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Available Games
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.games, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Our Game Collection',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('boardGames')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildDefaultGames();
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _GameCard(
                            name: data['name'] ?? 'Unknown',
                            players: data['players'] ?? '2-4',
                            duration: data['duration'] ?? '30-60 min',
                            description: data['description'] ?? '',
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSession(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Upcoming Sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back for the next Saturday game night!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultGames() {
    final defaultGames = [
      {'name': 'Catan', 'players': '3-4', 'duration': '60-90 min', 'description': 'Trade, build and settle the island of Catan'},
      {'name': 'Ticket to Ride', 'players': '2-5', 'duration': '30-60 min', 'description': 'Build railway routes across the country'},
      {'name': 'Uno', 'players': '2-10', 'duration': '20-30 min', 'description': 'Classic card game of matching colors and numbers'},
      {'name': 'Chess', 'players': '2', 'duration': '30-60 min', 'description': 'The timeless strategy game'},
      {'name': 'Scrabble', 'players': '2-4', 'duration': '60-90 min', 'description': 'Build words and score points'},
    ];

    return Column(
      children: defaultGames.map((game) {
        return _GameCard(
          name: game['name']!,
          players: game['players']!,
          duration: game['duration']!,
          description: game['description']!,
        );
      }).toList(),
    );
  }

  Future<void> _registerForSession(
    BuildContext context,
    String sessionId,
    String userId,
    String userName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('gameSessions')
          .doc(sessionId)
          .update({
        'players': FieldValue.arrayUnion([
          {'userId': userId, 'name': userName}
        ]),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully registered for game night!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _GameCard extends StatelessWidget {
  final String name;
  final String players;
  final String duration;
  final String description;

  const _GameCard({
    required this.name,
    required this.players,
    required this.duration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.extension, color: Colors.teal),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(players, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(duration, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}