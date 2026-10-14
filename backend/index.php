<?php
require_once __DIR__ . '/helpers.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$route = preg_match('#api/(.*)$#', $uri, $m) ? trim($m[1], '/') : '';
$method = $_SERVER['REQUEST_METHOD'];

const LEVELS = ['Débutant', 'Intermédiaire', 'Avancé'];

function course_fields(array $in): array {
    $title = trim($in['title'] ?? '');
    $desc = trim($in['description'] ?? '');
    $cat = trim($in['category'] ?? '');
    if ($title === '' || $desc === '' || $cat === '') fail('Titre, description et catégorie sont requis');
    if (strlen($cat) > 60) fail('Catégorie trop longue');
    $level = $in['level'] ?? 'Débutant';
    if (!in_array($level, LEVELS, true)) $level = 'Débutant';
    $color = $in['color'] ?? '#4F46E5';
    if (!preg_match('/^#[0-9a-fA-F]{6}$/', $color)) $color = '#4F46E5';
    $pub = array_key_exists('published', $in) ? ($in['published'] ? 1 : 0) : 1;
    return [$title, $desc, $cat, $level, $color, $pub];
}

function lesson_fields(array $in): array {
    $title = trim($in['title'] ?? '');
    $content = trim($in['content'] ?? '');
    if ($title === '' || $content === '') fail('Titre et contenu de la leçon requis');
    return [$title, $content, max(1, (int)($in['duration_min'] ?? 10))];
}

