<?php
// Suppress warnings and errors for clean JSON responses
error_reporting(0);
ini_set('display_errors', 0);

// Basic configuration for database connection and CORS

// IMPORTANT: Change these values for your environment
// XAMPP default settings:
$DB_HOST = getenv('DB_HOST') ?: '127.0.0.1';
$DB_NAME = getenv('DB_NAME') ?: 'phishti_auth';
$DB_USER = getenv('DB_USER') ?: 'root';
$DB_PASS = getenv('DB_PASS') ?: ''; // XAMPP default is empty password

// Email configuration (for verification emails)
$SMTP_HOST = getenv('SMTP_HOST') ?: 'smtp.gmail.com';
$SMTP_PORT = getenv('SMTP_PORT') ?: 587;
$SMTP_USERNAME = getenv('SMTP_USERNAME') ?: 'your-email@gmail.com';
$SMTP_PASSWORD = getenv('SMTP_PASSWORD') ?: 'your-app-password';
$SMTP_FROM_EMAIL = getenv('SMTP_FROM_EMAIL') ?: 'your-email@gmail.com';
$SMTP_FROM_NAME = getenv('SMTP_FROM_NAME') ?: 'Phishti Detector';

function db_connect(): PDO {
    global $DB_HOST, $DB_NAME, $DB_USER, $DB_PASS;
    $dsn = "mysql:host={$DB_HOST};dbname={$DB_NAME};charset=utf8mb4";
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ];
    return new PDO($dsn, $DB_USER, $DB_PASS, $options);
}

function json_response($data, int $status = 200): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    // CORS (adjust origin in production)
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    echo json_encode($data);
    exit;
}

// Handle CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    json_response(['ok' => true]);
}

function get_json_body(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function generate_token(int $length = 32): string {
    return bin2hex(random_bytes($length));
}

function generate_verification_code(): string {
    return str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
}

function send_verification_email(string $to, string $code, string $displayName = ''): bool {
    global $SMTP_HOST, $SMTP_PORT, $SMTP_USERNAME, $SMTP_PASSWORD, $SMTP_FROM_EMAIL, $SMTP_FROM_NAME;
    
    // Log the code for development
    error_log("Verification code for $to: $code");
    
    // Check if Gmail credentials are configured
    if ($SMTP_USERNAME === 'your-email@gmail.com' || empty($SMTP_PASSWORD) || $SMTP_PASSWORD === 'your-app-password') {
        error_log("Gmail SMTP not configured. Please run setup_email.php to configure Gmail credentials.");
        return true; // Return true so registration doesn't fail
    }
    
    // Try to send email using Gmail SMTP
    try {
        $subject = 'Verify Your Email - Phishti Detector';
        $message = "
        <html>
        <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
            <div style='max-width: 600px; margin: 0 auto; padding: 20px;'>
                <div style='text-align: center; margin-bottom: 30px;'>
                    <h1 style='color: #00FF88; margin: 0;'>Phishti Detector</h1>
                </div>
                
                <h2 style='color: #333;'>Email Verification</h2>
                <p>Hello " . htmlspecialchars($displayName ?: 'User') . ",</p>
                <p>Thank you for registering with Phishti Detector. Please use the verification code below to activate your account:</p>
                
                <div style='text-align: center; margin: 30px 0;'>
                    <div style='background: #f5f5f5; padding: 20px; border-radius: 10px; display: inline-block;'>
                        <h3 style='color: #00FF88; font-size: 32px; letter-spacing: 5px; margin: 0; font-family: monospace;'>{$code}</h3>
                    </div>
                </div>
                
                <p><strong>Important:</strong> This code will expire in 15 minutes.</p>
                <p>If you didn't create an account, please ignore this email.</p>
                
                <hr style='border: none; border-top: 1px solid #eee; margin: 30px 0;'>
                <p style='color: #666; font-size: 14px;'>
                    Best regards,<br>
                    Phishti Detector Team
                </p>
            </div>
        </body>
        </html>
        ";
        
        // Use Gmail SMTP settings
        ini_set('SMTP', 'smtp.gmail.com');
        ini_set('smtp_port', '587');
        ini_set('sendmail_from', $SMTP_FROM_EMAIL);
        
        $headers = [
            'MIME-Version: 1.0',
            'Content-type: text/html; charset=UTF-8',
            'From: ' . $SMTP_FROM_NAME . ' <' . $SMTP_FROM_EMAIL . '>',
            'Reply-To: ' . $SMTP_FROM_EMAIL,
            'X-Mailer: PHP/' . phpversion(),
            'X-Priority: 3'
        ];
        
        $result = @mail($to, $subject, $message, implode("\r\n", $headers));
        
        if ($result) {
            error_log("Email sent successfully to: $to");
        } else {
            error_log("Failed to send email to: $to");
        }
        
        return $result;
    } catch (Exception $e) {
        error_log("Email sending failed: " . $e->getMessage());
        return true; // Still return true so registration doesn't fail
    }
    
    /*
    // Original email code (commented out for development)
    $subject = 'Verify Your Email - Phishti Detector';
    $message = "
    <html>
    <body>
        <h2>Email Verification</h2>
        <p>Hello " . htmlspecialchars($displayName ?: 'User') . ",</p>
        <p>Thank you for registering with Phishti Detector. Please use the verification code below to activate your account:</p>
        <h3 style='color: #00FF88; font-size: 24px; letter-spacing: 2px;'>{$code}</h3>
        <p>This code will expire in 15 minutes.</p>
        <p>If you didn't create an account, please ignore this email.</p>
        <br>
        <p>Best regards,<br>Phishti Detector Team</p>
    </body>
    </html>
    ";
    
    $headers = [
        'MIME-Version: 1.0',
        'Content-type: text/html; charset=UTF-8',
        'From: ' . $SMTP_FROM_NAME . ' <' . $SMTP_FROM_EMAIL . '>',
        'Reply-To: ' . $SMTP_FROM_EMAIL,
        'X-Mailer: PHP/' . phpversion()
    ];
    
    return mail($to, $subject, $message, implode("\r\n", $headers));
    */
}

function require_auth(PDO $pdo): array {
    $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (stripos($auth, 'Bearer ') !== 0) {
        json_response(['error' => 'Unauthorized'], 401);
    }
    $token = substr($auth, 7);
    $stmt = $pdo->prepare('SELECT s.id as session_id, s.user_id, u.email, u.display_name FROM sessions s JOIN users u ON u.id = s.user_id WHERE s.token = :t AND s.expires_at > NOW()');
    $stmt->execute([':t' => $token]);
    $row = $stmt->fetch();
    if (!$row) {
        json_response(['error' => 'Invalid or expired token'], 401);
    }
    return $row;
}
?>


