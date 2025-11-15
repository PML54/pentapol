// Modified: 2025-11-15 06:45:00
// lib/data/race_repo.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class RaceRepo {
  final _sb = Supabase.instance.client;

  Future<Race> createRace({required String puzzleId}) async {
    final uid = _sb.auth.currentUser!.id;
    final row = await _sb.from('races').insert({
      'puzzle_id': puzzleId,
      'created_by': uid,
      'status': 'running',
    }).select().single();
    // s’auto-ajouter comme participant
    await _sb.from('race_participants').insert({
      'race_id': row['id'],
      'player_id': uid,
    });
    return Race.fromJson(row);
  }

  Future<List<Race>> myRaces() async {
    final rows = await _sb.from('races')
        .select('id,puzzle_id,created_by,status')
        .order('started_at', ascending: false)
        .limit(20);
    return (rows as List).map((e) => Race.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> joinRace(String raceId) async {
    final uid = _sb.auth.currentUser!.id;
    await _sb.from('race_participants').insert({
      'race_id': raceId, 'player_id': uid,
    });
  }

  Future<void> finishRace({required String raceId, required int elapsedMs, required int piecesPlaced}) async {
    await _sb.rpc('finish_race', params: {
      'p_race_id': raceId,
      'p_elapsed_ms': elapsedMs,
      'p_pieces_placed': piecesPlaced,
      'p_moves_hash': null,
    });
  }
  Future<List<RaceResult>> fetchLeaderboard(String raceId) async {
    final rows = await _sb
        .from('race_results')
        .select('player_id, elapsed_ms, pieces_placed, finished_at')
        .eq('race_id', raceId)
        .order('elapsed_ms', ascending: true)
        .limit(100);

    final list = (rows as List)
        .map((e) => RaceResult.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }
}
