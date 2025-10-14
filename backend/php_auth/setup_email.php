<?php
// Email Setup Script for Gmail SMTP
// Run this script to configure Gmail SMTP settings

echo "=== Gmail SMTP Setup for Phishti Detector ===\n\n";

// Get user input
echo "Enter your Gmail address: ";
$email = trim(fgets(STDIN));

echo "Enter your Gmail App Password (not your regular password): ";
$appPassword = trim(fgets(STDIN));

echo "Enter sender name (default: Phishti Detector): ";
$senderName = trim(fgets(STDIN)) ?: 'Phishti Detector';

// Update config.php
$configFile = __DIR__ . '/config.php';
$configContent = file_get_contents($configFile);

// Replace the SMTP settings
$newConfig = preg_replace(
    '/\$SMTP_USERNAME = getenv\(\'SMTP_USERNAME\'\) \?\: \'[^\']*\';/',
    "\$SMTP_USERNAME = getenv('SMTP_USERNAME') ?: '$email';",
    $configContent
);

$newConfig = preg_replace(
    '/\$SMTP_PASSWORD = getenv\(\'SMTP_PASSWORD\'\) \?\: \'[^\']*\';/',
    "\$SMTP_PASSWORD = getenv('SMTP_PASSWORD') ?: '$appPassword';",
    $newConfig
);

$newConfig = preg_replace(
    '/\$SMTP_FROM_EMAIL = getenv\(\'SMTP_FROM_EMAIL\'\) \?\: \'[^\']*\';/',
    "\$SMTP_FROM_EMAIL = getenv('SMTP_FROM_EMAIL') ?: '$email';",
    $newConfig
);

$newConfig = preg_replace(
    '/\$SMTP_FROM_NAME = getenv\(\'SMTP_FROM_NAME\'\) \?\: \'[^\']*\';/',
    "\$SMTP_FROM_NAME = getenv('SMTP_FROM_NAME') ?: '$senderName';",
    $newConfig
);

// Write the updated config
file_put_contents($configFile, $newConfig);

echo "\n✅ Gmail SMTP configuration updated successfully!\n";
echo "📧 Emails will now be sent from: $email\n";
echo "📝 Sender name: $senderName\n\n";

echo "🔧 To get your Gmail App Password:\n";
echo "1. Go to https://myaccount.google.com/security\n";
echo "2. Enable 2-Factor Authentication if not already enabled\n";
echo "3. Go to 'App passwords' section\n";
echo "4. Generate a new app password for 'Mail'\n";
echo "5. Use that 16-character password (not your regular Gmail password)\n\n";

echo "🧪 Test the setup by registering a new account in your Flutter app!\n";
?>
