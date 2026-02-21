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
$deviceId = isset($input['device_id']) ? trim($input['device_id']) : null;

if ($token === '' && !$deviceId) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'token or device_id is required']);
    exit();
}

// Deactivate by token or device
if ($token !== '') {
    $tokenEsc = mysqli_real_escape_string($conn, $token);
    $where = "token = '$tokenEsc'";
    if ($customerId) { $where .= " AND (customer_id = " . intval($customerId) . " OR customer_id IS NULL)"; }
    $sql = "UPDATE fcm_tokens SET is_active = 0, updated_at = NOW() WHERE $where";
} else {
    $deviceIdEsc = mysqli_real_escape_string($conn, $deviceId);
    $where = "device_id = '$deviceIdEsc'";
    if ($customerId) { $where .= " AND (customer_id = " . intval($customerId) . " OR customer_id IS NULL)"; }
    $sql = "UPDATE fcm_tokens SET is_active = 0, updated_at = NOW() WHERE $where";
}

$ok = mysqli_query($conn, $sql);
if (!$ok) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB error deleting token']);
    exit();
}

echo json_encode(['success' => true, 'message' => 'Token deactivated']);
?>


