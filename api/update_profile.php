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
if (!isset($data['customer_id'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Customer ID is required.'
    ]);
    exit();
}

$customer_id = intval($data['customer_id']);

// Check if customer exists
$check_query = "SELECT id FROM buyer WHERE id = $customer_id";
$check_result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($check_result) == 0) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'Customer not found.'
    ]);
    exit();
}

// Build update query dynamically based on provided fields
$update_fields = [];

if (isset($data['phone'])) {
    $phone = mysqli_real_escape_string($conn, trim($data['phone']));
    $update_fields[] = "phone = '$phone'";
}

if (isset($data['address'])) {
    $address = mysqli_real_escape_string($conn, trim($data['address']));
    $update_fields[] = "address = '$address'";
}

if (isset($data['email'])) {
    $email = mysqli_real_escape_string($conn, trim($data['email']));
    // Validate email format
    if (!empty($email) && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid email format.'
        ]);
        exit();
    }
    $update_fields[] = "email = '$email'";
}

// Check if there are fields to update
if (empty($update_fields)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'No fields to update. Provide at least one field (phone, address, or email).'
    ]);
    exit();
}

// Build and execute update query
$update_query = "UPDATE buyer SET " . implode(', ', $update_fields) . " WHERE id = $customer_id";

if (mysqli_query($conn, $update_query)) {
    // Get updated customer data
    $customer_query = "SELECT b.*, ut.name as usertype_name 
                      FROM buyer b 
                      LEFT JOIN usertype ut ON b.usertype = ut.id 
                      WHERE b.id = $customer_id";
    $customer_result = mysqli_query($conn, $customer_query);
    $customer = mysqli_fetch_assoc($customer_result);
    
    // Remove password from response
    unset($customer['password']);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Profile updated successfully.',
        'data' => [
            'profile' => [
                'id' => $customer['id'],
                'name' => $customer['name'],
                'phone' => $customer['phone'],
                'address' => $customer['address'],
                'email' => $customer['email'],
                'usertype' => $customer['usertype'],
                'usertype_name' => $customer['usertype_name'],
                'is_active' => $customer['is_active']
            ]
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error updating profile: ' . mysqli_error($conn)
    ]);
}

// Close database connection
mysqli_close($conn);
?>

