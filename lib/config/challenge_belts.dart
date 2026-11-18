// Modified: 2026-11-18 02:34 — départ quotidien au niveau 1 pour toutes les ceintures.
// Historique: 2026-11-17 09:44 — icône seule au profil et passages successifs dans le temps imparti.
// Historique: 2026-11-17 09:07 — ceintures acquises par six défis chronométrés.
// lib/config/challenge_belts.dart
import 'package:flutter/material.dart';
import 'package:pentapol/l10n/app_localizations.dart';

const beltColors = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFFFFD740),
  Color(0xFFF57C00),
  Color(0xFF268447),
  Color(0xFF1565C0),
  Color(0xFF795548),
  Color(0xFF212121),
];
const beltTimeLimits = <int>[30, 60, 90, 120, 150, 180];

String beltLabel(AppLocalizations l10n, int belt) => [
  l10n.beltWhite,
  l10n.beltYellow,
  l10n.beltOrange,
  l10n.beltGreen,
  l10n.beltBlue,
  l10n.beltBrown,
  l10n.beltBlack,
][belt.clamp(0, 6)];

/// Only the next belt's grid can promote. Time uses the game's recorded seconds.
int earnedChallengeBelt(int current, int sizeIndex, int seconds) {
  if (current < 0 || current >= 6 || sizeIndex != current || seconds < 0) {
    return current;
  }
  return seconds <= beltTimeLimits[current] ? current + 1 : current;
}

/// Small knotted belt, including a dark outline for white/yellow on light surfaces.
class BeltIcon extends StatelessWidget {
  final int belt;
  const BeltIcon({super.key, required this.belt});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: beltLabel(AppLocalizations.of(context), belt),
    child: Semantics(
      label: beltLabel(AppLocalizations.of(context), belt),
      image: true,
      child: CustomPaint(
        size: const Size(30, 24),
        painter: _BeltPainter(beltColors[belt.clamp(0, 6)]),
      ),
    ),
  );
}

class _BeltPainter extends CustomPainter {
  final Color color;
  const _BeltPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 30, size.height / 24);
    final fill = Paint()..color = color;
    final outline = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final band = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 5, 28, 7),
      const Radius.circular(2),
    );
    canvas.drawRRect(band, fill);
    canvas.drawRRect(band, outline);
    for (final points in [
      const [Offset(13, 9), Offset(18, 11), Offset(13, 23), Offset(8, 20)],
      const [Offset(14, 9), Offset(19, 9), Offset(24, 20), Offset(18, 23)],
    ]) {
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, outline);
    }
    final knot = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 5, 7, 8),
      const Radius.circular(2),
    );
    canvas.drawRRect(knot, fill);
    canvas.drawRRect(knot, outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BeltPainter oldDelegate) => color != oldDelegate.color;
}

/// Every belt starts at the first grid each day, then advances in order
/// only after completing the previous grid within its time limit.
bool canEnterBeltChallenge({
  required int belt,
  required int sizeIndex,
  required bool attemptedToday,
  required int lastSize,
  required bool lastPassed,
}) {
  if (sizeIndex < 0 || sizeIndex >= 6) return false;
  if (!attemptedToday) return sizeIndex == 0;
  return lastPassed && sizeIndex == lastSize + 1;
}
