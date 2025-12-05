import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';

/// Movie Night Screen - Vote for movies and see schedule
class MovieNightScreen extends ConsumerWidget {
  const MovieNightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Night'),
        backgroundColor: Colors.purple,
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
                  colors: [Colors.purple, Colors.deepPurple],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.movie, size: 60, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Movie Night',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vote for the next movie screening!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Current Poll
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('moviePolls')
                    .where('isActive', isEqualTo: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildNoPoll(context);
                  }

                  final poll = snapshot.data!.docs.first;
                  final pollData = poll.data() as Map<String, dynamic>;
                  final movies = (pollData['movies'] as List<dynamic>?) ?? [];
                  final eventDate = pollData['eventDate'] ?? 'TBA';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.how_to_vote, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            'Vote Now!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Event Date: $eventDate',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ...movies.map((movie) {
                        final movieData = movie as Map<String, dynamic>;
                        return _MovieVoteCard(
                          pollId: poll.id,
                          movieName: movieData['name'] ?? '',
                          votes: movieData['votes'] ?? 0,
                          userId: user.valueOrNull?.id,
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            // Past Screenings
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Past Screenings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('movieScreenings')
                        .orderBy('date', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No past screenings yet');
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.movie_outlined),
                            title: Text(data['movieName'] ?? 'Unknown'),
                            subtitle: Text(data['date'] ?? ''),
                            trailing: Text('${data['attendees'] ?? 0} attended'),
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

  Widget _buildNoPoll(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.movie_filter, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Active Poll',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for the next movie voting!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieVoteCard extends StatelessWidget {
  final String pollId;
  final String movieName;
  final int votes;
  final String? userId;

  const _MovieVoteCard({
    required this.pollId,
    required this.movieName,
    required this.votes,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userId != null
          ? FirebaseFirestore.instance
              .collection('moviePolls')
              .doc(pollId)
              .collection('votes')
              .doc(userId)
              .snapshots()
          : null,
      builder: (context, voteSnapshot) {
        final docExists = voteSnapshot.data?.exists == true;
        String? votedFor;
        if (docExists && voteSnapshot.data != null) {
          final data = voteSnapshot.data!.data() as Map<String, dynamic>?;
          votedFor = data?['movieName'] as String?;
        }
        final hasVoted = votedFor != null;
        final isThisMovieVoted = votedFor == movieName;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isThisMovieVoted
                ? const BorderSide(color: Colors.purple, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isThisMovieVoted ? Icons.check_circle : Icons.theaters,
                color: Colors.purple,
              ),
            ),
            title: Text(movieName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$votes votes'),
            trailing: hasVoted
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isThisMovieVoted ? Colors.purple : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isThisMovieVoted ? 'Voted' : 'Voted Other',
                      style: TextStyle(
                        color: isThisMovieVoted ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: userId == null
                        ? null
                        : () => _castVote(context, pollId, movieName, votes, userId!),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text('Vote', style: TextStyle(color: Colors.white)),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _castVote(
    BuildContext context,
    String pollId,
    String movieName,
    int currentVotes,
    String oderId,
  ) async {
    try {
      final pollRef = FirebaseFirestore.instance.collection('moviePolls').doc(pollId);

      // Use a transaction to ensure atomic update
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final pollDoc = await transaction.get(pollRef);
        if (!pollDoc.exists) return;

        final data = pollDoc.data()!;
        final movies = List<Map<String, dynamic>>.from(data['movies'] ?? []);

        // Find and update the movie's vote count
        for (int i = 0; i < movies.length; i++) {
          if (movies[i]['name'] == movieName) {
            movies[i] = {
              'name': movieName,
              'votes': (movies[i]['votes'] ?? 0) + 1,
            };
            break;
          }
        }

        // Update the poll with new vote counts
        transaction.update(pollRef, {'movies': movies});

        // Record the user's vote to prevent duplicates
        final voteRef = pollRef.collection('votes').doc(oderId);
        transaction.set(voteRef, {
          'movieName': movieName,
          'votedAt': Timestamp.now(),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voted for $movieName!'),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}