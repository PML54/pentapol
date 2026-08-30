// Modified: 2026-08-30 11:10 — PLAN_PERSISTANCE §7 étape 2 : schéma. Les deux tables mortes de
//           l'ancien historique de parties retirées (et toutes leurs méthodes) ; ajout de
//           CurrentGame, SolvedSolutions, PuzzleStats. schemaVersion 2 + migration destructive
//           (destructiveFallback) — efface et recrée à tout changement de version. Les méthodes
//           (écriture des records, restoreGame) viennent aux étapes 3-4.
// lib/database/settings_database.dart
// Historique: 2025-11-16 10:15:00 → 251226 — base SQLite Pentapol (Drift), version corrigée.

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'settings_database.g.dart';

// ✨ IMPORTANT: Cette fonction DOIT être AVANT la classe
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pentapol_settings.db'));
    return NativeDatabase(file);
  });
}

/// Table pour stocker les paramètres de l'application
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// La partie en cours — une seule ligne (id fixe 0), écrasée. Voir PLAN_PERSISTANCE §2.
/// Ne stocke ni le plateau (reconstruit depuis placedPieces) ni les solutions.
class CurrentGame extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))(); // ligne unique
  TextColumn get sizeName => text()();          // PentoscopeSize.name, ex. 'size6x10'
  TextColumn get pieceIds => text()();          // '1,2,3,…' — le tirage du puzzle
  IntColumn get solutionCount => integer()();   // repris de PentoscopePuzzle
  TextColumn get placedPieces => text()();      // JSON : [{id,pos,x,y}, …]
  TextColumn get positionIndices => text()();   // JSON : {pieceId: orientation}
  IntColumn get elapsedSeconds => integer()();
  IntColumn get isometryCount => integer()();
  IntColumn get translationCount => integer()();
  IntColumn get deleteCount => integer()();
  IntColumn get hintCount => integer()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rectangles complets : une ligne par SOLUTION DÉCOUVERTE. Voir PLAN_PERSISTANCE §4.1.
/// board en clé dès maintenant : la solution n° 5 du 6×10 et celle du 5×12 ne se confondent pas.
class SolvedSolutions extends Table {
  TextColumn get board => text()();                 // '6x10', '5x12', '4x15'
  IntColumn get solutionNumber => integer()();      // 1..9356 pour le 6×10
  IntColumn get timesSolved => integer().withDefault(const Constant(1))();
  IntColumn get bestTimeSeconds => integer()();
  IntColumn get bestActions => integer().nullable()();
  DateTimeColumn get firstSolvedAt => dateTime()();
  DateTimeColumn get lastSolvedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {board, solutionNumber};
}

/// Puzzles à pièces tirées : pas de numéro de solution, un agrégat par taille.
class PuzzleStats extends Table {
  TextColumn get sizeName => text()();               // 'size4x5'
  IntColumn get completed => integer().withDefault(const Constant(0))();
  IntColumn get bestTimeSeconds => integer().nullable()();

  @override
  Set<Column> get primaryKey => {sizeName};
}


// ✨ MAINTENANT la classe (après la fonction et les tables)
@DriftDatabase(tables: [Settings, CurrentGame, SolvedSolutions, PuzzleStats])
class SettingsDatabase extends _$SettingsDatabase {
  // ✨ CORRECTION: super(_openConnection()) au lieu de super._openConnection()
  SettingsDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // ⚠️ Réécriture destructive : à tout changement de schemaVersion, drop + recrée toutes les
  // tables. L'app n'est pas publiée, il n'y a rien à migrer (PLAN_PERSISTANCE §5).
  // 🚨 À RETIRER avant la première soumission App Store — cf. docs/CHECKLIST_APPSTORE.md.
  @override
  MigrationStrategy get migration => destructiveFallback;

  // ============================================================================
  // SETTINGS - Paramètres de l'application (ancien code, intacte)
  // ============================================================================

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

  // ============================================================================
  // Records (SolvedSolutions / PuzzleStats) et partie en cours (CurrentGame) :
  // les tables sont définies ci-dessus ; leurs méthodes d'accès viennent aux
  // étapes 3 et 4 du PLAN_PERSISTANCE.
  // ============================================================================

}