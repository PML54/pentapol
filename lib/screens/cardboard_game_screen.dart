// Modified: 2026-11-13 07:02 — ajouter la variante en cubes de bois et sa peinture après le carton.
// Historique: 2026-11-13 06:16 — ordonner règles, recherche personnelle puis fabrication du jeu.
// Historique: 2026-11-12 07:20 — présenter l’atelier carton bilingue et ouvrir son modèle.
// lib/screens/cardboard_game_screen.dart

import 'package:flutter/material.dart';
import 'package:pentapol/config/pentapol_website.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class CardboardGameScreen extends StatefulWidget {
  const CardboardGameScreen({super.key});

  @override
  State<CardboardGameScreen> createState() => _CardboardGameScreenState();
}

class _CardboardGameScreenState extends State<CardboardGameScreen> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _openTemplate() async {
    final language = Localizations.localeOf(context).languageCode;
    final uri = cardboardActivityUri(language);
    if (uri == null || _opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Le message et le bouton de reprise restent dans la page.
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      _failed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final available =
        cardboardActivityUri(Localizations.localeOf(context).languageCode) !=
        null;
    final steps = [
      l10n.cardboardStepPrint,
      l10n.cardboardStepGlue,
      l10n.cardboardStepCut,
      l10n.cardboardStepPlay,
      l10n.cardboardStepInvent,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cardboardTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.cardboardSlogan, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              key: const ValueKey('cardboard-shapes'),
              margin: EdgeInsets.zero,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpShapesTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.helpShapesRule),
                    const SizedBox(height: 8),
                    Text(l10n.helpShapesCount),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.cardboardSearchTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.helpShapesChallenge, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(l10n.cardboardMakeTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.cardboardIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(
              l10n.cardboardMaterialsTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.cardboardMaterials, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            for (var index = 0; index < steps.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}.', style: theme.textTheme.bodyLarge),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            Text(l10n.cardboardAdultHelp, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text(l10n.cardboardWoodTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final paragraph in [
              l10n.cardboardWoodMaterials,
              l10n.cardboardWoodShapes,
              l10n.cardboardWoodGlue,
              l10n.cardboardWoodPaint,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(paragraph, style: theme.textTheme.bodyLarge),
              ),
            const SizedBox(height: 8),
            if (!available)
              Text(l10n.cardboardUnavailable, style: theme.textTheme.bodyLarge),
            if (_failed)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.cardboardOpenError,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('cardboard-download'),
              onPressed: available && !_opening ? _openTemplate : null,
              icon: const Icon(Icons.download_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_failed ? l10n.retry : l10n.cardboardDownload),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
