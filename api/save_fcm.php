<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Customer-Id');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed. POST only.']);
    exit();
}

include '../resources/config.php';
require_once __DIR__ . '/fcm_helper.php';

ensureFcmTableExists($conn);

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) { $input = $_POST; }

$token = isset($input['token']) ? trim($input['token']) : '';
$customerId = isset($input['customer_id']) ? intval($input['customer_id']) : null;
if (!$customerId && isset($_SERVER['HTTP_CUSTOMER_ID'])) { $customerId = intval($_SERVER['HTTP_CUSTOMER_ID']); }
$platform = isset($input['platform']) ? trim($input['platform']) : null; // ios | android | web
$deviceId = isset($input['device_id']) ? trim($input['device_id']) : null;

if ($token === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'token is required']);
    exit();
}

// Upsert token
$tokenEsc = mysqli_real_escape_string($conn, $token);
$platformEsc = $platform ? "'" . mysqli_real_escape_string($conn, $platform) . "'" : 'NULL';
$deviceIdEsc = $deviceId ? "'" . mysqli_real_escape_string($conn, $deviceId) . "'" : 'NULL';
$customerIdVal = $customerId ? intval($customerId) : 'NULL';

$sql = "INSERT INTO fcm_tokens (customer_id, token, platform, device_id, is_active, created_at, updated_at, last_seen)
        VALUES ($customerIdVal, '$tokenEsc', $platformEsc, $deviceIdEsc, 1, NOW(), NOW(), NOW())
        ON DUPLICATE KEY UPDATE
            customer_id = VALUES(customer_id),
            platform = VALUES(platform),
            device_id = VALUES(device_id),
            is_active = 1,
            updated_at = NOW(),
            last_seen = NOW()";

$ok = mysqli_query($conn, $sql);
if (!$ok) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB error saving token']);
    exit();
}

echo json_encode(['success' => true, 'message' => 'Token saved']);
?>


