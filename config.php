<?php
// Settings come from environment variables (set them on Render).
// Defaults below are for local XAMPP testing.
date_default_timezone_set('Asia/Kolkata');
function env($k, $d = '') { $v = getenv($k); return ($v === false || $v === '') ? $d : $v; }

// ---- CORS: only your frontend may call this API ----
$allowed = array_map('trim', explode(',', env('FRONTEND_ORIGIN', 'http://localhost:3000,http://localhost:5500,http://127.0.0.1:5500')));
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin && in_array($origin, $allowed, true)) { header('Access-Control-Allow-Origin: ' . $origin); header('Vary: Origin'); }
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Content-Type: application/json; charset=utf-8');
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') { http_response_code(204); exit; }

// ---- helpers ----
function respond($data, $code = 200) { http_response_code($code); echo json_encode($data); exit; }
function fail($code, $msg) { respond(['error' => $msg], $code); }
function body() { static $b = null; if ($b === null) $b = json_decode(file_get_contents('php://input'), true) ?: []; return $b; }
function must_post() { if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') fail(405, 'POST required.'); }

function db() {
    static $pdo = null;
    if ($pdo) return $pdo;
    $opt = [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC];
    if (env('DB_SSL') === '1') $opt[PDO::MYSQL_ATTR_SSL_CA] = '/etc/ssl/certs/ca-certificates.crt';
    try {
        $pdo = new PDO('mysql:host=' . env('DB_HOST', 'localhost') . ';port=' . env('DB_PORT', '3306') . ';dbname=' . env('DB_NAME', 'restaurant_db') . ';charset=utf8mb4',
            env('DB_USER', 'root'), env('DB_PASS', ''), $opt);
    } catch (PDOException $e) { fail(500, 'Database connection failed.'); }
    return $pdo;
}

// ---- signed tokens (works across Vercel and Render, no cookies needed) ----
function b64($s) { return rtrim(strtr(base64_encode($s), '+/', '-_'), '='); }
function unb64($s) { return base64_decode(strtr($s, '-_', '+/')); }
function secret() { return env('TOKEN_SECRET', 'dev-secret-change-me'); }
function make_token($role, $id, $ver) {
    $p = b64(json_encode(['r' => $role, 'i' => (int)$id, 'v' => (int)$ver, 'e' => time() + 7 * 86400]));
    return $p . '.' . b64(hash_hmac('sha256', $p, secret(), true));
}
function bearer() {
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!$h && function_exists('getallheaders')) { foreach (getallheaders() as $k => $v) if (strtolower($k) === 'authorization') $h = $v; }
    return preg_match('/^Bearer\s+(.+)$/i', $h, $m) ? trim($m[1]) : '';
}
// Returns the logged-in user (or admin) row, or stops with 401.
function auth($role) {
    $t = bearer();
    if (!$t || substr_count($t, '.') !== 1) fail(401, 'Please log in.');
    [$p, $sig] = explode('.', $t);
    if (!hash_equals(b64(hash_hmac('sha256', $p, secret(), true)), $sig)) fail(401, 'Invalid session.');
    $d = json_decode(unb64($p), true);
    if (!$d || $d['r'] !== $role || $d['e'] < time()) fail(401, 'Session expired. Please log in again.');
    $s = db()->prepare('SELECT * FROM ' . ($role === 'admin' ? 'admins' : 'users') . ' WHERE id=?');
    $s->execute([$d['i']]); $row = $s->fetch();
    if (!$row || (int)$row['token_version'] !== $d['v']) fail(401, 'Session expired. Please log in again.');
    return $row;
}
