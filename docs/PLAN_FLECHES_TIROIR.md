# Tiroir : navigation d'une pièce par appui

Diagnostic du 2026-10-08. Statut : plan approuvé puis implémenté le 2026-10-08.
Validation automatique réussie ; ressenti sur appareil à apprécier par Paul.
Résultat détaillé dans `JOURNAL.md` §ÉTAT. Conserver jusqu'à validation appareil.

Révision demandée par Paul le 2026-10-08 après implémentation : essai d'une seule
grande flèche (cible 64 dp, icône 48 dp), un pas par appui et retour à la première
après la dernière. Remplace les deux flèches et leur désactivation aux butées
décrites ci-dessous. En portrait à droite, en paysage en bas du tiroir vertical.
Pas de mouvement automatique continu ni de modification de l'ordre des pièces.
Verrouillage pendant le drag et seuil de visibilité conservés. Tests ciblés et
analyse réussis ; voir la nouvelle entrée du journal pour le résultat courant.

Précision suivante de Paul : continuité visuelle dans le même sens au passage de
la dernière à la première, et non retour animé à l'offset initial. Implémentation
par trois copies d'affichage avec recalage d'un tour au repos ; les pièces du
provider restent uniques. L'aperçu parcourt une seule séquence. Tests vérifiant
le sens de la transition pendant l'animation et plus de deux tours rapides.

Correction suivante demandée par Paul : trois pièces pouvaient rester partiellement
cachées sans flèche. Le seuil de quatre est retiré ; dès deux pièces, la flèche
dépend du débordement de la longueur totale avec marges. Si tout tient, marges
16 dp aux extrémités plutôt que centrage première/dernière, afin de tout montrer.
Cette règle remplace les indications initiales de masquage sous quatre pièces.

Retour suivant de Paul : retirer le fondu de bord, qui rend les voisines moins
nettes. Un appui avance depuis la pièce la plus proche du centre vers la suivante,
plutôt que de seulement compléter un centrage si le swipe s'est arrêté juste
avant. Cette règle remplace la proposition initiale du premier centre strictement
suivant. Pas variable selon les pièces, appuis rapides et boucle conservés.

Retour appareil suivant : swipe perturbé lorsqu'une pièce est sélectionnée.
Le départ de drag immédiat utilise désormais une affinity perpendiculaire au
tiroir pour laisser son axe au swipe, puis le déplacement de la pièce reste libre.
Le conflit du ListView est reproduit et corrigé par test ; le mouvement de fenêtre
iOS signalé par Paul reste à confirmer sur appareil après cette correction.

## Faits vérifiés dans l'arbre de travail

- `lib/pentoscope/widgets/pentoscope_piece_slider.dart` construit un `ListView`,
  horizontal en portrait, vertical en paysage, avec un `ScrollController` local.
- Les emplacements ne sont pas uniformes : leur longueur sur l'axe de défilement
  vaut `_pieceMaxDim(piece) * pieceCellSize + 8`. La dimension maximale sur toutes
  les orientations vaut 3, 4 ou 5 cases ; elle reste stable lors d'une rotation.
  L'épaisseur vaut `5 * pieceCellSize + 8`.
- `_pieceOffset` calcule déjà l'offset de centrage d'une pièce, avec bornage aux
  limites du contrôleur. Les marges initiale et finale permettent de centrer les
  pièces aux extrémités. Le nombre visible dépend de la place disponible et des
  pièces : aucune règle ne limite actuellement le tiroir à exactement trois.
- `_schedulePreview` parcourt le tiroir pendant 2,7 s, puis centre la pièce du
  milieu pendant 0,3 s. `_centerPiece` recentre une sélection en 250 ms.
  `_stopAutomaticScroll` interrompt une animation et invalide sa continuation.
- Un swipe réel désélectionne une pièce du tiroir ; le centrage automatique ne
  la désélectionne pas. Les fondus indiquent les deux directions disponibles.
- Le widget est utilisé par `PentoscopeGameScreen` en portrait/paysage et par
  `PentoscopeMPGameScreen` dans les deux orientations. Le duel utilise la taille
  de case par défaut, le jeu la calcule depuis le plateau et `rackCellRatio`.
- `DraggablePieceWidget` utilise un appui long pour une pièce non sélectionnée,
  un drag immédiat pour une pièce sélectionnée. Son emplacement reste occupé
  pendant le drag. Le tiroir du jeu est enveloppé dans un `DragTarget` qui gère
  également les retours de pièces et les dépôts au ras du plateau.
- L'arbre comporte déjà des changements non commités, notamment le tiroir,
  les tests et le journal : l'implémentation devra travailler avec cet état.

## Comportement proposé pour l'étape 2

1. Conserver les tailles, le swipe libre, le centrage au tap et l'aperçu initial.
   Ajouter précédent/suivant à gauche/droite en portrait, haut/bas en paysage,
   dans des zones réservées hors des cellules, sans superposition sur les pièces.
   Chaque cible tactile mesure au moins 48 x 48 dp. Les flèches restent hors du
   `ShaderMask` afin de ne pas être estompées.
