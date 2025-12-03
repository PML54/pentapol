// lib/duel_isometry/screens/duel_isometry_screen.dart
// VERSION AVEC DEBUG AMÉLIORÉ POUR SIMULATEUR
// Le seul changement : _tryPlacePiece a des logs plus détaillés

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/config/game_icons_config.dart';

import '../providers/duel_isometry_provider.dart';
import '../models/duel_isometry_state.dart';
import '../widgets/duel_isometry_countdown.dart';
import 'duel_isometry_result_screen.dart';

// Importer les utilitaires d'isométrie
import '../services/isometry_puzzle.dart';

/// Constantes pour le slider
class DuelIsometrySliderConstants {
  static const double itemSize = 90.0;
  static const int itemsPerPage = 100;
}

/// Palette DUEL : 12 couleurs VIVES et SATURÉES
Color _getDuelColor(int pieceId) {
  const colors = [
    Color(0xFFD32F2F), // 1  - ROUGE vif
    Color(0xFF388E3C), // 2  - VERT franc
    Color(0xFF1976D2), // 3  - BLEU roi
    Color(0xFFFFC107), // 4  - JAUNE OR
    Color(0xFFE64A19), // 5  - ORANGE brûlé
    Color(0xFF7B1FA2), // 6  - VIOLET profond
    Color(0xFF0097A7), // 7  - CYAN foncé
    Color(0xFFC2185B), // 8  - MAGENTA
    Color(0xFF5D4037), // 9  - MARRON chocolat
    Color(0xFF689F38), // 10 - VERT OLIVE
    Color(0xFF512DA8), // 11 - VIOLET INDIGO
    Color(0xFF455A64), // 12 - GRIS BLEU foncé
  ];
  return colors[(pieceId - 1) % colors.length];
}

class DuelIsometryScreen extends ConsumerStatefulWidget {
  const DuelIsometryScreen({super.key});

  @override
  ConsumerState<DuelIsometryScreen> createState() => _DuelIsometryScreenState();
}

class _DuelIsometryScreenState extends ConsumerState<DuelIsometryScreen> {
  // Pièce sélectionnée dans le slider
  Pento? _selectedPiece;
  int _selectedPositionIndex = 0;

  // Preview sur le plateau
  int? _previewX;
  int? _previewY;

  // Controllers
  final ScrollController _sliderController = ScrollController(keepScrollOffset: true);
  bool _sliderInitialized = false;
  final GlobalKey _sliderKey = GlobalKey();

  // État des pièces (isométries appliquées)
  final Map<int, int> _piecePositionIndices = {};

  // Compteur d'isométries du joueur
  int _totalIsometries = 0;

