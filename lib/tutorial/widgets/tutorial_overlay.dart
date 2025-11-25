// lib/tutorial/widgets/tutorial_overlay.dart
// Overlay pour afficher les messages et contrôles du tutoriel

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tutorial_provider.dart';

/// Overlay qui s'affiche par-dessus le jeu pendant les tutoriels
class TutorialOverlay extends ConsumerWidget {
  const TutorialOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorialState = ref.watch(tutorialProvider);

    // Ne rien afficher si pas de tutoriel en cours
    if (!tutorialState.isRunning && tutorialState.currentMessage == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Message en haut
        if (tutorialState.currentMessage != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _MessageBox(message: tutorialState.currentMessage!),
          ),

        // Barre de progression en bas
        if (tutorialState.isRunning)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: _ProgressBar(
              progress: tutorialState.progress,
              currentStep: tutorialState.currentStep,
              totalSteps: tutorialState.totalSteps,
            ),
          ),
      ],
    );
  }
}

/// Boîte de message
class _MessageBox extends StatelessWidget {
  final String message;

  const _MessageBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.blue[700],
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre de progression
class _ProgressBar extends StatelessWidget {
  final double progress;
  final int currentStep;
  final int totalSteps;

  const _ProgressBar({
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Texte étape courante
            Text(
              'Étape $currentStep / $totalSteps',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
