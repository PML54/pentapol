PLAN_DIAG_DRAG — Décalage horizontal lors d'un drag vertical

Rédigé par Claude (chat) le 2026-09-01. À exécuter par Claude Code (CLI). Règle : diagnostic par instrumentation et mesure AVANT toute correction. Ne rien corriger tant que la cause n'est pas prouvée par les logs.

1. Symptôme (fait rapporté)
   En descendant une pièce verticalement (haut → bas) sur le plateau, à l'arrivée en bas la pièce se retrouve décalée d'une colonne vers la gauche.
   Non systématique.
   Concerne potentiellement les deux modes de déplacement :
   Mode A : drag-and-drop depuis le bandeau de pièces (tray) vers le plateau.
   Mode B : sélection d'une pièce déjà posée sur le plateau, puis déplacement au doigt.
2. Hypothèses (classées par plausibilité a priori — AUCUNE n'est prouvée)
   H1 — Biais de troncature pixel→cellule. Conversion de la position en indice de colonne par division entière (~/, floor) au lieu de round sur le centre de la pièce. floor biaise TOUJOURS vers la gauche/le haut ; le bug n'apparaît que quand le doigt dérive de quelques pixels, d'où l'aspect « non systématique ».
   H2 — Ordre de balayage du snap magnétique. Quand la position brute est invalide ou ambiguë (près du bord bas, cellules occupées), la recherche de la position valide la plus proche balaie les candidats dans un ordre fixe (gauche→droite) et retient le premier en cas d'égalité de distance → biais gauche. Dépend de l'occupation du plateau → non systématique.
   H3 — Clamp de bord erroné. En bas du plateau, le clamp du bounding box de la pièce utilise une mauvaise dimension (largeur/hauteur inversées, ou dimensions avant/après rotation) : un mouvement purement vertical produit alors une correction horizontale.
   H4 — Point d'ancrage (grab offset) incohérent. L'offset doigt↔origine de la pièce calculé au pointer-down n'est pas réappliqué à l'identique au drop, ou diffère entre mode A (dragAnchorStrategy / feedback du Draggable) et mode B (pièce déjà ancrée à la grille).
   H5 — Dérive cumulative. Position mise à jour par accumulation de deltas avec arrondi à chaque frame, ou aller-retour cellule(int)↔pixel(double) pendant le drag : erreurs qui s'accumulent sur un long trajet vertical.
3. Instrumentation à poser (CLI)

Ajouter un logger de diagnostic (debug uniquement, désactivable par un flag, ex. kDragDiag) qui trace pour CHAQUE drag, dans les deux modes :

pointer-down : mode (A/B), pièce, orientation, position globale du doigt, position locale plateau, grab offset calculé.
pointer-move (échantillonné, ex. 1 frame sur 5) : position locale, coordonnées de cellule fractionnaires (ex. col=3.48), colonne/ligne retenues AVANT snap.
résolution du snap : position d'entrée, liste des cellules candidates évaluées avec leur distance, cellule choisie, raison (arrondi direct / recherche de position valide / clamp).
pointer-up / drop : cellule finale, delta entre colonne fractionnaire brute et colonne finale.

Sortie : une ligne CSV par événement (tag DRAGDIAG,) pour extraction par grep + analyse.

4. Protocole de mesure (Paul, sur device)
   10 descentes verticales lentes en mode A, 10 en mode B, en visant la même colonne.
   Idem en visant une colonne près du bord droit et près du bord gauche.
   Noter les essais où le décalage se produit.
   Extraire les logs : grep DRAGDIAG → fichier CSV.
5. Critères de décision (lecture des mesures)
   Si col fractionnaire ≈ x.4–x.5 et colonne finale = floor(x) → H1 confirmée (troncature). Correctif attendu : arrondi sur le centre de la pièce, pas sur son coin.
   Si la colonne brute est correcte mais le snap choisit une cellule à gauche parmi des candidates équidistantes → H2 confirmée. Correctif attendu : départage par distance euclidienne réelle, pas par ordre de balayage.
   Si le décalage n'apparaît que lorsque le bounding box touche la dernière ligne → H3 confirmée.
   Si le grab offset loggé au drop diffère de celui du pointer-down, ou diffère entre modes A et B → H4 confirmée.
   Si la colonne fractionnaire dérive progressivement pendant la descente alors que le doigt ne bouge pas en x (à vérifier avec la position globale brute) → H5 confirmée.
   Plusieurs hypothèses peuvent être vraies simultanément (ex. H1 + H2).
6. Après diagnostic
   Consigner la ou les causes prouvées dans docs/JOURNAL.md §DÉCISIONS, avec extraits de logs à l'appui.
   Proposer le correctif dans un second temps, séparé de l'instrumentation.
   Ne pas retirer l'instrumentation : la laisser derrière le flag kDragDiag pour les régressions futures.