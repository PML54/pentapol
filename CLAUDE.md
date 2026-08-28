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
  classical/               jeu classique 6×10 (provider, écran, état)
  common/                  modèles et services partagés (Pento, PlacedPiece, Plateau…)
  config/                  constantes UI (tailles, icônes)
  data/                    documentation backend (pas de code Dart)
  database/                drift — persistance des réglages
  debug/                   outils de mise au point
  l10n/                    localisation
  models/                  app_settings
  pentoscope/              module Pentoscope (drag & drop, snapping, scoring)
  pentoscope_multiplayer/  mode duel — WebSocket, Cloudflare Durable Objects
  providers/               providers Riverpod transverses
  screens/                 écrans et widgets partagés
  services/                solveurs, matcher de solutions, chargeurs
  utils/                   géométrie, helpers
```

## Modules actifs

| Module | État | Notes |
|---|---|---|
| `classical` | actif | jeu classique de pentominos, plateau 6×10 |
| `pentoscope` | actif | drag & drop, snapping magnétique, scoring isométrique |
| `pentoscope_multiplayer` | actif | duel WebSocket, Cloudflare Durable Objects |

> Le tutoriel n'a pas de module propre : il est intégré au provider de `classical`.
> Il n'existe **ni** `lib/duel/` **ni** `lib/tutorial/` — une version antérieure de
> ce fichier les annonçait à tort.

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
// Modified: 2026-08-27 16:04 — garde d'initialisation : le jeu n'est plus monté
//           avant que les 9356 solutions soient chargées.
// lib/classical/pentomino_game_screen.dart
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
6. **Vérifier plutôt qu'affirmer.** Ce projet contient des invariants combinatoires
   (2339 solutions canoniques, 9356 après expansion) : ils se contrôlent par
   exécution, pas par raisonnement.

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
- `docs/JOURNAL.md` — état courant, décisions prises, passations
- `tools/` — 14 outils d'analyse statique (imports, orphelins, doublons, isolation
  des modules) alimentant `tools/db/pentapol.db`

## Développeur

- Paul Marie Larivière — ingénieur systèmes UNIX, ex-IT manager
- Expérience : Fortran, C/C++, Unix, Dart/Flutter
- Autres apps publiées : PuzHub, SudokuRix, Luchy
- Style : approche systémique, architecture propre, comprendre avant d'appliquer.
  Attend qu'on sépare les faits, les hypothèses et les opinions, et qu'on présente
  les objections sérieuses avant de conclure.
