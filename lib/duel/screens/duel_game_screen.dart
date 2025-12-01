// lib/duel/screens/duel_game_screen.dart
// Écran principal du jeu duel avec overlay solution et isométries
// v2: SNAP INTELLIGENT + Palette DUEL vive + contours noirs épais

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/services/solution_matcher.dart';
import 'package:pentapol/config/game_icons_config.dart';

import '../providers/duel_provider.dart';
import '../models/duel_state.dart';
import '../services/duel_validator.dart';
import '../widgets/duel_countdown.dart';
import 'duel_result_screen.dart';

/// Constantes pour le slider
class DuelSliderConstants {
  static const double itemSize = 90.0;
  static const int itemsPerPage = 100;
}

/// 🆕 Rayon de recherche pour le snap (en cases)
const int _snapRadius = 2;

/// Palette DUEL : 12 couleurs VIVES et SATURÉES
/// Couleurs franches, très distinctes, parfaites pour le mode compétitif
Color _getDuelColor(int pieceId) {
  const colors = [
    Color(0xFFD32F2F), // 1  - ROUGE vif
    Color(0xFF388E3C), // 2  - VERT franc
    Color(0xFF1976D2), // 3  - BLEU roi
    Color(0xFFFFC107), // 4  - JAUNE OR (ambre)
    Color(0xFFE64A19), // 5  - ORANGE brûlé
    Color(0xFF7B1FA2), // 6  - VIOLET profond
    Color(0xFF0097A7), // 7  - CYAN foncé
    Color(0xFFC2185B), // 8  - MAGENTA / Rose vif
    Color(0xFF5D4037), // 9  - MARRON chocolat
    Color(0xFF689F38), // 10 - VERT OLIVE / Lime foncé
    Color(0xFF512DA8), // 11 - VIOLET INDIGO
    Color(0xFF455A64), // 12 - GRIS BLEU foncé
  ];
  return colors[(pieceId - 1) % colors.length];
}

class DuelGameScreen extends ConsumerStatefulWidget {
  const DuelGameScreen({super.key});

