// Modified: 2026-10-31 06:51 — conserver cinq étoiles avant 35 secondes en Isométries.
// Historique: 2026-10-31 06:45 — Isométries : acuité sur 10, étoiles et limite de trois minutes.
// Historique: 2026-10-09 09:41 — attendre la fin de l'aperçu avant le compte à rebours.
// Historique: 2026-10-09 09:27 — compte à rebours Training 60 s avec alerte visuelle progressive.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pentapol/l10n/app_localizations.dart';

class IsometryTrainingCountdown extends StatefulWidget {
  final bool complete;
  final bool ready;
  final VoidCallback? onExpired;
  const IsometryTrainingCountdown({
    super.key,
    required this.complete,
    this.ready = true,
    this.onExpired,
  });

  @override
  State<IsometryTrainingCountdown> createState() =>
      _IsometryTrainingCountdownState();
}

class _IsometryTrainingCountdownState extends State<IsometryTrainingCountdown> {
  Timer? _timer;
  int _seconds = 180;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    _startIfReady();
  }

  void _startIfReady() {
    if (widget.ready && !widget.complete && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
        final seconds = (180 - timer.tick ~/ 4).clamp(0, 180);
        final pulse = seconds > 0 && seconds <= 10 && timer.tick % 4 < 2;
        if (seconds != _seconds || pulse != _pulse) {
          setState(() {
            _seconds = seconds;
            _pulse = pulse;
          });
        }
        if (seconds == 0) {
          timer.cancel();
          widget.onExpired?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant IsometryTrainingCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startIfReady();
    if (widget.complete) {
      _timer?.cancel();
      _pulse = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _seconds <= 10
        ? Colors.red.shade700
        : _seconds <= 20
        ? Colors.orange.shade800
        : Colors.teal.shade700;
    final elapsed = 180 - _seconds;
    final stars = _seconds == 0
        ? 0
        : elapsed < 35
        ? 5
        : elapsed < 60
        ? 4
        : elapsed < 90
        ? 3
        : elapsed < 150
        ? 2
        : 1;
    final description = _seconds == 0
        ? l10n.trainingTimeExpired
        : l10n.trainingTimeRemaining(_seconds);
    return Tooltip(
      message: description,
      child: Semantics(
        key: const ValueKey('training-countdown'),
        label: '$description · ${l10n.isometryTrainingStars(stars)}',
        excludeSemantics: true,
        child: SizedBox(
          width: 100,
          height: 48,
          child: AnimatedOpacity(
            opacity: _pulse && !MediaQuery.disableAnimationsOf(context)
                ? 0.45
                : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    key: const ValueKey('training-stars'),
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < stars ? Icons.star : Icons.star_border,
                        size: 18,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                  Text(
                    l10n.trainingCountdownSeconds(_seconds),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
