# Plan — l'interface hors plateau : AppBar et barre de pièces

> Établi le 2026-08-30 par cowork, sur capture d'écran iPad fournie par Paul :
> « les icônes sont trop petites ainsi que les pièces dans la zone du bas ».
> Périmètre : **tout sauf le plateau et la manipulation des pièces.**
>
> ⚠️ Cowork n'a jamais vu l'application tourner. Tout ce qui suit vient du code et d'une
> capture. Les valeurs en points sont **calculées**, pas mesurées à l'écran.

---

## 1. Le diagnostic tient en une phrase

Sur iPad, **ce qui s'adapte sur-adapte, et ce qui ne s'adapte pas sous-adapte.** Le problème
n'est pas « tout est trop petit » : c'est un **écart d'échelle** entre les deux moitiés de
l'écran.

Calcul pour un iPad Pro 12,9″ (1024 × 1366 pt), portrait, plateau 5 × 6 :

| élément | formule dans le code | iPad | iPhone 14 (390 × 844) |
|---|---|---|---|
| case du **plateau** | `min(W/cols, H/rows)` — pleinement adaptatif | **≈ 156 pt** | ≈ 76 pt |
| case d'une pièce dans la **barre** | `PieceRenderer` : `const cellSize = 22.0` | **22 pt** | 22 pt |
| **rapport** | | **≈ 7,1×** | ≈ 3,5× |

Le rapport **double** en passant du téléphone à la tablette. C'est exactement ce que montre
la capture : un plateau en damier géant, et en bas des pièces de la taille d'un timbre.

Et les icônes :

| barre | formule | iPad | iPhone |
|---|---|---|---|
| AppBar principale (l.846) | `(screenHeight × 0.045).clamp(20, 36)` | 61 → **36** | 38 → **36** |
| AppBar transformation, portrait (l.542) | `const double iconSize = 42.0` | **42** | **42** |
| AppBar transformation, paysage (l.625) | `(columnWidth × 0.75).clamp(28, 50)` | selon largeur | idem |
| hauteur d'AppBar (l.121-123) | `56.0` en dur | **56** | **56** |

**Les icônes de l'iPad et celles de l'iPhone font exactement la même taille.** Le plafond du
`clamp` mord dans les deux cas, ou la constante est fixe. L'adaptation est écrite mais
neutralisée.

---

## 2. Pourquoi c'est arrivé — quatre systèmes, trois morts

| système | volume | statut |
|---|---|---|
| `config/ui_layout_manager.dart` + `ui_layout_provider.dart` + `ui_dimensions.dart` | **893 l.** | **orphelins** — importés par personne hors d'eux-mêmes |
| `config/ui_sizes_config.dart` (`UISizes`) | 87 l. | **orphelin aussi** |
| `common/widgets/piece_renderer.dart` | — | `cellSize = 22.0` **en dur** |
| `pentoscope_game_screen.dart` | — | quatre constantes **improvisées sur place** |

Le plus frappant : **le moteur qui résout exactement ce problème existe déjà.**
`UILayoutManager` détecte `phone` / `tablet` / `largeTablet` sur la plus petite dimension
(seuils 600 et 800), applique un facteur d'échelle **1.0 / 1.25 / 1.5**, et en dérive
`ActionBarDimensions`, `SliderDimensions`, `BoardDimensions`, `TextDimensions` — y compris un
`pieceCellSize` et un `iconSize`. Il a même les bonnes valeurs de base : `_baseIconSize = 24`,
`_basePieceCellSize = 22`, `_baseSliderHeight = 160`.

Il n'a **jamais été branché**. `grep -rln ui_layout_provider lib/` ne renvoie rien.

---

## 3. Décision : ne pas brancher les 893 lignes

C'est le réflexe, et je recommande de ne pas le suivre.

