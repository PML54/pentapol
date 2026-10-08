// Modified: 2026-10-07 06:53 — contrôler l'unicité et la minimalité des indices sur tout le corpus et le 6×10.
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/pentoscope/challenge_clues.dart';
import 'package:pentapol/pentoscope/corpus_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_solutions_provider.dart';
import 'package:pentapol/pentoscope/solution_source.dart';

Plateau boardOf(int width, int height, List<PlacedPiece> pieces) {
  final board = Plateau.allVisible(width, height);
  for (final piece in pieces) {
    for (final cell in piece.absoluteCells) {
      expect(board.getCell(cell.x, cell.y), 0);
      board.setCell(cell.x, cell.y, piece.piece.id);
    }
  }
  return board;
}

List<List<int>> signature(List<PlacedPiece> pieces) => [
  for (final piece in pieces)
    [piece.piece.id, piece.positionIndex, piece.gridX, piece.gridY],
];

void checkClues(
  SolutionSource source,
  int width,
  int height,
  List<PlacedPiece> clues,
) {
  final n = width * height ~/ 5;
  expect(clues.length, inInclusiveRange(1, n ~/ 2));
  final board = boardOf(width, height, clues);
  expect(source.countFrom(board), 1);
  for (final clue in clues) {
    final less = clues
        .where((piece) => piece.piece.id != clue.piece.id)
        .toList();
    expect(source.countFrom(boardOf(width, height, less)), greaterThan(1));
  }
  final target = source.hintFrom(board, const [])!;
  for (var subset = 0; subset < (1 << target.length); subset++) {
    final smaller = <PlacedPiece>[
      for (var index = 0; index < target.length; index++)
        if ((subset & (1 << index)) != 0) target[index],
    ];
    if (smaller.length >= clues.length) continue;
    expect(source.countFrom(boardOf(width, height, smaller)), greaterThan(1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    '996 tirages : une solution exacte, indices nécessaires, au moins la moitié à jouer',
    () {
      final corpus = TirageCorpus(
        File('assets/data/solutions_corpus.bin').readAsBytesSync(),
        ByteData.sublistView(
          File('assets/data/subset_counts.bin').readAsBytesSync(),
        ),
      );
      var checked = 0;
      final maxima = <int, int>{};
      for (var mask = 0; mask < 4096; mask++) {
        final n = mask.toRadixString(2).replaceAll('0', '').length;
        if (n < 3 || n > 10 || corpus.countOf(mask) == 0) continue;
        final width = n < 5 ? n : 5;
        final height = n < 5 ? 5 : n;
        final bytes = corpus.solutionsFor(mask);
        final source = CorpusSolutionSource(
          bytes,
          width: width,
          height: height,
        );
        final clues = chooseChallengeClues(bytes, width, height, mask);
        checkClues(source, width, height, clues);
        expect(
          signature(chooseChallengeClues(bytes, width, height, mask)),
          signature(clues),
        );
        maxima[n] = (maxima[n] ?? 0) > clues.length ? maxima[n]! : clues.length;
        checked++;
      }
      expect(checked, 996);
      // ignore: avoid_print
      print('Maximum de pièces fixes par taille : $maxima');
    },
  );

  test('6×10 : préparation hors UI, 9356 solutions, indices minimaux', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final matcher = await container.read(
      pentoscopeSolutionsProvider(SolutionTable.r6x10).future,
    );
    expect(matcher.totalSolutions, 9356);
    final source = TableSolutionSource(matcher, SolutionTable.r6x10);
    for (final seed in [0, 1234567, 20261007]) {
      final watch = Stopwatch()..start();
      final clues = await source.uniqueChallengeClues(seed);
      checkClues(source, 6, 10, clues);
      expect(
        signature(await source.uniqueChallengeClues(seed)),
        signature(clues),
      );
      // ignore: avoid_print
      print(
        '6×10 seed=$seed : ${clues.length} pièces fixes en ${watch.elapsedMilliseconds}ms',
      );
    }
  });

  test('un corpus vide ou dupliqué est refusé explicitement', () {
    expect(() => chooseChallengeClues(Uint8List(0), 3, 5, 0), throwsStateError);
    final duplicate = Uint8List.fromList(List.filled(30, 7));
    expect(() => chooseChallengeClues(duplicate, 3, 5, 0), throwsStateError);
  });
}
