// Modified: 2026-09-23 05:00 — vérifier le bilan Game et sa relance au double-tap.
// Historique: 2026-09-22 06:24 — vérifier le bilan Game dans l'AppBar et la relance au tap.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/geometry_score.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';
import 'package:pentapol/providers/settings_provider.dart';

class _Game extends PentoscopeNotifier {
  int starts = 0;
  PentoscopeSize? startedSize;

  void load(PentoscopeState next) => state = next;

  @override
  Future<void> startPuzzle(
    PentoscopeSize size, {
    int? mask,
    bool showSolution = false,
    bool isProgression = false,
  }) async {
    starts++;
    startedSize = size;
    state = state.copyWith(isComplete: false);
  }
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  for (final size in [const Size(320, 568), const Size(874, 402)]) {
    for (final lang in ['fr', 'en']) {
      testWidgets('bilan lisible $size $lang', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final game = _Game();
        final container = ProviderContainer(
          overrides: [
            pentoscopeProvider.overrideWith(() => game),
            settingsProvider.overrideWith(_Settings.new),
          ],
        );
        addTearDown(container.dispose);
        container.read(pentoscopeProvider);
        game.load(
          PentoscopeState(
            plateau: Plateau.allVisible(3, 5),
            puzzle: const PentoscopePuzzle(
              size: PentoscopeSize.size3x5,
              pieceIds: [2, 4, 7],
              solutionCount: 1,
            ),
            isComplete: true,
            faultCount: 2,
            hintCount: 1,
            elapsedSeconds: 100,
            geometry: const GeometryScore(penalties: 7.5),
          ),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: const PentoscopeGameScreen(),
            ),
          ),
        );
        await tester.pump();
        final summary = find.byKey(const ValueKey('game-completion-summary'));
        expect(summary, findsOneWidget);
        final semantics = tester.widget<Semantics>(summary);
        final label = semantics.properties.label!;
        expect(
          label,
          contains(lang == 'fr' ? 'Géométrie 92,5/100' : 'Geometry 92.5/100'),
        );
        expect(label, contains(lang == 'fr' ? 'Impasses 2' : 'Dead ends 2'));
        expect(label, contains(lang == 'fr' ? 'Triche 1' : 'Cheating 1'));
        expect(
          label,
          contains(
            lang == 'fr'
                ? 'Double tap pour une nouvelle partie.'
                : 'Double tap for a new game.',
          ),
        );
        expect(find.text('Acuité'), findsNothing);
        expect(find.byKey(const ValueKey('game-continue')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('game-continue')));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byKey(const ValueKey('game-continue')));
        await tester.pump(const Duration(milliseconds: 100));
        expect(game.starts, 1);
        expect(game.startedSize, PentoscopeSize.size3x5);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
