# AGENTS.md — Pentapol

> Ce fichier doit rester **à la racine du dépôt**. Il est la **source unique des
> consignes communes** à tous les agents : architecture, conventions, contrôles et
> passations. Modifier ces consignes ici uniquement ; `CLAUDE.md` les importe via
> `@AGENTS.md` et ne doit pas en contenir de copie.
> Un `AGENTS.md` imbriqué peut préciser les règles du sous-répertoire concerné.
> Ce fichier n'est pas exécuté par Flutter. L'état courant appartient à `docs/JOURNAL.md`.

## Identité du projet

- **Nom** : Pentapol
- **Plateformes cibles** : iOS (iPhone, App Store) **et Android** (APK/Play Store) — décision de
  Paul, 2026-09-08. Le jeu tourne déjà en APK release. ⚠️ Ne pas supprimer le scaffold `android/` ;
  le scaffold `macos/` a été retiré (cible non visée). Les deux stores sont dans le périmètre de
  `docs/CHECKLIST_APPSTORE.md`.
- **Backend** : Cloudflare Workers + Durable Objects (mode multijoueur)

## Repères dans `lib/`

- `lib/data/` ne contient que de la documentation backend, pas de code Dart.
- Démarrage sur `HomeScreen` (`main.dart`) ; au premier lancement, parcours de découverte
  5×5 (`DiscoveryScreen`). Règles de validation et de reproposition : `docs/ACCUEIL_GUIDE.md`.

## Modules actifs

| Module | État | Notes |
|---|---|---|
| `pentoscope` | actif | **le seul module de jeu.** Tailles 3×5 à 5×10 (puzzles à pièces tirées) et 6×10 (rectangle complet adossé aux 9356 solutions) |
| `pentoscope_multiplayer` | actif | duel WebSocket, Cloudflare Durable Objects ; consomme le provider de `pentoscope` |

> ⚠️ **Le module `classical` a été supprimé le 2026-08-29** (`371c3d5`), avec
> `lib/screens/pentomino_game/`, l'écran d'accueil et le tutoriel — −3197 lignes.
> Pentoscope est désormais la référence unique de la manipulation des pièces. Une
> version antérieure de ce fichier annonçait aussi `lib/duel/` et `lib/tutorial/`, qui
> n'ont jamais existé. Conséquence pour `common/` : voir l'invariant 5.

## Convention de header — OBLIGATOIRE

Tout fichier `.dart` modifié porte, **en première ligne**, la date, l'heure et la
raison du changement :

```dart
// Modified: YYYY-MM-DD HH:MM — <raison courte et spécifique>
//           <continuation indentée si nécessaire>
// lib/[MODULE]/[CHEMIN]/fichier.dart
// Historique: <ancienne ligne Modified, si elle existait>
```

Exemple :

```dart
// Modified: 2026-08-29 09:26 — 6×10 temps 2 : les réponses « solution » passent par
//           une SolutionSource choisie au démarrage du puzzle.
// lib/pentoscope/solution_source.dart
// Historique: 251226120030 — Démarrage du timer à la première pièce touchée
```

**Règles de forme :**

- Date en **ISO** `YYYY-MM-DD`, heure en `HH:MM`, séparées par une espace.
  L'ordre lexicographique est l'ordre chronologique — c'est ce qui rend les
  recherches par date possibles.
- **Vérifier la date avec `date` avant d'écrire.** Ne jamais la déduire du contexte.
- Une seule ligne `Modified:` par fichier : on **met à jour** l'existante, on n'empile
  pas. L'ancienne valeur passe en `Historique:`.
- Raison factuelle et spécifique. « mise à jour » ne dit rien. Préciser quand le
  changement ne touche que des commentaires.

Recherches par date et garde-fou « header pas à jour » : `docs/MODUS_VIVENDI.md` §6.

> **Format antérieur, abandonné** : `YYMMDDHHMMM` (avec un `M` de trop) placé après
> la ligne de chemin. Il n'était pas triable entre formats, et ses gabarits n'étaient
> jamais remplis — `251213HHMMSS` et `250101HHMMM` traînaient tels quels dans le
> dépôt. Les fichiers non encore migrés gardent leur ancienne ligne ; ne pas les
> normaliser en masse sans demander.

## Règles impératives

