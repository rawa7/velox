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

// Get single brand if ID provided
$brand_id = isset($_GET['id']) ? intval($_GET['id']) : null;

// Build query with brand image
if ($brand_id) {
    $query = "SELECT b.id, b.name, b.image as image_id, f.web_path, f.filename
              FROM brand b
              LEFT JOIN files f ON b.image = f.id
              WHERE b.id = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $brand_id);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $query = "SELECT b.id, b.name, b.image as image_id, f.web_path, f.filename
              FROM brand b
              LEFT JOIN files f ON b.image = f.id
              ORDER BY b.name";
    
    $result = mysqli_query($conn, $query);
}

if (!$result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred.'
    ]);
    exit();
}

$brands = [];
while ($row = mysqli_fetch_assoc($result)) {
    $brands[] = [
        'id' => $row['id'],
        'name' => $row['name'],
        'image_id' => $row['image_id'],
        'image_url' => $row['web_path'] ? 'http://ruyadream.com/velox' . $row['web_path'] : null,
        'filename' => $row['filename']
    ];
}

// Check if results found
if (empty($brands)) {
    if ($brand_id) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Brand not found.'
        ]);
    } else {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'No brands found.',
            'data' => [
                'brands' => [],
                'count' => 0
            ]
        ]);
    }
    exit();
}

// Return success response
http_response_code(200);

if ($brand_id) {
    // Single brand
    echo json_encode([
        'success' => true,
        'message' => 'Brand retrieved successfully.',
        'data' => [
            'brand' => $brands[0]
        ]
    ]);
} else {
    // Multiple brands
    echo json_encode([
        'success' => true,
        'message' => 'Brands retrieved successfully.',
        'data' => [
            'brands' => $brands,
            'count' => count($brands)
        ]
    ]);
}

// Close database connection
mysqli_close($conn);
?>

