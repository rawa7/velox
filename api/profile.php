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

// Get customer details
$customer_query = "SELECT b.*, ut.name as usertype_name, ut.limitt as debt_limit,
                          ut.color1 AS usertype_color1,
                          ut.color2 AS usertype_color2,
                          ut.text_color AS usertype_text_color,
                          ut.name_ku AS usertype_name_ku,
                          ut.name_ar AS usertype_name_ar
                   FROM buyer b 
                   LEFT JOIN usertype ut ON b.usertype = ut.id 
                   WHERE b.id = $customer_id";
$customer_result = mysqli_query($conn, $customer_query);

if (!$customer_result || mysqli_num_rows($customer_result) == 0) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'Customer not found.'
    ]);
    exit();
}

$customer = mysqli_fetch_assoc($customer_result);

// Remove sensitive password from response
$password_exists = !empty($customer['password']);
unset($customer['password']);

// Get customer's balance (Iraqi Dinar — same logic as orders.php / account list)
// Payments (buyerpay.amount) and order totals (items.total_dinar) must use the same unit.
$balance_query = "SELECT 
                (SELECT COALESCE(SUM(amount), 0) FROM buyerpay WHERE buyerid = $customer_id) -
                (SELECT COALESCE(SUM(total_dinar), 0) FROM items WHERE customer_id = $customer_id AND paymentstatus = 1) 
                AS available_balance";
$balance_result = query($balance_query);
$customer_balance = floatval(mysqli_fetch_assoc($balance_result)['available_balance'] ?? 0);

// Approved unpaid orders (IQD)
$approved_unpaid_query = "SELECT COALESCE(SUM(total_dinar), 0) as approved_unpaid 
                         FROM items 
                         WHERE customer_id = $customer_id 
                         AND status IN (3, 4, -1, 16, 17, 19) 
                         AND paymentstatus = 0";
$approved_unpaid_result = query($approved_unpaid_query);
$approved_unpaid_total = floatval(mysqli_fetch_assoc($approved_unpaid_result)['approved_unpaid'] ?? 0);

// Get debt limit
$customer_debt_limit = floatval($customer['debt_limit'] ?? 0);
$customer_usertype_name = $customer['usertype_name'] ?? 'Unknown';

// Calculate available capacity
$customer_available_capacity = $customer_balance + $customer_debt_limit - $approved_unpaid_total;

// Get total items count
$total_items_query = "SELECT COUNT(*) as total_items FROM items WHERE customer_id = $customer_id";
$total_items_result = mysqli_query($conn, $total_items_query);
$total_items = intval(mysqli_fetch_assoc($total_items_result)['total_items'] ?? 0);

// Get total purchases (all orders total)
$total_purchases_query = "SELECT COALESCE(SUM(CASE WHEN totalprice IS NOT NULL AND totalprice != '' THEN totalprice ELSE itemprice END), 0) as total_purchases 
                         FROM items 
                         WHERE customer_id = $customer_id";
$total_purchases_result = mysqli_query($conn, $total_purchases_query);
$total_purchases = floatval(mysqli_fetch_assoc($total_purchases_result)['total_purchases'] ?? 0);

// Get total payments made
$total_payments_query = "SELECT COALESCE(SUM(amount), 0) as total_payments FROM buyerpay WHERE buyerid = $customer_id";
$total_payments_result = mysqli_query($conn, $total_payments_query);
$total_payments = floatval(mysqli_fetch_assoc($total_payments_result)['total_payments'] ?? 0);

// Get total paid items (IQD)
$total_paid_items_query = "SELECT COALESCE(SUM(total_dinar), 0) as total_paid FROM items WHERE customer_id = $customer_id AND paymentstatus = 1";
$total_paid_items_result = mysqli_query($conn, $total_paid_items_query);
$total_paid_items = floatval(mysqli_fetch_assoc($total_paid_items_result)['total_paid'] ?? 0);

// Get excluded statuses count
$excluded_status_ids = [6, 14];
$excluded_query = "SELECT COUNT(*) as excluded_count FROM items WHERE customer_id = $customer_id AND status IN (" . implode(',', $excluded_status_ids) . ")";
$excluded_result = mysqli_query($conn, $excluded_query);
$excluded_count = intval(mysqli_fetch_assoc($excluded_result)['excluded_count'] ?? 0);

// Calculate active items (excluding rejected/cancelled)
$active_items = $total_items - $excluded_count;

// Customer-facing code for QR / support (DB column `usercode` when present).
$usercode = !empty($customer['usercode']) ? $customer['usercode'] : ('C' . $customer_id);

$usertype_info = [
    'id'         => intval($customer['usertype']),
    'name'       => $customer['usertype_name'] ?? null,
    'name_ku'    => $customer['usertype_name_ku'] ?? null,
    'name_ar'    => $customer['usertype_name_ar'] ?? null,
    'limit'      => isset($customer['debt_limit']) ? intval($customer['debt_limit']) : null,
    'color1'     => $customer['usertype_color1'] ?? null,
    'color2'     => $customer['usertype_color2'] ?? null,
    'text_color' => $customer['usertype_text_color'] ?? null,
];

// Return success response with properly formatted decimals
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Profile retrieved successfully.',
    'data' => [
        'usertype' => $usertype_info,
        'profile' => [
            'id' => $customer['id'],
            'name' => $customer['name'],
            'phone' => $customer['phone'],
            'address' => $customer['address'],
            'email' => $customer['email'],
            'usercode' => $usercode,
            'usertype' => $customer['usertype'],
            'usertype_name' => $customer_usertype_name,
            'is_active' => $customer['is_active'],
            'has_password' => $password_exists
        ],
        'account_info' => [
            'customer_id' => $customer_id,
            'customer_name' => $customer['name'],
            'customer_code' => 'C' . $customer_id,
            'usercode' => $usercode,
            'current_balance' => round($customer_balance, 2),
            'account_type' => $customer_usertype_name,
            'debt_limit' => round($customer_debt_limit, 2),
            'orders_awaiting_payment' => round($approved_unpaid_total, 2),
            'available_capacity' => round($customer_available_capacity, 2)
        ],
        'summary' => [
            'total_items' => $total_items,
            'active_items' => $active_items,
            'excluded_items' => $excluded_count,
            'total_purchases' => round($total_purchases, 2),
            'total_payments' => round($total_payments, 2),
            'total_paid_items' => round($total_paid_items, 2)
        ]
    ]
]);

// Close database connection
mysqli_close($conn);
?>

