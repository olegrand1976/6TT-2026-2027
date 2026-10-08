CREATE TABLE IF NOT EXISTS drivers (
    name text PRIMARY KEY,
    team text NOT NULL,
    main_color text NOT NULL DEFAULT '#58a6ff'
);

-- Volume déjà créé sans cette colonne (replays d'anciennes versions du lab).
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS main_color text NOT NULL DEFAULT '#58a6ff';

INSERT INTO drivers (name, team, main_color) VALUES
    ('NeonSkid', 'Drift Squad', '#a855f7'),
    ('TurboZ', 'Velocity Crew', '#f97316'),
    ('PixelRider', 'Rac6TT Academy', '#22c55e'),
    ('ShadowDrift', 'Night Runners', '#6366f1')
ON CONFLICT (name) DO NOTHING;
