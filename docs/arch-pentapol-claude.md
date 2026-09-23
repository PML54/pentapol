# ARCHITECTURE — Pentapol

> Écrit le 2026-09-22 par Claude cowork à partir des sources (`lib/`, `pubspec.yaml`,
> `docs/JOURNAL.md` §ÉTAT). Version `1.0.7+7`, ~23 300 lignes Dart hors code généré.
> Ce document décrit **ce qui est** ; il ne prescrit rien. Vérifier le code avant intervention.

## 1. Pile technique

| Rôle | Choix | Où |
|---|---|---|
| État | Riverpod 3 (`flutter_riverpod`), `ProviderScope` à la racine | `main.dart` |
| Persistance locale | SQLite via l'ORM **drift** 2.29 (`drift_flutter`, `sqlite3_flutter_libs`) | `lib/database/` |
| Modèles immuables | `freezed` | `lib/models/app_settings.dart` |
| Données statiques | 3 assets binaires (`solutions_6x10_normalisees.bin`, `subset_counts.bin`, `solutions_corpus.bin`) | `assets/data/` |
| Réseau | `http` (REST) + `web_socket_channel` (WebSocket) | `pentoscope/challenge_api.dart`, `pentoscope_multiplayer/` |
| Backend | Cloudflare Workers + Durable Objects (hors dépôt) | `lib/data/cloudfare_architecture.md`, `docs/CLOUDFLARE_CONFIG.md` |
| i18n | `flutter_localizations` + `gen-l10n`, EN/FR | `lib/l10n/` |

Aucun solveur backtracking dans l'app livrée : toutes les réponses « solution » viennent des
tables pré-calculées (JOURNAL §ÉTAT, invariant n° 2 de `CLAUDE.md`).

## 2. Modules de `lib/`

