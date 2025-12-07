// lib/pentoscope/screens/pentoscope_menu_screen.dart

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 32),

              // Sélection de la taille
              const Text(
                'Taille du plateau',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildSizeSelector(),

              const SizedBox(height: 24),

              // Sélection de la difficulté
              const Text(
                'Difficulté',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildDifficultySelector(),

              const Spacer(),

              // Bouton Jouer
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Jouer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSelector() {
    return Row(
      children: IsopentoSize.values.map((size) {
        final isSelected = size == _selectedSize;
        final stats = IsopentoGenerator().getStats(size);

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedSize = size),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    size.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${size.numPieces} pièces',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${stats.configCount} configs',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white60 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector() {
    return Row(
      children: [
        _buildDifficultyButton(
          IsopentoDifficulty.easy,
          'Facile',
          Icons.sentiment_satisfied,
          Colors.green,
        ),
        const SizedBox(width: 8),
        _buildDifficultyButton(
          IsopentoDifficulty.random,
          'Aléatoire',
          Icons.shuffle,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildDifficultyButton(
          IsopentoDifficulty.hard,
          'Difficile',
          Icons.local_fire_department,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(
      IsopentoDifficulty difficulty,
      String label,
      IconData icon,
      Color color,
      ) {
    final isSelected = difficulty == _selectedDifficulty;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDifficulty = difficulty),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey[500], size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[600],
                ),
              ),
            ],
          ),
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