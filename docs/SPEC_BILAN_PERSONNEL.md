# Spécification exploratoire — bilan personnel du joueur

> _Créé le 2026-09-29, enrichi le 2026-09-30. Statut : point de départ de réflexion, non validé
> pour implémentation._

## 1. Intention

Pentapol ne doit pas seulement dire si un puzzle est terminé. Le bilan personnel doit aider le
joueur à comprendre **comment il résout**, quelles aptitudes propres au jeu il mobilise, où il
progresse et ce qu'il peut travailler ensuite.

La promesse produit proposée est :

> **Pentapol entraîne votre regard géométrique et vous montre comment votre manière de résoudre
> évolue.**

Le bilan vise trois réponses immédiates :

1. Quelles sont mes aptitudes actuelles dans Pentapol ?
2. Est-ce que je progresse, et sur quels aspects ?
3. Quel est aujourd'hui mon principal axe de progression ?

## 2. Limites de la promesse

Le produit peut parler d'**aptitudes observées dans Pentapol**, de raisonnement spatial mobilisé
par le jeu et d'évolution personnelle. Sans protocole scientifique externe, il ne doit pas
présenter ses scores comme une mesure :

- de l'intelligence générale ou d'un QI ;
- d'une aptitude clinique ou neuropsychologique ;
- de la prévention ou de la détection d'un déclin cognitif ;
- d'un transfert garanti vers les capacités générales du joueur.

Les formulations doivent rester descriptives : « dans tes parties Pentapol », « sur tes dix
dernières parties », « tu utilises moins de manipulations ». Le bilan n'est ni un diagnostic ni
une comparaison normative avec une population.

## 3. Ce que Pentapol peut faire travailler

Ces bénéfices constituent des **hypothèses produit raisonnables**, pas des effets scientifiques
démontrés :

- **visualisation spatiale** : imaginer une pièce après rotation ou symétrie ;
- **décomposition géométrique** : percevoir l'occupation et les zones laissées libres ;
- **anticipation** : estimer les conséquences d'un placement avant de le valider ;
- **planification** : coordonner plusieurs placements plutôt que traiter chaque pièce isolément ;
- **flexibilité de stratégie** : abandonner une piste et réorganiser le plateau ;
- **détection des impasses** : reconnaître une configuration sans issue ;
- **précision décisionnelle** : limiter les transformations et placements inutiles ;
- **persévérance** : corriger une hypothèse et poursuivre sans demander la solution.

La singularité recherchée est de décrire un style de résolution : rapide mais exploratoire, lent
mais précis, efficace en orientation, stable dans ses placements, ou habile pour sortir d'une
impasse.

## 4. Principes de mesure

1. **Comparer le joueur à lui-même.** Une évolution personnelle est prioritaire sur un classement.
2. **Comparer des situations comparables.** Temps, fautes et gestes sont séparés par taille/niveau.
3. **Montrer le volume d'observations.** Toute note est accompagnée du nombre de parties ou de poses.
4. **Ne pas inventer de précision.** En dessous d'un seuil, afficher « Observation en cours ».
5. **Séparer état et évolution.** Une aptitude actuelle et sa tendance sont deux informations.
6. **Exclure l'aide des notes d'habileté.** La lampe jaune automatise un placement et fausse la mesure.
7. **Garder les données locales par défaut.** Aucun bilan personnel ne nécessite un envoi au serveur.
8. **Expliquer chaque indicateur.** Un appui doit montrer sa définition et ses données brutes.
9. **Mesurer la vitesse indépendamment des erreurs.** La rapidité brute est une aptitude importante
   à part entière. Les impasses et corrections sont présentées à côté, mais ne corrigent pas le
   temps obtenu et ne sont pas fusionnées silencieusement avec lui.

## 5. État des données au 2026-09-29

### Déjà mesuré et conservé

- niveau Solo courant parmi les neuf tailles ;
- records par taille : meilleure acuité, moins de fautes et meilleur temps ;
- nombre de complétions par taille ou solution ;
- cumuls par pentomino : poses définitives, minimum théorique et isométries réelles ;
- partie courante : temps, isométries, translations, retraits, aides et fautes ;
- pendant la partie : classification et gravité des impasses, utilisées pour l'observation debug.
- vingt résumés de tentatives Solo par taille, terminées ou abandonnées ;
- pour chaque tentative : durée, aide, fautes, gestes, pièces posées et résultat du premier placement.

