// lib/duel_isometry/screens/duel_isometry_lobby_screen.dart
// Lobby pour créer/rejoindre une partie Duel Isométries

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/duel_isometry_provider.dart';
import 'duel_isometry_screen.dart';

class DuelIsometryLobbyScreen extends ConsumerStatefulWidget {
  const DuelIsometryLobbyScreen({super.key});

  @override
  ConsumerState<DuelIsometryLobbyScreen> createState() => _DuelIsometryLobbyScreenState();
}

class _DuelIsometryLobbyScreenState extends ConsumerState<DuelIsometryLobbyScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController(text: 'Joueur');

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel Isométries'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.rotate_90_degrees_ccw, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Duel Isométries',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Reconstruisez la configuration cible en appliquant les bonnes isométries.\n'
                          'Le joueur avec le moins d\'isométries gagne !',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nom du joueur
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Votre nom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 24),

              // Créer une partie
              ElevatedButton.icon(
                onPressed: _createRoom,
                icon: const Icon(Icons.add),
                label: const Text('Créer une partie'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Ou séparateur
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OU'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              // Rejoindre une partie
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code de la partie',
                  hintText: 'Entrez le code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                textCapitalization: TextCapitalization.characters,
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _joinRoom,
                icon: const Icon(Icons.login),
                label: const Text('Rejoindre'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              const Spacer(),

              // Règles
              TextButton(
                onPressed: _showRules,
                child: const Text('Voir les règles'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre nom')),
      );
      return;
    }

    final success = await ref.read(duelIsometryProvider.notifier).createRoom(name);
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DuelIsometryScreen()),
      );
    }
  }

  void _joinRoom() async {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un code de partie')),
      );
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre nom')),
      );
      return;
    }

    final success = await ref.read(duelIsometryProvider.notifier).joinRoom(code, name);
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DuelIsometryScreen()),
      );
    }
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Règles du Duel Isométries'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎯 OBJECTIF', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Reconstruire la configuration cible en appliquant les bonnes isométries aux pièces.\n'),

              Text('📐 ISOMÉTRIES', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• R : Rotation 90° horaire\n'
                  '• L : Rotation 90° anti-horaire\n'
                  '• H : Symétrie horizontale\n'
                  '• V : Symétrie verticale\n'),

              Text('🏆 SCORING', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Le joueur avec le MOINS d\'isométries gagne\n'
                  '• En cas d\'égalité, le plus rapide gagne\n'
                  '• Efficacité = Optimal / Vos isométries × 100%\n'),

              Text('🎮 ROUNDS', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 4 rounds : 3×5, 4×5, 5×5, 6×5\n'
                  '• Difficulté croissante\n'
                  '• Premier à 3 victoires gagne'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Compris !'),
          ),
        ],
      ),
    );
  }
}