<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
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

// Handle GET request - Retrieve notifications
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    
    // Check if mark_all_read parameter is present
    if (isset($_GET['mark_all_read']) && $_GET['mark_all_read'] == '1') {
        // Mark all notifications as read for this customer
        $update_query = "UPDATE notifications 
                        SET is_read = 1 
                        WHERE customer_id = $customer_id AND is_read = 0";
        
        if (mysqli_query($conn, $update_query)) {
            $affected_rows = mysqli_affected_rows($conn);
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'All notifications marked as read.',
                'data' => [
                    'customer_id' => $customer_id,
                    'notifications_marked' => $affected_rows
                ]
            ]);
            mysqli_close($conn);
            exit();
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Failed to mark notifications as read: ' . mysqli_error($conn)
            ]);
            mysqli_close($conn);
            exit();
        }
    }
    
    // Optional parameters
    $is_read = isset($_GET['is_read']) ? intval($_GET['is_read']) : null;
    $type = isset($_GET['type']) ? mysqli_real_escape_string($conn, $_GET['type']) : null;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 50;
    $offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
    
    // Build WHERE conditions
    $where_conditions = ["customer_id = $customer_id"];
    
    if ($is_read !== null) {
        $where_conditions[] = "is_read = $is_read";
    }
    
    if ($type !== null) {
        $where_conditions[] = "type = '$type'";
    }
    
    $where_clause = implode(' AND ', $where_conditions);
    
    // Get total count
    $count_query = "SELECT COUNT(*) as total FROM notifications WHERE $where_clause";
    $count_result = mysqli_query($conn, $count_query);
    $total_count = intval(mysqli_fetch_assoc($count_result)['total'] ?? 0);
    
    // Get unread count
    $unread_query = "SELECT COUNT(*) as unread FROM notifications WHERE customer_id = $customer_id AND is_read = 0";
    $unread_result = mysqli_query($conn, $unread_query);
    $unread_count = intval(mysqli_fetch_assoc($unread_result)['unread'] ?? 0);
    
    // Get notifications
    $query = "SELECT * FROM notifications 
              WHERE $where_clause 
              ORDER BY created_at DESC 
              LIMIT $limit OFFSET $offset";
    
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error occurred: ' . mysqli_error($conn)
        ]);
        exit();
    }
    
    $notifications = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $notifications[] = [
            'id' => intval($row['id']),
            'customer_id' => intval($row['customer_id']),
            'title' => $row['title'],
            'message' => $row['message'],
            'type' => $row['type'],
            'is_read' => intval($row['is_read']) === 1,
            'related_id' => $row['related_id'] ? intval($row['related_id']) : null,
            'related_type' => $row['related_type'],
            'created_at' => $row['created_at']
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Notifications retrieved successfully.',
        'data' => [
            'notifications' => $notifications,
            'total_count' => $total_count,
            'unread_count' => $unread_count,
            'current_count' => count($notifications),
            'limit' => $limit,
            'offset' => $offset
        ]
    ]);
    
    mysqli_close($conn);
    exit();
}

// Handle POST request - Create new notification (admin use)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    // Get JSON input
    $json_input = file_get_contents('php://input');
    $data = json_decode($json_input, true);
    
    // Validate required fields
    if (!isset($data['title']) || !isset($data['message'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Title and message are required.'
        ]);
        exit();
    }
    
    $title = mysqli_real_escape_string($conn, trim($data['title']));
    $message = mysqli_real_escape_string($conn, trim($data['message']));
    $type = isset($data['type']) ? mysqli_real_escape_string($conn, $data['type']) : 'general';
    $related_id = isset($data['related_id']) ? intval($data['related_id']) : null;
    $related_type = isset($data['related_type']) ? mysqli_real_escape_string($conn, $data['related_type']) : null;
    
    // Insert notification
    $insert_query = "INSERT INTO notifications (customer_id, title, message, type, related_id, related_type) 
                     VALUES ($customer_id, '$title', '$message', '$type', " . 
                     ($related_id ? $related_id : 'NULL') . ", " . 
                     ($related_type ? "'$related_type'" : 'NULL') . ")";
    
    if (mysqli_query($conn, $insert_query)) {
        $notification_id = mysqli_insert_id($conn);
        
        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'Notification created successfully.',
            'data' => [
                'notification_id' => $notification_id
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create notification: ' . mysqli_error($conn)
        ]);
    }
    
    mysqli_close($conn);
    exit();
}

// Handle PUT request - Mark notification(s) as read
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    
    // Get JSON input
    $json_input = file_get_contents('php://input');
    $data = json_decode($json_input, true);
    
    // Check if marking single notification or all
    if (isset($data['notification_id'])) {
        // Mark single notification as read
        $notification_id = intval($data['notification_id']);
        
        $update_query = "UPDATE notifications 
                        SET is_read = 1 
                        WHERE id = $notification_id AND customer_id = $customer_id";
        
        if (mysqli_query($conn, $update_query)) {
            $affected_rows = mysqli_affected_rows($conn);
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Notification marked as read.',
                'data' => [
                    'affected_rows' => $affected_rows
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Failed to update notification: ' . mysqli_error($conn)
            ]);
        }
    } elseif (isset($data['mark_all_read']) && $data['mark_all_read'] === true) {
        // Mark all notifications as read
        $update_query = "UPDATE notifications 
                        SET is_read = 1 
                        WHERE customer_id = $customer_id AND is_read = 0";
        
        if (mysqli_query($conn, $update_query)) {
            $affected_rows = mysqli_affected_rows($conn);
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'All notifications marked as read.',
                'data' => [
                    'affected_rows' => $affected_rows
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Failed to update notifications: ' . mysqli_error($conn)
            ]);
        }
    } else {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Either notification_id or mark_all_read must be provided.'
        ]);
    }
    
    mysqli_close($conn);
    exit();
}

// If method not supported
http_response_code(405);
echo json_encode([
    'success' => false,
    'message' => 'Method not allowed. Only GET, POST, and PUT requests are accepted.'
]);

mysqli_close($conn);
?>

