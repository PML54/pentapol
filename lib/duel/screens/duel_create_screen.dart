// lib/duel/screens/duel_create_screen.dart
// Écran de création de room avec nom sauvegardé via SQLite (SettingsProvider)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/providers/settings_provider.dart';
import '../providers/duel_provider.dart';
import 'duel_waiting_screen.dart';

class DuelCreateScreen extends ConsumerStatefulWidget {
  const DuelCreateScreen({super.key});

  @override
  ConsumerState<DuelCreateScreen> createState() => _DuelCreateScreenState();
}

class _DuelCreateScreenState extends ConsumerState<DuelCreateScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Charger le nom sauvegardé depuis SQLite
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

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Sauvegarder le nom dans SQLite
      await ref.read(settingsProvider.notifier).setDuelPlayerName(name);

      // Créer la room
      await ref.read(duelProvider.notifier).createRoom(name);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DuelWaitingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedName = ref.watch(settingsProvider).duel.playerName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une partie'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.blue),
              const SizedBox(height: 32),

              const Text(
                'Entrez votre pseudo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              if (savedName != null && savedName.isNotEmpty)
                Text(
                  'Dernier pseudo utilisé',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Pseudo',
                  hintText: 'Ex: Max',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Veuillez entrer un pseudo';
                  if (value.trim().length < 2) return 'Minimum 2 caractères';
                  return null;
                },
                onFieldSubmitted: (_) => _createRoom(),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Créer la partie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}