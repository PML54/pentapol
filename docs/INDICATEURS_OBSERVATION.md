# Indicateurs d'observation — le bandeau debug

> Créé le 2026-09-07. Référence de **tous les indicateurs affichés dans le bandeau debug** du haut-gauche
> de l'écran de jeu. C'est un outil de **test/observation**, pas une fonctionnalité livrée.
>
> - Affiché **seulement** si `kShowLiveCounters = true` (`lib/pentoscope/screens/pentoscope_game_screen.dart`).
> - **À repasser `false` avant toute soumission App Store** (`CHECKLIST_APPSTORE.md`, point 22).
> - Tous ces indicateurs sont **hors maillots** et **non persistés** (ils repartent à 0 à chaque partie).
> - Définition et formatage centralisés dans **`lib/pentoscope/fault_analysis.dart`**.

---

## Le principe en une phrase

La **lampe rouge** 🔴 (dans la barre du jeu) dit au **joueur** « tu es bloqué ». Le **bandeau debug**, lui,
sert à **toi** : il compte et **explique** ces blocages, pour préparer une future note.

---

## Le bandeau : 3 lignes

```
🔄 12   🔴 3   ↔️ 8   🚑 2          ← ligne 1 : compteurs bruts (blanc)
⚠️ 2   🌫️ 1   Σg 11.2               ← ligne 2 : classification des fautes (ambre)
maintenant : ⚠️ 4 (g5.0)            ← ligne 3 : diagnostic de l'instant (bleu)
```

---

## Ligne 1 — compteurs bruts (ce que le joueur a fait)

Ce sont des **compteurs d'actions**. Ils montent quand l'action correspondante a lieu.

| Symbole | Nom | Signification | Quand il monte |
|---|---|---|---|
| 🔄 | **isométries** | Nombre de rotations + miroirs appliqués | à chaque rotation ou miroir d'une pièce |
| 🔴 | **fautes** | Nombre d'**entrées en cul-de-sac** (la lampe passe de 🟡 à 🔴) | quand un coup rend le plateau insoluble alors qu'il ne l'était pas |
| ↔️ | **translations** | Nombre de **déplacements** d'une pièce déjà posée | à chaque fois qu'on bouge une pièce du plateau |
| 🚑 | **retraits en rouge** | Nombre de **retraits faits pendant que le plateau était rouge** (= sorties de cul-de-sac) | quand on retire une pièce alors que la lampe est rouge |

> 🔴 **fautes** est le seul de cette ligne qui compte aussi comme **maillot** (le maillot à pois).
> Les autres (🔄 ↔️ 🚑) sont là **uniquement pour observer**.

---

## Ligne 2 — classification des fautes (pourquoi le joueur s'est bloqué)

Chaque fois qu'une **faute** se produit (🟡→🔴), on regarde **pourquoi** le plateau est mort, et on
range la faute dans l'une des deux causes. Cette ligne est le **cumul** sur la partie.

| Symbole | Cause | Signification |
|---|---|---|
| ⚠️ | **aire non multiple de 5** | Une zone vide dont la taille **n'est pas un multiple de 5** (donc impossible à remplir avec des pièces de 5 cases). **Inclut les petites poches** (une poche de 4, 3, 2, 1 cases). C'est l'erreur **la plus évidente**. |
| 🌫️ | **impossibilité subtile** | Toutes les zones vides sont des multiples de 5, **mais** elles ne peuvent quand même pas être remplies par les pièces restantes (mauvaise forme, ou mauvais jeu de pièces). Erreur **subtile** : la table le sait, l'œil non. |
| Σg | **somme des gravités** | La somme des **gravités** de toutes les fautes de la partie (voir ci-dessous). |

### La gravité d'une faute

Une faute plus **évidente** est plus **grave**. Pour une **aire non multiple de 5**, plus la zone est
**petite**, plus c'est grave :

```
gravité = 20 ÷ (taille de la zone)        (le 20 est un réglage : kGraviteAireCoeff)
```

| Zone bloquée | Gravité | Lecture |
|---|---|---|
| 4 cases | **5.0** | 20 ÷ 4 — très évident, très grave |
| 7 cases | 2.9 | 20 ÷ 7 |
| 9 cases | 2.2 | 20 ÷ 9 |
| impossibilité subtile | **1.0** | valeur fixe (`kGraviteSubtile`) — la moins grave |

**Σg** additionne ces valeurs. Exemple : une faute « zone de 4 » (5.0) + une faute « zone de 9 » (2.2)
→ `Σg = 7.2`.

> Si **deux causes coexistent** au même coup (une poche non-mult-5 *et* une zone subtile ailleurs),
> on retient **la plus évidente** (⚠️ gagne). Principe : « aucune excuse pour rater ça ».

---

## Ligne 3 — diagnostic de l'instant (`maintenant : …`)

Ce n'est **pas** un compteur : c'est une **photo de l'état courant**, recalculée à **chaque coup**
(isométrie, translation, ajout, retrait). Elle dit ce qui ne va pas **maintenant**.

| Affichage | Signification |
|---|---|
| `maintenant : 🟢 soluble` | le plateau a encore une solution (lampe jaune) |
| `maintenant : ✅ résolu` | le plateau est terminé |
| `maintenant : ⚠️ 4 (g5.0)` | bloqué : zone non-mult-5 de 4 cases, gravité 5.0 |
| `maintenant : 🌫️ · (g1.0)` | bloqué : impossibilité subtile |

C'est cette ligne qui **change quand tu déplaces une pièce dans un plateau déjà rouge** (les compteurs
des lignes 1-2, eux, ne bougent pas dans ce cas — ils ne comptent que l'**entrée** en cul-de-sac).

---

## Rappel : qu'est-ce qu'une « faute » exactement

Une **faute** = **une** transition du plateau de **soluble (🟡) à insoluble (🔴)**, c'est-à-dire **une
entrée dans un cul-de-sac**. Comptée sur toute action qui casse la solubilité (poser, déplacer, tourner,
retourner, retirer). **Ne compte pas** : le coup qui complète le plateau (victoire), rester rouge
(🔴→🔴, tâtonnement), ou sortir du rouge (🔴→🟡, sauvetage). Détail complet : `MANUEL_DEFIS_ET_MAILLOTS.md`.

---

## En résumé

- **Lampe rouge** = aide au **joueur** (temps réel, ne dit pas pourquoi).
- **Lignes 1-2** = **compteurs d'événements** cumulés (montent à l'entrée en cul-de-sac).
- **Ligne 3** = **diagnostic de l'instant** (change à chaque coup).
- **⚠️ / 🌫️ / Σg** = matière première pour une future **note** du joueur — **pas encore** dans les maillots.
- Tout ça est du **debug** : `kShowLiveCounters = false` avant publication.
