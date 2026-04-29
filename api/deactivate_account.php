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
    echo json_encode(['success' => false, 'message' => 'Method not allowed.']);
    exit();
}

include '../resources/config.php';

$input = json_decode(file_get_contents('php://input'), true);
$customer_id = intval($input['customer_id'] ?? 0);

if (!$customer_id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Customer ID is required.']);
    exit();
}

$query = "UPDATE buyer SET is_active = 0 WHERE id = $customer_id";
$result = mysqli_query($conn, $query);

if ($result && mysqli_affected_rows($conn) > 0) {
    echo json_encode(['success' => true, 'message' => 'Account deactivated successfully.']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to deactivate account.']);
}

mysqli_close($conn);
?>
