// Modified: 2025-11-16 10:30:00
// lib/screens/custom_colors_screen.dart
// Écran pour personnaliser les couleurs des pièces

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

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
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _colors[index],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: _colors[index].computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text('Pièce ${index + 1}'),
              subtitle: Text(_getColorName(_colors[index])),
              trailing: const Icon(Icons.edit),
              onTap: () => _showColorPicker(index),
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

  void _showColorPicker(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Couleur de la pièce ${index + 1}'),
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