function admin_course(int $id): ?array {
    $st = db()->prepare('SELECT c.*,
        (SELECT COUNT(*) FROM lessons l WHERE l.course_id = c.id) AS lesson_count,
        (SELECT COUNT(*) FROM enrollments e WHERE e.course_id = c.id) AS enrolled_count
        FROM courses c WHERE c.id = ?');
    $st->execute([$id]);
    $c = $st->fetch();
    if (!$c) return null;
    $c = cast_row($c, ['id', 'lesson_count', 'enrolled_count'], ['published']);
    $ls = db()->prepare('SELECT id, title, content, duration_min, position FROM lessons WHERE course_id = ? ORDER BY position, id');
    $ls->execute([$id]);
    $c['lessons'] = array_map(function ($r) {
        $r = cast_row($r, ['id', 'duration_min', 'position']);
        $r['completed'] = false;
        return $r;
    }, $ls->fetchAll());
    return $c;
}

function student_courses(int $userId): array {
    $st = db()->prepare('SELECT c.id, c.title, c.color, c.category, c.level, c.description,
        (SELECT COUNT(*) FROM lessons l WHERE l.course_id = c.id) AS lesson_count,
        (SELECT COUNT(*) FROM lesson_progress p JOIN lessons l ON l.id = p.lesson_id
           WHERE l.course_id = c.id AND p.user_id = ?) AS done_count
        FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE e.user_id = ? ORDER BY e.enrolled_at DESC');
    $st->execute([$userId, $userId]);
    return array_map(fn($r) => cast_row($r, ['id', 'lesson_count', 'done_count']) + ['enrolled' => true], $st->fetchAll());
}

function unenroll(int $userId, int $courseId): void {
    db()->prepare('DELETE p FROM lesson_progress p JOIN lessons l ON l.id = p.lesson_id
                   WHERE p.user_id = ? AND l.course_id = ?')->execute([$userId, $courseId]);
    db()->prepare('DELETE FROM enrollments WHERE user_id = ? AND course_id = ?')->execute([$userId, $courseId]);
}

try {
    // ================= Authentification =================
    if ($route === 'register' && $method === 'POST') {
        $in = input();
        $name = trim($in['name'] ?? '');
        $email = strtolower(trim($in['email'] ?? ''));
        $pass = $in['password'] ?? '';
        if ($name === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Nom ou email invalide');
        if (strlen($pass) < 6) fail('Mot de passe : 6 caractères minimum');
        $st = db()->prepare('SELECT id FROM users WHERE email = ?');
        $st->execute([$email]);
        if ($st->fetch()) fail('Cet email est déjà utilisé', 409);
        db()->prepare("INSERT INTO users (name, email, password_hash, role) VALUES (?,?,?, 'student')")
            ->execute([$name, $email, password_hash($pass, PASSWORD_DEFAULT)]);
        $id = (int)db()->lastInsertId();
        json_out(['token' => make_token($id), 'user' => current_user($id)], 201);
    }

    if ($route === 'login' && $method === 'POST') {
        $in = input();
        $st = db()->prepare('SELECT * FROM users WHERE email = ?');
        $st->execute([strtolower(trim($in['email'] ?? ''))]);
        $u = $st->fetch();
        if (!$u || !password_verify($in['password'] ?? '', $u['password_hash'])) fail('Identifiants incorrects', 401);
        json_out(['token' => make_token((int)$u['id']), 'user' => current_user((int)$u['id'])]);
    }

    // ================= Routes protégées =================
    $uid = auth_user_id();
    $me = current_user($uid);

    if ($route === 'me' && $method === 'GET') {
        $c = db()->prepare('SELECT COUNT(*) FROM enrollments WHERE user_id = ?');
        $c->execute([$uid]);
        $l = db()->prepare('SELECT COUNT(*) FROM lesson_progress WHERE user_id = ?');
        $l->execute([$uid]);
        $me['courses_count'] = (int)$c->fetchColumn();
        $me['lessons_done'] = (int)$l->fetchColumn();
        json_out($me);
    }

    if ($route === 'me' && $method === 'PUT') {
        $in = input();
        $name = trim($in['name'] ?? $me['name']);
        if ($name === '') fail('Le nom est requis');
        if (!empty($in['new_password'])) {
            if (strlen($in['new_password']) < 6) fail('Mot de passe : 6 caractères minimum');
            $st = db()->prepare('SELECT password_hash FROM users WHERE id = ?');
            $st->execute([$uid]);
            if (!password_verify($in['current_password'] ?? '', $st->fetchColumn())) fail('Mot de passe actuel incorrect', 403);
            db()->prepare('UPDATE users SET name = ?, password_hash = ? WHERE id = ?')
                ->execute([$name, password_hash($in['new_password'], PASSWORD_DEFAULT), $uid]);
        } else {
            db()->prepare('UPDATE users SET name = ? WHERE id = ?')->execute([$name, $uid]);
        }
        json_out(current_user($uid));
    }

    // ---- Espace étudiant ----
    if ($route === 'courses' && $method === 'GET') {
        $st = db()->prepare('SELECT c.id, c.title, c.description, c.category, c.level, c.color, c.published,
              (SELECT COUNT(*) FROM lessons l WHERE l.course_id = c.id) AS lesson_count,
              (SELECT COUNT(*) FROM lesson_progress p JOIN lessons l ON l.id = p.lesson_id
                 WHERE l.course_id = c.id AND p.user_id = ?) AS done_count,
              EXISTS(SELECT 1 FROM enrollments e WHERE e.course_id = c.id AND e.user_id = ?) AS enrolled
            FROM courses c WHERE c.published = 1 ORDER BY c.id DESC');
        $st->execute([$uid, $uid]);
        json_out(array_map(fn($r) => cast_row($r, ['id', 'lesson_count', 'done_count'], ['enrolled', 'published']), $st->fetchAll()));
    }

    if (preg_match('#^courses/(\d+)$#', $route, $m) && $method === 'GET') {
        $cid = (int)$m[1];
        $st = db()->prepare('SELECT * FROM courses WHERE id = ?');
        $st->execute([$cid]);
        $course = $st->fetch();
        if (!$course || (!$course['published'] && $me['role'] !== 'admin')) fail('Cours introuvable', 404);
        $course = cast_row($course, ['id'], ['published']);
        $e = db()->prepare('SELECT 1 FROM enrollments WHERE user_id = ? AND course_id = ?');
        $e->execute([$uid, $cid]);
        $course['enrolled'] = (bool)$e->fetch();
        $ls = db()->prepare('SELECT l.id, l.title, l.content, l.duration_min, l.position,
                               (p.lesson_id IS NOT NULL) AS completed
                             FROM lessons l
                             LEFT JOIN lesson_progress p ON p.lesson_id = l.id AND p.user_id = ?
                             WHERE l.course_id = ? ORDER BY l.position, l.id');
        $ls->execute([$uid, $cid]);
        $course['lessons'] = array_map(fn($r) => cast_row($r, ['id', 'duration_min', 'position'], ['completed']), $ls->fetchAll());
        json_out($course);
    }

    if (preg_match('#^courses/(\d+)/enroll$#', $route, $m)) {
        if ($method === 'POST') {
            db()->prepare('INSERT IGNORE INTO enrollments (user_id, course_id) VALUES (?, ?)')->execute([$uid, (int)$m[1]]);
            json_out(['ok' => true]);
        }
        if ($method === 'DELETE') { unenroll($uid, (int)$m[1]); json_out(['ok' => true]); }
    }

    if (preg_match('#^lessons/(\d+)/complete$#', $route, $m) && $method === 'POST') {
        db()->prepare('INSERT IGNORE INTO lesson_progress (user_id, lesson_id) VALUES (?, ?)')->execute([$uid, (int)$m[1]]);
        db()->prepare('INSERT IGNORE INTO enrollments (user_id, course_id)
                       SELECT ?, course_id FROM lessons WHERE id = ?')->execute([$uid, (int)$m[1]]);
        json_out(['ok' => true]);
    }

    // ================= Espace administrateur =================
    if (strpos($route, 'admin/') === 0) {
        if ($me['role'] !== 'admin') fail('Accès réservé aux administrateurs', 403);

        if ($route === 'admin/stats' && $method === 'GET') {
            $q = fn($sql) => (int)db()->query($sql)->fetchColumn();
            $stats = [
                'students' => $q("SELECT COUNT(*) FROM users WHERE role = 'student'"),
                'courses' => $q('SELECT COUNT(*) FROM courses'),
                'published_courses' => $q('SELECT COUNT(*) FROM courses WHERE published = 1'),
                'lessons' => $q('SELECT COUNT(*) FROM lessons'),
                'enrollments' => $q('SELECT COUNT(*) FROM enrollments'),
                'completions' => $q('SELECT COUNT(*) FROM lesson_progress'),
            ];
            $stats['top_courses'] = array_map(fn($r) => cast_row($r, ['id', 'enrolled_count']), db()->query(
                'SELECT c.id, c.title, c.color, COUNT(e.user_id) AS enrolled_count
                 FROM courses c LEFT JOIN enrollments e ON e.course_id = c.id
                 GROUP BY c.id, c.title, c.color ORDER BY enrolled_count DESC, c.id LIMIT 5')->fetchAll());
            $stats['recent_students'] = array_map(fn($r) => cast_row($r, ['id']), db()->query(
                "SELECT id, name, email, created_at FROM users WHERE role = 'student' ORDER BY id DESC LIMIT 5")->fetchAll());
            json_out($stats);
        }

        // ---- Cours ----
        if ($route === 'admin/courses' && $method === 'GET') {
            $rows = db()->query('SELECT c.*,
                (SELECT COUNT(*) FROM lessons l WHERE l.course_id = c.id) AS lesson_count,
                (SELECT COUNT(*) FROM enrollments e WHERE e.course_id = c.id) AS enrolled_count
                FROM courses c ORDER BY c.id DESC')->fetchAll();
            json_out(array_map(fn($r) => cast_row($r, ['id', 'lesson_count', 'enrolled_count'], ['published']), $rows));
        }

        if ($route === 'admin/courses' && $method === 'POST') {
            db()->prepare('INSERT INTO courses (title, description, category, level, color, published) VALUES (?,?,?,?,?,?)')
                ->execute(course_fields(input()));
            json_out(admin_course((int)db()->lastInsertId()), 201);
        }

        if (preg_match('#^admin/courses/(\d+)$#', $route, $m)) {
            $cid = (int)$m[1];
            if ($method === 'GET') {
                $c = admin_course($cid);
                $c ? json_out($c) : fail('Cours introuvable', 404);
            }
            if ($method === 'PUT') {
                $f = course_fields(input());
                $f[] = $cid;
                db()->prepare('UPDATE courses SET title=?, description=?, category=?, level=?, color=?, published=? WHERE id=?')->execute($f);
                $c = admin_course($cid);
                $c ? json_out($c) : fail('Cours introuvable', 404);
            }
            if ($method === 'DELETE') {
                db()->prepare('DELETE FROM courses WHERE id = ?')->execute([$cid]);
                json_out(['ok' => true]);
            }
        }

        // ---- Leçons ----
        if (preg_match('#^admin/courses/(\d+)/lessons$#', $route, $m) && $method === 'POST') {
            $cid = (int)$m[1];
            [$t, $c, $d] = lesson_fields(input());
            db()->prepare('INSERT INTO lessons (course_id, title, content, duration_min, position)
                           SELECT ?, ?, ?, ?, COALESCE(MAX(position), 0) + 1 FROM lessons WHERE course_id = ?')
                ->execute([$cid, $t, $c, $d, $cid]);
            json_out(admin_course($cid), 201);
        }

        if (preg_match('#^admin/courses/(\d+)/reorder$#', $route, $m) && $method === 'POST') {
            $ids = input()['ids'] ?? [];
            if (!is_array($ids)) fail('Liste invalide');
            db()->beginTransaction();
            $st = db()->prepare('UPDATE lessons SET position = ? WHERE id = ? AND course_id = ?');
            foreach (array_values($ids) as $i => $lid) $st->execute([$i + 1, (int)$lid, (int)$m[1]]);
            db()->commit();
            json_out(['ok' => true]);
        }

        if (preg_match('#^admin/lessons/(\d+)$#', $route, $m)) {
            $lid = (int)$m[1];
            if ($method === 'PUT') {
                [$t, $c, $d] = lesson_fields(input());
                db()->prepare('UPDATE lessons SET title = ?, content = ?, duration_min = ? WHERE id = ?')->execute([$t, $c, $d, $lid]);
                json_out(['ok' => true]);
            }
            if ($method === 'DELETE') {
                db()->prepare('DELETE FROM lessons WHERE id = ?')->execute([$lid]);
                json_out(['ok' => true]);
            }
        }

        // ---- Étudiants ----
        if ($route === 'admin/students' && $method === 'GET') {
            $rows = db()->query('SELECT u.id, u.name, u.email, u.role, u.created_at,
                (SELECT COUNT(*) FROM enrollments e WHERE e.user_id = u.id) AS courses_count,
                (SELECT COUNT(*) FROM lesson_progress p WHERE p.user_id = u.id) AS lessons_done
                FROM users u ORDER BY u.id DESC')->fetchAll();
            json_out(array_map(fn($r) => cast_row($r, ['id', 'courses_count', 'lessons_done']), $rows));
        }

        if ($route === 'admin/students' && $method === 'POST') {
            $in = input();
            $name = trim($in['name'] ?? '');
            $email = strtolower(trim($in['email'] ?? ''));
            $pass = $in['password'] ?? '';
            $role = ($in['role'] ?? 'student') === 'admin' ? 'admin' : 'student';
            if ($name === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Nom ou email invalide');
            if (strlen($pass) < 6) fail('Mot de passe : 6 caractères minimum');
            $st = db()->prepare('SELECT id FROM users WHERE email = ?');
            $st->execute([$email]);
            if ($st->fetch()) fail('Cet email est déjà utilisé', 409);
            db()->prepare('INSERT INTO users (name, email, password_hash, role) VALUES (?,?,?,?)')
                ->execute([$name, $email, password_hash($pass, PASSWORD_DEFAULT), $role]);
            json_out(current_user((int)db()->lastInsertId()), 201);
        }

        if (preg_match('#^admin/students/(\d+)$#', $route, $m)) {
            $sid = (int)$m[1];
            if ($method === 'GET') {
                $u = current_user($sid);
                $u['courses'] = student_courses($sid);
                $u['courses_count'] = count($u['courses']);
                $u['lessons_done'] = array_sum(array_column($u['courses'], 'done_count'));
                json_out($u);
            }
            if ($method === 'DELETE') {
                if ($sid === $uid) fail('Vous ne pouvez pas supprimer votre propre compte', 403);
                db()->prepare('DELETE FROM users WHERE id = ?')->execute([$sid]);
                json_out(['ok' => true]);
            }
        }

        if (preg_match('#^admin/students/(\d+)/role$#', $route, $m) && $method === 'POST') {
            $sid = (int)$m[1];
            if ($sid === $uid) fail('Vous ne pouvez pas modifier votre propre rôle', 403);
            $role = (input()['role'] ?? '') === 'admin' ? 'admin' : 'student';
            db()->prepare('UPDATE users SET role = ? WHERE id = ?')->execute([$role, $sid]);
            json_out(['ok' => true, 'role' => $role]);
        }

        if (preg_match('#^admin/students/(\d+)/enroll$#', $route, $m) && $method === 'POST') {
            db()->prepare('INSERT IGNORE INTO enrollments (user_id, course_id) VALUES (?, ?)')
                ->execute([(int)$m[1], (int)(input()['course_id'] ?? 0)]);
            json_out(['ok' => true]);
        }

        if (preg_match('#^admin/students/(\d+)/courses/(\d+)$#', $route, $m) && $method === 'DELETE') {
            unenroll((int)$m[1], (int)$m[2]);
            json_out(['ok' => true]);
        }
    }

    fail('Route introuvable', 404);
} catch (PDOException $e) {
    if (db()->inTransaction()) db()->rollBack();
    fail('Erreur base de données', 500);
}
