<?php
require_once __DIR__ . '/config.php';

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
            DB_USER, DB_PASS,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
             PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
        );
    }
    return $pdo;
}

function json_out($data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function fail(string $message, int $code = 400): void {
    json_out(['error' => $message], $code);
}

function input(): array {
    $d = json_decode(file_get_contents('php://input'), true);
    return is_array($d) ? $d : [];
}

function b64u(string $s): string { return rtrim(strtr(base64_encode($s), '+/', '-_'), '='); }
function b64u_dec(string $s): string { return base64_decode(strtr($s, '-_', '+/')); }

function jwt_encode(array $payload): string {
    $h = b64u(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $p = b64u(json_encode($payload));
    $s = b64u(hash_hmac('sha256', "$h.$p", JWT_SECRET, true));
    return "$h.$p.$s";
}

function jwt_decode(string $token): ?array {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    [$h, $p, $s] = $parts;
    $expected = b64u(hash_hmac('sha256', "$h.$p", JWT_SECRET, true));
    if (!hash_equals($expected, $s)) return null;
    $data = json_decode(b64u_dec($p), true);
    if (!is_array($data) || ($data['exp'] ?? 0) < time()) return null;
    return $data;
}

function make_token(int $userId): string {
    return jwt_encode(['sub' => $userId, 'iat' => time(), 'exp' => time() + JWT_TTL]);
}

function auth_user_id(): int {
    $hdr = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!$hdr && function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) {
            if (strtolower($k) === 'authorization') $hdr = $v;
        }
    }
    if (!preg_match('/Bearer\s+(.+)/i', $hdr, $m)) fail('Non authentifié', 401);
    $data = jwt_decode(trim($m[1]));
    if (!$data) fail('Session expirée', 401);
    return (int)$data['sub'];
}

function cast_row(array $r, array $ints = [], array $bools = []): array {
    foreach ($ints as $k) if (array_key_exists($k, $r)) $r[$k] = (int)$r[$k];
    foreach ($bools as $k) if (array_key_exists($k, $r)) $r[$k] = (bool)$r[$k];
    return $r;
}

function current_user(int $uid): array {
    $st = db()->prepare('SELECT id, name, email, role, created_at FROM users WHERE id = ?');
    $st->execute([$uid]);
    $u = $st->fetch();
    if (!$u) fail('Compte introuvable', 401);
    $u['id'] = (int)$u['id'];
    return $u;
}