**Du code jamais exécuté n'est pas un actif, c'est une dette.** L'adopter, c'est déboguer 893
lignes que personne n'a jamais fait tourner, sur un écran pour lequel elles n'ont pas été
écrites — l'écran a changé trois fois depuis (suppression de la démo, du mode classique, du
menu). On y passerait plus de temps qu'à écrire le juste nécessaire, et sans savoir ce qui
casse.

Deuxième objection, plus de fond : **son facteur d'échelle est le mauvais concept.** 1.5 sur
« largeTablet » est un chiffre posé a priori. Il ne dit pas *par rapport à quoi*.

### Le bon ancrage : la barre se dimensionne sur le plateau

Une pièce dans la barre et la même pièce sur le plateau sont **la même chose**. C'est ce qui
rend le glisser lisible : on voit ce qu'on s'apprête à poser. Elles doivent donc être liées
par un rapport, pas par un type d'appareil :

```
pieceCellSize = boardCellSize × k        // k ≈ 0,45, à régler à l'œil
```

Le plateau connaît déjà sa taille de case — c'est la seule valeur pleinement adaptative de
l'application. En y accrochant la barre, **tout écran est traité, y compris ceux qui
n'existent pas encore**, sans détection d'appareil, sans seuils, sans facteur magique.

Pour les icônes, l'ancrage naturel est la hauteur de l'AppBar, elle-même dérivée de la plus
petite dimension de l'écran.

---

## 4. Les sites, exactement

**a) `PieceRenderer` prend sa taille en paramètre** — `common/widgets/piece_renderer.dart`
l.59 :

```dart
final double cellSize;              // au lieu de const cellSize = 22.0
const PieceRenderer({… this.cellSize = 22.0 …});
```

Le défaut 22 garde le comportement actuel pour tout appelant non modifié : le changement est
**additif**, il ne casse rien.

Trois appelants à alimenter : `pentoscope_piece_slider.dart` l.142 (la barre),
`pentoscope_board.dart` l.~423 et le `feedback:` du drag — **c'est aussi la « miniature »
signalée par Paul** : le retour visuel sous le doigt fait 22 pt pendant qu'on manipule des
cases de 156. Un seul correctif règle les deux symptômes.

**b) La barre reçoit la taille de case du plateau.** Le plateau la calcule dans son
`LayoutBuilder` (`pentoscope_board.dart` l.65-67) ; l'écran doit la faire redescendre au
slider — la remonter dans l'état serait excessif pour une valeur d'affichage.

**c) La hauteur de la barre** — `pentoscope_game_screen.dart` l.~811, `height: 160` en dur.
À dériver de `pieceCellSize` : la barre doit contenir la plus haute pièce (5 cases) plus
la marge. Sinon on agrandit les pièces dans un contenant qui ne bouge pas.

**d) Les icônes et l'AppBar** — quatre sites : `Size.fromHeight(56.0)` et
`toolbarHeight: 56.0` (l.121-123), `const double iconSize = 42.0` (l.542),
`.clamp(28, 50)` (l.625), `.clamp(20, 36)` (l.846). Un seul helper, dérivé de
`MediaQuery.size.shortestSide`, remplace les quatre.

