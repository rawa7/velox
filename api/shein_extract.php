<?php
/**
 * SHEIN Cart Extraction API for Flutter App
 * 
 * Endpoint: /api/shein_extract.php
 * Method: POST
 * Parameters:
 *   - shein_link: The SHEIN cart/share link
 * 
 * Response:
 *   {
 *     "success": true/false,
 *     "message": "Success message or error",
 *     "items": [
 *       {
 *         "code": "SKU_CODE",
 *         "name": "Product Name",
 *         "image": "https://...",
 *         "price": 12.50,  // Price in USD (SHEIN's original price)
 *         "qty": 1
 *       }
 *     ],
 *     "total_items": 3,
 *     "total_price": 37.50  // Total in USD
 *   }
 * 
 * NOTE: Prices are returned in USD (SHEIN's currency).
 *       Convert to Iraqi Dinar in your app using the exchange rate.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle OPTIONS request for CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// RapidAPI Configuration
define('RAPIDAPI_KEY', '2a7b7d7ff7msh0fc41abd991d525p18c937jsn22528fc5c264');
define('RAPIDAPI_HOST', 'shein-api-v1.p.rapidapi.com');

// Get the SHEIN link from POST or GET
$shein_link = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $shein_link = $input['shein_link'] ?? $_POST['shein_link'] ?? '';
} else {
    $shein_link = $_GET['shein_link'] ?? '';
}

// Validate input
if (empty($shein_link)) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing parameter: shein_link',
        'items' => [],
        'total_items' => 0,
        'total_price' => 0
    ]);
    exit;
}

// Validate it's a SHEIN URL
if (strpos($shein_link, 'shein') === false) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid SHEIN link. Please provide a valid SHEIN cart or share link.',
        'items' => [],
        'total_items' => 0,
        'total_price' => 0
    ]);
    exit;
}

// URL encode the SHEIN link
$encoded_link = urlencode($shein_link);

// Build RapidAPI URL
$api_url = 'https://' . RAPIDAPI_HOST . '/api/v1/cart/shareurl?link=' . $encoded_link;

// Initialize cURL
$curl = curl_init();

curl_setopt_array($curl, [
    CURLOPT_URL => $api_url,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_ENCODING => "",
    CURLOPT_MAXREDIRS => 10,
    CURLOPT_TIMEOUT => 30,
    CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
    CURLOPT_CUSTOMREQUEST => "GET",
    CURLOPT_SSL_VERIFYPEER => false,
    CURLOPT_HTTPHEADER => [
        "x-rapidapi-host: " . RAPIDAPI_HOST,
        "x-rapidapi-key: " . RAPIDAPI_KEY
    ],
]);

$response = curl_exec($curl);
$http_code = curl_getinfo($curl, CURLINFO_HTTP_CODE);
$curl_error = curl_error($curl);

curl_close($curl);

// Handle cURL errors
if ($curl_error) {
    echo json_encode([
        'success' => false,
        'message' => 'Network error: ' . $curl_error,
        'items' => [],
        'total_items' => 0,
        'total_price' => 0
    ]);
    exit;
}

// Handle HTTP errors
if ($http_code != 200) {
    echo json_encode([
        'success' => false,
        'message' => 'API request failed with HTTP code ' . $http_code,
        'items' => [],
        'total_items' => 0,
        'total_price' => 0
    ]);
    exit;
}

// Parse JSON response
$data = json_decode($response, true);

if (!$data || !isset($data['success'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid API response',
        'items' => [],
        'total_items' => 0,
        'total_price' => 0
    ]);
    exit;
}

// Check if API call was successful
if (!$data['success'] || !isset($data['data'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to extract items from SHEIN link. The link may be invalid or expired.',
        'items' => [],
        'total_items' => 0,
        'total_price' => 0
    ]);
    exit;
}

// Extract products from API response
$products = [];
$data_items = $data['data'];

// Handle if data.goods exists (old API format)
if (isset($data_items['goods']) && is_array($data_items['goods'])) {
    $data_items = $data_items['goods'];
}

// If data is not an array or is empty, return empty
if (!is_array($data_items) || empty($data_items)) {
    echo json_encode([
        'success' => false,
        'message' => 'No items found in the cart. The link may be empty or expired.',
        'items' => [],
        'total_items' => 0,
        'total_price' => 0
    ]);
    exit;
}

$total_price = 0;
$total_qty = 0;

// Extract each item
foreach ($data_items as $key => $item) {
    // Skip non-array items
    if (!is_array($item)) {
        continue;
    }
    
    // Extract SKU code
    $sku_code = $item['sku_code'] ?? 'UNKNOWN';
    
    // Extract product name
    $product_name = $item['goods_name'] ?? '';
    
    // Extract image
    $image_url = '';
    if (isset($item['goods_img'])) {
        $image_url = (strpos($item['goods_img'], 'http') === 0) 
                     ? $item['goods_img'] 
                     : 'https:' . $item['goods_img'];
    }
    
    // Extract price - try multiple possible fields
    $price = 0;
    if (isset($item['salePrice']['usdAmount'])) {
        $price = floatval($item['salePrice']['usdAmount']);
    } elseif (isset($item['sale_price']['usdAmount'])) {
        $price = floatval($item['sale_price']['usdAmount']);
    } elseif (isset($item['retailPrice']['usdAmount'])) {
        $price = floatval($item['retailPrice']['usdAmount']);
    } elseif (isset($item['retail_price']['usdAmount'])) {
        $price = floatval($item['retail_price']['usdAmount']);
    }
    
    // Default quantity is 1
    $qty = 1;
    
    // Only add if we have a SKU code
    if (!empty($sku_code)) {
        $products[] = [
            'code' => $sku_code,
            'name' => $product_name,
            'image' => $image_url,
            'price' => $price,
            'qty' => $qty
        ];
        
        $total_price += $price * $qty;
        $total_qty += $qty;
    }
}

// Return success response
if (count($products) > 0) {
    echo json_encode([
        'success' => true,
        'message' => 'Successfully extracted ' . count($products) . ' items from SHEIN cart',
        'items' => $products,
        'total_items' => $total_qty,
        'total_price' => round($total_price, 2)
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'No valid items found in the cart',
        'items' => [],
        'total_items' => 0,
        'total_price' => 0
    ]);
}
?>
