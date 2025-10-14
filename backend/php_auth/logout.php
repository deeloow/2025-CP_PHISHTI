<?php
require_once __DIR__ . '/config.php';

try {
    $pdo = db_connect();
    $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (stripos($auth, 'Bearer ') !== 0) {
        json_response(['ok' => true]); // idempotent
    }
    $token = substr($auth, 7);
    $stmt = $pdo->prepare('DELETE FROM sessions WHERE token = :t');
    $stmt->execute([':t' => $token]);
    json_response(['ok' => true]);
} catch (Throwable $e) {
    json_response(['error' => 'Server error', 'detail' => $e->getMessage()], 500);
}
?>


