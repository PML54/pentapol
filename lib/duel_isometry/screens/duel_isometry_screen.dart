// lib/duel_isometry/screens/duel_isometry_screen.dart
// Écran principal du jeu Duel Isométries
// Mode : Reconstruire une configuration cible en appliquant les bonnes isométries
// Scoring : Moins d'isométries gagne, égalité = plus rapide gagne

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
    // Charger le puzzle et initialiser les positions des pièces
    final state = ref.read(duelIsometryProvider);
    if (state.puzzle != null) {
      for (final piece in state.puzzle!.pieces) {
        _piecePositionIndices[piece.pieceId] = piece.initialPositionIndex;
      }
    }
  }

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
        _totalIsometries++; // Comptabiliser
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
        _totalIsometries++; // Comptabiliser
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
        _totalIsometries++; // Comptabiliser
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
        _totalIsometries++; // Comptabiliser
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
      // Initialiser le slider quand le jeu commence
      if (next.gameState == DuelIsometryGameState.playing &&
          previous?.gameState != DuelIsometryGameState.playing) {
        _startTime = DateTime.now();
        Future.delayed(const Duration(milliseconds: 200), () {
          _initializeSliderPosition();
        });
      }

      // Naviguer vers les résultats quand le round est terminé
      if (next.gameState == DuelIsometryGameState.roundEnded &&
          previous?.gameState != DuelIsometryGameState.roundEnded) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DuelIsometryResultScreen()),
        );
      }
    });

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

                  // === CIBLE EN MINIATURE ===
                  if (state.puzzle != null)
                    Container(
                      height: 100,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Miniature de la cible
                          Expanded(
                            flex: 2,
                            child: _buildTargetPreview(state),
                          ),
                          // Indicateur "CIBLE"
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flag, color: Colors.green, size: 28),
                                const SizedBox(height: 4),
                                const Text(
                                  'CIBLE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Iso: $_totalIsometries',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // === PLATEAU DE JEU ===
                  Expanded(
                    flex: 4,
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
  // MINIATURE DE LA CIBLE
  // ============================================================

  Widget _buildTargetPreview(DuelIsometryState state) {
    if (state.puzzle == null) return const SizedBox();

    final puzzle = state.puzzle!;
    final grid = puzzle.targetGrid;
    final rows = grid.length;
    final cols = grid.isNotEmpty ? grid[0].length : 0;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: AspectRatio(
        aspectRatio: cols / rows,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 1.0,
              ),
              itemCount: rows * cols,
              itemBuilder: (context, index) {
                final x = index % cols;
                final y = index ~/ cols;
                final pieceId = grid[y][x];

                return Container(
                  decoration: BoxDecoration(
                    color: pieceId > 0 ? _getDuelColor(pieceId) : Colors.grey.shade300,
                    border: Border.all(
                      color: pieceId > 0 ? Colors.black : Colors.grey.shade400,
                      width: 0.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PLATEAU DE JEU
  // ============================================================

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
                  final x = (offset.dx / cellSize).floor().clamp(0, visualCols - 1);
                  final y = (offset.dy / cellSize).floor().clamp(0, visualRows - 1);
                  setState(() {
                    _previewX = x;
                    _previewY = y;
                  });
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
                  final x = (offset.dx / cellSize).floor().clamp(0, visualCols - 1);
                  final y = (offset.dy / cellSize).floor().clamp(0, visualRows - 1);
                  if (_selectedPiece != null) {
                    _tryPlacePiece(ref, state, x, y);
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
      // GUIDE CIBLE (fantôme)
      cellColor = _getDuelColor(targetPieceId).withOpacity(0.3);
      borderColor = Colors.grey.shade500;
      borderWidth = 1.0;
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
    final position = piece.positions[placed.positionIndex];

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
    final position = piece.positions[posIndex];
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
    if (_selectedPiece == null) return;

    final puzzle = state.puzzle!;
    final target = puzzle.pieces.firstWhere(
          (p) => p.pieceId == _selectedPiece!.id,
      orElse: () => puzzle.pieces.first,
    );

    // Vérifier que la position ET l'orientation sont correctes
    final isCorrectPosition = (x == target.targetGridX && y == target.targetGridY);
    final isCorrectOrientation = (_selectedPositionIndex == target.targetPositionIndex);

    if (!isCorrectPosition || !isCorrectOrientation) {
      // Placement refusé - mauvaise position ou orientation
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isCorrectPosition
                ? 'Mauvaise position !'
                : 'Mauvaise orientation !',
          ),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Placement accepté
    ref.read(duelIsometryProvider.notifier).placePiece(
      pieceId: _selectedPiece!.id,
      gridX: x,
      gridY: y,
      positionIndex: _selectedPositionIndex,
    );

    // Vérifier si le puzzle est complet
    final newPlacedCount = state.placedPieces.length + 1;
    if (newPlacedCount == puzzle.pieceCount) {
      // Puzzle terminé !
      final elapsedMs = DateTime.now().difference(_startTime!).inMilliseconds;
      ref.read(duelIsometryProvider.notifier).completePuzzle(
        totalIsometries: _totalIsometries,
        timeMs: elapsedMs,
      );
    }

    // Notifier la progression
    _notifyIsometryChange();

    HapticFeedback.mediumImpact();
    setState(() {
      _selectedPiece = null;
    });
  }

  // ============================================================
  // SLIDER DES PIÈCES
  // ============================================================

  Widget _buildPieceSlider(BuildContext context, WidgetRef ref, DuelIsometryState state, settings) {
    if (state.puzzle == null) return const SizedBox();

    // Filtrer les pièces disponibles (non encore placées)
    final placedIds = state.placedPieces.map((p) => p.pieceId).toSet();
    final availablePieces = state.puzzle!.pieces
        .where((p) => !placedIds.contains(p.pieceId))
        .toList();

    if (availablePieces.isEmpty) {
      return const Center(
        child: Text(
          'Toutes les pièces sont placées !',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('slider_${availablePieces.length}'),
      controller: _sliderController,
      scrollDirection: Axis.horizontal,
      itemCount: availablePieces.length * DuelIsometrySliderConstants.itemsPerPage,
      itemBuilder: (context, index) {
        final targetPiece = availablePieces[index % availablePieces.length];
        final piece = pentominos.firstWhere((p) => p.id == targetPiece.pieceId);
        final posIndex = _piecePositionIndices[piece.id] ?? targetPiece.initialPositionIndex;
        final isSelected = _selectedPiece?.id == piece.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedPiece?.id == piece.id) {
                _selectedPiece = null;
              } else {
                _selectedPiece = piece;
                _selectedPositionIndex = posIndex;
              }
            });
            HapticFeedback.selectionClick();
          },
          child: Draggable<Pento>(
            data: piece,
            onDragStarted: () {
              setState(() {
                _selectedPiece = piece;
                _selectedPositionIndex = posIndex;
              });
            },
            feedback: _buildDraggablePiece(piece, posIndex),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildSliderPiece(piece, posIndex, false),
            ),
            child: _buildSliderPiece(piece, posIndex, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildSliderPiece(Pento piece, int posIndex, bool isSelected) {
    return Container(
      width: DuelIsometrySliderConstants.itemSize,
      height: DuelIsometrySliderConstants.itemSize,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 3 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)]
            : null,
      ),
      child: _buildPieceMiniature(piece, posIndex),
    );
  }

  Widget _buildDraggablePiece(Pento piece, int posIndex) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _getDuelColor(piece.id).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildPieceMiniature(piece, posIndex),
    );
  }

  Widget _buildPieceMiniature(Pento piece, int posIndex) {
    final position = piece.positions[posIndex];
    final coords = position.map((n) => [(n - 1) % 5, (n - 1) ~/ 5]).toList();

    final minX = coords.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
    final maxX = coords.map((c) => c[0]).reduce((a, b) => a > b ? a : b);
    final minY = coords.map((c) => c[1]).reduce((a, b) => a < b ? a : b);
    final maxY = coords.map((c) => c[1]).reduce((a, b) => a > b ? a : b);

    final gridWidth = maxX - minX + 1;
    final gridHeight = maxY - minY + 1;

    final normalizedCoords = coords.map((c) => [c[0] - minX, c[1] - minY]).toSet();

    return Center(
      child: AspectRatio(
        aspectRatio: gridWidth / gridHeight,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridWidth,
            childAspectRatio: 1.0,
          ),
          itemCount: gridWidth * gridHeight,
          itemBuilder: (context, index) {
            final x = index % gridWidth;
            final y = index ~/ gridWidth;
            final isFilled = normalizedCoords.contains([x, y]);

            return Container(
              margin: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                color: isFilled ? _getDuelColor(piece.id) : Colors.transparent,
                border: isFilled
                    ? Border.all(color: Colors.black, width: 0.5)
                    : null,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
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
}