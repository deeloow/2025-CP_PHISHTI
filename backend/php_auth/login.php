<?php
require_once __DIR__ . '/config.php';

try {
    $pdo = db_connect();
    $body = get_json_body();

    $email = trim(strtolower($body['email'] ?? ''));
    $password = $body['password'] ?? '';

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        json_response(['error' => 'Invalid email'], 400);
    }

    $stmt = $pdo->prepare('SELECT id, password_hash, display_name FROM users WHERE email = :e');
    $stmt->execute([':e' => $email]);
    $user = $stmt->fetch();
    if (!$user || !password_verify($password, $user['password_hash'])) {
        json_response(['error' => 'Invalid credentials'], 401);
    }

    // Check if email is verified
    $stmt = $pdo->prepare('SELECT id FROM email_verifications WHERE user_id = :u AND verified_at IS NOT NULL');
    $stmt->execute([':u' => $user['id']]);
    if (!$stmt->fetch()) {
        json_response(['error' => 'Email not verified. Please check your email for verification code.'], 403);
    }

    // Create new session (30 days)
    $token = generate_token(32);
    $stmt = $pdo->prepare('INSERT INTO sessions (user_id, token, expires_at) VALUES (:u, :t, DATE_ADD(NOW(), INTERVAL 30 DAY))');
    $stmt->execute([':u' => $user['id'], ':t' => $token]);

    json_response([
        'user' => [
            'id' => (int)$user['id'],
            'email' => $email,
            'displayName' => $user['display_name'],
        ],
        'token' => $token,
    ]);
} catch (Throwable $e) {
    json_response(['error' => 'Server error', 'detail' => $e->getMessage()], 500);
}
?>


