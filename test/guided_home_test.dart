// Modified: 2026-09-12 03:40 — parcours en navigation accessible ; défilement testé séparément.
// Historique: 2026-09-11 16:11 — vérifier Training en bouton plein et le retrait de Jouer à la fin du parcours.
// Historique: 2026-09-11 07:57 — sept pavages, aucune orientation déjà prête et enchaînement vers un autre entraînement.
// Historique: 2026-09-11 07:33 — tester exploration du rack, sélection, quatre commandes et dépôt depuis chaque case.
// Historique: 2026-09-10 15:07 — accueil : dépôt naturel au centre de la silhouette, quelle que soit la case saisie.
// Historique: 2026-09-10 14:57 — pavage réel et parcours guidé complet, gestes et langues, iPhone/tablette portrait/paysage.
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/home/guided_home.dart';
import 'package:pentapol/pentoscope/home/home_tirages_data.dart';
import 'package:pentapol/pentoscope/home/guided_success_celebration.dart';

void main() {
  for (var tirage = 0; tirage < kHomeTirages.length; tirage++) {
    test('pavage $tirage : toutes les pièces demandent une transformation', () {
      final steps = guidedSteps(tirageIndex: tirage);
      final cells = steps
          .expand((s) => s.target.cells)
          .map((c) => (c[0], c[1]))
          .toList();
      expect(cells.length, 15);
      expect(cells.toSet().length, 15);
      for (final (x, y) in cells) {
        expect(x, inInclusiveRange(0, 2));
        expect(y, inInclusiveRange(0, 4));
      }
      for (final s in steps) {
        expect(
          shapeKey(orientationCells(s.piece, s.initialOrientation)),
          isNot(shapeKey(orientationCells(s.piece, s.targetOrientation))),
        );
      }
      expect(
        transformedOrientation(steps[0].piece, steps[0].initialOrientation),
        steps[0].targetOrientation,
      );
      expect(steps[1].initialOrientation, isNot(steps[1].targetOrientation));
      expect(
        transformedOrientation(steps[1].piece, steps[1].initialOrientation),
        steps[1].targetOrientation,
      );
      var rotation = steps[2].initialOrientation;
      for (var i = 0; i < 4; i++) {
        expect(
          shapeKey(orientationCells(steps[2].piece, rotation)),
          isNot(
            shapeKey(
              orientationCells(steps[2].piece, steps[2].targetOrientation),
            ),
          ),
        );
        rotation = transformedOrientation(steps[2].piece, rotation);
      }
      expect(
        transformedOrientation(
          steps[2].piece,
          steps[2].initialOrientation,
          mirror: true,
        ),
        steps[2].targetOrientation,
      );
    });
  }

  testWidgets(
    'mauvais choix, quatre opérations et nouvelle tentative sans perte',
    (tester) async {
      tester.view.physicalSize = const Size(375, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
            child: child!,
          ),
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GuidedHome(
              initialTirageIndex: 0,
              colorOf: (_) => Colors.teal,
              ratio: .46,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(GuidedHome)));
      final rack = find.byKey(const ValueKey('guided-rack'));
      final scrollable = find.descendant(
        of: rack,
        matching: find.byType(Scrollable),
      );
      PieceRenderer piece(int i) => tester.widget<PieceRenderer>(
        find.descendant(
          of: find.byKey(ValueKey('guided-piece-$i')),
          matching: find.byType(PieceRenderer),
        ),
      );
      Future<void> choose(int i, double delta) async {
        final target = find.byKey(ValueKey('guided-select-$i'));
        await tester.scrollUntilVisible(target, delta, scrollable: scrollable);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> press(String key) async {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }

      Future<void> drag(int i, Offset destination) async {
        final f = find.descendant(
          of: find.byKey(ValueKey('guided-piece-$i')),
          matching: find.byType(PieceRenderer),
        );
        final r = piece(i);
        final coords = orientationCells(r.piece, r.positionIndex);
        final first = coords.first;
        final origin =
            tester.getTopLeft(f) +
            Offset(
              4 +
                  (first.x - coords.map((p) => p.x).reduce(math.min) + .5) *
                      r.cellSize,
              4 +
                  (first.y - coords.map((p) => p.y).reduce(math.min) + .5) *
                      r.cellSize,
            );
        final gesture = await tester.startGesture(origin);
        await tester.pump(const Duration(milliseconds: 150));
        await gesture.moveTo(destination);
        await tester.pump();
        expect(
          tester
              .widgetList<PieceRenderer>(find.byType(PieceRenderer))
              .where((p) => p.isDragging)
              .single
              .invalidPlacement,
          isTrue,
        );
        await gesture.up();
        await tester.pumpAndSettle();
      }

      // Un tap fonctionne aussi sans imposer un geste préalable au joueur.
      await choose(1, 80);
      expect(find.text(l10n.guidedChoose(7)), findsOneWidget);
      final initial = piece(1).positionIndex;
      final p = piece(1).piece;
      await press('guided-rotate-left');
      expect(piece(1).positionIndex, p.rotationTW(initial));
      await press('guided-rotate');
      expect(piece(1).positionIndex, initial);
      await press('guided-mirror-horizontal');
      expect(piece(1).positionIndex, p.symmetryH(initial));
      await press('guided-mirror-horizontal');
      expect(piece(1).positionIndex, initial);
      await press('guided-mirror');
      expect(piece(1).positionIndex, p.symmetryV(initial));
      await press('guided-mirror');
      expect(piece(1).positionIndex, initial);
      final board = tester.getRect(find.byType(DragTarget<int>));
      await drag(1, board.center);
      expect(find.text(l10n.guidedChoose(7)), findsOneWidget);
      await choose(0, 80);
      expect(find.text(l10n.guidedRotate), findsOneWidget);
      final cells = guidedSteps().first.target.cells;
      final cell = board.width / 3;
      final destination =
          board.topLeft +
          Offset(
            (cells.map((c) => c[0]).reduce(math.min) +
                    cells.map((c) => c[0]).reduce(math.max) +
                    1) *
                cell /
                2,
            (cells.map((c) => c[1]).reduce(math.min) +
                    cells.map((c) => c[1]).reduce(math.max) +
                    1) *
                cell /
                2,
          );
      await drag(0, destination);
      expect(find.text(l10n.guidedRetry), findsOneWidget);
      expect(find.byKey(const ValueKey('guided-piece-0')), findsOneWidget);
      await press('guided-rotate');
      expect(find.text(l10n.guidedReady), findsOneWidget);
      await drag(0, const Offset(2, 2));
      expect(find.text(l10n.guidedRetry), findsOneWidget);
      expect(tester.getRect(find.byType(DragTarget<int>)), board);
      expect(find.byType(GuidedSuccessCelebration), findsNothing);
      expect(find.textContaining('Étape'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (var tirage = 0; tirage < kHomeTirages.length; tirage++) {
    for (final size in [
      const Size(375, 650),
      const Size(874, 320),
      const Size(1024, 1200),
      const Size(1366, 850),
    ]) {
      for (final lang in ['fr', 'en']) {
        for (
          var grabIndex = 0;
          grabIndex < (tirage == 0 ? 5 : 1);
          grabIndex++
        ) {
          testWidgets('parcours $tirage complet $size $lang prise $grabIndex', (
            tester,
          ) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final boundary = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(accessibleNavigation: true),
                  child: child!,
                ),
                locale: Locale(lang),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: RepaintBoundary(
                    key: boundary,
                    child: GuidedHome(
                      initialTirageIndex: tirage,
                      colorOf: (id) =>
                          Colors.primaries[id % Colors.primaries.length],
                      ratio: .46,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final l10n = AppLocalizations.of(
              tester.element(find.byType(GuidedHome)),
            );
            final steps = guidedSteps(tirageIndex: tirage);
            // Export facultatif pour vérification visuelle, hors des comparaisons de tests.
            if (const bool.fromEnvironment('WELCOME_PREVIEWS') &&
                tirage == 0 &&
                lang == 'fr' &&
                grabIndex == 0) {
              await tester.runAsync(() async {
                final render =
                    boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary;
                final image = await render.toImage(pixelRatio: 1);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '/tmp/pentapol-welcome-${size.width.toInt()}.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            final frame = tester.widget<DecoratedBox>(
              find.byKey(const ValueKey('guided-board-frame')),
            );
            final decoration = frame.decoration as BoxDecoration;
            expect(
              decoration.border,
              Border.all(color: Colors.grey.shade700, width: 3),
            );
            expect(decoration.borderRadius, BorderRadius.circular(16));
            final boardBefore = tester.getRect(find.byType(DragTarget<int>));
            expect(find.text(l10n.guidedBrowse), findsOneWidget);
            final keys = [
              'guided-rotate-left',
              'guided-rotate',
              'guided-mirror-horizontal',
              'guided-mirror',
            ];
            final icons = [
              GameIcons.isometryRotationTW,
              GameIcons.isometryRotationCW,
              GameIcons.isometrySymmetryH,
              GameIcons.isometrySymmetryV,
            ];
            for (var i = 0; i < keys.length; i++) {
              final button = tester.widget<IconButton>(
                find.byKey(ValueKey(keys[i])),
              );
              expect((button.icon as Icon).icon, icons[i].icon);
              expect(button.onPressed, isNull);
            }
            final landscape = size.width > size.height;
            final rack = find.byKey(const ValueKey('guided-rack'));
            await tester.drag(
              rack,
              landscape ? const Offset(0, -80) : const Offset(-140, 0),
            );
            await tester.pumpAndSettle();
            expect(
              find.text(l10n.guidedChoose(steps.first.piece.id)),
              findsOneWidget,
            );
            for (var step = 0; step < 3; step++) {
              final choose = find.byKey(ValueKey('guided-select-$step'));
              // Afficher l'emplacement entier : une rotation peut agrandir la pièce dedans.
              await tester.scrollUntilVisible(
                find.byKey(ValueKey('guided-slot-$step')),
                step == 1 ? -80 : 80,
                scrollable: find.descendant(
                  of: rack,
                  matching: find.byType(Scrollable),
                ),
                maxScrolls: 40,
              );
              await tester.pumpAndSettle();
              await tester.tap(choose);
              await tester.pumpAndSettle();
              expect(tester.getRect(find.byType(DragTarget<int>)), boardBefore);
              for (final key in keys) {
                expect(
                  tester
                      .widget<IconButton>(find.byKey(ValueKey(key)))
                      .onPressed,
                  isNotNull,
                );
              }
              if (step < 2) {
                await tester.tap(find.byKey(const ValueKey('guided-rotate')));
              }
              if (step == 2) {
                await tester.tap(find.byKey(const ValueKey('guided-mirror')));
              }
              await tester.pump();
              expect(find.text(l10n.guidedReady), findsOneWidget);
              final draggable = find.byKey(ValueKey('guided-piece-$step'));
              final rendererFinder = find.descendant(
                of: draggable,
                matching: find.byType(PieceRenderer),
              );
              final renderer = tester.widget<PieceRenderer>(rendererFinder);
              final box = tester.renderObject<RenderBox>(rendererFinder);
              final coords = orientationCells(
                renderer.piece,
                renderer.positionIndex,
              );
              final gx =
                  coords[grabIndex].x - coords.map((p) => p.x).reduce(math.min);
              final gy =
                  coords[grabIndex].y - coords.map((p) => p.y).reduce(math.min);
              final grab = box.localToGlobal(
                Offset(
                  4 + (gx + .5) * renderer.cellSize,
                  4 + (gy + .5) * renderer.cellSize,
                ),
              );
              final gesture = await tester.startGesture(grab);
              await tester.pump(const Duration(milliseconds: 150));
              expect(
                tester
                    .widgetList<PieceRenderer>(find.byType(PieceRenderer))
                    .where((p) => p.isDragging)
                    .single
                    .invalidPlacement,
                isTrue,
              );
              final boardRect = tester.getRect(find.byType(DragTarget<int>));
              final cell = boardRect.width / 3;
              final target = steps[step].target;
              final tx = target.cells.map((c) => c[0]).reduce(math.min);
              final ty = target.cells.map((c) => c[1]).reduce(math.min);
              final destination =
                  boardRect.topLeft +
                  Offset(
                    (tx +
                            (target.cells.map((c) => c[0]).reduce(math.max) -
                                    tx +
                                    1) /
                                2) *
                        cell,
                    (ty +
                            (target.cells.map((c) => c[1]).reduce(math.max) -
                                    ty +
                                    1) /
                                2) *
                        cell,
                  );
              await gesture.moveTo(destination);
              await tester.pump();
              expect(
                tester
                    .widgetList<PieceRenderer>(find.byType(PieceRenderer))
                    .where((p) => p.isDragging)
                    .single
                    .invalidPlacement,
                isFalse,
              );
              await gesture.up();
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 180));
              expect(
                find.byKey(const ValueKey('guided-celebration-paint')),
                findsOneWidget,
              );
              expect(
                tester
                    .widget<GuidedSuccessCelebration>(
                      find.byType(GuidedSuccessCelebration),
                    )
                    .complete,
                step == 2,
              );
              expect(tester.getRect(find.byType(DragTarget<int>)), boardBefore);
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('guided-celebration-paint')),
                findsNothing,
              );
              expect(tester.takeException(), isNull);
            }
            expect(find.text(l10n.guidedDone), findsOneWidget);
            expect(find.text(l10n.play), findsNothing);
            expect(
              find.ancestor(
                of: find.text(l10n.guidedAnother),
                matching: find.byType(FilledButton),
              ),
              findsOneWidget,
            );
            await tester.tap(find.text(l10n.guidedAnother));
            await tester.pumpAndSettle();
            expect(find.text(l10n.guidedBrowse), findsOneWidget);
            final next = guidedSteps(
              tirageIndex: (tirage + 1) % kHomeTirages.length,
            );
            // Nouveau tirage réel, sans reprendre les pièces ou orientations du précédent.
            final firstVisible = tester.widget<PieceRenderer>(
              find.descendant(
                of: find.byKey(const ValueKey('guided-piece-1')),
                matching: find.byType(PieceRenderer),
              ),
            );
            expect(firstVisible.piece.id, next[1].piece.id);
            expect(firstVisible.positionIndex, next[1].initialOrientation);
            expect(
              tester
                  .widget<IconButton>(
                    find.byKey(const ValueKey('guided-rotate')),
                  )
                  .onPressed,
              isNull,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