1. **Ne jamais commiter sans demander explicitement** à l'utilisateur.
2. **Toujours écrire le header** sur chaque fichier `.dart` modifié.
3. **Expliquer avant d'agir** : décrire ce qui va être modifié avant de toucher au code.
4. **Imports absolus uniquement** — jamais de `../` dans les imports Dart.
5. **0 erreur de compilation** avant tout commit (`flutter analyze`).
6. **Base de données — tant que l'app n'est pas publiée** : réécriture destructive,
   `schemaVersion` incrémenté, pas de migration. **À partir de la première version sur
   l'App Store** : migration réelle, et **jamais** de stratégie destructive — elle
   effacerait les données des joueurs, des mois plus tard, quand personne ne se souviendra
   qu'elle est là. Son retrait fait partie de `docs/CHECKLIST_APPSTORE.md`.
7. **Vérifier plutôt qu'affirmer.** Ce projet contient des invariants combinatoires
   (2339 solutions canoniques, 9356 après expansion) : ils se contrôlent par
   exécution, pas par raisonnement.
8. **Aucune chaîne visible en dur.** Depuis le 2026-09-06 l'app est bilingue EN/FR
   (`flutter_localizations` + ARB). Toute chaîne affichée à l'utilisateur passe par
   `AppLocalizations` et existe dans **`app_en.arb` ET `app_fr.arb`** ; jamais de
   `Text('texte français')`. Procédure, pièges (`const` sans `context`, helpers) et
   littéraux volontairement gardés : `docs/I18N.md`. Régénérer avec `flutter gen-l10n`
   après toute édition d'ARB ; les fichiers générés `lib/l10n/app_localizations*.dart`
   sont versionnés.

## Invariants et pièges — vérifiés, à ne pas redécouvrir

Ces points ont coûté du temps une fois. Ils remplacent la §DÉCISIONS du journal, supprimée le
2026-08-31 ; le reste de son contenu est dans `git log`.

1. **Chaque source de solutions a son périmètre.** `TableSolutionSource` utilise les tables
   6×10 : rectangle complet, aucune case masquée (`-1`), les 12 pièces présentes.
   `CorpusSolutionSource` utilise le corpus 5×n correspondant au masque des pièces tirées.
   Ne jamais interroger la table 6×10 pour conclure sur un tirage partiel.
2. **Une génération interrompue n'est pas une table complète.** L'ancien solveur, supprimé
   de l'app, s'arrêtait silencieusement après 30 secondes : il avait produit 8175 solutions
   au lieu de 9356. Pour toute nouvelle génération, contrôler la complétude par exécution
   et signaler explicitement les interruptions. Aucun solveur backtracking dans l'app livrée.
3. **Les tailles d'affichage s'ancrent sur le plateau, pas sur l'appareil.** Une pièce dans la
   barre et la même pièce sur le plateau sont la même chose : `pieceCellSize =
   boardCellSize × k`. Aucun seuil, aucune détection de tablette — tout écran est traité, y
   compris ceux qui n'existent pas encore.
4. **Énumérer les valeurs existantes rate les widgets qui n'en ont aucune.** Un `grep` sur les
   constantes de taille ne trouve pas les `IconButton` sans `size:`, qui héritent du défaut.
   Quand un réglage doit s'appliquer à un ensemble, passer par l'**héritage** (`IconTheme`,
   une liste unique rendue deux fois), jamais par une liste de sites.
5. **La couche `common/` n'a plus qu'un seul client.** `PieceManipulationState`,
   `GameTimerMixin`, `PieceInteractionMixin`, `PentominoGameMixin` avaient été extraits pour
   tenir **deux** implémentations alignées ; le mode classique a été supprimé. Ils gardent
   leur valeur de découpage, pas leur valeur de contrainte — ne pas chercher la seconde
   implémentation qu'ils sont censés contraindre.
6. **`AppSettings` est sérialisé en JSON** dans une ligne de la table `Settings` : un champ
   ajouté ou retiré ne demande **aucune migration**.
7. **Le plateau reste toujours légal.** Les isométries s'appliquent librement sur une pièce **du
   rack** ; sur une pièce **posée**, elles ne s'appliquent que si le résultat est valide (aucun
   chevauchement, même transitoire). Ce n'est pas un choix d'interface mais un **invariant
   structurel** : le **compteur de solutions** apparie contre un corpus de placements **légaux**,
   et le **classifieur de fautes** (`fault_analysis`) mesure des transitions soluble→insoluble —
   une superposition illégale n'est pas « insoluble », elle est **hors modèle**. Un plateau qui
   accueillerait un chevauchement fausserait les deux **en silence**. Le refus se manifeste par
   **grisage préventif** des boutons dont l'opération échouerait (pas de message, choix de Paul).

