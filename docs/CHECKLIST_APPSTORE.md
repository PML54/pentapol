# Checklist — avant la première soumission App Store

> Ouverte le 2026-08-30. **Ce fichier s'allonge au fil du travail** : dès qu'une décision
> crée une dette qui ne doit pas partir en production, elle s'inscrit ici, avec sa raison.
> C'est le seul endroit où ces dettes sont rassemblées — le journal les disperse.
>
> État de l'application : **non publiée**, `version: 1.0.0+1`. Paul a déjà publié cinq
> applications ; ce document ne couvre donc **pas** la mécanique de soumission (certificats,
> App Store Connect, captures), seulement ce qui est spécifique à Pentapol.
>
> ⚠️ **Android est dans le périmètre** (décision de Paul, 2026-09-08 ; le jeu tourne déjà en APK
> release). Ce document parle « App Store » par héritage, mais **les bloquants valent pour les deux
> stores**. Spécifique au Play Store, à ajouter le moment venu : **Play Console** (compte
> développeur), **keystore** de signature release (l'APK de test est signé en clé debug),
> **métadonnées localisées EN/FR** à fournir **deux fois** (App Store Connect + Play Console).

---

## 1. Bloquants techniques

| # | Point | Pourquoi | Où |
|---|---|---|---|
| 24 | **Figer Géométrie et retirer son calibrage** | Fenêtre active même en release pour Paul. Arrêter les coefficients, désactiver `PENTAPOL_SCORE_TUNING` par défaut, vérifier que les valeurs expérimentales sont ignorées et décider du contrat de records Géométrie (les classements utilisent encore l’acuité). Parties de calibrage exclues des records. Schéma 11 destructif autorisé en développement ; retirer cette stratégie avant publication. | `docs/BAREME_GEOMETRIE.md`, `lib/pentoscope/geometry_score.dart` |
| 3 | **Retirer la réécriture destructive de la base** | `MigrationStrategy` destructive + `schemaVersion` : légitime tant que rien n'est publié, **mine** après. Elle effacerait les records des joueurs, et seulement le jour où le schéma bougera — des mois plus tard | `lib/database/settings_database.dart`, plan `PLAN_PERSISTANCE.md` §5 |
| 4 | **Ajouter un rapport de crash** | Sans ça, publication à l'aveugle : ceux qui plantent désinstallent sans rien dire. Aucun outil aujourd'hui — ni Crashlytics, ni Sentry | `pubspec.yaml`, `main.dart` |
| 5 | **Sauvegarde livrée — confirmer la reprise sur appareil** | Partie en cours enregistrée aux poses/retraits et au passage en arrière-plan, restaurée au lancement. Ne plus annoncer cette fonction absente. La confirmation de reprise après fermeture reste distincte du test OK de l’accueil | `main.dart`, `pentoscope_provider.dart`, `BASE_LOCALE.md` |
| 6 | **Fiabiliser le multijoueur, maintenu en V1** | **Paul le garde dans la V1** (CDC §12, Q4 — 2026-09-03), contre la recommandation initiale de couper. Il dépend d'un worker Cloudflare hors dépôt, **URL en dur**, sans interrupteur distant : le jour où il tombe, l'app publiée garde un bouton mort, et un lobby sans joueurs est pire que pas de lobby. Puisqu'il reste, ces deux défauts deviennent **bloquants** — prévoir un interrupteur distant (ou un ping de disponibilité qui masque l'entrée si le service ne répond pas) et sortir l'URL du code. Rappel conformité : le duel constitue un flux réseau distinct du classement sur consentement (points 12 et 14) | `pentoscope_mp_provider.dart` l.32-35 |
| 7 | **Renseigner `version:` de `pubspec.yaml` le jour de la soumission** | `version: 1.0.0+1`. Chaque téléversement demande un build supérieur au précédent, et c'est `pubspec.yaml` qu'Apple lit. **Ce n'est PAS une divergence à corriger** (précision de Paul, 2026-09-08) : `scripts/update_version.sh` est un **outil de développement** qui n'écrit que `lib/config/build_info.dart` (affichage interne de version/build), **volontairement** ; `pubspec.yaml` est renseigné **à la main** au moment de la soumission. Les deux sources n'ont pas à coïncider en cours de dev — d'où un simple **point de contrôle de soumission**, pas un bloquant permanent | `pubspec.yaml`, `lib/config/build_info.dart`, `scripts/update_version.sh` |
| 21 | ~~**Changer le bundle identifier**~~ **FAIT côté code (2026-09-08) — reste l'enregistrement dans les consoles** | L'identifiant est passé de `com.example.pentapol` à **`com.pml.pentapol`** sur les deux plateformes : iOS (`PRODUCT_BUNDLE_IDENTIFIER`, 6 occurrences incl. `.RunnerTests`) et Android (`applicationId` + `namespace`, `MainActivity.kt` déplacé). Build APK debug OK. **Reste, hors dépôt** : enregistrer l'**App ID** `com.pml.pentapol` dans App Store Connect (et le package name dans le Play Console si version Android). Rappel règle n°6 : après première publication, cet identifiant est **définitif** | `ios/Runner.xcodeproj/project.pbxproj`, `android/app/build.gradle.kts`, `FICHE_APP_STORE.md` |
| 22 | ~~**Désactiver le bandeau de debug des compteurs**~~ **FAIT le 2026-09-10** | `kShowLiveCounters` repassé à **`false`** (retour de Paul, C9 du PLAN_ERGONOMIE_ICONES) : le coin haut-gauche n'affiche plus la bande debug ; réglage `showCounters` off → rien, on → récap propre. Repasser `true` pour l'observation en dev | `lib/pentoscope/screens/pentoscope_game_screen.dart` |
| 23 | **Trancher le réglage live « Taille des pièces du rack » (`rackCellRatio`)** | Ajouté le 2026-09-10 comme outil de **calibrage device** (retour de Paul, décision 6) : stepper 0.30-0.60 dans les Réglages, valeur figée à **0.46**. Avant soumission : soit le **garder** comme réglage d'accessibilité (taille des pièces), soit le **retirer** en gelant 0.46 (const `kPieceToBoardCellRatio` + défaut `GameSettings.rackCellRatio`) | `lib/models/app_settings.dart`, `lib/screens/settings_screen.dart`, `lib/providers/settings_provider.dart` |
| 19 | ~~**Figer la règle des coups avant tout record publié**~~ **CADUC (refonte « A », 2026-09-05)** | Le maillot **Coups a été supprimé** : le maillot à pois mesure désormais les **fautes** (transitions soluble→insoluble, `faultCount`), qui n'ont pas de dépendance à `translationCount` ni de formule ambiguë poses/retraits. Il n'y a donc plus de « règle des coups » à figer. Ce qu'il reste à verrouiller avant publication : la **définition des fautes** et le **plafond d'acuité à 100 %** (les changer casserait la comparabilité des records — règle n°6). Réf. : `completion_metrics.dart`, `MANUEL_DEFIS_ET_MAILLOTS.md` §2.2, `CAHIER_DES_CHARGES_V1.md` §4.1 (refonte « A ») |

