// lib/duel/screens/duel_join_screen.dart
// Écran pour rejoindre une partie (saisir le code)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelJoinScreen extends ConsumerStatefulWidget {
  const DuelJoinScreen({super.key});

  @override
  ConsumerState<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

class _DuelJoinScreenState extends ConsumerState<DuelJoinScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre une partie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Champ nom du joueur
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Votre pseudo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Champ code de la room
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code de la partie',
                border: OutlineInputBorder(),
                hintText: 'ABC123',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            const SizedBox(height: 24),
            // TODO: Bouton rejoindre
            ElevatedButton(
              onPressed: () {
                // TODO: Rejoindre la room
              },
              child: const Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
  }
}
