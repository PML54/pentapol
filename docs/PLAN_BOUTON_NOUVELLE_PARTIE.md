# Plan — bouton « Nouvelle partie » en fin de Solo, retrait du double tap

> Étape 1 (constats). Aucune modification de `lib/` à ce stade. En attente de
> l'accord de Paul avant l'Étape 2.

## Objectif

En **fin de partie solo**, afficher un bouton `Icons.add_circle_outline` (tooltip
« Nouvelle partie », zone tactile ≥ 48 dp) pour lancer une nouvelle partie, et
**retirer la mention « double tap »** du message de fin. Remplacer le geste
`onDoubleTap` devenu inutile par ce bouton.

## 1. Où le message de fin solo est construit

- `lib/pentoscope/screens/pentoscope_game_screen.dart`
  - `_buildGameCompletionBar(state, notifier)` — **lignes ~1541-1607**.
  - Appelé **uniquement** depuis la barre du haut quand
    `widget.mode == PentoscopeMode.game && state.isComplete` (**ligne 1444-1448**).
  - En mode `game`, l'état est toujours `isRanked == false` donc `solo == true`
    (`solo = !state.isRanked`, ligne 1554). **La branche non-solo de cette méthode
    — celle qui empile `l10n.gameTapNewGame` dans `parts` (ligne 1552) — n'est donc
    jamais atteinte par le chemin d'appel actuel** (le mode défi utilise
    `PentoscopeMode.challenge`, pas `game`). C'est du code mort dans ce contexte.
- La mention « double tap » affichée en solo est la chaîne **`soloDoubleTap`** :
  - construite dans `message` (ligne 1563 : `'${l10n.soloDoubleTap} · $stats'`) ;
  - rendue en **rouge** via le `TextSpan` (lignes 1592-1600).
- Chaîne de localisation `soloDoubleTap = "Double Tap"` :
  - `lib/l10n/app_fr.arb:242`, `lib/l10n/app_en.arb:404`
  - générée dans `app_localizations.dart:1481`, `app_localizations_fr.dart:865`,
    `app_localizations_en.dart:860`.

## 2. Où le double tap « nouvelle partie » est géré

Le handler est **`_handleGameBoardDoubleTap(state, notifier)`** (ligne 687), qui
appelle `_startChosenSoloLevel` → `showSoloLevelDialog` → `notifier.startPuzzle(...)`.

Il est câblé à **deux** endroits, tous deux gardés par `widget.mode == PentoscopeMode.game` :

1. **Overlay plein cadre `game-continue`**, affiché **seulement à la complétion**
   (`Positioned.fill`, lignes 577-585). C'est lui qui capte le double tap une fois
   la partie finie — c'est le geste que le message annonce.
2. **Paramètre `onDoubleTap` de `PentoscopeBoard`**, en portrait (lignes 1766-1768)
   et en paysage (lignes 1845-1847). ⚠️ Celui-ci est actif **pendant toute la
   partie**, pas seulement à la fin : double-taper le plateau en cours de jeu
   lance déjà le dialogue « nouvelle partie ».

## 3. ⚠️ Interaction à ne pas casser : `PentoscopeBoard.onDoubleTap`

Dans `lib/pentoscope/widgets/pentoscope_board.dart`, le paramètre `onDoubleTap` a un
**double rôle** (lignes 662-698) :

- Quand `widget.onDoubleTap == null` (modes **hors game**), un double tap sur une
  **pièce posée sélectionnée** fait **pivoter** la pièce (`applyIsometryRotationTW`,
  lignes 662-667).
- Quand `widget.onDoubleTap != null` (mode **game**), cette rotation par double tap
  est **désactivée** (branche `null`, ligne 667) et le plateau entier est enrobé d'un
  `GestureDetector` qui appelle `widget.onDoubleTap` → nouvelle partie (lignes 693-698).

