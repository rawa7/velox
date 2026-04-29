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
include '../attend/status_tracker.php';
// Temporarily commented out to test
// include 'notification_helper.php';
// include 'fcm_helper.php';

// Image compression and resize function
function compressAndResizeImage($source_path, $destination_path, $max_width = 800, $max_height = 800, $quality = 80) {
    $image_info = getimagesize($source_path);
    if (!$image_info) {
        return false;
    }
    
    $width = $image_info[0];
    $height = $image_info[1];
    $mime_type = $image_info['mime'];
    
    switch ($mime_type) {
        case 'image/jpeg':
            $source_image = imagecreatefromjpeg($source_path);
            break;
        case 'image/png':
            $source_image = imagecreatefrompng($source_path);
            break;
        case 'image/gif':
            $source_image = imagecreatefromgif($source_path);
            break;
        case 'image/webp':
            // Common for product images from modern shops (Trendyol, Shein CDN, etc.)
            if (!function_exists('imagecreatefromwebp')) {
                return false;
            }
            $source_image = imagecreatefromwebp($source_path);
            break;
        default:
            return false;
    }
    
    if (!$source_image) {
        return false;
    }
    
    $ratio = min($max_width / $width, $max_height / $height);
    
    if ($ratio < 1) {
        $new_width = intval($width * $ratio);
        $new_height = intval($height * $ratio);
    } else {
        $new_width = $width;
        $new_height = $height;
    }
    
    $new_image = imagecreatetruecolor($new_width, $new_height);
    
    if ($mime_type == 'image/png' || $mime_type == 'image/gif' || $mime_type == 'image/webp') {
        imagealphablending($new_image, false);
        imagesavealpha($new_image, true);
        $transparent = imagecolorallocatealpha($new_image, 255, 255, 255, 127);
        imagefill($new_image, 0, 0, $transparent);
    }
    
    imagecopyresampled($new_image, $source_image, 0, 0, 0, 0, $new_width, $new_height, $width, $height);
    
    $success = false;
    switch ($mime_type) {
        case 'image/jpeg':
            $success = imagejpeg($new_image, $destination_path, $quality);
            break;
        case 'image/png':
            $png_quality = intval(9 - ($quality / 100) * 9);
            $success = imagepng($new_image, $destination_path, $png_quality);
            break;
        case 'image/gif':
            $success = imagegif($new_image, $destination_path);
            break;
        case 'image/webp':
            // Re-encode as JPEG so stored files match typical .jpg names from the app
            $success = imagejpeg($new_image, $destination_path, $quality);
            break;
    }
    
    imagedestroy($source_image);
    imagedestroy($new_image);
    
    return $success;
}

// Get customer_id from POST data or header
$customer_id = null;
if (isset($_POST['customer_id'])) {
    $customer_id = intval($_POST['customer_id']);
} elseif (isset($_SERVER['HTTP_CUSTOMER_ID'])) {
    $customer_id = intval($_SERVER['HTTP_CUSTOMER_ID']);
}

if (!$customer_id) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Customer ID is required. Please provide customer_id in request.'
    ]);
    exit();
}

// Validate required fields
$required_fields = ['link', 'size', 'qty'];
$validation_errors = [];

foreach ($required_fields as $field) {
    if (!isset($_POST[$field]) || empty(trim($_POST[$field]))) {
        $validation_errors[] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
    }
}

// Validate image upload
if (!isset($_FILES['product_image']) || $_FILES['product_image']['error'] !== UPLOAD_ERR_OK) {
    $validation_errors[] = 'Product image is required';
}

if (!empty($validation_errors)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Validation failed',
        'errors' => $validation_errors
    ]);
    exit();
}

// Get and sanitize input data
$link = mysqli_real_escape_string($conn, trim($_POST['link']));
$country = isset($_POST['country']) ? mysqli_real_escape_string($conn, trim($_POST['country'])) : '';
$size = mysqli_real_escape_string($conn, trim($_POST['size']));
$qty = intval($_POST['qty']);
$color = isset($_POST['color']) ? mysqli_real_escape_string($conn, trim($_POST['color'])) : '';
$note = isset($_POST['note']) ? mysqli_real_escape_string($conn, trim($_POST['note'])) : '';
$price = isset($_POST['price']) ? floatval($_POST['price']) : 0;

// Parse sub_items JSON (for SHEIN cart orders)
$sub_items = [];
$has_sub_items = 0;
if (!empty($_POST['sub_items'])) {
    $decoded = json_decode($_POST['sub_items'], true);
    if (is_array($decoded) && count($decoded) > 0) {
        $sub_items = $decoded;
        $has_sub_items = 1;
    }
}

