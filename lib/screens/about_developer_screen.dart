// Modified: 2026-09-25 15:16 — intégrer l'IA et ChatGPT au parcours informatique présenté.
// Historique: 2026-09-25 14:43 — créer la présentation du développeur et les remerciements.
// lib/screens/about_developer_screen.dart

import 'package:flutter/material.dart';
import 'package:pentapol/l10n/app_localizations.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutDeveloperTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            Icon(
              Icons.person_outline,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aboutDeveloperHeading,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            _Section(
              title: l10n.aboutDeveloperOriginsTitle,
              paragraphs: [
                l10n.aboutDeveloperOrigins1,
                l10n.aboutDeveloperOrigins2,
              ],
            ),
            _Section(
              title: l10n.aboutDeveloperComputingTitle,
              paragraphs: [
                l10n.aboutDeveloperComputing1,
                l10n.aboutDeveloperComputing2,
                l10n.aboutDeveloperComputing3,
              ],
            ),
            _Section(
              title: l10n.aboutDeveloperTributeTitle,
              paragraphs: [l10n.aboutDeveloperTribute],
            ),
            _Section(
              title: l10n.aboutDeveloperThanksTitle,
              paragraphs: [
                l10n.aboutDeveloperThanks1,
                l10n.aboutDeveloperThanks2,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> paragraphs;

  const _Section({required this.title, required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final paragraph in paragraphs) ...[
            Text(paragraph, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