L'acuité par pièce n'est enregistrée qu'après une partie Solo terminée sans lampe jaune. Toutes les
isométries de la pièce sont comptées, dans le tiroir comme sur le plateau, entre les tentatives et
jusqu'à sa pose définitive.

### Non conservé aujourd'hui

- évolution chronologique de l'acuité par pièce ;
- nombre de gestes nécessaires pour sortir d'une impasse ;
- durée passée en impasse ;
- stabilité du premier placement de chaque pièce ;
- ordre de pose et chronologie détaillée des actions.

Conséquence : l'application peut présenter un **état actuel cumulé** et comparer la rapidité des dix
dernières réussites propres aux dix précédentes. Elle ne peut pas encore produire honnêtement une
courbe chronologique de l'acuité par pièce, de la stabilité ou de la récupération.

## 6. Bilan synthétique proposé

L'en-tête du profil pourrait présenter, après validation des règles :

| Indicateur | Exemple | Statut |
|---|---:|---|
| Niveau Solo | 4 / 9 | disponible |
| Acuité isométrique globale | 74 % | formule à harmoniser |
| Rapidité de résolution | 3 min 42 s sur cette taille | temps disponible, historique nécessaire |
| Autonomie | 82 % sans lampe | nécessite un dénominateur défini |
| Progression récente | +5 points | nécessite un historique |
| Expérience mesurée | 38 parties propres | nécessite un historique ou un cumul dédié |

Une synthèse textuelle doit compléter les chiffres : un **point fort actuel**, un **axe de
progression** et, seulement si l'échantillon suffit, une **évolution récente**.

## 7. Catalogue des aptitudes candidates

### 7.1 Acuité isométrique

**Question :** le joueur atteint-il l'orientation finale avec peu de rotations et de symétries
inutiles ?

Par pièce, l'implémentation actuelle affiche un pourcentage entier :

```text
pourcentage = floor(min(théorique / réel, 1) × 100)
```

avec `réel == 0` traité à 100 % pour une pièce effectivement posée. La valeur est toujours tronquée
à l'entier inférieur : 99,99 % s'affiche donc 99 %. Les silhouettes sont classées
de la note la plus faible à la plus forte ; une pièce non observée reste sans note.

**Point à trancher avant une note globale :** le maillot d'acuité historique utilise
`(minIso + 1) / (isometryCount + 1)`, tandis que la nouvelle note par pièce utilise le rapport
direct avec un cas particulier à zéro. Ces deux conventions donnent des résultats différents,
notamment lorsque l'orientation initiale est déjà correcte. Une seule définition devra devenir la
référence du bilan.

À afficher par silhouette : note actuelle, tendance, poses observées, moyenne théorique et moyenne
réelle. Une tendance par pièce ne devrait apparaître qu'après au moins cinq poses dans chacune des
deux périodes comparées.

### 7.2 Perception des compositions isométriques

**Question :** le joueur perçoit-il qu'une orientation peut être atteinte par la composition de
plusieurs transformations élémentaires, et choisit-il un chemin court ?

Cette aptitude prolonge l'acuité isométrique : l'acuité compte les gestes excédentaires, tandis que
la perception des compositions s'intéresse spécialement aux orientations dont le chemin minimal
demande deux opérations.

Pentapol n'autorise aucune rotation d'angle libre : les rotations sont exclusivement les multiples
de π/2, soit `0`, `π/2`, `π` et `3π/2`, calculés modulo `2π`. Notons `R+` et `R-` les rotations d'un
quart de tour, `H` et `V` les symétries d'axes horizontal et vertical, et `I` l'identité. Les
relations utiles sont :

| Composition | Transformation résultante |
|---|---|
| `H` puis `V`, ou `V` puis `H` | rotation de π |
| `R+` puis `R+`, ou `R-` puis `R-` | rotation de π |
| trois `R+` | `R-`, soit une rotation de `3π/2` |
| trois `R-` | `R+`, soit une rotation de `π/2` |
| `R+` puis `R-` | identité |
| `H` puis `H`, ou `V` puis `V` | identité |
| quart de tour + `H` ou `V` | symétrie selon une diagonale, résultat sans bouton direct |
| `H`, puis `R+`, puis `H` | rotation `R-` |
| quatre quarts de tour dans le même sens | identité |

Dans le repère écran de Pentapol, les deux symétries diagonales s'obtiennent exactement ainsi :