> ⛔ **§4d est ABSORBÉE par le §9 (décision 69) — ne pas l'appliquer telle quelle.** Le
> correctif décrit ci-dessous passait par `AppBar.iconTheme` / `actionsIconTheme`. Or le §9
> **supprime `actions:`** et déplace les boutons dans le `title` : le mécanisme d'héritage de
> l'`AppBar` ne les atteindrait plus. Et il n'a jamais couvert la colonne du paysage, qui
> n'est pas dans une `AppBar` du tout.
> **Le bon endroit est désormais `_buildBarItems`** : chaque `IconButton` y reçoit
> `iconSize: _uiIconSize(context)`, une fois, pour les deux orientations. Le `leading` et le
> `title` visés ci-dessous disparaissent avec le §9 ; seul survit le besoin d'un
> `_uiLabelSize`, spécifié en §9.3 pour le chrono et le compteur de solutions.
> Appliquer §4d avant §9 serait du travail défait dans l'heure.
>
> 🔴 **Ce qui reste vrai de l'analyse — §4d était incomplet (décision 59).** Les icônes de
> l'AppBar principale n'ont **pas** grandi, et l'étape 3 n'y est pour rien : j'avais énuméré
> les sites en cherchant les **constantes de taille existantes**. Or les `IconButton` du bloc
> `actions:` (l.188-250) n'ont **aucun `size:`** — ils héritent du défaut de Flutter, 24 pt.
> Il n'y avait rien à remplacer, donc rien n'a changé. Et comme la hauteur de barre, elle, est
> bien passée à ~100 pt sur iPad, les icônes paraissent **plus petites qu'avant**.
>
> Même angle mort pour tout le contenu de la barre, figé aux tailles du téléphone :
> `leadingWidth: 60`, chrono `fontSize: 14`, et dans le titre `Icon(size: 14)` ×4 avec
> `Text(fontSize: 12)` ×3.
>
> **Correctif — par héritage, pas par énumération.** `AppBar` expose `iconTheme` et
> `actionsIconTheme` : les y poser règle **tous** les `IconButton` du bloc en une fois, y
> compris ceux qu'on ajoutera demain.
>
> ```dart
> AppBar(
>   toolbarHeight: _uiAppBarHeight(context),
>   iconTheme:        IconThemeData(size: _uiIconSize(context)),
>   actionsIconTheme: IconThemeData(size: _uiIconSize(context)),
>   …
> )
> ```
>
> `IconButton` prend sa taille dans `IconTheme` quand `iconSize` n'est pas donné : c'est le
> mécanisme prévu, et il rend l'énumération inutile. Restent à dériver explicitement, parce
> qu'ils ne relèvent pas de l'`IconTheme` : `leadingWidth`, et les tailles de texte du
> `leading` et du `title` — un second helper `_uiLabelSize(context)` (≈ `_uiIconSize × 0.35`)
> suffit.
>
> ⚠️ `IconButton` ajoute son `padding` (8) et ses `constraints` (48 min). À 64 pt d'icône, un
> bouton fait ~80 pt ; cinq boutons ~400 pt sur une barre de 1032 — ça passe, mais c'est à
> regarder si un sixième revient (le navigateur de solutions n'apparaît que sur les tailles à
> table).

**e) Les textes** — le numéro de pièce sur le plateau (`fontSize` 14/16) et les badges de la
barre. Même ancrage que leur contenant : proportionnels à la case, pas fixes.

---

## 5. Ce que ce plan ne tranche pas — question pour Paul

**Faut-il plafonner la case du plateau ?** À ≈ 156 pt sur iPad, elle fait environ **trois
fois la pulpe d'un doigt** (≈ 45-50 pt). Le plateau n'a pas besoin d'être si grand pour être
confortable ; il remplit l'écran parce que rien ne l'en empêche.

- **Plafonner** (80-100 pt) et centrer le plateau : proportions plus proches d'un vrai jeu de
  pentominos posé sur une table, et l'espace libéré profite à la barre. Risque : sur très
  grand écran, un plateau perdu au milieu d'un vide.
- **Ne pas plafonner** : on garde l'usage maximal de l'écran, et on se contente de corriger
  l'écart en remontant la barre et les icônes.

C'est un choix **esthétique**, pas technique.

