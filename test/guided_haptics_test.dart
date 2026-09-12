// Modified: 2026-09-12 06:33 — tester les vibrations de prise, cible et pose, ainsi que leur désactivation.
// test/guided_haptics_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/home/guided_home.dart';

void main() {
  for (final enabled in [true, false]) {
    testWidgets('retours physiques du glissé : enabled=$enabled', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 650);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
            child: child!,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GuidedHome(
              initialTirageIndex: 0,
              enableHaptics: enabled,
              colorOf: (_) => Colors.teal,
              ratio: .46,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('guided-rack')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('guided-slot-0')),
        80,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('guided-select-0')));
      await tester.pumpAndSettle();
      expect(
        haptics,
        enabled ? ['HapticFeedbackType.selectionClick'] : isEmpty,
      );
      haptics.clear();
      await tester.tap(find.byKey(const ValueKey('guided-rotate')));
      await tester.pumpAndSettle();
      expect(
        haptics,
        enabled ? ['HapticFeedbackType.selectionClick'] : isEmpty,
      );
      haptics.clear();
      final renderer = find.descendant(
        of: find.byKey(const ValueKey('guided-piece-0')),
        matching: find.byType(PieceRenderer),
      );
      final piece = tester.widget<PieceRenderer>(renderer);
      final first = orientationCells(piece.piece, piece.positionIndex).first;
      final origin =
          tester.getTopLeft(renderer) +
          Offset(
            4 + (first.x + .5) * piece.cellSize,
            4 + (first.y + .5) * piece.cellSize,
          );
      Future<TestGesture> grab() async {
        final gesture = await tester.startGesture(origin);
        await tester.pump(const Duration(milliseconds: 150));
        expect(haptics, enabled ? ['HapticFeedbackType.lightImpact'] : isEmpty);
        return gesture;
      }

      // Un relâchement hors plateau ne produit pas la confirmation de pose.
      final cancelled = await grab();
      await cancelled.moveTo(const Offset(5, 5));
      await cancelled.up();
      await tester.pumpAndSettle();
      expect(haptics, enabled ? ['HapticFeedbackType.lightImpact'] : isEmpty);
      haptics.clear();
      final gesture = await grab();
      final board = tester.getRect(find.byType(DragTarget<int>));
      final cell = board.width / 3;
      final target = guidedSteps().first.target.cells;
      final x =
          target.map((c) => c[0] + .5).reduce((a, b) => a + b) / target.length;
      final y =
          target.map((c) => c[1] + .5).reduce((a, b) => a + b) / target.length;
      final destination = board.topLeft + Offset(x * cell, y * cell);
      await gesture.moveTo(destination);
      await tester.pump();
      await gesture.moveTo(destination + const Offset(1, 0));
      await tester.pump();
      expect(
        haptics,
        enabled
            ? [
                'HapticFeedbackType.lightImpact',
                'HapticFeedbackType.selectionClick',
              ]
            : isEmpty,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        haptics,
        enabled
            ? [
                'HapticFeedbackType.lightImpact',
                'HapticFeedbackType.selectionClick',
                'HapticFeedbackType.mediumImpact',
              ]
            : isEmpty,
      );
      expect(find.byKey(const ValueKey('guided-piece-0')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
