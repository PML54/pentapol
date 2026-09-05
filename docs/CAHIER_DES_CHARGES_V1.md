# Cahier des charges — Pentapol V1

> Rédigé par cowork le 2026-09-03, à partir du **mémo commercial de Paul** et de l'état réel
> du dépôt à `de7f576`.
>
> **Méthode.** Chaque nombre de ce document vient d'une mesure sur le dépôt ou ses tables,
> pas d'une estimation. Les mesures elles-mêmes vivent dans les deux fichiers de référence —
> `REFERENCE_ISOMETRIES.md` (isométries, chiralité, `minIso`) et `REFERENCE_TIRAGES.md` §2 et
> §11 (tirages solubles) — rejouables par `tools/verif_isometries.py` et
> `tools/verif_subset_counts.py`. Ce cahier des charges les cite, il ne les héberge pas : il
> périmera, elles non. Là où le mémo suppose quelque chose que le code ne tient pas, c'est dit — c'est
> l'objet des §2 et §9.

---

## 1. Positionnement retenu

Le mémo a raison sur le fond : vendre « un jeu de pentominos » limite l'audience à ceux qui
connaissent déjà le mot. La promesse retenue :

> **Un puzzle spatial où chaque placement réduit les solutions possibles.**

Le mot *pentomino* reste dans les mots-clés et dans le corps de la description, pas dans la
promesse.

L'identité tient en une phrase, reprise du mémo §16 :

> La performance n'est pas de trouver la solution, mais de **la voir** avec le moins d'essais
> possible. Le compteur mesure la qualité du chemin, les isométries mesurent la
> visualisation, les coups mesurent l'efficacité, le temps départage.

---

## 2. Ce que les mesures imposent — corrections au mémo

### 2.1 « 996 configurations réparties sur 9 difficultés » est faux

Compté dans `subset_counts.bin` :

| Niveau | Taille | Pièces | Configurations | Solutions : min / médiane / max |
|---|---|---|---|---|
| 1 | 3×5 | 3 | **7** | 4 / 4 / 4 |
| 2 | 4×5 | 4 | 26 | 4 / 8 / 20 |
| 3 | 5×5 | 5 | 45 | 8 / 16 / 80 |
| 4 | 6×5 | 6 | 172 | 4 / 8 / 64 |
| 5 | 7×5 | 7 | 245 | 4 / 12 / 204 |
| 6 | 8×5 | 8 | 261 | 4 / 24 / 564 |
| 7 | 9×5 | 9 | 175 | 4 / 40 / 2 296 |
| 8 | 10×5 | 10 | 65 | 4 / 144 / 4 664 |
| 9 | 6×10 | 12 | **1** | 9 356 |

Les 996 configurations couvrent les niveaux **1 à 8**. Le niveau 9 en a **une**. Formulation
juste, à utiliser partout : *« 996 configurations sur 8 niveaux, puis la grille complète
6 × 10. »*

**Conséquence produit, plus grave que la formulation :** le niveau 1 s'épuise en 7 parties et
le niveau 2 en 26. La progression n'a de contenu réel qu'à partir du niveau 4. Si les
niveaux se déverrouillent un par un, un joueur assidu voit le fond des deux premiers dans sa
première session. À trancher (§11, question 1).

### 2.2 Le scénario de captures « 128 → 17 → 2 → 1 » n'est pas représentatif

Le compteur part de la médiane du niveau : **4 au niveau 1**, 8 au niveau 2, 16 au niveau 3.
Un « 128 » n'apparaît qu'aux niveaux 7-8 et sur le 6×10 (9 356). Une capture d'écran non
représentative du produit est un motif de rejet en revue App Store, et un motif d'avis
négatif si elle passe. Le scénario corrigé est dans `FICHE_APP_STORE.md` §5.

### 2.3 Le compteur compte les solutions AVEC leurs symétries

Au niveau 1, les 7 configurations ont **exactement 4 solutions chacune** — soit **une seule à
symétrie près**. Le joueur qui lit « 4 » croit avoir quatre chemins ; il en a un, vu sous
quatre angles. C'est directement contraire à la promesse « chaque placement réduit les
solutions possibles », et c'est aussi ce qui rend le compteur illisible aux petites tailles.

**Exigence :** décider si le compteur affiche les solutions brutes ou **à symétrie près**, et
l'appliquer partout (jeu, records, classement, captures). Recommandation : à symétrie près —
c'est le nombre qui a un sens pour le joueur. Coût : une division par la taille de l'orbite,
qui n'est pas toujours 4 (une solution auto-symétrique a une orbite plus petite) ; il faut
donc compter les orbites, pas diviser.

### 2.4 « Moins de 8 transformations » est un seuil qui ne veut rien dire

Mesuré : les quatre boutons de la barre d'isométries engendrent le groupe diédral D₄ avec un
**diamètre de 2** — toute orientation est atteignable en au plus deux appuis, pour toute
pièce. Coût moyen d'une pièce prise seule, orientation de départ uniforme : 1,25 appui pour
les pièces à 8 orientations (P, F, Y, L, N), 0,75 à 1,00 pour celles à 4 (T, U, V, W, Z),
0,50 pour I, 0 pour X.

Minimum réel pour **résoudre** au niveau 1, sur les 7 configurations et toutes les
orientations de départ : **médiane 2, maximum 4, minimum 0**.

