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
$customer_query = "SELECT b.*, ut.name as usertype_name, ut.limitt as debt_limit 
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

// All amounts in Iraqi Dinar (د.ع)
// Balance = total payments (dinar) - total paid items (total_dinar)
$balance_query = "SELECT 
                (SELECT COALESCE(SUM(amount), 0) FROM buyerpay WHERE buyerid = $customer_id) -
                (SELECT COALESCE(SUM(COALESCE(NULLIF(TRIM(total_dinar), ''), 0)), 0) FROM items WHERE customer_id = $customer_id AND paymentstatus = 1) 
                AS available_balance";
$balance_result = query($balance_query);
$customer_balance = floatval(mysqli_fetch_assoc($balance_result)['available_balance'] ?? 0);

// Approved unpaid orders total in dinar
$approved_unpaid_query = "SELECT COALESCE(SUM(COALESCE(NULLIF(TRIM(total_dinar), ''), 0)), 0) as approved_unpaid 
                         FROM items 
                         WHERE customer_id = $customer_id 
                         AND status IN (3, 4, -1, 16, 17, 19) 
                         AND paymentstatus = 0";
$approved_unpaid_result = query($approved_unpaid_query);
$approved_unpaid_total = floatval(mysqli_fetch_assoc($approved_unpaid_result)['approved_unpaid'] ?? 0);

// Get debt limit (in dinar)
$customer_debt_limit = floatval($customer['debt_limit'] ?? 0);
$customer_usertype_name = $customer['usertype_name'] ?? 'Unknown';

// Available capacity in dinar
$customer_available_capacity = $customer_balance + $customer_debt_limit - $approved_unpaid_total;

// Get total items count
$total_items_query = "SELECT COUNT(*) as total_items FROM items WHERE customer_id = $customer_id";
$total_items_result = mysqli_query($conn, $total_items_query);
$total_items = intval(mysqli_fetch_assoc($total_items_result)['total_items'] ?? 0);

// Total purchases in dinar (all orders total_dinar)
$total_purchases_query = "SELECT COALESCE(SUM(COALESCE(NULLIF(TRIM(total_dinar), ''), 0)), 0) as total_purchases 
                         FROM items 
                         WHERE customer_id = $customer_id";
$total_purchases_result = mysqli_query($conn, $total_purchases_query);
$total_purchases = floatval(mysqli_fetch_assoc($total_purchases_result)['total_purchases'] ?? 0);

// Total payments made (buyerpay.amount assumed in dinar)
$total_payments_query = "SELECT COALESCE(SUM(amount), 0) as total_payments FROM buyerpay WHERE buyerid = $customer_id";
$total_payments_result = mysqli_query($conn, $total_payments_query);
$total_payments = floatval(mysqli_fetch_assoc($total_payments_result)['total_payments'] ?? 0);

// Total paid items in dinar
$total_paid_items_query = "SELECT COALESCE(SUM(COALESCE(NULLIF(TRIM(total_dinar), ''), 0)), 0) as total_paid FROM items WHERE customer_id = $customer_id AND paymentstatus = 1";
$total_paid_items_result = mysqli_query($conn, $total_paid_items_query);
$total_paid_items = floatval(mysqli_fetch_assoc($total_paid_items_result)['total_paid'] ?? 0);

// Get excluded statuses count
$excluded_status_ids = [6, 14];
$excluded_query = "SELECT COUNT(*) as excluded_count FROM items WHERE customer_id = $customer_id AND status IN (" . implode(',', $excluded_status_ids) . ")";
$excluded_result = mysqli_query($conn, $excluded_query);
$excluded_count = intval(mysqli_fetch_assoc($excluded_result)['excluded_count'] ?? 0);

// Calculate active items (excluding rejected/cancelled)
$active_items = $total_items - $excluded_count;

// Return success response with properly formatted decimals
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Profile retrieved successfully.',
    'data' => [
        'profile' => [
            'id' => $customer['id'],
            'name' => $customer['name'],
            'phone' => $customer['phone'],
            'address' => $customer['address'],
            'email' => $customer['email'],
            'usertype' => $customer['usertype'],
            'usertype_name' => $customer_usertype_name,
            'is_active' => $customer['is_active'],
            'has_password' => $password_exists
        ],
        'account_info' => [
            'customer_id' => $customer_id,
            'customer_name' => $customer['name'],
            'customer_code' => 'C' . $customer_id,
            'current_balance' => round($customer_balance, 0),
            'account_type' => $customer_usertype_name,
            'debt_limit' => round($customer_debt_limit, 0),
            'orders_awaiting_payment' => round($approved_unpaid_total, 0),
            'available_capacity' => round($customer_available_capacity, 0)
        ],
        'summary' => [
            'total_items' => $total_items,
            'active_items' => $active_items,
            'excluded_items' => $excluded_count,
            'total_purchases' => round($total_purchases, 0),
            'total_payments' => round($total_payments, 0),
            'total_paid_items' => round($total_paid_items, 0)
        ]
    ]
]);

// Close database connection
mysqli_close($conn);
?>