> ✅ **Tranché le 2026-08-30 (décision 57).** Paul n'a pas de préférence et laisse le choix à
> cowork. **Décision : on ne plafonne pas maintenant.** Les étapes 1 à 4 se font sans toucher
> au plateau ; la question se rouvre après un regard sur l'appareil.
>
> Raison, et ce n'est pas une dérobade : c'est le seul point du plan qui se juge **à l'œil et
> nulle part ailleurs** — et cowork n'a jamais vu l'application tourner. Décider maintenant,
> ce serait trancher au calcul la seule chose qui ne se calcule pas. Surtout, les étapes 1 à
> 4 changent la donnée du problème : une fois les pièces de la barre à ~70 pt et les icônes
> proportionnées, le plateau cessera peut-être de paraître démesuré, parce que les deux
> moitiés de l'écran seront redevenues cohérentes. On jugerait alors sur une image qui
> n'existe pas encore.
>
> Le coût de ce report est nul : le plafond est un `clamp` d'une ligne dans le `LayoutBuilder`
> du plateau, ajoutable après coup sans rien défaire.
>
> Conséquence sur `k` : le régler **sur l'écran non plafonné**. Si un plafond arrive ensuite,
> `k` reste valable — il porte sur un rapport, pas sur une valeur absolue. C'est précisément
> l'avantage d'ancrer la barre sur le plateau plutôt que sur l'appareil.
>
> *Pari de cowork, pour mémoire, à vérifier ou infirmer au test :* un plafond autour de
> 90-110 pt finira par être voulu. Mais ce pari vaut moins qu'un coup d'œil.

---

## 6. Ordre et critères de fin

1. **`PieceRenderer` paramétrable** (défaut 22, aucun appelant modifié). Commit seul —
   `flutter analyze` doit rester à 0 et l'application être **visuellement identique**. C'est
   le filet : si quelque chose bouge à cette étape, c'est qu'un appelant a été manqué.
2. **La barre et le drag reçoivent la taille du plateau**, hauteur de barre dérivée.
3. **Un helper unique pour les icônes et l'AppBar**, les quatre constantes remplacées.
4. **Les textes**, ancrés sur leur contenant.
5. **Supprimer les 980 lignes orphelines** — `ui_layout_manager`, `ui_layout_provider`,
   `ui_dimensions`, `ui_sizes_config`. **En dernier** : tant qu'on n'a pas fini, elles restent
   une source d'inspiration pour les formules.

```bash
grep -rn "cellSize = 22" lib/                    # attendu : la seule valeur par défaut
grep -rn "iconSize = 4[0-9]\|clamp(20, 36)\|clamp(28, 50)" lib/   # attendu : aucun
grep -rn "56.0" lib/pentoscope/screens/pentoscope_game_screen.dart # attendu : aucun
grep -rln "ui_layout_manager\|ui_sizes_config" lib/               # attendu : aucun (étape 5)
flutter analyze                                   # 0 warning
```

Test appareil — **les deux, c'est tout l'objet du plan** : iPhone en release **et** iPad
simulé, portrait et paysage. Sur iPad : une pièce de la barre doit être manifestement la même
chose qu'une pièce du plateau, et les icônes doivent être proportionnées à la barre qui les
contient.

> La capture de Paul porte le bandeau **DEBUG**. Le ressenti et les performances diffèrent en
> `--release` ; les proportions, non.

---

## 7. L'ordre des trois zones en paysage — décision 61

> Paul, 2026-08-30 : « en vertical on a AppBar, plateau, slider ; en horizontal, de gauche à
> droite, on a plateau, AppBar, slider. Je voudrais l'ordre de gauche à droite identique à
> celui de haut en bas. »

### 7.1 Ce qu'il y a

En paysage, `appBar:` du `Scaffold` vaut **`null`** (l.124) : le rôle de la barre est tenu par
une **colonne d'actions** dessinée dans le corps. La structure est :

```dart
Row(children: [
  Expanded(child: PentoscopeBoard(isLandscape: true)),   // plateau
  Row(children: [
    Container(width: actionColumnWidth, …),              // la « AppBar » verticale
    … slider (width: sliderWidth)
  ]),
])
```

→ de gauche à droite : **plateau, barre, slider**. En portrait, de haut en bas : **barre,
plateau, slider**. Les deux ne se correspondent pas.

### 7.2 Ce qu'on veut

```dart
Row(children: [
  Container(width: actionColumnWidth, …),   // barre — à gauche
  Expanded(child: PentoscopeBoard(…)),      // plateau
  … slider (width: sliderWidth)             // slider — à droite
])
```