Donc « moins de 8 transformations » est atteint sans effort au niveau 1 et n'a aucun rapport
avec le 6×10, dont la somme des coûts moyens vaut environ 11 avant tout choix de solution. Un
seuil absolu est absurde.

**Exigence :** le score d'isométries est **relatif**, jamais un seuil en valeur brute. La forme
retenue est l'**acuité isométrique** du §4.2 — rapportée au minimum du placement que le joueur a
posé. Affichage : `acuité 86 % (6 isométries, minimum 5)`.

### 2.5 « Zéro transformation inutile » récompenserait le hasard

Au niveau 1, le minimum vaut 0 dans **28 cas sur 1 664** (1,7 %), soit 4 cas sur 256 par
configuration : les pièces tombent déjà bien orientées. Une médaille « zéro transformation »
serait décernée à un tirage chanceux, pas à une vision. La médaille se décerne sur l'**acuité à
100 %** (§4.6), jamais sur un nombre brut d'isométries. Ce même cas impose le `+ 1` de la
formule d'acuité.

---

## 3. Ce qui existe déjà — à ne pas redévelopper

Vérifié dans `pentoscope_provider.dart` et `settings_database.dart` :

| Élément | État | Emplacement |
|---|---|---|
| `hintCount` | existe, persisté | état + `CurrentGame` + records |
| `isometryCount` | existe, incrémenté par les 4 boutons | l. 1117, 1376, 1621 |
| `translationCount` | existe (déplacement d'une pièce posée) | l. 999 |
| `deleteCount` | existe (retrait d'une pièce) | état |
| Enregistrement d'un succès | existe | `recordSolvedSolution(board, solutionNumber, timeSeconds, actions)` |
| Note sur 20 fondée sur les aides | existe | `calculateNote()` |
| Configuration identique pour tous | existe | `generateFromSeed(size, seed, pieceIds)` |
| Pseudo joueur | existe | progression solo, commit `4be276f` |

**Défaut à corriger :** `recordSolvedSolution` enregistre un seul champ `actions` =
`isometryCount + translationCount + deleteCount`. Le classement du mémo a besoin des trois
séparément. Le schéma doit les séparer **avant** publication — après, la migration touche des
données de joueurs (checklist point 3).

**Absent, à créer :** le nombre de **poses** (un coup = poser une pièce sur la grille), et la
**somme** qui donne `minIso` (§4.2). La distance elle-même existe déjà :
`Pento.minIsometriesToReach` (`pentominos.dart` l. 795), BFS sur les quatre mêmes boutons,
orpheline depuis le 2026-08-30 et conservée à dessein. Il ne reste qu'à lire les orientations
dans la grille terminée et à sommer — douze appels au plus, aucune table consultée.

---

## 4. Système de performance

> Décision de Paul du 2026-09-03, prise en connaissance de l'effet consigné en 4.4.
> Les mesures qui la fondent sont dans `REFERENCE_ISOMETRIES.md` §4.

### 4.1 Trois classements, pas un — décision de Paul, 2026-09-03

> **Refonte « A » — 2026-09-05 : RETOUR À TROIS maillots, et acuité PLAFONNÉE.** Le 4e maillot
> **⚪ Blanc (Help)** de l'amendement du 2026-09-04 et le maillot **⚫ Coups (à pois)** sont
> **fusionnés** en un unique **🔴 À pois — Fautes** : nombre de transitions *soluble→insoluble*
> (culs-de-sac créés). Trois raisons : (1) l'acuité pouvait **dépasser 100 %** quand l'ampoule
> plaçait une pièce sans coûter d'isométrie → elle est désormais **plafonnée à 1.0** (§4.2) ;
> (2) « coups » classait une *habitude de geste* (retirer-reposer vs déplacer) plus qu'une
> compétence ; (3) à la complétion, le nombre de fautes (jaune→rouge) **égale** exactement le
> nombre de sauvetages (rouge→jaune, l'ancien « Help ») — une seule mesure pour deux anciens
> maillots. Bilan/records/serveur portent désormais **trois** valeurs (acuité plafonnée, fautes,
> temps). Le tableau et les §4.4-4.7 ci-dessous sont à lire à travers ce prisme ; le manuel
> `MANUEL_DEFIS_ET_MAILLOTS.md` en donne l'état courant faisant foi.
>
> **Amendé le 2026-09-04 : QUATRE maillots, pas trois.** (Amendement remplacé par la refonte « A »
> ci-dessus.) Un **4e maillot** s'ajoutait — **Help** (moins de sauvetages rouge→jaune, cf. §7 Acté
> 3-4) — **maillot blanc** (le 4e du Tour). Conservé ici pour la trace historique.

Un défi n'a **pas** de vainqueur unique. Les mêmes données produisent **trois classements
indépendants**, sur le modèle du Tour de France :

| Maillot | Classement | Clé de tri |
|---|---|---|
| **Jaune** | **Acuité isométrique** | décroissant — 100 % en tête |
| **À pois** | **Coups** | croissant — le minimum est le nombre de pièces |
| **Vert** | **Temps** | croissant |

*(Au Tour, le grimpeur porte le maillot à pois rouges et le sprinteur le vert ; « maillot
rouge » est le leader du Giro ou de la Vuelta. **Nommage arrêté par Paul le 2026-09-03 (§12,
Q5)** : on garde jaune / à pois / vert.)*

Le jaune va à l'acuité : c'est l'identité du produit, celle qu'aucun autre jeu de pavage ne
mesure. Le vert récompense la vitesse, le à pois l'économie de gestes. **Aucun des trois n'est
« le vrai »**, et il n'y a pas de classement combiné — arbitrer entre eux serait réintroduire
la pondération que ces trois maillots évitent.

Ce que ce choix règle, et qui résistait jusqu'ici :

- **plus de tri lexicographique**, donc plus de critère qui en écrase un autre ;
- **plus de conflit entre acuité et économie de gestes** : le joueur à 1 isométrie qui perdait
  le maillot jaune contre celui à 6 (§4.4) gagne le maillot à pois. Les deux lectures coexistent
  au lieu de se disputer une seule place ;
- **le critère « aides » disparaît des clés de tri** — et c'est cohérent : l'indice est
  neutralisé en mode classé (§4.8), donc il vaut 0 pour tout le monde. Hors mode classé, une
  partie avec aide n'entre simplement dans aucun des trois classements ;
- **trois fois plus de chances d'être classé quelque part** : un joueur rapide et brouillon
  brille en vert, un joueur lent et net en jaune. Personne n'est exclu par son style.

**Coût à surveiller — l'encombrement.** Trois classements × six tailles = dix-huit tableaux. Ne
pas les afficher tous : une seule vue, la taille du joueur par défaut, et les trois maillots en
onglets ou en trois podiums côte à côte. Côté base, trois index (§7), pas trois tables.

### 4.2 L'acuité isométrique

```
minIso = Σ  d( orientation de p dans le rack , orientation de p dans le placement posé )
        p ∈ pièces

acuité = (minIso + 1) / (isometryCount + 1)
```

`d` est la distance dans le graphe de Cayley de D₄ engendré par les **quatre boutons réels** de
la barre. Diamètre 2, donc `d ∈ {0, 1, 2}`. La primitive existe : `Pento.minIsometriesToReach`.

**`minIso` porte sur le placement que le joueur a réellement complété**, pas sur l'ensemble des
solutions du puzzle. L'objectif n°1 est de terminer ; le score mesure ensuite le tâtonnement sur
le chemin pris. On ne reproche pas au joueur d'avoir manqué un agencement moins coûteux qu'il ne
pouvait pas voir — sur le 6×10, comparer 9 356 solutions est hors de portée humaine.

Le `+ 1` traite le cas dégénéré `minIso = 0` (rack déjà bien orienté), où la forme brute
donnerait 0 % pour un geste de trop comme pour cinquante, et `0/0` pour une partie sans
isométrie. Il n'altère pas les valeurs utiles : 10 pour 20 donne 52 % au lieu de 50 %.

**Coût d'implémentation : nul.** Une fois le plateau complété, on lit l'orientation de chaque
pièce dans la grille finale et on somme douze appels au plus. Aucune table de solutions n'est
consultée.

### 4.3 Exigence — rack identique pour tous

Le classement n'a de sens que si tous les joueurs d'un même défi partent des mêmes orientations
initiales. `startPuzzleFromSeed` le fait déjà (`Random(seed)`). **Réserve** : Dart ne garantit
pas formellement la stabilité de `Random(seed)` entre versions du SDK — pour un classement qui
doit survivre à une montée de Flutter, tirer les orientations avec un PRNG écrit dans le dépôt.

### 4.4 Effet accepté — borné au maillot jaune

`minIso` porte sur le placement posé, le rack est commun : deux joueurs d'un même défi peuvent
donc être classés au **maillot jaune** dans l'ordre inverse de leur nombre de manipulations. Un
joueur qui pose le retournement coûteux sans gaspiller (6 isométries, acuité 100 %) passe devant
un joueur qui a fini en 1 isométrie (acuité 50 %) — exemple réel dans
`REFERENCE_ISOMETRIES.md` §4.

C'est cohérent avec ce que l'acuité mesure : l'absence de tâtonnement sur le chemin choisi, et
non l'économie de gestes. **Arbitrage assumé (Paul, 2026-09-03). Ne pas le « corriger ».**

Depuis la décision des trois maillots (§4.1), cet effet ne prive plus personne : le joueur à
1 isométrie remporte le **maillot à pois**, où seul le nombre de coups compte. Les deux lectures
sont récompensées séparément, ce qui était le vrai remède.

### 4.5 Ce que le joueur voit à la fin

```
Résolu
acuité isométrique 86 %   (6 isométries, minimum 5)     ← maillot jaune
17 coups                  (minimum 12)                  ← maillot à pois
03:42                                                    ← maillot vert
```

Les coups sont affichés **en brut**, pas en pourcentage : 12 sur 17 donne 71 %, et un
pourcentage punitif juste après une victoire décourage. L'acuité garde le sien, son échelle
étant plus clémente.

Le classement n'apparaît que si le joueur a activé l'envoi de score (§7).

### 4.6 Médaille

**Vision parfaite** = acuité à 100 %, c'est-à-dire aucun geste au-delà du nécessaire. Jamais un
seuil en valeur brute : `minIso` vaut 0 dans 1,7 % des parties du niveau 1, une médaille
« zéro isométrie » récompenserait le tirage et non le joueur.

### 4.7 Les coups

> **Tranché par Paul le 2026-09-03 (§12, Q6) : le déplacement direct d'une pièce posée ne compte
> PAS comme un coup.** Ni 1 ni 2 — `translationCount` sort du décompte.

Un **coup** = **poser** une pièce ou la **retirer**. Déplacer une pièce déjà posée est **gratuit**.
Le minimum reste le **nombre de pièces** : 12 sur le 6×10, 3 au niveau 1 (chaque pièce est posée
une fois, aucun retrait dans une partie sans erreur). Comme pour les isométries, le score est
relatif :

```
efficacité = nombre de pièces / nombre de coups        (coups = poses + retraits)
```

Pas de cas dégénéré ici — le nombre de coups vaut toujours au moins le nombre de pièces, donc
aucun `+ 1` n'est nécessaire. 17 coups sur un 6×10 → 71 %.

**Raison du choix (Paul).** Ne pas compter le déplacement direct récompense la **manipulation
directe** plutôt que le détour par le tiroir, et surtout ne départage plus les joueurs sur leur
**habitude de geste** — deux joueurs qui aboutissent au même plateau ne doivent pas être classés
différemment parce que l'un déplace et l'autre retire-repose. Le maillot à pois mesure donc les
**poses et retraits**, c'est-à-dire le tâtonnement de placement, pas le déplacement d'ajustement.

**Conséquence technique** : le décompte des coups **ignore `translationCount`** et somme le
nombre de poses et de retraits (`deleteCount` existe déjà ; le compteur de poses est à vérifier
au moment du code — il n'est peut-être pas encore matérialisé).

### 4.8 Mode classé — ce qui change, et ce qui ne change pas

| Élément | En mode classé | Pourquoi |
|---|---|---|
| **Compteur de solutions** | **conservé** | C'est l'identité du produit et l'argument de la capture n°2. Il est **identique pour tous** les joueurs du défi : il abaisse la difficulté pour tout le monde à la fois, il ne crée aucune inégalité. Un mode classé qui masquerait la seule chose qui distingue Pentapol serait un autre jeu |
| **Couleur de la lampe** | conservée | Elle sort du **même calcul** que le compteur (`hasPossibleSolution` et `solutionsCount` renvoyés ensemble, l. 315) : la neutraliser pendant que le compteur reste affiché ne masquerait rien |
| **Appui sur la lampe (indice)** | **neutralisé** | C'est la seule aide réelle : elle place une pièce à la place du joueur |
| **Retrait d'une pièce** | inchangé | Sélectionner une pièce posée fait apparaître la **poubelle** dans la barre d'isométries (`hasDeleteButton`, portrait et paysage). Le retour arrière ne dépend donc pas de la lampe : neutraliser l'appui ne prive le joueur de rien, sauf du retrait de la dernière pièce sans la sélectionner — une commodité, pas une fonction unique |
| **Rack et configuration** | identiques pour tous | §4.3 |

**Conséquence à assumer** : l'indice étant indisponible, le critère n°1 du classement (aides
utilisées) vaut **toujours 0** en mode classé. Le classement se joue en pratique sur l'acuité,
puis les coups, puis le temps. Le critère « aides » garde son sens pour les records personnels
hors classement, et pour départager si l'indice devait être réintroduit un jour.

**Variante à considérer** (non retenue) : plutôt que de griser le bouton, laisser l'indice
accessible et rendre la partie **non classable** dès le premier usage, avec un dialogue de
confirmation. Le joueur bloqué finit sa partie au lieu d'abandonner — un abandon ne laisse aucune
trace, une résolution assistée en laisse une — et la règle « 0 aide » reste absolue au
classement. Coût : un dialogue et un booléen.

---

## 5. Le compteur de solutions

C'est le différenciateur. Exigences :

1. Visible dès la première seconde de jeu, pas caché derrière un réglage. Aujourd'hui il
   dépend de `showSolutionCounter` — à activer par défaut.
2. Nombre **à symétrie près** (§2.3), cohérent partout.
3. Le passage à zéro doit être compris **immédiatement** : c'est l'instant où l'app tient sa
   promesse. Le comportement actuel (ampoule rouge, appui = retour arrière) est bon ; il faut
   qu'un joueur le découvre sans l'avoir lu.
4. Ne pas laisser croire que le compteur est un score : c'est un instrument, pas une note.

---

## 6. Onboarding

Traité à part, avec ses propres mesures : voir l'analyse de la première ouverture — **42,9 %
des premières parties sont insolubles sans le bouton miroir**, et dans 100 % de ces cas le
joueur pose quand même 2 pièces sur 3 avant de se retrouver bloqué sans indice.

Ordre retenu, conforme au mémo §8 mais corrigé par cette mesure :

1. rendre le niveau 1 toujours résoluble par rotations seules (contrainte sur les
   orientations de départ) ;
2. introduire le besoin du miroir au niveau 2, délibérément ;
3. **là seulement**, trois gestes guidés : prendre une pièce, la retourner, la poser ;
4. le compteur de solutions expliqué en une phrase au premier passage à un nombre plus petit.

Passable dès le premier écran, rejouable depuis les réglages.

---

## 7. Le défi de la semaine et son classement

> ⚠️ **Hors V1 — décision de Paul du 2026-09-03 (§12, Q3, modèle économique option 1).** Le
> classement en ligne et le défi de la semaine ne sont **pas** dans la V1 : un jeu payant d'un
> éditeur peu connu n'a pas la population qui remplit un classement, et un classement vide
> décourage. Ils deviennent la **première mise à jour**, avec leur argument de communication à ce
> moment-là. La V1 se contente des **records et statistiques personnels** (§4, qui reste utile
> hors classement). Cette section est conservée **telle quelle comme spécification de cette mise à
> jour** — rien n'y est abandonné, seulement différé.

> Spécifié le 2026-09-03 avec Paul. Le service à écrire **n'est pas** le worker existant :
> `https://pentapol-duel.pentapml.workers.dev` (URL en dur) est un WebSocket + Durable Objects
> pour le duel temps réel. Un classement asynchrone est un POST de score et un GET de tableau ;
> il ne réutilise rien sauf le compte Cloudflare. Aucun Durable Object n'est nécessaire.

> **Révision du 2026-09-04 (discussion Paul ↔ CLI).** Quatre points, dont deux **actés** et deux
> **encore ouverts**. Ils amendent §7.1, §7.3, §7.5 et §7.6 ci-dessous ; le corps de ces sections
> est conservé, cette note prime là où elle diffère.
>
> **Acté 1 — le défi est COMPOSABLE À LA MAIN, autorité serveur.** On garde la **capacité de choisir/
> ajuster** les défis à la main (éviter les tirages dégénérés, thématiser). La définition d'un défi = **trois
> informations : `(taille, masque, rack)`**, stockées dans une table serveur `challenges` indexée
> par `(version, semaine, taille)`. Conséquence : §7.3 est **amendé** — le défi n'est plus « purement
> dérivé, rien ne transite ». La dérivation `deriveChallenge` (déjà codée, `challenge.dart`) devient
> (a) le **générateur par défaut** qui pré-remplit la table (exécuté **en Dart** et téléversé — on ne
> réimplémente PAS `PentapolRng` en JavaScript), et (b) le **repli hors ligne** du client quand le
> réseau manque et qu'il n'y a pas de cache. Le client **télécharge** la définition de la semaine et
> la **met en cache**. Bénéfice de vérification (§7.5) : le serveur ayant le **rack en table**,
> il recalcule `minIso` directement, sans porter le PRNG côté Worker.
>
> **Acté 1bis — amorçage paresseux par le premier joueur (Paul, 2026-09-04).** Au lancement, le
> client lit pour la **semaine en cours** si les *n* définitions (une par taille ouverte) sont
> **initialisées** sur le serveur. Si oui → il les utilise. Si non → **le premier client les génère**
> (via `deriveChallenge`, en Dart) et les POST. Pas de cron serveur. Comme la dérivation est
> **déterministe**, tous les « premiers » produiraient la même définition → l'écriture serveur doit
> être **idempotente** (« insérer si absent », clé `(version, semaine, taille)`), la course est alors
> inoffensive. **Composition à la main** : une semaine composée à la main se **pré-remplit avant le
> premier joueur** (une redéfinition après coup ferait diverger les clients ayant déjà mis en cache).
> Hors ligne au lancement → repli sur la dérivation locale (= le défaut algorithmique) ; si la semaine
> était composée à la main, désaccord détecté à la
> soumission (edge rare, accepté).
>
> **Acté 2 — le serveur fait confiance aux chiffres d'une partie validée.** Tous les chiffres
> (`minIso`, coups, temps, Help) sont calculés **localement** et **montent au serveur** pour une
> partie validée (grille = pavage correct de la config de la semaine). Le serveur **recalcule
> `minIso`** (infalsifiable) et **fait confiance** aux coups/temps/Help, bornés par leurs minima —
> exactement le modèle déjà admis en §7.5 (« la triche ne peut jouer que sur le vert et le à pois »).
>
> **Acté 3 — indicateur « Help », métrique.** Un compteur d'**aide** distinct de l'ampoule :
> les **sauvetages rouge→jaune** = nombre de fois où une action du joueur ramène le plateau
> d'insoluble à soluble (par **translation OU retrait+repose** — **agnostique au geste**, cohérent
> avec Q6 §4.7). C'est l'usage réel de l'oracle (la couleur de la lampe). Détectable au code : au
> placement/déplacement, comparer `hasPossibleSolution` avant/après.
>
> **Acté 4 — Help est un 4e MAILLOT classé (Paul, 2026-09-04).** Moins de sauvetages = tête de
> classement. **§4.1 est amendé : quatre maillots, plus trois** — acuité (jaune), coups (à pois),
> temps (vert), Help (**maillot blanc**, le 4e du Tour ; nommage figé par Paul le 2026-09-04).
> Quatre classements indépendants, aucun combiné. Cohérent avec §4.8 :
> la lampe reste visible pour tous, Help classe simplement *qui s'en sert le moins*. Coût assumé :
> quatre tableaux par taille (l'encombrement de §4.1 s'accroît — une seule vue, onglets/podiums).
>
> **Acté 5 — un seul essai par joueur et par config, quatre valeurs (Paul, 2026-09-04).** §7.1
> « le premier essai, pas le meilleur » est **conservé** : une seule soumission par
> `(joueur, semaine, taille)`, **insertion unique, jamais de mise à jour**. Cet essai produit
> **quatre valeurs** (acuité, coups, temps, Help) → **une seule ligne** par `(joueur, semaine, taille)`
> portant les quatre + la **grille** (pour re-vérifier `minIso`). Chaque maillot trie sur sa colonne
> (« meilleure valeur par dimension » = classement indépendant par dimension, pas un meilleur sur
> plusieurs essais). Schéma D1 (§7.6) : **quatre index**, un par maillot. La clé primaire impose
> l'essai unique (§7.1).

### 7.1 Forme retenue

Le joueur ouvre l'option **Défi**, choisit une **dimension de plateau**, et Pentapol dérive tout
le reste de la semaine courante. Un défi = `(semaine, taille)`. Trois classements par défi
(§4.1). Un score par joueur et par défi : **le premier essai**, pas le meilleur — cohérent avec
« voir avant d'agir », et plus simple (une insertion, jamais de mise à jour).

### 7.2 Tailles ouvertes au défi

Le 6×10, le 5×9 et le 5×10 sont **écartés** (trop longs — décision de Paul). Restent six tailles,
soit 756 configurations :

| Taille | Configurations | Racks distincts | Reprise de la configuration |
|---|---|---|---|
| 3×5 | 7 | 1 664 | **7 semaines** |
| 4×5 | 26 | 33 024 | 6 mois |
| 5×5 | 45 | 259 072 | 10 mois |
| 5×6 | 172 | 4 845 568 | 3,3 ans |
| 5×7 | 245 | 31 383 552 | 4,7 ans |
| 5×8 | 261 | 113 803 264 | 5 ans |

Distinguer les deux colonnes, c'est le cœur du sujet : le **rack** ne se répète jamais (32 ans
pour le 3×5), mais la **configuration** revient — donc l'agencement à trouver, et le joueur s'en
souvient.

