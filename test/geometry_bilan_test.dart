// Modified: 2026-09-12 10:58 — bilan Géométrie/Impasses/Triche FR/EN, grands caractères et paysage.
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
  void load(PentoscopeState next) => state = next;
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
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();
        expect(
          find.text(lang == 'fr' ? 'Géométrie' : 'Geometry'),
          findsOneWidget,
        );
        expect(
          find.text(lang == 'fr' ? 'Impasses' : 'Dead ends'),
          findsOneWidget,
        );
        expect(find.text(lang == 'fr' ? 'Triche' : 'Cheating'), findsOneWidget);
        expect(
          find.text(lang == 'fr' ? '92,5/100' : '92.5/100'),
          findsOneWidget,
        );
        expect(find.text('Acuité'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
