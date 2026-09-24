import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/screens/leaderboard_screen.dart';

LeaderboardEntry entry(String id, String pseudo) => LeaderboardEntry(
  playerId: id,
  pseudo: pseudo,
  minIso: 0,
  isoCount: 0,
  faults: 0,
  timeMs: 0,
  moves: 0,
);

void main() {
  test('un nom unique reste intact', () {
    final paul = entry('0000000000000000000000000000a7f2', 'Paul');
    expect(leaderboardDisplayName(paul, [paul], 'Joueur'), 'Paul');
  });

  test('les homonymes recoivent un suffixe stable', () {
    final first = entry('0000000000000000000000000000a7f2', 'Paul');
    final second = entry('000000000000000000000000000019c4', ' paul ');
    final entries = [first, second];
    expect(leaderboardDisplayName(first, entries, 'Joueur'), 'Paul · A7F2');
    expect(leaderboardDisplayName(second, entries, 'Joueur'), 'paul · 19C4');
  });
}