Conséquence à assumer : sur 3×5 et 4×5, `minIso` ne dépasse pas 4 et le minimum de coups vaut 3
ou 4. Presque tous les joueurs atteindront 100 % d'acuité : **le maillot jaune et le maillot à
pois n'y départageront personne, seul le vert classera.** Ce sont des défis de vitesse, à
présenter comme tels. Les trois maillots gardent tout leur sens à partir du 5×6.

### 7.3 Dérivation — tout descend d'un entier, rien ne transite

```dart
final week  = weeksSinceEpoch();                       // lundi 5 janvier 2026, 00:00 UTC
final seed  = mix(kChallengeVersion, week, size.index);
final rng   = PentapolRng(seed);                       // PRNG du dépôt

// 1. la configuration : un masque parmi les solubles de cette taille
final solubles = solubleMasksSorted(size.numPieces);   // tri explicite, valeur croissante
final mask     = solubles[rng.nextInt(solubles.length)];

// 2. le rack : une orientation par pièce, pièces par id croissant
for (final pid in piecesOf(mask)) {
  orientation[pid] = rng.nextInt(pentoById(pid).numOrientations);
}
```

Deux joueurs qui choisissent la même taille la même semaine obtiennent le même masque **et** le
même rack sans échanger un octet. Le serveur n'a jamais besoin de connaître la configuration : il
range les scores sous `(version, semaine, taille)`. `week` étant un entier, tout défi passé se
recalcule — l'historique est gratuit.

