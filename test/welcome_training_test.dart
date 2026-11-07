// Modified: 2026-11-05 10:21 — vérifier la bande de balayage et la consigne du premier exercice.
// Historique: 2026-10-30 17:18 — vérifier la consigne « avec les icônes ».
// Historique: 2026-10-30 17:20 — vérifier la miniature orientée et la consigne Positionne FR/EN.
// Historique: 2026-10-30 17:12 — vérifier la miniature de sélection et la lisibilité des consignes FR/EN.
// Historique: 2026-10-29 07:42 — vérifier l’équirépartition des onze cibles et tous les pavages compatibles.
// Historique: 2026-10-29 07:35 — vérifier la consigne française « Balaie le tiroir ».
// Historique: 2026-10-29 07:26 — vérifier le retour tactile de réussite et sa désactivation sans modifier les gestes.
// Historique: 2026-10-28 08:05 — vérifier la découverte 5×5 et les cibles de son corpus.
// Historique: 2026-10-28 06:56 — vérifier le mélange et les six positions autorisées de la cible.
// Historique: 2026-10-28 06:52 — vérifier la nouvelle consigne d’orientation sur deux lignes.
// Historique: 2026-10-28 06:49 — vérifier les douze pièces et le message de réussite raccourci.
// Historique: 2026-10-28 06:35 — vérifier les quatre isométries et l’ordre des deux consignes.
// Historique: 2026-10-28 05:27 — vérifier deux exercices manuels successifs, sans relance automatique.
// Historique: 2026-10-28 05:01 — tester les vrais gestes de découverte et les consignes sur petit iPhone.
// test/welcome_training_test.dart
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/home/discovery_screen.dart';
import 'package:pentapol/pentoscope/home/discovery_boards_data.dart';
import 'package:pentapol/pentoscope/home/guided_home.dart'
    show shapeKey, orientationCells;
import 'package:pentapol/common/pentominos.dart';

