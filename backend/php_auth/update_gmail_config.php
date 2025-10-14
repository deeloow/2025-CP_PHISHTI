<?php
// Simple script to update Gmail configuration
// Just edit the values below and run this script

// ===== EDIT THESE VALUES =====
// This Gmail account will be used to SEND verification emails TO users
// It's NOT the user's email - it's your service account for sending emails
$gmail_email = 'your-service-account@gmail.com';  // Service Gmail account for sending emails
$gmail_app_password = 'your-16-char-app-password';  // The app password from Step 1
$sender_name = 'Phishti Detector';  // Sender name
// =============================

echo "Updating Gmail configuration...\n";

// Read the current config
$configFile = __DIR__ . '/config.php';
$config = file_get_contents($configFile);

// Update the SMTP settings
$config = str_replace(
    "\$SMTP_USERNAME = getenv('SMTP_USERNAME') ?: 'your-email@gmail.com';",
    "\$SMTP_USERNAME = getenv('SMTP_USERNAME') ?: '$gmail_email';",
    $config
);

$config = str_replace(
    "\$SMTP_PASSWORD = getenv('SMTP_PASSWORD') ?: 'your-app-password';",
    "\$SMTP_PASSWORD = getenv('SMTP_PASSWORD') ?: '$gmail_app_password';",
    $config
);

$config = str_replace(
    "\$SMTP_FROM_EMAIL = getenv('SMTP_FROM_EMAIL') ?: 'your-email@gmail.com';",
    "\$SMTP_FROM_EMAIL = getenv('SMTP_FROM_EMAIL') ?: '$gmail_email';",
    $config
);

$config = str_replace(
    "\$SMTP_FROM_NAME = getenv('SMTP_FROM_NAME') ?: 'Phishti Detector';",
    "\$SMTP_FROM_NAME = getenv('SMTP_FROM_NAME') ?: '$sender_name';",
    $config
);

// Write the updated config
file_put_contents($configFile, $config);

echo "✅ Gmail configuration updated!\n";
echo "📧 Email: $gmail_email\n";
echo "📝 Sender: $sender_name\n";
echo "🔧 App Password: " . str_repeat('*', strlen($gmail_app_password)) . "\n\n";

echo "🚀 Restart your PHP server to apply changes!\n";
echo "📱 Test by registering a new account in your Flutter app.\n";
?>