| 16 | **Des réglages d'affichage ne font rien** | L'écran Réglages expose « Taille des icônes » (curseur 16-48 px), `showGridLines`, `enableAnimations`, `pieceOpacity`, `isometriesAppBarColor`. **Aucun n'est lu par le jeu** — vérifié au grep le 2026-08-30 : leurs seuls lecteurs sont le modèle, le provider et l'écran de réglages lui-même (plus `ui_dimensions.dart`, orphelin). L'utilisateur bouge le curseur, la valeur est enregistrée en base, et rien ne change. C'est le genre de détail qui vaut des avis à une étoile. **MAJ 2026-09-10** : le nouveau `GameSettings.showPieceNumbers` (C8, câblé au plateau) **est** fonctionnel — à ne pas confondre avec le `DuelSettings.showPieceNumbers` (« numéros sur le guide » du duel) qui, lui, reste **mort** (aucun lecteur) | `lib/screens/settings_screen.dart`, `lib/models/app_settings.dart` |

> **Points 1 et 2 retirés le 2026-09-08 (vérifiés au `ls`/`grep`).** 1 (« `flutter test` rouge ») :
> `test/widget_test.dart` **n'existe plus** ; la suite est verte (55/55). 2 (« retirer
> `supabase_flutter` ») : **absent** de `pubspec.yaml`/`pubspec.lock`, et `lib/bootstrap.dart` est
> supprimé — plus aucune trace de Supabase.
>
> **Points 17 et 18 résolus le 2026-08-31, retirés.** 17 (« Afficher la solution » morte sur le
> 6×10) : réglé par l'étape B (commit `3c287c3`) — `currentSolution` vient de `hintFrom`, donc
> fonctionne sur toutes les tailles, 6×10 compris. 18 (lettres fausses) : réglé par le chantier
> « table de lettres unique » (commit `3e3beaf`) — `pentominoLetters` unique, adossée à la
> géométrie, gardée par `test/pentomino_letters_test.dart`.

