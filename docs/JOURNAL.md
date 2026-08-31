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

## §ÉTAT — au 2026-08-31

### L'application

Un seul module de jeu, **Pentoscope** : tailles `size3x5`…`size10x5` (tirage d'un masque de
pièces parmi les solubles d'une table précalculée `subset_counts.bin` — le nombre de solutions
est connu et affiché au tirage) plus `size6x10` (rectangle complet, adossé aux 9356 solutions
pré-calculées). Plus le **multijoueur**, qui réutilise son provider. Démarrage direct sur
`PentoscopeGameScreen`, pas d'écran d'accueil. Plus de notion de difficulté.

### Chantiers terminés

- **Suppression du mode classique** — −3197 lignes, module, widgets, écran d'accueil.
- **Le 6×10 dans Pentoscope** — temps 1 et 2, `SolutionSource`, compteur de solutions.
- **Bilan de fin de partie** — bandeau non modal, score retiré, chronomètre corrigé.
- **Ergonomie hors plateau** — tailles ancrées sur le plateau, barre d'actions unique pour les
  deux orientations, ordre des zones aligné, écran de réglages minimal.
- **Persistance, étape 1** — Supabase, `bootstrap.dart` et `DatabaseDebugScreen` retirés.
- **Suppression de la difficulté puis tirages précalculés (étape A)** — `subset_counts.bin`
  (4096 × uint16, 8 Ko) donne le nombre de solutions de tout tirage 5×n ; le générateur tire un
  masque parmi les solubles (plus d'appel-boucle au solveur, plus de difficulté), le compte est
  affiché au dialogue avec « autre tirage ». Table validée contre `REFERENCE_TIRAGES.md` §2.

Leurs plans ont été **supprimés** une fois appliqués et testés (`MODUS_VIVENDI` §5).

### Chantiers ouverts

| chantier | document | reste à faire |
|---|---|---|
| **Tirages étape B** | `REFERENCE_TIRAGES.md` §8 B / §9 | **en cours.** Faits : commit 1 (corpus `solutions_corpus.bin`, 3,13 Mo, octet/case, 73 876 solutions) ; commit 2 (source unifiée — `LiveSolutionSource` supprimée, `CorpusSolutionSource` adosse **toutes** les tailles au corpus, appariement d'octets factorisé dans `common/byte_matching.dart`). Reste : commit 3 (sortir `PentoscopeSolver` du runtime — touche générateur + multijoueur), commit 4 (compteur décroissant **affiché** partout). Les 2 mesures §9 acquises : le pire `_solutionStatus` (38–78 ms) venait du solveur live des petites tailles, pas du comptage par table (~0,6 ms). **Décision : 2 sources table-backed** (6×10 via `SolutionMatcher`/BigInt pour son navigateur ; 5×n via corpus/bytes) plutôt qu'une seule classe — l'appariement, lui, est unifié |
| **Persistance** | `PLAN_PERSISTANCE.md` | étapes 2 à 4 : schéma + réécriture destructive, records, **partie en cours** |
| **Mise sur l'App Store** | `CHECKLIST_APPSTORE.md` | bloquants technique/produit/conformité — s'allonge au fil du travail |

**Priorité recommandée** : étape 4 de la persistance (la partie en cours n'est pas sauvegardée
— quitter l'app au milieu d'un 6×10 perd tout), puis la mesure n°2 pour décider de B.

### Documentation

`FONCTIONNEMENT.md` est la description de référence de l'application — elle absorbe depuis
le 2026-08-31 l'ancien `PENTOSCOPE.md`, devenu un doublon partiel une fois qu'il n'est resté
qu'un module de jeu. `UI_PROPERTIES_GUIDE.md`, guide Flutter générique sans rapport avec
l'état du projet, est supprimé. `REFERENCE_TIRAGES.md` est le **test d'acceptation** du
générateur de tirages (`tools/generate_subset_counts.dart`) : sa sortie doit reproduire les
nombres du §2 (ce que le générateur vérifie, exit 1 sinon).

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

Poussé jusqu'à `64ec104`. **Non poussés** : enrichissement `REFERENCE_TIRAGES.md` (cowork,
`ceff658`), byte-matcher (`ef669cf`), corpus étape B commit 1 (`86dcea6`), et le commit 2
(source unifiée corpus + ce journal). **À tester sur appareil** avant le commit 3 : jouer une
petite taille (5×10, 4×5) — jeu normal, sans à-coup.

> ⚠️ `settings_database.g.dart` (généré) est gitignoré : après un `pull`, régénérer par
> `dart run build_runner build --delete-conflicting-outputs`. `subset_counts.bin` **est** suivi.

---

## §PASSATIONS

> Les trois dernières seulement. Au-delà, `git log --oneline` dit la même chose en plus court.

**2026-08-31 — CLI → cowork (mesure n°2 + appariement Uint8List).** Mesure n°2 (§9) jouée sur
iPad en `--release`, affichage à l'écran (le debug WiFi crashe chez Paul). Le pire
`_solutionStatus` (38–78 ms) venait du **solveur backtracking live des petites tailles**
(`LiveSolutionSource.hasSolutionFrom`), **pas** du comptage par table : bench desktop sur les
9356 réelles = 23 µs en octets vs 318 µs en BigInt (13×), soit ~0,6 ms sur appareil. Conclusion :
B n'est pas conditionnée, elle est **motivée** — elle supprime ce solveur. Socle livré :
`SolutionMatcher.countCompatibleBytes` (Uint8List plat 9356×60, sans allocation), branché sur
`countFrom`/`hasSolutionFrom` du 6×10 ; `_mask` BigInt réservé aux chemins froids (navigateur,
index). Garde d'équivalence byte≡BigInt sur 10 000 plateaux (`test/solution_matcher_bytes_test.dart`).
`analyze` 0, `test` 7/7. **Enchaîne sur B.**

**2026-08-31 — CLI → cowork (tirages précalculés, étape A).** REFERENCE_TIRAGES §8 A appliquée
en 3 commits. **1** (`68188eb`) : `tools/generate_subset_counts.dart` (Flutter-free) + asset
`subset_counts.bin` (8 Ko) + `test/subset_counts_test.dart` ; `widget_test.dart` supprimé (suite
verte). Les 9 totaux reproduisent le §2 exactement (dont popcount 12 = 4040) ; **mesure n°1
acquise** : 9 parcours en 11,6 s → B non-sujet côté génération. **2** (`05f8039`) : `generate`
tire un masque par table (aucun appel-boucle au solveur), `solutionCount` **redevient
non-nullable** (annule le `int?`/`nullable()` du matin) ; `schemaVersion` **3→4** (règle n°6 : la
colonne rechange ; v3 a tourné sur l'iPad, un retour à v2 serait un downgrade → crash). **3**
(`af6a2d3`) : le tirage passe au dialogue (« n solutions » + « autre tirage »), masque transmis à
la partie. `analyze` 0 error, `test` vert. **Hors périmètre** (étape B) non touché : ni corpus,
ni `ListSolutionSource`, ni retrait de `PentoscopeSolver`. **Dû par Paul** (vérif §Affichage) :
le dialogue affiche un nombre plausible et « autre tirage » le change ; 3×5 → 7 tirages tous à 4 ;
nouvelles parties instantanées sur toutes les tailles (10×5 compris) ; base réécrite au 1er
lancement (v4). **Mesure n°2 pour B** (fluidité `_solutionStatus`) reste à instrumenter/jouer.

**2026-08-31 — CLI → cowork (suppression de la difficulté).** Fait ce matin en un commit
(`f1f26cf`), **révisé par l'étape A** : l'approche `findSolutionFrom`+boucle bornée et le
`nullable()` du matin sont annulés au profit du tirage par table. La suppression de la difficulté
elle-même (enum, generateEasy/Hard, SegmentedButton, main.dart) survit. `findAllSolutions` gardée.
(Rappels hérités : correctif iOS `SafeArea` `3f09e1d` ; réglage barre `k`=0.35 `034ddff` ;
regroupement des 7 constantes de réglage `af2f5e0`.)