// Calculate totalprice as price * quantity when price is provided
$totalprice = 0;
if ($price > 0) {
    $totalprice = $price * $qty;
}

// Handle image upload
$upload_dir = '../images/';
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0755, true);
}

$file_extension = strtolower(pathinfo($_FILES['product_image']['name'], PATHINFO_EXTENSION));
$allowed_extensions = array('jpg', 'jpeg', 'png', 'gif', 'webp');
$original_filename = $_FILES['product_image']['name'];
$file_size = $_FILES['product_image']['size'];

// Validate file extension
if (!in_array($file_extension, $allowed_extensions)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid image format. Please upload JPG, JPEG, PNG, GIF, or WebP files only.'
    ]);
    exit();
}

// Validate file size (20MB max)
$max_size = 20 * 1024 * 1024;
if ($file_size > $max_size) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'File size should not exceed 20MB.'
    ]);
    exit();
}

// Generate unique serial
$serial = generateUniqueSerial();

// Build insert query based on whether optional fields are provided
$insert_fields = "customer_id, websiteid, link, size, qty, status, created_at, paymentstatus, color, note, image, serial, pcountry, has_sub_items";
$insert_values = "$customer_id, 0, '$link', '$size', $qty, 1, NOW(), 0, '$color', '$note', 0, '$serial', NULL, $has_sub_items";

// Add country if provided
if (!empty($country)) {
    $insert_fields .= ", country";
    $insert_values .= ", '$country'";
}

// Add price if provided
if ($price > 0) {
    $insert_fields .= ", itemprice";
    $insert_values .= ", $price";
}

// Add totalprice if calculated
if ($totalprice > 0) {
    $insert_fields .= ", totalprice";
    $insert_values .= ", $totalprice";
}

// Add currency_id if provided
if ($currency_id > 0) {
    $insert_fields .= ", currency_id";
    $insert_values .= ", $currency_id";
}

$insert_query = "INSERT INTO items ($insert_fields) VALUES ($insert_values)";

if (!query($insert_query)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error creating order: ' . mysqli_error($conn)
    ]);
    exit();
}

$item_id = mysqli_insert_id($conn);

// Log the item creation (status 0 -> 1)
logStatusChange($item_id, 0, 1, 'Item created via API');

// Insert file record
$file_insert_query = "INSERT INTO files (filename, filesize, web_path, system_path) 
                     VALUES ('" . mysqli_real_escape_string($conn, $original_filename) . "', 
                             " . intval($file_size) . ", '', '')";

if (!query($file_insert_query)) {
    // Rollback: delete the item
    query("DELETE FROM items WHERE id = $item_id");
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error saving file information: ' . mysqli_error($conn)
    ]);
    exit();
}

$file_id = mysqli_insert_id($conn);

// Use file ID as filename
$file_name = $file_id . '.' . $file_extension;
$upload_path = $upload_dir . $file_name;
$web_path = "/images/" . $file_name;

// Move uploaded file to temp location
$temp_path = $upload_dir . 'temp_' . $file_name;
if (!move_uploaded_file($_FILES['product_image']['tmp_name'], $temp_path)) {
    // Rollback
    query("DELETE FROM files WHERE id = $file_id");
    query("DELETE FROM items WHERE id = $item_id");
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error uploading image file.'
    ]);
    exit();
}

// Compress and resize the image
if (!compressAndResizeImage($temp_path, $upload_path, 800, 800, 75)) {
    // Clean up temp file and rollback
    if (file_exists($temp_path)) {
        unlink($temp_path);
    }
    query("DELETE FROM files WHERE id = $file_id");
    query("DELETE FROM items WHERE id = $item_id");
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error processing image. Please try uploading a different image.'
    ]);
    exit();
}

// Delete temp file
if (file_exists($temp_path)) {
    unlink($temp_path);
}

// Get compressed file size
$compressed_size = filesize($upload_path);

// Update file record with paths and compressed size
$update_file_query = "UPDATE files SET 
                    web_path = '" . mysqli_real_escape_string($conn, $web_path) . "',
                    system_path = '" . mysqli_real_escape_string($conn, $upload_path) . "',
                    filesize = " . intval($compressed_size) . "
                    WHERE id = $file_id";

if (!query($update_file_query)) {
    // Rollback
    if (file_exists($upload_path)) {
        unlink($upload_path);
    }
    query("DELETE FROM files WHERE id = $file_id");
    query("DELETE FROM items WHERE id = $item_id");
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error updating file information: ' . mysqli_error($conn)
    ]);
    exit();
}

// Update item with file ID
$update_image_query = "UPDATE items SET image = $file_id WHERE id = $item_id";
if (!query($update_image_query)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Order created but failed to link image.'
    ]);
    exit();
}

