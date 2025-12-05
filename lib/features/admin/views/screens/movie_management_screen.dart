import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Admin screen for managing Movie Night polls and screenings
class MovieManagementScreen extends ConsumerStatefulWidget {
  const MovieManagementScreen({super.key});

  @override
  ConsumerState<MovieManagementScreen> createState() => _MovieManagementScreenState();
}

class _MovieManagementScreenState extends ConsumerState<MovieManagementScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Night Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePollDialog(context),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add),
        label: const Text('New Poll'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Poll Section
            _buildSectionHeader('Active Poll', Icons.how_to_vote),
            const SizedBox(height: 12),
            _buildActivePoll(),
            const SizedBox(height: 24),

            // Past Screenings Section
            _buildSectionHeader('Past Screenings', Icons.history),
            const SizedBox(height: 12),
            _buildPastScreenings(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePoll() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('moviePolls')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.movie_filter, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'No active poll',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a new poll to start collecting votes',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final poll = snapshot.data!.docs.first;
        final pollData = poll.data() as Map<String, dynamic>;
        final movies = List<Map<String, dynamic>>.from(pollData['movies'] ?? []);
        final eventDate = pollData['eventDate'] ?? 'TBD';

        return Card(
          elevation: 4,
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
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Event: $eventDate', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'end') {
                          _endPoll(poll.id, movies);
                        } else if (action == 'add_movie') {
                          _showAddMovieDialog(context, poll.id, movies);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'add_movie', child: Text('Add Movie')),
                        const PopupMenuItem(
                          value: 'end',
                          child: Text('End Poll & Announce Winner', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Movies in Poll:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...movies.map((movie) => _buildMovieItem(poll.id, movie, movies)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovieItem(String pollId, Map<String, dynamic> movie, List<Map<String, dynamic>> allMovies) {
    final name = movie['name'] ?? 'Unknown';
    final votes = movie['votes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.movie, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('$votes votes', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeMovie(pollId, movie, allMovies),
          ),
        ],
      ),
    );
  }

  Widget _buildPastScreenings() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('movieScreenings')
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No past screenings yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.movie, color: Colors.white),
                ),
                title: Text(data['movieName'] ?? 'Unknown'),
                subtitle: Text('Date: ${data['date'] ?? 'N/A'}'),
                trailing: Text('${data['attendees'] ?? 0} attended'),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showCreatePollDialog(BuildContext context) {
    final movieControllers = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    final dateController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Movie Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event Date Picker
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Event Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
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
                const SizedBox(height: 16),
                const Text('Movies (add at least 2):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...movieControllers.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Movie ${entry.key + 1}',
                      prefixIcon: const Icon(Icons.movie),
                    ),
                  ),
                )),
                TextButton.icon(
                  onPressed: () {
                    movieControllers.add(TextEditingController());
                    setState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Movie'),
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
                final movies = movieControllers
                    .map((c) => c.text.trim())
                    .where((m) => m.isNotEmpty)
                    .toList();

                if (movies.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add at least 2 movies')),
                  );
                  return;
                }

                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select an event date')),
                  );
                  return;
                }

                // Deactivate any existing active polls
                final existingPolls = await _firestore
                    .collection('moviePolls')
                    .where('isActive', isEqualTo: true)
                    .get();

                for (final doc in existingPolls.docs) {
                  await doc.reference.update({'isActive': false});
                }

                // Create new poll
                await _firestore.collection('moviePolls').add({
                  'isActive': true,
                  'eventDate': DateFormat('MMM dd, yyyy').format(selectedDate!),
                  'movies': movies.map((m) => {'name': m, 'votes': 0}).toList(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Poll created!')),
                  );
                }
              },
              child: const Text('Create Poll'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMovieDialog(BuildContext context, String pollId, List<Map<String, dynamic>> currentMovies) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Movie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Movie Name',
            prefixIcon: Icon(Icons.movie),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              final updatedMovies = [
                ...currentMovies,
                {'name': controller.text.trim(), 'votes': 0},
              ];

              await _firestore.collection('moviePolls').doc(pollId).update({
                'movies': updatedMovies,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Movie added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMovie(String pollId, Map<String, dynamic> movie, List<Map<String, dynamic>> allMovies) async {
    if (allMovies.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll must have at least 2 movies')),
      );
      return;
    }

    final updatedMovies = allMovies.where((m) => m['name'] != movie['name']).toList();
    await _firestore.collection('moviePolls').doc(pollId).update({
      'movies': updatedMovies,
    });
  }

  Future<void> _endPoll(String pollId, List<Map<String, dynamic>> movies) async {
    // Find winner
    movies.sort((a, b) => (b['votes'] ?? 0).compareTo(a['votes'] ?? 0));
    final winner = movies.first;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Poll?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              'Winner: ${winner['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('with ${winner['votes']} votes'),
            const SizedBox(height: 12),
            const Text('This will end the poll and add it to past screenings.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End & Announce'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Get poll data for event date
    final pollDoc = await _firestore.collection('moviePolls').doc(pollId).get();
    final pollData = pollDoc.data();

    // Deactivate poll
    await _firestore.collection('moviePolls').doc(pollId).update({
      'isActive': false,
    });

    // Add to past screenings
    await _firestore.collection('movieScreenings').add({
      'movieName': winner['name'],
      'date': pollData?['eventDate'] ?? DateFormat('MMM dd, yyyy').format(DateTime.now()),
      'attendees': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${winner['name']} wins!')),
      );
    }
  }
}