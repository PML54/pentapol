// Modified: 2026-09-12 03:51 — défilement continu sans pause, vitesse doublée à 72 pixels logiques/s.
// Historique: 2026-09-12 03:40 — consigne défilante puis fixe, avec respect des réglages d’accessibilité.
// lib/pentoscope/home/guided_scrolling_message.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Défilement continu ; le texte répété assure un raccord sans saut entre les tours.
class GuidedScrollingMessage extends StatefulWidget {
  final String message;
  final TextStyle style;
  final double width;
  const GuidedScrollingMessage({
    super.key,
    required this.message,
    required this.style,
    required this.width,
  });
  @override
  State<GuidedScrollingMessage> createState() => _GuidedScrollingMessageState();
}

class _GuidedScrollingMessageState extends State<GuidedScrollingMessage>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this);
  double textWidth = 0;
  double cycleWidth = 0;
  bool stationary = false;

  void configure() {
    final media = MediaQuery.of(context);
    stationary = media.disableAnimations || media.accessibleNavigation;
    final painter = TextPainter(
      text: TextSpan(text: widget.message, style: widget.style),
      textDirection: Directionality.of(context),
      textScaler: media.textScaler,
      maxLines: 1,
    )..layout();
    textWidth = painter.width.ceilToDouble();
    painter.dispose();
    cycleWidth = math.max(widget.width, textWidth + 48);
    controller.stop();
    controller.duration = Duration(
      milliseconds: (cycleWidth / 72 * 1000).ceil(),
    );
    controller.value = 0;
    if (!stationary) controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    configure();
  }

  @override
  void didUpdateWidget(covariant GuidedScrollingMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.width != widget.width ||
        oldWidget.style != widget.style) {
      configure();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    child: Semantics(
      label: widget.message,
      liveRegion: true,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                if (stationary) {
                  return Center(
                    child: Text(
                      widget.message,
                      key: const ValueKey('guided-message'),
                      style: widget.style,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final dx = -controller.value * cycleWidth;
                return OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: cycleWidth + textWidth,
                  maxWidth: cycleWidth + textWidth,
                  child: Transform.translate(
                    key: const ValueKey('guided-message-motion'),
                    offset: Offset(dx, 0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: cycleWidth,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.message,
                              key: const ValueKey('guided-message'),
                              style: widget.style,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: textWidth,
                          child: Text(
                            widget.message,
                            style: widget.style,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
