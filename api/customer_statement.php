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

// Get customer_id from query parameter
$customer_id = null;
if (isset($_GET['customer_id'])) {
    $customer_id = intval($_GET['customer_id']);
}

if (!$customer_id) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Customer ID is required. Please provide customer_id in request.'
    ]);
    exit();
}

// Get optional date filters
$date_from = isset($_GET['date_from']) ? mysqli_real_escape_string($conn, $_GET['date_from']) : '';
$date_to = isset($_GET['date_to']) ? mysqli_real_escape_string($conn, $_GET['date_to']) : '';

// Build date filter conditions
$items_date_where = "";
$payments_date_where = "";

if (!empty($date_from)) {
    $items_date_where .= " AND i.created_at >= '$date_from'";
    $payments_date_where .= " AND bp.date >= '$date_from'";
}
if (!empty($date_to)) {
    $items_date_where .= " AND i.created_at <= '$date_to 23:59:59'";
    $payments_date_where .= " AND bp.date <= '$date_to'";
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

// Get all items (separated into pending and completed)
$items_query = "SELECT i.*, s.name as status_name, w.name as website_name, f.web_path as image_path,
                       c.currencysign as currency_symbol, c.currencyname as currency_name
                FROM items i
                LEFT JOIN statue s ON i.status = s.id
                LEFT JOIN website w ON i.websiteid = w.id
                LEFT JOIN files f ON i.image = f.id
                LEFT JOIN currency c ON i.currency_id = c.id
                WHERE i.customer_id = $customer_id
                $items_date_where
                ORDER BY i.created_at DESC";
$items_result = mysqli_query($conn, $items_query);

if (!$items_result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred: ' . mysqli_error($conn)
    ]);
    exit();
}

$pending_items = [];
$completed_items = [];
$refunded_items = [];
$total_pending_items = 0;
$total_completed_items = 0;
$total_refunded_items = 0;
$pending_items_value = 0;
$completed_items_value = 0;
$refunded_items_value = 0;

while ($item = mysqli_fetch_assoc($items_result)) {
    // Add full image URL
    if (!empty($item['image_path'])) {
        $item['image_url'] = 'https://veloxshoppingiq.com' . $item['image_path'];
    } else {
        $item['image_url'] = null;
    }
    
    // Format decimal values
    $item['itemprice'] = round(floatval($item['itemprice'] ?? 0), 2);
    $item['totalprice'] = round(floatval($item['totalprice'] ?? 0), 2);
    $item['total_dinar'] = round(floatval($item['total_dinar'] ?? 0), 0);
    $item['cargo'] = round(floatval($item['cargo'] ?? 0), 2);
    $item['shippingprice'] = round(floatval($item['shippingprice'] ?? 0), 2);
    $item['tax'] = round(floatval($item['tax'] ?? 0), 2);
    $item['commission'] = round(floatval($item['commission'] ?? 0), 2);
    
    // Convert numeric fields to appropriate types
    $item['id'] = intval($item['id']);
    $item['status'] = intval($item['status']);
    $item['qty'] = intval($item['qty'] ?? 1);
    $item['paymentstatus'] = intval($item['paymentstatus'] ?? 0);
    
    // Categorize by status (using Iraqi Dinar values)
    if ($item['status'] == -2) {
        // Completed/Sold items (these count in balance)
        $completed_items[] = $item;
        $total_completed_items++;
        $completed_items_value += $item['total_dinar'];
    } elseif ($item['status'] == -3) {
        // Refunded items
        $refunded_items[] = $item;
        $total_refunded_items++;
        $refunded_items_value += $item['total_dinar'];
    } else {
        // Pending items (all other statuses)
        $pending_items[] = $item;
        $total_pending_items++;
        $pending_items_value += $item['total_dinar'];
    }
}

// Get payment history
$payments_query = "SELECT bp.*, b.name as buyer_name
                  FROM buyerpay bp
                  LEFT JOIN buyer b ON bp.buyerid = b.id
                  WHERE bp.buyerid = $customer_id
                  $payments_date_where
                  ORDER BY bp.date DESC";
