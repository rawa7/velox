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

// Get optional search parameter
$search = isset($_GET['search']) ? mysqli_real_escape_string($conn, $_GET['search']) : '';

// Build search condition
$search_condition = '';
if (!empty($search)) {
    $search_condition = " WHERE currencyname LIKE '%$search%' OR currencycode LIKE '%$search%'";
}

// Query to get all currencies with conversion rates
$query = "SELECT id, currencyname, currencysign, currencycode, currencyconvert 
          FROM `currency` 
          $search_condition 
          ORDER BY id ASC";
$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred: ' . mysqli_error($conn)
    ]);
    exit();
}

$currencies = [];
while ($row = mysqli_fetch_assoc($result)) {
    $currencies[] = [
        'id' => intval($row['id']),
        'name' => $row['currencyname'],
        'symbol' => $row['currencysign'],
        'code' => $row['currencycode'],
        'conversion_rate' => round(floatval($row['currencyconvert']), 2)
    ];
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Currency rates retrieved successfully.',
    'data' => [
        'currencies' => $currencies,
        'count' => count($currencies),
        'last_updated' => date('Y-m-d H:i:s')
    ]
]);

// Close database connection
mysqli_close($conn);
?>

