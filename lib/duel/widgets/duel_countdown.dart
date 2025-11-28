// lib/duel/widgets/duel_countdown.dart
// Affichage du compte à rebours (3, 2, 1, GO!)

import 'package:flutter/material.dart';

class DuelCountdown extends StatelessWidget {
  final int value; // 3, 2, 1, 0 (0 = GO!)

  const DuelCountdown({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 300),
          key: ValueKey(value),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Text(
            value == 0 ? 'GO!' : '$value',
            style: TextStyle(
              fontSize: value == 0 ? 120 : 150,
              fontWeight: FontWeight.bold,
              color: value == 0 ? Colors.green : Colors.white,
              shadows: const [
                Shadow(
                  blurRadius: 20,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
