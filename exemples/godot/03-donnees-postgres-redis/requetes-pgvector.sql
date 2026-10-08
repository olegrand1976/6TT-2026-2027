-- Lab 03 — à exécuter dans psql (voir README)
\echo 'Extensions'
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';

\echo 'Échantillons télémétrie'
SELECT driver, track, lap_time_ms, embedding::text
FROM telemetry_samples
ORDER BY lap_time_ms;

\echo 'Similarité cosinus (style proche de alpha)'
SELECT driver, lap_time_ms,
       embedding <=> '[0.91, 0.78, 0.62]'::vector AS distance
FROM telemetry_samples
ORDER BY distance ASC
LIMIT 3;
