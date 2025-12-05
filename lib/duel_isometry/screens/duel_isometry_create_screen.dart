// lib/duel_isometry/screens/duel_isometry_create_screen.dart
// Écran de création de room Duel Isométries avec sélecteur de taille Pentoscope
// 251204HHMM

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_data.dart';
import '../providers/duel_isometry_provider.dart';
import 'duel_isometry_waiting_screen.dart';

class DuelIsometryCreateScreen extends ConsumerStatefulWidget {
  const DuelIsometryCreateScreen({super.key});

  @override
  ConsumerState<DuelIsometryCreateScreen> createState() =>
      _DuelIsometryCreateScreenState();
}

class _DuelIsometryCreateScreenState
    extends ConsumerState<DuelIsometryCreateScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _selectedSizeIndex = 2; // 0=3x5, 1=4x5, 2=5x5

  final _sizeLabels = ['3x5', '4x5', '5x5'];
  final _sizeDescriptions = [
    '3 pieces, 15 cases (facile)',
    '4 pieces, 20 cases (moyen)',
    '5 pieces, 25 cases (difficile)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedName = ref.read(settingsProvider).duel.playerName;
      if (savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Map<String, int> _generatePuzzleTriple() {
    final configsForSize = pentoscopeData[_selectedSizeIndex];
    if (configsForSize == null || configsForSize.isEmpty) {
      throw Exception('Aucune configuration pour taille $_selectedSizeIndex');
    }

    final configIndex = Random().nextInt(configsForSize.length);
    final (bitmask, numSolutions) = configsForSize[configIndex];
    final solutionNum = Random().nextInt(numSolutions);

    print('[DUEL-ISO] Triple: taille=$_selectedSizeIndex, config=$configIndex, solution=$solutionNum');

    return {
      'taille': _selectedSizeIndex,
      'configIndex': configIndex,
      'solutionNum': solutionNum,
    };
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    setState(() => _isLoading = true);

    try {
      await ref.read(settingsProvider.notifier).setDuelPlayerName(name);
      final puzzleTriple = _generatePuzzleTriple();
      await ref.read(duelIsometryProvider.notifier).createRoom(name, puzzleTriple);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DuelIsometryWaitingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creer une partie'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Section Pseudo
              const Text(
                'Entrez votre pseudo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Pseudo',
                  hintText: 'Ex: Max',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un pseudo';
                  }
                  if (value.trim().length < 2) {
                    return 'Minimum 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Section Taille
              const Text(
                'Choisir la taille du plateau',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Column(
                children: List.generate(
                  _sizeLabels.length,
                      (index) => RadioListTile<int>(
                    value: index,
                    groupValue: _selectedSizeIndex,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSizeIndex = value);
                      }
                    },
                    title: Text(
                      _sizeLabels[index],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_sizeDescriptions[index]),
                    tileColor: _selectedSizeIndex == index
                        ? Colors.purple.shade50
                        : Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton Creer
              ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Creer la partie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}