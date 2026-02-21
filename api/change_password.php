<?php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

include '../resources/config.php';

// Only allow POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'error' => 'Only POST method is allowed']);
    exit();
}

// Get input data
$phone = $_POST['phone'] ?? '';
$customer_id = $_POST['customer_id'] ?? null;
$current_password = $_POST['current_password'] ?? '';
$new_password = $_POST['new_password'] ?? '';

// Validate required fields
if (empty($current_password) || empty($new_password)) {
    echo json_encode(['success' => false, 'error' => 'Current password and new password are required']);
    exit();
}

// Must provide either phone or customer_id
if (empty($phone) && empty($customer_id)) {
    echo json_encode(['success' => false, 'error' => 'Phone number or customer ID is required']);
    exit();
}

// Validate new password length (minimum 4 characters)
if (strlen($new_password) < 4) {
    echo json_encode(['success' => false, 'error' => 'New password must be at least 4 characters long']);
    exit();
}

// Build query based on what identifier is provided
if (!empty($customer_id)) {
    $query = "SELECT * FROM buyer WHERE id = ?";
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $conn->error]);
        exit();
    }
    
    $stmt->bind_param('i', $customer_id);
} else {
    $query = "SELECT * FROM buyer WHERE phone = ?";
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $conn->error]);
    exit();
}

    $stmt->bind_param('s', $phone);
}

$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'error' => 'User not found']);
    exit();
}

$user = $result->fetch_assoc();

// Verify current password
if ($user['password'] !== $current_password) {
    echo json_encode(['success' => false, 'error' => 'Current password is incorrect']);
    exit();
}

// Check if account is active
if ($user['is_active'] == 0) {
    echo json_encode(['success' => false, 'error' => 'Account is disabled. Please contact administrator']);
    exit();
}

// Update password
$update_query = "UPDATE buyer SET password = ? WHERE id = ?";
$update_stmt = $conn->prepare($update_query);

if (!$update_stmt) {
    echo json_encode(['success' => false, 'error' => 'Database error: ' . $conn->error]);
    exit();
}

$update_stmt->bind_param('si', $new_password, $user['id']);

if ($update_stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Password changed successfully',
        'customer_id' => $user['id'],
        'phone' => $user['phone']
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to update password: ' . $update_stmt->error]);
}

$stmt->close();
$update_stmt->close();
$conn->close();
?>
