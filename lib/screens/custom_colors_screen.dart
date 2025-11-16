// Modified: 2025-11-16 10:45:00
// lib/screens/custom_colors_screen.dart
// Écran pour personnaliser les couleurs des pièces

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/pentominos.dart';

/// Noms des pièces selon leur ID
const Map<int, String> pieceNames = {
  1: 'X',  // Pièce 1 - Croix
  2: 'I',  // Pièce 2 - Barre
  3: 'Z',  // Pièce 3
  4: 'V',  // Pièce 4
  5: 'T',  // Pièce 5
  6: 'W',  // Pièce 6
  7: 'U',  // Pièce 7
  8: 'F',  // Pièce 8
  9: 'P',  // Pièce 9
  10: 'N', // Pièce 10
  11: 'Y', // Pièce 11
  12: 'L', // Pièce 12
};

class CustomColorsScreen extends ConsumerStatefulWidget {
  const CustomColorsScreen({super.key});

  @override
  ConsumerState<CustomColorsScreen> createState() => _CustomColorsScreenState();
}

class _CustomColorsScreenState extends ConsumerState<CustomColorsScreen> {
  late List<Color> _colors;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    
    // Si pas de couleurs personnalisées, utiliser les couleurs classiques par défaut
    if (settings.ui.customColors.isEmpty) {
      _colors = [
        const Color(0xFFE57373), // Rouge
        const Color(0xFF81C784), // Vert
        const Color(0xFF64B5F6), // Bleu
        const Color(0xFFFFD54F), // Jaune
        const Color(0xFFBA68C8), // Violet
        const Color(0xFFFF8A65), // Orange
        const Color(0xFF4DB6AC), // Turquoise
        const Color(0xFFA1887F), // Marron
        const Color(0xFF90A4AE), // Gris-bleu
        const Color(0xFFF06292), // Rose
        const Color(0xFF9575CD), // Violet clair
        const Color(0xFF4DD0E1), // Cyan
      ];
    } else {
      _colors = List.from(settings.ui.customColors);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couleurs personnalisées'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Enregistrer',
            onPressed: () async {
              await ref.read(settingsProvider.notifier).setCustomColors(_colors);
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 12,
        itemBuilder: (context, index) {
          final pieceId = index + 1;
          final pieceName = pieceNames[pieceId] ?? '?';
          final piece = pentominos.firstWhere((p) => p.id == pieceId);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _colors[index],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
                child: Center(
                  child: Text(
                    pieceName,
                    style: TextStyle(
                      color: _colors[index].computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              title: Text('Pièce $pieceName (#$pieceId)'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getColorName(_colors[index])),
                  const SizedBox(height: 4),
                  _buildPiecePreview(piece, _colors[index]),
                ],
              ),
              trailing: const Icon(Icons.edit),
              onTap: () => _showColorPicker(index, pieceName),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _resetToDefault,
        icon: const Icon(Icons.refresh),
        label: const Text('Réinitialiser'),
      ),
    );
  }

  Widget _buildPiecePreview(Pento piece, Color color) {
    // Afficher la forme de base de la pièce
    final baseShape = piece.baseShape;
    
    // Calculer les coordonnées min/max
    int minX = 4, maxX = 0, minY = 4, maxY = 0;
    for (final cellNum in baseShape) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    
    final width = maxX - minX + 1;
    final height = maxY - minY + 1;
    const cellSize = 12.0;
    
    return SizedBox(
      width: width * cellSize,
      height: height * cellSize,
      child: Stack(
        children: baseShape.map((cellNum) {
          final x = (cellNum - 1) % 5;
          final y = (cellNum - 1) ~/ 5;
          return Positioned(
            left: (x - minX) * cellSize,
            top: (y - minY) * cellSize,
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.7),
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showColorPicker(int index, String pieceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Couleur de la pièce $pieceName'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Couleurs prédéfinies
              ..._getPredefinedColors().map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _colors[index] = color;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _colors[index] == color
                            ? Colors.black
                            : Colors.grey.shade400,
                        width: _colors[index] == color ? 3 : 2,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  List<Color> _getPredefinedColors() {
    return [
      // Rouges
      Colors.red.shade900,
      Colors.red.shade700,
      Colors.red.shade500,
      Colors.red.shade300,
      // Roses
      Colors.pink.shade700,
      Colors.pink.shade500,
      Colors.pink.shade300,
      // Violets
      Colors.purple.shade700,
      Colors.purple.shade500,
      Colors.purple.shade300,
      Colors.deepPurple.shade700,
      Colors.deepPurple.shade500,
      // Bleus
      Colors.indigo.shade700,
      Colors.indigo.shade500,
      Colors.blue.shade700,
      Colors.blue.shade500,
      Colors.blue.shade300,
      Colors.lightBlue.shade700,
      Colors.lightBlue.shade500,
      // Cyans
      Colors.cyan.shade700,
      Colors.cyan.shade500,
      Colors.teal.shade700,
      Colors.teal.shade500,
      // Verts
      Colors.green.shade900,
      Colors.green.shade700,
      Colors.green.shade500,
      Colors.green.shade300,
      Colors.lightGreen.shade700,
      Colors.lightGreen.shade500,
      Colors.lime.shade700,
      Colors.lime.shade500,
      // Jaunes
      Colors.yellow.shade700,
      Colors.yellow.shade500,
      Colors.amber.shade700,
      Colors.amber.shade500,
      // Oranges
      Colors.orange.shade700,
      Colors.orange.shade500,
      Colors.deepOrange.shade700,
      Colors.deepOrange.shade500,
      // Marrons
      Colors.brown.shade700,
      Colors.brown.shade500,
      Colors.brown.shade300,
      // Gris
      Colors.grey.shade900,
      Colors.grey.shade700,
      Colors.grey.shade500,
      Colors.grey.shade300,
      Colors.blueGrey.shade700,
      Colors.blueGrey.shade500,
      // Noir et blanc
      Colors.black,
      Colors.white,
    ];
  }

  String _getColorName(Color color) {
    final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    return hex;
  }

  void _resetToDefault() {
    setState(() {
      _colors = [
        const Color(0xFFE57373), // Rouge
        const Color(0xFF81C784), // Vert
        const Color(0xFF64B5F6), // Bleu
        const Color(0xFFFFD54F), // Jaune
        const Color(0xFFBA68C8), // Violet
        const Color(0xFFFF8A65), // Orange
        const Color(0xFF4DB6AC), // Turquoise
        const Color(0xFFA1887F), // Marron
        const Color(0xFF90A4AE), // Gris-bleu
        const Color(0xFFF06292), // Rose
        const Color(0xFF9575CD), // Violet clair
        const Color(0xFF4DD0E1), // Cyan
      ];
    });
  }
}


