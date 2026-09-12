# Journal — état et passations

> Fichier de coordination entre Claude Code (CLI) et Claude cowork.
> Protocole : `docs/MODUS_VIVENDI.md`.
>
> **§ÉTAT est réécrite à chaque passage. §PASSATIONS ne garde que les trois dernières.**
>
> ⚠️ **§DÉCISIONS a été supprimée le 2026-08-31.** Elle comptait 69 entrées et 112 renvois
> croisés — une comptabilité devenue plus coûteuse que ce qu'elle rapportait, et le point de
> collision entre agents (trois renumérotations en deux jours). Les décisions qui **engagent
> encore** sont devenues des règles dans `CLAUDE.md` §Invariants ; les autres sont de
> l'histoire, et l'histoire est dans `git log`.

---

## §ÉTAT — au 2026-09-12

### L'application

Un seul module de jeu, **Pentoscope** : tailles `size3x5`…`size10x5` (tirage d'un masque de
pièces parmi les solubles) plus `size6x10` (rectangle complet). **Toutes** les réponses
« solution » (compte décroissant, disponibilité, guide) sont désormais adossées à des tables
pré-calculées : `subset_counts.bin` (comptes), `solutions_corpus.bin` (corpus 5×n, 3,13 Mo) et
`solutions_6x10_normalisees.bin`. **Plus aucun solveur backtracking dans l'app livrée.** Plus le
**multijoueur**, qui réutilise son provider. Démarrage sur `HomeScreen` (écran d'accueil livré le
2026-09-02, voir plus bas), puis `PentoscopeGameScreen` sur le niveau courant. Plus de notion de
difficulté.

### Géométrie — barème paramétrable (2026-09-12, local)

Réglages → Réglage du barème : quatre paramètres, aperçu immédiat des pénalités,
sauvegarde et restauration des valeurs initiales. Formule `c × remplissage^p + supplément`
si une zone vide a une aire non multiple de 5 ; défauts 100 / 10 / 2 / 5. Nouveau solo :
Géométrie remplace Acuité au bilan ; Fautes devient Impasses ; Triche compte les appuis
acceptés sur la lampe jaune. Affichage conservé avec aide, sans double pénalité.
Les étoiles solo suivent Géométrie (3 sans impasse/aide ; 2 si ≥80 % sans aide ; 1 sinon).

Barème figé à chaque nouvelle partie, pénalités cumulées sans arrondi, snapshot persisté.
**Décision de Paul en cours de chantier : repartir de zéro à la mise à jour, sans conserver
ni convertir les anciennes données.** Schéma SQLite **11**, destructif. Correctif trouvé
au test : insertion explicite `id=0` dans CurrentGame ; DEFAULT 0 seul laissait SQLite
attribuer 1, invisible à la lecture. Le démarrage attend la suppression de l'ancienne ligne.

Toutes les parties solo de calibrage sont expérimentales et exclues des records. Les défis
et duels conservent leur contrat ; alignement des classements avec la Géométrie à décider
avant publication. Drapeau de compilation pour masquer la fenêtre et ignorer les paramètres
expérimentaux sur les nouvelles parties publiques. Aucune migration de données anciennes.
Référence complète : [Barème Géométrie](BAREME_GEOMETRIE.md).

**205/205 tests**, analyse **0 erreur / 0 avertissement / 106 infos**. Reprise sur vrai corpus,
reset SQLite, fenêtre et bilan FR/EN avec grands caractères en portrait/paysage vérifiés.
Deux tests passent aussi avec le drapeau public false. Réglage des coefficients par Paul
sur appareil ; documentation mise à jour, aucun commit/push.

### Accueil — vocabulaire des icônes et retours physiques (2026-09-12, local)

Paul demande de parler d’icônes plutôt que de flèches et de sentir physiquement les déplacements.
Trois consignes corrigées en FR/EN (rotation, miroir, nouvelle tentative), localisations régénérées.
`GuidedHome.enableHaptics` reçoit le réglage du jeu depuis `HomeScreen` : sélection/transformation
avec clic discret, prise avec impact léger, entrée dans la cible valide avec clic, pose acceptée
avec impact moyen. Aucun clic à chaque mouvement dans une même cible ; pas de confirmation
sur un dépôt refusé. `hapticFeedbackOnStart` désactivé : une seule source de vibration,
intégralement coupée lorsque le réglage est désactivé.

**188/188 tests**, analyse complète **0 erreur / 0 avertissement / 106 infos**. Deux tests de
gestes interceptent le canal système et contrôlent les événements en mode actif/inactif,
y compris refus et mouvement dans la cible. Ressenti à apprécier par Paul sur iPhone.
Documentation actualisée ; aucun commit/push effectué.

### Accueil — consignes agrandies et défilantes (2026-09-12, local)

Paul demande un message qui défile et une police plus grande dans l’entraînement d’entrée.
Consignes en gras, 22–28 pixels logiques selon la largeur, avec agrandissement système conservé.
Après le premier retour, Paul demande une vitesse accrue et un défilement continu.
`GuidedScrollingMessage` défile désormais à 72 pixels logiques/s (vitesse doublée), sans pause
et sans arrêt après un passage. Deux copies assurent un raccord continu, même pour une consigne
courte. Une nouvelle consigne remplace immédiatement la précédente et redémarre le mouvement.
Le texte reste fixe si le système réduit les animations ou active la navigation accessible ;
sémantique unique malgré les deux copies visuelles.

La hauteur maximale des consignes est réservée avec la nouvelle police ; le plateau ne change
pas de position pendant les messages. Le bandeau ne capture pas les gestes. Aucun texte ajouté
aux traductions, contenu EN/FR existant conservé. **186/186 tests** ; analyse complète **0 erreur /
0 avertissement / 106 infos**. Quatre tests du mouvement et des modes accessibles, parcours de
l’accueil et accès direct au jeu vérifiés avec les grands caractères. Documentation actualisée.
Ressenti du défilement à apprécier par Paul sur iPhone. Aucun commit/push effectué.

### Accueil — Jouer permanent en tête et bouton Training (2026-09-11, local)

À la demande de Paul, le bouton plein Jouer remplace l’icône personne au centre de l’en-tête :
accès direct au jeu dès l’ouverture, sans terminer le parcours. Training remplace « Un autre
entraînement » en fin de parcours, avec le même style `FilledButton`, et conserve le passage
au tirage suivant. Le doublon Jouer sous le plateau et le callback `GuidedHome.onPlay` sont retirés.
Le libellé Training est identique en EN/FR, via les ARB régénérés. Multijoueur/Défi à gauche,
Records/Réglages à droite ; le bouton central dispose d’une largeur réservée pour éviter
le chevauchement sur petit écran. La partie de progression en cours est réutilisée par Jouer.

**Vérifications : 182/182 tests**, analyse complète **0 erreur / 0 avertissement / 106 infos**.
Les 88 parcours contrôlent Training et le tirage suivant. Quatre tests d’accueil contrôlent
l’accès immédiat, la conservation de la partie/du chrono et les boutons sans chevauchement,
en FR/EN sur 320×568 et 874×402. Documentation actualisée. Aucun commit/push effectué.

### Paysage — isométries à gauche, actions générales en bas (2026-09-11, local)

Paul propose puis autorise l’échange des deux barres dans l’écran de jeu. Rotations et miroirs
occupent désormais la colonne gauche ; accueil, chrono, nouvelle partie, ampoule et compteur
occupent la rangée basse. Plateau au centre et rack à droite. Portrait et accueil guidé conservés.
Les commandes partagent leurs callbacks, leurs icônes et le grisage préventif avec le portrait.

La colonne réserve cinq emplacements : quatre transformations stables et une corbeille visible
sur sélection d’une pièce posée. Sa largeur et la hauteur des actions du bas restent fixes,
indépendamment de la sélection. Les icônes s’adaptent à la hauteur disponible. `_barMetrics`
retranche la nouvelle hauteur basse pour maintenir le rapport de taille rack/plateau.

**Vérifications : 178/178 tests**, analyse complète **0 erreur / 0 avertissement / 106 infos**.
Douze cas de disposition : formats 667×375, 874×402, 1366×1024 et portrait 390×844, chacun sur
3×5, 8×5 et 6×10, avec marges système simulées. Contrôle des emplacements, de l’absence de
débordement et du plateau fixe au repos, sur sélection rack et sur sélection plateau/corbeille.
Ressenti à comparer par Paul sur iPhone. Documentation actualisée ; aucun commit/push effectué.

### Suppression du mode entraînement séparé — 2026-09-11, modifications locales

Paul demande de retirer l’icône et le code du mode à une pièce sur 5×7 : les sept parcours
3×5 de l’accueil lui suffisent. Icône, générateur d’exercices, état `isTraining`, démarrage/
retour, bilan spécifique et branches de persistance retirés du provider et de l’écran de jeu.
Compteur `trainingExercisesDone` et son enregistrement supprimés : ancienne clé JSON ignorée,
aucune migration ni modification des tables. Six clés de traduction retirées en EN/FR,
localisations régénérées. Plan du mode et références documentaires devenues obsolètes retirés.

Les sept accueils, leur contour et leurs célébrations sont conservés. Les primitives communes
d’isométrie restent utilisées par le jeu et les scores. Le test combinatoire des distances
est conservé dans `test/isometry_distance_test.dart` ; seuls les trois tests propres au mode
supprimé disparaissent. Les tests de glissé paysage démarrent désormais une vraie partie et
isolent les écritures dans une base SQLite en mémoire, hors de l’horloge simulée des gestes.

**Vérifications : 166/166 tests**, dont les parcours de l’accueil, les célébrations et les
prises paysage sur iPhone/tablette simulés. Analyse complète **0 erreur / 0 avertissement /
106 informations**. Recherche des symboles de l’ancien mode : aucune référence active dans
`lib/` et `test/` (anciens headers historiques exceptés). Aucun commit/push effectué.

### Accueil — contour et célébrations, 2026-09-11, modifications locales

À la demande de Paul, contour du plateau aligné sur le jeu : gris foncé, largeur 3,
coins arrondis (16) et ombre. Le contour est superposé aux cases pour conserver exactement
les coordonnées de dépôt et la taille du plateau. Chaque pose acceptée déclenche une coche
rebondissante et des confettis pendant 850 ms ; plateau rempli : célébration de 1 400 ms.
L’effet ignore les gestes et ne déplace aucun élément ; les refus ne déclenchent rien.
Le réglage système de réduction des animations désactive l’effet, les encouragements restent.

**Vérifications : 169/169 tests**, dont les 88 parcours complets avec contrôle du contour,
du déclenchement et de la fin de l’effet, plus les gestes pendant la célébration et la réduction
des animations. Analyse complète : **0 erreur / 0 avertissement / 106 informations**.
Le ressenti de cette nouvelle célébration reste à apprécier par Paul sur iPhone.
Code, tests et documentation locaux, sans commit/push demandé pour cette modification.

### Accueil — sept entraînements 3×5, 2026-09-11, `5f910e9`

Paul apprécie le nouveau rack (« c’est bien »), puis demande des pièces non déjà orientées
et plusieurs entraînements à l’entrée. Les sept tirages existants de `home_tirages_data.dart`
sont maintenant jouables : PFU, PUN, PVL, PVU, PYU, TYL, VLN. Un tirage est choisi au montage
de l’accueil ; « Un autre entraînement » passe au suivant, sans répétition avant les sept.
L’ordre pédagogique privilégie deux rotations puis une pièce nécessitant un miroir. Chaque
orientation initiale est géométriquement différente de sa cible, y compris les pièces symétriques.
L’indication rotation/miroir s’adapte à l’orientation courante, pas au numéro d’étape.

