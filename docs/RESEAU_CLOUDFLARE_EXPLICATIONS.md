# Pentapol — comprendre le réseau et Cloudflare

> Rédigé le **2026-11-11 à 07:07 CET**.
> Explications pour Paul ; fonctionnement actuel distingué des propositions.
> Les tarifs sont ceux consultés le 2026-11-11 et devront être revérifiés.

## 1. D1 fait bien partie de Cloudflare

**Cloudflare est le fournisseur. Workers, D1 et Durable Objects sont trois de ses services.**
Ils sont administrés depuis le même compte ; ce ne sont pas trois hébergeurs différents.

| Service Cloudflare | Rôle dans Pentapol |
|---|---|
| **Workers** | Exécutent les programmes serveurs : recevoir une demande, vérifier les données et préparer une réponse. |
| **D1** | Conserve les résultats dans une base de données SQL fondée sur SQLite. |
| **Durable Objects** | Coordonnent les salles du mode Duo et les échanges entre joueurs. |

Le téléphone contient l'application Flutter. Cloudflare héberge la partie serveur.

## 2. Ce qui reste sur le téléphone

Le plateau, la manipulation des pièces, les solutions embarquées, le chronomètre,
les statistiques personnelles et les sauvegardes locales ne demandent pas un serveur
pour fonctionner. Le Solo et la découverte peuvent fonctionner sans Internet.

Le départ du défi quotidien est lui aussi déterminé localement, à partir de la date
UTC, de la taille, de la version des règles et du corpus embarqué. Les joueurs ayant
la même version obtiennent ainsi le même défi, avec ou sans réseau.

Le réseau sert principalement à **partager les résultats et consulter les classements**,
ainsi qu'à **jouer en Duo**.

## 3. Le trajet d'un résultat de défi

```text
Application sur le téléphone
          ↕ HTTPS
Worker Cloudflare du classement
          ↕ requêtes SQL
Base D1 « pentapol-defi »
```

1. Le joueur termine un défi.
2. S'il a accepté le partage, l'application envoie le résultat au Worker.
3. Le Worker vérifie les champs et leur cohérence, puis enregistre le score dans D1.
4. Pour afficher un classement, l'application interroge le Worker.
5. Celui-ci consulte D1, calcule le classement demandé et renvoie les lignes à afficher.

Le Worker ne rejoue pas la partie pour prouver le score : les mesures viennent de
l'application. En cas d'échec d'envoi, un score peut être conservé localement pour
être renvoyé plus tard.

L'adresse actuelle du serveur de classement est :
pentapol-defi.pentapml.workers.dev.
Un domaine personnel n'est pas nécessaire pour ce fonctionnement.

## 4. Les données et les pseudos

Une ligne de score contient notamment le jour, le niveau, le temps, les compteurs
de coups, le pseudo, le qualificatif facultatif et l'identifiant du joueur.

**Le pseudo n'est pas l'identité technique.** Plusieurs personnes peuvent s'appeler
« Paul ». Le `playerId` distingue leurs résultats ; le nom public reste libre.
Le qualificatif facultatif permet d'afficher, par exemple, « Paul · Lyon » ou
« Paul · Hibou ». Il peut désigner une ville, une région ou un surnom ; aucune rue
ni adresse précise n'est demandée.

Le champ se trouve dans **Paramètres → Classement en ligne → Ville ou qualificatif**.
Il accompagne les prochains scores ; modifier le profil ne réécrit pas les anciens.
La ligne du joueur est marquée « Vous » lorsqu'elle figure dans les résultats affichés.

## 5. Les tables visibles dans D1

Dans la base `pentapol-defi` :

| Table | Contenu |
|---|---|
| `_cf_KV` | Table interne de Cloudflare : la conserver. |
| `challenges` | Définitions composées des défis, conservées pour les anciens clients et outils. Le défi version 3 de l'app est déterminé localement. |
| `scores` | Résultats des joueurs, utilisés pour les classements. |

Ces données sont distinctes de la base SQLite locale de chaque téléphone.

Pour lister les tables dans la console SQL de D1 :

```sql
SELECT name FROM sqlite_master WHERE type = 'table';
```

Pour voir les vingt derniers scores :

```sql
SELECT * FROM scores ORDER BY created_at DESC LIMIT 20;
```

Pour voir les colonnes et compter les scores :

```sql
PRAGMA table_info(scores);
SELECT COUNT(*) AS nombre FROM scores;
```

**Remise à zéro définitive de tous les résultats**, uniquement si elle est voulue :

```sql
DELETE FROM scores;
```

Cette commande conserve les tables et les définitions des défis. Elle ne remet pas
à zéro les statistiques ni la progression sur les téléphones. Des scores locaux en
attente d'envoi peuvent réapparaître ensuite. Ne pas utiliser `schema.sql` pour ce
nettoyage : il détruit et recrée aussi la table `challenges`.

Procédure complète : [README du serveur](../server/README.md).

## 6. Faut-il garder les scores des jours précédents ?

**Recommandation : oui.** Les classements semaine et mois les utilisent déjà.
On affiche le jour ou la période souhaitée en filtrant les données ; il n'est pas
nécessaire de vider la base chaque jour.