**Cinq pièges, tous mortels et tous évitables :**

1. **UTC obligatoire.** Sinon la semaine ne commence pas au même instant selon le pays et deux
   joueurs ne jouent pas le même défi.
2. **PRNG écrit dans le dépôt.** `Random(seed)` de `dart:math` n'est pas garanti stable entre
   versions du SDK : une montée de Flutter changerait tous les défis. Un xorshift de dix lignes
   règle la question définitivement. Cela vaut aussi pour `startPuzzle`, qui tire aujourd'hui
   avec un `Random()` non initialisé — le mode défi doit passer par le chemin seedé.
3. **Ordre de tirage figé.** L'ordre des masques vient d'un tri explicite, jamais de l'ordre
   d'itération d'une `Map` ; les pièces sont parcourues par id croissant.
4. **`kChallengeVersion` dans la clé du classement.** Le jour où l'algorithme change, les anciens
   classements restent lisibles au lieu d'être silencieusement corrompus.
5. **Test de non-régression** : figer les dix premiers défis (`week` 0 à 9, chaque taille) —
   masque et orientations — dans un test. Seul garde-fou contre une modification involontaire de
   la dérivation.

### 7.4 Identité du joueur

Rien de persistant n'existe aujourd'hui : `userName` est un `String?` dans `AppSettings`, et le
`playerId` du duel est attribué par le worker à chaque connexion.

