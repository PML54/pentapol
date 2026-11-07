// Modified: 2026-10-29 07:42 — vérifier la progression des cibles sauvegardée entre ouvertures.
// Historique: 2026-10-28 08:05 — vérifier la découverte 5×5 et les cibles de son corpus.
// Historique: 2026-10-28 06:49 — chercher la cible parmi les douze pièces du tiroir de découverte.
// Historique: 2026-10-28 05:27 — vérifier la reprise après réussite et la fin explicite persistée.
// Historique: 2026-10-28 05:01 — vérifier découverte directe et persistance depuis PentapolApp.
// test/welcome_startup_test.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/main.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/home/discovery_screen.dart';

class _Game extends PentoscopeNotifier {
  final started = Completer<void>();
  @override
  Future<void> startPuzzle(
    PentoscopeSize size, {
    int? mask,
    bool showSolution = false,
    bool isProgression = false,
  }) async {
    started.complete();
  }
}

void main() {
  for (final scenario in [
    'fresh',
    'legacy',
    'old-help',
    'seen',
    'won',
    'progress',
  ]) {
    testWidgets('démarrage complet : $scenario', (tester) async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      if (scenario != 'fresh') {
        await tester.runAsync(
          () => db.setSetting(
            'app_settings',
            jsonEncode({
              'localeCode': 'fr',
              if (scenario == 'progress') 'discoveryNextExercise': 17,
              if (scenario == 'old-help') 'hasSeenWelcomeHelp': true,
              if (scenario == 'seen') 'hasCompletedDiscovery': true,
            }),
          ),
        );
      }
      ProviderContainer? container;
      addTearDown(() async {
        container?.dispose();
        await tester.runAsync(db.close);
      });
      Future<void> launch() async {
        await tester.pumpWidget(const SizedBox.shrink());
        container?.dispose();
        final storedBefore = await tester.runAsync(
          () => db.getSetting('app_settings'),
        );
        final initialIndex = storedBefore == null
            ? 0
            : (jsonDecode(storedBefore)['discoveryNextExercise'] as int? ?? 0);
        final game = _Game();
        container = ProviderContainer(
          overrides: [
            settingsDatabaseProvider.overrideWithValue(db),
            pentoscopeProvider.overrideWith(() => game),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: const PentapolApp(),
          ),
        );
        await tester.runAsync(() => game.started.future);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        if (find.byType(DiscoveryScreen).evaluate().isNotEmpty) {
          final screen = tester.widget<DiscoveryScreen>(
            find.byType(DiscoveryScreen),
          );
          expect(screen.initialExerciseIndex, initialIndex);
          await tester.runAsync(() async {
            final saved = await db.getSetting('app_settings');
            expect(
              jsonDecode(saved!)['discoveryNextExercise'],
              initialIndex + 1,
            );
          });
        }
      }

      await launch();
      expect(
        find.byType(DiscoveryScreen),
        scenario == 'seen' ? findsNothing : findsOneWidget,
      );
      if (scenario == 'won') {
        final puzzle = DiscoveryPuzzle();
        final rack = find.byKey(const ValueKey('discovery-rack'));
        final tile = find.byKey(ValueKey('discovery-piece-${puzzle.piece.id}'));
        for (var i = 0; i < 32 && tile.hitTestable().evaluate().isEmpty; i++) {
          await tester.drag(rack, const Offset(-160, 0));
          await tester.pumpAndSettle();
        }
        await tester.tap(tile);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('discovery-rotate')));
        await tester.pump();
        final board = tester.getRect(
          find.byKey(const ValueKey('discovery-board')),
        );
        final cell = board.width / DiscoveryPuzzle.width;
        final gesture = await tester.startGesture(tester.getCenter(tile));
        await tester.pump(const Duration(milliseconds: 150));
        final xs = puzzle.target.cells.map((c) => c[0]);
        final ys = puzzle.target.cells.map((c) => c[1]);
        await gesture.moveTo(
          board.topLeft +
              Offset(
                (xs.reduce(math.min) + xs.reduce(math.max) + 1) * cell / 2,
                (ys.reduce(math.min) + ys.reduce(math.max) + 1) * cell / 2,
              ),
        );
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('discovery-next')), findsOneWidget);
        expect(
          container!.read(settingsProvider).hasCompletedDiscovery,
          isFalse,
        );
        await tester.runAsync(() async {
          final stored = await db.getSetting('app_settings');
          expect(jsonDecode(stored!)['hasCompletedDiscovery'], isNot(true));
        });
        // Une fermeture après réussite seule doit reproposer la découverte.
        await launch();
        expect(find.byType(DiscoveryScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('discovery-next')), findsNothing);
      }
      if (scenario != 'seen') {
        await tester.tap(find.byKey(const ValueKey('discovery-skip')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(() async {
          final stored = await db.getSetting('app_settings');
          expect(jsonDecode(stored!)['hasCompletedDiscovery'], isTrue);
        });
        await launch();
        expect(find.byType(DiscoveryScreen), findsNothing);
        expect(find.byKey(const ValueKey('home-play')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
