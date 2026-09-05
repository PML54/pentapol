// Modified: 2026-09-05 00:00 — création : client HTTP du classement du défi (CDC §7, Phase 4/5).
//           POST du score à la fin d'un défi, GET des classements. Échecs silencieux (§7.8 : le jeu
//           reste entier sans réseau — jamais de bouton mort).
// lib/pentoscope/challenge_api.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// URL du worker de classement (déployé par Paul). Distinct du worker duel (WebSocket).
const String kChallengeBaseUrl = 'https://pentapol-defi.pentapml.workers.dev';

/// Les quatre maillots, tels que l'API les nomme (paramètre `maillot`).
enum Maillot { jaune, pois, vert, blanc }

/// Une ligne de classement renvoyée par `GET /leaderboard`.
class LeaderboardEntry {
  final String playerId;
  final String pseudo;
  final int minIso;
  final int isoCount;
  final int moves;
  final int timeMs;
  final int help;

  const LeaderboardEntry({
    required this.playerId,
    required this.pseudo,
    required this.minIso,
    required this.isoCount,
    required this.moves,
    required this.timeMs,
    required this.help,
  });

  /// Acuité en % (§4.2), pour l'affichage du maillot jaune.
  int get acuityPercent => ((minIso + 1) / (isoCount + 1) * 100).round();

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        playerId: j['player_id'] as String? ?? '',
        pseudo: j['pseudo'] as String? ?? '',
        minIso: (j['min_iso'] as num?)?.toInt() ?? 0,
        isoCount: (j['iso_count'] as num?)?.toInt() ?? 0,
        moves: (j['moves'] as num?)?.toInt() ?? 0,
        timeMs: (j['time_ms'] as num?)?.toInt() ?? 0,
        help: (j['help'] as num?)?.toInt() ?? 0,
      );
}

/// Client du service de classement. Toutes les méthodes **échouent en silence** (retour `false`/
/// liste vide) : une panne réseau ne casse jamais le jeu (§7.8).
class ChallengeApi {
  final String baseUrl;
  final http.Client _client;

  ChallengeApi({this.baseUrl = kChallengeBaseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// Envoie le score d'un défi terminé. `true` si accepté (201). Un `409` (déjà soumis) ou une
  /// panne renvoient `false` sans lever d'exception. `timeout` court pour ne pas figer le bilan.
  Future<bool> submitScore({
    required int version,
    required int week,
    required int size,
    required String playerId,
    required String pseudo,
    required int minIso,
    required int isoCount,
    required int moves,
    required int timeMs,
    required int help,
    required String grid,
  }) async {
    try {
      final resp = await _client
          .post(
            Uri.parse('$baseUrl/score'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'version': version,
              'week': week,
              'size': size,
              'playerId': playerId,
              'pseudo': pseudo,
              'minIso': minIso,
              'isoCount': isoCount,
              'moves': moves,
              'timeMs': timeMs,
              'help': help,
              'grid': grid,
            }),
          )
          .timeout(const Duration(seconds: 6));
      return resp.statusCode == 201;
    } catch (e) {
      debugPrint('❌ submitScore échoué: $e');
      return false;
    }
  }

  /// Le classement d'un défi pour un maillot. Liste vide en cas de panne.
  Future<List<LeaderboardEntry>> leaderboard({
    required int version,
    required int week,
    required int size,
    required Maillot maillot,
    int limit = 100,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/leaderboard').replace(queryParameters: {
        'version': '$version',
        'week': '$week',
        'size': '$size',
        'maillot': maillot.name,
        'limit': '$limit',
      });
      final resp = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return const [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final entries = (data['entries'] as List? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return entries;
    } catch (e) {
      debugPrint('❌ leaderboard échoué: $e');
      return const [];
    }
  }
}
