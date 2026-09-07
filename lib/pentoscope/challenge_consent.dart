// Modified: 2026-09-07 07:34 — conformité défi V1 : proposition unique de l'opt-in à la 1re complétion
//           d'un défi (maybeProposeConsentOnChallengeCompletion, gardée par challengeConsentAsked).
// lib/pentoscope/challenge_consent.dart
// Historique: 2026-09-07 07:17 — conformité défi V1 : consentement à l'envoi de score (§4.5/§8). Le
//           classement n'est accessible qu'après un opt-in explicite ; sinon un dialogue le propose.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';

/// Ouvre le classement en ligne, en demandant d'abord le **consentement** (CDC §4.5/§8) si le
/// joueur n'a pas encore activé l'envoi de score. S'il refuse, **rien ne s'ouvre** (le classement
/// reste dormant tant qu'on ne participe pas). S'il accepte, l'opt-in est activé et — si
/// [submitAfterOptIn] — le score du défi qu'on vient de terminer est soumis avant l'ouverture.
///
/// [builder] fabrique l'écran de classement à pousser (typiquement un `LeaderboardScreen`).
Future<void> openLeaderboardWithConsent(
  BuildContext context,
  WidgetRef ref, {
  required Widget Function() builder,
  bool submitAfterOptIn = false,
}) async {
  final optedIn = ref.read(settingsProvider).shareScoresOptIn;
  if (!optedIn) {
    final accepted = await showChallengeConsentDialog(context);
    if (accepted != true) return; // refus → on n'ouvre pas le classement
    await ref.read(settingsProvider.notifier).setShareScoresOptIn(true);
    if (submitAfterOptIn) {
      // Le défi tout juste terminé n'avait pas été soumis (opt-in absent) : on le soumet maintenant.
      await ref.read(pentoscopeProvider.notifier).submitChallengeScore();
    }
  }
  if (!context.mounted) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder()));
}

/// Propose l'opt-in **une seule fois** à la première complétion d'un défi (choix de Paul, 2026-09-07).
/// Ne fait rien si l'opt-in est déjà donné ou si la proposition a déjà eu lieu (`challengeConsentAsked`).
/// En cas d'acceptation : active l'opt-in et **soumet le défi qu'on vient de terminer**. Le refus
/// n'ouvre rien et ne redemandera plus automatiquement (activable ensuite via Réglages / classement).
Future<void> maybeProposeConsentOnChallengeCompletion(
  BuildContext context,
  WidgetRef ref,
) async {
  final s = ref.read(settingsProvider);
  if (s.shareScoresOptIn || s.challengeConsentAsked) return;
  await ref.read(settingsProvider.notifier).setChallengeConsentAsked(true); // proposition unique
  if (!context.mounted) return;
  final accepted = await showChallengeConsentDialog(context);
  if (accepted != true) return;
  await ref.read(settingsProvider.notifier).setShareScoresOptIn(true);
  await ref.read(pentoscopeProvider.notifier).submitChallengeScore();
}

/// Dialogue expliquant ce qui est envoyé, avec activation explicite (« geste explicite », §8).
Future<bool?> showChallengeConsentDialog(BuildContext context) {
  final loc = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(loc.consentTitle),
      content: Text(loc.consentBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(loc.consentLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(loc.consentEnable),
        ),
      ],
    ),
  );
}
