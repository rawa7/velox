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

// Get customer_id from query parameter or header
$customer_id = null;
if (isset($_GET['customer_id'])) {
    $customer_id = intval($_GET['customer_id']);
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

// Get optional parameters
$status_filter = isset($_GET['status']) ? intval($_GET['status']) : null;
$search = isset($_GET['search']) ? mysqli_real_escape_string($conn, $_GET['search']) : '';

// Get customer's balance and user type information
$customer_info_query = "SELECT b.usertype, ut.name as usertype_name, ut.limitt as debt_limit 
                        FROM buyer b 
                        LEFT JOIN usertype ut ON b.usertype = ut.id 
                        WHERE b.id = $customer_id";
$customer_info_result = query($customer_info_query);

if (mysqli_num_rows($customer_info_result) == 0) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'Customer not found.'
    ]);
    exit();
}

$customer_info = mysqli_fetch_assoc($customer_info_result);
$customer_debt_limit = floatval($customer_info['debt_limit'] ?? 0);
$customer_usertype_name = $customer_info['usertype_name'] ?? 'Unknown';

// Calculate current balance (in Iraqi Dinar)
$balance_query = "SELECT 
                (SELECT COALESCE(SUM(amount), 0) FROM buyerpay WHERE buyerid = $customer_id) -
                (SELECT COALESCE(SUM(total_dinar), 0) FROM items WHERE customer_id = $customer_id AND paymentstatus = 1) 
                AS available_balance";
$balance_result = query($balance_query);
$customer_balance = floatval(mysqli_fetch_assoc($balance_result)['available_balance'] ?? 0);

// Calculate approved unpaid orders (in Iraqi Dinar)
$approved_unpaid_query = "SELECT COALESCE(SUM(total_dinar), 0) as approved_unpaid 
                         FROM items 
                         WHERE customer_id = $customer_id 
                         AND status IN (3, 4, -1, 16, 17, 19) 
                         AND paymentstatus = 0";
$approved_unpaid_result = query($approved_unpaid_query);
$approved_unpaid_total = floatval(mysqli_fetch_assoc($approved_unpaid_result)['approved_unpaid'] ?? 0);

// Available capacity
$customer_available_capacity = $customer_balance + $customer_debt_limit - $approved_unpaid_total;

// Build search condition
$search_condition = '';
if (!empty($search)) {
    $search_condition = " AND (i.id LIKE '%$search%' OR i.serial LIKE '%$search%' OR w.name LIKE '%$search%' OR s.name LIKE '%$search%')";
}

// Build status filter condition
$status_condition = '';
if ($status_filter !== null) {
    $status_condition = " AND i.status = $status_filter";
}

// Get all orders
$orders_query = "SELECT i.*, s.name as status_name, w.name as website_name, f.web_path as image_path,
                         c.currencysign as currency_symbol, c.currencyname as currency_name
                FROM items i
                LEFT JOIN statue s ON i.status = s.id
                LEFT JOIN website w ON i.websiteid = w.id
                LEFT JOIN files f ON i.image = f.id
                LEFT JOIN currency c ON i.currency_id = c.id
                WHERE i.customer_id = $customer_id $status_condition $search_condition
                ORDER BY i.created_at DESC";
$orders_result = mysqli_query($conn, $orders_query);

if (!$orders_result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred.'
    ]);
    exit();
}

$orders = [];
while ($order = mysqli_fetch_assoc($orders_result)) {
    // Add full image URL
    if (!empty($order['image_path'])) {
        $order['image_url'] = 'https://ruyadream.com/velox' . $order['image_path'];
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
    // Add total_dinar (Iraqi Dinar) - rounded to whole number
    if (isset($order['total_dinar'])) {
        $order['total_dinar'] = round(floatval($order['total_dinar']), 0);
    }
    if (isset($order['cargo'])) {
        $order['cargo'] = round(floatval($order['cargo']), 2);
    }
    if (isset($order['shippingprice'])) {
        $order['shippingprice'] = round(floatval($order['shippingprice']), 2);
    }
    if (isset($order['tax'])) {
        $order['tax'] = round(floatval($order['tax']), 2);
    }
    if (isset($order['commission'])) {
        $order['commission'] = round(floatval($order['commission']), 2);
    }
    
    // Ensure note field is included (even if null or empty)
    if (!isset($order['note'])) {
        $order['note'] = null;
    }
    
    $orders[] = $order;
}

// Get all statuses with counts
$statuses_query = "SELECT id, name FROM statue ORDER BY CASE WHEN id < 0 THEN 1 ELSE 0 END, id";
$statuses_result = mysqli_query($conn, $statuses_query);
$statuses = [];
$status_counts = [];
$status_totals = [];
$excluded_status_ids = [6, 14];
$total_count = 0;
$all_total_price = 0;

while ($status = mysqli_fetch_assoc($statuses_result)) {
    // Get count for this status
    $count_query = "SELECT COUNT(*) as count FROM items WHERE customer_id = $customer_id AND status = " . $status['id'];
    $count_result = mysqli_query($conn, $count_query);
    $count = mysqli_fetch_assoc($count_result)['count'];
    
    // Get total price for this status (in Iraqi Dinar)
    $total_query = "SELECT COALESCE(SUM(total_dinar), 0) as total_dinar 
                   FROM items 
                   WHERE customer_id = $customer_id AND status = " . $status['id'];
    $total_result = mysqli_query($conn, $total_query);
    $total_dinar = mysqli_fetch_assoc($total_result)['total_dinar'];
    
    $statuses[] = [
        'id' => $status['id'],
        'name' => $status['name'],
        'count' => intval($count),
        'total' => round(floatval($total_dinar), 0)
    ];
    
    $status_counts[$status['id']] = intval($count);
    $status_totals[$status['id']] = round(floatval($total_dinar), 0);
    
    if (!in_array(intval($status['id']), $excluded_status_ids, true)) {
        $total_count += intval($count);
        $all_total_price += floatval($total_dinar);
    }
}

// Return success response with properly formatted decimals
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Orders retrieved successfully.',
    'data' => [
        'account_info' => [
            'customer_id' => $customer_id,
            'current_balance' => round($customer_balance, 0),
            'account_type' => $customer_usertype_name,
            'debt_limit' => round($customer_debt_limit, 0),
            'orders_awaiting_payment' => round($approved_unpaid_total, 0),
            'available_capacity' => round($customer_available_capacity, 0)
        ],
        'orders' => $orders,
        'orders_count' => count($orders),
        'statuses' => $statuses,
        'summary' => [
            'total_count' => $total_count,
            'total_value' => round($all_total_price, 0)
        ]
    ]
]);

// Close database connection
mysqli_close($conn);
?>

