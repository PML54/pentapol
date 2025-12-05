// lib/duel/services/duel_validator.dart
// Validation des placements contre une solution spécifique
// CORRIGÉ : conversion bit6 → pieceId, sans late

import 'package:pentapol/models/pentominos.dart';

/// Résultat de validation d'un placement
class PlacementValidation {
  final bool isValid;
  final String? errorMessage;

  const PlacementValidation.valid() : isValid = true, errorMessage = null;
  const PlacementValidation.invalid(this.errorMessage) : isValid = false;
}

/// Service de validation des placements pour le mode Duel
class DuelIsometryValidator {
  static final DuelIsometryValidator instance = DuelIsometryValidator._();

  DuelIsometryValidator._() {
    // Construire la map bit6 → pieceId au démarrage
    _buildBit6Map();
  }

  /// Grille de la solution (6x10) - pieceId (1-12) par cellule
  List<List<int>>? _solutionGrid;
  int? _currentSolutionId;
  List<BigInt>? _solutions;

  /// Map de conversion bit6 → pieceId (initialisée dans le constructeur)
  Map<int, int> _bit6ToPieceId = {};

  /// Construit la map de conversion bit6 → pieceId
  void _buildBit6Map() {
    _bit6ToPieceId = {};
    for (final pento in pentominos) {
      _bit6ToPieceId[pento.bit6] = pento.id;
    }
    print('[VALIDATOR] Map bit6→pieceId construite: $_bit6ToPieceId');
  }

  void initialize(List<BigInt> solutions) {
    _solutions = solutions;
    print('[VALIDATOR] ✅ Initialisé avec ${solutions.length} solutions');
  }

  /// Convertit un bit6 en pieceId
  int _bit6ToPiece(int bit6) {
    return _bit6ToPieceId[bit6] ?? 0;
  }

  /// Charge une solution et la décode en grille
  Future<bool> loadSolution(int solutionId) async {
    if (_currentSolutionId == solutionId && _solutionGrid != null) {
      print('[VALIDATOR] Solution #$solutionId déjà chargée');
      return true;
    }

    print('[VALIDATOR] Chargement solution #$solutionId...');

    if (_solutions == null || _solutions!.isEmpty) {
      print('[VALIDATOR] ❌ Solutions non initialisées !');
      return false;
    }

    if (solutionId < 1 || solutionId > _solutions!.length) {
      print('[VALIDATOR] ❌ Solution #$solutionId hors limites (1-${_solutions!.length})');
      return false;
    }

    try {
      final solutionBigInt = _solutions![solutionId - 1];
      _solutionGrid = _decodeBigIntToGrid(solutionBigInt);
      _currentSolutionId = solutionId;

      // Debug : afficher la grille avec pieceId
      print('[VALIDATOR] ✅ Solution #$solutionId décodée (pieceId 1-12) :');
      _printGrid();

      return true;
    } catch (e) {
      print('[VALIDATOR] ❌ Erreur: $e');
      return false;
    }
  }

  /// Décode un BigInt en grille 6x10 avec conversion bit6 → pieceId
  List<List<int>> _decodeBigIntToGrid(BigInt solution) {
    final grid = List.generate(10, (_) => List.filled(6, 0));

    BigInt remaining = solution;
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 6; x++) {
        final bit6 = (remaining & BigInt.from(0x3F)).toInt();
        // ✅ CONVERSION bit6 → pieceId
        final pieceId = _bit6ToPiece(bit6);
        grid[y][x] = pieceId;
        remaining = remaining >> 6;
      }
    }

    return grid;
  }

  /// Affiche la grille pour debug
  void _printGrid() {
    if (_solutionGrid == null) return;

    print('   0  1  2  3  4  5');
    for (int y = 0; y < 10; y++) {
      final row = _solutionGrid![y].map((v) => v.toString().padLeft(2)).join(' ');
      print('$y: $row');
    }

    // Vérifier que toutes les pièces sont présentes
    final foundPieces = <int>{};
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 6; x++) {
        final pieceId = _solutionGrid![y][x];
        if (pieceId > 0) foundPieces.add(pieceId);
      }
    }
    print('[VALIDATOR] Pièces trouvées: ${foundPieces.toList()..sort()}');
  }

  /// Retourne la grille de la solution
  List<List<int>>? get solutionGrid => _solutionGrid;

  int? get currentSolutionId => _currentSolutionId;

  /// Valide un placement
  PlacementValidation validatePlacement({
    required int pieceId,
    required int x,
    required int y,
    required int orientation,
  }) {
    if (_solutionGrid == null) {
      print('[VALIDATOR] ❌ Grille non chargée');
      return const PlacementValidation.invalid('Solution non chargée');
    }

    print('[VALIDATOR] 🔍 Validation pièce $pieceId en ($x, $y) orientation $orientation');

    // Récupérer la forme de la pièce
    final pento = pentominos.firstWhere(
          (p) => p.id == pieceId,
      orElse: () => pentominos.first,
    );

    if (pento.id != pieceId) {
      print('[VALIDATOR] ❌ Pièce $pieceId non trouvée');
      return const PlacementValidation.invalid('Pièce non trouvée');
    }

    final position = pento.positions[orientation % pento.numPositions];

    // Calculer les cellules occupées par la pièce
    final occupiedCells = <_Point>[];
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      final cellX = x + localX;
      final cellY = y + localY;
      occupiedCells.add(_Point(cellX, cellY));
    }

    print('[VALIDATOR]   Cellules: ${occupiedCells.map((c) => "(${c.x},${c.y})").join(", ")}');

    // Vérifier que TOUTES les cellules correspondent à pieceId dans la solution
    for (final cell in occupiedCells) {
      // Hors limites ?
      if (cell.x < 0 || cell.x >= 6 || cell.y < 0 || cell.y >= 10) {
        print('[VALIDATOR] ❌ Cellule (${cell.x}, ${cell.y}) hors limites');
        return const PlacementValidation.invalid('Hors du plateau');
      }

      // Vérifier la solution
      final expectedPieceId = _solutionGrid![cell.y][cell.x];

      if (expectedPieceId != pieceId) {
        print('[VALIDATOR] ❌ Cellule (${cell.x}, ${cell.y}): attendu=$expectedPieceId, placé=$pieceId');
        return PlacementValidation.invalid('Mauvaise position');
      }
    }

    print('[VALIDATOR] ✅ Placement VALIDE !');
    return const PlacementValidation.valid();
  }

  void reset() {
    _solutionGrid = null;
    _currentSolutionId = null;
  }
}

class _Point {
  final int x, y;
  const _Point(this.x, this.y);
}