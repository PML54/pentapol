// Modified: 2026-09-05 00:35 — fetchChallenge (GET /challenge) : récupère la définition composée à
//           la main (§7 Acté 1), null si non composée → l'appelant dérive localement.
// lib/pentoscope/challenge_api.dart
// Historique: 2026-09-05 00:00 — création : client HTTP du classement du défi (CDC §7, Phase 4/5).
//           POST du score à la fin d'un défi, GET des classements. Échecs silencieux (§7.8 : le jeu
//           reste entier sans réseau — jamais de bouton mort).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

/// URL du worker de classement (déployé par Paul). Distinct du worker duel (WebSocket).
const String kChallengeBaseUrl = 'https://pentapol-defi.pentapml.workers.dev';

/// Les trois maillots, tels que l'API les nomme (paramètre `maillot`).
enum Maillot { jaune, pois, vert }

/// Une ligne de classement renvoyée par `GET /leaderboard`.
class LeaderboardEntry {
  final String playerId;
  final String pseudo;
  final int minIso;
  final int isoCount;
  final int faults;
  final int timeMs;

  const LeaderboardEntry({
    required this.playerId,
    required this.pseudo,
    required this.minIso,
    required this.isoCount,
    required this.faults,
    required this.timeMs,
  });

  /// Acuité en % (§4.2), plafonnée à 100, pour l'affichage du maillot jaune.
  int get acuityPercent {
    final r = (minIso + 1) / (isoCount + 1);
    return ((r > 1.0 ? 1.0 : r) * 100).round();
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        playerId: j['player_id'] as String? ?? '',
        pseudo: j['pseudo'] as String? ?? '',
        minIso: (j['min_iso'] as num?)?.toInt() ?? 0,
        isoCount: (j['iso_count'] as num?)?.toInt() ?? 0,
        faults: (j['faults'] as num?)?.toInt() ?? 0,
        timeMs: (j['time_ms'] as num?)?.toInt() ?? 0,
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
    required int faults,
    required int timeMs,
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
              'faults': faults,
              'timeMs': timeMs,
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

  /// La définition **composée à la main** d'un défi (§7 Acté 1), ou `null` si le serveur n'en a
  /// pas (404) ou est injoignable → l'appelant retombe sur la dérivation locale. Reconstruit un
  /// `ChallengeDefinition` depuis `{mask, rack}`.
  Future<ChallengeDefinition?> fetchChallenge({
    required int version,
    required int week,
    required PentoscopeSize size,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/challenge').replace(queryParameters: {
        'version': '$version',
        'week': '$week',
        'size': '${size.index}',
      });
      final resp = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null; // 404 = non composé → dériver localement
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final mask = (data['mask'] as num).toInt();
      final rack = (data['rack'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      final pieceIds = <int>[
        for (int id = 1; id <= 12; id++)
          if (mask & (1 << (id - 1)) != 0) id,
      ];
      return ChallengeDefinition(
          week: week, size: size, mask: mask, pieceIds: pieceIds, orientations: rack);
    } catch (e) {
      debugPrint('❌ fetchChallenge échoué: $e');
      return null;
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
