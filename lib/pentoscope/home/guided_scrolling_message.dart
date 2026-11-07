// Modified: 2026-10-26 15:02 — afficher les consignes fixes, lisibles sans défilement.
// Historique: 2026-10-08 07:29 — permettre plusieurs couleurs de texte.
// lib/pentoscope/home/guided_scrolling_message.dart
import 'package:flutter/material.dart';

/// Consigne fixe ; le nom est conservé pour les appelants existants.
class GuidedScrollingMessage extends StatelessWidget {
  final String message;
  final TextStyle style;
  final double width;
  final TextSpan? textSpan;

  const GuidedScrollingMessage({
    super.key,
    required this.message,
    required this.style,
    required this.width,
    this.textSpan,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Semantics(
      label: message,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: width,
              child: textSpan == null
                  ? Text(
                      message,
                      key: const ValueKey('guided-message'),
                      style: style,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    )
                  : Text.rich(
                      textSpan!,
                      key: const ValueKey('guided-message'),
                      style: style,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
