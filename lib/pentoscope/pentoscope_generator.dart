// lib/pentoscope/pentoscope_generator.dart
// Générateur de puzzles Pentoscope utilisant les données pré-calculées

import 'dart:math';
import 'pentoscope_data.dart';

// Remplacer dans pentoscope_generator.dart

/// Tailles de plateau disponibles
enum PentoscopeSize {
  size3x5(0, 5, 3, 3, '3×5'),
  size4x5(1, 5, 4, 4, '4×5'),
  size5x5(2, 5, 5, 5, '5×5');

  final int dataIndex;  // ← renommé
  final int width;
  final int height;
  final int numPieces;
  final String label;

  const PentoscopeSize(this.dataIndex, this.width, this.height, this.numPieces, this.label);

  int get area => width * height;
}
/// Configuration d'un puzzle Pentoscope
class PentoscopePuzzle {
  final PentoscopeSize size;
  final int bitmask;
  final List<int> pieceIds;
  final int solutionCount;

  const PentoscopePuzzle({
    required this.size,
    required this.bitmask,
    required this.pieceIds,
    required this.solutionCount,
  });

  /// Noms des pièces (F, I, L, N, P, T, U, V, W, X, Y, Z)
  static const _pieceNames = ['F', 'I', 'L', 'N', 'P', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

  /// Retourne les noms des pièces du puzzle
  List<String> get pieceNames => pieceIds.map((id) => _pieceNames[id - 1]).toList();

  /// Description lisible
  String get description =>
      '${size.label} avec ${pieceNames.join(", ")} ($solutionCount solution${solutionCount > 1 ? "s" : ""})';

  @override
  String toString() => 'PentoscopePuzzle($description)';
}

/// Générateur de puzzles Pentoscope
class PentoscopeGenerator {
  final Random _random;

  PentoscopeGenerator([Random? random]) : _random = random ?? Random();

  /// Génère un puzzle aléatoire pour une taille donnée
  PentoscopePuzzle generate(PentoscopeSize size) {
    final entries = pentoscopeData[size.dataIndex];
    if (entries == null || entries.isEmpty) {
      throw StateError('Aucune configuration disponible pour ${size.label}');
    }

    // Sélectionner une entrée au hasard
    final index = _random.nextInt(entries.length);
    final (bitmask, solutionCount) = entries[index];

    return PentoscopePuzzle(
      size: size,
      bitmask: bitmask,
      pieceIds: _bitmaskToIds(bitmask),
      solutionCount: solutionCount,
    );
  }

  /// Génère un puzzle en favorisant ceux avec plus de solutions (plus faciles)
  PentoscopePuzzle generateEasy(PentoscopeSize size) {
    final entries = pentoscopeData[size.dataIndex];
    if (entries == null || entries.isEmpty) {
      throw StateError('Aucune configuration disponible pour ${size.label}');
    }

    // Pondérer par le nombre de solutions
    final totalWeight = entries.fold<int>(0, (sum, e) => sum + e.$2);
    var target = _random.nextInt(totalWeight);

    for (final (bitmask, solutionCount) in entries) {
      target -= solutionCount;
      if (target < 0) {
        return PentoscopePuzzle(
          size: size,
          bitmask: bitmask,
          pieceIds: _bitmaskToIds(bitmask),
          solutionCount: solutionCount,
        );
      }
    }

    // Fallback (ne devrait pas arriver)
    return generate(size);
  }

  /// Génère un puzzle en favorisant ceux avec moins de solutions (plus durs)
  PentoscopePuzzle generateHard(PentoscopeSize size) {
    final entries = pentoscopeData[size.dataIndex];
    if (entries == null || entries.isEmpty) {
      throw StateError('Aucune configuration disponible pour ${size.label}');
    }

    // Inverser les poids (1/solutionCount)
    final weights = entries.map((e) => 1.0 / e.$2).toList();
    final totalWeight = weights.fold<double>(0, (sum, w) => sum + w);
    var target = _random.nextDouble() * totalWeight;

    for (int i = 0; i < entries.length; i++) {
      target -= weights[i];
      if (target < 0) {
        final (bitmask, solutionCount) = entries[i];
        return PentoscopePuzzle(
          size: size,
          bitmask: bitmask,
          pieceIds: _bitmaskToIds(bitmask),
          solutionCount: solutionCount,
        );
      }
    }

    // Fallback
    return generate(size);
  }

  /// Retourne toutes les configurations pour une taille
  List<PentoscopePuzzle> getAllForSize(PentoscopeSize size) {
    final entries = pentoscopeData[size.dataIndex] ?? [];
    return entries
        .map((e) => PentoscopePuzzle(
      size: size,
      bitmask: e.$1,
      pieceIds: _bitmaskToIds(e.$1),
      solutionCount: e.$2,
    ))
        .toList();
  }

  /// Statistiques pour une taille
  PentoscopeStats getStats(PentoscopeSize size) {
    final entries = pentoscopeData[size.dataIndex] ?? [];
    final totalSolutions = entries.fold<int>(0, (sum, e) => sum + e.$2);
    final minSolutions = entries.isEmpty ? 0 : entries.map((e) => e.$2).reduce(min);
    final maxSolutions = entries.isEmpty ? 0 : entries.map((e) => e.$2).reduce(max);

    return PentoscopeStats(
      size: size,
      configCount: entries.length,
      totalSolutions: totalSolutions,
      minSolutions: minSolutions,
      maxSolutions: maxSolutions,
    );
  }

  /// Convertit un bitmask en liste d'IDs de pièces
  List<int> _bitmaskToIds(int bitmask) {
    final ids = <int>[];
    for (int i = 0; i < 12; i++) {
      if (bitmask & (1 << i) != 0) {
        ids.add(i + 1);
      }
    }
    return ids;
  }
}

/// Statistiques pour une taille de plateau
class PentoscopeStats {
  final PentoscopeSize size;
  final int configCount;
  final int totalSolutions;
  final int minSolutions;
  final int maxSolutions;

  const PentoscopeStats({
    required this.size,
    required this.configCount,
    required this.totalSolutions,
    required this.minSolutions,
    required this.maxSolutions,
  });

  double get avgSolutions => configCount > 0 ? totalSolutions / configCount : 0;

  @override
  String toString() => '${size.label}: $configCount configs, '
      '$totalSolutions solutions (min=$minSolutions, max=$maxSolutions, avg=${avgSolutions.toStringAsFixed(1)})';
}