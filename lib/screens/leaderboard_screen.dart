import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/race_repo.dart';
import '../models.dart';
import '../utils/time_format.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.raceId});
  final String raceId;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final repo = RaceRepo();
  late Future<List<RaceResult>> future;

  @override
  void initState() {
    super.initState();
    future = repo.fetchLeaderboard(widget.raceId);
  }

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: FutureBuilder<List<RaceResult>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erreur: ${snap.error}'));
          }
          final data = snap.data ?? const [];
          if (data.isEmpty) {
            return const Center(child: Text('Aucun résultat pour cette course.'));
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = data[i];
              final isMe = r.playerId == me;
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(
                  isMe ? 'Moi' : 'Joueur ${r.playerId.substring(0, 6)}',
                  style: isMe ? const TextStyle(fontWeight: FontWeight.bold) : null,
                ),
                subtitle: Text('Pièces: ${r.piecesPlaced} • Fin: ${r.finishedAt.toLocal()}'),
                trailing: Text(
                  formatMillis(r.elapsedMs),
                  style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
