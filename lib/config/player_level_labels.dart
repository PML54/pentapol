// Modified: 2026-11-17 09:07 — ceintures acquises par six défis chronométrés.
// lib/config/player_level_labels.dart
import 'package:pentapol/config/challenge_belts.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

String playerLevelLabel(AppLocalizations l10n, int level) {
  final size = sizeForLevel(level.clamp(1, kMaxLevel));
  return l10n.homeSoloProgress(
    level.clamp(1, kMaxLevel),
    size.width,
    size.height,
  );
}

String playerSizeLabel(AppLocalizations l10n, PentoscopeSize size) =>
    size.index < 6
    ? beltLabel(l10n, size.index + 1)
    : playerLevelLabel(l10n, size.index + 1);
