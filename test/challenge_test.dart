// Modified: 2026-09-04 06:25 — création : test de gel de la dérivation du défi (CDC §7.3, piège 5).
//           Seul garde-fou contre une modification involontaire des défis (dérivation ou .bin).
// test/challenge_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

int _popcount(int x) {
  var c = 0;
  while (x != 0) {
    c += x & 1;
    x >>= 1;
  }
  return c;
}

/// Hash stable (FNV-1a) — `String.hashCode` n'est PAS stable entre runs en Dart.
int _fnv(String s) {
  var h = 0x811c9dc5;
  for (final u in s.codeUnits) {
    h = (h ^ u) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// Masques solubles par popcount, lus depuis l'asset (comme `_ensureTable`, hors rootBundle).
Map<int, List<int>> _loadSolubleByPop() {
  final bytes = File('assets/data/subset_counts.bin').readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final byPop = <int, List<int>>{};
  for (int m = 0; m < 4096; m++) {
    if (data.getUint16(m * 2, Endian.little) > 0) {
      byPop.putIfAbsent(_popcount(m), () => <int>[]).add(m);
    }
  }
  return byPop;
}

String _digestString(Map<int, List<int>> byPop) {
  final sb = StringBuffer();
  for (final size in kChallengeSizes) {
    final masks = byPop[size.numPieces]!;
    for (int w = 0; w < 10; w++) {
      final ch = deriveChallenge(week: w, size: size, solubleMasks: masks);
      final ori = ch.pieceIds.map((id) => '$id:${ch.orientations[id]}').join(',');
      sb.write('${size.name}|$w|${ch.mask}|$ori;');
    }
  }
  return sb.toString();
}

void main() {
  late Map<int, List<int>> byPop;
  setUpAll(() => byPop = _loadSolubleByPop());

  group('Défi — dérivation FIGÉE (ne pas modifier sans intention, §7.3 piège 5)', () {
    // Un échec ici = TOUS les défis changent. C'est un signal, pas un test à « réparer » en
    // recopiant la nouvelle valeur. Si la dérivation change volontairement, incrémenter
    // kChallengeVersion, puis mettre ce golden à jour.
    test('digest des 60 premiers défis (6 tailles × semaines 0..9)', () {
      expect(_fnv(_digestString(byPop)), 4015859194);
    });

    test('spot-check semaine 0, 3×5', () {
      final ch = deriveChallenge(
          week: 0, size: PentoscopeSize.size3x5, solubleMasks: byPop[3]!);
      expect(ch.mask, 416); // pièces 6, 8, 9
      expect(ch.pieceIds, [6, 8, 9]);
      expect(ch.orientations, {6: 0, 8: 5, 9: 2});
    });
  });

  group('Défi — invariants de dérivation', () {
    test('même (semaine, taille) ⟹ défi identique', () {
      final a = deriveChallenge(
          week: 3, size: PentoscopeSize.size5x5, solubleMasks: byPop[5]!);
      final b = deriveChallenge(
          week: 3, size: PentoscopeSize.size5x5, solubleMasks: byPop[5]!);
      expect(a.mask, b.mask);
      expect(a.orientations, b.orientations);
    });

    test('masque soluble, pièces cohérentes, orientations valides', () {
      for (final size in kChallengeSizes) {
        final masks = byPop[size.numPieces]!;
        for (int w = 0; w < 20; w++) {
          final ch = deriveChallenge(week: w, size: size, solubleMasks: masks);
          expect(masks.contains(ch.mask), isTrue); // masque tiré parmi les solubles
          expect(_popcount(ch.mask), size.numPieces); // bon nombre de pièces
          expect(ch.pieceIds.length, size.numPieces);
          expect(ch.orientations.keys.toSet(), ch.pieceIds.toSet());
          for (final id in ch.pieceIds) {
            final o = ch.orientations[id]!;
            expect(o, inInclusiveRange(0, pentominos[id - 1].numOrientations - 1));
          }
        }
      }
    });

    test('pieceIds triés par id croissant (ordre figé)', () {
      final ch = deriveChallenge(
          week: 7, size: PentoscopeSize.size8x5, solubleMasks: byPop[8]!);
      final sorted = [...ch.pieceIds]..sort();
      expect(ch.pieceIds, sorted);
    });
  });

  group('Défi — semaines et seed', () {
    test('weeksSinceEpoch : origine = 0, +7j = 1, avant = 0', () {
      expect(weeksSinceEpoch(kChallengeEpoch), 0);
      expect(weeksSinceEpoch(kChallengeEpoch.add(const Duration(days: 7))), 1);
      expect(weeksSinceEpoch(kChallengeEpoch.add(const Duration(days: 13))), 1);
      expect(weeksSinceEpoch(kChallengeEpoch.add(const Duration(days: 14))), 2);
      expect(weeksSinceEpoch(kChallengeEpoch.subtract(const Duration(days: 5))), 0);
    });

    test('challengeSeed déterministe et sensible à chaque argument', () {
      expect(challengeSeed(1, 5, 2), challengeSeed(1, 5, 2));
      expect(challengeSeed(1, 5, 2) == challengeSeed(2, 5, 2), isFalse);
      expect(challengeSeed(1, 5, 2) == challengeSeed(1, 6, 2), isFalse);
      expect(challengeSeed(1, 5, 2) == challengeSeed(1, 5, 3), isFalse);
    });
  });
}
