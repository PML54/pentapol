// lib/services/solution_matcher.dart
// Gestion des solutions de pentominos encodées en BigInt (360 bits).
//
// Chaque solution canonique est un BigInt construit ainsi :
//   acc = BigInt.zero;
//   for (code in boardBit6) { // 60 cases, code = bit6 (0..63)
//     acc = (acc << 6) | BigInt.from(code);
//   }
//
// Ici, on reçoit les 2339 solutions normalisées (une par classe de symétrie),
// puis on génère 4 variantes 6x10 :
//   - identité
//   - rotation 180°
//   - miroir horizontal
//   - miroir vertical
// -> au total ~9356 solutions utilisées pour la comparaison.

import 'package:flutter/foundation.dart';

class SolutionMatcher {
  /// Toutes les solutions utilisées (BigInt 360 bits chacune).
  late final List<BigInt> _solutions;

  bool _initialized = false;

  SolutionMatcher() {
    debugPrint('[SOLUTION_MATCHER] Créé (en attente d\'initialisation BigInt)...');
  }

  /// Initialise le matcher avec la liste des solutions canoniques (2339 BigInt).
  /// On génère ensuite en interne les 4 variantes 6x10 pour chaque solution.
  void initWithBigIntSolutions(List<BigInt> canonicalSolutions) {
    if (_initialized) {
      debugPrint('[SOLUTION_MATCHER] initWithBigIntSolutions déjà appelé, on ignore.');
      return;
    }

    final startTime = DateTime.now();

    final expanded = <BigInt>[];


    for (final canonical in canonicalSolutions) {


      // 1) Décoder le BigInt canonique vers 60 codes bit6
      final baseBoard = _decodeBigIntToBit6Board(canonical);

      // 2) Générer les 4 variantes 6x10
      final rot180 = _rotate180(baseBoard);
      final mirrorH = _mirrorHorizontal(baseBoard);
      final mirrorV = _mirrorVertical(baseBoard);

      // 3) Ré-encoder en BigInt (même convention que lors de l'encodage)
      expanded.add(_bit6BoardToBigInt(baseBoard));  // identité
      expanded.add(_bit6BoardToBigInt(rot180));     // rotation 180°
      expanded.add(_bit6BoardToBigInt(mirrorH));    // miroir horizontal
      expanded.add(_bit6BoardToBigInt(mirrorV));    // miroir vertical
    }

    _solutions = List<BigInt>.unmodifiable(expanded);
    _initialized = true;

    final duration = DateTime.now().difference(startTime);
    debugPrint(
      '[SOLUTION_MATCHER] ✓ ${canonicalSolutions.length} solutions canoniques '
          '→ ${_solutions.length} solutions BigInt générées en ${duration.inMilliseconds}ms',
    );
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'SolutionMatcher non initialisé.\n'
            'Appelle solutionMatcher.initWithBigIntSolutions(...) au démarrage.',
      );
    }
  }

  /// Nombre total de solutions chargées (devrait être ~9356).
  int get totalSolutions {
    if (!_initialized) return 0;
    return _solutions.length;
  }

  /// Accès en lecture à toutes les solutions (pour le navigateur).
  List<BigInt> get allSolutions {
    _checkInitialized();
    return _solutions;
  }

  // ─────────────────────────────────────────────
  // DÉCODAGE / ENCODAGE BigInt <-> 60 codes bit6
  // ─────────────────────────────────────────────

  static const int _cells = 60;
  static const int _bitMask = 0x3F; // 6 bits

  /// Decode un BigInt (360 bits) en liste de 60 codes bit6 (0..63).
  ///
  /// Convention : le BigInt a été construit en faisant:
  ///   acc = (acc << 6) | code; pour les cases 0..59.
  List<int> _decodeBigIntToBit6Board(BigInt value) {
    final board = List<int>.filled(_cells, 0);
    var v = value;

    // On lit en partant de la fin : case 59, 58, ..., 0
    for (int i = _cells - 1; i >= 0; i--) {
      final code = (v & BigInt.from(_bitMask)).toInt();
      board[i] = code;
      v = v >> 6;
    }

    return board;
  }

  /// Encode une liste de 60 codes bit6 (0..63) vers un BigInt 360 bits.
  BigInt _bit6BoardToBigInt(List<int> boardBit6) {
    if (boardBit6.length != _cells) {
      throw ArgumentError('Un plateau doit avoir exactement $_cells cases.');
    }

    BigInt acc = BigInt.zero;
    for (final code in boardBit6) {
      acc = (acc << 6) | BigInt.from(code);
    }
    return acc;
  }

  // ─────────────────────────────────────────────
  // TRANSFORMATIONS 6x10 (sur la grille de 60 codes)
  // ─────────────────────────────────────────────

  /// Rotation 180° sur un plateau 6x10 (indices 0..59).
  List<int> _rotate180(List<int> grid) {
    final rotated = List<int>.filled(_cells, 0);
    for (int i = 0; i < _cells; i++) {
      rotated[i] = grid[_cells - 1 - i];
    }
    return rotated;
  }

  /// Miroir horizontal (gauche-droite) sur un plateau 6x10.
  List<int> _mirrorHorizontal(List<int> grid) {
    const width = 6;
    const height = 10;
    final mirrored = List<int>.filled(_cells, 0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final srcIndex = y * width + x;
        final dstIndex = y * width + (width - 1 - x);
        mirrored[dstIndex] = grid[srcIndex];
      }
    }
    return mirrored;
  }

  /// Miroir vertical (haut-bas) sur un plateau 6x10.
  List<int> _mirrorVertical(List<int> grid) {
    const width = 6;
    const height = 10;
    final mirrored = List<int>.filled(_cells, 0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final srcIndex = y * width + x;
        final dstIndex = (height - 1 - y) * width + x;
        mirrored[dstIndex] = grid[srcIndex];
      }
    }
    return mirrored;
  }

  // ─────────────────────────────────────────────
  // COMPATIBILITÉ 100% BigInt
  // ─────────────────────────────────────────────

  /// Vérifie la compatibilité d'une solution [solution]
  /// avec un plateau défini par [piecesBits] et [maskBits].
  ///
  /// piecesBits : codes bit6 (0 si vide)
  /// maskBits   : 0x3F (6 bits à 1) pour case occupée, 0 sinon
  ///
  /// Compatibilité :
  ///   (solution & maskBits) == piecesBits
  bool _isCompatibleBigInt(BigInt piecesBits, BigInt maskBits, BigInt solution) {
    return (solution & maskBits) == piecesBits;
  }

  /// Compte les solutions compatibles pour un plateau donné.
  int countCompatibleFromBigInts(BigInt piecesBits, BigInt maskBits) {
    _checkInitialized();
    int count = 0;
    for (final solution in _solutions) {
      if (_isCompatibleBigInt(piecesBits, maskBits, solution)) {
        count++;
      }
    }
    return count;
  }

  /// Retourne la liste des solutions compatibles (pour debug / navigateur).
  List<BigInt> getCompatibleSolutionsFromBigInts(
      BigInt piecesBits,
      BigInt maskBits,
      ) {
    _checkInitialized();
    final out = <BigInt>[];
    for (final solution in _solutions) {
      if (_isCompatibleBigInt(piecesBits, maskBits, solution)) {
        out.add(solution);
      }
    }
    return out;
  }
}

/// Singleton global pour éviter de recharger les solutions.
final solutionMatcher = SolutionMatcher();
