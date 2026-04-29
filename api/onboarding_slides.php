<?php
/**
 * Onboarding Slides API
 *
 * Endpoint : GET /api/onboarding_slides.php
 * Auth     : none (public)
 *
 * Response:
 * {
 *   "success": true,
 *   "slides": [
 *     {
 *       "id": 1,
 *       "slide_order": 1,
 *       "image_url": "https://veloxshoppingiq.com/uploads/onboarding/slide_1_xxx.jpg",
 *       "title_en": "Welcome",
 *       "title_ku": "بخێربێیت",
 *       "title_ar": "مرحباً",
 *       "body_en": "...",
 *       "body_ku": "...",
 *       "body_ar": "..."
 *     },
 *     ...
 *   ],
 *   "total": 3
 * }
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed.']);
    exit();
}

include '../resources/config.php';

$base_url = 'https://veloxshoppingiq.com';

$result = mysqli_query($conn, "SELECT * FROM onboarding_slides WHERE is_active = 1 ORDER BY slide_order ASC");

if (!$result) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error.', 'slides' => [], 'total' => 0]);
    exit();
}

$slides = [];
while ($row = mysqli_fetch_assoc($result)) {
    $slides[] = [
        'id'          => intval($row['id']),
        'slide_order' => intval($row['slide_order']),
        'image_url'   => !empty($row['image_path']) ? $base_url . $row['image_path'] : null,
        'title_en'    => $row['title_en'] ?? '',
        'title_ku'    => $row['title_ku'] ?? '',
        'title_ar'    => $row['title_ar'] ?? '',
        'body_en'     => $row['body_en']  ?? '',
        'body_ku'     => $row['body_ku']  ?? '',
        'body_ar'     => $row['body_ar']  ?? '',
    ];
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'slides'  => $slides,
    'total'   => count($slides),
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

mysqli_close($conn);
?>
