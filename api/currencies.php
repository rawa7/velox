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

// Get all currencies
$query = "SELECT * FROM currency ORDER BY id";
$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred.'
    ]);
    exit();
}

$currencies = [];
while ($row = mysqli_fetch_assoc($result)) {
    $currencies[] = $row;
}

// Return success response
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Currencies retrieved successfully.',
    'data' => [
        'currencies' => $currencies,
        'count' => count($currencies)
    ]
]);

// Close database connection
mysqli_close($conn);
?>

