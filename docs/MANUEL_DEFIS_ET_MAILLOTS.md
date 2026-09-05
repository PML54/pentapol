# Manuel — les défis (perso & réseau) et le calcul des maillots

> Référence du système de performance de Pentapol. Décrit **ce que le joueur voit**, **comment
> chaque maillot est calculé** (formules exactes), et la différence entre les **records perso**
> (locaux) et le **défi de la semaine** (classement en ligne).
>
> Source : implémentation réelle (`completion_metrics.dart`, `pentoscope_provider.dart`,
> `settings_database.dart`, `challenge*.dart`, `server/`) et cahier des charges `CAHIER_DES_CHARGES_V1.md`
> §4 et §7. En cas de doute, le code fait foi.

---

## 1. Vue d'ensemble

À la fin de chaque puzzle résolu **sans aide**, Pentapol mesure **trois valeurs**, présentées comme
**trois maillots** indépendants, sur le modèle du Tour de France. **Il n'y a pas de vainqueur
unique** : un joueur peut être premier sur un maillot et dernier sur un autre. Aucun classement
combiné.

| Maillot | Mesure | Meilleur = |
|---|---|---|
| 🟡 **Jaune** | Acuité isométrique | le **plus grand** (100 %, **plafonné**) |
| 🔴 **À pois** | Fautes (culs-de-sac) | le **plus petit** (0 = jamais coincé) |
| 🟢 **Vert** | Temps | le **plus petit** |

Ces mêmes trois valeurs alimentent **deux dispositifs** :

- **Le défi perso** — tes meilleurs scores, **sur ton appareil**, par taille. Toujours actif, hors ligne.
- **Le défi réseau** — le **classement en ligne** de la semaine, où tous les joueurs affrontent la
  **même** configuration.

> **Refonte « A » (2026-09-05)** : l'ancien maillot **⚫ Coups** et l'ancien maillot **⚪ Blanc
> (Help)** ont été **fusionnés** dans un unique maillot **🔴 À pois — Fautes**, et l'acuité est
> désormais **plafonnée à 100 %**. Motivations : (1) l'acuité pouvait dépasser 100 % quand l'ampoule
> plaçait une pièce à l'optimum sans coûter d'isométrie ; (2) « coups » classait une *habitude de
> geste* plus qu'une compétence ; (3) « fautes » et « Help » comptaient en réalité **le même
> événement** (voir §2.2). Un maillot de moins, une mesure plus juste.

---

## 2. Les trois maillots — modes de calcul

Toutes les formules ci-dessous sont dans `computeMetrics` (`lib/pentoscope/completion_metrics.dart`),
appelé à la complétion.

### 2.1 🟡 Maillot jaune — l'acuité isométrique

Mesure la **qualité de la visualisation** : as-tu tourné/retourné les pièces **juste ce qu'il faut**,
ou as-tu tâtonné ?

```
minIso = Σ  d(orientation distribuée de la pièce p ,  orientation où tu l'as posée)
        p ∈ pièces posées

acuité = min( (minIso + 1) / (isometryCount + 1) , 1.0 )     ← plafonnée à 100 %
```

- **`d(a, b)`** = nombre **minimal** d'appuis sur les 4 boutons d'isométrie pour passer de
  l'orientation `a` à l'orientation `b`. C'est la distance dans le graphe des isométries (BFS,
  `Pento.minIsometriesToReach`). Elle vaut **0, 1 ou 2** (les 4 boutons engendrent le groupe D₄, de
  diamètre 2).
