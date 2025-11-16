// Modified: 2025-11-16 10:15:00
// lib/database/settings_database.dart
// Base de données SQLite pour les paramètres de l'application

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'settings_database.g.dart';

/// Table pour stocker les paramètres de l'application
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Settings])
class SettingsDatabase extends _$SettingsDatabase {
  SettingsDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
  
  /// Récupère une valeur de paramètre
  Future<String?> getSetting(String key) async {
    final query = select(settings)..where((tbl) => tbl.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }
  
  /// Définit une valeur de paramètre
  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key: key,
        value: value,
      ),
    );
  }
  
  /// Supprime un paramètre
  Future<void> deleteSetting(String key) async {
    await (delete(settings)..where((tbl) => tbl.key.equals(key))).go();
  }
  
  /// Supprime tous les paramètres
  Future<void> clearAllSettings() async {
    await delete(settings).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pentapol_settings.db'));
    return NativeDatabase(file);
  });
}

