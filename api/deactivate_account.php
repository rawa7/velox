<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Only POST requests are accepted.'
    ]);
    exit();
}

// Include database configuration
include '../resources/config.php';

// Get JSON input
$json_input = file_get_contents('php://input');
$data = json_decode($json_input, true);

// Also support form data
if (!is_array($data)) {
    $data = $_POST;
}

// Validate input
if (!isset($data['phone']) || !isset($data['password'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Phone number and password are required.'
    ]);
    exit();
}

$phone = mysqli_real_escape_string($conn, trim($data['phone']));
$password = mysqli_real_escape_string($conn, trim($data['password']));

// Validate that fields are not empty
if (empty($phone) || empty($password)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Phone number and password cannot be empty.'
    ]);
    exit();
}

// Verify credentials
$query = "SELECT id, name, is_active FROM buyer WHERE phone='$phone' AND password='$password'";
$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred.'
    ]);
    exit();
}

$user = mysqli_fetch_assoc($result);

// Check if user exists
if (!$user) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid phone number or password.'
    ]);
    exit();
}

// Check if already deactivated
if ($user['is_active'] == 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'This account is already deactivated.'
    ]);
    exit();
}

// Deactivate the account
$user_id = intval($user['id']);
$update_query = "UPDATE buyer SET is_active = 0 WHERE id = $user_id";

if (mysqli_query($conn, $update_query)) {
    // Optionally deactivate all FCM tokens for this user
    $deactivate_fcm = "UPDATE fcm_tokens SET is_active = 0 WHERE customer_id = $user_id";
    @mysqli_query($conn, $deactivate_fcm);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Your account has been successfully deactivated. Contact support to reactivate.',
        'data' => [
            'customer_id' => $user_id,
            'customer_name' => $user['name']
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while deactivating your account. Please try again.'
    ]);
}

// Close database connection
mysqli_close($conn);
?>