**Conséquence pour l'Étape 2** : si on retire `onDoubleTap` du `PentoscopeBoard` en
mode game, le double tap de **rotation** d'une pièce posée **se réactive** en mode
game (comme dans les autres modes). C'est vraisemblablement souhaitable (cohérence
avec le reste), et cela supprime au passage les redémarrages accidentels en cours de
partie. **À confirmer par Paul.**

## 4. Autres usages du double tap — à NE PAS toucher

| Lieu | Fichier / ligne | Rôle | Mode(s) |
|---|---|---|---|
| Pièce du rack | `common/widgets/draggable_piece_widget.dart:130,162` | pivoter / sélectionner la pièce | tous (cœur du jeu) |
| Pièce posée sélectionnée | `pentoscope/widgets/pentoscope_board.dart:662-667` | pivoter | hors game |
| Fin de training | `pentoscope_game_screen.dart:571` (`_openGameFromTraining`) | passer au module Game | training |
| Reset overlay adversaire | `pentoscope_game_screen.dart:757` | recentrer le mini-plateau | game (overlay multi) |
| Reset overlay adversaire (MP) | `pentoscope_multiplayer/screens/pentoscope_mp_game_screen.dart:379` | recentrer | multijoueur |

Chaînes « double tap » **sans rapport** avec la fin de solo (à laisser) :
`recreationalTapAgain`, `recreationalTapTraining2` (flux training, `app_*.arb:239-240/401-402`),
`gameTapNewGame` (`app_*.arb:241/403`, seulement dans la branche morte du §1).

## 5. Proposition Étape 2 (option A)

1. Dans `_buildGameCompletionBar`, retirer le préfixe `soloDoubleTap` du message et
   du `TextSpan` (le bandeau ne présente plus que les stats défilantes), et ajouter
   un `IconButton(Icons.add_circle_outline)` — tooltip/semantics « Nouvelle partie »
   via une nouvelle clé ARB, `constraints`/`iconSize` garantissant ≥ 48 dp —
   qui appelle `_handleGameBoardDoubleTap(state, notifier)` (déjà la bonne action).
   Le bouton est rendu **à côté** du `GuidedScrollingMessage` (Row), affiché
   uniquement dans ce bandeau donc **uniquement en fin de partie solo**.
   - Point d'attention layout : la barre solo est clampée à 36-48 px de haut
     (ligne 1571-1573). Un IconButton 48 dp tient tout juste ; sinon élargir le clamp
     ou réduire la zone du message. À valider sur appareil.
2. Retirer le câblage `onDoubleTap` du `PentoscopeBoard` (lignes 1766-1768, 1845-1847)
   et l'overlay `game-continue` (lignes 577-585), devenus inutiles. Vérifier qu'aucun
   autre appelant ne reste (`grep _handleGameBoardDoubleTap`).
3. Supprimer la clé `soloDoubleTap` des deux ARB + régénérer (`flutter gen-l10n`),
   **si** plus aucun usage ne subsiste.
4. En-tête `Modified:` sur chaque `.dart` touché (date vérifiée par `date`).
5. `flutter analyze` (0 erreur) + tests ciblés (un test couvre déjà la fin de solo).

## 6. ⚠️ Point de procédure : §DÉCISIONS

L'Étape 2 demandée dit « noter la décision dans `docs/JOURNAL.md` §DÉCISIONS ». Or
**§DÉCISIONS a été supprimée le 2026-08-31** (CLAUDE.md §Protocole et en-tête du
JOURNAL : à ne pas recréer, c'était le point de collision entre agents). Le protocole
en vigueur veut que la décision soit écrite en **§ÉTAT + §PASSATIONS** (et, si elle
engage durablement, promue en règle dans CLAUDE.md §Invariants). **Je propose de la
consigner là plutôt qu'en §DÉCISIONS — à confirmer.**

## Questions ouvertes

- Réactivation du double tap de **rotation** d'une pièce posée en mode game (§3) : OK ?
- Le double tap « nouvelle partie » doit-il disparaître aussi **en cours de partie**
  (câblage §2.2), ou seulement à la complétion ? L'option A implique les deux.
- §DÉCISIONS vs §ÉTAT/§PASSATIONS (§6).
