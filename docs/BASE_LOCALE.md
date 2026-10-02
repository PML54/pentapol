# Base locale (sur l'appareil) — ce que Pentapol garde

> _Dernière révision : 2026-10-02._

> Mémo : ce que l'app stocke **sur le téléphone**, dans quelle structure, quand c'est écrit/effacé.
> Pendant, la base Cloudflare (classement en ligne) est décrite dans `CLOUDFLARE_CONFIG.md`.
> Source de vérité : `lib/database/settings_database.dart` et `lib/models/app_settings.dart`.

---

## 1. Vue d'ensemble

### Remise à zéro demandée par le joueur

L'icône de nettoyage à l'accueil demande confirmation avant d'effacer la partie en cours,
les records et solutions découvertes, l'historique personnel, l'acuité cumulée par pièce,
les statistiques Duo et les résultats locaux des Défis. Les trois tables de jeu et le JSON
du profil sont mis à jour dans une seule transaction ; en cas d'erreur, la purge est annulée.
La partie gardée en mémoire et son chrono sont ensuite vidés pour empêcher sa resauvegarde.

L'identifiant joueur, les pseudos, les réglages, les consentements et les niveaux Solo
débloqués sont conservés. Aucun score Cloudflare n'est supprimé. Un Défi déjà soumis reste
soumis côté serveur : effacer son résultat local ne permet pas de remplacer le score en ligne.
Le schéma et sa version ne changent pas.

### Choix du niveau Solo

Le joueur peut choisir entre les niveaux 1 et `currentLevel` à chaque nouvelle partie Solo.
Ce choix ne modifie pas `currentLevel` : seul le niveau courant réussi sans aide fait avancer
la progression. Le niveau choisi est conservé dans la taille de `CurrentGame`, avec
`isProgression` vrai seulement pour le niveau courant. Annuler le sélecteur conserve la partie.

**Une seule base, locale, `drift`/SQLite** — aucun cloud, aucun `SharedPreferences`, aucun fichier à
côté.

| Champ | Valeur |
|---|---|
| Fichier | `pentapol_settings.db` |
| Emplacement | dossier *Documents* de l'app (`getApplicationDocumentsDirectory`) |
| Techno | `drift` (SQLite natif) |
| `schemaVersion` | **11** |
| Migration | `destructiveFallback` — **efface et recrée** à tout changement de version |

> ⚠️ **Réécriture destructive.** Tant que l'app n'est pas publiée, un changement de `schemaVersion`
> **efface toute la base** au prochain lancement (réglages, partie en cours, records). C'est voulu
> (pas de migration à écrire en développement). **À remplacer par une vraie migration avant la
> première soumission App Store** (voir `CHECKLIST_APPSTORE.md`).

> **Portée** : purement local. **Désinstaller l'app efface tout** — y compris l'identité 128 bits
> (`playerId`), donc l'historique de classement en ligne. Rien n'est synchronisé ni transférable.

---

## 2. Les quatre tables

### `Settings` — les réglages (clé/valeur)
Une seule ligne utile, clé `app_settings`, valeur = **tout `AppSettings` en JSON**. Ajouter/retirer
un champ ne demande **aucune migration** (c'est du JSON dans une colonne texte).

Champs de `AppSettings` (voir `app_settings.dart`) :

| Champ | Rôle |
|---|---|
| `ui`, `game`, `duel` | préférences (affichage, jeu, duel) |
| `userName` | pseudo du joueur (saisi au 1er succès) |
| `currentLevel` | niveau de progression solo (1..9), avancé uniquement par une réussite sans lampe jaune |
| `pieceAcuityTotals` | par pentomino : poses définitives, minimum théorique et isométries réelles cumulés |
| `attemptHistory` | au plus 20 tentatives Solo par taille, terminées ou abandonnées, pour le bilan personnel |
| `playerId` | **identité 128 bits** (32 hex) — clé du joueur pour le classement en ligne, distincte du pseudo. Générée à la 1re soumission de défi. |

### `CurrentGame` — la partie en cours (une seule ligne, `id = 0`, écrasée)
Permet de **reprendre** une partie interrompue. Ne stocke **ni le plateau** (reconstruit depuis
`placedPieces`) **ni les solutions** (dans les `.bin`).

| Colonne | Contenu |
|---|---|
| `sizeName` | taille (`PentoscopeSize.name`, ex. `size6x10`) |
| `pieceIds` | le tirage (`'1,2,3,…'`) |
| `solutionCount` | nombre de solutions du tirage |
| `placedPieces` | JSON `[{id,pos,x,y}, …]` — les pièces posées |
| `geometryState` | JSON versionné : barème figé, pénalités, compteurs par pièce et diagnostic du premier placement |
| `positionIndices` | JSON `{pieceId: orientation}` — orientations courantes |
| `initialOrientations` | JSON — le **rack distribué** (figé), pour l'acuité (🟡) |
| `elapsedSeconds` | temps écoulé |
| `isometryCount`, `translationCount`, `deleteCount`, `hintCount`, `faultCount` | compteurs (voir maillots) |
| `isProgression` | la partie fait-elle avancer le niveau |
| `savedAt` | horodatage |

**Écrite** après chaque pose/retrait et au passage en arrière-plan. **Effacée** à la complétion et au
démarrage d'une partie neuve. **Non écrite** en multijoueur ni en **défi** (éphémère).

Le réglage du barème suivant est dans `AppSettings.game.geometryRules`. Le barème de la
partie courante est indépendant : modifier le réglage ne modifie pas son snapshot.
À l'insertion, `id: Value(0)` est explicite (un INTEGER PRIMARY KEY omis reçoit 1 malgré
DEFAULT 0). Le test de reprise vérifie qu'il reste exactement une ligne d'identifiant 0.

