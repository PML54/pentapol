-- Schéma D1 du service de classement du défi de la semaine (Pentapol, CDC §7).
-- Appliquer : wrangler d1 execute pentapol-defi --file=schema.sql   (voir README.md).
--
-- Deux tables :
--   challenges — la DÉFINITION d'un défi (composable à la main, autorité serveur, §7 Acté 1).
--   scores     — un essai par (joueur, défi), quatre maillots (§7 Acté 4-5).

-- Définition d'un défi : (taille, masque, rack). Clé (version, semaine, taille).
-- Alimentée par l'admin (composition à la main) ou par un job qui téléverse la dérivation Dart.
CREATE TABLE IF NOT EXISTS challenges (
  version INTEGER NOT NULL,
  week    INTEGER NOT NULL,
  size    INTEGER NOT NULL,        -- index de PentoscopeSize
  mask    INTEGER NOT NULL,        -- masque 12 bits des pièces
  rack    TEXT    NOT NULL,        -- JSON {"pieceId": orientation, ...}
  PRIMARY KEY (version, week, size)
);

-- Un score par joueur et par défi (§7.1 : premier essai, insertion unique — la clé primaire
-- refuse un second essai). Quatre maillots (§4.1 amendé) : acuité (minIso+isoCount bruts, §7.6),
-- coups, temps, Help. La grille est conservée pour l'AUDIT hors ligne (modèle confiance : le
-- serveur ne recalcule pas minIso ; cf. README « Vérification »).
CREATE TABLE IF NOT EXISTS scores (
  version    INTEGER NOT NULL,
  week       INTEGER NOT NULL,
  size       INTEGER NOT NULL,
  player_id  TEXT    NOT NULL,     -- identité 128 bits (§7.4), clé primaire du joueur
  pseudo     TEXT    NOT NULL,     -- étiquette d'affichage (non unique)
  min_iso    INTEGER NOT NULL,     -- 🟡 acuité = (min_iso+1)/(iso_count+1)
  iso_count  INTEGER NOT NULL,     -- 🟡
  moves      INTEGER NOT NULL,     -- ⚫ coups
  time_ms    INTEGER NOT NULL,     -- 🟢 temps
  help       INTEGER NOT NULL,     -- ⚪ sauvetages rouge→jaune
  grid       TEXT    NOT NULL,     -- grille terminée (audit) : ids de pièces par case
  created_at INTEGER NOT NULL,     -- epoch ms de la soumission
  PRIMARY KEY (version, week, size, player_id)
);

-- Un index de localité de partition suffit à cette échelle (une app payante à petite population) :
-- chaque classement lit la partition (version, week, size) puis trie en requête sur le maillot
-- demandé. Ajouter des index par maillot si une partition devient volumineuse.
CREATE INDEX IF NOT EXISTS scores_partition ON scores (version, week, size);
