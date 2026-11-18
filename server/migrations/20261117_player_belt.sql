-- Additive migration: preserve all existing scores and unknown belts as NULL.
ALTER TABLE scores ADD COLUMN belt INTEGER CHECK (belt BETWEEN 0 AND 6);
CREATE INDEX scores_player_belt ON scores (player_id, belt);