Pendant le calibrage Géométrie, les parties solo expérimentales n'écrivent pas les tables
ci-dessous, même avec les valeurs initiales. Voir [Barème Géométrie](BAREME_GEOMETRIE.md).

### `SolvedSolutions` — records des rectangles complets (une ligne par solution découverte)
Clé `(board, solutionNumber)`. Pour le 6×10 (et, à terme, 5×12/4×15).

| Colonne | Contenu |
|---|---|
| `board`, `solutionNumber` | quelle solution (ex. `6x10`, n° 1..9356) |
| `timesSolved` | nombre de fois résolue |
| `bestAcuityMinIso` + `bestAcuityIsoCount` | 🟡 meilleur score d'acuité (ingrédients bruts, plafonné à 100 %) |
| `bestFaults` | 🔴 moins de fautes (culs-de-sac jaune→rouge) |
| `bestTimeSeconds` | 🟢 meilleur temps |
| `firstSolvedAt`, `lastSolvedAt` | horodatages |

### `PuzzleStats` — records des tailles à pièces tirées (un agrégat par taille)
Clé `sizeName`. Mêmes trois bests que ci-dessus, plus `completed` (nombre de complétions).

> Les trois bests sont **nullables** et **indépendants** (ils peuvent venir de trois parties
> différentes). Une partie résolue **avec aide** (`hintCount > 0`) n'est pas enregistrée :
> aucun compteur de réussite, record ni entrée dans l'historique local. Une partie de **défi** (mode classé) **n'écrit pas** ici (son classement
> est en ligne).

---

### Historique borné du bilan

`AppSettings.attemptHistory` conserve un résumé, pas le journal des gestes. Une tentative Solo est
enregistrée à la victoire ou lorsqu'une partie commencée est volontairement remplacée par un nouveau
puzzle. Un retour à l'accueil, une mise en arrière-plan ou une fermeture de l'app ne constitue pas
un abandon : `CurrentGame` permet la reprise.

Chaque résumé contient : taille, état terminé/abandonné, durée, fautes, isométries, translations,
retraits, aides, nombre de pièces encore posées et résultat du premier placement. L'historique est
borné aux **20 dernières tentatives de chaque taille**. Les Défis, le Training et le multijoueur
restent exclus du bilan Solo.

## 3. Ce qui n'est PAS stocké (et pourquoi)

- **Le plateau** : reconstruit depuis `placedPieces` (`_rebuildPlateau`).
- **Les solutions** : dans les assets `.bin`, jamais dupliquées en base.
- **Le journal détaillé de chaque geste** : seules les synthèses bornées des tentatives sont gardées.

---

## 4. Inspecter la base (développement)

La base vit dans le conteneur de l'app (device/simulateur). En pratique, on l'observe via les
**écrans** (Mes records, reprise de partie) plutôt qu'en SQL. Il n'y a **plus** d'écran de debug
(`DatabaseDebugScreen` retiré).

> ⚠️ `settings_database.g.dart` (code drift généré) est **gitignoré** : après un `pull`, régénérer
> par `dart run build_runner build --delete-conflicting-outputs`.

---

## 5. Voir aussi

- `CLOUDFLARE_CONFIG.md` — la base **en ligne** (classement du défi).
- `MANUEL_DEFIS_ET_MAILLOTS.md` — le sens des compteurs et des maillots.
- `PLAN_PERSISTANCE.md` — le plan d'origine de la persistance (les étapes, la réécriture destructive
  et sa date de péremption).
- `CHECKLIST_APPSTORE.md` — **retirer la stratégie destructive** avant publication.
