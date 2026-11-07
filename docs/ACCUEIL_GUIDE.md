# Accueil et Training guidé 5×5

> _Dernière révision : 2026-11-05 — Jeu Iso, accueil sans Training, classement agrandi._

## Classement du menu principal

L’accueil affiche jusqu’aux cinq meilleurs temps du défi quotidien sur une même
page, avec uniquement la taille en titre (par exemple 4×5), puis rang, pseudo et
durée totale en secondes. Titre de 26 sp et lignes de 20 sp ; le défilement automatique et le balayage passent
d’une taille de plateau à l’autre. Le menu commence sous l’en-tête pour utiliser
l’espace supérieur. Sur écran court, le menu reste défilable verticalement.
Le classement est actualisé au retour au menu et à la reprise de l’application
si l’accueil est visible. Sans score, le panneau et son espacement disparaissent.
Le consentement au partage des scores reste requis avant toute requête.

## Parcours visible

`HomeScreen` affiche directement `DiscoveryScreen` tant que le marqueur JSON
`hasCompletedDiscovery` est absent ou false. L'ancien marqueur de présentation de
l'aide n'est pas repris : lire une aide ne signifie pas avoir fait cette découverte.
Aucune migration de base. Seuls Play ou Passer enregistrent le marqueur. Une pose
réussie ne le change pas : fermer l'app à ce stade repropose la découverte au lancement
suivant.

La découverte utilise les 856 pavages 5×5 (45 tirages) extraits du corpus livré par
`tools/generate_discovery_boards.py` dans `discovery_boards_data.dart`. Aucune
résolution à l'exécution, aucun chargement réseau : les données sont disponibles
dès l'ouverture. Chaque exercice laisse quatre pièces fixes et une seule à poser.
La cible est choisie avant le pavage : un cycle propose chacune des onze pièces
orientables une fois, puis recommence. Le pavage est choisi parmi ceux qui contiennent
cette cible et varie à chaque retour de la même pièce. Le compteur JSON
`discoveryNextExercise` est avancé à chaque exercice présenté, y compris au premier
affichage, et conservé entre les ouvertures. Une fermeture ne ramène donc pas à la
pièce n°2. Aucune migration. X est exclue des cibles car elle n'a pas d'autre orientation. La cible demande une rotation horaire.

Les douze pentominos sont mélangés dans un tiroir horizontal. La cible est insérée
aléatoirement en position 7 à 12, jamais parmi les six premières. Le mélange reste
stable pendant l'exercice et est renouvelé au suivant. Les quatre formes déjà posées
figurent aussi dans le tiroir. Seule la cible est jouable : aucune copie des pièces
fixes ne peut être déposée. Aucun chrono, score ni changement
du Solo sauvegardé ; les leurres ne peuvent jamais être déposés.

Consignes fixes EN/FR, police 20 sp avec agrandissement système, deux lignes maximum :

1. « Balaie le tiroir. » puis « Sélectionne » suivi de la miniature colorée de la cible, sans numéro.
2. Quand la cible est visible après balayage : « Sélectionne » et la même miniature, dans son orientation initiale au tiroir.
3. Après sélection : « Positionne » suivi de la miniature dans l’orientation à obtenir, puis « avec les icônes. » sur la deuxième ligne.
4. Rotation exacte : « Glisse la pièce / dans l’espace libre. »
5. Dépôt : « Bravo ! » seul, agrandi de 20 à 34 sp en 700 ms puis fixe. Boutons
« Training » violet (nouvel exercice) et « Play » (Solo). Avec réduction des animations,
Bravo est directement affiché à sa taille finale.

