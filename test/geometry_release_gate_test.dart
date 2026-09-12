// Modified: 2026-09-12 10:58 — contrôler le masquage public et le gel du barème officiel.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/geometry_score.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/settings_screen.dart';

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'option de compilation : réglages expérimentaux ou valeurs fixes',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await container
          .read(settingsProvider.notifier)
          .setGeometryRules(const GeometryRules(fillPenalty: 25));
      await container
          .read(pentoscopeProvider.notifier)
          .startPuzzle(PentoscopeSize.size3x5);
      final score = container.read(pentoscopeProvider).geometry!;
      expect(score.rules.fillPenalty, kGeometryTuningEnabled ? 25 : 10);
      expect(score.experimental, kGeometryTuningEnabled);
    },
  );

  testWidgets(
    'option de compilation : entrée des réglages visible ou absente',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsProvider.overrideWith(_Settings.new)],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('geometry-settings')),
        kGeometryTuningEnabled ? findsOneWidget : findsNothing,
      );
    },
  );
}
