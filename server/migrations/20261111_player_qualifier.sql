-- Ajout compatible avec les scores existants ; ne pas rejouer schema.sql.
ALTER TABLE scores ADD COLUMN qualifier TEXT;