void main() {
  setUpAll(() async {
    final configFile = File('.dart_tool/package_config.json');
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final flutter = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['name'] == 'flutter');
    final root = configFile.absolute.uri.resolve('${flutter['rootUri']}/');
    final font = File.fromUri(
      root.resolve(
        '../../bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      ),
    );
    final loader = FontLoader('DiscoveryTestRoboto')
      ..addFont(font.readAsBytes().then((bytes) => bytes.buffer.asByteData()));
    await loader.load();
  });
  test('pavage légal : un trou, douze pièces, une rotation simple', () {
    final seenBoards = <String>{};
    for (
      var exercise = 0;
      exercise < kDiscoveryBoards5x5.length * 11;
      exercise++
    ) {
      final puzzle = DiscoveryPuzzle(exerciseIndex: exercise);
      seenBoards.add(puzzle.solution.name);
      final fixed = puzzle.solution.pieces
          .where((p) => p.id != puzzle.piece.id)
          .expand((p) => p.cells)
          .map((c) => '${c[0]},${c[1]}')
          .toSet();
      final target = puzzle.target.cells.map((c) => '${c[0]},${c[1]}').toSet();
      expect(puzzle.solution.pieces, hasLength(5));
      for (final placed in puzzle.solution.pieces) {
        final piece = pentominos.firstWhere((p) => p.id == placed.id);
        final shape = shapeKey(placed.cells.map((c) => math.Point(c[0], c[1])));
        expect(
          List.generate(
            piece.numOrientations,
            (i) => shapeKey(orientationCells(piece, i)),
          ),
          contains(shape),
        );
        expect(
          placed.cells.every(
            (c) => c[0] >= 0 && c[0] < 5 && c[1] >= 0 && c[1] < 5,
          ),
          isTrue,
        );
      }
      expect(fixed.length, 20);
      expect(target.length, 5);
      expect(fixed.intersection(target), isEmpty);
      expect(fixed.union(target).length, 25);
      expect(puzzle.rack.map((p) => p.id).toSet().length, 12);
      expect(puzzle.rack.where((p) => p.id == puzzle.piece.id).length, 1);
      expect(
        puzzle.accepts(
          pieceId: puzzle.piece.id,
          position: puzzle.initialOrientation,
        ),
        isFalse,
      );
      expect(
        puzzle.accepts(pieceId: puzzle.rack.first.id, position: 0),
        isFalse,
      );
      expect(
        puzzle.accepts(
          pieceId: puzzle.piece.id,
          position: puzzle.piece.rotationCW(puzzle.initialOrientation),
        ),
        isTrue,
      );
    }
    expect(seenBoards.length, kDiscoveryBoards5x5.length);
  });

  test('tiroir mélangé : douze pièces uniques, cible en positions 7 à 12', () {
    final positions = <int>{};
    final orders = <String>{};
    for (var seed = 0; seed < 200; seed++) {
      final puzzle = DiscoveryPuzzle(random: math.Random(seed));
      final ids = puzzle.rack.map((p) => p.id).toList();
      expect(ids.toSet(), {for (var id = 1; id <= 12; id++) id});
      final index = ids.indexOf(puzzle.piece.id);
      expect(index, inInclusiveRange(6, 11));
      positions.add(index);
      orders.add(ids.join(','));
      // Le mélange reste stable pendant l'exercice.
      expect(identical(puzzle.rack, puzzle.rack), isTrue);
    }
    expect(positions, {6, 7, 8, 9, 10, 11});
    expect(orders.length, greaterThan(1));
  });

  test(
    'chaque série de onze exercices propose toutes les pièces orientables une fois',
    () {
      final eligible = pentominos
          .where((p) => p.numOrientations > 1)
          .map((p) => p.id)
          .toSet();
      expect(eligible, {for (var id = 2; id <= 12; id++) id});
      for (var start = 0; start < 220; start++) {
        final ids = List.generate(
          11,
          (i) => DiscoveryPuzzle(exerciseIndex: start + i).piece.id,
        );
        expect(ids.toSet(), eligible);
        expect(ids.where((id) => id == 2), hasLength(1));
      }
    },
  );

  for (final lang in ['fr', 'en']) {
    for (final size in [const Size(320, 568), const Size(874, 402)]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('découverte complète $lang $size texte=$scale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final reduced =
              lang == 'en' && size.width > size.height && scale == 1.3;
          final hapticsEnabled = scale == 1.0;
          final impacts = <String>[];
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                impacts.add(call.arguments as String);
              }
              return null;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(SystemChannels.platform, null),
          );
          var played = 0;
          var skipped = 0;
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              theme: ThemeData(fontFamily: 'DiscoveryTestRoboto'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: reduced,
                ),
                child: child!,
              ),
              home: DiscoveryScreen(
                enableHaptics: hapticsEnabled,
                colorOf: (id) => Colors.primaries[id % Colors.primaries.length],
                onSkip: () async {
                  skipped++;
                },
                onPlay: () async {
                  played++;
                },
              ),
            ),
          );
          for (var round = 0; round < 2; round++) {
            final puzzle = DiscoveryPuzzle(exerciseIndex: round);
            final message = find.byKey(const ValueKey('discovery-message'));
            String instruction() {
              final text = tester.widget<Text>(message);
              return text.data ?? text.textSpan!.toPlainText();
            }

            void readable() {
              final text = tester.widget<Text>(message);
              expect(text.maxLines, 2);
              expect(
                text.style!.fontSize,
                instruction() == (lang == 'fr' ? 'Bravo !' : 'Bravo!')
                    ? 34
                    : 20,
              );
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(of: message, matching: find.byType(RichText)),
              );
              expect(paragraph.didExceedMaxLines, isFalse);
              expect(
                find.byKey(const ValueKey('discovery-skip')).hitTestable(),
                findsOneWidget,
              );
              expect(tester.takeException(), isNull);
            }

            expect(
              instruction(),
              lang == 'fr'
                  ? 'Balaie le tiroir.\nSélectionne \uFFFC'
                  : 'Swipe the tray.\nSelect \uFFFC',
            );
            final rack = find.byKey(const ValueKey('discovery-rack'));
            final scrollable = find.descendant(
              of: rack,
              matching: find.byType(Scrollable),
            );
            final scroll = tester.state<ScrollableState>(scrollable).position;
            final before = scroll.pixels;
            final swipeStrip = find.byKey(
              const ValueKey('discovery-swipe-strip'),
            );
            final swipeHint = lang == 'fr'
                ? 'Balaie ici pour voir les pièces'
                : 'Swipe here to see the pieces';
            expect(
              find.text(swipeHint),
              round == 0 ? findsOneWidget : findsNothing,
            );
            await tester.drag(swipeStrip, const Offset(-40, 0));
            await tester.pumpAndSettle();
            expect(scroll.pixels, greaterThan(before));
            expect(find.text(swipeHint), findsNothing);
            final afterSwipe = scroll.pixels;
            await tester.pump(const Duration(seconds: 2));
            expect(scroll.pixels, afterSwipe);
            readable();
            final thumbnail = tester.widget<PieceRenderer>(
              find.byKey(const ValueKey('discovery-target-thumbnail')),
            );
            expect(thumbnail.piece.id, puzzle.piece.id);
            expect(thumbnail.positionIndex, puzzle.initialOrientation);
            expect(thumbnail.showLabel, isFalse);
            final firstPiece = find
                .descendant(of: rack, matching: find.byType(PieceRenderer))
                .first;
            expect(
              tester.widget<PieceRenderer>(firstPiece).piece.id,
              isNot(puzzle.piece.id),
            );
            await tester.tap(firstPiece);
            await tester.pump();
            expect(instruction(), contains(lang == 'fr' ? 'Balaie' : 'Swipe'));
            for (var i = 0; i < 80 && instruction().contains('\n'); i++) {
              await tester.drag(swipeStrip, const Offset(-40, 0));
              await tester.pumpAndSettle();
            }
            expect(
              instruction(),
              lang == 'fr' ? 'Sélectionne \uFFFC' : 'Select \uFFFC',
            );
            readable();
            final tile = find.byKey(
              ValueKey('discovery-piece-${puzzle.piece.id}'),
            );
            await tester.tap(tile);
            await tester.pump();
            readable();
            final orientationThumbnail = tester.widget<PieceRenderer>(
              find.byKey(const ValueKey('discovery-target-thumbnail')),
            );
            expect(orientationThumbnail.piece.id, puzzle.piece.id);
            expect(orientationThumbnail.positionIndex, puzzle.orientation);
            expect(orientationThumbnail.showLabel, isFalse);
            final selectedInstruction = instruction();
            final selectedOffset = scroll.pixels;
            final swipeDelta = selectedOffset >= scroll.maxScrollExtent - 40
                ? const Offset(40, 0)
                : const Offset(-40, 0);
            await tester.drag(swipeStrip, swipeDelta);
            await tester.pumpAndSettle();
            expect(scroll.pixels, isNot(selectedOffset));
            expect(instruction(), selectedInstruction);
            expect(
              tester
                  .widget<PieceRenderer>(
                    find.byKey(const ValueKey('discovery-target-thumbnail')),
                  )
                  .positionIndex,
              puzzle.orientation,
            );
            await tester.drag(swipeStrip, -swipeDelta);
            await tester.pumpAndSettle();

            expect(
              instruction(),
              lang == 'fr'
                  ? 'Positionne \uFFFC\navec les icônes.'
                  : 'Orient \uFFFC\nusing the icons.',
            );
            for (final key in [
              'discovery-rotate-left',
              'discovery-rotate',
              'discovery-mirror-horizontal',
              'discovery-mirror-vertical',
            ]) {
              expect(
                tester.widget<IconButton>(find.byKey(ValueKey(key))).onPressed,
                isNotNull,
              );
            }
            final source = find.descendant(
              of: tile,
              matching: find.byType(PieceRenderer),
            );
            expect(
              tester.widget<PieceRenderer>(source).positionIndex,
              puzzle.initialOrientation,
            );
            await tester.tap(find.byKey(const ValueKey('discovery-rotate')));
            await tester.pump();
            expect(
              tester.widget<PieceRenderer>(source).positionIndex,
              puzzle.orientation,
            );
            expect(
              find.byKey(const ValueKey('discovery-target-thumbnail')),
              findsNothing,
            );
            // Les quatre commandes restent utilisables ; une forme erronée ne
            // peut plus être déposée, puis l'opération inverse retrouve la cible.
            for (final operation in [
              (
                'discovery-rotate',
                'discovery-rotate-left',
                puzzle.piece.rotationCW,
              ),
              (
                'discovery-mirror-horizontal',
                'discovery-mirror-horizontal',
                puzzle.piece.symmetryH,
              ),
              (
                'discovery-mirror-vertical',
                'discovery-mirror-vertical',
                puzzle.piece.symmetryV,
              ),
            ]) {
              await tester.tap(find.byKey(ValueKey(operation.$1)));
              await tester.pump();
              expect(
                tester.widget<PieceRenderer>(source).positionIndex,
                operation.$3(puzzle.orientation),
              );
              await tester.tap(find.byKey(ValueKey(operation.$2)));
              await tester.pump();
              expect(
                tester.widget<PieceRenderer>(source).positionIndex,
                puzzle.orientation,
              );
            }
            readable();
            final board = tester.getRect(
              find.byKey(const ValueKey('discovery-board')),
            );
            final cell = board.width / DiscoveryPuzzle.width;
            final x =
                (puzzle.target.cells.map((p) => p[0]).reduce(math.min) +
                    puzzle.target.cells.map((p) => p[0]).reduce(math.max) +
                    1) /
                2;
            final y =
                (puzzle.target.cells.map((p) => p[1]).reduce(math.min) +
                    puzzle.target.cells.map((p) => p[1]).reduce(math.max) +
                    1) /
                2;
            final drop = board.topLeft + Offset(x * cell, y * cell);
            final start = tester.getCenter(tile);
            impacts.clear();
            // Un relâcher hors plateau ne valide rien.
            await tester.dragFrom(start, const Offset(0, -12));
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('discovery-next')), findsNothing);
            expect(impacts, isEmpty);
            final gesture = await tester.startGesture(tester.getCenter(tile));
            await tester.pump(const Duration(milliseconds: 150));
            await gesture.moveTo(drop);
            await tester.pump();
            await gesture.up();
            await tester.pump();
            final initialSize = tester.widget<Text>(message).style!.fontSize!;
            if (reduced) {
              expect(initialSize, 34);
            } else {
              expect(initialSize, 20);
              await tester.pump(const Duration(milliseconds: 350));
              expect(
                tester.widget<Text>(message).style!.fontSize!,
                greaterThan(initialSize),
              );
            }
            await tester.pumpAndSettle();
            expect(
              impacts,
              hapticsEnabled ? ['HapticFeedbackType.mediumImpact'] : isEmpty,
            );
            expect(find.text('Training'), findsOneWidget);
            expect(find.text('Play'), findsOneWidget);
            expect(
              find.byKey(const ValueKey('discovery-next')),
              findsOneWidget,
            );
            expect(
              find.text(lang == 'fr' ? 'Bravo !' : 'Bravo!'),
              findsOneWidget,
            );
            expect(tile, findsNothing);
            readable();

            if (round == 0) {
              final done = tester.widget<Text>(message).data;
              await tester.pump(const Duration(seconds: 5));
              expect(instruction(), done);
              await tester.ensureVisible(
                find.byKey(const ValueKey('discovery-next')),
              );
              await tester.tap(find.byKey(const ValueKey('discovery-next')));
              await tester.pumpAndSettle();
              expect(
                tester
                    .widget<ListView>(rack)
                    .childrenDelegate
                    .estimatedChildCount,
                12,
              );
              expect(played, 0);
              expect(skipped, 0);
            }
          }
          await tester.ensureVisible(
            find.byKey(const ValueKey('discovery-play')),
          );
          await tester.tap(find.byKey(const ValueKey('discovery-play')));
          await tester.pump();
          expect(played, 1);
          expect(skipped, 0);
        });
      }
    }
  }
}
