<?php
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
    echo json_encode(['success' => false, 'message' => 'Method not allowed. POST only.']);
    exit();
}

include '../resources/config.php';
require_once __DIR__ . '/fcm_helper.php';

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) { $input = $_POST; }

$token = isset($input['token']) ? trim($input['token']) : '';
$customerId = isset($input['customer_id']) ? intval($input['customer_id']) : 0;
$title = isset($input['title']) ? trim($input['title']) : '';
$body = isset($input['body']) ? trim($input['body']) : '';
$data = isset($input['data']) && is_array($input['data']) ? $input['data'] : [];

if ($title === '' || $body === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'title and body are required']);
    exit();
}

// If customer_id is provided, check if they have bronze account (usertype = 5)
if ($customerId > 0) {
    $usertype_check = mysqli_query($conn, "SELECT usertype FROM buyer WHERE id = " . intval($customerId));
    if ($usertype_check && $usertype_row = mysqli_fetch_assoc($usertype_check)) {
        if (intval($usertype_row['usertype']) === 5) {
            // Bronze accounts should NOT receive notifications
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Bronze account - notifications disabled']);
            exit();
        }
    }
}

$result = null;
if ($token !== '') {
    $result = sendFirebaseNotificationToToken($token, $title, $body, $data);
} elseif ($customerId > 0) {
    $result = sendFirebaseNotificationToCustomer($conn, $customerId, $title, $body, $data);
} else {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Provide token or customer_id']);
    exit();
}

http_response_code($result['success'] ? 200 : 500);
echo json_encode($result);
?>


