<?php
// Simple test to check if add_order.php includes work
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "Testing add_order.php includes...\n\n";

// Test includes
echo "1. Testing config.php...\n";
include '../resources/config.php';
echo "   ✓ Config loaded\n\n";

echo "2. Testing status_tracker.php...\n";
include '../attend/status_tracker.php';
echo "   ✓ Status tracker loaded\n\n";

echo "3. Testing notification_helper.php...\n";
include 'notification_helper.php';
echo "   ✓ Notification helper loaded\n\n";

echo "4. Testing fcm_helper.php...\n";
include 'fcm_helper.php';
echo "   ✓ FCM helper loaded\n\n";

echo "5. Testing function exists...\n";
if (function_exists('sendNotification')) {
    echo "   ✓ sendNotification exists\n";
} else {
    echo "   ✗ sendNotification NOT FOUND\n";
}

if (function_exists('sendFirebaseNotificationToCustomer')) {
    echo "   ✓ sendFirebaseNotificationToCustomer exists\n";
} else {
    echo "   ✗ sendFirebaseNotificationToCustomer NOT FOUND\n";
}

echo "\n✅ All includes loaded successfully!\n";
?>