  // Chronomètre local
  int _elapsedMs = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // Charger le puzzle et initialiser les positions des pièces avec les orientations INITIALES
    final state = ref.read(duelIsometryProvider);
    if (state.puzzle != null) {
      for (final piece in state.puzzle!.pieces) {
        _piecePositionIndices[piece.pieceId] = piece.initialPositionIndex;
      }
    }
  }

  /// Initialise la position du slider après le countdown
  void _initializeSliderPosition() {
    if (_sliderInitialized) return;
    _sliderInitialized = true;

    if (_sliderController.hasClients && mounted) {
      final totalItems = 12 * DuelIsometrySliderConstants.itemsPerPage;
      final middleOffset = (totalItems / 2) * DuelIsometrySliderConstants.itemSize;
      _sliderController.jumpTo(middleOffset);
    }
  }

  // ============================================================
  // ISOMÉTRIES - Comptabilisées
  // ============================================================

  void _rotateCounterClockwise() {
    if (_selectedPiece == null) return;
    final newIndex = _selectedPiece!.findRotation90(_selectedPositionIndex);
    if (newIndex != -1) {
      setState(() {
        _selectedPositionIndex = newIndex;
        _piecePositionIndices[_selectedPiece!.id] = newIndex;
        _totalIsometries++;
      });
      _notifyIsometryChange();
      HapticFeedback.selectionClick();
    }
  }

  void _rotateClockwise() {
    if (_selectedPiece == null) return;
    int newIndex = _selectedPositionIndex;
    for (int i = 0; i < 3; i++) {
      final next = _selectedPiece!.findRotation90(newIndex);
      if (next != -1) newIndex = next;
    }
    if (newIndex != _selectedPositionIndex) {
      setState(() {
        _selectedPositionIndex = newIndex;
        _piecePositionIndices[_selectedPiece!.id] = newIndex;
        _totalIsometries++;
      });
      _notifyIsometryChange();
      HapticFeedback.selectionClick();
    }
  }

  void _flipHorizontal() {
    if (_selectedPiece == null) return;
    final newIndex = _selectedPiece!.findSymmetryH(_selectedPositionIndex);
    if (newIndex != -1) {
      setState(() {
        _selectedPositionIndex = newIndex;
        _piecePositionIndices[_selectedPiece!.id] = newIndex;
        _totalIsometries++;
      });
      _notifyIsometryChange();
      HapticFeedback.selectionClick();
    }
  }

  void _flipVertical() {
    if (_selectedPiece == null) return;
    final newIndex = _selectedPiece!.findSymmetryV(_selectedPositionIndex);
    if (newIndex != -1) {
      setState(() {
        _selectedPositionIndex = newIndex;
        _piecePositionIndices[_selectedPiece!.id] = newIndex;
        _totalIsometries++;
      });
      _notifyIsometryChange();
      HapticFeedback.selectionClick();
    }
  }

  /// Notifie le provider du changement d'isométrie (pour sync adversaire)
  void _notifyIsometryChange() {
    ref.read(duelIsometryProvider.notifier).updateLocalProgress(
      placedPieces: _countCorrectlyPlacedPieces(),
      isometryCount: _totalIsometries,
    );
  }

  /// Compte les pièces correctement placées ET orientées
  int _countCorrectlyPlacedPieces() {
    final state = ref.read(duelIsometryProvider);
    int count = 0;
    for (final placed in state.placedPieces) {
      final target = state.puzzle?.pieces.firstWhere(
            (p) => p.pieceId == placed.pieceId,
        orElse: () => throw StateError('Pièce non trouvée'),
      );
      if (target != null &&
          placed.gridX == target.targetGridX &&
          placed.gridY == target.targetGridY &&
          placed.positionIndex == target.targetPositionIndex) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelIsometryProvider);
    final settings = ref.watch(settingsProvider);

    // Écouter les changements d'état
    ref.listen<DuelIsometryState>(duelIsometryProvider, (previous, next) {
      print('[LISTENER] État changé: ${previous?.gameState} → ${next.gameState}');

      // Initialiser le slider quand le jeu commence
      if (next.gameState == DuelIsometryGameState.playing &&
          previous?.gameState != DuelIsometryGameState.playing) {
        print('[LISTENER] Jeu commence!');
        _startTime = DateTime.now();
        Future.delayed(const Duration(milliseconds: 200), () {
          _initializeSliderPosition();
        });
      }

      // Naviguer vers les résultats quand le round est terminé
      if (next.gameState == DuelIsometryGameState.roundEnded &&
          previous?.gameState != DuelIsometryGameState.roundEnded) {
        print('[LISTENER] Round terminé!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DuelIsometryResultScreen()),
        );
      }
    });

    // Afficher l'écran d'attente si on attend un adversaire
    if (state.gameState == DuelIsometryGameState.waiting) {
      return _buildWaitingScreen(state);
    }

    return WillPopScope(
      onWillPop: () async {
        _showLeaveConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _showLeaveConfirmation,
            tooltip: 'Quitter',
          ),
          title: _buildScoreTitle(state),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Message d'erreur
                  if (state.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.shade100,
                      child: Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),

                  // === PLATEAU DE JEU === (espace max pour voir les pièces)
                  Expanded(
                    child: _buildGameBoard(context, ref, state, settings),
                  ),

                  // === BARRE D'ISOMÉTRIES ===
                  Container(
                    height: 44,
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.white,
                    child: _selectedPiece != null
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildIsometryButton(
                          icon: GameIcons.isometryRotation.icon,
                          color: GameIcons.isometryRotation.color,
                          onPressed: _rotateCounterClockwise,
                          tooltip: 'Rotation ↺',
                        ),
                        _buildIsometryButton(
                          icon: GameIcons.isometryRotationCW.icon,
                          color: GameIcons.isometryRotationCW.color,
                          onPressed: _rotateClockwise,
                          tooltip: 'Rotation ↻',
                        ),
                        _buildIsometryButton(
                          icon: GameIcons.isometrySymmetryH.icon,
                          color: GameIcons.isometrySymmetryH.color,
                          onPressed: _flipHorizontal,
                          tooltip: 'Symétrie ↔',
                        ),
                        _buildIsometryButton(
                          icon: GameIcons.isometrySymmetryV.icon,
                          color: GameIcons.isometrySymmetryV.color,
                          onPressed: _flipVertical,
                          tooltip: 'Symétrie ↕',
                        ),
                      ],
                    )
                        : const Center(
                      child: Text(
                        'Sélectionnez une pièce',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),

                  // === SLIDER DES PIÈCES ===
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: _buildPieceSlider(context, ref, state, settings),
                  ),
                ],
              ),

              // Countdown
              if (state.gameState == DuelIsometryGameState.countdown &&
                  state.countdown != null)
                DuelIsometryCountdown(value: state.countdown!),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TITRE AVEC SCORES ET SUIVI LIVE
  // ============================================================

  Widget _buildScoreTitle(DuelIsometryState state) {
    final timeElapsed = state.elapsedTime ?? 0;
    final minutes = timeElapsed ~/ 60;
    final seconds = timeElapsed % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    final localName = state.localPlayer?.name ?? 'Moi';
    final opponentName = state.opponent?.name ?? 'Adv';

    final totalPieces = state.puzzle?.pieceCount ?? 0;
    final localPlaced = _countCorrectlyPlacedPieces();
    final opponentPlaced = state.opponentPlacedPieces;
    final opponentIso = state.opponentIsometries;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.black, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // === MOI ===
          _buildPlayerProgress(
            name: localName,
            placed: localPlaced,
            total: totalPieces,
            isometries: _totalIsometries,
            color: Colors.cyan,
            isLocal: true,
          ),

          // === TIMER ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ),

          // === ADVERSAIRE ===
          _buildPlayerProgress(
            name: opponentName,
            placed: opponentPlaced,
            total: totalPieces,
            isometries: opponentIso,
            color: Colors.orange,
            isLocal: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerProgress({
    required String name,
    required int placed,
    required int total,
    required int isometries,
    required Color color,
    required bool isLocal,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nom
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocal)
              const Padding(
                padding: EdgeInsets.only(right: 2),
                child: Icon(Icons.person, size: 10, color: Colors.green),
              ),
            Text(
              name.length > 5 ? '${name.substring(0, 4)}.' : name,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),

        // Progression pièces (carrés)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(total, (i) {
            final isFilled = i < placed;
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isFilled ? color : Colors.transparent,
                border: Border.all(color: color, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),

        // Isométries
        Text(
          'Iso: $isometries',
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLATEAU DE JEU
  // ============================================================

  /// Vérifie si une pièce peut être placée à une position donnée
  bool _canPlacePieceAt(
      Pento piece,
      int positionIndex,
      int gridX,
      int gridY,
      DuelIsometryState state,
      ) {
    if (state.puzzle == null) return false;

    final puzzle = state.puzzle!;
    final position = piece.positions[positionIndex % piece.numPositions];

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      final x = gridX + localX;
      final y = gridY + localY;

      // Hors limites ?
      if (x < 0 || x >= puzzle.width || y < 0 || y >= puzzle.height) {
        return false;
      }

      // Case déjà occupée par une autre pièce ?
      for (final placed in state.placedPieces) {
        if (_isPieceAtCell(placed, x, y, puzzle)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Cherche la position valide la plus proche dans un rayon donné
  _SnapResult? _findNearestValidPosition(
      Pento piece,
      int positionIndex,
      int anchorX,
      int anchorY,
      DuelIsometryState state,
      ) {
    if (state.puzzle == null) return null;

    const int snapRadius = 3;
    _SnapResult? best;
    double bestDistanceSquared = double.infinity;

    for (int dx = -snapRadius; dx <= snapRadius; dx++) {
      for (int dy = -snapRadius; dy <= snapRadius; dy++) {
        final testX = anchorX + dx;
        final testY = anchorY + dy;

        if (_canPlacePieceAt(piece, positionIndex, testX, testY, state)) {
          final distanceSquared = (dx * dx + dy * dy).toDouble();

          if (distanceSquared < bestDistanceSquared) {
            bestDistanceSquared = distanceSquared;
            best = _SnapResult(testX, testY);
          }
        }
      }
    }

    return best;
  }

  Widget _buildGameBoard(BuildContext context, WidgetRef ref, DuelIsometryState state, settings) {
    if (state.puzzle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final puzzle = state.puzzle!;
    final visualCols = puzzle.width;
    final visualRows = puzzle.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth / visualCols)
            .clamp(0.0, constraints.maxHeight / visualRows)
            .toDouble();

        return Center(
          child: Container(
            width: cellSize * visualCols,
            height: cellSize * visualRows,
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DragTarget<Pento>(
                onWillAcceptWithDetails: (details) => true,
                onMove: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final offset = renderBox.globalToLocal(details.offset);
                  final rawX = (offset.dx / cellSize).floor();
                  final rawY = (offset.dy / cellSize).floor();

                  // Appliquer le snap intelligent
                  if (_selectedPiece != null) {
                    final snapped = _findNearestValidPosition(
                      _selectedPiece!,
                      _selectedPositionIndex,
                      rawX,
                      rawY,
                      state,
                    );

                    if (snapped != null) {
                      setState(() {
                        _previewX = snapped.x;
                        _previewY = snapped.y;
                      });
                    } else {
                      // Pas de position valide proche
                      setState(() {
                        _previewX = null;
                        _previewY = null;
                      });
                    }
                  }
                },
                onLeave: (data) {
                  setState(() {
                    _previewX = null;
                    _previewY = null;
                  });
                },
                onAcceptWithDetails: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final offset = renderBox.globalToLocal(details.offset);
                  final rawX = (offset.dx / cellSize).floor();
                  final rawY = (offset.dy / cellSize).floor();

                  // Chercher la position valide la plus proche
                  if (_selectedPiece != null) {
                    final snapped = _findNearestValidPosition(
                      _selectedPiece!,
                      _selectedPositionIndex,
                      rawX,
                      rawY,
                      state,
                    );

                    if (snapped != null) {
                      _tryPlacePiece(ref, state, snapped.x, snapped.y);
                    }
                  }

                  setState(() {
                    _previewX = null;
                    _previewY = null;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: visualCols,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: visualCols * visualRows,
                    itemBuilder: (context, index) {
                      final x = index % visualCols;
                      final y = index ~/ visualCols;
                      return _buildCell(context, ref, state, x, y, cellSize);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CELLULE DU PLATEAU
  // ============================================================

  Widget _buildCell(
      BuildContext context,
      WidgetRef ref,
      DuelIsometryState state,
      int x,
      int y,
      double cellSize,
      ) {
    final puzzle = state.puzzle!;
    final targetPieceId = puzzle.targetGrid[y][x];

    // Pièce placée ?
    DuelIsometryPlacedPiece? placedPiece;
    for (final piece in state.placedPieces) {
      if (_isPieceAtCell(piece, x, y, puzzle)) {
        placedPiece = piece;
        break;
      }
    }

    // Preview ?
    bool isPreview = false;
    bool previewIsCorrect = false;
    if (_selectedPiece != null && _previewX != null && _previewY != null) {
      if (_isPiecePreviewAtCell(_selectedPiece!, _selectedPositionIndex, _previewX!, _previewY!, x, y)) {
        isPreview = true;

        // Vérifier si la preview correspond à la cible (position ET orientation)
        final target = puzzle.pieces.firstWhere(
              (p) => p.pieceId == _selectedPiece!.id,
          orElse: () => puzzle.pieces.first,
        );
        previewIsCorrect = (targetPieceId == _selectedPiece!.id) &&
            (_previewX == target.targetGridX) &&
            (_previewY == target.targetGridY) &&
            (_selectedPositionIndex == target.targetPositionIndex);
      }
    }

    // === COULEURS ET STYLE ===
    Color cellColor;
    Color borderColor;
    double borderWidth;

    if (placedPiece != null) {
      // PIÈCE PLACÉE
      final isCorrect = _isPieceCorrectlyPlaced(placedPiece, puzzle);
      cellColor = _getDuelColor(placedPiece.pieceId);
      borderColor = isCorrect ? Colors.green : Colors.orange;
      borderWidth = isCorrect ? 2.5 : 1.5;
    } else if (isPreview) {
      // PREVIEW
      cellColor = _getDuelColor(_selectedPiece!.id).withOpacity(0.7);
      borderColor = previewIsCorrect ? Colors.green : Colors.orange;
      borderWidth = 3.0;
    } else if (targetPieceId > 0) {
      // GUIDE CIBLE (fantôme) - COULEURS VIVES ET CONTOURS ÉPAIS
      cellColor = _getDuelColor(targetPieceId).withOpacity(0.6);
      borderColor = Colors.black87;
      borderWidth = 2.5;
    } else {
      // CASE VIDE
      cellColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade400;
      borderWidth = 0.5;
    }

    return GestureDetector(
      onTap: () {
        if (_selectedPiece != null && targetPieceId == _selectedPiece!.id && placedPiece == null) {
          // Placement par tap sur la zone cible
          final target = puzzle.pieces.firstWhere((p) => p.pieceId == _selectedPiece!.id);
          _tryPlacePiece(ref, state, target.targetGridX, target.targetGridY);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
      ),
    );
  }

  bool _isPieceAtCell(DuelIsometryPlacedPiece placed, int x, int y, IsometryPuzzle puzzle) {
    final piece = pentominos.firstWhere((p) => p.id == placed.pieceId);
    final safeIndex = placed.positionIndex % piece.positions.length;
    final position = piece.positions[safeIndex];

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (placed.gridX + localX == x && placed.gridY + localY == y) {
        return true;
      }
    }
    return false;
  }

  bool _isPiecePreviewAtCell(Pento piece, int posIndex, int anchorX, int anchorY, int cellX, int cellY) {
    final safeIndex = posIndex % piece.positions.length;
    final position = piece.positions[safeIndex];
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (anchorX + localX == cellX && anchorY + localY == cellY) {
        return true;
      }
    }
    return false;
  }

  bool _isPieceCorrectlyPlaced(DuelIsometryPlacedPiece placed, IsometryPuzzle puzzle) {
    final target = puzzle.pieces.firstWhere(
          (p) => p.pieceId == placed.pieceId,
      orElse: () => puzzle.pieces.first,
    );
    return placed.gridX == target.targetGridX &&
        placed.gridY == target.targetGridY &&
        placed.positionIndex == target.targetPositionIndex;
  }

  // ============================================================
  // PLACEMENT DE PIÈCE
  // ============================================================

  void _tryPlacePiece(WidgetRef ref, DuelIsometryState state, int x, int y) {
    if (_selectedPiece == null) {
      print('[PLACE] ❌ _selectedPiece est NULL!');
      return;
    }

    final puzzle = state.puzzle!;
    final target = puzzle.pieces.firstWhere(
          (p) => p.pieceId == _selectedPiece!.id,
      orElse: () => puzzle.pieces.first,
    );

    final isCorrectPosition = (x == target.targetGridX && y == target.targetGridY);
    final isCorrectOrientation = (_selectedPositionIndex == target.targetPositionIndex);

    // 🔴 DEBUG AMÉLIORÉ
    print('═' * 60);
    print('[PLACE] Tentative placement pièce ${_selectedPiece!.id}');
    print('[PLACE] Position snappée: ($x, $y)  |  Cible: (${target.targetGridX}, ${target.targetGridY})');
    print('[PLACE] Orientation: $_selectedPositionIndex  |  Cible: ${target.targetPositionIndex}');
    print('[PLACE] Position OK: $isCorrectPosition | Orientation OK: $isCorrectOrientation');
    print('═' * 60);

    if (!isCorrectPosition || !isCorrectOrientation) {
      // Placement refusé
      print('[PLACE] ❌ Placement refusé');
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isCorrectPosition
                ? 'Mauvaise position ! (reçu: $x,$y vs attendu: ${target.targetGridX},${target.targetGridY})'
                : 'Mauvaise orientation ! (reçu: $_selectedPositionIndex vs attendu: ${target.targetPositionIndex})',
          ),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Placement accepté ✅
    print('[PLACE] ✅ PLACEMENT ACCEPTÉ');
    print('[PLACE] Avant: ${state.placedPieces.length} pièces');

    ref.read(duelIsometryProvider.notifier).placePiece(
      pieceId: _selectedPiece!.id,
      gridX: x,
      gridY: y,
      positionIndex: _selectedPositionIndex,
    );

    print('[PLACE] ✅ placePiece() appelé');
    print('[PLACE] État après: (state n\'est pas mis à jour immédiatement)');

    // Vérifier si puzzle complet
    final newPlacedCount = state.placedPieces.length + 1;
    print('[PLACE] Pièces: ${state.placedPieces.length} → $newPlacedCount / ${puzzle.pieceCount}');

    if (newPlacedCount == puzzle.pieceCount) {
      print('[PLACE] 🎉 PUZZLE COMPLET!');
      final elapsedMs = DateTime.now().difference(_startTime!).inMilliseconds;
      ref.read(duelIsometryProvider.notifier).completePuzzle(
        totalIsometries: _totalIsometries,
        timeMs: elapsedMs,
      );
    }

    print('[PLACE] Appel _notifyIsometryChange()');
    _notifyIsometryChange();

    HapticFeedback.mediumImpact();
    print('[PLACE] Appel setState()');
    setState(() {
      _selectedPiece = null;
    });

    print('[PLACE] ✅ setState() complété');
  }

  // ============================================================
  // SLIDER DES PIÈCES
  // ============================================================

  Widget _buildPieceSlider(BuildContext context, WidgetRef ref, DuelIsometryState state, settings) {
    if (state.puzzle == null) return const SizedBox();

    final puzzle = state.puzzle!;

    final placedIds = state.placedPieces.map((p) => p.pieceId).toSet();
    final puzzlePieceIds = puzzle.pieces.map((p) => p.pieceId).toSet();
    final availablePieces = pentominos
        .where((p) => puzzlePieceIds.contains(p.id) && !placedIds.contains(p.id))
        .toList();

    if (availablePieces.isEmpty) {
      return const Center(
        child: Text(
          '🎉 Toutes les pièces placées !',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    final useInfiniteScroll = availablePieces.length >= 4;
    final totalItems = useInfiniteScroll
        ? availablePieces.length * DuelIsometrySliderConstants.itemsPerPage
        : availablePieces.length;

    return ListView.builder(
      key: _sliderKey,
      controller: useInfiniteScroll ? _sliderController : null,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        final pieceIndex = index % availablePieces.length;
        final piece = availablePieces[pieceIndex];
        return _buildDraggablePieceItem(piece, state, settings);
      },
    );
  }

  /// Élément draggable du slider
  Widget _buildDraggablePieceItem(Pento piece, DuelIsometryState state, settings) {
    final isSelected = _selectedPiece?.id == piece.id;
    final positionIndex = isSelected
        ? _selectedPositionIndex
        : (_piecePositionIndices[piece.id] ?? 0);

    final pieceContainer = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.amber.shade700 : Colors.grey.shade400,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _getDuelColor(piece.id),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              piece.id.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildPieceWidget(piece, positionIndex),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: LongPressDraggable<Pento>(
        data: piece,
        delay: const Duration(milliseconds: 150),
        hapticFeedbackOnStart: true,
        onDragStarted: () {
          setState(() {
            _selectedPiece = piece;
            _selectedPositionIndex = _piecePositionIndices[piece.id] ?? 0;
          });
        },
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.2,
            child: _buildPieceWidget(piece, positionIndex, isDragging: true),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: pieceContainer),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) {
                  _selectedPositionIndex = (_selectedPositionIndex + 1) % piece.numPositions;
                  _piecePositionIndices[piece.id] = _selectedPositionIndex;
                } else {
                  _selectedPiece = piece;
                  _selectedPositionIndex = _piecePositionIndices[piece.id] ?? 0;
                }
              });
            },
            onDoubleTap: () {
              HapticFeedback.mediumImpact();
            },
            onLongPress: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedPiece = null;
              });
            },
            child: pieceContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildPieceWidget(Pento piece, int positionIndex, {bool isDragging = false}) {
    final position = piece.positions[positionIndex % piece.numPositions];
    final color = _getDuelColor(piece.id);

    int minX = 5, maxX = 0, minY = 5, maxY = 0;
    for (final cellNum in position) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    final width = maxX - minX + 1;
    final height = maxY - minY + 1;
    const cellSize = 18.0;

    return SizedBox(
      width: width * cellSize,
      height: height * cellSize,
      child: Stack(
        children: position.map((cellNum) {
          final x = (cellNum - 1) % 5 - minX;
          final y = (cellNum - 1) ~/ 5 - minY;

          return Positioned(
            left: x * cellSize,
            top: y * cellSize,
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: isDragging ? color.withOpacity(0.9) : color,
                border: Border.all(
                  color: Colors.black,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildIsometryButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 28),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 24,
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text('Vous abandonnerez le round en cours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(duelIsometryProvider.notifier).leaveRoom();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen(DuelIsometryState state) {
    final roomCode = state.roomCode ?? '----';
    final hasOpponent = state.opponent != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel Isométries'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(duelIsometryProvider.notifier).leaveRoom();
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rotate_90_degrees_ccw, size: 64, color: Colors.purple.shade400),
              const SizedBox(height: 24),
              const Text(
                'CODE DE LA PARTIE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      roomCode,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.purple),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: roomCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copié !'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              if (!hasOpponent) ...[
                const CircularProgressIndicator(color: Colors.purple),
                const SizedBox(height: 24),
                const Text(
                  'En attente d\'un adversaire...',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Partagez le code ci-dessus',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  '${state.opponent!.name} a rejoint !',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('La partie va commencer...'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Helper pour le snap
class _SnapResult {
  final int x, y;
  const _SnapResult(this.x, this.y);
}