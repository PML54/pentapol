# CLAUDE.md — Pentapol

> Ce fichier doit rester **à la racine du dépôt** (ou dans `.claude/`, traité à
> l'identique). Un `CLAUDE.md` placé dans un sous-répertoire comme `docs/` n'est
> **pas** chargé automatiquement : il n'est lu que lorsqu'on travaille dans ce
> répertoire. Ne pas le déplacer.

## Identité du projet

- **Nom** : Pentapol
- **Package Flutter** : `pentapol`
- **Langage** : Dart / Flutter
- **Plateforme cible** : iOS (iPhone, App Store)
- **Backend** : Cloudflare Workers + Durable Objects (mode multijoueur)
- **State management** : Riverpod
- **Imports** : absolus uniquement (`package:pentapol/...`), jamais de `../`

## Architecture réelle de `lib/`

```
lib/
  common/                  modèles, widgets et mixins partagés (Pento, PlacedPiece,
                           Plateau, PieceRenderer, GameTimerMixin…)
  config/                  constantes UI (tailles, icônes, layout)
  data/                    documentation backend (pas de code Dart)
  database/                drift — persistance des réglages
  debug/                   database_debug_screen (orphelin, voué à disparaître — §9)
  l10n/                    localisation
  models/                  app_settings
  pentoscope/              LE module de jeu : provider, plateau, barre, écrans,
                           générateur, solveur, sources de solutions
  pentoscope_multiplayer/  mode duel — WebSocket, Cloudflare Durable Objects
  providers/               providers Riverpod transverses (réglages)
  screens/                 settings_screen, custom_colors_screen
  services/                solveur hors-ligne, matcher de solutions, chargeur .bin
  utils/                   géométrie, helpers, export
```

L'application démarre **directement sur `PentoscopeGameScreen`** (`main.dart`) : il n'y
a plus d'écran d'accueil ni de route nommée.

## Modules actifs

| Module | État | Notes |
|---|---|---|
| `pentoscope` | actif | **le seul module de jeu.** Tailles 3×5 à 5×10 (puzzles à pièces tirées) et 6×10 (rectangle complet adossé aux 9356 solutions) |
| `pentoscope_multiplayer` | actif | duel WebSocket, Cloudflare Durable Objects ; consomme le provider de `pentoscope` |

> ⚠️ **Le module `classical` a été supprimé le 2026-08-29** (`371c3d5`), avec
> `lib/screens/pentomino_game/`, l'écran d'accueil et le tutoriel — −3197 lignes.
> Pentoscope est désormais la référence unique de la manipulation des pièces. Une
> version antérieure de ce fichier annonçait aussi `lib/duel/` et `lib/tutorial/`, qui
> n'ont jamais existé.
>
> Conséquence à connaître avant de toucher à `common/` : `PieceManipulationState`,
> `GameTimerMixin`, `PieceInteractionMixin` et `PentominoGameMixin` avaient été extraits
> pour tenir **deux** implémentations alignées. Il n'en reste qu'une. Ils gardent leur
> valeur de découpage, pas leur valeur de contrainte.

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
  recherches ci-dessous possibles.
- **Vérifier la date avec `date` avant d'écrire.** Ne jamais la déduire du contexte.
- Une seule ligne `Modified:` par fichier : on **met à jour** l'existante, on n'empile
  pas. L'ancienne valeur passe en `Historique:`.
- Raison factuelle et spécifique. « mise à jour » ne dit rien. Préciser quand le
  changement ne touche que des commentaires.

**Pourquoi ce format — les recherches qu'il permet :**

```bash
# fichiers modifiés un jour donné
grep -rl "^// Modified: 2026-08-27" lib --include='*.dart'

# avec la raison
grep -rn "^// Modified: 2026-08-27" lib --include='*.dart'

# tout ce qui a changé depuis une date (tri lexicographique = tri chronologique)
grep -rn "^// Modified: [0-9]\{4\}-" lib --include='*.dart' \
  | awk -F'Modified: ' '$2 >= "2026-01-01"'

# garde-fou : .dart modifié dans git mais header pas à jour
for f in $(git status --porcelain lib | awk '{print $NF}' | grep '\.dart$'); do
  [ -f "$f" ] && { head -1 "$f" | grep -q "^// Modified: $(date +%F)" \
    || echo "⚠ header non à jour : $f"; }
done
```

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

## Invariants et pièges — vérifiés, à ne pas redécouvrir

Ces points ont coûté du temps une fois. Ils remplacent la §DÉCISIONS du journal, supprimée le
2026-08-31 ; le reste de son contenu est dans `git log`.

1. **Les tables de solutions ne répondent que sur un rectangle complet.** « Compte > 0 ⟺ les
   pièces restantes peuvent remplir le plateau » n'est vrai que parce que **chaque solution
   de la table emploie les 12 pièces**. Sur une taille à pièces tirées, la table ne dit rien.
   Deux invariants sans lesquels elle répond faux **en silence** : aucune case masquée (`-1`),
   et les 12 pièces toutes présentes.
2. **`PentominoSolver.maxSeconds` vaut 30 et n'est pas paramétrable**, et `findAllSolutions`
   fait un simple `return` à l'expiration : l'appelant reçoit une liste **indistinguable**
   d'une liste complète. C'est ce qui a produit un fichier de 8175 solutions sur 9356 sans
   que rien ne le signale. **À corriger — signature et paramètre — avant toute génération de
   table.**
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

## Protocole entre agents — OBLIGATOIRE

Deux agents travaillent sur ce dépôt : **Claude Code (CLI)**, qui écrit le code,
compile, teste et fait tout le git ; et **Claude cowork**, qui analyse, documente et
écrit les plans. Ils ne partagent **aucune mémoire**. Le dépôt est le seul canal.
Mémo complet : `docs/MODUS_VIVENDI.md`.

1. **Au démarrage** : lire `docs/JOURNAL.md` §ÉTAT, puis le plan qu'il cite.
2. **Toute décision non prévue au plan** s'écrit dans `docs/JOURNAL.md` §DÉCISIONS
   **avant** le commit qui l'applique. Un message de commit n'est pas un canal :
   cowork ne le lit pas.
3. **En fin de travail** : réécrire §ÉTAT, ajouter une ligne en §PASSATIONS.
4. **Ne jamais ranger un fait de projet dans la mémoire `~/.claude/`** — elle est
   locale à cette machine et invisible pour cowork. Ce qui doit survivre va dans
   `docs/`.
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

## Stack technique

- Flutter SDK (dernière version stable), lints via `package:flutter_lints`
- Riverpod (state management)
- drift (persistance locale des réglages)
- Cloudflare Workers + Durable Objects + WebSocket (backend duel)
- BigInt 360 bits (encodage des solutions 6×10)
- SQLite (analyse de dépendances — voir `tools/`)

## Documentation de référence

- `docs/ANALYSE_STOCKAGE_POSITIONS.md` — encodage des plateaux et solutions,
  vérifications exécutées, défauts connus, fondement combinatoire du code `bit6`
- `docs/PIECES_ENCODING.md` — définition des pièces, `bit6`, isométries
- `docs/MODUS_VIVENDI.md` — répartition du travail entre le CLI et cowork,
  passations, règles de commit
- `docs/JOURNAL.md` — **à lire en premier** : état courant et passations (§DÉCISIONS
  supprimée le 2026-08-31 ; les règles vivantes sont ci-dessus, l'histoire est dans `git log`)
- `docs/PLAN_6X10_DANS_PENTOSCOPE.md` — le 6×10 et les tables de solutions
  pré-calculées ; §5 (tables 5×12 et 4×15) reste à appliquer
- `docs/CHECKLIST_APPSTORE.md` — **ce qui doit être fait ou défait avant la première
  soumission**. S'allonge au fil du travail : toute décision qui crée une dette de
  production s'y inscrit avec sa raison
- `docs/PLAN_PERSISTANCE.md` — ce que l'app garde sur l'appareil : quatre tables drift,
  la partie en cours, les records
> Les plans **appliqués et testés sont supprimés**, pas archivés — `git log` les conserve.
> Cinq l'ont été le 2026-08-31 (démo, unification, suppression classical, bilan, ergonomie).
- `tools/` — 14 outils d'analyse statique (imports, orphelins, doublons, isolation
  des modules) alimentant `tools/db/pentapol.db`

## Développeur

- Paul Marie Larivière — ingénieur systèmes UNIX, ex-IT manager
- Expérience : Fortran, C/C++, Unix, Dart/Flutter
- Autres apps publiées : PuzHub, SudokuRix, Luchy
- Style : approche systémique, architecture propre, comprendre avant d'appliquer.
  Attend qu'on sépare les faits, les hypothèses et les opinions, et qu'on présente
  les objections sérieuses avant de conclure.
