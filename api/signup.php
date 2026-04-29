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

// If JSON decode failed, try to get from POST
if (json_last_error() !== JSON_ERROR_NONE) {
    $data = $_POST;
}

// Validate required fields
$required_fields = ['name', 'phone', 'address', 'password'];
$missing_fields = [];

foreach ($required_fields as $field) {
    if (!isset($data[$field]) || empty(trim($data[$field]))) {
        $missing_fields[] = $field;
    }
}

$cityid = isset($data['cityid']) ? intval($data['cityid']) : 0;
if ($cityid < 1) {
    $missing_fields[] = 'cityid';
}

if (!empty($missing_fields)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing required fields: ' . implode(', ', $missing_fields)
    ]);
    exit();
}

// Ensure city exists (matches `city` table)
$cityid_escaped = intval($cityid);
$city_check = mysqli_query($conn, "SELECT id FROM city WHERE id = $cityid_escaped LIMIT 1");
if (!$city_check || mysqli_num_rows($city_check) === 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid city selected.'
    ]);
    exit();
}

// Get and sanitize input
$name = mysqli_real_escape_string($conn, trim($data['name']));
$phone = mysqli_real_escape_string($conn, trim($data['phone']));
$address = mysqli_real_escape_string($conn, trim($data['address']));
$password = trim($data['password']);

// Optional fields
$email = isset($data['email']) ? mysqli_real_escape_string($conn, trim($data['email'])) : '';
$instagram = isset($data['instagram']) ? mysqli_real_escape_string($conn, trim($data['instagram'])) : '';
$facebook = isset($data['facebook']) ? mysqli_real_escape_string($conn, trim($data['facebook'])) : '';

// Validate name (minimum 2 characters)
if (strlen($name) < 2) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Name must be at least 2 characters long.'
    ]);
    exit();
}

// Validate phone (minimum 10 digits)
$phone_digits = preg_replace('/[^0-9]/', '', $phone);
if (strlen($phone_digits) < 10) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Please provide a valid phone number (at least 10 digits).'
    ]);
    exit();
}

// Validate password (minimum 6 characters)
if (strlen($password) < 6) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Password must be at least 6 characters long.'
    ]);
    exit();
}

// Validate email format if provided
if (!empty($email) && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Please provide a valid email address.'
    ]);
    exit();
}

// Check if phone already exists
$check_phone_query = "SELECT id FROM buyer WHERE phone = '$phone'";
$check_phone_result = mysqli_query($conn, $check_phone_query);

if (mysqli_num_rows($check_phone_result) > 0) {
    http_response_code(409);
    echo json_encode([
        'success' => false,
        'message' => 'This phone number is already registered. Please use a different phone number or login.'
    ]);
    exit();
}

// Check if email already exists (if provided)
if (!empty($email)) {
    $check_email_query = "SELECT id FROM buyer WHERE email = '$email' AND email != ''";
    $check_email_result = mysqli_query($conn, $check_email_query);
    
    if (mysqli_num_rows($check_email_result) > 0) {
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'This email address is already registered. Please use a different email or login.'
        ]);
        exit();
    }
}

// Store password as plain text (not hashed)
$plain_password = mysqli_real_escape_string($conn, $password);

// Determine account type based on phone number country
// Iraq numbers start with 9647 (international) or 07 (local) or +9647
$phone_normalized = preg_replace('/[^0-9]/', '', $phone);
$is_iraq = (
    strpos($phone_normalized, '9647') === 0 ||
    (strpos($phone_normalized, '07') === 0 && strlen($phone_normalized) === 11)
);
$default_usertype = $is_iraq ? 5 : 1; // Bronze (5) for Iraq, Silver (1) for others
$is_active = 1; // Activated immediately for all new signups
$round = 0; // Default round value

// Start transaction
mysqli_begin_transaction($conn);

try {
    // Insert new user
    $insert_query = "INSERT INTO buyer (name, phone, address, email, instagram, facebook, password, usertype, is_active, round, cityid) 
                     VALUES ('$name', '$phone', '$address', '$email', '$instagram', '$facebook', '$plain_password', $default_usertype, $is_active, $round, $cityid_escaped)";
    
    if (!mysqli_query($conn, $insert_query)) {
        throw new Exception('Failed to create account: ' . mysqli_error($conn));
    }
    
    $user_id = mysqli_insert_id($conn);
    
    // Commit transaction
    mysqli_commit($conn);
    
    // Get user details with usertype colours (without password)
    $user_query = "SELECT b.id, b.name, b.phone, b.address, b.email, b.instagram, b.facebook, b.usertype, b.is_active,
                          ut.name AS ut_name, ut.limitt AS ut_limit,
                          ut.color1 AS ut_color1, ut.color2 AS ut_color2, ut.text_color AS ut_text_color
                   FROM buyer b
                   LEFT JOIN usertype ut ON ut.id = b.usertype
                   WHERE b.id = $user_id";
    $user_result = mysqli_query($conn, $user_query);
    $user = mysqli_fetch_assoc($user_result);

    $usertype_info = [
        'id'         => intval($user['usertype']),
        'name'       => $user['ut_name'] ?? null,
        'limit'      => isset($user['ut_limit']) ? intval($user['ut_limit']) : null,
        'color1'     => $user['ut_color1'] ?? null,
        'color2'     => $user['ut_color2'] ?? null,
        'text_color' => $user['ut_text_color'] ?? null,
    ];
    
    // Return success response
    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Account created successfully! You can now login.',
        'data' => [
            'user_id' => intval($user['id']),
            'name' => $user['name'],
            'phone' => $user['phone'],
            'address' => $user['address'],
            'email' => $user['email'] ?? null,
            'instagram' => $user['instagram'] ?? null,
            'facebook' => $user['facebook'] ?? null,
            'usertype' => $usertype_info,
            'is_active' => intval($user['is_active'])
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback on error
    mysqli_rollback($conn);
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

// Close database connection
mysqli_close($conn);
?>

