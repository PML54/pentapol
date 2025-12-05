// lib/duel/screens/duel_join_screen.dart
// Écran pour rejoindre une room - Code 4 caractères, nom via SQLite

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/providers/settings_provider.dart';
import '../providers/duel_isometry_provider.dart';
import 'duel_isometry_game_screen.dart';
import 'duel_isometry_waiting_screen.dart';

class DuelJoinScreen extends ConsumerStatefulWidget {
  const DuelJoinScreen({super.key});

  @override
  ConsumerState<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

class _DuelJoinScreenState extends ConsumerState<DuelJoinScreen> {
  final _codeController = TextEditingController();
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
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Sauvegarder le nom dans SQLite
      await ref.read(settingsProvider.notifier).setDuelPlayerName(name);

      // Rejoindre la room
      await ref.read(duelIsometryProvider.notifier).joinRoom(code, name);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DuelIsometryWaitingScreen()),



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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre une partie'),
        backgroundColor: Colors.green,
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
              const Icon(Icons.group_add, size: 80, color: Colors.green),
              const SizedBox(height: 32),

              const Text(
                'Rejoindre une partie',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Code (4 caractères)
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Code de la partie',
                  hintText: 'AB12',
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  counterText: '',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  _UpperCaseFormatter(),
                ],
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
                textAlign: TextAlign.center,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Entrez le code';
                  if (value.trim().length != 4) return 'Code à 4 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pseudo
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Votre pseudo',
                  hintText: 'Ex: Max',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Entrez un pseudo';
                  if (value.trim().length < 2) return 'Minimum 2 caractères';
                  return null;
                },
                onFieldSubmitted: (_) => _joinRoom(),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _joinRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Rejoindre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
