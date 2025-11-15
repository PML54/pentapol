// Modified: 2025-11-15 06:45:00
// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/race_repo.dart';
import '../logic/race_presence.dart';
import '../models.dart';
import 'leaderboard_screen.dart';
import 'pentomino_game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repo = RaceRepo();
  List<Race> races = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      races = await repo.myRaces();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final race = await repo.createRace(puzzleId: 'pento-001');
    if (!mounted) return;
    setState(() => races.insert(0, race));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RaceLiveScreen(raceId: race.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour ${user.email}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.games),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PentominoGameScreen(),
                ),
              );
            },
            tooltip: 'Jouer au Pentomino',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        label: const Text('Créer une course'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        itemCount: races.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = races[i];
          return ListTile(
            title: Text('Course ${r.id.substring(0, 8)} — ${r.puzzleId}'),
            subtitle: Text(r.status),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaceLiveScreen(raceId: r.id),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () => repo.joinRace(r.id),
              tooltip: 'Rejoindre',
            ),
          );
        },
      ),
    );
  }
}

class RaceLiveScreen extends StatefulWidget {
  const RaceLiveScreen({super.key, required this.raceId});
  final String raceId;

  @override
  State<RaceLiveScreen> createState() => _RaceLiveScreenState();
}

class _RaceLiveScreenState extends State<RaceLiveScreen> {
  late final RealtimeChannel _ch;
  late final RacePresence presence;
  int placed = 0;
  final total = 12;

  @override
  void initState() {
    super.initState();
    _ch = RacePresence.open(widget.raceId);
    presence = RacePresence(_ch);

    final u = Supabase.instance.client.auth.currentUser!;
    // Souscrire + publier la présence initiale
    presence
        .subscribeInitial(
      playerId: u.id,
      name: u.email ?? 'Player',
      totalPieces: total,
    )
        .then((_) {
      // Rebuild quand la présence se resynchronise
      _ch.onPresenceSync((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    presence.close();
    super.dispose();
  }

  Future<void> _placeOne() async {
    setState(() => placed = (placed + 1).clamp(0, total));
    await presence.updateProgress(placed, total);
  }

  Future<void> _finish() async {
    final repo = RaceRepo();
    await repo.finishRace(
      raceId: widget.raceId,
      elapsedMs: 60000,
      piecesPlaced: placed,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Résultat enregistré')));
  }

  @override
  Widget build(BuildContext context) {
    final players = presence.players();

    return Scaffold(
      appBar: AppBar(title: Text('Course ${widget.raceId.substring(0, 8)}')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _placeOne,
                    child: const Text('Placer une pièce (+1)'),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Moi: $placed/$total'),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Progression des joueurs'),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: players.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = players[i];
                final name = (p['name'] as String?) ?? 'Player';
                final pp = (p['piecesPlaced'] ?? 0) as int;
                final tt = (p['totalPieces'] ?? total) as int;
                final ratio = tt == 0 ? 0.0 : (pp / tt).clamp(0.0, 1.0);

                return ListTile(
                  title: Text(name),
                  subtitle: LinearProgressIndicator(value: ratio),
                  trailing: Text('$pp/$tt'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LeaderboardScreen(raceId: widget.raceId),
                        ),
                      );
                    },
                    child: const Text('Voir le leaderboard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _finish,
                    child: const Text('Terminer et enregistrer'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
