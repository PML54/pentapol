// Modified: 2026-10-07 01:46 — vérifier le prochain changement de défis (minuit UTC) et son
//           affichage en heure locale sur l'écran Défis.
// test/next_challenge_change_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/pentoscope/challenge.dart';

void main() {
  group('nextChallengeChange', () {
    test('renvoie le prochain minuit UTC', () {
      // 01:44 à Paris (CEST) : encore mardi en UTC, changement à 00:00 UTC mercredi.
      expect(
        nextChallengeChange(DateTime.utc(2026, 10, 6, 23, 44)),
        DateTime.utc(2026, 10, 7),
      );
    });

    test('à minuit pile, le changement suivant est le lendemain', () {
      expect(
        nextChallengeChange(DateTime.utc(2026, 10, 7)),
        DateTime.utc(2026, 10, 8),
      );
    });

    test('franchit la fin de mois et la fin d’année', () {
      expect(
        nextChallengeChange(DateTime.utc(2026, 10, 31, 12)),
        DateTime.utc(2026, 11, 1),
      );
      expect(
        nextChallengeChange(DateTime.utc(2026, 12, 31, 23, 59)),
        DateTime.utc(2027, 1, 1),
      );
    });

    test('ne dépend pas du fuseau de l’instant fourni', () {
      final local = DateTime(2026, 10, 7, 1, 44);
      expect(nextChallengeChange(local), nextChallengeChange(local.toUtc()));
    });

    test('coïncide avec le changement de challengeDay', () {
      final now = DateTime.utc(2026, 10, 6, 23, 44);
      final next = nextChallengeChange(now);
      final justBefore = next.subtract(const Duration(microseconds: 1));
      expect(challengeDay(justBefore), challengeDay(now));
      expect(challengeDay(next), isNot(challengeDay(now)));
    });
  });
}
