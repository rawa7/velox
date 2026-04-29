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

$phone_raw = trim($data['phone']);
$password = mysqli_real_escape_string($conn, trim($data['password']));

// Validate that fields are not empty
if ($phone_raw === '' || $password === '') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Phone number and password cannot be empty.'
    ]);
    exit();
}

$digits = preg_replace('/[^0-9]/', '', $phone_raw);

// Match buyer.phone across formats (+964…, 964…, 0750…, 750…) — same idea as check_phone_available.php
$variants = strlen($digits) >= 10 ? [$digits] : [];
if (strlen($digits) === 11 && substr($digits, 0, 2) === '07') {
    $variants[] = '964' . substr($digits, 1);
}
if (strlen($digits) === 10 && isset($digits[0]) && $digits[0] === '7') {
    $variants[] = '964' . $digits;
}
$variants = array_values(array_unique($variants));

$norm = "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(b.phone,'+',''),'-',''),' ',''),'(',''),')',''),'.','')";
$phone_conds = [];
foreach ($variants as $v) {
    if ($v === '') {
        continue;
    }
    $e = mysqli_real_escape_string($conn, $v);
    $phone_conds[] = "$norm = '$e'";
}
$phone_raw_esc = mysqli_real_escape_string($conn, $phone_raw);
$phone_conds[] = "b.phone = '$phone_raw_esc'";
$phone_clause = '(' . implode(' OR ', $phone_conds) . ')';

// Query the database (join usertype to get gradient colors)
$query = "SELECT b.*, 
                 ut.name    AS usertype_name,
                 ut.name_ku AS usertype_name_ku,
                 ut.name_ar AS usertype_name_ar,
                 ut.limitt  AS usertype_limit,
                 ut.color1  AS usertype_color1,
                 ut.color2  AS usertype_color2,
                 ut.text_color AS usertype_text_color
          FROM buyer b
          LEFT JOIN usertype ut ON ut.id = b.usertype
          WHERE $phone_clause AND b.password='$password'";
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

// Build usertype object
$usertype_info = [
    'id'         => intval($user['usertype']),
    'name'       => $user['usertype_name']    ?? null,
    'name_ku'    => $user['usertype_name_ku'] ?? null,
    'name_ar'    => $user['usertype_name_ar'] ?? null,
    'limit'      => isset($user['usertype_limit']) ? intval($user['usertype_limit']) : null,
    'color1'     => $user['usertype_color1']  ?? null,
    'color2'     => $user['usertype_color2']  ?? null,
    'text_color' => $user['usertype_text_color'] ?? null,
];

// Clean joined fields from user object
unset($user['usertype_name'], $user['usertype_name_ku'], $user['usertype_name_ar'], $user['usertype_limit'], $user['usertype_color1'], $user['usertype_color2'], $user['usertype_text_color']);

// Return success response
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Login successful.',
    'data' => [
        'user'     => $user,
        'usertype' => $usertype_info,
    ]
]);

// Close database connection
mysqli_close($conn);
?>

