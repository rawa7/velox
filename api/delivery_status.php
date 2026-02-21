<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database configuration
include '../resources/config.php';

// Get customer_id from query parameter or JSON body
$customer_id = null;

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // GET request - retrieve delivery status
    if (isset($_GET['customer_id'])) {
        $customer_id = intval($_GET['customer_id']);
    }
    
    if (!$customer_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Customer ID is required. Please provide customer_id in request.'
        ]);
        exit();
    }
    
    // Get customer delivery status
    $query = "SELECT id, name, phone, delivery FROM buyer WHERE id = $customer_id";
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error occurred: ' . mysqli_error($conn)
        ]);
        exit();
    }
    
    if (mysqli_num_rows($result) == 0) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Customer not found.'
        ]);
        exit();
    }
    
    $customer = mysqli_fetch_assoc($result);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Delivery status retrieved successfully.',
        'data' => [
            'customer_id' => intval($customer['id']),
            'name' => $customer['name'],
            'phone' => $customer['phone'],
            'delivery_status' => intval($customer['delivery']),
            'delivery_enabled' => intval($customer['delivery']) === 1,
            'delivery_text' => intval($customer['delivery']) === 1 ? 'Delivery Yes' : 'Delivery No'
        ]
    ]);
    
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST' || $_SERVER['REQUEST_METHOD'] === 'PUT') {
    // POST/PUT request - update delivery status
    
    // Get JSON input
    $json_input = file_get_contents('php://input');
    $data = json_decode($json_input, true);
    
    // If JSON decode failed, try to get from POST
    if (json_last_error() !== JSON_ERROR_NONE) {
        $data = $_POST;
    }
    
    // Validate required fields
    if (!isset($data['customer_id']) || empty($data['customer_id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Customer ID is required.'
        ]);
        exit();
    }
    
    if (!isset($data['delivery_status'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Delivery status is required. Use 0 (No) or 1 (Yes).'
        ]);
        exit();
    }
    
    $customer_id = intval($data['customer_id']);
    $delivery_status = intval($data['delivery_status']);
    
    // Validate delivery status value (must be 0 or 1)
    if ($delivery_status !== 0 && $delivery_status !== 1) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid delivery status. Must be 0 (No) or 1 (Yes).'
        ]);
        exit();
    }
    
    // Check if customer exists
    $check_query = "SELECT id, name, phone, delivery FROM buyer WHERE id = $customer_id";
    $check_result = mysqli_query($conn, $check_query);
    
    if (!$check_result || mysqli_num_rows($check_result) == 0) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Customer not found.'
        ]);
        exit();
    }
    
    $customer = mysqli_fetch_assoc($check_result);
    $old_status = intval($customer['delivery']);
    
    // Check if status is already the same
    if ($old_status === $delivery_status) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Delivery status is already set to ' . ($delivery_status === 1 ? 'Yes' : 'No') . '.',
            'data' => [
                'customer_id' => $customer_id,
                'name' => $customer['name'],
                'phone' => $customer['phone'],
                'old_status' => $old_status,
                'new_status' => $delivery_status,
                'delivery_enabled' => $delivery_status === 1,
                'delivery_text' => $delivery_status === 1 ? 'Delivery Yes' : 'Delivery No'
            ]
        ]);
        exit();
    }
    
    // Update delivery status
    $update_query = "UPDATE buyer SET delivery = $delivery_status WHERE id = $customer_id";
    
    if (mysqli_query($conn, $update_query)) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Delivery status updated successfully from ' . 
                        ($old_status === 1 ? 'Yes' : 'No') . ' to ' . 
                        ($delivery_status === 1 ? 'Yes' : 'No') . '.',
            'data' => [
                'customer_id' => $customer_id,
                'name' => $customer['name'],
                'phone' => $customer['phone'],
                'old_status' => $old_status,
                'new_status' => $delivery_status,
                'delivery_enabled' => $delivery_status === 1,
                'delivery_text' => $delivery_status === 1 ? 'Delivery Yes' : 'Delivery No'
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to update delivery status: ' . mysqli_error($conn)
        ]);
    }
    
} else {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Only GET, POST, and PUT requests are accepted.'
    ]);
}

// Close database connection
mysqli_close($conn);
?>

