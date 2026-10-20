CREATE TABLE IF NOT EXISTS backup_probe (
    id integer PRIMARY KEY,
    note text NOT NULL
);

INSERT INTO backup_probe (id, note)
VALUES (1, 'compose-templates')
ON CONFLICT (id) DO NOTHING;
