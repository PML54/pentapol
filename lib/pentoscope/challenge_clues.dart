// Modified: 2026-10-07 06:53 — isoler une solution exacte avec un ensemble minimal de pièces fixes.
// lib/pentoscope/challenge_clues.dart
import 'dart:typed_data';
import 'package:pentapol/common/byte_matching.dart';
import 'package:pentapol/common/pentapol_rng.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';

/// Filters stored pavings, never solves a board. At least half the pieces remain playable.
List<PlacedPiece> chooseChallengeClues(
  Uint8List boards,
  int width,
  int height,
  int seed,
) {
  final cells = width * height;
  if (cells <= 0 || boards.isEmpty || boards.length % cells != 0) {
    throw StateError('Invalid challenge corpus');
  }
  final count = boards.length ~/ cells;
  final bits = {
    for (final piece in pentominos) piece.bit6: 1 << (piece.id - 1),
  };
  final first = PentapolRng(seed).nextInt(count);
  for (var attempt = 0; attempt < count; attempt++) {
    final index = (first + attempt) % count;
    final base = index * cells;
    final target = Uint8List.sublistView(boards, base, base + cells);
    final pieces = flatBoardToPlacedPieces(target, 0, width, height);
    final mask = pieces.fold(
      0,
      (mask, piece) => mask | (1 << (piece.piece.id - 1)),
    );
    final differences = <int>{};
    for (var other = 0; other < count; other++) {
      if (other == index) continue;
      var difference = 0;
      for (var cell = 0; cell < cells; cell++) {
        if (target[cell] != boards[other * cells + cell]) {
          difference |= bits[target[cell]]!;
        }
      }
      if (difference == 0) throw StateError('Duplicate challenge solution');
      differences.add(difference);
    }
    // A clue set must intersect every alternative's changed-piece mask.
    final subsets = <int>[];
    for (var subset = mask; subset > 0; subset = (subset - 1) & mask) {
      if (_popcount(subset) <= pieces.length ~/ 2) subsets.add(subset);
    }
    subsets.sort((a, b) {
      final byCount = _popcount(a).compareTo(_popcount(b));
      return byCount != 0 ? byCount : a.compareTo(b);
    });
    if (count == 1) return const [];
    for (final subset in subsets) {
      if (differences.every((difference) => (difference & subset) != 0)) {
        return pieces
            .where((piece) => (subset & (1 << (piece.piece.id - 1))) != 0)
            .toList();
      }
    }
  }
  throw StateError('No unique challenge with enough playable pieces');
}

int _popcount(int value) {
  var count = 0;
  while (value != 0) {
    value &= value - 1;
    count++;
  }
  return count;
}

List<PlacedPiece> corpusChallengeClues((Uint8List, int, int, int) input) {
  final (boards, width, height, seed) = input;
  return chooseChallengeClues(boards, width, height, seed);
}

List<PlacedPiece> tableChallengeClues((List<BigInt>, int, int, int) input) {
  final (boards, width, height, seed) = input;
  final cells = width * height;
  final bytes = Uint8List(boards.length * cells);
  final mask = BigInt.from(63);
  for (var index = 0; index < boards.length; index++) {
    var value = boards[index];
    for (var cell = cells - 1; cell >= 0; cell--) {
      bytes[index * cells + cell] = (value & mask).toInt();
      value >>= 6;
    }
  }
  return chooseChallengeClues(bytes, width, height, seed);
}