- **`minIso`** = somme, sur toutes les pièces, de cette distance entre l'orientation **du rack**
  (celle où la pièce t'a été distribuée au départ) et l'orientation **où tu l'as réellement posée**.
  C'est le **minimum d'isométries nécessaires** pour aboutir à ton placement.
- **`isometryCount`** = le nombre d'isométries que **tu as réellement faites**.

**Lecture** : si tu n'as fait aucun geste de trop, `isometryCount == minIso` → acuité **100 %**. Plus
tu tournes inutilement, plus `isometryCount` dépasse `minIso`, plus l'acuité baisse.

**Le plafond à 100 %** : sans lui, une pièce placée par l'ampoule (indice) — donc `isometryCount`
plus petit que `minIso` — donnerait un ratio **> 1** (ex. 2/1 = 200 %). On plafonne : l'acuité ne
peut pas dépasser la perfection. (En pratique l'aide bascule aussi le bilan en mode « résolu avec
aide », §3.2 ; le plafond couvre les cas résiduels et le mode classé.)

Le `+ 1` traite le cas où `minIso = 0` (rack déjà bien orienté) : sans lui, un seul geste de trop
donnerait 0 %. Il ne fausse pas les valeurs utiles (ex. 10 pour 20 → 52 % au lieu de 50 %).

> ⚠️ L'acuité se mesure sur le **placement que tu as réellement complété**, pas sur la meilleure
> solution théorique. Le but est d'abord de finir ; le maillot mesure ensuite le tâtonnement sur
> **ton** chemin. Le rack de départ (les orientations distribuées) est **figé** au démarrage — même
> si tu tournes les pièces ensuite, la référence ne bouge pas.

### 2.2 🔴 Maillot à pois — les fautes (culs-de-sac)

Mesure combien de fois tu t'es **peint dans un coin** : combien de fois le plateau est devenu
**insoluble** par ta faute.

Pendant le jeu, la lampe (le compteur de solutions) passe au **rouge** quand le plateau devient
**insoluble** (les pièces restantes ne peuvent plus le remplir), et au **jaune/vert** quand il
redevient soluble.

```
fautes = nombre de transitions  SOLUBLE → INSOLUBLE
minimum = 0
```

- Une **faute** = un geste (pose, déplacement ou rotation d'une pièce posée) qui fait passer le
  plateau de **soluble à insoluble** : la lampe vire au **rouge**. Tu viens de créer un cul-de-sac.
- **Lecture** : `fautes = 0` = tu n'as jamais mis le plateau dans un état sans issue — un jeu
  « propre ». Plus le nombre monte, plus tu as tâtonné en te coinçant.

> **Pourquoi ce maillot remplace à la fois « Coups » et « Help ».** À la complétion, le plateau
> part soluble et finit soluble. Le nombre de fois où il **entre** en insoluble (jaune→rouge, une
> *faute*) est donc **exactement** le nombre de fois où il en **ressort** (rouge→jaune, un
> *sauvetage*, l'ancien « Help »). Compter les fautes, c'est compter les sauvetages — une seule
> mesure pour deux anciens maillots. Et contrairement aux « coups », elle ne pénalise pas une
> *manière de jouer* (retirer-reposer vs déplacer) : seul l'événement « je me suis coincé » compte.

### 2.3 🟢 Maillot vert — le temps

Le **temps écoulé**, en secondes, entre le premier geste et la résolution.

- Le chronomètre **se met en pause en arrière-plan** : un appel téléphonique, un verrouillage
  d'écran ou un passage dans une autre app **ne comptent pas** (le temps de fond est retranché).
- Il démarre à la **première pièce** posée depuis la barre et s'arrête à la complétion (le temps est
  **figé** à ce moment — il ne bouge plus, même si tu laisses l'écran de bilan ouvert).

### 2.4 🏅 La médaille — « vision parfaite »

Ce n'est **pas** un maillot mais une distinction, affichée au bilan.

```
Vision parfaite  ⟺  acuité = 100 %  ( isometryCount == minIso )  ET  aucune aide (ampoule)
```

C'est-à-dire : **aucun geste d'isométrie au-delà du nécessaire**. Jamais un seuil sur `minIso` brut
(un tirage déjà bien orienté donnerait `minIso = 0`, ce qui récompenserait le tirage, pas le joueur).

---

## 3. Le défi perso (records locaux)

**But** : garder, sur ton appareil, tes **meilleurs scores par taille**, pour toutes tes parties
libres et de progression. Aucun réseau, toujours disponible.

### 3.1 Ce qui est gardé

Une ligne **par taille** (`PuzzleStats` pour les tailles à pièces tirées, `SolvedSolutions` par
solution pour le 6×10), avec **trois meilleurs indépendants** :

- meilleure **acuité** (le plus grand ratio, plafonné à 100 %),
- moins de **fautes**,
- meilleur **temps**.

Ces trois records peuvent venir de **trois parties différentes** — chacun évolue séparément quand
une partie le bat. Plus le nombre de complétions (`completed`).

### 3.2 Ce qui compte comme record — et le bilan « avec aide »

- Une **partie avec aide** (tu as appuyé sur l'**ampoule** pour qu'elle place une pièce,
  `hintCount > 0`) **compte** dans le nombre de complétions **mais ne pose aucun record** — l'indice
  place à l'optimum et fausserait l'acuité.
- **Bilan d'une partie avec aide** : pas de maillots ni de médaille. Le bilan affiche simplement
  **« Résolu avec N aide(s) »** et le **temps**. Les maillots n'ont de sens que sur une partie
  résolue par le joueur.
- Une partie de **défi de la semaine** (mode classé) **n'écrit pas** dans les records perso : son
  classement vit sur le serveur. Records perso et classement défi sont **séparés**.

### 3.3 Où c'est affiché

- **Au bilan de fin de partie** : les trois maillots + la médaille éventuelle (ou le message
  « résolu avec aide »), dans une carte flottante déplaçable.
- **Écran « Mes records »** (icône trophée de l'accueil) : une carte par taille jouée, les trois
  maillots, et l'icône médaille sur les tailles où ton meilleur score d'acuité est à 100 %.

---

## 4. Le défi réseau (classement de la semaine)

**But** : chaque semaine, une **même** configuration pour tous les joueurs d'une taille donnée, et
**trois classements en ligne**.

### 4.1 Un défi = (semaine, taille)

Le joueur ouvre **Défi de la semaine** (drapeau de l'accueil) et choisit une **taille** parmi six :
**3×5, 4×5, 5×5, 5×6, 5×7, 5×8**. (Le 6×10, le 5×9 et le 5×10 sont écartés — trop longs.) Tout le
reste — **quelles pièces** et **dans quelles orientations** — est **identique pour tous** cette
semaine-là.

Cette définition `(taille, masque, rack)` est :

- soit **composée à la main** (choisie côté serveur, autorité serveur),
- soit **dérivée** automatiquement d'un seul entier : `graine = mix(version, semaine, taille)`, via un
  générateur pseudo-aléatoire **écrit dans le dépôt** (`PentapolRng`), donc reproductible à
  l'identique sur tous les appareils **sans rien échanger**. Le client télécharge la définition
  composée si elle existe, sinon il la dérive lui-même (repli hors ligne).

### 4.2 Mode classé — ce qui change

En défi, la partie est **classée** :

- L'**appui sur l'ampoule** (l'indice qui place une pièce) est **neutralisé** — l'indice n'existe
  pas en défi. Le **compteur de solutions et la couleur** de la lampe restent, eux, visibles (ils
  sont identiques pour tous, donc n'avantagent personne).
- Le retrait d'une pièce passe par sélection + poubelle (comme d'habitude).
- Les **fautes** (maillot à pois) restent comptées — c'est justement leur intérêt en classé.

### 4.3 Un seul essai, trois valeurs

**Un seul essai par joueur et par défi** `(semaine, taille)` : le **premier** est enregistré, il n'y
a pas de reprise ni de « meilleur des N ». Cet unique essai produit les **trois valeurs** (acuité,
fautes, temps), qui alimentent **trois classements indépendants**. Chaque maillot trie sur sa
colonne.

### 4.4 Identité du joueur

À la première soumission, l'app génère une **identité 128 bits** (aléatoire), **distincte du
pseudo**. C'est la clé du joueur côté serveur. Le pseudo n'est qu'une **étiquette d'affichage** ; en
cas d'homonymie, l'affichage peut suffixer quelques caractères de l'identité.

> Conséquence : **désinstaller l'app perd l'identité** (et l'historique de classement). Rien n'est
> transférable d'un appareil à l'autre. C'est le prix d'un classement sans compte.

### 4.5 Confiance et vérification

L'app **mesure** les trois valeurs toute seule — le joueur ne saisit aucun chiffre, **il ne peut
pas tricher via le jeu**. Le serveur **fait confiance** aux chiffres envoyés par une partie valide,
et **conserve la grille terminée** : si un classement paraissait louche, il resterait **auditable**
hors ligne. (Le seul vecteur de triche serait un envoi forgé *hors* de l'app — jugé négligeable à
cette échelle.)

### 4.6 Où c'est affiché

Écran **Classement** (icône « classement » d'une taille dans Défi de la semaine) : **trois onglets**
(jaune / à pois / vert), chacun le tableau trié du maillot, **ton score surligné**. Si le serveur ne
répond pas, l'écran affiche « aucun score / serveur injoignable » — le jeu reste entier sans réseau.

---

## 5. Tableau récapitulatif — perso vs réseau

| | **Défi perso** (local) | **Défi réseau** (en ligne) |
|---|---|---|
| Configuration | ton tirage (aléatoire par partie) | **la même pour tous** cette semaine |
| Réseau | jamais | envoi du score + consultation |
| Nombre d'essais | illimité (on garde le meilleur par maillot) | **un seul** (premier essai) |
| Indice (ampoule) | disponible (mais bilan « avec aide », aucun record) | **neutralisé** |
| Fautes (culs-de-sac) | comptées (maillot à pois) | comptées, classent (maillot à pois) |
| Stockage | ton appareil (3 meilleurs par taille) | serveur (1 ligne par joueur/défi) |
| Identité | aucune | 128 bits, distincte du pseudo |

---

## 6. Annexe — les compteurs bruts

Sous les maillots, l'app suit quelques compteurs pendant la partie :

| Compteur | Sens | Entre dans |
|---|---|---|
| `isometryCount` | isométries réellement faites | acuité (🟡) |
| `faultCount` | transitions soluble→insoluble (culs-de-sac) | fautes (🔴) |
| `deleteCount` | retraits de pièces | **rien** (n'est plus un maillot) |
| `translationCount` | déplacements directs | **rien** (gratuit, Q6) |
| `hintCount` | appuis sur l'ampoule (indice) | bascule le bilan en « avec aide », aucun record ; toujours 0 en défi |
| `elapsedSeconds` | temps (chrono, pause en arrière-plan) | temps (🟢) |
| `minIso` | somme des isométries minimales (rack→placement) | acuité (🟡) |