$payments_result = mysqli_query($conn, $payments_query);

if (!$payments_result) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred: ' . mysqli_error($conn)
    ]);
    exit();
}

$payments = [];
$total_payments = 0;

while ($payment = mysqli_fetch_assoc($payments_result)) {
    $payment['id'] = intval($payment['id']);
    $payment['buyerid'] = intval($payment['buyerid']);
    $payment['amount'] = round(floatval($payment['amount']), 2);
    $payment['dinarconvert'] = round(floatval($payment['dinarconvert'] ?? 0), 2);
    
    $payments[] = $payment;
    $total_payments += $payment['amount'];
}

// Calculate balance (only completed items count)
// Balance = Total Completed Items Value - Total Payments
$balance = $completed_items_value - $total_payments;

// Get approved unpaid orders for capacity calculation (in Iraqi Dinar)
$approved_unpaid_query = "SELECT COALESCE(SUM(total_dinar), 0) as approved_unpaid 
                         FROM items 
                         WHERE customer_id = $customer_id 
                         AND status IN (3, 4, -1, 16, 17, 19) 
                         AND paymentstatus = 0";
$approved_unpaid_result = mysqli_query($conn, $approved_unpaid_query);
$approved_unpaid_total = round(floatval(mysqli_fetch_assoc($approved_unpaid_result)['approved_unpaid'] ?? 0), 0);

// Calculate available capacity (in Iraqi Dinar)
$debt_limit = round(floatval($customer['debt_limit'] ?? 0), 0);
$available_capacity = (-$balance) + $debt_limit - $approved_unpaid_total;

// Total items count
$total_items = $total_pending_items + $total_completed_items + $total_refunded_items;

// Get status counts for summary (in Iraqi Dinar)
$status_query = "SELECT s.id, s.name, COUNT(i.id) as count, COALESCE(SUM(i.total_dinar), 0) as total
                FROM statue s
                LEFT JOIN items i ON i.status = s.id AND i.customer_id = $customer_id
                GROUP BY s.id, s.name
                ORDER BY CASE WHEN s.id < 0 THEN 1 ELSE 0 END, s.id";
$status_result = mysqli_query($conn, $status_query);
$status_summary = [];

while ($status = mysqli_fetch_assoc($status_result)) {
    $status_summary[] = [
        'id' => intval($status['id']),
        'name' => $status['name'],
        'count' => intval($status['count']),
        'total' => round(floatval($status['total']), 0)
    ];
}

// Build response
$response = [
    'success' => true,
    'message' => 'Customer statement retrieved successfully.',
    'data' => [
        'customer' => [
            'id' => intval($customer['id']),
            'name' => $customer['name'],
            'email' => $customer['email'] ?? null,
            'phone' => $customer['phone'] ?? null,
            'address' => $customer['address'] ?? null,
            'usertype' => $customer['usertype_name'] ?? 'Unknown',
            'debt_limit' => $debt_limit
        ],
        'financial_summary' => [
            'completed_purchases_value' => round($completed_items_value, 0),
            'total_payments' => round($total_payments, 0),
            'current_balance' => round($balance, 0),
            'balance_status' => $balance > 0 ? 'due' : ($balance < 0 ? 'overpaid' : 'settled'),
            'pending_items_value' => round($pending_items_value, 0),
            'refunded_items_value' => round($refunded_items_value, 0),
            'orders_awaiting_payment' => $approved_unpaid_total,
            'available_capacity' => round($available_capacity, 0)
        ],
        'items_summary' => [
            'total_items' => $total_items,
            'pending_count' => $total_pending_items,
            'completed_count' => $total_completed_items,
            'refunded_count' => $total_refunded_items,
            'status_breakdown' => $status_summary
        ],
        'pending_items' => $pending_items,
        'completed_items' => $completed_items,
        'refunded_items' => $refunded_items,
        'payments' => $payments,
        'filters' => [
            'date_from' => $date_from ?: null,
            'date_to' => $date_to ?: null
        ]
    ]
];

http_response_code(200);
echo json_encode($response);

// Close database connection
mysqli_close($conn);
?>