Le `Row` imbriqué qui regroupait « colonne de droite : actions + slider » n'a plus lieu
d'être : **aplatir en un seul `Row` de trois enfants**. C'est plus simple à lire, et ça évite
qu'un futur réglage de largeur s'applique au mauvais niveau.

> ⚠️ **Le `boxShadow` doit changer de sens.** La colonne d'actions porte
> `offset: const Offset(-1, 0)` — une ombre portée **vers la gauche**, correcte quand la
> colonne est à droite du plateau. Passée à l'extrême gauche, elle doit porter vers la
> droite : `Offset(1, 0)`. Détail, mais c'est exactement le genre d'oubli qui se voit.

### 7.3 Ce que ça vaut, au-delà de la cohérence

L'argument de Paul — même ordre dans les deux orientations — se suffit à lui-même. Il s'en
ajoute un second : une tablette tenue à deux mains met les **actions sous le pouce gauche** et
la **barre de pièces sous le pouce droit**, le plateau au milieu. Aujourd'hui les actions sont
au centre, l'endroit le moins accessible des deux pouces.

Objection honnête, pour être complet : placer le plateau en premier lui donne la position de
primauté à la lecture. C'est le seul argument en faveur de l'ordre actuel, et il pèse moins
que les deux autres.

### 7.4 Critères de fin

- portrait inchangé ;
- paysage : de gauche à droite, colonne d'actions, plateau, barre de pièces ;
- l'ombre de la colonne porte vers le plateau ;
- **en mode transformation** (pièce sélectionnée), les icônes d'isométrie pleine hauteur sont
  bien dans la colonne de gauche — c'est le même `Container`, mais à vérifier à l'écran ;
- multijoueur non touché (écran distinct).

---

## 8. Écran de réglages minimal — décision 62

> Paul, 2026-08-30 : « repars d'un écran minimal. »

### 8.1 L'inventaire, vérifié au grep

**Neuf des quatorze entrées ne font rien.** Le relevé du 2026-08-30 (décision 63) en comptait
six ; l'inventaire complet en trouve trois de plus.

| entrée | champ | statut |
|---|---|---|
| Couleurs des pièces | `colorScheme` | **vivant** |
| Personnaliser les couleurs | `customColors` | **vivant** |
| Numéros sur les pièces | `showPieceNumbers` | mort |
| Lignes de grille | `showGridLines` | mort |
| Animations | `enableAnimations` | mort |
| Opacité des pièces | `pieceOpacity` | mort |
| Taille des icônes | `iconSize` | mort |
| Couleur mode isométries | `isometriesAppBarColor` | mort |
| **Niveau de difficulté** | `game.difficulty` | **mort** — la difficulté se choisit désormais dans le dialogue « Nouvelle partie », qui porte son propre état |
| Compteur de solutions | `showSolutionCounter` | **vivant** |
| **Indices** | `enableHints` | **mort** — le bouton indice s'affiche toujours |
| **Chronomètre** | `enableTimer` | **mort** — le chrono s'affiche toujours |
| Retour haptique | `enableHaptics` | **vivant** (barre de pièces) |
| Sensibilité du drag | `longPressDuration` | **vivant** (barre + `DraggablePieceWidget`) |

Sections « Mode Duel » et « À propos » : vivantes, à conserver.

### 8.2 L'écran minimal

**Six entrées au lieu de quatorze** : Couleurs des pièces, Personnaliser les couleurs,
Compteur de solutions, Retour haptique, Sensibilité du drag, plus Duel et À propos.

Retirer **l'entrée d'écran et le champ du modèle** pour les neuf autres — laisser le champ
sans son contrôle recréerait la même situation à l'envers. `AppSettings` étant sérialisé en
JSON, un champ disparu est simplement ignoré à la relecture : **aucune migration**.

### 8.3 Deux réserves

