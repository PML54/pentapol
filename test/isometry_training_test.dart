// Modified: 2026-10-31 06:45 — vérifier étoiles, acuité et expiration à trois minutes.
// Historique: 2026-10-09 09:41 — vérifier que le chrono attend l'aperçu initial.
// Historique: 2026-10-09 09:27 — vérifier le bouton nouveau jeu et le chrono dans le Training complet.
// Historique: 2026-10-09 09:15 — vérifier les huit pièces dès le départ et à la relance.
// Historique: 2026-10-09 09:11 — vérifier les couleurs pastel et l'ordre libre.
// Historique: 2026-10-09 09:05 — vérifier toute la solution avant sélection.
// Historique: 2026-10-09 09:00 — vérifier le Training 8x5 et ses quatre niveaux.
// Historique: 2026-10-09 07:33 — tester refus, aimantation et absence de persistance.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';

class _Game extends PentoscopeNotifier {
  bool recordNextStage = false;
  int? requestedStage;
  @override
  Future<void> startIsometryTraining() {
    if (recordNextStage) {
      requestedStage = 8;
      return Future.value();
    }
    return super.startIsometryTraining();
  }

  void orient(int index) {
    state = state.copyWith(selectedPositionIndex: index);
    cancelSelection();
  }
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  for (final portrait in [false, true]) {
    const k = 8;
    testWidgets('isométries huit pièces, portrait=$portrait, base intacte', (
      tester,
    ) async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final game = _Game();
      final container = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith(_Settings.new),
          pentoscopeProvider.overrideWith(() => game),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await tester.runAsync(db.close);
      });
      container.read(pentoscopeProvider);
      Future<List<String>> snapshot() async => [
        for (final table in db.allTables)
          '${table.actualTableName}:${(await db.customSelect('SELECT * FROM ${table.actualTableName}').get()).map((r) => r.data).toList()}',
      ];
      final before = await tester.runAsync(snapshot);
      await tester.runAsync(game.startIsometryTraining);
      PentoscopeState current() => container.read(pentoscopeProvider);
      expect(current().availablePieces.length, k);
      expect(current().puzzle!.size, PentoscopeSize.size8x5);
      expect(current().plateau.width * current().plateau.height, 40);
      expect(current().placedPieces.length, 8 - k);
      expect(current().fixedPieceIds.length, 8 - k);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = portrait
          ? const Size(390, 844)
          : const Size(874, 402);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: Locale(portrait ? 'fr' : 'en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PentoscopeGameScreen(mode: PentoscopeMode.training),
          ),
        ),
      );
      await tester.pump();
      expect(current().selectedPiece, isNull);
      final newGame = find.byKey(const ValueKey('training-new-game'));
      expect(newGame, findsOneWidget);
      expect(find.text('180 s'), findsOneWidget);
      expect(tester.getSize(newGame).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(newGame).height, greaterThanOrEqualTo(48));
      await tester.pump();
      for (var frame = 0; frame < 13; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (frame < 7) expect(find.text('180 s'), findsOneWidget);
      }
      await tester.pump();
      expect(
        container.read(rackPreviewCompletedProvider),
        same(current().puzzle),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.text('178 s'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(', '),
      );
      tester.view.physicalSize = portrait
          ? const Size(874, 402)
          : const Size(390, 844);
      await tester.pump();
      expect(find.text('178 s'), findsOneWidget);
      tester.view.physicalSize = portrait
          ? const Size(390, 844)
          : const Size(874, 402);
      await tester.pump();
      expect(find.text('178 s'), findsOneWidget);
      for (final target in current().trainingTargets) {
        for (final cell in target.absoluteCells) {
          final ghost = find.byKey(
            ValueKey('isometry-target-${cell.x}-${cell.y}'),
          );
          expect(ghost, findsOneWidget);
          final decoration =
              tester.widget<Container>(ghost).decoration as BoxDecoration;
          expect(
            decoration.color,
            Color.alphaBlend(
              container
                  .read(settingsProvider)
                  .ui
                  .getPieceColor(target.piece.id)
                  .withValues(alpha: 0.35),
              Colors.white,
            ),
          );
          expect(
            tester
                .widgetList<Text>(
                  find.descendant(of: ghost, matching: find.byType(Text)),
                )
                .every((text) => text.data == ''),
            isTrue,
          );
        }
      }
      for (final target in current().trainingTargets) {
        expect(
          current().initialOrientations[target.piece.id],
          isNot(target.positionIndex),
        );
      }
      for (final fixed in current().placedPieces) {
        game.removePlacedPiece(fixed);
        game.selectPlacedPiece(fixed, fixed.gridX, fixed.gridY);
        expect(current().selectedPiece, isNull);
      }
      final wrong = current().availablePieces.last;
      game.selectPiece(wrong);
      expect(current().trainingWrongSelections, 0);
      game.selectPiece(wrong);
      expect(current().trainingWrongSelections, 0);
      final target = current().trainingTarget!;
      game.selectPiece(target.piece);
      final board = current().plateau;
      expect(game.tryPlaceAtAnchor(target.gridX, target.gridY), isFalse);
      expect(current().plateau, same(board));
      game.recordRejectedDrop();
      game.cancelSelection();
      expect(current().trainingRejectedDrops, 1);
      while (current().trainingTarget != null) {
        final next = current().trainingTargetFor(
          current().availablePieces.last.id,
        )!;
        game.selectPiece(next.piece);
        game.orient(next.positionIndex);
        game.selectPiece(next.piece);
        expect(current().validPlacements, [Point(next.gridX, next.gridY)]);
        expect(game.tryPlaceAtAnchor(next.gridX + 1, next.gridY), isFalse);
        final grab = current().selectedCellInPiece!;
        final raw = next.piece.orientations[next.positionIndex];
        final minX = raw
            .map((n) => (n - 1) % 5)
            .reduce((a, b) => a < b ? a : b);
        final minY = raw
            .map((n) => (n - 1) ~/ 5)
            .reduce((a, b) => a < b ? a : b);
        game.updatePreview(
          next.gridX + grab.x - minX + 1,
          next.gridY + grab.y - minY,
        );
        expect(current().isPreviewValid, isTrue);
        expect(current().previewX, next.gridX);
        expect(current().previewY, next.gridY);
        expect(
          game.tryPlaceAtAnchor(current().previewX!, current().previewY!),
          isTrue,
        );
      }
      expect(current().isComplete, isTrue);
      await tester.pump();
      expect(
        find.textContaining(portrait ? 'Acuité :' : 'Acuity:'),
        findsWidgets,
      );
      expect(
        find.textContaining(portrait ? 'dépôts refusés' : 'rejected drops'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.runAsync(game.saveCurrentGameSnapshot);
      expect(await tester.runAsync(snapshot), before);
      game.recordNextStage = true;
      await tester.tap(find.byKey(const ValueKey('training-continue')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(game.requestedStage, 8);
      await tester.pump();
      game.requestedStage = null;
      await tester.tap(newGame);
      await tester.pump(const Duration(milliseconds: 1));
      expect(game.requestedStage, 8);
      expect(await tester.runAsync(snapshot), before);
      game.recordNextStage = false;
      await tester.runAsync(game.startIsometryTraining);
      await tester.pump();
      final minimum = current().trainingMinIso;
      expect(current().copyWith(isometryCount: 0).trainingAcuity, 10);
      expect(current().copyWith(isometryCount: minimum).trainingAcuity, 10);
      expect(
        current().copyWith(isometryCount: minimum + 3).trainingAcuity,
        10 * minimum ~/ (minimum + 3),
      );
      game.selectPiece(current().availablePieces.first);
      game.finishRackPreview(current().puzzle!);
      await tester.pump();
      await tester.pump(const Duration(seconds: 180));
      await tester.pump();
      expect(current().trainingTimeExpired, isTrue);
      final frozen = current().plateau;
      game.selectPiece(current().availablePieces.first);
      expect(current().selectedPiece, isNull);
      expect(game.tryPlaceAtAnchor(0, 0), isFalse);
      expect(current().plateau, same(frozen));
      expect(current().isComplete, isFalse);
      await tester.runAsync(game.startIsometryTraining);
      expect(current().trainingTimeExpired, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
