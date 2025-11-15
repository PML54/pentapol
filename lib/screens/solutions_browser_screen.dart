// Modified: 2025-11-15 17:05:00
// lib/screens/solutions_browser_screen.dart
// Navigateur pour parcourir des solutions de pentominos stockées en BigInt (360 bits)

import 'package:flutter/material.dart';
import '../services/solution_matcher.dart';
import '../models/pentominos.dart';

class SolutionsBrowserScreen extends StatefulWidget {
  /// Liste de solutions à afficher (BigInt).
  /// Si null → on affiche toutes les solutions de solutionMatcher.
  final List<BigInt>? initialSolutions;

  /// Titre personnalisé (affiché en petit au-dessus des flèches si fourni).
  final String? title;

  /// Constructeur standard : affiche toutes les solutions.
  const SolutionsBrowserScreen({super.key})
      : initialSolutions = null,
        title = null;

  /// Constructeur pour afficher une liste donnée de solutions.
  const SolutionsBrowserScreen.forSolutions({
    super.key,
    required List<BigInt> solutions,
    String? title,
  })  : initialSolutions = solutions,
        title = title;

  @override
  State<SolutionsBrowserScreen> createState() => _SolutionsBrowserScreenState();
}

class _SolutionsBrowserScreenState extends State<SolutionsBrowserScreen> {
  final SolutionMatcher _matcher = solutionMatcher; // singleton
  late final Map<int, int> _idByBit6;
  late List<BigInt> _allSolutions;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // bit6 -> id de pièce (1..12)
    _idByBit6 = {
      for (final p in pentominos) p.bit6: p.id,
    };