---

## 2. Bloquants produit

Ceux-là ne font pas planter l'app. Ils décident si quelqu'un la garde.

| # | Point | Pourquoi |
|---|---|---|
| 8 | **Accueil gestuel livré ; explication du compteur et des aides à compléter** | Accueil participatif 3×5 : placement, rotation, miroir, dépôt depuis toute case de la pièce. Livré dans `72a16bf`, validé sur iPhone par Paul le 2026-09-10 (« test OK »). Révision locale du 2026-09-11 : rack défilant, sélection par numéro, quatre icônes du jeu, encouragements, suppression des étapes affichées, sept tirages avec orientations à corriger et bouton « Un autre entraînement » ; version validée par Paul le 2026-09-11 (« c’est OK »). Depuis : bouton Training plein en fin de parcours et Jouer permanent dans l’en-tête pour accès direct au jeu. Il ne présente pas encore le compteur de solutions ni les aides. Voir `ACCUEIL_GUIDE.md` |
| 9 | **Variété des tirages livrée** | Le 6×10 garde un seul ensemble de 12 pièces. La variété vient des tirages solubles 5×n et des défis, déjà implémentés. Les rectangles 5×12 et 4×15 restent abandonnés (Paul, 2026-09-08) |
| 10 | **Compteur disponible sur toutes les tailles — résolu** | `CorpusSolutionSource` et le corpus précalculé apportent le compteur décroissant aux tirages 5×n ; `TableSolutionSource` couvre le 6×10. Aucun nouveau solveur ni `ListSolutionSource` à écrire. Ne pas confondre disponibilité des données et exposition du navigateur de solutions dans l’interface |
| 11 | **Records et progression livrés** | Progression solo persistée, trois records indépendants (acuité, fautes, temps), bilan, écran Records et médaille. Voir `MANUEL_DEFIS_ET_MAILLOTS.md` et `BASE_LOCALE.md`. Leur validation de persistance est distincte du test de l’accueil |

---

## 3. Conformité

| # | Point | Note |
|---|---|---|
| 12 | **App Privacy** | ⚠️ **Révisé le 2026-09-07 — le classement en ligne est DANS la V1** (choix de Paul, révise le « hors V1 » du 2026-09-03). Le défaut reste « **ne collecte rien** » : `shareScoresOptIn = false` par défaut → aucun score envoyé, **aucun `playerId` généré**. **Si** le joueur active le classement (geste explicite, dialogue de consentement + interrupteur Réglages), l'app envoie à la fin d'un défi : **pseudo**, **identifiant anonyme 128 bits** (`playerId`, non lié à une identité réelle), les trois métriques et la **grille terminée**. À déclarer dans App Store Connect : type **Identifiants → ID utilisateur**, **lié à l'utilisateur**, usage **Fonctionnalité de l'app** (classement), **pas de suivi**. La grille = « Autres données de diagnostic/usage ». Multijoueur : voir point 14. **La déclaration « ne collecte rien » n'est vraie que si on déclare aussi le comportement opt-in** — Apple veut ce qui *peut* être collecté, pas seulement le défaut |
| 13 | **Suppression de compte** | ⚠️ **Révisé le 2026-09-07 — exigible en V1** (le classement y est). **Fait** : Réglages → « Supprimer mes données de classement » appelle `DELETE /score?playerId=…` (efface toutes les lignes du joueur côté serveur) puis efface le `playerId` local et coupe l'opt-in. Pas de compte à créer (identité anonyme auto-générée sous opt-in) → l'exigence Apple « supprimer le compte/les données depuis l'app » est satisfaite par ce bouton. **Prérequis d'exploitation** : la route `DELETE /score` du worker doit être **déployée** (redéploiement par Paul) — tant qu'elle ne l'est pas, le nettoyage local se fait mais le serveur garde les lignes (id secret → inatteignables, mais non conforme au sens strict) |
| 14 | **RGPD** | Aujourd'hui, hors du multijoueur, une donnée ne quitte l'appareil **que** si le joueur active le classement (opt-in explicite, désactivé par défaut) : pseudo + identifiant 128 bits (donnée personnelle au sens RGPD, CDC §7.4). Bases légales couvertes : **consentement** (opt-in) et **droit à l'effacement** (bouton de suppression, point 13). Le point 6 (multijoueur) reste un point de conformité distinct |
| 15 | **Politique de confidentialité** | Une URL est demandée à la soumission, même pour une app qui ne collecte rien |
| 20 | **Localiser les métadonnées App Store (EN + FR)** | Depuis le 2026-09-06 l'app est **bilingue EN/FR** (`docs/I18N.md`). Il faut **déclarer les deux langues** dans App Store Connect et fournir des **métadonnées localisées** : nom, sous-titre, description, mots-clés, et **captures** par langue. Une app bilingue avec une fiche unilingue perd le bénéfice — surtout côté anglophone. Ce n'est pas du code : c'est un livrable de soumission | App Store Connect, `FICHE_APP_STORE.md` |