Séparer **identité** et **affichage**. À la première ouverture, le client génère **128 bits
aléatoires** stockés dans `AppSettings` (champ JSON, donc aucune migration — invariant #6) : c'est
la clé primaire côté serveur. Le pseudo devient une étiquette ; deux « Paul » coexistent, et en
cas d'homonymie dans un même classement l'affichage suffixe quatre caractères de l'identifiant
(`Paul#3f9a`).

Ce que cette solution coûte, à écrire dans l'aide plutôt qu'à laisser découvrir :

- **désinstaller l'application perd l'identité** et tout l'historique de classement ;
- rien n'est transférable d'un appareil à l'autre ;
- un joueur peut se refabriquer des identités en réinstallant — enjeu faible sans récompense ;
- **RGPD** : un identifiant persistant lié à une activité *est* une donnée personnelle, même sans
  nom (voir §8).

La portabilité entre appareils demanderait Sign in with Apple — et Apple exige alors la
suppression du compte depuis l'application. À garder pour plus tard, en connaissance de cause.

### 7.5 Vérification côté serveur — sans elle, le classement se remplit de 100 %

N'importe quel client peut poster n'importe quel score. Bonne nouvelle : **le système de score
est vérifiable**, ce qui est rare. Le client envoie la grille terminée (un id de pièce par case,
soixante octets au plus) et les compteurs ; le worker recalcule :

| Élément | Vérifiable ? |
|---|---|
| La grille est un pavage valide avec exactement les pièces du défi | **oui**, vérification pure, aucun solveur |
| `minIso`, donc l'**acuité** — maillot jaune | **oui**, exactement : rack de la semaine + orientations lues dans la grille |
| Coups — maillot à pois | non, seulement borné : ≥ nombre de pièces |
| Temps — maillot vert | non, seulement borné par un plancher plausible |
| Aides | constant : 0 pour tous en mode classé (§4.8) |

Le maillot jaune est donc infalsifiable, et c'est celui qui porte l'identité du produit. La
triche ne peut jouer que sur le vert et le à pois.

### 7.6 Stockage — D1, pas KV

KV ne trie pas ; un classement se trie.

```sql
CREATE TABLE scores (
  version   INTEGER NOT NULL,
  week      INTEGER NOT NULL,
  size      INTEGER NOT NULL,
  playerId  TEXT    NOT NULL,
  pseudo    TEXT    NOT NULL,
  minIso    INTEGER NOT NULL,
  isoCount  INTEGER NOT NULL,
  moves     INTEGER NOT NULL,
  timeMs    INTEGER NOT NULL,
  grid      BLOB    NOT NULL,
  PRIMARY KEY (version, week, size, playerId)
);
CREATE INDEX maillot_jaune  ON scores (version, week, size, minIso, isoCount);
CREATE INDEX maillot_pois   ON scores (version, week, size, moves);
CREATE INDEX maillot_vert   ON scores (version, week, size, timeMs);
```

Trois index, une seule table. `minIso` et `isoCount` sont stockés **bruts** plutôt que l'acuité :
le rapport se recalcule, et les deux nombres permettent d'auditer un score après coup. La clé
primaire impose le premier essai (§7.1) : l'insertion d'un second est refusée.

### 7.7 Prérequis — le chronomètre ne se met pas en pause

Il n'existe **aucun** `didChangeAppLifecycleState` dans l'écran de jeu ni dans `GameTimerMixin`
— alors que `HomeScreen` en a un pour son animation. Le temps est calculé par différence avec
`_startTime`, pas par accumulation de tics : un appel téléphonique, un verrouillage d'écran ou un
passage dans une autre application sont **intégralement comptés**.

Acceptable pour un chrono d'ambiance en solo, rédhibitoire pour le maillot vert. Le mixin sait
déjà faire — `stopTimer` conserve l'origine, `startTimer` reprend sans perdre le temps accumulé ;
il ne manque que l'observateur de cycle de vie qui les appelle. **Bloquant du classement au
temps**, au même titre que le rack commun (§4.3).

### 7.8 Le service peut s'arrêter

Le jeu doit rester **entier** sans réseau : le défi se calcule hors ligne (§7.3), seuls l'envoi
du score et la consultation des classements demandent une connexion. Prévoir dès le départ le
jour où le serveur ne répond plus — un bouton mort dans une application payante est un avis à une
étoile. Un score envoyé est immuable ; pas de suppression sélective côté client.

---

## 8. Confidentialité — ce que le classement coûte

Aujourd'hui, sans le multijoueur, **aucune donnée ne quitte l'appareil**. C'est la
déclaration App Privacy la plus simple qui existe, et c'est un argument de vente.

Le classement mondial la supprime : envoyer pseudo + score, c'est collecter un identifiant
utilisateur lié à une activité. Conséquences, non négociables :

- la déclaration App Privacy change de catégorie ;
- RGPD : mention obligatoire, base légale, politique de confidentialité à jour ;
- si le pseudo devient un compte (récupération sur un autre appareil), Apple **exige** la
  suppression du compte depuis l'application.

**Recommandation :** envoi de score **désactivé par défaut**, activé par un geste explicite du
joueur, et jeu complet sans lui. Cela garde « aucune donnée collectée » comme comportement par
défaut et rend la déclaration honnête.

---

## 9. La contradiction à trancher : payant + classement

Le mémo veut deux choses qui se gênent.

- **Payant, sans publicité ni achat intégré** : cohérent avec le produit, et le bon
  positionnement pour un puzzle de réflexion.
- **Classement mondial et défi du jour comme moteurs de rétention** : ils supposent une
  population de joueurs.

Un jeu payant d'un éditeur sans notoriété fait peu d'installations. Peu d'installations
donnent un classement quasi vide, et un classement vide ne retient personne — il décourage.
Les deux mécaniques que le mémo place en 6ᵉ et 7ᵉ priorité sont donc les plus exposées au
choix de modèle économique.

Trois issues cohérentes, à choisir explicitement :

1. **Payant, sans classement mondial en V1.** On garde les records personnels et les statistiques
   (§11 du mémo), qui fonctionnent avec un seul joueur. Le classement attend d'avoir une
   population. C'est l'option la plus sûre, et elle préserve « aucune donnée collectée ».
2. **Payant avec classement**, en acceptant qu'il soit maigre au début et en l'affichant de
   façon qui ne le souligne pas (rang parmi les joueurs du jour, pas « 84ᵉ / 6 231 »).
3. **Gratuit avec déblocage premium**, ce qui donne la population — mais complique la V1 et
   contredit « vous achetez le jeu, vous avez le jeu ».

Recommandation cowork : **option 1**. Les statistiques personnelles portent seules la
rétention en V1, et le classement devient la première mise à jour, avec un argument de
communication à ce moment-là.

---

## 10. Vérification

Les mesures de ce document sont établies et rejouables ailleurs :

| Sujet | Référence | Script |
|---|---|---|
| Isométries, `minIso`, chiralité, première ouverture | `REFERENCE_ISOMETRIES.md` | `tools/verif_isometries.py` |
| Tirages solubles, 996, contrôle de l'asset livré | `REFERENCE_TIRAGES.md` §2 et §11 | `tools/verif_subset_counts.py` (≈ 70 s) |

Les deux scripts relisent `lib/common/pentominos.dart` et n'utilisent aucune valeur écrite à la
main. À relancer après toute modification de la table des pièces, de leurs orientations, des
tirages d'accueil ou des assets de solutions.

## 11. Priorités V1 — révisées

L'ordre du mémo §14 est bon. Deux déplacements, justifiés par les mesures :

| # | Chantier | Écart avec le mémo |
|---|---|---|
| 1 | **Manipulation tactile** | inchangé. Le chantier a déjà été reverté une fois (2026-09-01) ; il n'est pas acquis |
| 2 | **Première ouverture toujours gagnable** (§6, étapes 1-2) | **remonté** : c'est une correction de tirage, pas de la pédagogie, et elle est très peu coûteuse |
| 3 | **Sauvegarde de la partie en cours** | **remontée** de la 4ᵉ à la 3ᵉ place : perdre une partie de 6×10 en quittant l'app coûte plus qu'un tutoriel absent |
| 4 | **Tutoriel court** (§6, étapes 3-4) | après 2 et 3, dont il dépend |
| 5 | **Compteur de solutions lisible** (§5) | dont la décision « à symétrie près » |
| 6 | **Records personnels et statistiques** — avec les compteurs séparés (§3) | |
| 7 | **Chronomètre suspendu en arrière-plan** (§7.7) | **dès la V1** — le temps entre dans les records personnels (le futur maillot vert, #6) : sans suspension, le premier appel téléphonique le fausse, classement ou pas. Le second prérequis, **PRNG écrit dans le dépôt** (§7.3, piège 2), ne sert qu'à rendre le **défi** reproductible entre versions du SDK : il part avec le défi (#8, hors V1) |
| 8 | Défi de la semaine et ses trois classements (§7) | **hors V1** — Paul a tranché le §9 en faveur de l'option 1 (§12, Q3). Devient la première mise à jour |
| 9 | Multijoueur temps réel | **maintenu dans la V1** — Paul le garde accessible (§12, Q4), contrairement à la recommandation initiale de couper |

Rappel des bloquants techniques indépendants de tout cela, déjà listés dans
`CHECKLIST_APPSTORE.md` : identifiant de bundle `com.example.pentapol`, `flutter test` rouge,
`supabase_flutter` inutilisé, migration destructive, absence de rapport de plantage.

---

## 12. Questions tranchées par Paul — 2026-09-03

Les sept questions ouvertes ont été **tranchées par Paul le 2026-09-03**. Conservées ici avec
leur réponse pour l'audit ; chaque section concernée porte un renvoi vers cette liste.

1. **Déverrouillage progressif** — pas de choix libre de la taille dès le départ. Le joueur monte
   taille par taille ; c'est déjà le comportement du code (`currentLevel`, `sizeForLevel`). Le
   « + » (choix libre d'une taille) reste un accès secondaire, hors progression.
2. **Le compteur affiche TOUTES les solutions**, symétries comprises — **pas** « à symétrie près »
   (§2.3). Décision transverse : records, classement et captures s'alignent sur ce compte. C'est
   aussi le comportement actuel du code (§2.3). Ferme la part « à symétrie près » de la priorité #5.
3. **Payant, sans classement mondial en V1** — §9, **option 1** (recommandation cowork). Les
   records et statistiques personnels portent seuls la rétention en V1 ; le **défi de la semaine
   et son classement (§7) passent hors V1** et deviennent la première mise à jour. « Aucune donnée
   collectée » préservé. → renvois posés en tête de §7 et à la priorité #8.
4. **Le duel temps réel reste accessible en V1** — contrairement à la recommandation initiale de
   couper. → priorité #9 maintenue dans la V1.
5. **Nommage Tour de France retenu** : maillot **jaune** = acuité, **à pois** = coups, **vert** =
   temps (§4.1). Nommage figé.
6. **Un déplacement direct ne compte PAS comme un coup** — ni 1 ni 2. `translationCount` sort du
   décompte : un **coup** = poser ou retirer une pièce, déplacer une pièce déjà posée est gratuit.
   → §4.7 mis à jour ; le maillot à pois mesure poses + retraits, minimum = nombre de pièces.
7. **3×5 et 4×5 restent ouverts au défi** (§7.2), assumés comme **défis de vitesse** : `minIso`
   n'y dépasse pas 4 et le minimum de coups vaut 3 ou 4, donc jaune et à pois n'y départagent
   personne — seul le vert classe. (Concerne la mise à jour « défi », le défi étant hors V1 — Q3.)
