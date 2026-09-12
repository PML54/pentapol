// Modified: 2026-09-12 10:58 — réglages FR/EN sur iPhone portrait et paysage, aperçu et persistance.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/geometry_score.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/geometry_settings_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(874, 402)]) {
    for (final lang in ['fr', 'en']) {
      testWidgets(
        'réglage, aperçu, annulation, sauvegarde et reset : $size $lang',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = SettingsDatabase.forTesting(NativeDatabase.memory());
          final container = ProviderContainer(
            overrides: [settingsDatabaseProvider.overrideWithValue(db)],
          );
          addTearDown(() async {
            container.dispose();
            await tester.runAsync(db.close);
          });
          await tester.runAsync(
            () => container.read(settingsProvider.notifier).ensureLoaded(),
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
                home: const SettingsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          Future<void> open() async {
            final entry = find.byKey(const ValueKey('geometry-settings'));
            await tester.scrollUntilVisible(
              entry,
              180,
              scrollable: find.byType(Scrollable).first,
            );
            await Scrollable.ensureVisible(
              tester.element(entry),
              alignment: .2,
            );
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              await tester.tap(entry);
              await tester.pump();
              await container.read(settingsProvider.notifier).ensureLoaded();
            });
            await tester.pumpAndSettle();
            expect(find.byType(GeometrySettingsScreen), findsOneWidget);
          }

          await open();
          final coefficient = find.byKey(
            const ValueKey('geometry-coefficient'),
          );
          await tester.ensureVisible(coefficient);
          await tester.pumpAndSettle();
          tester.widget<Slider>(coefficient).onChanged!(20);
          await tester.pump();
          expect(
            container.read(settingsProvider).game.geometryRules.fillPenalty,
            10,
          );
          final preview = find.byKey(const ValueKey('geometry-preview'));
          await tester.ensureVisible(preview);
          await tester.pumpAndSettle();
          expect(
            find.descendant(of: preview, matching: find.text('−5')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await open();
          expect(tester.widget<Slider>(coefficient).value, 10);
          tester.widget<Slider>(coefficient).onChanged!(20);
          await tester.pump();
          await tester.runAsync(() async {
            await tester.tap(find.byKey(const ValueKey('geometry-save')));
            await db.customSelect('SELECT 1').get();
          });
          await tester.pumpAndSettle();
          expect(find.byType(GeometrySettingsScreen), findsNothing);
          expect(
            container.read(settingsProvider).game.geometryRules.fillPenalty,
            20,
          );
          final stored = await tester.runAsync(
            () => db.getSetting('app_settings'),
          );
          expect(stored, contains('"fillPenalty":20.0'));
          await open();
          expect(tester.widget<Slider>(coefficient).value, 20);
          final reset = find.byKey(const ValueKey('geometry-defaults'));
          await tester.ensureVisible(reset);
          await tester.pumpAndSettle();
          await tester.tap(reset);
          await tester.pump();
          expect(tester.widget<Slider>(coefficient).value, 10);
          await tester.runAsync(() async {
            await tester.tap(find.byKey(const ValueKey('geometry-save')));
            await db.customSelect('SELECT 1').get();
          });
          await tester.pumpAndSettle();
          expect(
            container.read(settingsProvider).game.geometryRules.toJson(),
            const GeometryRules().toJson(),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