Rack défilant horizontal/vertical, choix par numéro, quatre icônes `GameIcons` et opérations
`Pento`, encouragements EN/FR, pièces posées retirées du rack et dépôt assisté conservés.
Pas d’étapes affichées. Une sélection par tap ou maintien reste possible directement.
Emplacements dimensionnés pour les pièces longues dans toutes leurs orientations ; hauteur
réservée des consignes et bouton de fin adaptable aux petits écrans. État local, sans DB/records.
Le mode entraînement à une pièce 5×7 est supprimé ensuite, à la demande de Paul (voir ci-dessus).

**Vérifications** : **166/166 tests**, analyse complète **0 erreur / 0 avertissement /
106 informations** (incluant `tools/`). Sept contrôles géométriques + 88 parcours widget
(40 prises PFU et 48 autres parcours : six tirages × quatre formats × deux langues), contrôle
des refus et des quatre opérations, vérification du passage au tirage suivant, retour VLN→PFU.
**Paul valide cette version (« c’est OK ») le 2026-09-11**, après invitation à l’essayer sur iPhone.
Version enregistrée dans `5f910e9`, documentation dans `4b86ef5`.

### Chantiers terminés

> **Livraison du 2026-09-10** (à la demande « commit et push » de Paul) : les quatre chantiers
> ci-dessous, jusque-là « NON commité », sont désormais dans `72a16bf feat(accueil)` (avec l10n
> EN/FR, `guided_home_test.dart`, `rack_drag_landscape_test.dart` et `build_info` build
> `202609101839`). `AGENTS.md` — miroir Codex des règles — est commité à part dans `e3dbe61`.
> Suivi de livraison dans `68ecece` et `a3f2cd3`, base poussée sur `origin/main`.
> **Paul confirme « test OK » le 2026-09-10 sur iPhone : accueil guidé et dépôt assisté validés.**
> Les sept variantes et leur documentation sont maintenant dans `5f910e9` et `4b86ef5`.
> Référence fonctionnelle : [Accueil guidé](ACCUEIL_GUIDE.md).

- **Accueil guidé — prise libre et dépôt assisté (2026-09-10, `72a16bf`)** : Paul constate
  que le dépôt ne fonctionne qu’en saisissant un bout de la pièce. Le premier contrôle imposait
  l’alignement exact de la case saisie sur une case cible, malgré une miniature plus petite.
  Désormais, avec la bonne orientation, le doigt peut viser la zone de la silhouette, quelle que
  soit la case saisie ; la pièce se place exactement sur le modèle. Tolérance d’un quart de case
  autour de la zone, limitée au plateau. L’orientation incorrecte et le hors-plateau restent refusés.
  Changement limité à l’accueil guidé, règles du jeu normal conservées.
  Régression reproduite : les 8 parcours avec dépôt naturel au centre échouaient avant correction.
  Après : **40 parcours complets** (5 prises × 4 formats × 2 langues), **111/111 tests** au total,
  **analyse 0 erreur / 0 avertissement (61 infos)**. **Validé sur iPhone par Paul (« test OK »).**

- **Accueil guidé 3×5 (2026-09-10, `72a16bf`)** : la démo automatique est remplacée par un
  parcours participatif en trois étapes sur le pavage PFU existant : U à glisser, P à tourner,
  F à retourner. Seule la pièce courante est active, les suivantes sont visibles en atténué ;
  silhouette cible et consigne EN/FR, confirmation quand l’orientation correspond. La miniature
  reste visible et rouge hors de la cible, normale sur la cible. Validation de la forme et dépôt assisté sur la zone de la silhouette (voir correctif ci-dessus).
  Géométrie des transformations réutilisée depuis `Pento`, aucun solveur ajouté.
  État local dans `GuidedHome`, sans minuterie, score, base ni modification de la partie solo.
  Hub et accès direct Jouer conservés ; au terme du parcours : Jouer ou Recommencer.
  Hauteurs de texte mesurées pour les deux langues ; portrait/paysage iPhone et tablette vérifiés
  par tests widget. Après correction de la prise : **111/111 tests**, analyse **0 erreur / 0 avertissement (61 infos)**.
  **Ressenti et dépôt validés par Paul sur iPhone le 2026-09-10 (« test OK »).**

- **Glissé toujours visible (2026-09-10, `72a16bf`)** : à la demande de Paul, la miniature
  suit le doigt dès la prise ; hors plateau ou sur un placement interdit, sa couleur est conservée
  à 55 % d’opacité et sa silhouette reçoit un contour rouge avec sous-trait blanc. Sur une pose
  valide, aspect normal. Rendu partagé `PieceDragFeedback` pour rack et pièces posées, solo/duel.
  `dragOverBoardProvider` suit la présence du doigt séparément de l’aperçu de pose conservé au bord :
  sortir d’une zone valide rend bien le feedback rouge, sans effacer l’ancre utilisée au dépôt.
  Test de glissé étendu (prise, obstacle, sortie, rentrée, pose de la pièce 5) : **70/70 tests**.
  Analyse : **0 erreur / 0 avertissement, 61 infos**. **Validé par Paul** (« c’est OK »),
  avant sa demande de passer à l’accueil guidé.

- **Drag rack → ligne basse en paysage (2026-09-10, `72a16bf`)** : Paul signale que la pièce 5
  n’atteint pas la dernière ligne sur iPhone ; sur sa tablette, le geste fonctionne.
  `PentoscopeBoard.onMove` ré-ajoutait l’ancre locale du feedback uniquement en portrait. Le
  correctif reconstruit le doigt dans les deux orientations AVANT conversion des axes paysage.
  Test widget avec vrais rack tourné/drag/plateau : régression reproduite (ancre x=1 au lieu de 0),
  corrigée pour chaque orientation et chacune des cinq cases de prise de la pièce 5, formats
  iPhone et tablette simulés. **70/70 tests, analyse 0 erreur / 0 avertissement (61 infos).**
  Le test contrôle aussi la pose après relâchement. **Validé sur iPhone par Paul : la pièce 5
  atteint désormais la dernière ligne depuis le rack en paysage** (confirmation explicite).
  Le travail de disposition du bloc 5, présent dans `pentoscope_game_screen.dart`, est désormais
  commité lui aussi (dans `72a16bf`) ; cette correction ne modifiait pas ce fichier.

- **Grisage préventif (2026-09-10, `f1a8ad7`)** : les quatre transformations
  impossibles sont désactivées dans les barres solo et duel, portrait et paysage. Le paramètre
  `preview` utilise les règles réelles de validation/recentrage sans modifier l’état ni les compteurs.
  Test d’équivalence sur les douze pièces et leurs orientations, bords et obstacles, avec et sans
  recentrage ; absence de mutation contrôlée. **Analyse : 0 erreur / 0 avertissement (61 infos),
  68/68 tests réussis.** Les vignettes restent à faire ; la rangée réservée est livrée (voir ci-dessous).

- **Rangée permanente d’isométrie — bloc 5 (`72a16bf`)** : dans l’écran de jeu partagé
  solo, rangée de hauteur réservée au-dessus du rack en portrait et en bas
  en paysage dans la version du 2026-09-10. Révisé le 2026-09-11 : isométries à gauche et actions
  générales en bas en paysage (voir en tête). Ne pas étendre ce constat à l’écran de duel
  sans vérification de sa disposition.

