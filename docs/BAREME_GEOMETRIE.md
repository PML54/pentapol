# Géométrie — mise au point du barème

Référence au 2026-09-12. Décision de Paul : réglage sur appareil avant publication,
remise à zéro des données de développement, aucune conversion des anciennes notes.

## Utilisation

Accueil → Réglages → **Réglage du barème**. Les curseurs modifient un brouillon ;
le tableau donne immédiatement les pénalités à 20 %, 50 %, 80 % et 90 % de remplissage.
**Sauvegarder** enregistre sur l'appareil et ferme la fenêtre. Le retour abandonne les
modifications. **Rétablir les valeurs initiales** remet le brouillon aux valeurs ci-dessous ;
le sauvegarder pour les appliquer.

| Paramètre | Défaut | Plage / pas |
|---|---:|---|
| Note de départ | 100 | 10–100 / 5 |
| Pénalité de remplissage | 10 | 0–50 / 0,5 |
| Progressivité | 2 | 1–4 / 0,25 |
| Supplément zone non multiple de 5 | 5 | 0–50 / 0,5 |

Les paramètres sont pris à la **prochaine nouvelle partie solo**, libre ou de progression.
Reprendre la partie courante conserve son propre barème, y compris après fermeture de l'app.
L'accueil guidé, les duels et les défis ne consomment pas ces réglages.

## Calcul et affichage

`pénalité = coefficient × r^progressivité + supplément éventuel`

`r` est la proportion de cases occupées **après** le coup fautif (cases masquées exclues).
Le supplément s'applique si une zone vide connexe par les côtés a une aire non multiple de 5.
Le diagnostic est celui de `fault_analysis.dart`. Une aire multiple de 5 n'assure pas qu'une
solution existe : l'impasse peut venir des formes ou des pièces restantes.

Une pénalité est enregistrée seulement lors d'une transition **soluble → insoluble**.
Les essais dans le rack, aperçus et transformations refusées ne la modifient pas. Les
corrections pendant une même impasse ne multiplient pas les pénalités ; corriger ne rend
pas les points perdus. Une nouvelle entrée en impasse est comptée de nouveau. La pose finale
ne crée jamais de pénalité, même si le moteur n'a plus de solution restante à chercher.

`note = max(0, note de départ − somme des pénalités)` ; aucun arrondi intermédiaire.
Le bilan affiche jusqu'à une décimale, sur la note de départ choisie, même pour une partie aidée.

| Remplissage | Impasse subtile | Zone non multiple de 5 |
|---|---:|---:|
| 20 % | 0,4 | 5,4 |
| 50 % | 2,5 | 7,5 |
| 80 % | 6,4 | 11,4 |

Le bilan et les compteurs optionnels affichent **Géométrie**, **Impasses**, **Triche**.
Triche compte chaque appui accepté sur la lampe **jaune**, même si la source ne fournit
finalement aucune aide. Un appui rouge (retrait) ou neutralisé en défi n'incrémente pas Triche.
Il n'y a pas de deuxième pénalité géométrique pour une aide ; le bilan indique « Partie aidée ».
Les compteurs à zéro restent affichés dans le détail.

Étoiles solo : 3 sans impasse et sans aide ; 2 avec impasse mais au moins 80 % de la note
initiale et sans aide ; 1 sinon. Les rotations du rack n'entrent plus dans cette note.
Le détail du bilan défile si nécessaire en paysage et adapte les lignes aux grands caractères.

## Persistance et records

- `GameSettings.geometryRules` : configuration pour la prochaine partie, JSON dans Settings.
- `PentoscopeState.geometry` : objet immuable contenant barème, total des pénalités et marqueur
  expérimental ; transmis à `CompletionMetrics`.
- `CurrentGame.geometryState` : snapshot JSON version 1, stocké avec les pièces et compteurs.
- **Schéma SQLite 11**, avec `destructiveFallback` : la première ouverture après cette mise à
  jour efface les réglages, parties et records locaux. Paul l'a explicitement demandé.
- L'identifiant de sauvegarde est explicitement **0** à l'insertion : SQLite attribuait 1 si
  l'INTEGER PRIMARY KEY était omis, malgré DEFAULT 0, alors que la lecture cherchait 0.
  L'upsert remplace désormais réellement la ligne unique. Le démarrage attend aussi la
  suppression de l'ancienne partie avant de rendre la main.

Pendant le calibrage, **toutes les nouvelles parties solo sont expérimentales**, même avec
les valeurs initiales. Elles n'écrivent ni PuzzleStats ni SolvedSolutions. La progression
reste disponible. Les contrats des défis/duels et le calcul d'acuité des classements ne
changent pas dans ce chantier : leur migration vers Géométrie sera décidée avec le barème final.

## Avant publication

Le drapeau `PENTAPOL_SCORE_TUNING` vaut true par défaut, **y compris en release**, pour les
essais de Paul sur iPhone. `--dart-define=PENTAPOL_SCORE_TUNING=false` masque l'entrée et fait
utiliser `const GeometryRules()` aux nouvelles parties ; une valeur personnalisée sauvegardée
ne peut donc pas contaminer une nouvelle partie publique. Une partie déjà commencée conserve
son snapshot et son exclusion des records.

Avant soumission : fixer les valeurs retenues dans GeometryRules, désactiver le drapeau par
défaut, arrêter le contrat des records locaux et du classement en ligne, puis remplacer la
stratégie destructive par de vraies migrations. **Masquer la fenêtre seul ne termine pas la
migration du système de records.** Voir CHECKLIST_APPSTORE.md.

## Vérifications exécutées

- **205/205 tests** sur la suite complète ; analyse **0 erreur / 0 avertissement / 106 infos**.
- Calculs chiffrés, classification des poches, correction, deuxième impasse et victoire.
- Parcours sur le vrai corpus 3×5 : pénalité, aide, sauvegarde SQLite, nouveau provider,
  reprise fidèle, nouvelles valeurs à la partie suivante, exclusion des records.
- Montée d'une base avec schéma 10 vers 11 : données effacées et colonne créée.
- Fenêtre et bilan FR/EN, 320×568 et 874×402, police système à 130 % : aperçu,
  abandon, sauvegarde, réouverture, reset et absence de débordement.
- Deux tests supplémentaires exécutés avec le drapeau false : accès masqué et paramètres
  expérimentaux ignorés au démarrage.

Tests : `test/geometry_*_test.dart`. Le généré Drift est ignoré par Git ; après récupération
du code, régénérer avec `dart run build_runner build --delete-conflicting-outputs`.
Le ressenti et les coefficients restent à apprécier sur appareil par Paul.