**`showPieceNumbers` est le seul qui vaille d'être rebranché plutôt que retiré.** Sur la
capture iPad de Paul, les numéros chargent visiblement le plateau, et c'est une vraie
préférence de lisibilité. Il part avec les autres puisque la consigne est « écran minimal » —
mais c'est le premier à reconsidérer si l'écran se re-garnit un jour.

**Si `iconSize` revient un jour, il doit revenir en multiplicateur** (≈ 0,7×–1,3×) sur la
taille dérivée de l'écran, **jamais** en valeur absolue de pixels : 48 px fixes annuleraient
exactement l'adaptation des §1 à §4 et ramèneraient le défaut d'origine. Le libellé « 48px »
devrait disparaître avec.

### 8.4 Critères de fin

```bash
S=lib/screens/settings_screen.dart
grep -c "SwitchListTile\|Slider(" $S     # doit baisser fortement
for f in showPieceNumbers showGridLines enableAnimations pieceOpacity iconSize \
         isometriesAppBarColor enableHints enableTimer difficulty; do
  printf "%-24s " "$f"; grep -rn "$f" lib/ --include=*.dart | wc -l   # attendu : 0
done
flutter analyze                           # 0 warning
```

Test appareil : chaque contrôle restant **fait quelque chose de visible**. C'est le seul
critère qui compte, et c'est celui qui manquait.

---

## 9. Une seule barre d'actions pour les deux orientations — décisions 65 à 68

> Paul, 2026-08-30 : « quand je passe en horizontal les icônes non isométriques changent, on
> devrait avoir les mêmes ; je les voudrais équi-réparties dans les deux modes ; et le chrono,
> à gauche, est peu visible. »

### 9.1 Ce n'est pas qu'une incohérence : deux fonctions sont inaccessibles en paysage

Relevé exact des deux jeux d'icônes, mode normal :

| action | portrait (`actions:`) | paysage (colonne) |
|---|---|---|
| Nouvelle partie — dialogue taille / difficulté / solution | ⊕ `add_circle_outline` | **absent** |
| Multijoueur | 👥 `people_outline` | **absent** |
| Recommencer même taille | 👤 `person` (vert si terminé) | 🎮 `games` — **icône et intitulé différents** |
| Indice | 💡 `lightbulb` | 💡 `lightbulb_outline` — **variante différente** |
| Solutions compatibles | 🔎 `view_carousel` | 🔎 `view_carousel` |
| Réglages | ⚙️ `settings` | ⚙️ `settings` |

**En paysage, on ne peut ni changer la taille du plateau ni lancer une partie multijoueur.**
Ce n'est pas un défaut d'esthétique, c'est une perte de fonction — et elle ne se voit pas,
puisqu'il n'y a rien à voir.

Cause : les deux barres sont **deux listes écrites à la main**, à deux endroits. Rien ne les
oblige à rester d'accord, et elles ont divergé.

### 9.2 Le remède : une liste, deux rendus

Une seule source de vérité, construite une fois :

```dart
/// Les actions de la barre, dans l'ordre, communes aux deux orientations.
/// C'est cette liste unique qui garantit que portrait et paysage proposent
/// la même chose — pas la discipline de qui édite le fichier.
List<Widget> _buildBarItems(BuildContext context, …) { … }
```

Rendue par l'orientation, et par elle seule :

- **portrait** — `Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: items)` ;
- **paysage** — `Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: items)`.

**En portrait, ne plus utiliser `actions:`.** Le paramètre `actions:` d'un `AppBar` **tasse
ses enfants à droite** — il ne peut pas répartir. Pour obtenir la répartition demandée, la
barre doit porter sa `Row` dans le `title`, avec `automaticallyImplyLeading: false`,
`titleSpacing: 0` et `centerTitle: false`. Les compteurs (isométries, déplacements,
suppressions) qui occupaient le titre deviennent alors des éléments de la liste comme les
autres, ou disparaissent — voir §9.4.