    try {
      if (widget.initialSolutions != null) {
        _allSolutions = List<BigInt>.from(widget.initialSolutions!);
        debugPrint('[BROWSER] ${_allSolutions.length} solutions (filtrées) chargées');
      } else {
        _allSolutions = _matcher.allSolutions;
        debugPrint('[BROWSER] ${_allSolutions.length} solutions (toutes) chargées');
      }
    } catch (e) {
      debugPrint('[BROWSER] Solutions non initialisées: $e');
      _allSolutions = const [];
    }
  }

  void _previousSolution() {
    setState(() {
      if (_allSolutions.isEmpty) return;
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = _allSolutions.length - 1; // Boucler au dernier
      }
    });
  }

  void _nextSolution() {
    setState(() {
      if (_allSolutions.isEmpty) return;
      if (_currentIndex < _allSolutions.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // Boucler au premier
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allSolutions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Solutions'),
          backgroundColor: Colors.blue[700],
        ),
        body: const Center(
          child: Text(
            'Aucune solution chargée.\n'
                'Vérifie que SolutionMatcher est bien initialisé au démarrage.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final BigInt solutionBigInt = _allSolutions[_currentIndex];
    final grid = _decodeSolutionToIds(solutionBigInt); // 60 ids de pièces
    
    // Détecter l'orientation
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final visualCols = isLandscape ? 10 : 6;
    final visualRows = isLandscape ? 6 : 10;
    final aspectRatio = isLandscape ? 10 / 6 : 6 / 10;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null)
              Text(
                widget.title!,
                style: const TextStyle(fontSize: 12),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Précédente',
                  onPressed: _previousSolution,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_currentIndex + 1} / ${_allSolutions.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Suivante',
                  onPressed: _nextSolution,
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: visualCols,
                childAspectRatio: 1.0,
                crossAxisSpacing: 0, // on gère les contours nous-mêmes
                mainAxisSpacing: 0,
              ),
              itemCount: 60,
              itemBuilder: (context, index) {
                // Calculer les coordonnées visuelles
                final visualX = index % visualCols;
                final visualY = index ~/ visualCols;
                
                // Transformer en coordonnées logiques (6×10)
                int logicalX, logicalY;
                if (isLandscape) {
                  // Paysage: rotation 90° anti-horaire
                  logicalX = (visualRows - 1) - visualY;
                  logicalY = visualX;
                } else {
                  // Portrait: pas de transformation
                  logicalX = visualX;
                  logicalY = visualY;
                }
                
                final cellIndex = logicalY * 6 + logicalX;
                final pieceId = grid[cellIndex];

                final border = _buildPieceBorder(logicalX, logicalY, grid, isLandscape);

                return Container(
                  decoration: BoxDecoration(
                    color: _getPieceColor(pieceId),
                    border: border,
                  ),
                  child: Center(
                    child: Text(
                      pieceId.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  /// Decode un BigInt (360 bits) en 60 ids de pièces (1..12).
  /// On suppose que le BigInt a été construit avec :
  ///   acc = (acc << 6) | code;
  /// dans l'ordre des 60 cases.
  List<int> _decodeSolutionToIds(BigInt value) {
    const int cells = 60;
    const int mask = 0x3F; // 6 bits

    final board = List<int>.filled(cells, 0);
    var v = value;

    // On lit de la fin à l'avant : cell 59, 58, ..., 0
    for (int i = cells - 1; i >= 0; i--) {
      final code = (v & BigInt.from(mask)).toInt();
      final id = _idByBit6[code] ?? 0;
      board[i] = id;
      v = v >> 6;
    }

    return board;
  }

  /// Palette de couleurs identique à celle du game
  Color _getPieceColor(int pieceId) {
    const colors = [
      Colors.black,     // 1
      Colors.blue,      // 2
      Colors.green,     // 3
      Colors.orange,    // 4
      Colors.red,       // 5
      Colors.teal,      // 6
      Colors.pink,      // 7
      Colors.brown,     // 8
      Colors.indigo,    // 9
      Colors.lime,      // 10
      Colors.cyan,      // 11
      Colors.amber,     // 12
    ];
    if (pieceId >= 1 && pieceId <= 12) {
      return colors[pieceId - 1];
    }
    return Colors.grey;
  }

  /// Construit un contour de pièce : trait épais aux frontières entre pièces.
  /// En paysage, les bordures sont adaptées à la rotation visuelle.
  Border _buildPieceBorder(int x, int y, List<int> grid, bool isLandscape) {
    const width = 6;
    const height = 10;

    final index = y * width + x;
    final id = grid[index];

    // Fonction pour récupérer l'id voisin ou -1 si hors plateau
    int neighborId(int nx, int ny) {
      if (nx < 0 || nx >= width || ny < 0 || ny >= height) return -1;
      return grid[ny * width + nx];
    }

    final idLogicalTop = neighborId(x, y - 1);
    final idLogicalBottom = neighborId(x, y + 1);
    final idLogicalLeft = neighborId(x - 1, y);
    final idLogicalRight = neighborId(x + 1, y);

    // Si voisin différent (ou bord du plateau), on trace un contour épais.
    const borderWidthOuter = 2.0;
    const borderWidthInner = 0.5;

    // En paysage, rotation 90° anti-horaire des bordures
    if (isLandscape) {
      return Border(
        top: BorderSide(
          color: (idLogicalRight != id) ? Colors.black : Colors.grey.shade400,
          width: (idLogicalRight != id) ? borderWidthOuter : borderWidthInner,
        ),
        bottom: BorderSide(
          color: (idLogicalLeft != id) ? Colors.black : Colors.grey.shade400,
          width: (idLogicalLeft != id) ? borderWidthOuter : borderWidthInner,
        ),
        left: BorderSide(
          color: (idLogicalTop != id) ? Colors.black : Colors.grey.shade400,
          width: (idLogicalTop != id) ? borderWidthOuter : borderWidthInner,
        ),
        right: BorderSide(
          color: (idLogicalBottom != id) ? Colors.black : Colors.grey.shade400,
          width: (idLogicalBottom != id) ? borderWidthOuter : borderWidthInner,
        ),
      );
    } else {
      // Portrait : bordures normales
      return Border(
        top: BorderSide(
          color: (idLogicalTop != id) ? Colors.black : Colors.grey.shade400,
          width: (idLogicalTop != id) ? borderWidthOuter : borderWidthInner,
        ),
        bottom: BorderSide(
          color: (idLogicalBottom != id) ? Colors.black : Colors.grey.shade400,
          width: (idLogicalBottom != id) ? borderWidthOuter : borderWidthInner,
        ),
        left: BorderSide(
          color: (idLogicalLeft != id) ? Colors.black : Colors.grey.shade400,
          width: (idLogicalLeft != id) ? borderWidthOuter : borderWidthInner,
        ),
        right: BorderSide(
          color: (idLogicalRight != id) ? Colors.black : Colors.grey.shade400,
          width: (idLogicalRight != id) ? borderWidthOuter : borderWidthInner,
        ),
      );
    }
  }
}


