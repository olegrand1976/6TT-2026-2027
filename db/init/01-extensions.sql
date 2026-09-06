-- =============================================================================
-- Joue automatiquement par l'entrypoint postgres a la CREATION du volume.
-- Pour rejouer : docker compose down -v && docker compose up -d
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- Pas d'extension uuid-ossp : gen_random_uuid() est natif depuis PostgreSQL 13.

-- ---------------------------------------------------------------------------
-- Table de demonstration : echantillons de telemetrie de course.
-- L'embedding sert a comparer des styles de pilotage / trajectoires.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS telemetry_samples (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    driver      text        NOT NULL,
    track       text        NOT NULL,
    lap_time_ms integer     NOT NULL,
    -- [vitesse_moy_norm, agressivite_freinage, regularite_trajectoire]
    embedding   vector(3)   NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS telemetry_samples_embedding_idx
    ON telemetry_samples USING hnsw (embedding vector_cosine_ops);

INSERT INTO telemetry_samples (driver, track, lap_time_ms, embedding)
SELECT * FROM (VALUES
    ('alpha',  'monaco', 92140, '[0.91, 0.78, 0.62]'::vector),
    ('bravo',  'monaco', 94870, '[0.72, 0.41, 0.88]'::vector),
    ('charlie','monaco', 91020, '[0.95, 0.83, 0.55]'::vector),
    ('delta',  'spa',    88310, '[0.88, 0.35, 0.91]'::vector)
) AS seed(driver, track, lap_time_ms, embedding)
WHERE NOT EXISTS (SELECT 1 FROM telemetry_samples);
