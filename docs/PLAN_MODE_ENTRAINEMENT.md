# Plan — Mode entraînement (rotation mentale)

> Écrit le 2026-09-08 par cowork, d'après la spécification de Paul (session du 2026-09-08).
> Destiné au CLI. À **supprimer** une fois appliqué et testé sur device (`MODUS_VIVENDI` §5).
>
> Tous les nombres de ce document sortent d'un calcul rejouable
> (`tools/verif_isometries.py` + BFS sur les mêmes quatre générateurs) ; aucun n'est une estimation.

---

## 1. Intention

Le tutoriel a été supprimé le 2026-08-28 (`519f5ff` — c'était une **démo automatique**, l'app se
jouait toute seule, 696 lignes, plus 11 méthodes `*ForTutorial` orphelines). Le bloquant produit
n°8 de `CHECKLIST_APPSTORE.md` (« aucun onboarding ») est ouvert depuis.

Le mode entraînement est un **exercice interactif de rotation mentale** : il n'automatise rien,
il fait manipuler. Il vise la compétence que rien n'enseigne aujourd'hui — reconnaître qu'une
pièce du rack devient la forme visée après une ou deux isométries.

**Ce n'est pas un mode noté.** Aucune écriture dans `PuzzleStats`, `SolvedSolutions` ni au
classement en ligne. Le temps et le nombre d'appuis sont un **retour de fin d'exercice**, pas un
record : les records sont gelés par la règle n°6 et ne doivent pas être pollués.

---

## 2. Niveau 1 — une pièce

### Tirage

1. Tirer une pièce parmi les douze, une **orientation cible** et une **position** sur le plateau.
2. Afficher la forme obtenue en **surbrillance** sur le plateau (pièce fantôme / *ghost piece* —
   pas « ombré », qui veut dire dégradé).
3. Mettre **la même pièce** au rack, dans une **orientation différente** de la cible.
4. Le joueur applique rotations et symétries, puis superpose la pièce sur la surbrillance.

### Règles non négociables (sinon le code casse)

- **Cas du X.** Le X n'a **qu'une seule orientation** : « une orientation différente de la cible »
  n'existe pas. Décision de Paul : on garde le X. Alors, **sur le X uniquement**, le rack porte la
  pièce telle quelle et l'exercice se réduit à la **pose** (minimum 0 appui). Sans cette règle, la
  boucle de tirage « tant que orientation ≠ cible » ne se termine jamais.
- **Le I ne fournit que 2 exercices**, tous deux à un appui. Normal, ce n'est pas un bug.
- **Validation par égalité des ensembles de cases occupées**, jamais par égalité d'indices
  d'orientation : sur une pièce symétrique, deux indices distincts peuvent décrire la même forme.
- **Tirage avec `PentapolRng`** (du dépôt, testé) et non `dart:math`, pour que le tirage soit
  reproductible — donc testable.
- **L'orientation tirée doit tenir dans le plateau.** Voir §4.

### Retour de fin d'exercice

- appuis effectués, temps, et le **minimum** requis, calculé par
  `Pento.minIsometriesToReach(startPos, endPos)` (`lib/common/pentominos.dart` l. 795) —
  **primitive déjà présente et orpheline** : ce mode la réutilise, il n'y a rien à écrire.
- Formulation : « 5 appuis — 2 suffisaient ». Informatif, pas comparatif.

---

## 3. Niveau 2 — deux pièces collées

Extension demandée par Paul. Deux pièces adjacentes (par une arête) forment une région de
**10 cases**, affichée en **une seule surbrillance**. Le rack porte les deux pièces, dans des
orientations quelconques.

Le joueur doit alors trouver **comment la région se découpe** avant d'orienter — c'est la première
chose du vrai jeu que ce mode enseigne, et elle se prolonge vers 3 puis 4 pièces, c'est-à-dire vers
le jeu lui-même.

**Règle obligatoire : accepter TOUT pavage valide de la région**, pas seulement celui qui a été
tiré. Une même région se pave souvent de plusieurs façons avec les deux mêmes pièces (le rectangle
2×5, par exemple). Refuser une réponse correcte parce qu'elle n'est pas celle du tirage est le pire
retour possible dans un mode d'entraînement.

**Corollaire :** le minimum d'appuis affiché est le **minimum sur l'ensemble des pavages valides**
de la région, pas sur le pavage tiré.

---

## 4. Choix du plateau — contrainte calculée

Paul : « prendre un des plateaux existants ». Le choix n'est pas libre : **la cible doit tenir dans
le plateau dans l'orientation tirée**.

- Boîte englobante du I : **1×5**. Sur un `size3x5`, le I vertical ne rentre pas → le I ne fournit
  **aucun** exercice, et toutes les orientations de hauteur 4 (L, Y, N, P…) sautent également, soit
  près de la moitié du catalogue.
- Aucune boîte englobante de pentomino ne dépasse 5, et seul le I atteint 5.

→ **`size5x5` est le plus petit plateau où les 63 orientations rentrent.** C'est le plateau par
défaut du mode. Un `size6x10` pour une seule pièce en surbrillance ne fait que rapetisser les cases
sur un téléphone sans rien apporter.

