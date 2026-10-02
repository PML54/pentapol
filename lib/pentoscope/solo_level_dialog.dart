// Modified: 2026-10-02 06:49 — proposer uniquement les niveaux Solo déjà débloqués.
// lib/pentoscope/solo_level_dialog.dart
import 'package:flutter/material.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

Future<int?> showSoloLevelDialog(
  BuildContext context, {
  required int unlockedLevel,
}) async {
  final maximum = unlockedLevel.clamp(1, kMaxLevel);
  if (maximum == 1) return 1;
  final l10n = AppLocalizations.of(context);
  return showDialog<int>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.chooseSoloLevel),
      children: [
        for (var level = 1; level <= maximum; level++)
          SimpleDialogOption(
            key: ValueKey('solo-level-$level'),
            onPressed: () => Navigator.pop(context, level),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                l10n.soloLevelOption(
                  level,
                  sizeForLevel(level).width,
                  sizeForLevel(level).height,
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ),
      ],
    ),
  );
}
