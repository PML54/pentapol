-- Schema D1 du defi quotidien. En developpement, supprimer les anciennes tables avant application.
DROP TABLE IF EXISTS scores;
DROP TABLE IF EXISTS challenges;

CREATE TABLE challenges (
  version        INTEGER NOT NULL,
  day            TEXT    NOT NULL,
  size           INTEGER NOT NULL,
  mask           INTEGER NOT NULL,
  rack           TEXT    NOT NULL,
  solution_count INTEGER NOT NULL,
  PRIMARY KEY (version, day, size)
);

CREATE TABLE scores (
  version    INTEGER NOT NULL,
  day        TEXT    NOT NULL,
  size       INTEGER NOT NULL,
  player_id  TEXT    NOT NULL,
  pseudo     TEXT    NOT NULL,
  min_iso    INTEGER NOT NULL,
  iso_count  INTEGER NOT NULL,
  moves      INTEGER NOT NULL,
  faults     INTEGER NOT NULL,
  time_ms    INTEGER NOT NULL,
  grid       TEXT    NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (version, day, size, player_id)
);

CREATE INDEX scores_partition ON scores (version, day, size);