Le fond du Training est bleu très pâle (#EAF3FC), le tiroir légèrement plus soutenu
(#DDEAF7) et la silhouette manquante est hachurée en diagonale sur fond blanc dès le début de
chaque exercice. Les traits continus sont découpés sur les cinq cases de la cible ;
le contour bleu se superpose sans masquer les hachures à l'étape de pose. Une pose validée produit un unique
impact tactile moyen (mediumImpact), uniquement si enableHaptics est activé dans les
réglages. Un dépôt refusé ou une simple prise ne produit pas cette confirmation.

Une bande tactile de balayage est placée entre les icônes
et le tiroir. Le glissement dans cette bande fait défiler directement le tiroir,
y compris lorsqu’une pièce est sélectionnée, en conservant son orientation.
Au premier exercice affiché dans ce parcours, « Balaie ici pour voir les pièces »
(EN : « Swipe here to see the pieces ») précise la zone. La consigne disparaît au
premier défilement effectif, depuis la bande ou le tiroir, et ne revient pas aux
exercices suivants. Les doubles flèches ont été retirées à la demande de Paul.

Dans Solo, Défi et Jeu Iso, le tiroir débordant dispose aussi d’une bande tactile sans flèche :
au-dessus en portrait, sur le bord en paysage.
Balayer cette bande conserve la sélection sans attraper la pièce. L’espace de la
bande est inclus dans le calcul des dimensions plateau/tiroir.

Le résultat reste affiché sans temporisation ni relance automatique. « Encore une
pièce » réinitialise le plateau, l’orientation, la consigne de recherche et le tiroir
au début, uniquement sur appui du joueur. La réussite seule ne termine jamais le
parcours.

Les pièces du tiroir gardent un rapport constant à la case du plateau : 0,55
(au lieu de 0,65), ce qui réduit aussi la hauteur du tiroir. Le feedback pendant le
glissement conserve la taille des cases du plateau et la même ancre centrale.
Les quatre icônes mesurent 44 dp, avec zones tactiles de 64 dp, et sont affichées
dans l'ordre habituel : rotation antihoraire,
rotation horaire, miroir haut/bas, miroir gauche/droite. Elles sont grisées avant
sélection, toutes utilisables ensuite, y compris quand la pièce est prête à poser.
La transformation conseillée est celle qui rapproche de l'orientation cible. Refaire
une transformation peut ramener à la consigne d'orientation ; le dépôt n'est possible
que lorsque la forme correspond de nouveau à la cible. Les pièces fixes ne bougent pas.
La pièce cible et la commande utile sont mises en évidence aux étapes correspondantes.
Maintenir puis glisser reprend le délai configuré dans les réglages. La pose vérifie
l'identité et l'orientation, puis aimante uniquement vers les cinq cases manquantes
avec une tolérance d'une case autour de la cible. Un relâcher ailleurs ne modifie pas
le plateau. Aucun geste automatique ni défilement automatique du tiroir.

« Passer » est permanent, y compris après réussite, et ouvre l'accueil normal.
« Play » lance un Solo 3×5 ; pour un joueur déjà avancé, cet essai ne change pas le
niveau débloqué. Les accès aux modes, le niveau, le profil et les réglages restent
masqués pendant la découverte. L'accueil normal conserve ces accès sans démo.
L'aide propose « Découvrir le jeu » pour rejouer le parcours.

## Accès à la découverte et Jeu Iso

Depuis le 2026-11-05, le bouton Training n’apparaît plus dans le menu principal.
Le parcours 5×5 reste proposé au premier lancement et accessible depuis l’aide
via `_openDiscovery` : quatre pièces fixes, une cible, douze pièces mélangées,
quatre icônes, Bravo, Training pour continuer et Play pour le premier Solo.
Passer revient à l’accueil. L’ouverture depuis l’aide et le passage ne modifient
pas la partie Solo chargée.

L’entrée « Jeu Iso » (« Iso Game » en anglais) ouvre le mode Isométries existant,
avec huit pièces, acuité sur 10, étoiles et compte à rebours de trois minutes.
L'ancien branchement de l’accueil vers le Training 3×5 à une/deux pièces et son
paramètre `startRecreationalOnOpen` restent retirés ; le moteur historique et ses
tests sont conservés.

## Référence historique : sept petits entraînements

> Cette section décrit le parcours d'accueil antérieur au 2026-09-21. Elle est conservée pour
> expliquer les variantes et composants historiques ; elle ne décrit plus le démarrage actuel.

Les sept pavages existants sont utilisés : **PFU, PUN, PVL, PVU, PYU, TYL, VLN**.
L’accueil choisit un premier tirage au montage. Le bouton **« Training »**
en fin de parcours, de même style plein que Jouer, passe au tirage suivant : les sept configurations sont parcourues avant
répétition, y compris le retour du dernier au premier. Ce choix est local, sans persistance.

Toutes les pièces démarrent dans une orientation géométriquement différente de leur silhouette.
Les deux premières demandent une rotation ; la dernière est une pièce chirale qui nécessite
un miroir. La consigne s’adapte aux transformations réalisées par le joueur. Exemple PFU :

| Ordre interne (non affiché) | Pièce | Geste enseigné |
|---|---|---|
| 1 | U, n°7 | Tourner, puis déposer |
| 2 | P, n°2 | Tourner, puis déposer |
| 3 | F, n°4 | Retourner en miroir, puis déposer |

Le rack place la première pièce demandée en dernier pour inviter à explorer. Il défile
horizontalement en portrait et verticalement en paysage, avec une barre de défilement.
Les pièces restent numérotées et disponibles ; un mauvais choix invite à retrouver le numéro
demandé. Une pièce posée quitte le rack. Les emplacements réservent assez de place pour les
pièces longues dans toutes leurs orientations, sans changer de taille lors d’une rotation.

Les quatre icônes proviennent de `GameIcons`, avec le même ordre, les mêmes couleurs et la
même taille partagée que le jeu : rotation antihoraire, horaire, miroir horizontal, vertical.
Les quatre boutons sont gris sans sélection et actifs sur une pièce du rack. Les opérations
utilisent `Pento`. Le joueur peut essayer, revenir en arrière et corriger son orientation.

Les consignes parlent d’**icônes** (EN : icons) et suivent quatre états : aucune pièce sélectionnée,
pièce sélectionnée sans placement valide, pièce prête à déposer, puis puzzle complété. Les textes FR sont
« Appuie sur la pièce du tiroir pour la sélectionner », « Mets la pièce dans la bonne position avec
les icônes », « Déplace-la au bon endroit sur le plateau » et « C’est bon ! ». Le deuxième message
reste affiché tant que `validPlacements` est vide, quel que soit le nombre d'icônes déjà pressées.
Depuis le 2026-09-12, la police est agrandie (22 à 28 pixels logiques selon la largeur),
en gras, et respecte l’agrandissement système. À la demande de Paul, le message défile désormais
en continu vers la gauche à 72 pixels logiques/s (vitesse doublée), sans pause ni arrêt après
un tour. Une seconde copie assure le raccord entre les tours ; le changement de consigne
redémarre immédiatement avec le nouveau texte.
La zone garde la hauteur de la plus longue consigne : ni le mouvement ni le changement de message
ne déplacent le plateau. Une poignée permet de déplacer tout le bandeau au doigt lorsqu'il masque
une pièce. La couleur de police du bandeau change à chaque état (aucune sélection : bleu ; sans
placement valide : deep-orange ; placement valide : violet ; résolu : vert). La fin du Training 1
affiche « C'est bon ! — Tap pour le training 2. Double tap pour jouer » ; celle du Training 2 propose
de recommencer au Training 1. Aucun bouton ni bilan de score n'est affiché.
En réduction des animations ou
navigation accessible, la consigne est fixe dès le départ et annoncée une seule fois aux aides vocales.
Rendu isolé dans `lib/pentoscope/home/guided_scrolling_message.dart`.
Le parcours alterne deux niveaux. Le **Training 1** retire une pièce d'un plateau complet. Après sa
réussite, un tap lance le **Training 2** : deux pièces qui partageaient au moins un côté sont retirées
et placées dans le tiroir, chacune avec une orientation différente. Leur retrait conserve une solution
unique. Après la réussite du Training 2, un tap recommence au Training 1. À chaque fin, un
**double-tap** propose les niveaux Solo débloqués, puis démarre une vraie partie `Game` au niveau
choisi et remplace l'écran Training. Annuler conserve le Training. Il n'y a ni bouton
« Voir un autre » ni relance automatique (la relance auto 1 s a été essayée puis écartée). Le retour
Accueil ouvre le menu principal ; son bouton Training permet également de repartir sur un nouvel
exercice. Aucune boucle animée ne joue à la place du joueur.

## Choix du niveau Solo

Depuis l'accueil, toute partie Solo neuve propose les niveaux 1 au niveau courant, avec la taille
du plateau. Le plateau vide préparé au démarrage passe aussi par ce choix. Une partie de progression
déjà commencée est reprise directement. Le double-tap du plateau Solo et les actions de nouvelle
partie du bilan proposent la même liste ; au niveau 1, la partie démarre directement.
Seul le niveau de progression courant, réussi sans lampe jaune, permet de débloquer le suivant.
Rejouer un ancien niveau conserve les niveaux débloqués. L'annulation ne remplace pas la partie.

## Contour et encouragements animés

Le plateau reprend le contour du jeu : gris foncé, épaisseur de 3 pixels logiques, coins
arrondis de 16 et ombre. Le contour est dessiné par-dessus les cases, sans réduire leur taille
ni déplacer les zones de dépôt.

Chaque pose acceptée déclenche une coche verte rebondissante et des confettis colorés pendant
850 ms, centrés sur la pièce posée. À la dernière pièce, l’effet est plus ample et dure
1 400 ms au centre du plateau. Une tentative refusée ne déclenche aucune célébration.
L’effet laisse passer les gestes et disparaît seul ; le plateau reste fixe.
Le réglage système de réduction des animations supprime cet effet. Les consignes et
encouragements textuels EN/FR restent disponibles.
Le rendu est isolé dans `lib/pentoscope/home/guided_success_celebration.dart`.

## Prise et dépôt

La pièce suit le doigt dès sa prise. Le délai de prise et le rapport de taille rack/plateau
proviennent des réglages. Un contour rouge et un remplissage atténué indiquent que le dépôt
n’est pas accepté ; l’aspect redevient normal dans la zone cible avec la bonne orientation.

Le joueur peut saisir **n’importe laquelle des cinq cases**. Pour accepter le dépôt :

- la forme doit correspondre à la cible (comparaison géométrique, pas d’index arbitraire) ;
- le doigt doit être sur le plateau, dans la boîte englobante de la silhouette augmentée
  d’un quart de case de chaque côté.

La pièce se place alors exactement sur le modèle. La case saisie sert à l’ancrage visuel
pendant le déplacement, sans imposer une visée exacte sur sa case d’arrivée.
Cette assistance est propre à l’accueil ; elle ne modifie pas le placement dans le jeu.

## Retours physiques

L’accueil suit le réglage `enableHaptics` du jeu : clic discret à la sélection et à une
transformation, impact léger à la prise, clic à l’entrée dans une cible valide, impact moyen
uniquement à la pose acceptée. Aucun retour répété à chaque déplacement dans la même cible,
et aucune confirmation de pose sur un dépôt refusé. Le retour automatique de prise de Flutter
est désactivé pour éviter un doublon et respecter la désactivation des vibrations.
La sensation réelle dépend de l’appareil ; le réglage coupe tous ces retours dans l’accueil.

## Architecture et limites

`lib/pentoscope/home/guided_home.dart` contient un état local et ses propres widgets de geste.
Il réutilise `PieceRenderer`, la géométrie et les transformations de `Pento`, ainsi que les sept pavages
présents dans `home_tirages_data.dart`. Il ne charge pas de solveur et n’écrit ni partie solo,
ni temps, ni score, ni record, ni progression. Le parcours n’est pas mémorisé entre lancements.

En portrait, les zones se suivent verticalement. En paysage, le plateau 3×5 reste vertical
à gauche et les commandes/rack sont à droite. La hauteur des consignes est réservée en fonction
des textes mesurés pour éviter les débordements et les mouvements du plateau ; leur position peut
ensuite être ajustée sans modifier le layout.

Depuis le 2026-09-11, à la demande de Paul, l’icône et le mode séparé à une pièce sur 5×7
sont supprimés. Les sept parcours de cet accueil constituent l’entraînement de l’application.
L’accueil enseigne placement, rotation, miroir et remplissage ; l’explication du compteur
de solutions et des aides reste à traiter séparément (checklist de publication n°8).

## Vérifications

`test/guided_home_test.dart` vérifie les sept pavages sans chevauchement, l’orientation
initiale différente pour chaque pièce et la nécessité du miroir pour la dernière.
**88 parcours complets** : 40 prises PFU (cinq cases × quatre formats × deux langues) et
48 parcours supplémentaires (six tirages × quatre formats × deux langues).
Les tests couvrent défilement, déplacement du bandeau, quatre états de consigne, sélection,
transformations, dépôt, stabilité du plateau,
contour, déclenchement et disparition de la célébration,
le bouton Training plein, puis le passage au vrai tirage suivant avec réinitialisation des orientations.
Le retour du septième au premier est également vérifié.

Trois tests dans `test/guided_success_celebration_test.dart` vérifient que les gestes restent
possibles pendant les deux célébrations, que les effets se terminent et que la réduction des
animations est respectée.

Un parcours négatif contrôle les quatre opérations, les mauvais choix, les dépôts mal orientés
et hors plateau, puis la possibilité de réessayer sans perdre la pièce.
Quatre tests du bandeau vérifient message court/long, vitesse de 72 pixels/s, répétition sur
plusieurs tours, nouvelle consigne et arrêt lors du passage dans un mode accessible.
Les parcours de gestes utilisent la navigation accessible pour isoler leurs vérifications du défilement.
Deux tests de gestes réels contrôlent les appels haptiques, vibrations activées et désactivées :
sélection, transformation, prise, entrée dans la cible, mouvement interne, refus et pose acceptée.
Les formats de tests widget ne constituent pas une validation tactile sur appareil.

Vérification du 2026-09-12 : **188 tests réussis** en suite complète ; analyse du dépôt
complet : **0 erreur, 0 avertissement, 106 informations** (incluant les outils).
Les tests de `test/home_play_test.dart` vérifient l’accès via Jouer, la conservation de la partie et
du chrono, la présence des six destinations du menu et l'absence de débordement en petit portrait
et en paysage, en français et en anglais.
Les tests de l’accueil et le contrôle combinatoire des distances restent conservés.
Paul confirme « c’est OK » le 2026-09-11 pour cette version à sept variantes et orientations
à corriger. Le contour renforcé et les célébrations ont été ajoutés après ce retour.
Le mode séparé sur 5×7 a été retiré ensuite à la demande de Paul.
