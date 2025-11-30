// lib/duel/screens/duel_game_screen.dart
// Écran principal du jeu duel avec overlay solution et isométries
// CORRIGÉ : Palette DUEL vive + contours noirs épais

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
  List<List<int>>? _solutionGrid;
  bool _solutionLoaded = false;
  final ScrollController _sliderController = ScrollController();
  final Map<int, int> _piecePositionIndices = {};
  bool _sliderInitialized = false;
  int _lastAvailablePiecesCount = 0;

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

                  // Barre d'isométries
                  if (_selectedPiece != null)
                    Container(
                      height: 44,
                      margin: const EdgeInsets.only(top: 8),
                      color: Colors.white,
                      child: Row(
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
    final opponentName = duelState.opponent?.name ?? 'Adversaire';

    Color timerColor = Colors.blue;
    if (timeRemaining <= 30) {
      timerColor = Colors.red;
    } else if (timeRemaining <= 60) {
      timerColor = Colors.orange;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$opponentName = ${duelState.opponentScore}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: timerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            timeStr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$localName = ${duelState.localScore}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
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
                    _tryPlacePiece(ref, duelState, x, y);
                  }
                  setState(() {
                    _previewX = null;
                    _previewY = null;
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
  // CELLULE DU PLATEAU - STYLE SOLUTION VIEWER
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
    if (_selectedPiece != null && _previewX != null && _previewY != null) {
      if (_isPiecePreviewAtCell(_selectedPiece!, _selectedPositionIndex, _previewX!, _previewY!, x, y)) {
        isPreview = true;
        previewMatchesSolution = (solutionPieceId == _selectedPiece!.id);
      }
    }

    // === COULEURS ET STYLE ===
    Color cellColor;
    Color borderColor;
    double borderWidth;
    String? cellNumber;
    bool showHatch = false;

    if (placedPiece != null) {
      // ══════════════════════════════════════════
      // PIÈCE PLACÉE - Couleur VIVE + contour BLANC épais (distinction)
      // ══════════════════════════════════════════
      cellColor = _getDuelColor(placedPiece.pieceId);
      cellNumber = '${placedPiece.pieceId}';
      borderColor = Colors.white;  // Contour BLANC pour distinguer
      borderWidth = 3.0;           // Plus épais

      // Hachures pour l'adversaire
      final isMyPiece = placedPiece.ownerId == duelState.localPlayer?.id;
      showHatch = !isMyPiece;

    } else if (isPreview) {
      // ══════════════════════════════════════════
      // PREVIEW - Semi-transparent + contour coloré
      // ══════════════════════════════════════════
      cellColor = _getDuelColor(_selectedPiece!.id).withOpacity(0.7);
      cellNumber = '${_selectedPiece!.id}';
      borderColor = previewMatchesSolution ? Colors.green : Colors.orange;
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
        ),
        child: Stack(
          children: [
            // Numéro de pièce
            if (cellNumber != null)
              Center(
                child: Text(
                  cellNumber,
                  style: TextStyle(
                    color: Colors.white,
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

            // Hachures pour l'adversaire
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

    // FIX : Ne repositionner le slider que si :
    // 1. Pas encore initialisé (première fois)
    // 2. OU le nombre de pièces a DIMINUÉ (une pièce a été placée)
    final shouldRepositionSlider = useInfiniteScroll &&
        (!_sliderInitialized ||
            (_lastAvailablePiecesCount > 0 && availablePieces.length < _lastAvailablePiecesCount));

    if (shouldRepositionSlider) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sliderController.hasClients) {
          // Seulement si pas encore initialisé, on jump au milieu
          if (!_sliderInitialized) {
            final middleOffset = (totalItems / 2) * DuelSliderConstants.itemSize;
            _sliderController.jumpTo(middleOffset);
          }
          _sliderInitialized = true;
          _lastAvailablePiecesCount = availablePieces.length;
        }
      });
    }

    // Mettre à jour le count même sans repositionnement
    if (_lastAvailablePiecesCount != availablePieces.length) {
      _lastAvailablePiecesCount = availablePieces.length;
    }
    return ListView.builder(
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

class _Point {
  final int x, y;
  const _Point(this.x, this.y);
}

/// Hachures diagonales pour les pièces adversaires
class HatchPainter extends CustomPainter {
  final Color hatchColor;
  final double hatchWidth;
  final double hatchSpacing;
  final int cellX;
  final int cellY;
  final double cellSize;

  HatchPainter({
    required this.hatchColor,
    required this.hatchWidth,
    required this.hatchSpacing,
    this.cellX = 0,
    this.cellY = 0,
    this.cellSize = 50,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = hatchColor
      ..strokeWidth = hatchWidth
      ..style = PaintingStyle.stroke;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final spacing = hatchSpacing + hatchWidth;
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

  @override
  bool shouldRepaint(covariant HatchPainter oldDelegate) {
    return oldDelegate.cellX != cellX ||
        oldDelegate.cellY != cellY ||
        oldDelegate.hatchColor != hatchColor;
  }
}