// Ensure item_details has a size column (safe to run repeatedly with IF NOT EXISTS)
query("ALTER TABLE item_details ADD COLUMN IF NOT EXISTS size varchar(100) DEFAULT NULL COMMENT 'Item size (e.g. M, L, One Size)'");
query("ALTER TABLE item_details ADD COLUMN IF NOT EXISTS line_note varchar(512) DEFAULT NULL COMMENT 'Staff note e.g. out of stock'");

// Insert sub-items into item_details (SHEIN cart items)
if ($has_sub_items && count($sub_items) > 0) {
    foreach ($sub_items as $sub) {
        $item_code  = isset($sub['item_code'])  ? mysqli_real_escape_string($conn, trim($sub['item_code']))  : '';
        $serial_sub = isset($sub['serial'])      ? mysqli_real_escape_string($conn, trim($sub['serial']))     : '';
        $image_sub  = isset($sub['image'])       ? mysqli_real_escape_string($conn, trim($sub['image']))      : '';
        $qty_sub    = isset($sub['qty'])         ? intval($sub['qty'])                                        : 1;
        $price_sub  = isset($sub['price'])       ? floatval($sub['price'])                                    : 0.00;
        $size_sub   = isset($sub['size'])        ? mysqli_real_escape_string($conn, trim($sub['size']))       : '';
        $line_raw   = isset($sub['line_note'])   ? trim((string)$sub['line_note'])                            : '';
        if ($qty_sub === 0 && $line_raw === '') {
            $line_raw = 'This item is out of stock.';
        }
        $line_sql = $line_raw !== ''
            ? "'" . mysqli_real_escape_string($conn, $line_raw) . "'"
            : 'NULL';

        $sub_insert = "INSERT INTO item_details (item_id, item_code, serial, image, qty, price, size, line_note)
                       VALUES ($item_id, '$item_code', '$serial_sub', '$image_sub', $qty_sub, $price_sub, '$size_sub', $line_sql)";
        query($sub_insert);
    }
}

// Get the complete order details with currency info
$order_query = "SELECT i.*, f.web_path, f.filename, 
                c.currencyname, c.currencysign, c.currencycode, c.currencyconvert
                FROM items i 
                LEFT JOIN files f ON i.image = f.id 
                LEFT JOIN currency c ON i.currency_id = c.id
                WHERE i.id = $item_id";
$order_result = query($order_query);
$order = mysqli_fetch_assoc($order_result);

// Add full image URL
if (!empty($order['web_path'])) {
    $order['image_url'] = 'https://veloxshoppingiq.com' . $order['web_path'];
} else {
    $order['image_url'] = null;
}

// Format decimal values to 2 decimal places
if (isset($order['itemprice'])) {
    $order['itemprice'] = round(floatval($order['itemprice']), 2);
}
if (isset($order['totalprice'])) {
    $order['totalprice'] = round(floatval($order['totalprice']), 2);
}
if (isset($order['cargo'])) {
    $order['cargo'] = round(floatval($order['cargo']), 2);
}
if (isset($order['shippingprice'])) {
    $order['shippingprice'] = round(floatval($order['shippingprice']), 2);
}

// Send notification to admin (customer_id 932) about new order
// Wrapped in try-catch to prevent any notification errors from breaking the API
try {
    $admin_id = 932;
    $notification_title = "New Order Added";
    $notification_message = "Customer C{$customer_id} added a new order (ID: {$item_id}). Size: {$size}, Qty: {$qty}";

    // Save to database
    if (function_exists('sendNotification')) {
        $notification_id = sendNotification(
            $admin_id,
            $notification_title,
            $notification_message,
            'new_order',
            $item_id,
            'order'
        );

        // Also send FCM push notification to admin
        if ($notification_id && function_exists('sendFirebaseNotificationToCustomer')) {
            $fcm_data = [
                'notification_id' => (string)$notification_id,
                'type' => 'new_order',
                'order_id' => (string)$item_id,
                'customer_id' => (string)$customer_id
            ];
            sendFirebaseNotificationToCustomer($conn, $admin_id, $notification_title, $notification_message, $fcm_data);
        }
    }
} catch (Exception $e) {
    // Notification failed but don't break the API - just log it
    error_log("Notification to admin failed: " . $e->getMessage());
}

// Return success response with properly formatted decimals
http_response_code(201);
echo json_encode([
    'success' => true,
    'message' => 'Order added successfully! Admin will add pricing details.',
    'data' => [
        'order_id' => $item_id,
        'serial' => $serial,
        'order' => $order
    ]
]);

// Close database connection
mysqli_close($conn);
?>

