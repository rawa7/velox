<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include '../resources/config.php';

// Create shop_banners table if it doesn't exist
$createTableQuery = "
CREATE TABLE IF NOT EXISTS shop_banners (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    title_kurdish VARCHAR(255),
    title_arabic VARCHAR(255),
    description TEXT,
    description_kurdish TEXT,
    description_arabic TEXT,
    product_id INT NOT NULL,
    image_id INT,
    position INT DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES shop(id) ON DELETE CASCADE,
    FOREIGN KEY (image_id) REFERENCES files(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

if (!$conn->query($createTableQuery)) {
    echo json_encode(['error' => 'Failed to create shop_banners table: ' . $conn->error]);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Get all active banners with product and image details
        $query = "SELECT 
                    sb.id as banner_id,
                    sb.title,
                    sb.title_kurdish,
                    sb.title_arabic,
                    sb.description,
                    sb.description_kurdish,
                    sb.description_arabic,
                    sb.product_id,
                    sb.position,
                    sb.is_active,
                    sb.created_at,
                    p.item_name as product_name,
                    p.item_name_kurdish as product_name_kurdish,
                    p.item_name_arabic as product_name_arabic,
                    p.price as product_price,
                    p.item_category as product_category,
                    f.web_path as banner_image_path,
                    pf.web_path as product_image_path,
                    b.name as brand_name
                  FROM shop_banners sb
                  LEFT JOIN shop p ON sb.product_id = p.id
                  LEFT JOIN files f ON sb.image_id = f.id
                  LEFT JOIN files pf ON p.imageid = pf.id
                  LEFT JOIN brand b ON p.item_type = b.id
                  WHERE sb.is_active = 1
                  ORDER BY sb.position ASC, sb.id DESC";
        
        $result = $conn->query($query);
        
        if (!$result) {
            echo json_encode(['error' => 'Failed to fetch banners: ' . $conn->error]);
            exit();
        }
        
        $banners = [];
        while ($row = $result->fetch_assoc()) {
            // Helper function to build clean image URL
            $buildImageUrl = function($web_path) {
                if (!$web_path) return null;
                $clean_path = preg_replace('#^(\.\./|\./)+#', '', $web_path);
                if (strlen($clean_path) > 0 && $clean_path[0] !== '/') {
                    $clean_path = '/' . $clean_path;
                }
                return 'https://ruyadream.com/velox' . $clean_path;
            };
            
            $banners[] = [
                'banner_id' => $row['banner_id'],
                'title' => $row['title'],
                'title_kurdish' => $row['title_kurdish'],
                'title_arabic' => $row['title_arabic'],
                'description' => $row['description'],
                'description_kurdish' => $row['description_kurdish'],
                'description_arabic' => $row['description_arabic'],
                'product_id' => $row['product_id'],
                'product_name' => $row['product_name'],
                'product_name_kurdish' => $row['product_name_kurdish'],
                'product_name_arabic' => $row['product_name_arabic'],
                'product_price' => round(floatval($row['product_price']), 2),
                'product_category' => $row['product_category'],
                'brand_name' => $row['brand_name'],
                'position' => intval($row['position']),
                'banner_image' => $buildImageUrl($row['banner_image_path']),
                'product_image' => $buildImageUrl($row['product_image_path']),
                'created_at' => $row['created_at']
            ];
        }
        
        echo json_encode(['success' => true, 'data' => $banners]);
        break;
        
    case 'POST':
        // Create new banner
        $title = $_POST['title'] ?? '';
        $title_kurdish = $_POST['title_kurdish'] ?? '';
        $title_arabic = $_POST['title_arabic'] ?? '';
        $description = $_POST['description'] ?? '';
        $description_kurdish = $_POST['description_kurdish'] ?? '';
        $description_arabic = $_POST['description_arabic'] ?? '';
        $product_id = intval($_POST['product_id'] ?? 0);
        $position = intval($_POST['position'] ?? 0);
        $is_active = intval($_POST['is_active'] ?? 1);
        $image_id = null;
        
        if (!$title || !$product_id) {
            echo json_encode(['error' => 'Title and product_id are required']);
            exit();
        }
        
        // Verify product exists
        $product_check = $conn->query("SELECT id FROM shop WHERE id = $product_id");
        if ($product_check->num_rows === 0) {
            echo json_encode(['error' => 'Product not found']);
            exit();
        }
        
        // Handle banner image upload
        if (isset($_FILES['banner_image']) && $_FILES['banner_image']['error'] === UPLOAD_ERR_OK) {
            $upload_dir = '../uploads/';
            if (!is_dir($upload_dir)) {
                mkdir($upload_dir, 0755, true);
            }
            
            $file_info = pathinfo($_FILES['banner_image']['name']);
            $extension = strtolower($file_info['extension']);
            
            // Validate file type
            $allowed_types = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
            if (!in_array($extension, $allowed_types)) {
                echo json_encode(['error' => 'Invalid file type. Only JPG, PNG, GIF, and WEBP are allowed.']);
                exit();
            }
            
            // Validate file size (2MB limit for banners)
            if ($_FILES['banner_image']['size'] > 2000000) {
                echo json_encode(['error' => 'File size must be smaller than 2MB']);
                exit();
            }
            
            // Generate unique filename
            $filename = 'banner_' . uniqid() . '.' . $extension;
            $filepath = $upload_dir . $filename;
            
            if (move_uploaded_file($_FILES['banner_image']['tmp_name'], $filepath)) {
                // Insert into files table
                $insert_file_query = "INSERT INTO files (filename, filesize, web_path, system_path) VALUES (?, ?, ?, ?)";
                $stmt = $conn->prepare($insert_file_query);
                if ($stmt) {
                    $web_path = '/uploads/' . $filename;
                    $filesize = $_FILES['banner_image']['size'];
                    $stmt->bind_param('siss', $filename, $filesize, $web_path, $filepath);
                    if ($stmt->execute()) {
                        $image_id = $conn->insert_id;
                    }
                    $stmt->close();
                }
            }
        }
        
        $query = "INSERT INTO shop_banners (title, title_kurdish, title_arabic, description, description_kurdish, description_arabic, product_id, image_id, position, is_active) 
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            echo json_encode(['error' => 'Failed to prepare statement: ' . $conn->error]);
            exit();
        }
        
        $stmt->bind_param('ssssssiiis', $title, $title_kurdish, $title_arabic, $description, $description_kurdish, $description_arabic, $product_id, $image_id, $position, $is_active);
        
        if ($stmt->execute()) {
            $new_id = $conn->insert_id;
            echo json_encode(['success' => true, 'banner_id' => $new_id]);
        } else {
            echo json_encode(['error' => 'Failed to create banner: ' . $stmt->error]);
        }
        
        $stmt->close();
        break;
        
    case 'PUT':
        // Update banner
        parse_str(file_get_contents('php://input'), $_PUT);
        
        if (!isset($_PUT['banner_id'])) {
            echo json_encode(['error' => 'Missing banner_id']);
            exit();
        }
        
        $banner_id = intval($_PUT['banner_id']);
        $title = $_PUT['title'] ?? '';
        $title_kurdish = $_PUT['title_kurdish'] ?? '';
        $title_arabic = $_PUT['title_arabic'] ?? '';
        $description = $_PUT['description'] ?? '';
        $description_kurdish = $_PUT['description_kurdish'] ?? '';
        $description_arabic = $_PUT['description_arabic'] ?? '';
        $product_id = intval($_PUT['product_id'] ?? 0);
        $position = intval($_PUT['position'] ?? 0);
        $is_active = intval($_PUT['is_active'] ?? 1);
        $image_id = isset($_PUT['image_id']) ? intval($_PUT['image_id']) : null;
        
        if (!$title || !$product_id) {
            echo json_encode(['error' => 'Title and product_id are required']);
            exit();
        }
        
        $query = "UPDATE shop_banners SET 
                    title = ?, 
                    title_kurdish = ?, 
                    title_arabic = ?, 
                    description = ?, 
                    description_kurdish = ?, 
                    description_arabic = ?, 
                    product_id = ?, 
                    image_id = ?, 
                    position = ?, 
                    is_active = ?
                  WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            echo json_encode(['error' => 'Failed to prepare statement: ' . $conn->error]);
            exit();
        }
        
        $stmt->bind_param('ssssssiiii', $title, $title_kurdish, $title_arabic, $description, $description_kurdish, $description_arabic, $product_id, $image_id, $position, $is_active, $banner_id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['error' => 'Failed to update banner: ' . $stmt->error]);
        }
        
        $stmt->close();
        break;
        
    case 'DELETE':
        // Delete banner
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['banner_id'])) {
            echo json_encode(['error' => 'Missing banner_id']);
            exit();
        }
        
        $banner_id = intval($data['banner_id']);
        
        $query = "DELETE FROM shop_banners WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            echo json_encode(['error' => 'Failed to prepare statement: ' . $conn->error]);
            exit();
        }
        
        $stmt->bind_param('i', $banner_id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['error' => 'Failed to delete banner: ' . $stmt->error]);
        }
        
        $stmt->close();
        break;
        
    default:
        echo json_encode(['error' => 'Method not allowed']);
        break;
}

$conn->close();
?>

