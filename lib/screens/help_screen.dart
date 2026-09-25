// Modified: 2026-09-25 03:14 — lampe scindée en deux entrées (rouge, jaune) placées en tête
//           de l'aide : leur compréhension est prioritaire.
// lib/screens/help_screen.dart
// Historique: 2026-09-25 03:11 — icônes sur fond clair : les deux icônes quasi-blanches
//           (settings, undo) foncées pour rester lisibles ; couleurs saturées inchangées.
// Historique: 2026-09-25 02:56 — Nouvel écran d'Aide décrivant les icônes du jeu :
//           les 13 entrées de GameIcons (dédupliquées) + home, nouvelle partie et la lampe.

import 'package:flutter/material.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/l10n/app_localizations.dart';

/// Écran d'Aide : liste « icône + libellé + description » de toutes les icônes du jeu.
///
/// Les 13 icônes cataloguées viennent de [GameIcons.getIconsForMode] (mode normal +
/// isométries, dédupliquées : `settings` est commun aux deux). Trois icônes de la barre
/// d'action du plateau ne sont pas dans le registre `GameIcons` (posées en dur dans
/// `pentoscope_game_screen.dart`) et sont ajoutées à la main : retour à l'accueil, nouvelle
/// partie et la lampe (indice / retour en arrière).
///
/// Tous les textes passent par [AppLocalizations] (EN/FR). Les libellés/descriptions figés
/// dans `game_icons_config.dart` restent une source de vérité provisoire, non consommée ici.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = _entries(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _buildRow(entries[index]),
        ),
      ),
    );
  }

  Widget _buildRow(_HelpEntry entry) {
    return ListTile(
      // Icône directement sur le fond clair de la liste. Les couleurs de jeu sont pensées
      // pour la barre sombre : les deux icônes quasi-blanches (settings, undo) y seraient
      // invisibles, donc foncées ici. Les couleurs saturées restent inchangées.
      leading: SizedBox(
        width: 40,
        child: Icon(entry.icon, color: _displayColor(entry.color), size: 30),
      ),
      title: Text(entry.label),
      subtitle: Text(entry.description),
      isThreeLine: entry.description.length > 60,
    );
  }

  /// Couleur d'affichage sur fond clair : fonce les couleurs quasi-blanches (invisibles
  /// autrement), laisse les couleurs saturées (bleu, vert, violet, rouge, ambre) telles quelles.
  Color _displayColor(Color color) =>
      color.computeLuminance() > 0.7 ? Colors.blueGrey.shade700 : color;

  /// Construit la liste des entrées d'aide : catalogue `GameIcons` dédupliqué, puis les trois
  /// icônes hors registre de la barre d'action du plateau.
  List<_HelpEntry> _entries(AppLocalizations l10n) {
    // La lampe est un seul bouton physique à deux états ; sa compréhension est prioritaire,
    // donc ses deux couleurs ouvrent l'aide, chacune sur sa propre ligne.
    final entries = <_HelpEntry>[
      _HelpEntry(
        Icons.lightbulb,
        Colors.red,
        l10n.helpLampRedLabel,
        l10n.helpDescLampRed,
      ),
      _HelpEntry(
        Icons.lightbulb,
        Colors.amber,
        l10n.helpLampAmberLabel,
        l10n.helpDescLampAmber,
      ),
    ];

    // Catalogue `GameIcons` : mode normal puis isométries, dédupliqué par identité
    // (`settings` figure dans les deux modes).
    final configs = <GameIconConfig>[
      ...GameIcons.getIconsForMode(GameMode.normal),
      ...GameIcons.getIconsForMode(GameMode.isometries),
    ];
    final seen = <GameIconConfig>[];
    for (final config in configs) {
      if (seen.any((c) => identical(c, config))) continue;
      seen.add(config);
      entries.add(_entryFor(config, l10n));
    }

    // Autres icônes hors `GameIcons`, posées en dur dans pentoscope_game_screen.dart
    // (la lampe, également hors registre, est déjà traitée en tête).
    entries.addAll([
      _HelpEntry(
        Icons.home_outlined,
        Colors.blueGrey,
        l10n.homeTooltip,
        l10n.helpDescHome,
      ),
      _HelpEntry(
        Icons.add_circle_outline,
        Colors.blue,
        l10n.newGame,
        l10n.helpDescNewGame,
      ),
    ]);

    return entries;
  }

  /// Associe une entrée `GameIcons` à ses textes localisés, par identité de la constante.
  _HelpEntry _entryFor(GameIconConfig c, AppLocalizations l10n) {
    if (identical(c, GameIcons.settings)) {
      return _HelpEntry(c.icon, c.color, l10n.settingsTitle, l10n.helpDescSettings);
    }
    if (identical(c, GameIcons.enterIsometries)) {
      return _HelpEntry(c.icon, c.color, l10n.helpLabelEnterIso, l10n.helpDescEnterIso);
    }
    if (identical(c, GameIcons.exitIsometries)) {
      return _HelpEntry(c.icon, c.color, l10n.helpLabelExitIso, l10n.helpDescExitIso);
    }
    if (identical(c, GameIcons.viewSolutions)) {
      return _HelpEntry(
        c.icon,
        c.color,
        l10n.helpLabelViewSolutions,
        l10n.helpDescViewSolutions,
      );
    }
    if (identical(c, GameIcons.solutionsCounter)) {
      return _HelpEntry(
        c.icon,
        c.color,
        l10n.helpLabelSolutionsCounter,
        l10n.helpDescSolutionsCounter,
      );
    }
    if (identical(c, GameIcons.rotatePiece)) {
      return _HelpEntry(c.icon, c.color, l10n.helpLabelRotate, l10n.helpDescRotate);
    }
    if (identical(c, GameIcons.removePiece)) {
      return _HelpEntry(c.icon, c.color, l10n.helpLabelRemove, l10n.helpDescRemove);
    }
    if (identical(c, GameIcons.undo)) {
      return _HelpEntry(c.icon, c.color, l10n.helpLabelUndo, l10n.helpDescUndo);
    }
    if (identical(c, GameIcons.isometryRotationTW)) {
      return _HelpEntry(c.icon, c.color, l10n.isoRotateTW, l10n.helpDescIsoRotateTW);
    }
    if (identical(c, GameIcons.isometryRotationCW)) {
      return _HelpEntry(c.icon, c.color, l10n.isoRotateCW, l10n.helpDescIsoRotateCW);
    }
    if (identical(c, GameIcons.isometrySymmetryH)) {
      return _HelpEntry(c.icon, c.color, l10n.isoSymH, l10n.helpDescIsoSymH);
    }
    if (identical(c, GameIcons.isometrySymmetryV)) {
      return _HelpEntry(c.icon, c.color, l10n.isoSymV, l10n.helpDescIsoSymV);
    }
    if (identical(c, GameIcons.isometryDelete)) {
      return _HelpEntry(c.icon, c.color, l10n.isoRemove, l10n.helpDescIsoDelete);
    }
    // Filet de sécurité : une icône ajoutée au registre sans entrée d'aide reste visible,
    // avec au moins son libellé figé (provisoire) plutôt qu'une ligne vide.
    return _HelpEntry(c.icon, c.color, c.tooltip, c.description);
  }
}

/// Une ligne de l'écran d'aide : icône, sa couleur d'affichage, libellé, description.
class _HelpEntry {
  final IconData icon;
  final Color color;
  final String label;
  final String description;

  const _HelpEntry(this.icon, this.color, this.label, this.description);
}
