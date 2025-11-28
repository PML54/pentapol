// lib/duel/screens/duel_create_screen.dart
// Écran de création de partie (affiche le code)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelCreateScreen extends ConsumerStatefulWidget {
  const DuelCreateScreen({super.key});

  @override
  ConsumerState<DuelCreateScreen> createState() => _DuelCreateScreenState();
}

class _DuelCreateScreenState extends ConsumerState<DuelCreateScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une partie'),
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
            const SizedBox(height: 24),
            // TODO: Bouton créer
            ElevatedButton(
              onPressed: () {
                // TODO: Créer la room
              },
              child: const Text('Créer'),
            ),
            // TODO: Afficher le code de la room
            // TODO: Boutons Copier / Partager
            // TODO: Message "En attente d'un adversaire..."
          ],
        ),
      ),
    );
  }
}
