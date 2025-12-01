// lib/duel/widgets/duel_scoreboard.dart
// Scoreboard style football avec animations

import 'package:flutter/material.dart';

class DuelScoreboard extends StatelessWidget {
  final String player1Name;
  final int player1Score;
  final String player2Name;
  final int player2Score;
  final int timeRemaining;
  final bool isPlayer1Local;

  const DuelScoreboard({
    super.key,
    required this.player1Name,
    required this.player1Score,
    required this.player2Name,
    required this.player2Score,
    required this.timeRemaining,
    required this.isPlayer1Local,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = timeRemaining < 30;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade700,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Joueur 1 (gauche)
          Expanded(
            child: _AnimatedPlayerScore(
              name: player1Name,
              score: player1Score,
              color: Colors.cyan,
              isLocal: isPlayer1Local,
              alignment: CrossAxisAlignment.start,
            ),
          ),

          // Timer central
          _AnimatedTimer(
            timeRemaining: timeRemaining,
            isUrgent: isUrgent,
          ),

          // Joueur 2 (droite)
          Expanded(
            child: _AnimatedPlayerScore(
              name: player2Name,
              score: player2Score,
              color: Colors.orange,
              isLocal: !isPlayer1Local,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Score animé d'un joueur
class _AnimatedPlayerScore extends StatefulWidget {
  final String name;
  final int score;
  final Color color;
  final bool isLocal;
  final CrossAxisAlignment alignment;

  const _AnimatedPlayerScore({
    required this.name,
    required this.score,
    required this.color,
    required this.isLocal,
    required this.alignment,
  });

  @override
  State<_AnimatedPlayerScore> createState() => _AnimatedPlayerScoreState();
}

class _AnimatedPlayerScoreState extends State<_AnimatedPlayerScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  int _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.score;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 25.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 25.0, end: 8.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_AnimatedPlayerScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score != _previousScore) {
      _previousScore = widget.score;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.alignment,
      children: [
        // Nom du joueur avec indicateur local
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isLocal && widget.alignment == CrossAxisAlignment.start)
              _localIndicator(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                widget.name.toUpperCase(),
                style: TextStyle(
                  color: widget.color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (widget.isLocal && widget.alignment == CrossAxisAlignment.end)
              _localIndicator(),
          ],
        ),
        const SizedBox(height: 6),

        // Score avec animation
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(minWidth: 55),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.color.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: _glowAnimation.value,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '${widget.score}',
                    key: ValueKey<int>(widget.score),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      shadows: [
                        Shadow(
                          color: widget.color,
                          blurRadius: _glowAnimation.value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Label "pièces"
        const SizedBox(height: 2),
        Text(
          'pièces',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _localIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: const Icon(
          Icons.person,
          size: 12,
          color: Colors.green,
        ),
      ),
    );
  }
}

/// Timer central animé
class _AnimatedTimer extends StatefulWidget {
  final int timeRemaining;
  final bool isUrgent;

  const _AnimatedTimer({
    required this.timeRemaining,
    required this.isUrgent,
  });

  @override
  State<_AnimatedTimer> createState() => _AnimatedTimerState();
}

class _AnimatedTimerState extends State<_AnimatedTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_AnimatedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUrgent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isUrgent && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = widget.isUrgent ? Colors.red : Colors.amber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Points lumineux du haut
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlowingDot(color: timerColor, size: 6),
              const SizedBox(width: 8),
              _GlowingDot(color: timerColor, size: 6),
            ],
          ),
          const SizedBox(height: 4),

          // Timer
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = widget.isUrgent ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: timerColor.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: timerColor.withOpacity(widget.isUrgent ? 0.6 : 0.3),
                        blurRadius: widget.isUrgent ? 15 : 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    _formatTime(widget.timeRemaining),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: timerColor,
                      shadows: [
                        Shadow(
                          color: timerColor,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 4),
          // Points lumineux du bas
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlowingDot(color: timerColor, size: 6),
              const SizedBox(width: 8),
              _GlowingDot(color: timerColor, size: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Point lumineux avec pulsation
class _GlowingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _GlowingDot({
    required this.color,
    this.size = 8,
  });

  @override
  State<_GlowingDot> createState() => _GlowingDotState();
}

class _GlowingDotState extends State<_GlowingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 3.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.8),
                blurRadius: _animation.value,
                spreadRadius: 0,
              ),
            ],
          ),
        );
      },
    );
  }
}