Choisir les mêmes variantes d'icônes des deux côtés : `lightbulb` ou `lightbulb_outline`, pas
l'un puis l'autre.

### 9.3 Le chrono

**La cause principale de son manque de visibilité n'est pas son côté, c'est sa taille** :
`fontSize: 14` figé dans un `leadingWidth: 60`, au sein d'une barre qui fait désormais ~100 pt
de haut sur iPad. Un texte de 14 pt dans une barre de 100 pt se perd où qu'il soit.

Deux corrections, à faire ensemble :

1. **Taille dérivée et graisse** — `_uiLabelSize(context) × 1.4` environ, en `FontWeight.bold`.
   C'est ce qui règle 80 % du problème.
2. **Position** — Paul le veut ailleurs qu'à gauche. Le traiter comme **un élément de la
   liste**, inséré à l'indice `items.length ~/ 2` : avec `spaceEvenly`, il se retrouve
   visuellement **au centre** de la barre, et il y reste quel que soit le nombre d'icônes
   conditionnelles affichées. `leadingWidth` et le `leading` disparaissent.

> Un `centerTitle: true` donnerait aussi un chrono centré, mais interdirait de répartir les
> icônes sur toute la barre — les deux demandes s'excluent par ce chemin. L'insertion dans la
> liste les satisfait toutes les deux.

### 9.4 Point à trancher — les compteurs du titre

Le `title` du portrait porte aujourd'hui trois compteurs (isométries ↻, déplacements ✥,
suppressions 🗑) plus le compteur de solutions. **Le paysage n'en affiche aucun** hormis les
solutions. Il faut choisir, et le plan ne le fait pas :

- **les garder**, comme éléments de la liste dans les deux orientations — la barre devient
  chargée : 6 icônes + chrono + 4 compteurs ;
- **les retirer** de la barre — ils sont déjà tous dans le bandeau de fin de partie, qui est
  le moment où ils intéressent le joueur ; seul le compteur de solutions a un intérêt
  **pendant** la partie.

*Avis de cowork : les retirer, garder le compteur de solutions.* Un compteur d'isométries qui
s'incrémente pendant qu'on joue n'informe pas, il distrait — et il est de toute façon absent
du paysage aujourd'hui sans que personne l'ait remarqué.

> ✅ **Tranché le 2026-08-30 (décision 68).** Paul a validé « une liste, deux rendus » et le
> retrait d'`actions:` sans se prononcer sur ce point. **Cowork applique son avis : les trois
> compteurs sortent de la barre, le compteur de solutions reste.** Décision prise dans le
> silence, donc explicitement réversible : les compteurs restent dans l'état
> (`isometryCount`, `translationCount`, `deleteCount`) et dans le bandeau de fin de partie —
> les remettre dans la barre coûterait trois éléments à ajouter à la liste, rien de plus.

### 9.5 Critères de fin

```bash
G=lib/pentoscope/screens/pentoscope_game_screen.dart
grep -n "actions:" $G                    # attendu : aucun sur l'AppBar principale
grep -n "leadingWidth\|leading:" $G      # attendu : aucun
grep -c "_buildBarItems" $G              # 1 définition + 2 appels
grep -n "Icons.games" $G                 # attendu : aucun (icône divergente)
```

Test appareil, et c'est **le** test de cette section : **basculer portrait ↔ paysage en cours
de partie et vérifier que la barre propose exactement les mêmes actions, dans le même ordre.**
Plus : le dialogue « Nouvelle partie » et le multijoueur sont désormais atteignables en
paysage ; le chrono est lisible et centré ; en mode transformation, les icônes d'isométrie
restent réparties comme aujourd'hui.

---

## Voir aussi

- `docs/CHECKLIST_APPSTORE.md` §4 — la miniature de drag y figurait comme dette isolée ;
  elle est en fait un symptôme du même défaut
- `docs/PLAN_6X10_DANS_PENTOSCOPE.md` §6 — première mention du `cellSize` codé en dur
