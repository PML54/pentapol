// plateau_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plateau_editor_provider.dart';
import '../providers/plateau_editor_state.dart';
import 'pentomino_game_screen.dart';

class PlateauEditorScreen extends ConsumerWidget {
  const PlateauEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plateauEditorProvider);

    // Debug: écouter les changements
    ref.listen<PlateauEditorState>(
      plateauEditorProvider,
          (previous, next) {
        if (previous == null) return;
        print('[LISTEN] État changé! solutionIndex: ${previous.solutionIndex} -> ${next.solutionIndex}');
        if (next.solution != null && previous.solution != null) {
          print('[LISTEN] Solution identique? ${identical(previous.solution, next.solution)}');
          print('[LISTEN] Nouvelle solution:');
          for (var i = 0; i < next.solution!.length; i++) {
            print('  Piece ${next.solution![i].pieceIndex}: ${next.solution![i].occupiedCells}');
          }
        }
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[800],
            centerTitle: !isLandscape,
            title: _buildAppBarTitle(state, ref, isLandscape),
            actions: [
              // Bouton Jeu (toujours visible)
              IconButton(
                icon: const Icon(Icons.games),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PentominoGameScreen(),
                    ),
                  );
                },
                tooltip: '🎮 Jouer',
                color: Colors.amber[300],
              ),
              // Autres actions (seulement en paysage)
              if (isLandscape) ..._buildAppBarActions(context, ref, state),
            ],
      ),
      body: Stack(
        children: [
          // Grille principale qui remplit l'écran
          Positioned.fill(
                child: isLandscape
                    ? _buildLandscapeLayout(context, ref, state)
                    : _buildPortraitLayout(context, ref, state),
          ),

          // Overlay de chargement
          if (state.isSolving)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Résolution en cours...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
      },
    );
  }

  // Layout portrait (classique)
  Widget _buildPortraitLayout(BuildContext context, WidgetRef ref, PlateauEditorState state) {
    return Column(
      children: [
        // Message d'erreur en haut (si présent)
        if (state.errorMessage != null)
          Container(
      width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange[100],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // Grille plateau
        Expanded(
          child: _buildPlateauGrid(ref, state),
        ),

        // Contrôles en bas
        _buildControlPanel(context, ref, state),
      ],
    );
  }

  // Layout paysage (grille + slider à droite)
  Widget _buildLandscapeLayout(BuildContext context, WidgetRef ref, PlateauEditorState state) {
    return Column(
        children: [
        // Message d'erreur en haut (si présent)
        if (state.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.orange[100],
            child: Text(
              state.errorMessage!,
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Grille + Slider à droite
        Expanded(
          child: Row(
            children: [
              // Grille plateau
              Expanded(
                child: _buildPlateauGrid(ref, state),
              ),

              // Slider vertical à droite
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'Pièces',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: state.numPieces.toDouble(),
                          min: 1,
                          max: 12,
                          divisions: 11,
                          label: state.numPieces.toString(),
                          onChanged: (value) {
                            ref.read(plateauEditorProvider.notifier).setNumPieces(value.toInt());
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.numPieces}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Affichage compteur (si actif)
        if (state.isCountingAll || (state.totalSolutionsFound > 0 && !state.isCountingAll))
          _buildCountingPanel(state, ref),
      ],
    );
  }

  // Actions AppBar en mode paysage (icônes seules)
  List<Widget> _buildAppBarActions(BuildContext context, WidgetRef ref, PlateauEditorState state) {
    return [
      // Reset
      IconButton(
        onPressed: state.isSolving || state.isCountingAll
            ? null
            : () => ref.read(plateauEditorProvider.notifier).reset(),
        icon: const Icon(Icons.refresh),
        tooltip: 'Reset',
      ),
      // Valider
      IconButton(
        onPressed: state.isSolving || state.isCountingAll
            ? null
            : () => ref.read(plateauEditorProvider.notifier).validate(),
        icon: const Icon(Icons.check_circle),
        tooltip: 'Valider',
        color: Colors.green[300],
      ),
      // Compter
      IconButton(
        onPressed: state.isSolving || state.isCountingAll
            ? null
            : () => ref.read(plateauEditorProvider.notifier).startCountingAll(),
        icon: const Icon(Icons.calculate),
        tooltip: 'Compter toutes',
        color: Colors.blue[300],
      ),
      const SizedBox(width: 8),
    ];
  }

  // Panel de comptage (réutilisable portrait/paysage)
  Widget _buildCountingPanel(PlateauEditorState state, WidgetRef ref) {
    if (state.isCountingAll) {
      // Pendant le comptage
      return Container(
        padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border(top: BorderSide(color: Colors.blue[300]!, width: 2)),
              ),
              child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
                children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              '${state.totalSolutionsFound} solutions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
                  ),
                  const SizedBox(width: 8),
                  Text(
              '⏱️ ${_formatTime(state.countingElapsedSeconds)}',
              style: TextStyle(fontSize: 14, color: Colors.blue[700]),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => ref.read(plateauEditorProvider.notifier).cancelCounting(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
              child: const Text('Arrêter'),
            ),
          ],
        ),
      );
    } else {
      // Résultat final
      return Container(
        padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border(top: BorderSide(color: Colors.green[300]!, width: 2)),
              ),
              child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
                children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
            Text(
              '${state.totalSolutionsFound} solutions trouvées',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'en ${_formatTime(state.countingElapsedSeconds)}',
              style: TextStyle(fontSize: 14, color: Colors.green[700]),
                    ),
        ],
      ),
    );
  }
  }

  // Titre de l'AppBar avec info solution
  Widget _buildAppBarTitle(PlateauEditorState state, WidgetRef ref, bool isLandscape) {
    // Si solution trouvée, afficher N° et bouton Suivante
    if (state.hasSolution == true && state.solver != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
      children: [
          // N° solution
        Text(
            '✓ N°${state.solutionIndex}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
          ),
        ),
          const SizedBox(width: 16),
          // Bouton flèche Suivante ou spinner Recherche
          state.isSolving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : IconButton(
                  onPressed: () => ref.read(plateauEditorProvider.notifier).findNextSolution(),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  iconSize: 28,
                  tooltip: 'Solution suivante',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
        ),
      ],
    );
  }
    
    // Si aucune solution
    if (state.hasSolution == false) {
      return const Text(
        '✗ Aucune solution',
        style: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    }
    
    // Par défaut : titre vide
    return const SizedBox.shrink();
  }


  // Grille du plateau
  Widget _buildPlateauGrid(WidgetRef ref, PlateauEditorState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Détecter l'orientation
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        
        // En paysage: 10 colonnes × 6 lignes
        // En portrait: 6 colonnes × 10 lignes
        final cols = isLandscape ? 10 : 6;
        final rows = isLandscape ? 6 : 10;
        
        // Calculer la taille de cellule pour remplir l'espace disponible
        final cellSizeByHeight = constraints.maxHeight / rows;
        final cellSizeByWidth = constraints.maxWidth / cols;
        final cellSize = cellSizeByHeight < cellSizeByWidth 
            ? cellSizeByHeight 
            : cellSizeByWidth;

        return Center(
          child: SizedBox(
            width: cellSize * cols,
            height: cellSize * rows,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 1.0,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: 60,
              itemBuilder: (context, index) {
                // En paysage: rotation de 90° anti-horaire
                // Colonne portrait → Ligne paysage (inversée)
                // Ligne portrait → Colonne paysage
                
                int x, y;
                
                if (isLandscape) {
                  // Paysage: 10 colonnes × 6 lignes visuellement
                  // Rotation: col_portrait → ligne_paysage_inversée
                  //          ligne_portrait → col_paysage
                  final visualCol = index % 10;  // 0-9
                  final visualRow = index ~/ 10; // 0-5
                  
                  // Transformation inverse pour retrouver coord logiques
                  x = 5 - visualRow;  // col paysage → col portrait (inversé)
                  y = visualCol;      // ligne paysage → ligne portrait
                } else {
                  // Portrait: mapping standard
                  x = index % 6;
                  y = index ~/ 6;
                }
                
                return _CellWidget(x: x, y: y);
              },
            ),
          ),
        );
      },
    );
  }

  // Panel de contrôle en bas
  Widget _buildControlPanel(
      BuildContext context,
      WidgetRef ref,
      PlateauEditorState state,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider pour nombre de pièces
          Row(
            children: [
              const Text(
                'Pièces:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: state.numPieces.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  label: state.numPieces.toString(),
                  onChanged: (value) {
                    ref.read(plateauEditorProvider.notifier).setNumPieces(value.toInt());
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${state.numPieces}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Boutons Reset / Valider / Compter sur la même ligne
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isSolving || state.isCountingAll
                      ? null
                      : () => ref.read(plateauEditorProvider.notifier).reset(),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isSolving || state.isCountingAll
                      ? null
                      : () => ref.read(plateauEditorProvider.notifier).validate(),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isSolving || state.isCountingAll
                      ? null
                      : () => ref.read(plateauEditorProvider.notifier).startCountingAll(),
                  icon: const Icon(Icons.calculate, size: 20),
                  label: const Text('Compter'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
          ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Affichage du compteur pendant/après comptage
          if (state.isCountingAll) ...[
            // Affichage pendant le comptage
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${state.totalSolutionsFound} solutions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '⏱️ ${_formatTime(state.countingElapsedSeconds)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(plateauEditorProvider.notifier).cancelCounting(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Arrêter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (state.totalSolutionsFound > 0 && !state.isCountingAll) ...[
            // Affichage du résultat final
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${state.totalSolutionsFound} solutions trouvées',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'en ${_formatTime(state.countingElapsedSeconds)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Formatte le temps en secondes vers format lisible
  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes}m ${secs}s';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}

// Widget pour une cellule individuelle
class _CellWidget extends ConsumerWidget {
  final int x;
  final int y;

  const _CellWidget({required this.x, required this.y});

  // Couleurs pour les 12 pièces
  static const List<Color> pieceColors = [
    Color(0xFF212121), // Noir - Pièce 1 (croix, pour se distinguer de l'orange)
    Color(0xFF81C784), // Vert clair - Pièce 2
    Color(0xFF64B5F6), // Bleu clair - Pièce 3
    Color(0xFFFFD54F), // Jaune - Pièce 4
    Color(0xFFE53935), // Rouge - Pièce 5
    Color(0xFFFF8A65), // Orange - Pièce 6
    Color(0xFF4DD0E1), // Cyan - Pièce 7
    Color(0xFFA1887F), // Brun - Pièce 8
    Color(0xFFAED581), // Vert lime - Pièce 9
    Color(0xFFFFB74D), // Orange clair - Pièce 10
    Color(0xFF9575CD), // Violet clair - Pièce 11
    Color(0xFF90A4AE), // Bleu gris - Pièce 12
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plateauEditorProvider);
    final cellStatus = state.plateau.getCell(x, y);
    final isVisible = cellStatus >= 0; // 0 = libre, >= 1 = occupé

    // Calculer le numéro de case (1-60) pour cette position
    final cellNumber = y * 6 + x + 1;

    // Chercher si cette case fait partie de la solution
    int? pieceNumber;
    if (state.solution != null) {
      for (var i = 0; i < state.solution!.length; i++) {
        final placement = state.solution![i];
        if (placement.occupiedCells.contains(cellNumber)) {
          pieceNumber = placement.pieceIndex + 1; // +1 car index commence à 0
          break;
        }
      }
      // Debug: afficher pour plusieurs cellules
      if (cellNumber <= 10) {
        print('[CELL ($x,$y)=#$cellNumber] solutionIndex=${state.solutionIndex}, pieceNumber=$pieceNumber');
      }
    }

    // Couleur de fond
    Color backgroundColor;
    if (!isVisible) {
      backgroundColor = Colors.grey[800]!; // Case cachée
    } else if (pieceNumber != null) {
      backgroundColor = pieceColors[pieceNumber - 1]; // Case avec pièce
    } else {
      backgroundColor = Colors.white; // Case vide
    }

    return GestureDetector(
      onTap: state.isSolving
          ? null
          : () => ref.read(plateauEditorProvider.notifier).toggleCell(x, y),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: Colors.black26,
            width: 0.5,
          ),
        ),
        child: Center(
          child: pieceNumber != null
              ? Text(
            '$pieceNumber',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          )
              : (!isVisible
              ? Icon(
          Icons.block,
          color: Colors.grey[600],
          size: 16,
          )
              : null),
        ),
      ),
    );
  }
}