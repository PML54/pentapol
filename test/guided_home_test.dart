// Modified: 2026-09-10 15:07 — accueil : dépôt naturel au centre de la silhouette, quelle que soit la case saisie.
// Historique: 2026-09-10 14:57 — pavage réel et parcours guidé complet, gestes et langues, iPhone/tablette portrait/paysage.
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/home/guided_home.dart';

void main() {
  test(
    'trois étapes : pavage complet, une rotation et un miroir nécessaire',
    () {
      final steps = guidedSteps();
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
      expect(steps[0].initialOrientation, steps[0].targetOrientation);
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
    },
  );

  for (final size in [
    const Size(375, 650),
    const Size(874, 320),
    const Size(1024, 1200),
    const Size(1366, 850),
  ]) {
    for (final lang in ['fr', 'en']) {
      for (var grabIndex = 0; grabIndex < 5; grabIndex++) {
        testWidgets('parcours complet $size $lang prise $grabIndex', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var playCount = 0;
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: RepaintBoundary(
                  key: boundary,
                  child: GuidedHome(
                    colorOf: (id) => {
                      7: Colors.orange,
                      2: Colors.teal,
                      4: Colors.purple,
                    }[id]!,
                    ratio: .46,
                    onPlay: () {
                      playCount++;
                    },
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
          final steps = guidedSteps();
          // Export facultatif pour vérification visuelle, hors des comparaisons de tests.
          if (const bool.fromEnvironment('WELCOME_PREVIEWS') &&
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
          for (var step = 0; step < 3; step++) {
            expect(find.text(l10n.guidedStep(step + 1)), findsOneWidget);
            if (step == 1) {
              await tester.tap(find.byKey(const ValueKey('guided-rotate')));
            }
            if (step == 2) {
              await tester.tap(find.byKey(const ValueKey('guided-mirror')));
            }
            await tester.pump();
            if (step > 0) expect(find.text(l10n.guidedReady), findsOneWidget);
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
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(find.text(l10n.guidedDone), findsOneWidget);
          expect(playCount, 0);
          await tester.tap(find.text(l10n.play));
          expect(playCount, 1);
          await tester.tap(find.text(l10n.guidedAgain));
          await tester.pumpAndSettle();
          expect(find.text(l10n.guidedStep(1)), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
