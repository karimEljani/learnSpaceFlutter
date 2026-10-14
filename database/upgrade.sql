-- À exécuter UNIQUEMENT si vous avez déjà importé l'ancienne version de database.sql
USE learnspace;

ALTER TABLE users   ADD COLUMN role ENUM('student','admin') NOT NULL DEFAULT 'student' AFTER password_hash;
ALTER TABLE courses ADD COLUMN color VARCHAR(7) NOT NULL DEFAULT '#4F46E5',
                    ADD COLUMN published TINYINT(1) NOT NULL DEFAULT 1;

UPDATE courses SET color = '#0EA5E9' WHERE id = 2;
UPDATE courses SET color = '#10B981' WHERE id = 3;

-- Compte administrateur : admin@learnspace.com / admin123  (à changer !)
INSERT INTO users (name, email, password_hash, role) VALUES
('Administrateur', 'admin@learnspace.com', '$2y$10$m5/T6Rbb6ShUFxL1ygONaepRmA5X.RH3Mm63cuKPxoiXNAdfdXnDO', 'admin');