Les défis variant selon le jour, leurs temps bruts ne se comparent pas directement.
Les classements cumulés utilisent des points calculés à partir du classement de
chaque défi.

Une conservation détaillée pendant **un an** a été proposée dans la discussion.
C'est une piste à décider, **pas une purge automatique déjà mise en place**.
Le volume réel et les besoins des joueurs guideront cette décision.

## 7. Afficher son rang avec beaucoup de joueurs

Proposition discutée, **pas encore entièrement implémentée** :

- Sur l'accueil : les trois premiers et la place personnelle du joueur.
- Dans le détail : classement centré sur soi, avec cinq joueurs devant et derrière.
- Un accès aux premiers et, éventuellement, un pourcentage situant le joueur dans
  le même défi du même jour et du même niveau.

Le serveur calculerait la place et renverrait seulement les lignes nécessaires,
plutôt que de faire télécharger tout le classement. Les règles d'ex æquo restent
à préciser pour cette évolution.

## 8. Le mode Duo utilise un autre trajet

```text
Téléphone du joueur A ── WebSocket ──┐
                                   ├── Worker Duo / Durable Object de la salle
Téléphone du joueur B ── WebSocket ──┘
```

Contrairement à une demande ponctuelle de classement, la connexion WebSocket
reste ouverte pendant la partie pour échanger les actions. Le Durable Object
coordonne les joueurs d'une salle. Le serveur Duo est distinct du Worker des
classements ; sa consommation n'est pas comprise dans l'estimation ci-dessous.

## 9. Coût estimatif pour 1 000 joueurs

Le nombre de comptes ne suffit pas : le coût dépend des joueurs **actifs**, du
nombre de scores et de la fréquence des consultations.

Hypothèse discutée : **1 000 joueurs actifs chaque jour, trois défis terminés chacun**.

| Activité | Volume estimé |
|---|---:|
| Scores par jour | 3 000 |
| Scores sur un mois de trente jours | 90 000 |
| Scores sur 365 jours | 1 095 000 |

Tarifs officiels consultés le 2026-11-11, en dollars américains :

| Élément | Gratuit | Forfait Workers payant |
|---|---|---|
| Abonnement Workers | 0 $ | À partir de 5 $/mois |
| Requêtes Workers | 100 000/jour | 10 millions/mois incluses |
| Lectures D1 | 5 millions de lignes/jour | 25 milliards de lignes/mois incluses |
| Écritures D1 | 100 000 lignes/jour | 50 millions de lignes/mois incluses |
| Stockage D1 total inclus | 5 Go | 5 Go |

Au-delà des inclusions payantes : requêtes Workers à 0,30 $ par million ; lectures
D1 à 0,001 $ par million de lignes ; écritures D1 à 1 $ par million de lignes ;
stockage D1 à 0,75 $ par Go-mois supplémentaire. Le temps CPU du Worker est aussi
facturé au-delà de son inclusion : 30 millions de millisecondes par mois, puis
0,02 $ par million de millisecondes supplémentaires.

**Estimation de travail : environ 5 à 10 $/mois hors taxes pour défis et classements**,
à confirmer par les mesures. Ce n'est ni un devis, ni un plafond garanti, ni le prix
de tous les services Cloudflare du compte. Le Duo est exclu de cette estimation.

Le principal point à surveiller est la lecture des classements. D1 compte les
lignes **examinées par SQL**, pas seulement les cinq noms finalement affichés.
Les index comptent aussi dans le stockage et peuvent ajouter des écritures.
Garder un historique n'entraîne donc pas un prix fixe par score ou par joueur.

L'accueil demande actuellement neuf classements par chargement du panneau.
Un cache court partagé entre les joueurs réduirait les calculs répétés. **C'est
une amélioration proposée, pas un cache déjà déployé.**

Sur le forfait gratuit, dépasser le quota quotidien D1 peut bloquer les requêtes
jusqu'à sa remise à zéro. Le gratuit ne garantit donc pas la disponibilité pour
1 000 joueurs actifs, même si les écritures sont peu nombreuses.

Sources : [tarifs Workers](https://developers.cloudflare.com/workers/platform/pricing/)
et [tarifs D1 et définition des lectures](https://developers.cloudflare.com/d1/platform/pricing/).
Pour confirmer le budget, mesurer les requêtes, le CPU, les lignes lues/écrites et
le stockage dans le tableau de bord Cloudflare.

## 10. À quoi sert Wrangler ?

**Wrangler est l'outil d'administration sur le Mac**, utilisé pour se connecter à
Cloudflare, déployer les Workers et exécuter des commandes sur D1. Il ne fait pas
partie de l'application des joueurs.

La connexion d'administration se fait depuis `server/` avec `npx wrangler login`.
Elle est distincte du consentement des joueurs à partager leurs scores.

Déployer le serveur ne met pas à jour l'app installée sur un iPhone : les nouveaux
écrans et champs Flutter demandent une nouvelle construction et installation de
l'application, puis une distribution par les stores lorsque l'app sera publiée.
