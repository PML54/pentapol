// lib/duel/screens/duel_join_screen.dart
// Écran pour rejoindre une partie (saisir le code)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/duel_provider.dart';
import '../models/duel_state.dart';
import 'duel_game_screen.dart';

class DuelJoinScreen extends ConsumerStatefulWidget {
  const DuelJoinScreen({super.key});

  @override
  ConsumerState<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

class _DuelJoinScreenState extends ConsumerState<DuelJoinScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Joueur';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Entrez un pseudo');
      return;
    }

    if (code.isEmpty || code.length != 6) {
      setState(() => _errorMessage = 'Entrez un code à 6 caractères');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(duelProvider.notifier).joinRoom(code, name);

      if (success && mounted) {
        // La navigation vers le jeu sera gérée par le listener
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de rejoindre. Vérifiez le code.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état
    ref.listen<DuelState>(duelProvider, (previous, next) {
      // Erreur
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        setState(() {
          _errorMessage = next.errorMessage;
          _isLoading = false;
        });
      }

      // Partie commence (countdown ou playing)
      if (next.gameState == DuelGameState.countdown ||
          next.gameState == DuelGameState.playing) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DuelGameScreen(),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre une partie'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icône
              const Icon(
                Icons.group_add,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 32),

              // Titre
              const Text(
                'Rejoindre une partie',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Champ pseudo
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Votre pseudo',
                  hintText: 'Ex: Alice',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 8),

              // Champ code
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Code de la partie',
                  hintText: 'ABC123',
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  counterText: '',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                enabled: !_isLoading,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                onSubmitted: (_) => _joinRoom(),
              ),
              const SizedBox(height: 16),

              // Message d'erreur
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Bouton rejoindre
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Rejoindre',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info
              Text(
                'Demandez le code à votre adversaire',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formatter pour convertir en majuscules
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}