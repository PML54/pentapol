// Modified: 2026-09-12 10:58 — fenêtre de calibrage avec aperçu, sauvegarde et retour aux valeurs initiales.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/geometry_score.dart';
import 'package:pentapol/providers/settings_provider.dart';

class GeometrySettingsScreen extends ConsumerStatefulWidget {
  const GeometrySettingsScreen({super.key});

  @override
  ConsumerState<GeometrySettingsScreen> createState() =>
      _GeometrySettingsState();
}

class _GeometrySettingsState extends ConsumerState<GeometrySettingsScreen> {
  GeometryRules? _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ref.read(settingsProvider.notifier).ensureLoaded();
    if (mounted) {
      setState(() => _draft = ref.read(settingsProvider).game.geometryRules);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(settingsProvider.notifier).setGeometryRules(_draft!);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).geometrySaveError),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rules = _draft;
    final format = NumberFormat('0.##', l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.geometryTitle)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton(
          key: const ValueKey('geometry-save'),
          onPressed: rules == null || _saving ? null : _save,
          child: Text(l10n.save),
        ),
      ),
      body: rules == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.geometryExperimental,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.geometryNextGame),
                        const SizedBox(height: 20),
                        _slider(
                          'initial',
                          l10n.geometryInitial,
                          rules.initialScore,
                          10,
                          100,
                          18,
                          (v) => rules.copyWith(initialScore: v),
                          format,
                        ),
                        _slider(
                          'coefficient',
                          l10n.geometryCoefficient,
                          rules.fillPenalty,
                          0,
                          50,
                          100,
                          (v) => rules.copyWith(fillPenalty: v),
                          format,
                        ),
                        _slider(
                          'exponent',
                          l10n.geometryExponent,
                          rules.exponent,
                          1,
                          4,
                          12,
                          (v) => rules.copyWith(exponent: v),
                          format,
                        ),
                        Text(l10n.geometryExponentHelp),
                        const SizedBox(height: 12),
                        _slider(
                          'area',
                          l10n.geometryAreaBonus,
                          rules.areaPenalty,
                          0,
                          50,
                          100,
                          (v) => rules.copyWith(areaPenalty: v),
                          format,
                        ),
                        const Divider(height: 32),
                        Text(
                          l10n.geometryPreview,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Table(
                          key: const ValueKey('geometry-preview'),
                          columnWidths: const {0: FlexColumnWidth(.7)},
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(
                              children:
                                  [
                                        l10n.geometryPreviewFill,
                                        l10n.geometryPreviewOrdinary,
                                        l10n.geometryPreviewArea,
                                      ]
                                      .map(
                                        (s) => Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                            for (final ratio in [.2, .5, .8, .9])
                              TableRow(
                                children:
                                    [
                                          NumberFormat.percentPattern(
                                            l10n.localeName,
                                          ).format(ratio),
                                          '−${format.format(rules.penalty(ratio, invalidArea: false))}',
                                          '−${format.format(rules.penalty(ratio, invalidArea: true))}',
                                        ]
                                        .map(
                                          (s) => Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          key: const ValueKey('geometry-defaults'),
                          onPressed: _saving
                              ? null
                              : () => setState(
                                  () => _draft = const GeometryRules(),
                                ),
                          icon: const Icon(Icons.restore),
                          label: Text(l10n.geometryDefaults),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _slider(
    String id,
    String label,
    double value,
    double min,
    double max,
    int divisions,
    GeometryRules Function(double) update,
    NumberFormat format,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$label : ${format.format(value)}'),
        Slider(
          key: ValueKey('geometry-$id'),
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: format.format(value),
          semanticFormatterCallback: format.format,
          onChanged: _saving ? null : (v) => setState(() => _draft = update(v)),
        ),
      ],
    );
  }
}
