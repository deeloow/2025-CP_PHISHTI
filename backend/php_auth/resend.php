<?php
require_once __DIR__ . '/config.php';

try {
    $pdo = db_connect();
    $body = get_json_body();

    $email = trim(strtolower($body['email'] ?? ''));

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        json_response(['error' => 'Invalid email'], 400);
    }

    // Get user
    $stmt = $pdo->prepare('SELECT id, display_name FROM users WHERE email = :e');
    $stmt->execute([':e' => $email]);
    $user = $stmt->fetch();
    if (!$user) {
        json_response(['error' => 'User not found'], 404);
    }

    // Check if already verified
    $stmt = $pdo->prepare('SELECT id FROM email_verifications WHERE user_id = :u AND verified_at IS NOT NULL');
    $stmt->execute([':u' => $user['id']]);
    if ($stmt->fetch()) {
        json_response(['error' => 'Email already verified'], 400);
    }

    // Generate new verification code
    $verificationCode = generate_verification_code();
    $stmt = $pdo->prepare('INSERT INTO email_verifications (user_id, verification_code, expires_at) VALUES (:u, :c, DATE_ADD(NOW(), INTERVAL 15 MINUTE))');
    $stmt->execute([':u' => $user['id'], ':c' => $verificationCode]);

    // Send verification email
    $emailSent = send_verification_email($email, $verificationCode, $user['display_name']);
    
    if (!$emailSent) {
        error_log("Failed to resend verification email to: $email");
    }

    json_response([
        'message' => 'Verification code sent successfully',
        'emailSent' => $emailSent,
    ]);
} catch (Throwable $e) {
    json_response(['error' => 'Server error', 'detail' => $e->getMessage()], 500);
}
?>
