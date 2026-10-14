CREATE DATABASE IF NOT EXISTS learnspace CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE learnspace;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('student','admin') NOT NULL DEFAULT 'student',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE courses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(60) NOT NULL,
  level ENUM('Débutant','Intermédiaire','Avancé') DEFAULT 'Débutant',
  color VARCHAR(7) NOT NULL DEFAULT '#4F46E5',
  published TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lessons (
  id INT AUTO_INCREMENT PRIMARY KEY,
  course_id INT NOT NULL,
  title VARCHAR(150) NOT NULL,
  content TEXT NOT NULL,
  duration_min INT DEFAULT 10,
  position INT NOT NULL DEFAULT 1,
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE TABLE enrollments (
  user_id INT NOT NULL,
  course_id INT NOT NULL,
  enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, course_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE TABLE lesson_progress (
  user_id INT NOT NULL,
  lesson_id INT NOT NULL,
  completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, lesson_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
);

INSERT INTO courses (id, title, description, category, level, color) VALUES
(1, 'Introduction à Flutter', 'Découvrez les bases de Flutter et créez votre première application mobile multiplateforme.', 'Mobile', 'Débutant', '#4F46E5'),
(2, 'PHP & API REST', 'Apprenez à construire une API REST sécurisée avec PHP et MySQL.', 'Backend', 'Intermédiaire', '#0EA5E9'),
(3, 'SQL pour tous', 'Maîtrisez les requêtes SQL, les jointures et la conception de bases de données.', 'Données', 'Débutant', '#10B981');

INSERT INTO lessons (course_id, title, content, duration_min, position) VALUES
(1, 'Qu''est-ce que Flutter ?', 'Flutter est un framework open source de Google permettant de créer des applications natives pour mobile, web et desktop à partir d''une seule base de code écrite en Dart.', 8, 1),
(1, 'Les widgets', 'Dans Flutter, tout est widget : texte, bouton, mise en page. Les widgets se composent en arbre. On distingue StatelessWidget (sans état) et StatefulWidget (avec état).', 12, 2),
(1, 'Mise en page', 'Row, Column et Stack permettent d''organiser les widgets. Expanded et Flexible contrôlent la répartition de l''espace disponible.', 12, 3),
(1, 'Navigation', 'Navigator.push et Navigator.pop gèrent la pile d''écrans. Pour des apps complexes, on peut utiliser go_router.', 10, 4),
(2, 'Principes REST', 'REST repose sur des ressources identifiées par des URL et manipulées via les verbes HTTP : GET, POST, PUT, DELETE.', 10, 1),
(2, 'PDO et MySQL', 'PDO offre une interface unifiée pour accéder aux bases de données. Utilisez toujours des requêtes préparées pour éviter les injections SQL.', 15, 2),
(2, 'Authentification JWT', 'Un JSON Web Token contient un en-tête, une charge utile et une signature. Le serveur vérifie la signature à chaque requête.', 15, 3),
(3, 'SELECT et WHERE', 'SELECT lit des données, WHERE filtre les lignes. Exemple : SELECT * FROM courses WHERE level = ''Débutant''.', 8, 1),
(3, 'Les jointures', 'INNER JOIN combine les lignes de deux tables ayant une valeur commune. LEFT JOIN conserve aussi les lignes sans correspondance.', 14, 2),
(3, 'Agrégations', 'COUNT, SUM, AVG, MIN et MAX calculent des valeurs sur des groupes de lignes définis par GROUP BY.', 12, 3);

-- Compte administrateur par défaut : admin@learnspace.com / admin123  (à changer !)
INSERT INTO users (name, email, password_hash, role) VALUES
('Administrateur', 'admin@learnspace.com', '$2y$10$m5/T6Rbb6ShUFxL1ygONaepRmA5X.RH3Mm63cuKPxoiXNAdfdXnDO', 'admin');
