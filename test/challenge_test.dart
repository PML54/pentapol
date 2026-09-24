import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

int _popcount(int value) {
  var count = 0;
  while (value != 0) {
    count += value & 1;
    value >>= 1;
  }
  return count;
}

({Map<int, List<int>> masks, Map<int, int> counts}) _loadTable() {
  final bytes = File('assets/data/subset_counts.bin').readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final masks = <int, List<int>>{};
  final counts = <int, int>{};
  for (int mask = 0; mask < 4096; mask++) {
    final count = data.getUint16(mask * 2, Endian.little);
    counts[mask] = count;
    if (count > 0) {
      masks.putIfAbsent(_popcount(mask), () => []).add(mask);
    }
  }
  return (masks: masks, counts: counts);
}

void main() {
  late ({Map<int, List<int>> masks, Map<int, int> counts}) table;
  setUpAll(() => table = _loadTable());

  ChallengeDefinition derive(DateTime date, PentoscopeSize size) =>
      deriveChallenge(
        date: date,
        size: size,
        solubleMasks: size == PentoscopeSize.size6x10
            ? const []
            : table.masks[size.numPieces]!,
        solutionCountForMask: (mask) => table.counts[mask]!,
      );

  test('la date UTC est stable', () {
    expect(challengeDay(DateTime.parse('2026-09-24T23:59:00Z')), '2026-09-24');
    expect(daysSinceEpoch(kChallengeEpoch), 0);
    expect(daysSinceEpoch(kChallengeEpoch.add(const Duration(days: 3))), 3);
  });

  test('meme date et taille donnent le meme defi', () {
    final date = DateTime.utc(2026, 9, 24);
    final a = derive(date, PentoscopeSize.size5x5);
    final b = derive(date, PentoscopeSize.size5x5);
    expect(a.mask, b.mask);
    expect(a.orientations, b.orientations);
    expect(a.solutionCount, greaterThan(0));
  });

  test('les neuf tailles sont proposees dans l ordre', () {
    expect(kChallengeSizes, PentoscopeSize.values);
    expect(kChallengeSizes.first, PentoscopeSize.size3x5);
    expect(kChallengeSizes.last, PentoscopeSize.size6x10);
  });

  test('masques et orientations restent valides', () {
    for (final size in kChallengeSizes) {
      final challenge = derive(DateTime.utc(2026, 9, 24), size);
      expect(_popcount(challenge.mask), size.numPieces);
      expect(challenge.pieceIds.length, size.numPieces);
      for (final id in challenge.pieceIds) {
        expect(
          challenge.orientations[id],
          inInclusiveRange(0, pentominos[id - 1].numOrientations - 1),
        );
      }
    }
  });

  test('le 6x10 utilise toutes les pieces et son compte connu', () {
    final challenge = derive(
      DateTime.utc(2026, 9, 24),
      PentoscopeSize.size6x10,
    );
    expect(challenge.mask, 0xFFF);
    expect(challenge.solutionCount, 9356);
  });
}