---

## 5. Catalogue — ce que le mode contient réellement

Exercices distincts au niveau 1 (couples orientation de départ ≠ orientation cible), et minimum
d'appuis requis, par pièce :

| pièce | orientations | exercices | à 1 appui | à 2 appuis |
|---|---|---|---|---|
| F, L, N, P, Y | 8 | 56 chacune | 32 | 24 |
| V, W, Z | 4 | 12 chacune | 8 | 4 |
| T, U | 4 | 12 chacune | 12 | 0 |
| I | 2 | 2 | 2 | 0 |
| X | 1 | 0 (pose seule) | — | — |

**Total : 342 exercices distincts** — 210 à un appui (61,4 %), 132 à deux. Minimum moyen sur tirage
uniforme : **1,386 appui**. Le diamètre du graphe de Cayley engendré par les quatre boutons de la
barre est **2** (`REFERENCE_ISOMETRIES.md` §2) : aucune orientation ne demande jamais plus de deux
appuis.

Le mode n'a donc pas 12 exercices mais 342 — la rejouabilité est réelle.

**Recommandation (non bloquante) :** un tirage uniforme donne 61 % d'exercices à un seul appui,
c'est-à-dire trop faciles trop souvent. Tirer plutôt **sur la distance** : premiers exercices à
1 appui, puis exclusivement parmi les 132 paires à 2 appuis. Le gradient sort du calcul, pas d'un
réglage à l'œil.

---

## 6. Stockage

Les résultats vont dans le **JSON d'`AppSettings`** (nouveau champ, `null` = jamais joué),
**pas** dans une table drift : un bump de `schemaVersion` déclenche aujourd'hui une réécriture
destructive, qui est le bloquant n°3 de la checklist. Invariant #6 : le JSON ne demande pas de
migration.

---

## 7. Ce que ce mode n'enseigne pas

À dire franchement pour que personne ne coche le bloquant n°8 trop vite : le mode entraînement
apprend à poser une pièce et à l'orienter. Il **n'explique ni le compteur décroissant de solutions,
ni la lampe rouge, ni le but du jeu** (remplir un rectangle) — c'est-à-dire précisément ce que
Pentapol a de singulier.

Le n°8 ne sera refermé qu'avec un écran de plus : une vraie partie 3×5 avec le compteur visible et
une phrase qui dit ce qu'il compte. À planifier séparément.

---

## 8. Corrections documentaires à passer dans le même lot

Vérifiées au `ls`/`grep` sur l'arbre du 2026-09-08 :

1. **`CHECKLIST_APPSTORE.md` point 1** (« `flutter test` est rouge à cause de `widget_test.dart` ») —
   le fichier **n'existe plus**. Point à retirer.
2. **Point 2** (« retirer `supabase_flutter` ») — **absent** de `pubspec.yaml` et de `pubspec.lock`.
   Point à retirer.
3. **§4, « trois fichiers orphelins »** — `bigint_plateau`, `shape_recognizer` et
   `ui_layout_provider` sont **supprimés**. Seul `ui_dimensions.dart` subsiste ; ligne à corriger.
4. **Point 7 (numéro de build)** — reformuler. `scripts/update_version.sh` est un **outil de
   développement** : il n'écrit que `lib/config/build_info.dart`, et c'est voulu (décision de Paul,
   2026-09-08). `pubspec.yaml` est renseigné **à la main le jour de la soumission**. Ce n'est donc
   pas une divergence à corriger mais un **point de contrôle de soumission**.
5. **Bloquant n°9** — les tables **5×12 et 4×15 sont abandonnées** (décision de Paul, 2026-09-08 :
   inadaptées au format téléphone). Son remède devient le « second remède » du point 10, déjà décidé
   le 2026-08-31 : énumérer les solutions du tirage sur les petites tailles et brancher une
   `ListSolutionSource`, pour que le compteur décroissant, le navigateur et l'alerte « aucune
   solution » existent hors 6×10. À écrire dans la checklist pour que le n°9 ne reste pas sans remède.
6. **`CLAUDE.md`** — **Android est dans le périmètre** (décision de Paul, 2026-09-08). Le fichier dit
   aujourd'hui « Plateforme cible : iOS », et c'est cette ligne que le CLI a invoquée le 2026-09-08
   pour supprimer le scaffold `macos/`, le jour même où Paul testait un APK release. À corriger, ainsi
   que le périmètre de `CHECKLIST_APPSTORE.md` (Play Console, keystore, métadonnées EN/FR ×2 stores).

---

## 9. Vérifications attendues du CLI

- `flutter analyze lib test` : 0 erreur, 0 warning.
- Tests neufs : terminaison du tirage **sur les douze pièces X compris** ; validation par ensembles
  de cases sur une pièce symétrique (T ou I) ; `minIsometriesToReach` cohérente avec la table du §5
  (342 couples, 210/132) ; acceptation d'un pavage alternatif au niveau 2.
- Aucune écriture dans `PuzzleStats` / `SolvedSolutions` depuis le mode entraînement (preuve au grep).
- i18n : clés EN **et** FR dès l'écriture (l'app est bilingue depuis le 2026-09-06).