  @override
  ConsumerState<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends ConsumerState<DuelGameScreen> {
  Pento? _selectedPiece;
  int _selectedPositionIndex = 0;
  int? _previewX;
  int? _previewY;
  bool _isPreviewSnapped = false; // 🆕 Pour le snap
  List<List<int>>? _solutionGrid;
  bool _solutionLoaded = false;
  final ScrollController _sliderController = ScrollController(keepScrollOffset: true);
  final Map<int, int> _piecePositionIndices = {};
  bool _sliderInitialized = false;
  final GlobalKey _sliderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadSolution();
    });
  }

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  /// Initialise la position du slider après le countdown
  void _initializeSliderPosition() {
    if (_sliderInitialized) return;
    _sliderInitialized = true;  // Marquer immédiatement pour éviter double appel

    if (_sliderController.hasClients && mounted) {
      // 12 pièces * 100 pages / 2 = milieu
      const totalItems = 12 * DuelSliderConstants.itemsPerPage;
      final middleOffset = (totalItems / 2) * DuelSliderConstants.itemSize;
      _sliderController.jumpTo(middleOffset);
    }
  }

  Future<void> _initializeAndLoadSolution() async {
    DuelValidator.instance.initialize(solutionMatcher.allSolutions);
    await _loadSolution();
  }

  Future<void> _loadSolution() async {
    final duelState = ref.read(duelProvider);
    final solutionId = duelState.solutionId;
    if (solutionId == null) return;

    final success = await DuelValidator.instance.loadSolution(solutionId);
    if (success) {
      _solutionGrid = DuelValidator.instance.solutionGrid;
    }
    setState(() {
      _solutionLoaded = success;
    });
  }

  // ============================================================
  // 🆕 SNAP INTELLIGENT
  // ============================================================

  /// Vérifie si une pièce peut être placée à une position donnée
  bool _canPlacePieceAt(Pento piece, int positionIndex, int gridX, int gridY, DuelState duelState) {
    final position = piece.positions[positionIndex % piece.numPositions];

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      final x = gridX + localX;
      final y = gridY + localY;

      // Hors limites ?
      if (x < 0 || x >= 6 || y < 0 || y >= 10) {
        return false;
      }

      // Case déjà occupée par une autre pièce ?
      for (final placed in duelState.placedPieces) {
        if (_isPieceAtCell(placed, x, y)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Cherche la position valide la plus proche dans un rayon donné
  _SnapResult? _findNearestValidPosition(Pento piece, int positionIndex, int anchorX, int anchorY, DuelState duelState) {
    _SnapResult? best;
    double bestDistanceSquared = double.infinity;

    for (int dx = -_snapRadius; dx <= _snapRadius; dx++) {
      for (int dy = -_snapRadius; dy <= _snapRadius; dy++) {
        if (dx == 0 && dy == 0) continue; // Position exacte déjà testée

        final testX = anchorX + dx;
        final testY = anchorY + dy;

        if (_canPlacePieceAt(piece, positionIndex, testX, testY, duelState)) {
          // Distance euclidienne au carré (évite sqrt pour la perf)
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

  /// Met à jour la preview avec snap
  void _updatePreviewWithSnap(int rawX, int rawY, DuelState duelState) {
    if (_selectedPiece == null) {
      setState(() {
        _previewX = null;
        _previewY = null;
        _isPreviewSnapped = false;
      });
      return;
    }

    // 1. Vérifier position exacte
    if (_canPlacePieceAt(_selectedPiece!, _selectedPositionIndex, rawX, rawY, duelState)) {
      setState(() {
        _previewX = rawX;
        _previewY = rawY;
        _isPreviewSnapped = false;
      });
      return;
    }

    // 2. Chercher snap
    final snapped = _findNearestValidPosition(_selectedPiece!, _selectedPositionIndex, rawX, rawY, duelState);

    if (snapped != null) {
      setState(() {
        _previewX = snapped.x;
        _previewY = snapped.y;
        _isPreviewSnapped = true;
      });
    } else {
      // Aucune position valide → afficher en rouge à la position du curseur
      setState(() {
        _previewX = rawX;
        _previewY = rawY;
        _isPreviewSnapped = false;
      });
    }
  }

  // ============================================================
  // ISOMÉTRIES
  // ============================================================

  void _rotateCounterClockwise() {
    if (_selectedPiece == null) return;
    final newIndex = _selectedPiece!.findRotation90(_selectedPositionIndex);
    if (newIndex != -1) {
      setState(() {
        _selectedPositionIndex = newIndex;
        _piecePositionIndices[_selectedPiece!.id] = newIndex;
      });
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
      });
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
      });
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
      });
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final duelState = ref.watch(duelProvider);
    final settings = ref.watch(settingsProvider);

    if (duelState.solutionId != null &&
        duelState.solutionId != DuelValidator.instance.currentSolutionId) {
      _loadSolution();
    }

    ref.listen<DuelState>(duelProvider, (previous, next) {
      // Initialiser le slider quand le jeu commence (après countdown)
      if (next.gameState == DuelGameState.playing &&
          previous?.gameState != DuelGameState.playing) {
        // Petit délai pour laisser le ListView se construire
        Future.delayed(const Duration(milliseconds: 200), () {
          _initializeSliderPosition();
        });
      }

      if (next.gameState == DuelGameState.ended &&
          previous?.gameState != DuelGameState.ended) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DuelResultScreen()),
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
          title: _buildScoreTitle(duelState),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  if (duelState.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.shade100,
                      child: Text(
                        duelState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),

                  // Plateau de jeu
                  Expanded(
                    flex: 4,
                    child: _buildGameBoard(context, ref, duelState, settings),
                  ),

                  // Barre d'isométries (toujours visible pour éviter resize)
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

                  // Slider des pièces
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
                    child: _buildPieceSlider(context, ref, duelState, settings),
                  ),
                ],
              ),

              if (duelState.gameState == DuelGameState.countdown &&
                  duelState.countdown != null)
                DuelCountdown(value: duelState.countdown!),
            ],
          ),
        ),
      ),
    );
  }

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
        content: const Text('Vous abandonnerez la partie en cours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(duelProvider.notifier).leaveRoom();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTitle(DuelState duelState) {
    final timeRemaining = duelState.timeRemaining ?? 180;
    final minutes = timeRemaining ~/ 60;
    final seconds = timeRemaining % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    final localName = duelState.localPlayer?.name ?? 'Moi';
    final opponentName = duelState.opponent?.name ?? 'Adv';
    final localScore = duelState.localScore;
    final opponentScore = duelState.opponentScore;

    final isUrgent = timeRemaining <= 30;
    final timerColor = isUrgent ? Colors.red : Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          _buildPlayerScore(localName, localScore, Colors.cyan, true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: timerColor.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: timerColor.withOpacity(0.4),
                    blurRadius: isUrgent ? 12 : 6,
                  ),
                ],
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                  shadows: [
                    Shadow(color: timerColor, blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
          _buildPlayerScore(opponentName, opponentScore, Colors.orange, false),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(String name, int score, Color color, bool isLocal) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocal)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.person, size: 10, color: Colors.green),
              ),
            Text(
              name.length > 6 ? '${name.substring(0, 5)}.' : name,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(minWidth: 32),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 4),
            ],
          ),
          child: Text(
            '$score',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: [
                Shadow(color: color, blurRadius: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLATEAU DE JEU
  // ============================================================

  Widget _buildGameBoard(BuildContext context, WidgetRef ref, DuelState duelState, settings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const visualCols = 6;
        const visualRows = 10;

        final cellSize = (constraints.maxWidth / visualCols)
            .clamp(0.0, constraints.maxHeight / visualRows)
            .toDouble();

        return Center(
          child: Container(
            width: cellSize * visualCols,
            height: cellSize * visualRows,
            decoration: BoxDecoration(
              color: Colors.black, // Fond noir pour les contours
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

                  // 🆕 Utiliser le snap intelligent
                  _updatePreviewWithSnap(x, y, duelState);
                },
                onLeave: (data) {
                  setState(() {
                    _previewX = null;
                    _previewY = null;
                    _isPreviewSnapped = false;
                  });
                },
                onAcceptWithDetails: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final offset = renderBox.globalToLocal(details.offset);
                  final x = (offset.dx / cellSize).floor().clamp(0, visualCols - 1);
                  final y = (offset.dy / cellSize).floor().clamp(0, visualRows - 1);

                  if (_selectedPiece != null) {
                    // 🆕 Utiliser la position snappée si disponible
                    final placeX = _previewX ?? x;
                    final placeY = _previewY ?? y;
                    _tryPlacePiece(ref, duelState, placeX, placeY);
                  }

                  setState(() {
                    _previewX = null;
                    _previewY = null;
                    _isPreviewSnapped = false;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: visualCols,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 60,
                    itemBuilder: (context, index) {
                      final x = index % visualCols;
                      final y = index ~/ visualCols;
                      return _buildCell(context, ref, duelState, settings, x, y, cellSize);
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
  // CELLULE DU PLATEAU - STYLE SOLUTION VIEWER + SNAP
  // ============================================================

  Widget _buildCell(
      BuildContext context,
      WidgetRef ref,
      DuelState duelState,
      settings,
      int x,
      int y,
      double cellSize,
      ) {
    final solutionPieceId = _solutionGrid?[y][x] ?? 0;

    // Pièce placée ?
    DuelPlacedPiece? placedPiece;
    for (final piece in duelState.placedPieces) {
      if (_isPieceAtCell(piece, x, y)) {
        placedPiece = piece;
        break;
      }
    }

    // Preview ?
    bool isPreview = false;
    bool previewMatchesSolution = false;
    bool previewIsValid = false;

    if (_selectedPiece != null && _previewX != null && _previewY != null) {
      if (_isPiecePreviewAtCell(_selectedPiece!, _selectedPositionIndex, _previewX!, _previewY!, x, y)) {
        isPreview = true;
        previewMatchesSolution = (solutionPieceId == _selectedPiece!.id);
        previewIsValid = _canPlacePieceAt(_selectedPiece!, _selectedPositionIndex, _previewX!, _previewY!, duelState);
      }
    }

    // === COULEURS ET STYLE ===
    Color cellColor;
    Color borderColor;
    double borderWidth;
    String? cellNumber;
    bool showHatch = false;
    bool showHorizontalHatch = false;
    List<BoxShadow>? boxShadow;

    if (placedPiece != null) {
      // ══════════════════════════════════════════
      // PIÈCE PLACÉE
      // ══════════════════════════════════════════
      cellColor = _getDuelColor(placedPiece.pieceId);
      cellNumber = '${placedPiece.pieceId}';
      borderColor = Colors.black;
      borderWidth = 2.0;

      final isMyPiece = placedPiece.ownerId == duelState.localPlayer?.id;

      if (isMyPiece) {
        // MES PIÈCES : Hachures HORIZONTALES
        showHatch = true;
        showHorizontalHatch = true;
      } else {
        // PIÈCES ADVERSAIRE : Hachures DIAGONALES
        showHatch = true;
        showHorizontalHatch = false;
      }

    } else if (isPreview) {
      // ══════════════════════════════════════════
      // PREVIEW - Semi-transparent + contour coloré
      // 🆕 Support du snap avec bordure cyan
      // ══════════════════════════════════════════
      cellColor = _getDuelColor(_selectedPiece!.id).withOpacity(
          _isPreviewSnapped ? 0.8 : 0.7 // Plus opaque si snappé
      );
      cellNumber = '${_selectedPiece!.id}';

      if (previewIsValid) {
        if (_isPreviewSnapped) {
          // 🆕 Snap actif : bordure cyan + glow
          borderColor = Colors.cyan.shade400;
          boxShadow = [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ];
        } else {
          // Position exacte valide : bordure verte ou orange selon solution
          borderColor = previewMatchesSolution ? Colors.green : Colors.orange;
        }
      } else {
        // Position invalide : bordure rouge
        borderColor = Colors.red;
      }
      borderWidth = 3.0;

    } else if (solutionPieceId > 0) {
      // ══════════════════════════════════════════
      // GUIDE SOLUTION - Couleurs VIVES (100%)
      // ══════════════════════════════════════════
      cellColor = _getDuelColor(solutionPieceId);
      cellNumber = '$solutionPieceId';
      borderColor = Colors.black;
      borderWidth = 1.5;

    } else {
      // ══════════════════════════════════════════
      // CASE VIDE
      // ══════════════════════════════════════════
      cellColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade400;
      borderWidth = 0.5;
    }

    return GestureDetector(
      onTap: () {
        if (_selectedPiece != null && solutionPieceId == _selectedPiece!.id && placedPiece == null) {
          _tryPlacePieceAt(ref, duelState, solutionPieceId);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: boxShadow,
        ),
        child: Stack(
          children: [
            // Numéro de pièce
            if (cellNumber != null)
              Center(
                child: Text(
                  cellNumber,
                  style: TextStyle(
                    color: isPreview && _isPreviewSnapped
                        ? Colors.cyan.shade900 // 🆕 Texte cyan si snappé
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

            // Hachures pour distinguer joueur/adversaire
            if (showHatch)
              Positioned.fill(
                child: CustomPaint(
                  painter: HatchPainter(
                    hatchColor: Colors.black.withOpacity(0.5),
                    hatchWidth: 2,
                    hatchSpacing: 5,
                    cellX: x,
                    cellY: y,
                    cellSize: cellSize,
                    isHorizontal: showHorizontalHatch,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isPieceAtCell(DuelPlacedPiece placedPiece, int x, int y) {
    final pento = pentominos.firstWhere((p) => p.id == placedPiece.pieceId);
    final position = pento.positions[placedPiece.orientation % pento.numPositions];
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (placedPiece.x + localX == x && placedPiece.y + localY == y) return true;
    }
    return false;
  }

  bool _isPiecePreviewAtCell(Pento piece, int positionIndex, int baseX, int baseY, int cellX, int cellY) {
    final position = piece.positions[positionIndex % piece.numPositions];
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (baseX + localX == cellX && baseY + localY == cellY) return true;
    }
    return false;
  }

  void _tryPlacePieceAt(WidgetRef ref, DuelState duelState, int pieceId) {
    if (!duelState.isPlaying) return;
    if (duelState.placedPieces.any((p) => p.pieceId == pieceId)) {
      HapticFeedback.heavyImpact();
      _showError('Déjà placée !');
      return;
    }

    final placement = _findCorrectPlacement(pieceId);
    if (placement == null) return;

    ref.read(duelProvider.notifier).placePiece(
      pieceId: pieceId,
      x: placement['x']!,
      y: placement['y']!,
      orientation: placement['orientation']!,
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _selectedPiece = null;
    });
  }

  Map<String, int>? _findCorrectPlacement(int pieceId) {
    if (_solutionGrid == null) return null;

    final cells = <_Point>[];
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 6; x++) {
        if (_solutionGrid![y][x] == pieceId) {
          cells.add(_Point(x, y));
        }
      }
    }
    if (cells.isEmpty) return null;

    int minX = cells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    int minY = cells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final normalizedCells = cells.map((c) => _Point(c.x - minX, c.y - minY)).toSet();

    final pento = pentominos.firstWhere((p) => p.id == pieceId);

    for (int orientation = 0; orientation < pento.numPositions; orientation++) {
      final position = pento.positions[orientation];
      final positionCells = <_Point>{};

      int posMinX = 5, posMinY = 5;
      for (final cellNum in position) {
        final lx = (cellNum - 1) % 5;
        final ly = (cellNum - 1) ~/ 5;
        if (lx < posMinX) posMinX = lx;
        if (ly < posMinY) posMinY = ly;
      }

      for (final cellNum in position) {
        positionCells.add(_Point((cellNum - 1) % 5 - posMinX, (cellNum - 1) ~/ 5 - posMinY));
      }

      if (_setsEqual(normalizedCells, positionCells)) {
        return {'x': minX - posMinX, 'y': minY - posMinY, 'orientation': orientation};
      }
    }
    return null;
  }

  bool _setsEqual(Set<_Point> a, Set<_Point> b) {
    if (a.length != b.length) return false;
    for (final p in a) {
      if (!b.any((q) => q.x == p.x && q.y == p.y)) return false;
    }
    return true;
  }

  void _tryPlacePiece(WidgetRef ref, DuelState duelState, int x, int y) {
    if (_selectedPiece == null || !duelState.isPlaying) return;
    if (duelState.placedPieces.any((p) => p.pieceId == _selectedPiece!.id)) {
      HapticFeedback.heavyImpact();
      return;
    }

    final validation = DuelValidator.instance.validatePlacement(
      pieceId: _selectedPiece!.id,
      x: x,
      y: y,
      orientation: _selectedPositionIndex,
    );

    if (!validation.isValid) {
      HapticFeedback.lightImpact();
      return;
    }

    ref.read(duelProvider.notifier).placePiece(
      pieceId: _selectedPiece!.id,
      x: x,
      y: y,
      orientation: _selectedPositionIndex,
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _selectedPiece = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ============================================================
  // SLIDER DES PIÈCES
  // ============================================================

  Widget _buildPieceSlider(BuildContext context, WidgetRef ref, DuelState duelState, settings) {
    final placedPieceIds = duelState.placedPieces.map((p) => p.pieceId).toSet();
    final availablePieces = pentominos.where((p) => !placedPieceIds.contains(p.id)).toList();

    if (availablePieces.isEmpty) {
      return const Center(
        child: Text('🎉 Toutes les pièces placées !',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    }

    final useInfiniteScroll = availablePieces.length >= 4;
    final totalItems = useInfiniteScroll
        ? availablePieces.length * DuelSliderConstants.itemsPerPage
        : availablePieces.length;

    return ListView.builder(
      key: _sliderKey,  // Empêche le rebuild complet
      controller: useInfiniteScroll ? _sliderController : null,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        final pieceIndex = index % availablePieces.length;
        final piece = availablePieces[pieceIndex];
        return _buildDraggablePiece(piece, duelState, settings);
      },
    );
  }

  Widget _buildDraggablePiece(Pento piece, DuelState duelState, settings) {
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
      child: _buildPieceWidget(piece, positionIndex),
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
              _tryPlacePieceAt(ref, duelState, piece.id);
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

  /// Widget pièce dans le slider - COULEURS VIVES + CONTOURS NOIRS
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
                  color: Colors.black,  // ← CONTOUR NOIR
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
}

// 🆕 Helper pour le snap
class _SnapResult {
  final int x, y;
  const _SnapResult(this.x, this.y);
}

class _Point {
  final int x, y;
  const _Point(this.x, this.y);
}

/// Hachures pour distinguer les pièces
/// - Diagonales (/) pour l'adversaire
/// - Horizontales (═) pour le joueur
class HatchPainter extends CustomPainter {
  final Color hatchColor;
  final double hatchWidth;
  final double hatchSpacing;
  final int cellX;
  final int cellY;
  final double cellSize;
  final bool isHorizontal;

  HatchPainter({
    required this.hatchColor,
    required this.hatchWidth,
    required this.hatchSpacing,
    this.cellX = 0,
    this.cellY = 0,
    this.cellSize = 50,
    this.isHorizontal = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = hatchColor
      ..strokeWidth = hatchWidth
      ..style = PaintingStyle.stroke;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final spacing = hatchSpacing + hatchWidth;

    if (isHorizontal) {
      // HACHURES HORIZONTALES (pour le joueur)
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          paint,
        );
      }
    } else {
      // HACHURES DIAGONALES (pour l'adversaire)
      final globalOffsetX = cellX * cellSize;
      final globalOffsetY = cellY * cellSize;
      final maxDimension = (size.width + size.height) * 2;

      for (double i = -maxDimension; i < maxDimension; i += spacing) {
        final adjustedI = i - (globalOffsetX + globalOffsetY) % spacing;
        canvas.drawLine(
          Offset(adjustedI, 0),
          Offset(adjustedI + size.height, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant HatchPainter oldDelegate) {
    return oldDelegate.cellX != cellX ||
        oldDelegate.cellY != cellY ||
        oldDelegate.hatchColor != hatchColor ||
        oldDelegate.isHorizontal != isHorizontal;
  }
}