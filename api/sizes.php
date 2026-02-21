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

// Optional search parameter
$search = isset($_GET['search']) ? mysqli_real_escape_string($conn, $_GET['search']) : '';

// Build query
$query = "SELECT id, name FROM size";

// Add search condition if provided
if (!empty($search)) {
    $query .= " WHERE name LIKE '%$search%'";
}

// Order by name
$query .= " ORDER BY name ASC";

$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred: ' . mysqli_error($conn)
    ]);
    exit();
}

$sizes = [];
while ($row = mysqli_fetch_assoc($result)) {
    $sizes[] = [
        'id' => intval($row['id']),
        'name' => $row['name']
    ];
}

// Return success response
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Sizes retrieved successfully.',
    'data' => [
        'sizes' => $sizes,
        'count' => count($sizes)
    ]
]);

// Close database connection
mysqli_close($conn);
?>

