<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Only GET requests are accepted.'
    ]);
    exit();
}

// Include database configuration
include '../resources/config.php';

// Get query parameters
$id = isset($_GET['id']) ? mysqli_real_escape_string($conn, $_GET['id']) : null;
$country = isset($_GET['country']) ? mysqli_real_escape_string($conn, $_GET['country']) : null;
$order_by = isset($_GET['order_by']) ? mysqli_real_escape_string($conn, $_GET['order_by']) : 'order_id';
$sort = isset($_GET['sort']) ? strtoupper(mysqli_real_escape_string($conn, $_GET['sort'])) : 'ASC';

// Validate sort direction
if (!in_array($sort, ['ASC', 'DESC'])) {
    $sort = 'ASC';
}

// Validate order_by column
$allowed_columns = ['id', 'name', 'link', 'order_id', 'country'];
if (!in_array($order_by, $allowed_columns)) {
    $order_by = 'order_id';
}

// Build query with JOIN to get image path
if ($id) {
    // Get single website by ID
    $query = "SELECT w.*, f.web_path, f.filename 
              FROM website w 
              LEFT JOIN files f ON w.image_id = f.id 
              WHERE w.id='$id'";
} else {
    // Get all websites or filter by country
    $query = "SELECT w.*, f.web_path, f.filename 
              FROM website w 
              LEFT JOIN files f ON w.image_id = f.id";
    
    $where_conditions = [];
    
    if ($country) {
        $where_conditions[] = "w.country='$country'";
    }
    
    if (!empty($where_conditions)) {
        $query .= " WHERE " . implode(' AND ', $where_conditions);
    }
    
    $query .= " ORDER BY w.$order_by DESC";
}

// Execute query
$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred.'
    ]);
    exit();
}

// Fetch results and build image URL
$websites = [];
while ($row = mysqli_fetch_assoc($result)) {
    // Add full image URL if web_path exists
    if (!empty($row['web_path'])) {
        $row['image_url'] = 'https://veloxshoppingiq.com' . $row['web_path'];
    } else {
        $row['image_url'] = null;
    }
    $websites[] = $row;
}

// Check if results found
if (empty($websites)) {
    if ($id) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Website not found.'
        ]);
    } else {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'No websites found.',
            'data' => [
                'websites' => [],
                'count' => 0
            ]
        ]);
    }
    exit();
}

// Return success response
http_response_code(200);

if ($id) {
    // Single website
    echo json_encode([
        'success' => true,
        'message' => 'Website retrieved successfully.',
        'data' => [
            'website' => $websites[0]
        ]
    ]);
} else {
    // Multiple websites
    echo json_encode([
        'success' => true,
        'message' => 'Websites retrieved successfully.',
        'data' => [
            'websites' => $websites,
            'count' => count($websites)
        ]
    ]);
}

// Close database connection
mysqli_close($conn);
?>

