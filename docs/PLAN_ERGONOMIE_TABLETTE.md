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

> 🔴 **§4d était incomplet — constaté au test du 2026-08-30 (décision 59).** Les icônes de
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

## Voir aussi

- `docs/CHECKLIST_APPSTORE.md` §4 — la miniature de drag y figurait comme dette isolée ;
  elle est en fait un symptôme du même défaut
- `docs/PLAN_6X10_DANS_PENTOSCOPE.md` §6 — première mention du `cellSize` codé en dur