| Axe diagonal résultant | Séquences équivalentes de deux boutons |
|---|---|
| haut-gauche vers bas-droite (`\`) | `H` puis rotation horaire ; rotation horaire puis `V` ; `V` puis rotation antihoraire ; rotation antihoraire puis `H` |
| haut-droite vers bas-gauche (`/`) | `V` puis rotation horaire ; rotation horaire puis `H` ; `H` puis rotation antihoraire ; rotation antihoraire puis `V` |

Par exemple, pour l'axe `\`, une symétrie horizontale échange d'abord le haut et le bas, puis la
rotation horaire transforme ce résultat en échange des coordonnées `x` et `y`. La transformation
est calculée autour de la pièce ; sa position sur le plateau n'entre pas dans cette identité.
L'ordre compte : `H` puis rotation horaire et rotation horaire puis `H` produisent les deux diagonales
opposées.

**Correction de l'exemple initial :** une symétrie horizontale suivie d'une symétrie verticale
produit une rotation de π, pas de π/2. Avec les deux seuls boutons `H` et `V`, on n'obtient jamais
une rotation de π/2 : leurs compositions restent dans `{I, H, V, rotation de π}`. Le quart de tour
est une transformation élémentaire de Pentapol. Une symétrie diagonale peut apparaître comme le
résultat d'un quart de tour composé avec `H` ou `V`, mais elle n'est pas proposée comme bouton.

Avec les quatre boutons de Pentapol, le graphe des transformations a un diamètre de 2 : toute
orientation est atteignable en au plus deux appuis. Plus de deux transformations ne sont jamais
nécessaires pour atteindre une orientation donnée ; elles traduisent une exploration, un retour en
arrière ou un changement de cible pendant la résolution.

Mesure candidate dans une partie :

```text
opportunité de composition = pose dont le minimum théorique vaut 2
composition directe = opportunité réalisée avec exactement 2 transformations
note de composition = compositions directes / opportunités × 1000
```

Cette mesure reste une **inférence** : le placement final n'était peut-être pas la cible envisagée
par le joueur au début de ses manipulations. Pour isoler réellement la perception, un exercice
court pourrait montrer une orientation de départ et une orientation cible, puis demander au joueur
de trouver la séquence. Le jeu Solo mesure plutôt une **efficacité sur les compositions** qu'une
perception pure.

Les symétries propres à certaines pièces doivent aussi être prises en compte : pour les pièces qui
ont moins de huit orientations (X, I, T, U, V, W et Z), plusieurs transformations abstraites peuvent
produire la même orientation visible. Le juge doit rester `minIsometriesToReach` appliqué à la pièce
concernée, et non une table abstraite de D4.

Les cumuls actuels ne permettent pas de calculer le taux proposé : il faudrait conserver, par pose,
si le minimum valait 2 et si le joueur l'a atteint en exactement deux transformations.

### 7.3 Stabilité de placement, candidate pour l'anticipation

**Question :** le premier placement valide reste-t-il en place jusqu'à la fin ?

Mesure candidate :

```text
stabilité = pièces jamais retirées, déplacées ou transformées après leur première pose
            / pièces finalement posées
```

Cette mesure est plus défendable que « nombre de coups », qui dépend aussi des habitudes gestuelles.
Elle nécessite cependant une instrumentation par pièce qui n'existe pas encore. Elle décrit une
stabilité de placement, pas à elle seule toute la capacité de planification.

### 7.4 Économie de placement

**Question :** combien d'actions de placement ont été nécessaires par rapport au chemin minimal ?

Une première définition candidate serait :

```text
actions de placement = premières poses + nouvelles poses après retrait + translations
minimum de placement = nombre de pièces finalement posées
efficacité = min(minimum de placement / actions de placement, 1) × 1000
```

Cette mesure doit rester distincte de l'acuité isométrique : tourner une pièce mesure la recherche
d'orientation, tandis que la poser, la déplacer ou la retirer mesure la recherche de position. La
définition doit être testée sur les gestes réels, notamment le déplacement direct d'une pièce déjà
posée et l'annulation d'un drag, afin de ne pas compter un artefact d'interface comme une hésitation.

Elle recoupe partiellement la stabilité du premier placement. Les deux indicateurs ne devraient pas
entrer ensemble dans une note globale avant d'avoir vérifié qu'ils apportent des informations
différentes.

### 7.5 Maîtrise des impasses

**Question :** le joueur conserve-t-il un plateau soluble ?

Les faits disponibles sont le nombre de transitions soluble vers insoluble et, en observation,
leur cause et leur gravité. Les premiers indicateurs devraient rester lisibles :

- part des parties terminées sans impasse ;
- nombre médian d'impasses, par taille ;
- répartition entre poches d'aire impossible et impossibilités subtiles ;
- évolution de ces valeurs sur des tailles identiques.

Une note sur 1000 ne doit pas être créée avant d'avoir observé la distribution réelle des fautes.
Un simple total favoriserait mécaniquement les petits plateaux.

#### Anticipation initiale : premier placement

Le tout premier placement mérite une observation spécifique : le plateau est encore vide et le
joueur dispose du maximum d'espace et d'information. Si ce placement fait immédiatement passer le
plateau de soluble à insoluble, il constitue une faute d'anticipation et doit être pénalisé, même si
la partie est ensuite abandonnée ou recommencée.

Le moteur actuel le pénalise déjà comme toute transition soluble vers insoluble : `faultCount` est
incrémenté une fois et le barème Géométrie applique sa pénalité, renforcée pour une aire non multiple
de 5. Le futur bilan ne doit pas ajouter une seconde faute au score de la partie ; il doit marquer
cette faute existante comme survenue au premier placement afin d'en tirer un indicateur personnel
et de la conserver même lorsque la tentative n'est pas terminée.

La pénalité porte sur **la position choisie**, pas sur la pièce choisie. Commencer par une pièce
difficile ou garder volontairement la pièce P pour la fin relève d'une stratégie ; seule la
conséquence effective du dépôt est évaluée. L'événement observé est le premier dépôt légal validé
sur le plateau vide. Une pièce simplement sélectionnée, tournée dans le tiroir ou présentée sans
être déposée ne compte pas.

Deux causes doivent rester distinguées :

- **impasse géométrique directe** : le placement crée au moins une composante vide dont l'aire
  n'est pas un multiple de 5 ; cette impossibilité est visible sans explorer les solutions ;
- **impasse subtile** : toutes les composantes vides ont une aire multiple de 5, mais aucune
  solution du tirage ne contient ce placement.

L'impasse géométrique directe doit être considérée comme la faute d'anticipation la plus nette. Une
impasse subtile peut également être pénalisée, mais elle doit rester identifiable séparément : elle
demande une anticipation combinatoire plus fine et ne doit pas être présentée au joueur comme une
simple poche mal dimensionnée.

Premiers indicateurs candidats, par taille de plateau :

```text
taux d'erreur initiale = premiers placements rendant le plateau insoluble
                        / parties ayant reçu un premier placement

anticipation initiale = (1 - taux d'erreur initiale) × 1000
```

La note sur 1000 reste provisoire jusqu'à observation des distributions. Les données brutes doivent
toujours être accessibles, par exemple « 2 premiers placements en impasse sur 18 parties ». Une
ventilation par silhouette peut révéler les pièces avec lesquelles le joueur engage mal ses
parties :

```text
erreur initiale de la pièce p = premiers placements de p causant une impasse
                               / parties où p a été placée en premier
```

Cette valeur par pièce exige un volume minimal affiché et ne mesure pas sa difficulté intrinsèque :
elle dépend des tirages, des positions tentées et des habitudes du joueur. Elle ne doit pas être
fusionnée avec l'acuité isométrique. Une orientation atteinte avec peu de transformations et un
placement qui condamne le plateau décrivent deux aptitudes différentes ; les cumuler dans les deux
notes créerait une double pénalité.

### 7.6 Capacité de récupération

**Question :** après une impasse, combien d'actions faut-il pour retrouver un plateau soluble ?

Mesures candidates : nombre médian de gestes rouge vers jaune, temps médian de récupération et
part des impasses résolues sans lampe. Elles demandent le début et la fin de chaque épisode rouge,
ainsi que les gestes effectués entre les deux. Les compteurs actuels ne suffisent pas.

### 7.7 Maîtrise temporelle

**Question :** à quelle vitesse le joueur remplit-il un puzzle ?

La rapidité de résolution est une aptitude autonome et importante. Elle mesure le temps écoulé
jusqu'au remplissage complet du plateau, quel que soit le nombre d'impasses, de déplacements, de
retraits ou d'isométries réalisés. Ces erreurs et manipulations restent analysées dans leurs propres
indicateurs, mais elles ne doivent ni ajouter une pénalité au temps ni être incorporées dans une
note de vitesse opaque.

Le temps doit être comparé uniquement :

- sur une même taille ;
- entre parties terminées ;
- à condition d'aide équivalente : les parties avec lampe jaune sont identifiées séparément, car
  l'aide réalise une partie du travail ;
- à partir du même événement de départ, actuellement la première pièce touchée.

Les restitutions prioritaires sont :

- évolution du temps médian entre deux périodes comparables ;
- régularité des temps.

Dans le bloc « Rapidité de résolution », seuls les écarts de tendance sont affichés. Le record, la
médiane et le nombre de parties observées n'y apparaissent pas. Le meilleur temps reste disponible
dans les records par taille ; médianes et volumes restent conservés ou calculés en interne pour
fiabiliser la tendance.

La médiane est préférable à la moyenne, car cette dernière est plus sensible à une interruption ou
à une partie atypique.
Le bilan peut dire « 14 % plus rapide que sur tes dix parties précédentes ». Les erreurs sont
affichées à proximité pour décrire le style de résolution, sans retirer cette progression de
rapidité : un joueur peut devenir plus rapide tout en devenant plus exploratoire. Une éventuelle
note de vitesse sur 1000 demandera d'abord une référence par taille ; elle ne doit pas être inventée
à partir d'un seuil arbitraire.

### 7.8 Autonomie

Deux notions doivent rester distinctes :

- **autonomie des réussites** : réussites sans lampe / réussites terminées ;
- **autonomie des tentatives** : réussites sans lampe / parties commencées.

La seconde est plus informative mais exige d'enregistrer les abandons. Tant que ceux-ci ne sont pas
mesurés, le libellé doit préciser « parmi les parties terminées ».

### 7.9 Régularité

**Question :** les performances sont-elles stables ou très variables ?

Après un historique suffisant, la régularité peut être décrite par l'écart entre les résultats
récents, toujours à taille égale. Une formulation simple (« résultats réguliers sur 8 parties »)
est préférable à une note opaque calculée sur l'écart-type.

## 8. Mesure de l'évolution

### Fenêtres proposées

- état récent : dix dernières parties propres et terminées d'une taille donnée ;
- référence : dix parties propres précédentes de la même taille ;
- tendance longue : trente dernières parties, uniquement si disponibles.

La comparaison produit une variation absolue, par exemple `684 → 742`, et une phrase. Les courbes
ne doivent pas relier des tailles différentes comme si leur difficulté était identique.

### Seuils provisoires à valider

- moins de 5 observations : « Observation en cours », aucune tendance ;
- 5 à 9 : valeur actuelle, confiance limitée ;
- 10 ou plus : tendance récente autorisée ;
- par pièce : au moins 5 poses dans chaque fenêtre comparée.

Les seuils sont des hypothèses ergonomiques. Ils devront être confrontés au rythme réel de jeu.

### Exemples de restitutions

- « Ton acuité isométrique passe de 684 à 742 sur cette taille. »
- « Ton temps médian passe de 5 min 08 s à 4 min 21 s, quelles que soient les erreurs commises. »
- « Tu conserves plus souvent ton premier placement : 7 pièces sur 10 récemment. »
- « Ton temps diminue, mais tes impasses augmentent : ta vitesse progresse au prix de la stabilité. »
- « Cette silhouette reste celle qui te demande le plus de transformations. »
- « Données encore insuffisantes pour mesurer une évolution. »

## 9. Historique local retenu

L'application conserve désormais les **20 dernières tentatives Solo de chaque taille** dans le JSON
`AppSettings`. Il n'y a donc ni nouvelle table Drift ni migration. Une tentative est enregistrée :

- à la victoire, avec le statut `terminée` ;
- lorsqu'une partie ayant reçu au moins une action significative est volontairement remplacée, avec
  le statut `abandonnée`.

Quitter momentanément l'écran, mettre l'app en arrière-plan ou la fermer ne clôt pas la tentative :
la partie courante reste reprenable. Training, Défis et multijoueur sont hors de cet historique Solo.

Chaque résumé contient : date de fin, taille, terminée/abandonnée, durée, aide, fautes, isométries,
translations, retraits, nombre de pièces posées, identité de la première pièce, résultat
soluble/insoluble de son placement, indication d'une pose par la lampe et cause de l'impasse
éventuelle. La rapidité ne retient que les tentatives terminées sans lampe ; l'anticipation et les
impasses peuvent exploiter aussi les abandons.

Les indicateurs de composition, de stabilité et de récupération nécessitent encore des compteurs
dédiés ou des résumés d'épisodes, pas obligatoirement le journal de chaque geste.

## 10. Indice global de maîtrise

Un **Indice de maîtrise Pentapol** sur 1000 peut rendre le bilan immédiatement lisible, mais il
agrège des dimensions hétérogènes et risque de masquer l'information utile. Il est donc proposé
comme piste de phase ultérieure, pas comme exigence initiale.

Pondération exploratoire précédemment envisagée :

| Dimension | Poids hypothétique |
|---|---:|
| Acuité isométrique | 35 % |
| Stabilité/anticipation | 25 % |
| Économie de placement | 20 % |
| Maîtrise des impasses | 10 % |
| Maîtrise temporelle | 10 % |

Objections sérieuses : poids arbitraires, normalisation différente selon la taille, double comptage
possible entre stabilité et économie, et pression indésirable liée au temps. Aucun indice global ne
devrait être publié avant une phase d'observation des distributions et une explication accessible de
son calcul. Cette ancienne pondération exploratoire ne traduit pas encore la décision de considérer
la rapidité comme une aptitude majeure ; elle devra donc être entièrement revue plutôt que corrigée
ponctuellement.

## 11. Parcours d'affichage proposé

Le profil pourrait être organisé sans multiplier les écrans :

1. **Synthèse** : niveau, rapidité par taille, expérience mesurée, autonomie et éventuelle tendance
   globale ;
2. **Aptitudes actuelles** : acuité, stabilité, impasses, récupération, temps et régularité ;
3. **Acuité isométrique par pièce** : silhouettes de la moins maîtrisée à la mieux maîtrisée ;
4. **Évolution** : période récente contre période précédente, filtrée par taille ;
5. **À travailler maintenant** : un seul conseil fondé sur l'indicateur le plus faible et fiable ;
6. **Détails** : données brutes, définition et volume d'observations.

Le bilan ne doit pas afficher douze notes sans hiérarchie. Le joueur doit d'abord comprendre la
conclusion, puis pouvoir vérifier les chiffres qui la fondent.

## 12. Phasage recommandé

### Phase 0 — fiabiliser les définitions

- choisir une formule unique d'acuité ;
- définir précisément partie propre, tentative, abandon et pose stable ;
- vérifier les compteurs sur des scénarios exécutés ;
- observer les distributions avant toute normalisation sur 1000.

### Phase 1 — bilan actuel avec les données existantes

- niveau Solo ;
- acuité cumulée par pièce avec volume d'observations ;
- records par taille ;
- explications des indicateurs ;
- aucune affirmation de progression chronologique.

### Phase 2 — historique et tendances

- historique local borné ;
- comparaison 10 parties récentes / 10 précédentes ;
- autonomie, temps médian et impasses par taille ;
- anticipation initiale, y compris pour les tentatives abandonnées après un premier placement ;
- point fort et axe de progression ;
- tendances par pièce quand l'échantillon est suffisant.

### Phase 3 — aptitudes enrichies

- stabilité du premier placement ;
- efficacité sur les compositions isométriques ;
- récupération après impasse ;
- régularité ;
- éventuel indice global, seulement après validation des pondérations.

## 13. Questions ouvertes

1. Le bilan doit-il inclure uniquement le Solo ou également les Défis, dans des séries séparées ?
2. Une partie abandonnée doit-elle compter dès le premier placement, après une durée minimale, ou
   seulement après un nombre minimal de pièces ?
3. Quelle formule d'acuité devient la référence : rapport direct ou formule lissée avec `+1` ?
4. Faut-il conserver 50, 100 ou davantage de tentatives locales ?
5. Le joueur peut-il effacer uniquement son bilan sans perdre ses réglages et sa progression ?
6. L'indice global apporte-t-il une lecture utile ou encourage-t-il une optimisation artificielle ?
7. Les conseils doivent-ils être purement descriptifs ou proposer un niveau et une pièce à exercer ?

## 14. Critères de réussite du futur bilan

Le bilan sera réussi si le joueur peut, en moins de trente secondes :

- nommer son point fort actuel ;
- identifier un axe de progression concret ;
- comprendre si la conclusion repose sur assez de parties ;
- voir une évolution sans confondre des tailles différentes ;
- retrouver la définition et les données brutes derrière chaque note ;
- comprendre que les conclusions concernent Pentapol et ne constituent pas un diagnostic général.
