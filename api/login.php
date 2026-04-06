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

// Query the database, joining usertype to get the name
$query = "SELECT b.*, ut.name as usertype_name FROM buyer b LEFT JOIN usertype ut ON b.usertype = ut.id WHERE b.phone='$phone' AND b.password='$password'";
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

// Check if account is active
if ($user['is_active'] == 0) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'Your account is disabled. Please contact the system administrator.'
    ]);
    exit();
}

// Remove sensitive information
unset($user['password']);

// Return success response
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Login successful.',
    'data' => [
        'user' => $user
    ]
]);

// Close database connection
mysqli_close($conn);
?>