- **Ergonomie du jeu (2026-09-10, PLAN_ERGONOMIE_ICONES blocs 2-3 + carte de fin)** — chrono `m:ss`,
  compteur de solutions désambiguïsé, bande debug débranchée (C9), invariant « plateau toujours légal »
  (CLAUDE.md §Inv. #7) ; rack agrandi (`rackCellRatio` live, défaut 0.46) à emplacement serré + fondu de
  bord, pastille unique par pièce posée (`showPieceNumbers`) ; carte de fin refondue (étoiles 1-3 +
  bouton infos, plus de « Résolu »/« Vision parfaite »). **Reste du plan** : décision 4 (noms/glyphes
  d'axe), bloc 4 (vignettes ; grisage livré). Bloc 5 livré ; les −11 % étaient une estimation
  du côté des cases sur une capture précise, pas une mesure universelle. Détail
  en §PASSATIONS 2026-09-10.
- **Suppression du mode classique** — −3197 lignes, module, widgets, écran d'accueil.
- **Le 6×10 dans Pentoscope** — temps 1 et 2, `SolutionSource`, compteur de solutions.
- **Bilan de fin de partie** — bandeau non modal, score retiré, chronomètre corrigé.
- **Ergonomie hors plateau** — tailles ancrées sur le plateau, barre d'actions unique pour les
  deux orientations, ordre des zones aligné, écran de réglages minimal.
- **Persistance, étape 1** — Supabase, `bootstrap.dart` et `DatabaseDebugScreen` retirés.
- **Persistance (PLAN_PERSISTANCE, 4 étapes)** — **faite et committée** (`ea23af7`→`30e4fae`, tous
  ancêtres de `main` ; conservée par le revert du chantier déplacement car présente dans `1efda1a`).
  Une base drift, quatre tables (`Settings` inchangée, `CurrentGame`, `SolvedSolutions`,
  `PuzzleStats`), `schemaVersion` destructif. Records à la complétion via `solutionIndexOf`
  (`null`→`PuzzleStats`, entier→`SolvedSolutions`). Partie en cours : écriture aux poses/retraits +
  au passage en arrière-plan (`main.dart` observe `paused`), effacement à la complétion/partie neuve,
  `restoreGame` au lancement. `SharedPreferences`/Supabase retirés. **Le §ÉTAT précédent la disait à
  tort « reste à faire » — l'état « complète » (`30e4fae`) avait été perdu dans les réécritures du
  journal pendant la saga du revert.** Correctif `isProgression` du 2026-09-04 ci-dessous. **Reste :
  confirmation device de la reprise** à recueillir séparément. L'écran de lecture des
  records est désormais livré (voir ci-dessous).
- **Records perso (CDC §4, V1)** — les **trois maillots** (acuité **plafonnée** / **fautes** /
  temps, refonte « A » du 2026-09-05 — voir plus bas). Calcul (`completion_metrics.dart`, testé),
  rack initial capturé/persisté, bilan de fin, schéma à trois bests indépendants (partie avec aide
  comptée mais hors record, §4.8), **écran de lecture** (`records_screen.dart`, bouton trophée de
  l'accueil) et **médaille « vision parfaite » §4.6** (acuité 100 % : badge au bilan, icône sur
  l'écran de records). Détail en §ÉTAT « Records perso ».
- **Refonte « A » des maillots (2026-09-05, choix de Paul)** — retour à **trois** maillots après
  l'épisode « 4e maillot blanc » du 2026-09-04. L'acuité est **plafonnée à 100 %** (elle dépassait
  quand l'ampoule plaçait une pièce sans coûter d'isométrie), et les maillots **Coups** et **Help
  (blanc)** fusionnent en **🔴 À pois — Fautes** = nombre de transitions soluble→insoluble
  (culs-de-sac), mathématiquement égal aux anciens sauvetages. `helpCount`→`faultCount`,
  `bestMoves`+`bestHelp`→`bestFaults` (schéma drift **10**, réécriture destructive), `Maillot` à
  trois cas, serveur `scores.faults` (**redéployé + D1 réinitialisée le 2026-09-05** — voir §ÉTAT défi).
  Bilan d'une **partie avec aide** (`hintCount>0`) : pas de maillots, message « Résolu avec N
  aide(s) » + temps. Docs : `MANUEL_DEFIS_ET_MAILLOTS.md` (réécrit, fait foi), CDC §4.1 (amendé).
- **Phase 0 du défi hebdo (prérequis V1)** — PRNG du dépôt (`PentapolRng`, testé) et pause du
  chronomètre en arrière-plan (solo). Détail en §ÉTAT « Phase 0 ».
- **Suppression de la difficulté puis tirages précalculés (étape A)** — `subset_counts.bin`
  (4096 × uint16, 8 Ko) donne le nombre de solutions de tout tirage 5×n ; le générateur tire un
  masque parmi les solubles (plus d'appel-boucle au solveur, plus de difficulté), le compte est
  affiché au dialogue avec « autre tirage ». Table validée contre `REFERENCE_TIRAGES.md` §2.
- **Tirages précalculés (étape B)** — corpus complet `solutions_corpus.bin` (3,13 Mo, octet/case,
  73 876 solutions 5×n) ; `CorpusSolutionSource` adosse **toutes** les tailles à une table,
  appariement d'octets sans allocation (`common/byte_matching.dart`), compteur décroissant partout,
  et **`PentoscopeSolver` supprimé du dépôt** (les outils réimplémentent l'énumération Flutter-free
  — inutile de le garder dans `tools/`). Motivé par la mesure n°2 : le pire `_solutionStatus`
  (38–78 ms) venait du solveur live, pas du comptage par table (~0,6 ms). Choix : **2 sources
  table-backed** (6×10 via `SolutionMatcher`/BigInt pour son navigateur ; 5×n via corpus/bytes).

Leurs plans ont été **supprimés** une fois appliqués et testés (`MODUS_VIVENDI` §5).

- **Bilinguisme EN/FR (i18n, 2026-09-06)** — l'app était **française en dur** ; `lib/l10n/` ne contenait
  que 4 clés jamais câblées. Désormais : `flutter_localizations` + `generate: true`, `l10n.yaml`,
  délégués et `supportedLocales: [en, fr]` dans le `MaterialApp` (`main.dart`), **locale résolue depuis
  `AppSettings.localeCode`** (nouveau champ JSON, `null` = suit l'appareil ; pas de migration, invariant #6)
  et **sélecteur `Système / Français / English`** dans les Réglages (`setLocale`). **~90 clés** (dont
  pluriels et placeholders) dans `app_en.arb` (template) / `app_fr.arb` ; **toutes les chaînes visibles**
  des 13 écrans/widgets passent par `AppLocalizations` (accueil, jeu solo, bilan/maillots, records,
  réglages, couleurs perso, navigateur de solutions, défi, classement, **et** duel/multijoueur — choix
  de Paul « tout d'un coup »). Restent **littéraux** par choix : `PENTAPOL` (logo), `Pentoscope
  Multiplayer` (nom), `Go`/`DNF`/`GO!` (abréviations), le SnackBar de debug « test DB » du lobby, et les
  libellés `DuelDuration` (« 1 min »… numériques ; « Perso » n'apparaît jamais à l'écran). `analyze lib
  test` **0 error/0 warning** (61 infos, toutes préexistantes), **49/49 tests**. **Fichiers générés
  `lib/l10n/app_localizations*.dart` désormais versionnés**, notamment avec le parcours guidé EN/FR. **Reste : test device** (langue système + bascule
  manuelle) par Paul.

### Chantiers ouverts

**Accueil interactif 3×5** : première version livrée dans `72a16bf` et validée par Paul ;
révision du 2026-09-11 (rack, sélection, commandes du jeu et sept variantes) validée par Paul (« c’est OK »).
L’explication du compteur de solutions et des aides reste un sujet distinct (checklist n°8).
**Ergonomie restante** : vignettes de résultat et clarification des axes des miroirs,
voir `PLAN_ERGONOMIE_ICONES.md`.

| chantier | document | reste à faire |
|---|---|---|
| **Défi de la semaine + classement en ligne** | `CAHIER_DES_CHARGES_V1.md` §7 | ⚠️ **EN V1 (décision de Paul du 2026-09-07, révise le « hors V1 » du 2026-09-03)** — rendu conforme : envoi de score **désactivé par défaut** (opt-in explicite), consultation du classement conditionnée à l'opt-in (§4.5), **suppression des données** (RGPD §7.4). Détail en §ÉTAT « Conformité défi V1 ». **Phases 0-3 faites** : PRNG (0), dérivation `challenge.dart` (1), mode défi jouable local (2), **identité 128 bits** `AppSettings.playerId` + `generatePlayerId`/`ensurePlayerId` (3). **Phase 4 DÉPLOYÉE** (worker en ligne `https://pentapol-defi.pentapml.workers.dev`, D1 + `SEED_TOKEN` posés, round-trip validé au curl : POST 201, essai unique 409, leaderboard trié). **Client** : `challenge_api.dart` (POST score / GET tableau, échec silencieux §7.8) + **soumission auto à la complétion d'un défi** (`_submitChallengeScore`, `_activeChallenge`). **Phases 0-5 + extras faites** : `LeaderboardScreen` (**3 onglets** depuis la refonte « A »), accès **par l'icône classement d'une taille (ChallengeScreen)** ET **par un bouton « Voir le classement » au bilan d'un défi**. Fetch `GET /challenge` (composition à la main côté client, repli dérivation), et **semeur** `tools/seed_challenges.dart` (dérive + POST avec `SEED_TOKEN`, auto-contrôle du digest gelé). **Le défi est complet de bout en bout.** **Refonte « A » (2026-09-05) : le serveur `scores` porte `faults` au lieu de `moves`/`help` — worker REDÉPLOYÉ (`Version ID a459eb84…`) et D1 RÉINITIALISÉE le 2026-09-05 (DROP `scores` puis `schema.sql` ; `challenges` intacte ; round-trip revalidé au curl : POST 201, doublon 409, leaderboard renvoie `faults`).** Reste : composer/semer les vraies semaines (geste de Paul) |
| **Mise sur l'App Store** | `CHECKLIST_APPSTORE.md` | bloquants technique/produit/conformité — s'allonge au fil du travail. **Bloquant 21 (bundle id) réglé côté code le 2026-09-08** : `com.example.pentapol` → **`com.pml.pentapol`** sur iOS ET Android ; reste l'enregistrement de l'App ID dans les consoles (hors dépôt). Migration iOS **SPM + min iOS 15** committée le même jour. |

**Suite proposée** : terminer les vignettes et les axes du plan d’ergonomie, puis reprendre
les points ouverts de la checklist de publication. La reprise après fermeture, le cycle de vie
ont leurs validations propres : le « test OK » de l’accueil ne les solde pas. Médaille et défi sont déjà implémentés ; le défi est dans la V1.

### Réglage « compteurs » et accueil hub (2026-09-09)

- Réglage « compteurs » : isométries et fautes affichables en overlay dans le jeu.
- Accueil : bouton plein Jouer au centre, Multijoueur/Défi à gauche et Records/Réglages à droite.
  Il remplace l’icône personne depuis le 2026-09-11 ; l’icône Entraînement séparée a été retirée.
- Ancien mode à une pièce supprimé le 2026-09-11 ; son historique et son plan restent dans git.

### Corrections documentaires (2026-09-08, ancien plan d’entraînement §8)

Cinq des six corrections du §8 appliquées ; la sixième **rejetée car son postulat était faux**
(règle n°7, vérifié au `ls`/`grep`) :

- **`CHECKLIST_APPSTORE.md`** : points **1** (`flutter test` rouge — `widget_test.dart` n'existe
  plus) et **2** (`supabase_flutter` — absent, `bootstrap.dart` supprimé) **retirés** (note datée).
  Point **7** reformulé en **point de contrôle de soumission** (`update_version.sh` n'écrit que
  `build_info.dart`, volontairement ; `pubspec.yaml` renseigné à la main — pas une divergence).
  Bloquant **9** : tables 5×12/4×15 **abandonnées** (format téléphone), remède reporté sur la
  `ListSolutionSource` du point 10. En-tête : **Android dans le périmètre** (Play Console, keystore,
  métadonnées EN/FR ×2 stores).
- **`CLAUDE.md`** : « Plateforme cible : iOS » → **iOS + Android** (ne pas supprimer `android/`).
- **⚠️ §8 point 3 NON appliqué** : le plan disait `bigint_plateau`, `shape_recognizer` et
  `ui_layout_provider` « supprimés » — **c'est faux**, les trois existent toujours et sont suivis
  par git (aucun importateur). Le §4 du checklist était donc **déjà exact** ; j'y ai ajouté une note
  datée. `ui_layout_provider` est de plus **entrelacé** avec `ui_layout_manager`→`ui_dimensions` :
  leur retrait est un **chantier de code** (à décider avec Paul), pas une correction documentaire.
  `bigint_plateau`/`shape_recognizer` sont autonomes (zéro import) → suppression sûre si voulue.
- **Suite (2026-09-09, décision de Paul)** : `bigint_plateau.dart` et `shape_recognizer.dart`
  **supprimés** (`git rm`, zéro importateur). `analyze` 0/0, 59/59 tests inchangés. Reste le seul
  `ui_layout_provider` (cluster entrelacé). *(Verrou git `index.lock` périmé de la veille retiré au
  passage — aucun processus git actif.)*

### Centralisation des règles de score (2026-09-09, décision de Paul)

Les **calculs de score côté Dart** sont désormais isolés, testables et **réellement réutilisés** par
leurs consommateurs, à **résultats identiques** (prouvé par tests) et **sans toucher à la manipulation
des pièces**. Le socle métrique (`computeMetrics`/`CompletionMetrics`) était déjà central et partagé
(records + défi) ; ce qui restait dispersé, c'était la **règle d'acuité**, recopiée en **quatre** endroits.

- **Nouveau module pur, sans dépendance** `lib/pentoscope/score_rules.dart` (importable par la couche
  drift, l'API, les écrans) : `acuityRatio` (plafonné 1.0), `acuityPercent` (entier plafonné),
  `isBetterAcuity` (produit croisé sans flottant), `isPerfectVision`. Une seule définition de chaque règle.
- **Consommateurs routés** : `completion_metrics.dart` (`acuity`/`acuityPercent`/`perfectVision`
  délèguent), `pentoscope_game_screen.dart` (bilan lit `m.acuityPercent`), `records_screen.dart`
  (`acuityPercent`, agrégation 6×10, `hasPerfectVision`), `settings_database.dart` (`_isBetterAcuity`
  **retiré**, deux sites → `isBetterAcuity`), `challenge_api.dart` (`LeaderboardEntry.acuityPercent`).
- **Plafond partout (décision de Paul, 2026-09-09)** : `records_screen.acuityPercent` était **non
  plafonné**, il l'est maintenant. **Aucun effet visible** : les records ne stockent que les parties
  **propres** (`isoCount ≥ minIso` → ratio ≤ 1) — prouvé par un test d'équivalence sur ce domaine.
- **Code mort supprimé** : `PentoscopeNotifier.calculateNote()` (note 0-20 sur les indices), **zéro
  appelant** (public → invisible à `analyze`, famille des « membres publics morts » de CHECKLIST §4).
- **Tests** `test/score_rules_test.dart` : plafond, équivalence exhaustive de `isBetterAcuity` avec
  l'ancien `_isBetterAcuity` (grille 9⁴), et de `acuityPercent` avec les anciennes formules (API
  plafonnée partout ; records non plafonné sur le domaine propre). `completion_metrics_test` et
  `records_db_test` protègent les comportements existants.

`flutter analyze lib test` **0 error / 0 warning** (62 infos préexistantes), **67/67 tests**. Aucune
ligne de la manipulation des pièces (drag/rotation/pose) touchée. **Incohérence latente laissée
telle quelle** (à décider si besoin) : `isBetterAcuity` compare des ratios **non** plafonnés (ordre
total) alors que l'affichage est plafonné — sans conséquence tant que les records sont propres.

### Conformité défi V1 (2026-09-07) — opt-in + suppression (décision de Paul)

**Décision de Paul (2026-09-07), déclenchée par `INDEX_DOCS.md` §3.1 de cowork** : le défi en ligne
**reste dans la V1** (révise le « hors V1 » du 2026-09-03). Or le code envoyait `playerId` + pseudo
+ grille **sans condition** à la complétion d'un défi, alors que la déclaration App Privacy visée
(« ne collecte rien ») supposait le défi hors V1. Rendu conforme sans couper le défi :

- **Opt-in, désactivé par défaut** (CDC §8). `AppSettings.shareScoresOptIn` (bool, défaut `false`,
  JSON sans migration, invariant #6). `_submitChallengeScore` **ne fait rien** sans opt-in → **aucun
  `playerId` n'est généré** par défaut (`ensurePlayerId` n'est appelé que sous opt-in) : « ne collecte
  rien » redevient vrai pour une install par défaut.
- **Consultation du classement conditionnée** (CDC §4.5). Les deux accès (icône classement d'une
  taille dans `ChallengeScreen` ; « Voir le classement » au bilan d'un défi) passent par
  `openLeaderboardWithConsent` (`challenge_consent.dart`) : sans opt-in, un **dialogue de
  consentement** explique ce qui est envoyé et propose Activer / Plus tard. Refus → rien ne s'ouvre.
  Depuis le bilan, l'activation soumet le défi qu'on vient de terminer (`submitAfterOptIn`).
- **Proposition à la 1re complétion d'un défi** (choix de Paul, 2026-09-07) : à la fin d'un défi, si
  l'opt-in n'est pas donné, un dialogue le propose — **une seule fois** (drapeau
  `challengeConsentAsked`, JSON sans migration), après l'éventuelle saisie du nom. Refus → ne
  redemande plus automatiquement (activable ensuite via Réglages / classement).
  `maybeProposeConsentOnChallengeCompletion` dans `challenge_consent.dart`, appelé depuis
  `_onPuzzleCompleted`.
- **Interrupteur permanent** dans les Réglages (nouvelle section « Classement en ligne »).
- **Suppression RGPD** (CDC §7.4, exigence Apple en V1). Bouton « Supprimer mes données de
  classement » (Réglages) → `deleteOnlineIdentity()` : `DELETE /score?playerId=…` (efface toutes les
  lignes du joueur) puis efface le `playerId` local et coupe l'opt-in. Route serveur `DELETE /score`
  ajoutée (`server/src/index.ts`) — **à redéployer par Paul** avant que le nettoyage serveur soit
  effectif (le nettoyage local, lui, se fait toujours).
- **i18n** : ~12 clés (consentement, section réglages, suppression) dans `app_en.arb`/`app_fr.arb`,
  `gen-l10n` régénéré (invariant #8).
- **Docs** : `CHECKLIST_APPSTORE.md` points 12-14 réécrits (le défi est en V1, opt-in, suppression
  faite) + **nouveau bloquant 21** (bundle id `com.example.pentapol`) et note de divergence de
  version sur le point 7, tous deux signalés par `INDEX_DOCS.md` §3.2.

`flutter analyze lib test` **0 error / 0 warning** (61 infos préexistantes), **49/49 tests**,
`tsc --noEmit` (serveur) OK. **Reste : (1) redéploiement du worker par Paul** (route DELETE),
**(2) test device** (dialogue de consentement, bascule Réglages, suppression), **(3)** déclarer le
comportement opt-in dans App Store Connect (point 12).

### Taille des pièces et icônes (2026-09-07) — retour de Paul « réduction perturbante entre configs »

Gêne signalée par Paul : les pièces rétrécissent d'une config à l'autre (plus le plateau est grand,
plus la case — et donc la pièce de barre `= boardCell × k` — est petite). **Cause** : `cellSize =
min(W/w, H/h)` **sans borne haute** → les petits plateaux (3×5, 4×5) s'affichent démesurés et le
passage à un plus grand fait une « falaise ». Le rétrécissement des pièces **du plateau** est en
partie inévitable (géométrie : le 6×10 a 4× plus de cases), mais la falaise, elle, est corrigeable.
Direction retenue par Paul (Levier 1+3) :

- **Borne haute `kMaxBoardCellSize = 84.0`** (pt absolus, pas relatifs à l'appareil pour ne pas
  réintroduire une détection de tablette, §3) appliquée au `cellSize` du board **et** au `boardCell`
  de `_barMetrics` (cohérence §3). Effet iPhone : la case des niveaux 1-2 passe de 112/95 à 84.
- **`kPieceToBoardCellRatio` 0.22 → 0.26** : pièces de barre ~+18 % partout (le 6×10 reste préhensible).
- **Icônes d'isométrie** `isometryIconSize` facteur 0.12 → 0.14 (≈47→55 pt).
- **Icônes de l'AppBar** (`_uiIconSize`) : `_kIconSizeFactor` 0.075 → 0.11 et plancher 30 → 40 (elles
  étaient collées au plancher 30 sur iPhone → ≈43 pt) — « trop petites dans l'AppBar » (Paul).
- **Retrait de l'icône `Icons.person`** de l'AppBar (elle faisait `reset()` « recommencer ») — choix
  de Paul ; la remise à zéro reste dans « Nouvelle partie » (add_circle) et la carte de bilan.
- **Halo de sélection lisible sur pièce jaune** (`pentoscope_piece_slider.dart`) : le halo ambré seul
  ne contrastait pas sur la pièce N°3 (jaune) ; ajout d'un **contour sombre net par-dessus**, visible
  quelle que soit la couleur (palettes perso incluses).
- **Retrait de l'icône visionneuse** (`view_carousel`, navigateur de solutions, 6×10) — buggée (Paul).
  `compatibleSolutions()` (provider) et les clés i18n `compatibleSolutionsTitle/Tooltip` deviennent
  orphelines, laissées en place (comme `restartTooltip`).
- **Vignette d'accueil découplée du `k` de gameplay** (`home_screen.dart`, `_kHomePieceRatio = 0.20`) :
  la hausse de `k` (0.22→0.26) faisait se toucher les mini-pièces du rack de la démo (posées à des
  fractions égales de la largeur). La vignette étant décorative, elle garde son propre ratio.
- **🐞 DEBUG bandeau compteurs live** (`kShowLiveCounters = true`) : coin haut-gauche, `🔄 iso · 🔴
  fautes · ↔️ translations · 🚑 retraits-en-rouge` (`state.isometryCount`/`faultCount`/
  `translationCount`/`redRemovalCount`), pour le test device. **À repasser `false` avant soumission**
  — `CHECKLIST_APPSTORE` point 22. Pas `kDebugMode` (test en `--release`). *Décision de Paul
  (2026-09-07)* : ne PAS compter le tâtonnement en rouge (translation ni retrait) comme **faute** —
  ça casserait l'invariant fautes=culs-de-sac et doublonnerait avec le temps — mais **observer**
  d'abord les compteurs bruts. `translationCount` existait déjà ; `redRemovalCount` est neuf (retrait
  quand le plateau était rouge = sortie de cul-de-sac), **non persisté** (compteur d'observation).
- **🔎 Classifieur de fautes** (`lib/pentoscope/fault_analysis.dart`, pur, testé — `test/fault_analysis_test.dart`).
  À chaque faute (🟡→🔴), `analyzeFault(board)` classe la cause : **⚠️ aire non multiple de 5** (une zone
  vide dont la taille n'est pas multiple de 5 ; **englobe les poches < 5** — refonte du 2026-09-07 qui a
  supprimé `pocheTropPetite`) ou **🌫️ impossibilité subtile** (zones toutes multiples de 5, mais mort).
  **Gravité continue** = `kGraviteAireCoeff / taille` (défaut 20 → zone de 4 = 5.0, plus petite = plus
  grave), `kGraviteSubtile` (défaut 1.0) pour le subtil — coefficients **à régler à l'observation**.
  Câblé aux 4 sites de faute (pose/déplacement, retrait, rotation, symétrie) : `faultAireCount`,
  `faultSubtileCount`, `faultGraviteSum` (état, **non persistés**), affichés en **2ᵉ ligne** du bandeau
  debug (`⚠️ n · 🌫️ m · Σg X.X`). **Observation seulement** : n'entre PAS dans les maillots ; le barème
  et son éventuelle intégration se décideront sur données (avant lock de publication si classé).
  **Centralisation (2026-09-07)** : tous les indicateurs d'observation sont **définis, documentés et
  formatés dans `fault_analysis.dart`** — `FaultIndicators` (les deux lignes de compteurs) et
  `diagnosticCourant(...)` (3ᵉ ligne = **diagnostic de l'état courant**, recalculé à **chaque coup** :
  `✅ résolu` / `🟢 soluble` / `⚠️ zone (g)` / `🌫️ subtile`). Le bandeau (`_debugIndicatorsOverlay`) ne
  fait que les afficher ; l'accumulation reste dans `PentoscopeState`. L'analyse tourne donc bien à
  **chaque mouvement** (le bandeau se reconstruit à chaque changement d'état).

Toutes ces valeurs sont des **constantes nommées « à régler à l'œil sur device »**. `analyze lib test`
**0/0**, **49/49 tests**. **Reste : test device** (calage des valeurs par Paul).

### Déplacement d'une pièce — méthode « suivi exact du doigt » (2026-09-07, testée OK par Paul) ✅

> ⚠️ **Les deux sections ci-dessous (REVERT + cartographie des fourches) sont désormais HISTORIQUES.**
> Elles décrivaient l'ancien état ; le bug intermittent « la pièce ne suit pas toujours le doigt » a
> été repris et **corrigé** le 2026-09-07. Correction du §ÉTAT au passage : contrairement à ce que
> disaient ces sections, les correctifs de `snap-directionnel` **avaient bien été fusionnés dans
> `main`** (dépôt à l'ancre de l'aperçu, snap directionnel, `setDragMastercase`) — la branche a été
> supprimée depuis. Le bug **persistait malgré eux**, ce qui a motivé un changement de **méthode**.

**Méthode retenue (validée puis testée par Paul)** : **suivi exact du doigt, validité = couleur, aucune
aimantation.** La case empoignée reste sous le doigt à tout instant ; la pièce ne « saute » plus vers un
placement valide.

- **`updatePreview`** pose TOUJOURS à l'ancre désirée (`_calculateDesiredAnchorFromDrag`), sans snap ;
  `isPreviewValid` = appartenance à `validPlacements` (déjà calculé pièce exclue).
- **Suppression** de `_findClosestValidPlacement` et `_gestureAxis` (l'aimantation et l'heuristique
  d'axe, devenues inutiles) — fix **soustractif**.
- **Feedback sous le doigt réactif** (plateau + tiroir) : **image réelle si posable, transparent si
  chevauchement** (un `Consumer` sur `isPreviewValid`, se reconstruit à chaque coup). Le **fantôme du
  plateau** garde son vert/rouge.
- **Effet de bord corrigé le même jour** : le plafond de case était **absolu** (`kMaxBoardCellSize=84`)
  et **rapetissait tout sur tablette** (grand écran → tout rogné à 84). Rendu **proportionnel**
  (`kMaxBoardCellFactor=0.215`, `maxBoardCellSize(context)` = `shortestSide × facteur`) : ≈84 sur
  iPhone, plein écran sur tablette.

`analyze lib test` **0/0**, **55/55 tests**. **Testé OK sur tablette 9×5 par Paul** (le drag suit le
doigt, les plateaux remplissent l'écran). Valeurs `à régler à l'œil` : `kMaxBoardCellFactor`,
`kPieceToBoardCellRatio`. *(Les deux sections historiques ci-dessous peuvent être élaguées à la
prochaine passe.)*

- **Confinement de l'ancre (2026-09-08, testé OK par Paul, `44b9c04`)** — effet de bord du retrait de
  l'aimantation : une **grande pièce** (Paul : la N°8) glissée au ras d'un bord — surtout le **bas**,
  collé au rack — **débordait** hors du plateau → aperçu rouge, dépôt refusé, obligeant à poser
  ailleurs puis repositionner (« en 2 temps »). `_clampAnchorToBoard` borne l'ancre à
  `x ∈ [0, W−larg]`, `y ∈ [0, H−haut]` (boîte englobante de l'orientation courante), appliqué aux deux
  cas (rack + pièce posée déplacée). **Pas** un retour à l'aimantation vers un emplacement VALIDE : le
  suivi du doigt est inchangé à l'intérieur, les chevauchements restent rouges — la pièce ne peut plus
  sortir de la table. `analyze` 0/0, 55/55.

- **Pose de la ligne du bas — acceptation du dépôt au bord (2026-09-09, testé OK par Paul)** — le
  confinement corrigeait le débordement de l'aperçu, mais **pas l'acceptation du dépôt** : le plateau
  est ancré en bas (design #6) → sa ligne du bas est **collée** à la cible de drop du rack. Viser une
  case basse (surtout en empoignant une case basse de la pièce) faisait relâcher au ras/au-dessus du
  rack. Deux causes conjuguées : (1) `pentoscope_board.dart` `onLeave` **appelait `clearPreview()`**
  (contredisant son propre commentaire) → l'ancre `previewX/Y` était effacée dès que le doigt
  effleurait le rack ; (2) le rack (`_buildSliderWithDragTarget`) **rejetait** une pièce venue du rack
  (`onWillAccept → selectedPlacedPiece != null`) → au relâcher, **aucune** cible n'acceptait, geste
  perdu (« s'y reprendre à plusieurs fois »). Correctif, **câblage des drop-targets uniquement** (la
  géométrie de pose — `updatePreview`/`tryPlaceAtAnchor`/clamp — est **inchangée**) : (1) `onLeave` ne
  fait **plus** `clearPreview` (l'aperçu valide survit) ; (2) le rack accepte aussi une pièce **du
  rack** quand un aperçu valide est en attente (`selectedPiece != null && previewX/Y != null &&
  isPreviewValid`) et la **pose** via `tryPlaceAtAnchor` ; rouge/poubelle réservés au **retrait** d'une
  pièce déjà placée. `analyze` 0/0, 67/67. **Non couvert** (à traiter si rencontré) : *déplacer une
  pièce **déjà posée** vers la ligne du bas* retombe sur le même bord, mais là lâcher sur le rack =
  retrait volontaire.

- **Ligne du bas — CAUSE RACINE trouvée et corrigée (2026-09-09, testé OK par Paul).** Les correctifs
  ci-dessus (rack-coopération, marge) aidaient sans suffire : la pose du bas restait **aléatoire** sur
  un grand plateau (5×7). Diagnostic de Paul (« ça vient des mouvements du doigt ») + lecture du
  pipeline : le **feedback de drag est rendu à l'échelle du RACK** (petit, `≈0,26×case plateau`) et la
  `dragAnchorStrategy` l'ancre par la case empoignée → `details.offset = doigt − localGrab` (px rack).
  `onMove` mappait ce point **à l'échelle du plateau** sans ré-ajouter `localGrab` → l'ancre se
  décalait de **~0-1 case selon la ligne empoignée** (et la hauteur de la pièce), non rattrapable au
  bord bas. **Correctif** : le slider passe `localGrab` au provider (`selectPiece(grabLocal:)` →
  `dragGrabLocal`) et `onMove` **reconstruit le doigt réel** `details.offset + localGrab` → `ancre =
  caseDoigt − caseEmpoignée` (la case empoignée tombe exactement sous le doigt). **Portrait + pièce du
  rack seulement** (paysage = swap d'axes ; pièce posée = branche `masterAbs`, inchangés). `analyze`
  0/0, 67/67. **Testé OK par Paul.** C'est LA correction qui rend la ligne du bas fiable.

- **Marge latérale du plateau (2026-09-09, retour de Paul, testé OK).** Un grand plateau (5×n, 6×10)
  prenait toute la largeur (≈4 pt de marge) → avec le suivi 1:1, positionner près d'un bord amenait le
  doigt contre le biseau. `kBoardSideMargin = 26 pt/côté` (portrait) réservé au plateau **et** à
  `_barMetrics` (§3). N'affecte que les plateaux **limités par la largeur** (les petits, plafonnés par
  `maxCell`, gardent leur taille). Constante « à régler à l'œil ».

- **Sensibilité du drag (2026-09-09, retour de Paul).** `longPressDuration` défaut **200 → 100 ms** ;
  réglage Params borné **50-200** (pas de 50 ; setter clampé). *Une valeur déjà persistée sur l'appareil
  ne change pas seule — à réajuster une fois via les −/+.*

- **Orientation du rack conservée (2026-09-09, retour de Paul).** `cancelSelection` commit
  `selectedPositionIndex` dans `piecePositionIndices` pour une pièce du rack → un drag annulé (relâché
  hors cible) **garde** l'orientation donnée au lieu de revenir à l'initiale. (Cause : `_applyIsoUsingLookup`
  CAS 1 ne mettait à jour que `selectedPositionIndex` ; `cycleToNextOrientation`, qui committait, était mort.)

### Chantier « déplacement d'une pièce » — REVERT (2026-09-01)

Le chantier `PLAN_DEPLACEMENT_PIECE` (correctifs 1→5) a fait **apparaître beaucoup d'anomalies**
(déplacements aléatoires) au test de Paul. Décision de Paul : **revenir à l'état pré-chantier**.
La branche de travail a été **reset --hard sur `1efda1a`** (= tag `avant-deplacement-piece`), puis
l'ergonomie conservée (voir plus bas) **fusionnée dans `main`** (`b9bec37`, fast-forward) et
**poussée sur `origin`**. La branche `deplacement-piece`, devenue redondante, a été **supprimée**.
Tout le chantier ET l'instrumentation DRAGDIAG posée ensuite sont **écartés du tree** mais
**conservés intacts** sur `c5306b5` :

- branche **`backup/deplacement-piece-c5306b5`** — **poussée sur `origin`** (donc visible pour
  cowork sur un clone neuf ; ne PAS la fusionner, c'est une archive).
- tag **`chantier-deplacement-backup`** — **local à la machine du CLI** (non poussé).

On y retrouve : plan `PLAN_DEPLACEMENT_PIECE.md`, correctifs 1→5 (carte des sha dans le `git log`
du backup), `PLAN_DIAG_DRAG.md` et l'instrumentation `lib/common/drag_diag.dart` + points DRAGDIAG.
**Rien n'est perdu** — reprise possible par `git cherry-pick`/`checkout` depuis la branche de backup.

**Conservés par-dessus le pré-chantier** (indépendants du chantier, validés par Paul) : les deux
correctifs d'ergonomie du 2026-09-01 — (a) saisie du « I » (barre des pièces, `hitBoxSize` : toute
la boîte de la case répond au doigt ; halo de sélection collé à la pièce) et (b) sortie de l'écran
Paramètres sur iPad (bouton « Fermer » en bas + `SafeArea`, la flèche retour étant recouverte par
les commandes multitâche macOS « Designed for iPad sur Mac »). Reposés à la main sur la version
pré-chantier de `draggable_piece_widget.dart` (le fichier avait été touché par le correctif 1),
`slider`/`settings` repris tels quels. `analyze` 0 error.

### Déplacement d'une pièce — cartographie du bug intermittent (pour la reprise)

Analyse du code **actuel `main` (pré-chantier)** — le décalage horizontal intermittent au glissé
vertical **précède le chantier** et est donc toujours là. Séparé en faits / hypothèse / correctif.

**Faits — topologie.** 2 sinks `DragTarget` : le plateau (`pentoscope_board.dart:85`) et le tiroir
(`pentoscope_game_screen.dart:648`). 3 trajets réels : ① poser depuis le tiroir, ② déplacer une
pièce posée, ③ supprimer (glisser vers le tiroir).
- ③ **fait bande à part** sainement : sink tiroir, `removePlacedPiece`, aucune arithmétique de case.
- ① et ② partagent le **sink plateau**, mais le partage est trompeur — deux fourches :
  - **Fourche A, aperçu ≠ dépôt.** L'aperçu (`onMove`→`updatePreview`→`_findClosestValidPlacement`)
    **snappe** sur l'ancre valide la plus proche. Le dépôt (`onAccept`, board:162-173) **ne snappe
    pas** : il **reconstruit un faux doigt** = `previewX/Y + selectedCellInPiece`, puis
    `tryPlacePiece` **re-dérive** l'ancre via `_calculateDesiredAnchorFromDrag` et place en direct.
  - **Fourche B, mode A ≠ mode B** dans `_calculateDesiredAnchorFromDrag` (prov ~1720). Tiroir
    (mode A, `selectedPlacedPiece == null`) → branche `selectedCellInPiece`, et la reconstruction du
    dépôt (`+selectedCellInPiece`) en est **l'exact inverse** → boucle propre. Pièce posée (mode B,
    `selectedMasterAbs != null`) → branche **`masterAbs`**, formule différente ; or le dépôt ajoute
    `selectedCellInPiece`, **pas** `masterAbs` → **pas inverses**, coïncidence seulement si
    `masterAbs == sp.gridX + selectedCellInPiece` (vrai au décalage de normalisation près).
- Aggravant : `selectPlacedPiece` (prov ~563-571) cherche `selectedCellInPiece` en comparant
  `rawLocal` à des coords **non normalisées** alors que les cellules sont **normalisées** → si
  l'offset de forme ≠ 0, match raté et **fallback brut** `Point(rawLocalX, rawLocalY)`.
- **Fourche C, métrique du snap aveugle à la direction (piste de Paul, la plus probable pour le
  « ça monte »).** `_findClosestValidPlacement` retient l'ancre valide qui minimise
  `dx*dx + dy*dy` — **isotrope** (x et y pèsent pareil) et **sans plafond** sur `main` (le plafond
  ~1,5 case était le correctif 4 du chantier, reverté). Conséquence : si la case visée par le doigt
  est occupée, monter d'une ligne (`dy=1`, d²=1) **bat** continuer horizontalement de deux cases
  (`dx=2`, d²=4) → la pièce « saute vers le haut » pendant un glissé horizontal, et le saut n'est
  même pas borné. La métrique ignore **la direction du geste**.

**Hypothèse (à PROUVER par mesure, pas à affirmer).** Le décalage vit dans le **trajet ②** :
aperçu (snap) et dépôt (reconstruction + re-dérivation `masterAbs`) divergent, et
`selectedCellInPiece` bascule parfois sur son fallback brut selon **forme / orientation / case
saisie** → non systématique, biaisé d'une case dans un sens. Le **trajet ① (tiroir) boucle
proprement** → il devrait être nettement plus stable. **L'asymétrie ① vs ② est testable** — c'est
ce que DRAGDIAG (dans le backup) mesure : `fcol` aperçu vs `finalX` dépôt, `grabx/graby` A vs B.

**Correctif ① appliqué (2026-09-03, testé par Paul).** L'analyse « ① boucle proprement » était
incomplète : le tiroir ancrait le **feedback** sur la case empoignée mais le **placement** sur la
cellule PAR DÉFAUT (`_calculateDefaultCell`) — mismatch → « je n'arrive pas à poser sur une case
dispo depuis le tiroir » (rapport de Paul). Fix : `DraggablePieceWidget` capte l'offset du toucher
(`dragAnchorStrategy` → `onGrab`), le slider en déduit la cellule empoignée (`_grabbedCell`) et la
passe à `selectPiece(grabbedCell:)`. Le tiroir ancre désormais sur la case tenue, comme le plateau.
Correctif isolé, un commit, validé sur device.

**Correctif minimal proposé (isolé, mesurable, un seul changement de comportement).**
**Déposer directement à `previewX/previewY`** dans `onAccept` — l'aperçu contient déjà une ancre
snappée et validée — **au lieu** de reconstruire un faux doigt puis de re-dériver. Supprime la
fourche A d'un coup. Corriger en parallèle le raw-vs-normalisé de `selectPlacedPiece` (fourche B /
fallback). Ne PAS ré-empaqueter avec d'autres retouches (c'est ce qui a coulé le chantier) ; un
correctif = un commit, testé à l'écran par Paul, l'asymétrie ①/② servant d'oracle avant/après.

**Correctif A — snap conscient de l'axe du geste (en préparation, 2026-09-01).** Vise la fourche C.
**Objection posée puis intégrée** : le « A naïf » (ne garder que les candidats de même ligne)
créerait le **bug miroir** pour un glissé vertical (saut latéral) ; aucune métrique *statique* ne
distingue horizontal de vertical quand la géométrie est symétrique. Il faut donc **la direction
réelle du geste**. Implémentation retenue : suivre l'axe dominant du mouvement (case doigt
précédente → courante, dans `updatePreview`, via un champ transitoire `_dragAxis` remis à zéro à
chaque sélection/pose), puis dans `_findClosestValidPlacement` **départager lexicographiquement** —
axe horizontal : minimiser d'abord `|Δligne|` puis `|Δcolonne|` ; axe vertical : l'inverse ; axe
inconnu : isotrope (comportement d'avant). Pas de plafond réintroduit (hors périmètre). Livré sur la
branche **`snap-directionnel`** (hors `main` tant que non testé), en **2 commits** : (1)
instrumentation DRAGDIAG rebranchée (oracle avant/après, `drag_diag.dart` du backup + log
`event=snap` avec `axis`, snap encore isotrope) ; (2) le changement de métrique.
Oracle : `event=snap` doit montrer, après (2), un `chosen` qui **reste sur la ligne du doigt** en
glissé horizontal. Test à l'écran par Paul.

**Résultat (2026-09-02, test de Paul).** La version aboutie de la branche — snap directionnel +
dépôt à l'ancre de l'aperçu (fourche A supprimée) + **ancrage de la mastercase sur la cellule
empoignée** + puce diag `c0..c4` (`d93b584`) — **fonctionne mieux** : le déplacement d'une pièce
posée se comporte correctement à l'écran. Branche **poussée sur `origin/snap-directionnel`** pour
que cowork la voie. Pas encore fusionnée dans `main`.

**Instrumentation retirée (2026-09-02).** Le diagnostic ayant rempli son office, `kDragDiag`,
`dragDiag()` et tous les points DRAGDIAG ont été supprimés : fichier `lib/common/drag_diag.dart`
(`git rm`), blocs `event=grab`/`event=snap`/`event=drop`, helper `_diagCandidates`, et la puce
`c0..c4` de la barre d'isométrie (`_mastercaseLabel` + `_buildMastercaseChip`). **La logique du
correctif A est intacte** — `setDragMastercase`, `_gestureAxis`, snap directionnel, dépôt à l'ancre
de l'aperçu. `analyze` 0 erreur. La branche est **prête à fusionner dans `main`** sous réserve d'un
dernier tour de test de Paul. (L'archive DRAGDIAG reste disponible sur `backup/deplacement-piece-c5306b5`.)

### Revue UI (2026-09-02) — #6 (répartition verticale) et #3 (cul-de-sac réversible)

Revue d'UI menée sur **simulateur** (captures `simctl` ; le ressenti du geste n'est **pas** jugé —
réservé au test device de Paul). Deux corrections retenues par Paul, appliquées sur `main`.

- **#6 — plateau ancré bas en portrait.** Sur un plateau quasi-carré (5×5) la hauteur excède la
  largeur : le plateau « flottait », centré entre deux marges. `pentoscope_board.dart` : portrait
  `Alignment.center` → `Alignment.bottomCenter` (paysage inchangé, `topCenter`). **Piège rattrapé au
  contrôle visuel** : le positionnement visuel (`Align`) et le hit-test du drag
  (`offsetY = (maxHeight − gridHeight)/2`, centré en dur, l.90) étaient **découplés** ; déplacer le
  seul visuel aurait fait tomber les dépôts sur les mauvaises cases. `offsetY` est désormais **couplé
  à l'alignement** (portrait = bas, paysage = haut) — ce qui corrige au passage une incohérence
  latente du paysage (offset centré alors que l'Align est `topCenter`, sans effet tant que le paysage
  n'a pas de rab vertical). Vérifié à l'écran : haut du plateau 26 % → 39 %.

- **#3 — cul-de-sac réversible par l'ampoule.** Choix de Paul : **laisser poser** même quand le
  compteur est à 0 (le joueur peut croire, à tort ou à raison, que c'est jouable), et faire du
  **voyant rouge le bouton de retour**. `pentoscope_game_screen.dart` : la branche `else` (ampoule
  rouge, `!hasPossibleSolution`, jusqu'ici sans effet) appelle `removePlacedPiece(placedPieces.last)`
  — **un appui = un coup en arrière, répétable** ; `removePlacedPiece` recalcule `hasPossibleSolution`,
  donc le rouge s'éteint dès que le plateau redevient soluble. Icône inchangée (ampoule jaune =
  indice, rouge = retour). `deleteCount` s'incrémente mais **n'entre pas** dans `calculateNote`
  (basée sur `hintCount`) → aucune pénalité. **Non encore validé au test device** (comportement gestuel).

`analyze` 0 erreur / 0 warning sur les deux fichiers. **Autres constats de la revue non traités** (à
arbitrer) : barre d'icônes principale hétérogène, rouge sémantiquement surchargé (alerte / suppression
/ mastercase), hiérarchie de boutons ambiguë à l'entrée multijoueur, titre « Multiplayer » en anglais.

### Revue UI — suite (2026-09-02) : icônes d'isométrie + Route 2 (mini-plateau docké)

Deux ajouts, sur retour de Paul.

- **Icônes de la barre d'isométrie agrandies (portrait).** « Trop petites sur iPhone » — de fait
  `_uiIconSize` plafonne à 30 sur iPhone (côté court ≈ 393). Nouvelle fonction **partagée**
  `isometryIconSize(context)` (`config/game_icons_config.dart`) = `shortestSide × 0.12` borné [44, 84]
  ≈ 47 sur iPhone, utilisée par les barres d'isométrie **portrait** des DEUX écrans (solo
  `PentoscopeGameScreen` et duel `PentoscopeMpGameScreen`, jusqu'ici 30 et 42 en dur, indépendants).
  Paysage laissé tel quel (rails compacts, icônes à 20 alignées ; les élargir en permanence pour des
  boutons qui n'apparaissent qu'en manipulation serait un mauvais compromis — à faire si demandé).

- **Route 2 — « occuper le rab » avec le mini-plateau adverse (duel).** #6 libère une bande en haut
  en portrait ; on y **docke** le mini-plateau adverse au lieu de le laisser flotter/chevaucher le
  jeu. `pentoscope_mp_game_screen.dart` : `_opponentDockHeight` décide (portrait, œil actif, **1v1**,
  bande suffisante) et dimensionne le dock d'après la géométrie réelle du plateau — estimation
  **conservatrice** (hauteur de grille bornée par la largeur → on ne docke que si l'espace est franc,
  sinon **repli sur l'overlay flottant** existant). Le dock est le premier enfant de la Column
  portrait (dockH ≤ rab → plateau non rétréci) ; l'overlay flottant est supprimé dans ce cas (pas de
  double rendu). **Réservé au 1v1** (à 2-3 adversaires la bande peu profonde ne tient pas une rangée
  de minis lisibles → empilement à droite conservé). Vraies données adverses. **Non observable au
  simulateur seul** (duel 1v1 réel requis) → à valider sur device.

`analyze` 0 erreur / 0 warning. Découverte au passage : l'overlay adverse de `PentoscopeGameScreen`
(solo) est **dormant** (`_showOpponentOverlay` jamais mis à `true`) et **simulé** ; le vrai mini du
duel vit dans `PentoscopeMpGameScreen` et utilise des données réelles.

### Menu d'entrée = hub de navigation (2026-09-05, choix de Paul)

L'accueil devient le **hub** : sous « Jouer » (solo/progression), un **bouton « Multijoueur »** (→
lobby duel) ; l'en-tête garde **Défi 🚩 / Records 🏆 / Réglages ⚙️**. La **barre du jeu solo** est
**allégée** : bouton **« Accueil » 🏠** (retour au menu, `popUntil isFirst`), et **retrait** du
multijoueur (people) et des **Réglages** (déplacés sur l'accueil). Le joueur part toujours du menu,
choisit solo/multi, et revient au menu depuis le solo. `analyze` 0/0, 50/50.

### Anciennes démos d'accueil — remplacées le 2026-09-10

Les animations livrées les 2 et 5 septembre ont été remplacées par le parcours interactif
3×5. Leurs temporisations et constantes ne décrivent plus l'écran actuel. Le plan de la démo
passive est supprimé ; les données de pavage sont conservées. Voir `ACCUEIL_GUIDE.md`.

### Progression solo (niveaux) + nom du joueur (2026-09-02)

Nouveau : une **progression de niveaux solo**, sauvée, et la **saisie du nom du joueur**.

- **Niveaux = tailles.** `sizeForLevel(n)` (`pentoscope_generator.dart`) : niveau 1..9 → size3x5
  (3 pièces) … size6x10 (12 pièces). `kMaxLevel = 9`.
- **Persistance** (AppSettings, JSON, sans migration, invariant #6) : `currentLevel` (défaut 1) et
  `userName` (nom canonique). Setters `advanceLevel`, `setUserName`, plus `ensureLoaded` (attendre le
  chargement des réglages avant de lire currentLevel au démarrage).
- **Démarrage** : `main.dart` démarre sur `sizeForLevel(currentLevel)` (niveau 1 = 5×3),
  `isProgression:true`. L'accueil affiche « Niveau N » ; « Jouer » enchaîne sur le niveau courant
  (frais si l'actuel est terminé/d'un autre niveau, sinon reprend).
- **Complétion** : un puzzle de progression du niveau courant terminé → `advanceLevel` (via
  `ref.listen` dans l'écran de jeu). Le bilan propose alors **« Niveau suivant »** (remplace
  « Nouvelle partie »). Au **1er puzzle réussi** (userName vide) → dialogue de saisie du nom.
- **`PentoscopeState.isProgression`** distingue un puzzle de progression d'un puzzle du « + » (choix
  libre de taille) ou du multijoueur, qui ne font **pas** avancer le niveau.
- **Pseudo unique** : `userName` est LE nom, utilisé par le MP lobby (« Ton pseudo »), les Réglages
  (« Nom du joueur ») et le dialogue au 1er succès. `duel.playerName` reste dans le modèle mais n'est
  plus lu (vestige).

**Vérifié au simulateur** : accueil « Niveau 1 ». **À valider sur device** (résoudre un puzzle) :
Jouer→5×3 → solution → dialogue nom → niveau 2 sauvé + « Niveau suivant ». Cas limite assumé : une
partie **reprise** d'une session précédente est `isProgression=false` (la terminer n'avance pas le niveau).

### Persistance — correctif `isProgression` (2026-09-04)

Bug d'intégration trouvé en relisant le code (la progression a atterri **après** la persistance) :
`restoreGame` reconstruisait l'état **sans** poser `isProgression` → toute partie reprise retombait
sur le défaut `false`, et la table `CurrentGame` **ne stockait pas** ce champ. Conséquences sur une
partie de **progression** reprise : (1) le bouton « Jouer » (`home_screen.dart` `_play`, `needFresh =
… || !st.isProgression`) démarrait un puzzle **frais** et **effaçait** la partie reprise ; (2) même
atteinte, la terminer **n'avançait pas le niveau**. La reprise était donc silencieusement défaite
dans le flux principal.

**Correctif (un commit, pré-publication → destructif assumé, règle n°6).** Colonne
`CurrentGame.isProgression` (`boolean().withDefault(false)`), `schemaVersion` 4 → 5 ;
`saveCurrentGame` écrit `state.isProgression`, `restoreGame` le lit depuis `row.isProgression`.
`build_runner` régénéré, `flutter analyze lib/` **0 error / 0 warning** (56 infos préexistantes).
**À valider sur device** (PLAN_PERSISTANCE §8, base existante) : commencer un puzzle de progression,
poser des pièces, **tuer l'app**, relancer, « Jouer » → la partie reprend et sa complétion avance le
niveau. `settings_database.g.dart` est gitignoré : régénérer après `pull`.

### Phase 0 du défi de la semaine (2026-09-04) — PRNG du dépôt + pause du chrono

Deux prérequis posés (décision de Paul : les faire **en V1**, ils servent aussi les records perso).
Ils ouvrent les phases 1→5 du défi (spec `CDC §7`), mais **ne créent pas** encore le mode défi.

- **`PentapolRng` (`lib/common/pentapol_rng.dart`)** — PRNG déterministe (xorshift32), indépendant de
  `dart:math` dont `Random(seed)` n'est pas garanti stable entre versions du SDK (`CDC §7.3`, piège 2).
  Test de gel `test/pentapol_rng_test.dart` (goldens + reproductibilité + bornes) — le seul garde-fou
  contre une dérive involontaire des puzzles seedés. **Seul consommateur seedé actuel migré** : les
  orientations du duel (`startPuzzleFromSeed`, ex-`Random(seed)`). *Le `seed` de `generateFromSeed`
  reste mort — le masque du duel vient des `pieceIds` du serveur.* Conséquence assumée : les
  orientations du duel changent vs anciens builds, sans effet (les deux joueurs sont sur la même
  release ; rien de persisté n'en dépend).
- **Pause du chrono** — `pauseTimerForBackground` / `resumeTimerFromBackground` sur le provider,
  câblés dans l'observateur déjà présent de `main.dart` (`paused`/`resumed`). **Solo uniquement**
  (`!_isMultiplayer` ; en duel le serveur fait foi). Correction d'une imprécision de `CDC §7.7` :
  `stopTimer()` seul **ne met pas en pause** (`getElapsedSeconds` = `now − _startTime`, le temps court
  toujours) — on capture la valeur à `paused` et `restoreTimerOrigin(figé)` recale l'origine à
  `resumed`, sans compter l'arrière-plan.

`flutter analyze lib/` 0 error/warning, **22/22 tests** (7 PRNG + 15 existants). **À valider sur
device** : lancer une partie solo, la mettre en arrière-plan (ou passer un appel) 30 s, revenir — le
chrono n'a pas avancé du trou.

### Défi de la semaine — Phase 1 (2026-09-04) : dérivation hors ligne (HORS V1)

Deuxième brique du défi (après le PRNG de Phase 0). **Tout descend d'un entier** (`CDC §7.3`), rien
ne transite : `lib/pentoscope/challenge.dart` (pur, sans réseau) — `weeksSinceEpoch` (origine lundi
5 janvier 2026 **UTC**), `challengeSeed(version, semaine, taille)` (FNV-1a, dépôt), et
`deriveChallenge(week, size, solubleMasks)` → masque + rack (orientation par pièce, id croissant), via
`PentapolRng`. `kChallengeVersion` (dans la clé du classement), `kChallengeSizes` (six tailles, §7.2 :
6×10, 5×9, 5×10 écartés).

**Vérifié** : `_solubleByPopcount` du générateur est **trié par valeur croissante** (balayage
`for m in 0..4095`) → dérivation reproductible (§7.3 piège 3) ; `solubleMasksFor(size)` l'expose (ordre
figé, pour brancher le défi en Phase 2). **Test de gel** `test/challenge_test.dart` : digest des 60
premiers défis (6 tailles × semaines 0..9) + spot-check + invariants (masque soluble, orientations
valides, reproductibilité, semaines) — le garde-fou du §7.3 piège 5. **45/45 tests.**

**Phase 2 (2026-09-04) — mode défi jouable en local (mode classé).** `startChallenge(ChallengeDefinition)`
et `startWeeklyChallenge(size)` construisent le puzzle depuis le **masque + rack dérivés** (pas de
tirage aléatoire). Nouvel état `isRanked` : l'**appui sur l'ampoule est neutralisé** (§4.8 ; message ;
couleur/compteur conservés ; retrait via sélection+poubelle). Le défi est **éphémère** — non persisté
(garde `isRanked` dans `_saveCurrentGame`) et **n'efface pas** la partie de progression sauvegardée
(garde dans le clear). Écran `challenge_screen.dart` (choix parmi les 6 tailles, §7.2) + **bouton
drapeau** sur l'accueil. **Décision de Paul (2026-09-04)** : un défi **n'écrit PAS** dans les records
perso (`_saveCompletionRecord` skip si `isRanked`) — parties libres/progression restent purs, le
classement du défi viendra du serveur. Le bilan affiche quand même acuité/coups/temps.
`analyze lib/` 0 error/warning, 45/45 tests. **Reste Phases 3-5** (réseau) : identité 128 bits (§7.4),
serveur Worker+D1 (§7.5-7.6, recalcul serveur du `minIso`), UI des trois classements.

### Records perso — Phase A (2026-09-04) : calcul + capture du rack + bilan de fin

> ⚠️ **Détails « coups » (`bestMoves`, `pièces + 2·retraits`) SUPERSÉDÉS par la refonte « A »
> (2026-09-05)** : le maillot Coups est remplacé par **Fautes**. L'acuité et le rack initial
> ci-dessous restent valides (l'acuité est désormais **plafonnée à 100 %**). Voir §ÉTAT en tête.

Premier tiers du chantier §4 (les deux maillots recommandés : acuité complète + bilan de fin).

- **Socle de calcul** `lib/pentoscope/completion_metrics.dart` (+ `test/completion_metrics_test.dart`,
  7 tests) : `minIso = Σ minIsometriesToReach(rack, placement)`, `acuité = (minIso+1)/(iso+1)`,
  `coups = pièces + 2·retraits` (Q6 : `translationCount` exclu ; démonstration :
  `poses − retraits = pièces` à la complétion), temps. Vérifié que `rotationCW/symmetryH…` opèrent
  sur le **même espace d'index** que `positionIndex` — le maillot jaune est sain.
- **Rack initial** : `PentoscopeState.initialOrientations`, figé au démarrage
  (`Map.from(piecePositionIndices)`), **persisté** dans `CurrentGame.initialOrientations`
  (schéma **5→6**, destructif) et restauré → l'acuité survit à une reprise (`piecePositionIndices`
  mute quand le joueur tourne les pièces, pas ce champ).
- **Bilan de fin** (`pentoscope_game_screen.dart`) : le bandeau affiche les trois maillots — acuité %
  (jaune), coups brut (à pois), temps (vert) — détail (isométries, minimums) en tooltip. Remplace les
  compteurs bruts iso/translation/delete.
- **Bug corrigé au passage** : `computeCompletionMetrics` lisait le temps **vivant**
  (`getElapsedSeconds`), qui continue de croître après `stopTimer()` (l'origine n'est pas recalée) →
  le bilan aurait grandi à chaque rebuild. `elapsedSeconds` est désormais **figé dans l'état** aux deux
  sites de complétion (placement et indice) et le bilan le lit.

`analyze lib/` 0 error/warning. **À valider sur device** : terminer un puzzle, voir les trois maillots ;
le temps ne bouge plus une fois résolu.

**Phase B (2026-09-04) — enregistrement à trois bests indépendants (§4.1).** `SolvedSolutions` et
`PuzzleStats` portent désormais **trois bests nullables** : acuité (`bestAcuityMinIso` +
`bestAcuityIsoCount`, bruts §7.6), coups (`bestMoves`), temps (`bestTimeSeconds`) — schéma **6→7**.
`_saveCompletionRecord` passe les métriques et `clean = hintCount == 0` : **fini le `bestActions`
faux** (iso+translation+delete). Décision alignée §4.8 : **une partie avec aide compte** (timesSolved
/ completed) **mais ne pose aucun record** (l'indice place à l'optimum, gonflerait l'acuité). Chaque
best évolue **séparément** (comparaison d'acuité croisée sans flottant, `_isBetterAcuity`). Test
d'intégration base-mémoire `test/records_db_test.dart` (6 cas). **35/35 tests.**

**Phase C (2026-09-04) — écran de lecture.** `lib/pentoscope/screens/records_screen.dart` : une
carte par taille jouée, les trois maillots (acuité % / coups / temps, `—` si pas de best), lus depuis
`PuzzleStats` (pièces tirées) et **agrégés** depuis `SolvedSolutions` (6×10 : meilleure acuité, moins
de coups, meilleur temps parmi les solutions trouvées). Accès par un **bouton trophée** ajouté à
l'en-tête de l'accueil. État vide explicite tant qu'aucun record. **À valider sur
device** : terminer quelques puzzles (sans aide), ouvrir l'écran, vérifier les trois maillots.

**Médaille « vision parfaite » §4.6 (2026-09-04).** Acuité 100 % = `isometryCount == minIso` (aucun
geste de trop), **jamais** un seuil sur `minIso` brut (`minIso = 0` récompenserait le tirage).
`CompletionMetrics.perfectVision` (testé) ; badge « Vision parfaite » au bilan si `perfectVision &&
hintCount == 0` (partie sans aide) ; icône médaille sur l'écran de records pour les tailles au best
d'acuité 100 %. Chantier records perso **clos**. 38/38 tests.

### FIX minIso toujours à 0 (2026-09-04)

Bug signalé par Paul : le maillot jaune affichait `minimum 0` sur toute partie **relancée**. Cause :
`reset()` (« recommencer »/« Nouvelle partie ») construisait l'état avec `piecePositionIndices: {}` et
**sans** `initialOrientations` → rack de référence absent → `computeMetrics` faisait `rack == null →
continue` pour chaque pièce → minIso = 0. La partie initiale (via `startPuzzle`) marchait ; `reset()`
était le seul chemin de démarrage à ne pas capturer le rack. Correctif : `reset()` tire des orientations
**aléatoires** (comme `startPuzzle`) et fige `initialOrientations`. Effet de bord corrigé : après un
« recommencer », les pièces repartaient toutes à l'orientation 0 (plus facile, incohérent) ; désormais
tirage aléatoire comme la partie initiale. `analyze lib/` 0/0, 45/45.

### Bilan de fin — carte flottante (2026-09-04, choix de Paul)

Le bilan de fin **supersède le bandeau non-modal** (`PLAN_BILAN §2`) : c'est désormais une **carte
flottante non-modale** (`_BilanCard` dans `pentoscope_game_screen.dart`), centrée par-dessus le
plateau résolu, **fermable** (tap sur le plateau pour rouvrir) et **déplaçable au doigt** (poignée +
`_bilanOffset`, recentré au prochain bilan). Elle regroupe tout le bilan
lisiblement : titre, badge « Vision parfaite » éventuel, les trois maillots en **lignes libellées**
(acuité / coups / temps + détail), note d'aides, boutons Fermer / Nouvelle partie ou Niveau suivant.
Nettoyage demandé : à la complétion, le **chrono** et le **compteur de solutions** sont retirés de la
barre du haut, et le bandeau du bas disparaît (slider vide). **Pendant le jeu, rien ne change.**
`analyze lib/` 0 error/warning, 45/45 tests. Testé à l'écran par Paul.

### Compteur Help — maillot blanc (2026-09-04) — ⚠️ SUPERSÉDÉ par la refonte « A » (2026-09-05)

> Cette section décrit le 4e maillot blanc **tel qu'il a existé du 2026-09-04 au 2026-09-05**. La
> refonte « A » l'a **fusionné avec Coups** en un seul maillot 🔴 **Fautes** (`helpCount`→
> `faultCount`, `bestHelp`+`bestMoves`→`bestFaults`, schéma **10**). L'insight qui autorise la
> fusion : à la complétion, sauvetages (rouge→jaune) = fautes (jaune→rouge). Conservée pour la trace.

Implémenté (CDC §7 Acté 3-4). État `PentoscopeState.helpCount`, incrémenté à chaque **sauvetage
rouge→jaune** (`_bumpHelp` : lampe `false→true` après une action) aux **trois** sites qui peuvent
rétablir la solubilité — retrait (`removePlacedPiece`), déplacement (`tryPlaceAtAnchor`), rotation/
symétrie d'une pièce **posée** (`_applyIsoUsingLookup` CAS 2, `_applySymmetryAbs`). Poser une pièce
neuve ne peut jamais sortir d'un cul-de-sac (prouvé) → non compté là. Persisté `CurrentGame.helpCount`
(schéma **7→8**), exposé par `CompletionMetrics.rescues` (param `computeMetrics`, défaut 0, testé),
affiché au **bilan comme 4e maillot blanc** ⚪ (pastille bordée). Tourne aussi en défi (mode classé).
**4e colonne Help dans les records perso locaux (2026-09-04)** : `bestHelp` nullable dans
`SolvedSolutions`/`PuzzleStats` (schéma **8→9**), mis à jour comme les autres bests sur partie propre
(le moins de sauvetages = best) ; l'écran trophée affiche désormais **quatre maillots** (acuité/coups/
temps/Help), agrégation `bestHelp` pour le 6×10. Test `records_db_test` étendu. `analyze lib/` 0/0,
**48/48 tests**.

### Défi Phase 4 — serveur écrit, à déployer (2026-09-04)

`server/` (neuf, TypeScript/Cloudflare) : worker `src/index.ts`, `schema.sql` (D1), `wrangler.toml`,
`package.json`, `tsconfig.json`, `README.md`. **Modèle confiance** (décision Paul) : l'app mesure, le
joueur ne saisit rien → pas de triche via le jeu ; le seul vecteur (POST forgé hors app) est jugé
négligeable → **le serveur ne recalcule pas `minIso`**, il **stocke la grille** pour audit hors ligne.
Endpoints : `POST /score` (essai unique par clé primaire `(version,week,size,player_id)`, §7.1),
`GET /leaderboard?maillot=jaune|pois|vert|blanc`, `GET/POST /challenge` (définition composée à la main,
`POST` gardé par `SEED_TOKEN` pour éviter l'empoisonnement — **révise Acté 1bis** : l'amorçage n'est
plus ouvert au premier joueur mais réservé à un semeur de confiance, cf. `server/README.md`).
**Déployée par Paul le 2026-09-04** : worker en ligne `https://pentapol-defi.pentapml.workers.dev`,
base D1 + tables créées, `SEED_TOKEN` posé. Round-trip validé au curl (POST /score → 201, doublon →
409, GET /leaderboard trié). **Intégration client (2026-09-05)** : `lib/pentoscope/challenge_api.dart`
(client HTTP, échec silencieux §7.8, `submitScore`/`leaderboard`) et **soumission auto** — à la
complétion d'un défi (`isRanked`), le provider POST le score (`_submitChallengeScore` ; `_activeChallenge`
porte week/size ; grille sérialisée pour l'audit). `analyze lib/` 0/0, 50/50. **Reste Phase 5** : écran
des quatre classements (une vue, onglets/podiums, dégradation gracieuse), + fetch `GET /challenge`
(composition à la main côté client) + un script Dart de semage (dérive + POST avec le token). *Ligne de
test « Test » sur (v1, week0, size1) à purger par Paul si souhaité.*

### Documentation

`INDICATEURS_OBSERVATION.md` (neuf, 2026-09-07) — référence de **tous les indicateurs du bandeau debug**
(compteurs bruts 🔄🔴↔️🚑, classification des fautes ⚠️🌫️Σg + gravité, diagnostic courant). Outil de
test/observation, gated `kShowLiveCounters` (à couper avant publication). S'appuie sur `fault_analysis.dart`.

`MANUEL_DEFIS_ET_MAILLOTS.md` (neuf 2026-09-05, **réécrit le 2026-09-05** pour la refonte « A ») —
manuel de référence **faisant foi** : défi perso (records locaux) vs défi réseau (classement en
ligne), et le **mode de calcul exact des trois maillots** (acuité **plafonnée**, fautes, temps) + la
médaille + le bilan « avec aide ». Ancré sur l'implémentation et `CDC §4`/`§7`.

`CLOUDFLARE_CONFIG.md` (neuf, 2026-09-05) — mémo opérationnel de l'infra Cloudflare : les deux
workers (duel WebSocket *hors dépôt* ; défi `pentapol-defi` dans `server/`), la config exacte (URL,
base D1 `7ea667b1…`, secret `SEED_TOKEN`), le flux de données, et les commandes courantes (déployer,
init D1, secret, semer, inspecter/purger). Le `SEED_TOKEN` n'y figure pas (secret non relisible).

`BASE_LOCALE.md` (neuf, 2026-09-05) — miroir côté appareil : la base drift/SQLite locale
(`pentapol_settings.db`, `schemaVersion 10`, réécriture destructive), les quatre tables (`Settings` =
AppSettings JSON dont `playerId` ; `CurrentGame` ; `SolvedSolutions` ; `PuzzleStats`), quand c'est
écrit/effacé, et ce qui n'est PAS stocké. Reflète le schéma courant.

`FONCTIONNEMENT.md` est la description de référence de l'application — elle absorbe depuis
le 2026-08-31 l'ancien `PENTOSCOPE.md`, devenu un doublon partiel une fois qu'il n'est resté
qu'un module de jeu. `UI_PROPERTIES_GUIDE.md`, guide Flutter générique sans rapport avec
l'état du projet, est supprimé. `REFERENCE_TIRAGES.md` est le **test d'acceptation** du
générateur de tirages (`tools/generate_subset_counts.dart`) : sa sortie doit reproduire les
nombres du §2 (ce que le générateur vérifie, exit 1 sinon). Son §11 (ajouté le 2026-09-03)
recontrôle l'**asset livré** `subset_counts.bin` (996 confirmé), pas seulement l'énumération.

Trois documents de référence commités le 2026-09-03 (`69fce95`) : `REFERENCE_ISOMETRIES.md`
(coût des isométries, `minIso`, acuité, chiralité des tirages ; rejouable par
`tools/verif_isometries.py`), `CAHIER_DES_CHARGES_V1.md` (positionnement V1, système de score,
défi de la semaine) et `FICHE_APP_STORE.md` (champs mesurés contre les limites App Store).

### Test

Paul, iPhone et iPad simulé, en release :

```bash
flutter run --release -d 00008150-000165D4027B401C
```

> ⚠️ En `--release`, `debugPrint` est supprimé : tout critère formulé sur la console doit être
> reformulé en observation à l'écran.
> ⚠️ La réécriture destructive de la base ne se teste que **sur une base existante** — une
> installation neuve ne l'exécute jamais.

### Git

`origin/main` = **`8091059`** (poussé le 2026-09-04 : fix `isProgression` + Phase 0 défi + bump
`202609040505`, 1.0.3). **Commit local non poussé** : records perso **Phase A** (calcul + rack + bilan).
Bump de version à lancer (`scripts/update_version.sh`, date/heure) juste avant le prochain push.
La branche `deplacement-piece` a été
**supprimée** (fusionnée dans `main`). Depuis, commits locaux non poussés (2026-09-04, après le push de `16df5f8`) : médaille §4.6
(`ef58394`) et défi **Phase 1** (`challenge.dart`). Sauvegarde du
chantier écarté : branche **`backup/deplacement-piece-c5306b5`** (sur `origin` **et** locale) et tag
`chantier-deplacement-backup` (local seul), tous deux sur `c5306b5` — **ne pas supprimer** tant que
la question du déplacement d'une pièce n'est pas retranchée. Détail dans §ÉTAT « REVERT ».

> ⚠️ `settings_database.g.dart` (généré) est gitignoré : après un `pull`, régénérer par
> `dart run build_runner build --delete-conflicting-outputs`. `subset_counts.bin` **est** suivi.

---

## §PASSATIONS

> Les trois dernières seulement. Au-delà, `git log --oneline` dit la même chose en plus court.

**2026-09-12 (5) — CLI : lot des 11-12/09 commité et poussé sur `origin/main`.**
Quatre commits : `cd17918` feat(géométrie+accueil) — barème paramétrable, haptique et
consignes défilantes, l10n EN/FR, `build_info` estampillé `202609121549` ; `ad61576`
test — barème, accueil guidé, dispositions paysage ; `00a13ef` refactor(entrainement) —
suppression du mode autonome (les trois fichiers supprimés) ; `4887baf` docs — §ÉTAT,
`BAREME_GEOMETRIE.md`, accueil, checklist. Avant commit : `flutter analyze` **0 erreur /
0 avertissement** (61 infos), **205/205 tests** verts. Ressentis device restent à apprécier
par Paul (haptique, défilement, calage des coefficients du barème).

**2026-09-12 (4) — Codex : barème Géométrie paramétrable et reprise fiable.**
Fenêtre avec aperçu, barème figé et persisté, Impasses/Triche au bilan. Schéma 11 destructif
sur demande explicite de Paul ; id=0 rendu explicite pour retrouver la sauvegarde.
205 tests verts, 0 erreur/avertissement (106 infos), drapeau public vérifié. Les parties
expérimentales restent hors records ; voir BAREME_GEOMETRIE.md et CHECKLIST_APPSTORE.md.
Aucun commit/push.

**2026-09-12 (3) — Codex : icônes dans les consignes, retours haptiques dans l’accueil.**
FR/EN corrigés et régénérés ; retours de sélection, transformation, prise, cible et pose acceptée.
Réglage des vibrations respecté, pas de doublon automatique de Flutter ni de clic à chaque pixel.
**188/188 tests**, analyse **0 erreur / 0 avertissement / 106 infos**. Documentation à jour,
ressenti à apprécier sur appareil, aucun commit/push.


*(Les passations antérieures restent dans `git log` ; leurs règles vivent dans les documents de référence.)*
