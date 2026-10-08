// Modified: 2026-10-07 06:53 — vérifier identité hors ligne/en ligne, verrouillage et rendu des indices.
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/challenge_clues.dart';
import 'package:pentapol/pentoscope/corpus_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_board.dart';
import 'package:pentapol/providers/settings_provider.dart';

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

class _Game extends PentoscopeNotifier {
  void load(PentoscopeState value) => state = value;
}

List<List<int>> _signature(List<PlacedPiece> pieces) => [
  for (final piece in pieces)
    [piece.piece.id, piece.positionIndex, piece.gridX, piece.gridY],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'neuf tailles, même défi avec ou sans réseau, indices intouchables et timer arrêté',
    () async {
      var networkRequests = 0;
      ProviderContainer create(bool online) => ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(_Settings.new),
          challengeApiProvider.overrideWithValue(
            ChallengeApi(
              client: MockClient((request) async {
                networkRequests++;
                if (!online) throw const SocketException('offline');
                return http.Response(
                  '{"mask":74,"rack":{},"solutionCount":4}',
                  200,
                );
              }),
            ),
          ),
        ],
      );
      final online = create(true);
      final offline = create(false);
      addTearDown(online.dispose);
      addTearDown(offline.dispose);
      for (final size in kChallengeSizes) {
        final aGame = online.read(pentoscopeProvider.notifier);
        final bGame = offline.read(pentoscopeProvider.notifier);
        final a = await aGame.dailyChallengeDefinition(
          size,
          date: DateTime.utc(2026, 10, 7),
        );
        final b = await bGame.dailyChallengeDefinition(
          size,
          date: DateTime.utc(2026, 10, 7),
        );
        expect(a.mask, b.mask);
        expect(a.orientations, b.orientations);
        expect(_signature(a.fixedPieces), _signature(b.fixedPieces));
        expect(a.solutionCount, 1);
        expect(a.playablePieceCount, greaterThanOrEqualTo(2));
        await aGame.startChallenge(a);
        final initial = online.read(pentoscopeProvider);
        expect(initial.solutionsCount, 1);
        expect(initial.strategyActions.total, 0);
        expect(initial.hintCount, 0);
        expect(initial.availablePieces.length, a.playablePieceCount);
        expect(initial.initialOrientations.length, a.playablePieceCount);
        expect(aGame.isTimerRunning, isFalse);
        for (final fixed in a.fixedPieces) {
          final cell = fixed.absoluteCells.first;
          aGame.selectPlacedPiece(fixed, cell.x, cell.y);
          aGame.selectPiece(fixed.piece);
          aGame.applyIsometryRotationCW();
          aGame.applyIsometrySymmetryH();
          aGame.removePlacedPiece(fixed);
        }
        final after = online.read(pentoscopeProvider);
        expect(after.selectedPiece, isNull);
        expect(_signature(after.placedPieces), _signature(a.fixedPieces));
        expect(after.strategyActions.total, 0);
        expect(aGame.isTimerRunning, isFalse);
      }
      expect(networkRequests, 0);
    },
  );

  for (final landscape in [false, true]) {
    testWidgets('cadenas et absence de sélection, paysage=$landscape', (
      tester,
    ) async {
      final corpus = TirageCorpus(
        File('assets/data/solutions_corpus.bin').readAsBytesSync(),
        ByteData.sublistView(
          File('assets/data/subset_counts.bin').readAsBytesSync(),
        ),
      );
      final clues = chooseChallengeClues(corpus.solutionsFor(74), 3, 5, 0);
      final board = Plateau.allVisible(3, 5);
      for (final clue in clues) {
        for (final cell in clue.absoluteCells) {
          board.setCell(cell.x, cell.y, clue.piece.id);
        }
      }
      final game = _Game();
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(_Settings.new),
          pentoscopeProvider.overrideWith(() => game),
        ],
      );
      addTearDown(container.dispose);
      container.read(pentoscopeProvider);
      game.load(
        PentoscopeState(
          puzzle: const PentoscopePuzzle(
            size: PentoscopeSize.size3x5,
            pieceIds: [2, 4, 7],
            solutionCount: 1,
          ),
          plateau: board,
          placedPieces: clues,
          fixedPieceIds: {for (final clue in clues) clue.piece.id},
          isRanked: true,
        ),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: landscape ? 500 : 300,
                  height: landscape ? 300 : 500,
                  child: PentoscopeBoard(isLandscape: landscape),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(clues.length));
      await tester.tap(find.byIcon(Icons.lock_outline).first);
      await tester.drag(
        find.byIcon(Icons.lock_outline).first,
        const Offset(60, 30),
      );
      await tester.pumpAndSettle();
      expect(container.read(pentoscopeProvider).selectedPiece, isNull);
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
