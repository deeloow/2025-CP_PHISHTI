<?php
require_once __DIR__ . '/config.php';

try {
    $pdo = db_connect();
    $session = require_auth($pdo);

    json_response([
        'user' => [
            'id' => (int)$session['user_id'],
            'email' => $session['email'],
            'displayName' => $session['display_name'],
        ],
    ]);
} catch (Throwable $e) {
    json_response(['error' => 'Server error', 'detail' => $e->getMessage()], 500);
}
?>