| Répertoire | Contenu | Dépend de |
|---|---|---|
| `common/` | Noyau métier sans UI : `pentominos.dart` (12 pièces, orientations), `plateau.dart`, `placed_piece.dart`, `point.dart`, `pentomino_symmetry_api.dart` (isométries), mixins (`piece_interaction_mixin`, `pentomino_game_mixin`, `game_timer_mixin`), `pentapol_rng.dart`, `widgets/` (rendu d'une pièce, drag, bordures) | rien |
| `services/` | Chaîne 6×10 : `pentapol_solutions_loader.dart` (dépaquetage 6 bits → `List<BigInt>`, 2339 canoniques) → `solution_matcher.dart` (expansion ×4 → 9356, matching, décodage). Détail : `services.md` | `common/` |
| `pentoscope/` | **Le** module de jeu : `pentoscope_provider.dart` (état de partie), `pentoscope_generator.dart` (enum `PentoscopeSize` size3x5…size10x5 + size6x10, tirages), `solution_source.dart` (`CorpusSolutionSource` pour 5×n, `TableSolutionSource` pour 6×10), barème (`score_rules`, `geometry_score`, `fault_analysis`, `completion_metrics`), défis (`challenge*`), `home/` (accueil-menu, parcours guidé 3×5), `screens/`, `widgets/` | `common/`, `services/`, `database/`, `providers/` |
| `pentoscope_multiplayer/` | Duel en ligne : `models/` (messages, état), `providers/`, écrans lobby / partie / résultat | `pentoscope/` (réutilise son provider) |
| `database/` | Schéma drift + code généré | — |
| `providers/` | `settings_provider.dart` (réglages transverses) | `database/`, `models/` |
| `models/` | `AppSettings` (freezed, sérialisé JSON) | — |
| `screens/` | Réglages, couleurs personnalisées, réglages géométrie | `providers/` |
| `config/`, `utils/`, `l10n/` | Constantes UI, utilitaires (`piece_utils`, `solution_exporter`), traductions générées | — |
| `data/` | Documentation backend, pas de Dart | — |

Les 4 mixins de `common/` ont été extraits pour tenir deux implémentations alignées ; depuis la
suppression du mode classique (2026-08-29) il n'en reste qu'une (invariant n° 5).

## 3. Providers Riverpod

| Provider | Type | Fichier | Rôle |
|---|---|---|---|
| `settingsDatabaseProvider` | `Provider<SettingsDatabase>` | `providers/settings_provider.dart` | instance unique de la base drift |
| `settingsProvider` | `NotifierProvider<SettingsNotifier, AppSettings>` | idem | réglages ; `AppSettings` entier en JSON sous la clé `app_settings` de la table `Settings` |
| `pentoscopeProvider` | `NotifierProvider<PentoscopeNotifier, PentoscopeState>` | `pentoscope/pentoscope_provider.dart` | **le cœur** : partie, sauvegarde/reprise, compteurs, scores, défis — 3045 lignes |
| `pentoscopeSolutionsProvider` | `FutureProvider.family<SolutionMatcher, SolutionTable>` | `pentoscope/pentoscope_solutions_provider.dart` | charge une table 6×10 à la demande |
| `tirageCorpusProvider` | `FutureProvider<TirageCorpus>` | `pentoscope/corpus_provider.dart` | charge `solutions_corpus.bin` (5×n) |
| `dragOverBoardProvider` | `NotifierProvider<DragOverBoardNotifier, bool>` | `pentoscope/widgets/piece_drag_feedback.dart` | feedback de drag au-dessus du plateau |
| `pentoscopeMPProvider` | `NotifierProvider<PentoscopeMPNotifier, PentoscopeMPState>` | `pentoscope_multiplayer/providers/…` | salle, WebSocket, synchronisation duel |

## 4. Base locale (SQLite / drift, `schemaVersion = 11`)

Quatre tables (`lib/database/settings_database.dart`, détail dans `BASE_LOCALE.md`) :

| Table | Clé | Contenu |
|---|---|---|
| `Settings` | `key` texte | clé/valeur ; une seule ligne utilisée (`app_settings`, JSON) |
| `CurrentGame` | `id = 0` (ligne unique) | partie en cours pour reprise : taille, tirage, pièces posées (JSON), orientations, état géométrie (JSON), compteurs isométries / translations / suppressions / indices / fautes, temps, `savedAt` |
| `SolvedSolutions` | `board` + `solutionNumber` | nombre de résolutions, meilleurs acuité / fautes / temps, dates |
| `PuzzleStats` | `sizeName` | parties complétées et meilleurs scores par taille |

Migration **destructive** (drop + recreate à chaque bump) — règle n° 6 de `CLAUDE.md`, à retirer
avant publication (`CHECKLIST_APPSTORE.md`). C'est ce qui a vidé l'écran Records au schéma 11.

## 5. Backend

Deux Workers Cloudflare sous `pentapml.workers.dev` :

- `pentapol-defi` — REST : défis et classement (`pentoscope/challenge_api.dart`, `kChallengeBaseUrl`).
- `pentapol-duel` — REST `/room/create`, `/room/{code}/exists`, puis WebSocket `wss://…` sur un
  Durable Object (`pentoscope_multiplayer/providers/pentoscope_mp_provider.dart`).

## 6. Flux de démarrage

`main()` → `ProviderScope` → `PentapolApp` (`MaterialApp` localisé) → écran de chargement pendant
l'initialisation (réglages, générateur, tables) → `HomeScreen` (menu principal) →
`PentoscopeGameScreen` sur le niveau courant, ou duel / défis / records / réglages.

## 7. Observations (opinions, pas décisions)

- `pentoscope_provider.dart` (3045 l.) et `pentoscope_game_screen.dart` (2181 l.) concentrent
  l'essentiel de la logique : un provider unique porte partie, persistance, barème et défis.
  Conséquence : tests unitaires difficiles, et le multijoueur en dépend entièrement.
- `pentoscope/` mélange logique de jeu et écrans, alors que `common/` et `services/` sont purs.
- `providers/` ne contient que les réglages ; les autres providers vivent dans leur module.
  Ce n'est pas incohérent, mais le nom du répertoire le laisse croire.
