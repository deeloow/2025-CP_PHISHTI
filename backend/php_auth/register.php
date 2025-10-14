<?php
require_once __DIR__ . '/config.php';

try {
    $pdo = db_connect();
    $body = get_json_body();

    $email = trim(strtolower($body['email'] ?? ''));
    $password = $body['password'] ?? '';
    $displayName = trim($body['displayName'] ?? '');

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        json_response(['error' => 'Invalid email'], 400);
    }
    if (strlen($password) < 6) {
        json_response(['error' => 'Password must be at least 6 characters'], 400);
    }

    // Check existing user
    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = :e');
    $stmt->execute([':e' => $email]);
    if ($stmt->fetch()) {
        json_response(['error' => 'Email already in use'], 409);
    }

    $hash = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare('INSERT INTO users (email, password_hash, display_name) VALUES (:e, :p, :d)');
    $stmt->execute([':e' => $email, ':p' => $hash, ':d' => $displayName]);
    $userId = (int)$pdo->lastInsertId();

    // Generate verification code
    $verificationCode = generate_verification_code();
    $stmt = $pdo->prepare('INSERT INTO email_verifications (user_id, verification_code, expires_at) VALUES (:u, :c, DATE_ADD(NOW(), INTERVAL 15 MINUTE))');
    $stmt->execute([':u' => $userId, ':c' => $verificationCode]);

    // Send verification email
    $emailSent = send_verification_email($email, $verificationCode, $displayName);
    
    // Log the verification code for development
    error_log("Registration successful for $email. Verification code: $verificationCode");

    json_response([
        'message' => 'Registration successful. Please check your email for verification code.',
        'email' => $email,
        'emailSent' => $emailSent,
    ], 201);
} catch (Throwable $e) {
    json_response(['error' => 'Server error', 'detail' => $e->getMessage()], 500);
}
?>


