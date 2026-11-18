// Modified: 2026-11-17 09:57 — vérifier transport et compatibilité des ceintures publiques.
// test/leaderboard_belt_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';

void main() {
  test('grade absent ou invalide reste inconnu, grade zéro reste blanc', () {
    for (final value in [null, -1, 7, 1.5, '2']) {
      expect(LeaderboardEntry.fromJson({'belt': value}).belt, isNull);
    }
    for (var belt = 0; belt <= 6; belt++) {
      expect(LeaderboardEntry.fromJson({'belt': belt}).belt, belt);
    }
  });
  test(
    'score en attente et POST conservent la ceinture sans altérer le temps',
    () async {
      final score = PendingChallengeScore.fromJson({
        'belt': 4,
        'timeMs': 12345,
      });
      final restored = PendingChallengeScore.fromJson(score.toJson());
      expect(restored.belt, 4);
      expect(PendingChallengeScore.fromJson({}).belt, isNull);
      Map<String, dynamic>? sent;
      final api = ChallengeApi(
        client: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 201);
        }),
      );
      await api.submitScore(
        version: 3,
        day: '2026-11-17',
        size: 3,
        playerId: 'a' * 32,
        pseudo: 'Paul',
        belt: restored.belt,
        minIso: 0,
        isoCount: 0,
        faults: 0,
        timeMs: restored.timeMs,
        moves: 3,
        grid: '123',
      );
      expect(sent!['belt'], 4);
      expect(sent!['timeMs'], 12345);
    },
  );
}