---

## 4. Recommandé, non bloquant

- **`bigint_plateau.dart` et `shape_recognizer.dart` supprimés le 2026-09-09** (`git rm`, décision de
  Paul) — orphelins autonomes, zéro importateur, `analyze` 0/0 et tests inchangés après retrait.
- Orphelin restant : **`ui_layout_provider.dart`** (et ses 9 providers). Sans effet à l'exécution,
  mais alourdit la relecture. Il est **entrelacé** avec `ui_layout_manager` → `ui_dimensions`
  (import chaîné) : son retrait est un **chantier de code**, pas une correction documentaire, à
  décider avec Paul.
- ~~`pentomino_solver.dart`~~ **résolu le 2026-08-31 (étape B, chantier 2)** : `pentomino_solver.dart`,
  `tools/generate_6x10_solutions.dart` et `solution_collector.dart` **supprimés**. Retrait par
  **substitution** : l'énumération du 6×10 est reprise par `tools/generate_solutions_corpus.dart`
  (`_verify6x10`), qui vérifie `solutions_6x10_normalisees.bin` par égalité d'ensembles (9356 =
  énumération = asset expansé ×4). Plus aucun solveur backtracking dans le dépôt.
- **Deux membres publics morts, invisibles à `flutter analyze`** (trouvés le 2026-09-03) :
  `PentoscopeNotifier.cycleToNextOrientation()` — aucun appelant dans `lib/`, donc la barre
  d'isométries est le **seul** chemin vers une réflexion ; et `GameIcons.undo` — icône, libellé
  « Annuler » et couleur définis dans `game_icons_config.dart`, référencés nulle part. Même
  famille que les trois fichiers orphelins ci-dessus : `analyze` ne les signale pas parce qu'ils
  sont publics.
- `flutter pub add collection` — lint `depend_on_referenced_packages` préexistant.
- La preview cyan morte dans `pentoscope_board.dart` (lit `state.isSnapped`, que personne
  n'écrit).
- **Le SnackBar de debug « 🎯 Lobby chargé - test DB »** au lancement du lobby multijoueur
  (`pentoscope_mp_lobby_screen.dart`, `initState`) — artefact de développement, visible en prod.
  À **retirer** (il est volontairement laissé non traduit, cf. `docs/I18N.md`).
- Le paramètre `cellSize` de `PieceRenderer` — la miniature signalée par Paul au déplacement
  d'une pièce, taille de case codée en dur à 22 px alors que celle du plateau est calculée.

---

## 5. Ce que cowork ne peut pas juger

À dire franchement, pour que personne ne s'appuie sur un avis qui n'existe pas : **cowork n'a
jamais vu l'application tourner.** Ni les graphismes, ni la fluidité, ni le ressenti d'un
glissé de pièce, ni la lisibilité sur un écran réel. Pour un jeu de puzzle, c'est l'essentiel
de ce qui décide de son sort, et rien dans ce document ne l'évalue.

Deux défauts visibles ont été trouvés par Paul en deux sessions de jeu occasionnel (le
chronomètre qui ne s'arrête pas, le bilan qui masque le plateau). Cela donne une idée de la
densité de ce qui reste : **ça se trouve en jouant, pas en relisant du code.**
