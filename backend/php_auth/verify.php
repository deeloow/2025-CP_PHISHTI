<?php
require_once __DIR__ . '/config.php';

try {
    $pdo = db_connect();
    $body = get_json_body();

    $email = trim(strtolower($body['email'] ?? ''));
    $code = trim($body['code'] ?? '');

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        json_response(['error' => 'Invalid email'], 400);
    }
    if (strlen($code) !== 6 || !ctype_digit($code)) {
        json_response(['error' => 'Invalid verification code'], 400);
    }

    // Get user
    $stmt = $pdo->prepare('SELECT id, display_name FROM users WHERE email = :e');
    $stmt->execute([':e' => $email]);
    $user = $stmt->fetch();
    if (!$user) {
        json_response(['error' => 'User not found'], 404);
    }

    // Check verification code
    $stmt = $pdo->prepare('SELECT id FROM email_verifications WHERE user_id = :u AND verification_code = :c AND expires_at > NOW() AND verified_at IS NULL');
    $stmt->execute([':u' => $user['id'], ':c' => $code]);
    $verification = $stmt->fetch();
    
    if (!$verification) {
        json_response(['error' => 'Invalid or expired verification code'], 400);
    }

    // Mark as verified
    $stmt = $pdo->prepare('UPDATE email_verifications SET verified_at = NOW() WHERE id = :id');
    $stmt->execute([':id' => $verification['id']]);

    // Create session (30 days)
    $token = generate_token(32);
    $stmt = $pdo->prepare('INSERT INTO sessions (user_id, token, expires_at) VALUES (:u, :t, DATE_ADD(NOW(), INTERVAL 30 DAY))');
    $stmt->execute([':u' => $user['id'], ':t' => $token]);

    json_response([
        'message' => 'Email verified successfully',
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
