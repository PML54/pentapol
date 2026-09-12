// Modified: 2026-09-11 10:25 — coche rebondissante et confettis sur pose réussie, sans bloquer le plateau.
// lib/pentoscope/home/guided_success_celebration.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Effet purement visuel. Une nouvelle clé redémarre la célébration à chaque pose.
class GuidedSuccessCelebration extends StatefulWidget {
  final Offset origin;
  final bool complete;
  const GuidedSuccessCelebration({
    super.key,
    required this.origin,
    required this.complete,
  });

  @override
  State<GuidedSuccessCelebration> createState() =>
      _GuidedSuccessCelebrationState();
}

class _GuidedSuccessCelebrationState extends State<GuidedSuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.complete ? 1400 : 850),
  );
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.value = 1;
      started = true;
    } else if (!started) {
      started = true;
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.isCompleted) return const SizedBox.shrink();
            return CustomPaint(
              key: const ValueKey('guided-celebration-paint'),
              painter: _SuccessPainter(
                controller.value,
                widget.origin,
                widget.complete,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    ),
  );
}

class _SuccessPainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final bool complete;
  _SuccessPainter(this.progress, this.origin, this.complete);

  static const colors = [
    Color(0xFFFFC107),
    Color(0xFF42A5F5),
    Color(0xFFEC407A),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final unit = size.shortestSide;
    final center = Offset(origin.dx * size.width, origin.dy * size.height);
    final opacity = ((1 - t) / .35).clamp(0.0, 1.0);
    final paint = Paint();
    final count = complete ? 56 : 26;
    for (var i = 0; i < count; i++) {
      final angle = i * 2.399963;
      final speed = unit * (.28 + (i % 7) * .065) * (complete ? 1.4 : 1);
      final position =
          center +
          Offset(
            math.cos(angle) * speed * t,
            math.sin(angle) * speed * t + size.height * .3 * t * t,
          );
      final radius = unit * (.012 + (i % 3) * .004);
      paint.color = colors[i % colors.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + t * (i.isEven ? 5 : -5));
      if (i % 3 == 0) {
        final star = Path();
        for (var point = 0; point < 10; point++) {
          final theta = point * math.pi / 5 - math.pi / 2;
          final r = radius * (point.isEven ? 1.5 : .6);
          if (point == 0) {
            star.moveTo(math.cos(theta) * r, math.sin(theta) * r);
          } else {
            star.lineTo(math.cos(theta) * r, math.sin(theta) * r);
          }
        }
        canvas.drawPath(star..close(), paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: radius * 1.2,
              height: radius * 2.5,
            ),
            Radius.circular(radius * .25),
          ),
          paint,
        );
      }
      canvas.restore();
    }
    final pop = Curves.easeOutBack.transform((t / .3).clamp(0.0, 1.0));
    final radius = unit * (complete ? .18 : .12) * pop;
    if (radius <= 0) return;
    final badge = center.translate(0, -unit * .04 * math.sin(math.pi * t));
    paint.color = Colors.white.withValues(alpha: opacity);
    canvas.drawCircle(badge, radius + 3, paint);
    paint.color = const Color(0xFF43A047).withValues(alpha: opacity);
    canvas.drawCircle(badge, radius, paint);
    final check = Path()
      ..moveTo(badge.dx - radius * .48, badge.dy)
      ..lineTo(badge.dx - radius * .1, badge.dy + radius * .35)
      ..lineTo(badge.dx + radius * .52, badge.dy - radius * .34);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SuccessPainter old) =>
      old.progress != progress ||
      old.origin != origin ||
      old.complete != complete;
}
