// Modified: 2026-09-12 10:58 — vérifier la remise à zéro autorisée au passage en schéma 11.
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';

void main() {
  test('schéma 10 vers 11 : base neuve, réglages et parties effacés', () async {
    final dir = await Directory.systemTemp.createTemp('pentapol-schema-test-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/test.sqlite');
    final old = SettingsDatabase.forTesting(NativeDatabase(file));
    await old.setSetting('old-marker', 'to-delete');
    await old.saveCurrentGame(
      sizeName: 'size3x5',
      pieceIds: '2,4,7',
      solutionCount: 1,
      placedPieces: '[]',
      positionIndices: '{}',
      elapsedSeconds: 0,
      isometryCount: 0,
      translationCount: 0,
      deleteCount: 0,
      hintCount: 0,
      faultCount: 0,
      isProgression: false,
      initialOrientations: '{}',
    );
    await old.customStatement(
      'ALTER TABLE current_game DROP COLUMN geometry_state',
    );
    await old.customStatement('PRAGMA user_version = 10');
    await old.close();
    final fresh = SettingsDatabase.forTesting(NativeDatabase(file));
    addTearDown(fresh.close);
    expect(await fresh.getSetting('old-marker'), isNull);
    expect(await fresh.loadCurrentGame(), isNull);
    final columns = await fresh
        .customSelect('PRAGMA table_info(current_game)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      contains('geometry_state'),
    );
    expect(fresh.schemaVersion, 11);
  });
}
