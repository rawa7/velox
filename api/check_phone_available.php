<?php
/**
 * Returns whether a phone number is NOT already registered (for signup OTP step).
 * POST JSON: { "phone": "+9647..." or digits }
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'available' => false,
        'message' => 'Method not allowed. Only POST requests are accepted.',
    ]);
    exit();
}

include '../resources/config.php';

$json_input = file_get_contents('php://input');
$data = json_decode($json_input, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    $data = $_POST;
}

$phone_raw = isset($data['phone']) ? trim((string)$data['phone']) : '';
$digits = preg_replace('/[^0-9]/', '', $phone_raw);

if (strlen($digits) < 10) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'available' => false,
        'message' => 'Please provide a valid phone number (at least 10 digits).',
    ]);
    exit();
}

// Canonical forms (align with app: 964 + national without leading 0; plus legacy rows)
$variants = [$digits];
// Iraq: 07xxxxxxxxx → 9647xxxxxxxxx
if (strlen($digits) === 11 && substr($digits, 0, 2) === '07') {
    $variants[] = '964' . substr($digits, 1);
}
// 7xxxxxxxx (10 digits, mobile) → 964…
if (strlen($digits) === 10 && isset($digits[0]) && $digits[0] === '7') {
    $variants[] = '964' . $digits;
}
$variants = array_values(array_unique($variants));

$norm = "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone,'+',''),'-',''),' ',''),'(',''),')',''),'.','')";
$conds = [];
foreach ($variants as $v) {
    if ($v === '') {
        continue;
    }
    $e = mysqli_real_escape_string($conn, $v);
    $conds[] = "$norm = '$e'";
}

if (empty($conds)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'available' => false,
        'message' => 'Invalid phone number.',
    ]);
    exit();
}

$sql = 'SELECT id FROM buyer WHERE ' . implode(' OR ', $conds) . ' LIMIT 1';
$result = mysqli_query($conn, $sql);
$exists = $result && mysqli_num_rows($result) > 0;

http_response_code(200);
echo json_encode([
    'success' => true,
    'available' => !$exists,
    'message' => $exists
        ? 'This phone number is already registered.'
        : 'Phone number is available.',
]);

mysqli_close($conn);
