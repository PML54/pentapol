import 'package:supabase_flutter/supabase_flutter.dart';

/// Gestion très simple de la présence Realtime pour une course.
class RacePresence {
  final RealtimeChannel ch;
  RacePresence(this.ch);

  static RealtimeChannel open(String raceId) {
    final key = 'race:$raceId';
    return Supabase.instance.client.channel(
      key,
      opts: const RealtimeChannelConfig(self: true),
    );
  }

  Future<void> subscribeInitial({
    required String playerId,
    required String name,
    String? avatar,
    required int totalPieces,
  }) async {
    ch.subscribe();

    await ch.track({
      'playerId': playerId,
      'name': name,
      'avatar': avatar,
      'piecesPlaced': 0,
      'totalPieces': totalPieces,
      'lastUpdate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateProgress(int placed, int total) async {
    await ch.track({
      'piecesPlaced': placed,
      'totalPieces': total,
      'lastUpdate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Retourne la liste des joueurs (payloads) triés par pièces placées (desc).
  List<Map<String, dynamic>> players() {
    final out = <Map<String, dynamic>>[];
    for (final s in ch.presenceState()) {
      for (final pr in s.presences) {
        final m = Map<String, dynamic>.from(pr.payload);
        out.add(m);
      }
    }
    out.sort((a, b) {
      final ai = (a['piecesPlaced'] ?? 0) as int;
      final bi = (b['piecesPlaced'] ?? 0) as int;
      return bi.compareTo(ai);
    });
    return out;
  }

  Future<void> close() async {
    try {
      await ch.untrack();
    } catch (_) {}
    try {
      await ch.unsubscribe();
    } catch (_) {}
  }
}
