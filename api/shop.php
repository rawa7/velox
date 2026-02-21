<?php




header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');


include '../resources/config.php';

// Create menu table if it doesn't exist
$createTableQuery = "
CREATE TABLE IF NOT EXISTS shop (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(255) NOT NULL,
    item_name_kurdish VARCHAR(255),
    item_name_arabic VARCHAR(255),
    item_type VARCHAR(100) NOT NULL,
    item_category VARCHAR(100) NOT NULL,
    item_category_kurdish VARCHAR(255),
    item_category_arabic VARCHAR(255),
    item_description TEXT,
    item_description_kurdish TEXT,
    item_description_arabic TEXT,
    price DECIMAL(10,2) NOT NULL,
    imageid INT,
    imageid2 INT,
    imageid3 INT,
    imageid4 INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (imageid) REFERENCES files(id) ON DELETE SET NULL,
    FOREIGN KEY (imageid2) REFERENCES files(id) ON DELETE SET NULL,
    FOREIGN KEY (imageid3) REFERENCES files(id) ON DELETE SET NULL,
    FOREIGN KEY (imageid4) REFERENCES files(id) ON DELETE SET NULL
)";

if (!$conn->query($createTableQuery)) {
        die(json_encode(['error' => 'Failed to create shop table: ' . $conn->error]));
}

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Check for query parameters
        $item_type = $_GET['item_type'] ?? null;
        $get_subcategories = isset($_GET['subcategories']) && $_GET['subcategories'] === 'true';
        
        if ($get_subcategories) {
            // Get subcategories grouped by brand
            $query = "SELECT DISTINCT s.item_type as brand_id, b.name as brand_name, s.item_category 
                     FROM shop s 
                     LEFT JOIN brand b ON s.item_type = b.id 
                     ORDER BY b.name, s.item_category";
            $result = $conn->query($query);
            
            if (!$result) {
                echo json_encode(['error' => 'Failed to fetch subcategories: ' . $conn->error]);
                exit();
            }
            
            $subcategories = [];
            while ($row = $result->fetch_assoc()) {
                $brand_name = $row['brand_name'] ?? 'Unknown';
                if (!isset($subcategories[$brand_name])) {
                    $subcategories[$brand_name] = [
                        'brand_id' => $row['brand_id'],
                        'categories' => []
                    ];
                }
                $subcategories[$brand_name]['categories'][] = $row['item_category'];
            }
            
            echo json_encode(['data' => $subcategories]);
            break;
        }
        
        // Build query with optional item_type filter (brand filter)
        $query = "SELECT 
                    m.id as item_id,
                    m.item_name,
                    m.item_name_kurdish,
                    m.item_name_arabic,
                    m.item_type as brand_id,
                    b.name as brand_name,
                    b.image as brand_image_id,
                    bf.web_path as brand_image_path,
                    m.item_category,
                    m.item_category_kurdish,
                    m.item_category_arabic,
                    m.price,
                    m.imageid,
                    m.imageid2,
                    m.imageid3,
                    m.imageid4,
                    f.filename,
                    f.web_path,
                    f2.web_path as web_path2,
                    f3.web_path as web_path3,
                    f4.web_path as web_path4,
                    m.item_description,
                    m.item_description_kurdish,
                    m.item_description_arabic,
                    f.system_path
                  FROM shop m 
                  LEFT JOIN files f ON m.imageid = f.id
                  LEFT JOIN files f2 ON m.imageid2 = f2.id
                  LEFT JOIN files f3 ON m.imageid3 = f3.id
                  LEFT JOIN files f4 ON m.imageid4 = f4.id
                  LEFT JOIN brand b ON m.item_type = b.id
                  LEFT JOIN files bf ON b.image = bf.id";
        
        $params = [];
        $types = "";
        
        if ($item_type) {
            $query .= " WHERE m.item_type = ?";
            $params[] = $item_type;
            $types .= "s";
        }
        
        $query .= " ORDER BY m.id DESC";
        
        if (!empty($params)) {
            $stmt = $conn->prepare($query);
            if (!$stmt) {
                echo json_encode(['error' => 'Failed to prepare statement: ' . $conn->error]);
                exit();
            }
            $stmt->bind_param($types, ...$params);
            $stmt->execute();
            $result = $stmt->get_result();
        } else {
            $result = $conn->query($query);
        }
        
        if (!$result) {
            echo json_encode(['error' => 'Failed to fetch menu items: ' . $conn->error]);
            exit();
        }
        
        $menu_items = [];
        while ($row = $result->fetch_assoc()) {
            // Helper function to build clean image URL
            $buildImageUrl = function($web_path) {
                if (!$web_path) return null;
                // Remove any leading '../' or './' and ensure path starts with /
                $clean_path = preg_replace('#^(\.\./|\./)+#', '', $web_path);
                if (strlen($clean_path) > 0 && $clean_path[0] !== '/') {
                    $clean_path = '/' . $clean_path;
                }
                return 'https://ruyadream.com/velox' . $clean_path;
            };
            
            $menu_items[] = [
                'item_id' => $row['item_id'],
                'item_name' => $row['item_name'],
                'item_name_kurdish' => $row['item_name_kurdish'],
                'item_name_arabic' => $row['item_name_arabic'],
                'brand_id' => $row['brand_id'],
                'brand_name' => $row['brand_name'],
                'brand_image_id' => $row['brand_image_id'],
                'brand_image_url' => $buildImageUrl($row['brand_image_path']),
                'item_category' => $row['item_category'],
                'item_category_kurdish' => $row['item_category_kurdish'],
                'item_category_arabic' => $row['item_category_arabic'],
                'price' => round(floatval($row['price']), 2),
                'imageid' => $buildImageUrl($row['web_path']),
                'imageid2' => $buildImageUrl($row['web_path2']),
                'imageid3' => $buildImageUrl($row['web_path3']),
                'imageid4' => $buildImageUrl($row['web_path4']),
                'image_path' => $buildImageUrl($row['web_path']),
                'filename' => $row['filename'],
                'item_description' => $row['item_description'],
                'item_description_kurdish' => $row['item_description_kurdish'],
                'item_description_arabic' => $row['item_description_arabic']
            ];
        }
        
        echo json_encode(['data' => $menu_items]);
        break;
        
    case 'POST':
        // Create new menu item
        $item_name = $_POST['item_name'] ?? '';
        $item_name_kurdish = $_POST['item_name_kurdish'] ?? '';
        $item_name_arabic = $_POST['item_name_arabic'] ?? '';
        $item_type = $_POST['item_type'] ?? '';
        $item_category = $_POST['item_category'] ?? '';
        $item_category_kurdish = $_POST['item_category_kurdish'] ?? '';
        $item_category_arabic = $_POST['item_category_arabic'] ?? '';
        $item_description = $_POST['item_description'] ?? '';
        $item_description_kurdish = $_POST['item_description_kurdish'] ?? '';
        $item_description_arabic = $_POST['item_description_arabic'] ?? '';
        $price = floatval($_POST['price'] ?? 0);
        $imageid = null;
        
        if (!isset($_POST['item_name']) || !isset($_POST['item_type']) || 
            !isset($_POST['item_category']) || !isset($_POST['price'])) {
            echo json_encode(['error' => 'Missing required fields']);
            exit();
        }
        
        // Handle file upload
        if (isset($_FILES['image_upload']) && $_FILES['image_upload']['error'] === UPLOAD_ERR_OK) {
            $upload_dir = '../uploads/';
            if (!is_dir($upload_dir)) {
                mkdir($upload_dir, 0755, true);
            }
            
            $file_info = pathinfo($_FILES['image_upload']['name']);
            $extension = strtolower($file_info['extension']);
            
            // Validate file type
            $allowed_types = ['jpg', 'jpeg', 'png', 'gif'];
            if (!in_array($extension, $allowed_types)) {
                echo json_encode(['error' => 'Invalid file type. Only JPG, PNG, and GIF are allowed.']);
                exit();
            }
            
            // Validate file size (500KB limit)
            if ($_FILES['image_upload']['size'] > 500000) {
                echo json_encode(['error' => 'File size must be smaller than 500KB']);
                exit();
            }
            
            // Generate unique filename
            $filename = uniqid() . '.' . $extension;
            $filepath = $upload_dir . $filename;
            
            if (move_uploaded_file($_FILES['image_upload']['tmp_name'], $filepath)) {
                // Insert into files table
                $insert_file_query = "INSERT INTO files (filename, filesize, web_path, system_path) VALUES (?, ?, ?, ?)";
                $stmt = $conn->prepare($insert_file_query);
                if ($stmt) {
                    $web_path = 'uploads/' . $filename;
                    $filesize = $_FILES['image_upload']['size'];
                    $stmt->bind_param('siss', $filename, $filesize, $web_path, $filepath);
                    if ($stmt->execute()) {
                        $imageid = $conn->insert_id;
                    }
                }
            }
        }
        
        $query = "INSERT INTO shop (item_name, item_name_kurdish, item_name_arabic, item_type, item_category, item_category_kurdish, item_category_arabic, item_description, item_description_kurdish, item_description_arabic, price, imageid) 
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            echo json_encode(['error' => 'Failed to prepare statement: ' . $conn->error]);
            exit();
        }
        
        $stmt->bind_param('ssssssssssdi', $item_name, $item_name_kurdish, $item_name_arabic, $item_type, $item_category, $item_category_kurdish, $item_category_arabic, $item_description, $item_description_kurdish, $item_description_arabic, $price, $imageid);
        
        if ($stmt->execute()) {
            $new_id = $conn->insert_id;
            echo json_encode(['success' => true, 'item_id' => $new_id]);
        } else {
            echo json_encode(['error' => 'Failed to create menu item: ' . $stmt->error]);
        }
        break;
        
    case 'PUT':
        // Update menu item
        parse_str(file_get_contents('php://input'), $_PUT);
        
        if (!isset($_PUT['item_id'])) {
            echo json_encode(['error' => 'Missing item_id']);
            exit();
        }
        
        $item_id = intval($_PUT['item_id']);
        $item_name = $_PUT['item_name'] ?? '';
        $item_name_kurdish = $_PUT['item_name_kurdish'] ?? '';
        $item_name_arabic = $_PUT['item_name_arabic'] ?? '';
        $item_type = $_PUT['item_type'] ?? '';
        $item_category = $_PUT['item_category'] ?? '';
        $item_category_kurdish = $_PUT['item_category_kurdish'] ?? '';
        $item_category_arabic = $_PUT['item_category_arabic'] ?? '';
        $item_description = $_PUT['item_description'] ?? '';
        $item_description_kurdish = $_PUT['item_description_kurdish'] ?? '';
        $item_description_arabic = $_PUT['item_description_arabic'] ?? '';
        $price = floatval($_PUT['price'] ?? 0);
        $imageid = isset($_PUT['imageid']) ? intval($_PUT['imageid']) : null;
        
        // Handle file upload for update
        if (isset($_FILES['image_upload']) && $_FILES['image_upload']['error'] === UPLOAD_ERR_OK) {
            $upload_dir = '../uploads/';
            if (!is_dir($upload_dir)) {
                mkdir($upload_dir, 0755, true);
            }
            
            $file_info = pathinfo($_FILES['image_upload']['name']);
            $extension = strtolower($file_info['extension']);
            
            // Validate file type
            $allowed_types = ['jpg', 'jpeg', 'png', 'gif'];
            if (!in_array($extension, $allowed_types)) {
                echo json_encode(['error' => 'Invalid file type. Only JPG, PNG, and GIF are allowed.']);
                exit();
            }
            
            // Validate file size (500KB limit)
            if ($_FILES['image_upload']['size'] > 500000) {
                echo json_encode(['error' => 'File size must be smaller than 500KB']);
                exit();
            }
            
            // Generate unique filename
            $filename = uniqid() . '.' . $extension;
            $filepath = $upload_dir . $filename;
            
            if (move_uploaded_file($_FILES['image_upload']['tmp_name'], $filepath)) {
                // Insert into files table
                $insert_file_query = "INSERT INTO files (filename, filesize, web_path, system_path) VALUES (?, ?, ?, ?)";
                $stmt = $conn->prepare($insert_file_query);
                if ($stmt) {
                    $web_path = 'uploads/' . $filename;
                    $filesize = $_FILES['image_upload']['size'];
                    $stmt->bind_param('siss', $filename, $filesize, $web_path, $filepath);
                    if ($stmt->execute()) {
                        $imageid = $conn->insert_id;
                    }
                }
            }
        }
        
        $query = "UPDATE shop SET 
                    item_name = ?, 
                    item_name_kurdish = ?, 
                    item_name_arabic = ?, 
                    item_type = ?, 
                    item_category = ?, 
                    item_category_kurdish = ?, 
                    item_category_arabic = ?, 
                    item_description = ?, 
                    item_description_kurdish = ?, 
                    item_description_arabic = ?, 
                    price = ?, 
                    imageid = ? 
                  WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            echo json_encode(['error' => 'Failed to prepare statement: ' . $conn->error]);
            exit();
        }
        
        $stmt->bind_param('ssssssssssdii', $item_name, $item_name_kurdish, $item_name_arabic, $item_type, $item_category, $item_category_kurdish, $item_category_arabic, $item_description, $item_description_kurdish, $item_description_arabic, $price, $imageid, $item_id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['error' => 'Failed to update menu item: ' . $stmt->error]);
        }
        break;
        
    case 'DELETE':
        // Delete menu item
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['item_id'])) {
            echo json_encode(['error' => 'Missing item_id']);
            exit();
        }
        
        $item_id = intval($data['item_id']);
        
                $query = "DELETE FROM shop WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            echo json_encode(['error' => 'Failed to prepare statement: ' . $conn->error]);
            exit();
        }
        
        $stmt->bind_param('i', $item_id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['error' => 'Failed to delete menu item: ' . $stmt->error]);
        }
        break;
        
    default:
        echo json_encode(['error' => 'Method not allowed']);
        break;
}
?>