2. Afficher les deux flèches seulement avec au moins quatre pièces disponibles
   et un débordement réel après layout. Si tout tient, aucune navigation n'est
   nécessaire. Garder la place des deux boutons lorsqu'un seul est désactivé.
3. Définir un pas par les centres des pièces : depuis un centrage exact, viser
   le centre voisin ; après un swipe laissant un offset intermédiaire, viser le
   premier centre strictement suivant/précédent dans le sens demandé. Utiliser
   une tolérance en pixels pour ne pas retomber sur le même centre.
   Réutiliser le calcul d'offset existant, jamais une largeur moyenne ou fixe.
4. Interrompre l'aperçu ou le centrage actif avant une navigation. Animer vers
   la cible avec `animateTo`, 250 ms et `easeOutCubic` ; respecter la réduction
   des animations système. Un appui de navigation désélectionne la pièce du
   tiroir comme un swipe, sans toucher à une sélection sur le plateau et sans
   modifier coups, tentatives ou chrono. Effectuer cette désélection avant de
   démarrer l'animation pour que le listener ne l'interrompe pas.
5. Pour les appuis rapides, mémoriser la cible demandée : chaque nouvel appui
   avance d'un indice depuis cette cible, même si l'animation n'est pas finie.
   Un swipe ou un toucher dans les pièces invalide cette cible et interrompt
   l'animation. Les continuations obsolètes ne doivent jamais relancer un mouvement.
6. Désactiver précédent au début et suivant à la fin, d'après les positions
   réelles/cibles et les nouvelles dimensions. Recalculer après layout et swipe.

## Cas limites et gestes

- Retrait/retour d'une pièce pendant une animation : interrompre l'animation,
  invalider la cible, recalculer les centres à partir des IDs disponibles.
  Après layout, borner l'offset aux nouvelles limites, puis rafraîchir les
  boutons. Ne pas conserver un indice qui désignerait une autre pièce.
- Passage de quatre à trois pièces : retirer les flèches, recalculer le viewport
  et borner l'offset après layout. Zéro pièce : conserver le tiroir vide actuel.
- Rotation écran, changement de ratio ou redimensionnement : abandonner les
  cibles en pixels périmées, recalculer marges, centres et butées après layout.
- Drag : le toucher dans le tiroir arrête déjà les animations. Ne pas faire
  défiler le contenu sous une pièce en cours de drag, y compris si un deuxième
  doigt presse une flèche. Bloquer la navigation pendant le drag ; au besoin
  ajouter un callback de fin de drag minimal dans le widget partagé, sans
  modifier les règles d'acceptation/refus ni enregistrer une tentative en plus.
- Garder les boutons distincts des zones de prise, sans nouveau reconnaisseur
  de swipe et sans toucher à l'ancrage du doigt ou au feedback dans l'Overlay.
- Les marges de centrage montrent volontairement moins de voisins aux butées.

## Fichiers concernés

| Fichier | Intervention prévue |
| --- | --- |
| `lib/pentoscope/widgets/pentoscope_piece_slider.dart` | Boutons, cibles par pièce, interruption, butées et adaptation après layout |
| `lib/common/widgets/draggable_piece_widget.dart` | Seulement si nécessaire : callback de fin pour verrouiller les flèches pendant le drag |
| `test/rack_scroll_test.dart` | Tests de navigation et de régression portrait/paysage |
| `lib/l10n/app_en.arb`, `app_fr.arb` | Seulement si les clés existantes `previous`/`next` ne conviennent pas aux tooltips et à l'accessibilité |
| `lib/l10n/app_localizations*.dart` | Régénération si les ARB changent |
| `docs/JOURNAL.md` | Résultat et décisions dans §ÉTAT et §PASSATIONS |

Les écrans du jeu et du duel sont des sites de contrôle du layout, pas des
modifications prévues. Aucun changement du provider ou des règles de jeu prévu.

## Vérifications après accord

- Vérifier la date avec `date`, puis renseigner `Modified:` en première ligne de
  chaque Dart modifié et conserver l'ancienne valeur dans `Historique:`.
- Tester des pièces de longueurs différentes, les deux sens, les butées,
  les offsets intermédiaires et les appuis rapides/inversés.
- Tester retrait en fin de tiroir et pendant animation, retour de pièce,
  zéro à trois pièces, quatre pièces sans débordement, resize et rotation.
- Vérifier cibles tactiles, désélection et compteurs inchangés, interruption
  de l'aperçu, centrage au tap, swipe et drag. Tester les animations réduites.
- Exécuter les tests ciblés, les régressions de drag concernées, puis
  `flutter analyze`. Régénérer les localisations si nécessaire.
- Paul apprécie le geste sur appareil, en portrait/paysage et en duel.
  Aucun commit sans demande explicite.

## Point soumis à accord

La proposition traite « trois pièces visibles » comme le constat motivant les
flèches, et conserve le layout adaptatif actuel. Garantir exactement trois
emplacements visibles serait un changement supplémentaire : cellules de tailles
différentes, marges de centrage et échelle liée au plateau empêchent de l'obtenir
simplement en divisant le viewport par trois. Paul a approuvé cette proposition
conservant le layout adaptatif par son « go » du 2026-10-08.
