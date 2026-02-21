<?php

include "../resources/config.php";


$sql = "SELECT id, image, link, position FROM banners WHERE is_active = 1 ORDER BY position ASC";
$result = $conn->query($sql);

$banners = [];
while ($row = $result->fetch_assoc()) {
    $row['image'] = 'https://ruyadream.com/velox'.filesimage($row['image']);
    $banners[] = $row;
}

header('Content-Type: application/json');
echo json_encode($banners);
?>
