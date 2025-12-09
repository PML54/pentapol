// lib/isopento/screens/isopento_menu_screen.dart
// Modified: 2512091028
// Menu principal Isopento - syntaxe corrigée

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../isopento_generator.dart';
import '../isopento_provider.dart';
import 'isopento_game_screen.dart';

class IsopentoMenuScreen extends ConsumerStatefulWidget {
  const IsopentoMenuScreen({super.key});

  @override
  ConsumerState<IsopentoMenuScreen> createState() => _IsopentoMenuScreenState();
}

class _IsopentoMenuScreenState extends ConsumerState<IsopentoMenuScreen> {
  IsopentoSize _selectedSize = IsopentoSize.size3x5;
  IsopentoDifficulty _selectedDifficulty = IsopentoDifficulty.random;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isopento'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Titre
              const Text(
                'Mini-Puzzles Pentominos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Remplissez le plateau avec les pièces proposées',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              // SECTION TAILLE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Taille du plateau',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeOption(IsopentoSize.size3x5, '3 × 5'),
                  const SizedBox(height: 8),
                  _buildSizeOption(IsopentoSize.size4x5, '4 × 5'),
                  const SizedBox(height: 8),
                  _buildSizeOption(IsopentoSize.size5x5, '5 × 5'),
                ],
              ),

              // SECTION DIFFICULTÉ
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Difficulté',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildDifficultyOption(
                    IsopentoDifficulty.easy,
                    '😊 Facile',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildDifficultyOption(
                    IsopentoDifficulty.random,
                    '🔀 Aléatoire',
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildDifficultyOption(
                    IsopentoDifficulty.hard,
                    '🔥 Difficile',
                    Colors.orange,
                  ),
                ],
              ),

              // BOUTON JOUER
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _startGame,
                child: const Text(
                  'Jouer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeOption(IsopentoSize size, String label) {
    final isSelected = _selectedSize == size;
    final stats = IsopentoGenerator().getStats(size);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSize = size;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${size.numPieces} pièces • ${stats.configCount} configs',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
      IsopentoDifficulty difficulty,
      String label,
      Color color,
      ) {
    final isSelected = _selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _startGame() {
    ref.read(isopentoProvider.notifier).startPuzzle(
      _selectedSize,
      difficulty: _selectedDifficulty,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IsopentoGameScreen(),
      ),
    );
  }
}