8. **Les défis version 3 ont une solution exacte unique.** Date UTC, taille et corpus
   versionné déterminent localement le même départ avec ou sans réseau ; les définitions
   composées du serveur ne remplacent pas ce départ. Des pièces fixes minimales isolent
   un pavage stocké en laissant au moins la moitié des pièces à jouer. Elles sont verrouillées,
   hors tiroir, hors coups et hors minimum théorique. Toute modification du tirage ou du
   choix des indices incrémente `kChallengeVersion` pour séparer les résultats.

9. **Ceintures indépendantes du Solo.** Blanche au départ, puis six défis de 3×5 à
   5×8, seuils inclusifs 30/60/90/120/150/180 secondes enregistrées. Seule la grille
   correspondant au prochain grade permet sa promotion. Chaque nouveau jour UTC,
   tous les joueurs repartent au premier défi, quelle que soit leur ceinture ; le
   suivant exige la réussite du précédent dans son temps limite. Ceinture acquise persistante,
   plusieurs promotions le même jour UTC, nouvelle tentative le lendemain après un
   dépassement. Le consentement réseau n’influence pas le grade local. La remise à
   zéro des statistiques ne doit ni retirer une ceinture ni autoriser un rejeu du passage.

## Protocole entre agents — OBLIGATOIRE

Deux rôles interviennent sur ce dépôt, quel que soit l’outil (Codex ou Claude) :
**l’agent de développement (CLI)** écrit le code, compile, teste et fait tout le git ;
**l’agent d’analyse/documentation (cowork)** analyse, documente et écrit les plans. Ils ne partagent **aucune mémoire**. Le dépôt est le seul canal.
Mémo complet : `docs/MODUS_VIVENDI.md`.

1. **Au démarrage** : lire `docs/JOURNAL.md` §ÉTAT, puis le plan qu'il cite.
2. **Toute décision non prévue au plan** s'écrit dans `docs/JOURNAL.md` §ÉTAT et
   se signale en §PASSATIONS **avant** le commit qui l'applique. Les règles durables
   rejoignent les invariants du projet. Ne pas recréer §DÉCISIONS, supprimée le 2026-08-31.
3. **En fin de travail** : réécrire §ÉTAT, ajouter une ligne en §PASSATIONS.
4. **Ne jamais ranger un fait de projet dans la mémoire privée d’un agent**
   (notamment `~/.codex/`, `~/.claude/` ou une mémoire de compte) : elle n’est pas
   partagée entre agents. Ce qui doit survivre va dans `docs/`.
5. **`docs/` appartient au CLI côté git.** Un doc qui pilote un travail de code est
   commité DANS le même commit que ce code. Un doc sans code derrière est commité
   seul, en début de session suivante, avant toute modification de `lib/`.
   Vérification : `git status -s docs/` doit être vide en fin de session.

> ⚠️ `flutter analyze` ne signale pas une méthode **publique** sans appelant. Il ne
> peut donc pas confirmer qu'un nettoyage est complet : vérifier au `grep`, par nom.

> ⚠️ **Le test se fait sur appareil, par Paul** :
> `flutter run --release -d 00008150-000165D4027B401C` (iPhone).
> Aucun agent ne juge le ressenti d'un geste. Ne jamais écrire « non testé » faute de
> rapport : demander, ou ne rien affirmer. En `--release`, `debugPrint` est supprimé —
> ne pas formuler de critère d'acceptation sur la console.

## Documentation de référence

- `docs/JOURNAL.md` — **à lire en premier** : état courant et passations.
- `docs/CHECKLIST_APPSTORE.md` — ce qui doit être fait ou défait avant la première
  soumission ; toute décision qui crée une dette de production s'y inscrit avec sa raison.
- `docs/INDEX_DOCS.md` — index de toute la documentation (encodage `bit6` et BigInt 360 bits,
  pièces, persistance, i18n, sessions cloud…).
- `tools/` — outils d'analyse statique alimentant `tools/db/pentapol.db`.

> Les plans **appliqués et testés sont supprimés**, pas archivés — `git log` les conserve.

## Développeur

- Paul Marie Larivière — ingénieur systèmes UNIX, ex-IT manager
- Expérience : Fortran, C/C++, Unix, Dart/Flutter
- Autres apps publiées : PuzHub, SudokuRix, Luchy
- Style : approche systémique, architecture propre, comprendre avant d'appliquer.
  Attend qu'on sépare les faits, les hypothèses et les opinions, et qu'on présente
  les objections sérieuses avant de conclure.
