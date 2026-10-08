// Modified: 2026-10-08 06:50 — vérifier le minimum 30 ms et sa persistance sans écraser un choix existant.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  test('délai par défaut 30 ms, anciennes préférences conservées', () {
    expect(const GameSettings().longPressDuration, 30);
    expect(GameSettings.fromJson({}).longPressDuration, 30);
    expect(
      GameSettings.fromJson({'longPressDuration': 50}).longPressDuration,
      50,
    );
  });

  test('délai borné à 30–200 ms et sauvegardé', () async {
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [settingsDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final notifier = container.read(settingsProvider.notifier);
    await notifier.ensureLoaded();
    await notifier.setLongPressDuration(30);
    expect(container.read(settingsProvider).game.longPressDuration, 30);
    final stored =
        jsonDecode((await db.getSetting('app_settings'))!)
            as Map<String, dynamic>;
    expect(AppSettings.fromJson(stored).game.longPressDuration, 30);
    await notifier.setLongPressDuration(0);
    expect(container.read(settingsProvider).game.longPressDuration, 30);
    await notifier.setLongPressDuration(300);
    expect(container.read(settingsProvider).game.longPressDuration, 200);
  });
}
