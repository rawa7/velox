<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('memory_limit', '256M');
ini_set('max_execution_time', 60);

ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    ob_end_clean();
    exit();
}

try {

function fetchPageContent($url) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_MAXREDIRS, 10);
    curl_setopt($ch, CURLOPT_TIMEOUT, 20);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    curl_setopt($ch, CURLOPT_REFERER, 'https://www.shein.com/');
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language: en-US,en;q=0.5'
    ]);
    $response = curl_exec($ch);
    $finalUrl = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
    $error = curl_error($ch);
    curl_close($ch);
    if ($error) {
        return ['content' => null, 'final_url' => $url, 'error' => $error];
    }
    return ['content' => $response, 'final_url' => $finalUrl, 'error' => null];
}

function extractIdFromSharePage($url) {
    $result = fetchPageContent($url);
    if ($result['error'] || !$result['content']) return null;
    $content = $result['content'];
    $finalUrl = $result['final_url'];
    if (preg_match('/-p-(\d+)\.html/i', $finalUrl, $matches)) return $matches[1];
    if (preg_match('/var\s+shareInfo\s*=\s*(\{[^;]+\})\s*;?/s', $content, $matches)) {
        $shareInfo = json_decode($matches[1], true);
        if ($shareInfo && json_last_error() === JSON_ERROR_NONE) {
            if (!empty($shareInfo['id']) && is_numeric($shareInfo['id'])) return $shareInfo['id'];
            if (!empty($shareInfo['shareId']) && is_numeric($shareInfo['shareId'])) return $shareInfo['shareId'];
        }
    }
    if (preg_match('/-p-(\d{5,})\.html/i', $content, $matches)) return $matches[1];
    if (preg_match('/["\']id["\']\s*:\s*["\'](\d{5,})["\']/i', $content, $matches)) return $matches[1];
    return null;
}

function extractSheinProductId($url) {
    $cleanUrl = strtok($url, '?');
    if (preg_match('/-p-(\d+)\.html/i', $cleanUrl, $matches)) return $matches[1];
    if (preg_match('/-p-(\d+)/i', $cleanUrl, $matches)) return $matches[1];
    if (preg_match('/(\d{8,})\.html/i', $cleanUrl, $matches)) return $matches[1];

    // SHEIN category/recommendation links carry the goods_id as ?adp=XXXXXXXX
    $queryString = parse_url($url, PHP_URL_QUERY);
    if ($queryString) {
        parse_str($queryString, $params);
        if (!empty($params['adp']) && is_numeric($params['adp'])) return $params['adp'];
        if (!empty($params['goods_id']) && is_numeric($params['goods_id'])) return $params['goods_id'];
        if (!empty($params['goodsId']) && is_numeric($params['goodsId'])) return $params['goodsId'];
    }

    $isShareLink = preg_match('/api-shein\.shein\.com|sharejump|shein\.com\/h5\/share|shein\.com\/share/i', $url);
    if ($isShareLink) {
        $productId = extractIdFromSharePage($url);
        if ($productId) return $productId;
        return null;
    }

    if (preg_match('/^\d{5,}$/', trim($url))) return trim($url);

    // Fallback: follow redirects and check the final URL / page content
    // Handles links that don't contain -p- directly but redirect to a product page
    $result = fetchPageContent($url);
    if (!$result['error'] && $result['content']) {
        $finalUrl = $result['final_url'];
        if (preg_match('/-p-(\d+)\.html/i', $finalUrl, $matches)) return $matches[1];
        if (preg_match('/-p-(\d+)/i', $finalUrl, $matches)) return $matches[1];
        // Also scan the page content for the first product link
        if (preg_match('/-p-(\d{5,})\.html/i', $result['content'], $matches)) return $matches[1];
        // goods_id in JSON blobs embedded in the page
        if (preg_match('/["\']goods_id["\']\s*:\s*["\']?(\d{5,})["\']?/i', $result['content'], $matches)) return $matches[1];
    }

    return null;
}

/**
 * Scrape a SHEIN product page and extract name, image, goods_sn, price.
 * Uses og: meta tags and JSON blobs embedded in the page.
 */
function scrapeSheinPage($url, $productId) {
    $result = fetchPageContent($url);
    if ($result['error'] || empty($result['content'])) return null;
    $html = $result['content'];

    $name    = '';
    $image   = '';
    $goodsSn = '';
    $price   = '';

    // Product name — og:title is most reliable
    if (preg_match('/<meta[^>]+property=["\']og:title["\'][^>]+content=["\']([^"\']+)["\']/', $html, $m)) {
        $name = html_entity_decode(trim(preg_replace('/\s*[\|\-]\s*SHEIN.*$/i', '', $m[1])));
    }
    if (!$name && preg_match('/<title>([^<]+)<\/title>/i', $html, $m)) {
        $name = html_entity_decode(trim(preg_replace('/\s*[\|\-]\s*SHEIN.*$/i', '', $m[1])));
    }

    // Product image — og:image is fastest
    if (preg_match('/<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']/', $html, $m)) {
        $image = $m[1];
    }
    // Fallback: first ltwebstatic image URL in scripts
    if (!$image && preg_match('/https:\/\/img\.ltwebstatic\.com\/[^\s"\']+\.jpg/i', $html, $m)) {
        $image = $m[1];
    }

    // goods_sn — look in embedded JSON
    if (preg_match('/["\']goods_sn["\']\s*:\s*["\']([^"\']+)["\']/', $html, $m)) {
        $goodsSn = $m[1];
    } elseif (preg_match('/["\']goodsSn["\']\s*:\s*["\']([^"\']+)["\']/', $html, $m)) {
        $goodsSn = $m[1];
    }

    // Price — retailPrice or salePrice in embedded JSON
    if (preg_match('/["\']retailPrice["\']\s*:\s*\{[^}]*["\']amount["\']\s*:\s*["\']([^"\']+)["\']/', $html, $m)) {
        $price = preg_replace('/[^\d.]/', '', $m[1]);
    } elseif (preg_match('/["\']salePrice["\']\s*:\s*\{[^}]*["\']amount["\']\s*:\s*["\']([^"\']+)["\']/', $html, $m)) {
        $price = preg_replace('/[^\d.]/', '', $m[1]);
    }

    // Normalize protocol-relative image URLs
    if (strpos($image, '//') === 0) $image = 'https:' . $image;
    if (strpos($image, '?') !== false) $image = strtok($image, '?');

    if ($name || $image) {
        return [
            'goods_id' => $productId,
            'goods_sn' => $goodsSn,
            'name'     => $name,
            'image'    => $image,
            'price'    => $price,
            'source'   => 'scrape',
        ];
    }
    return null;
}

function fetchSheinProduct($productId, $originalUrl = null) {
    // ── Primary: scrape the product page directly ──────────────────────────
    // Try the original URL first, then construct fallback URLs
    $urlsToTry = [];
    if ($originalUrl) $urlsToTry[] = $originalUrl;
    $urlsToTry[] = "https://us.shein.com/p-{$productId}.html";
    $urlsToTry[] = "https://m.shein.com/us/p-{$productId}.html";

    foreach ($urlsToTry as $tryUrl) {
        $scraped = scrapeSheinPage($tryUrl, $productId);
        if ($scraped) {
            return ['success' => true, 'product_id' => $productId, 'product' => $scraped];
        }
    }

    // ── Fallback: RapidAPI ─────────────────────────────────────────────────
    $curl = curl_init();
    curl_setopt_array($curl, [
        CURLOPT_URL            => "https://shein-api-v1.p.rapidapi.com/api/v1/product/productDetail5/" . $productId,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 30,
        CURLOPT_CUSTOMREQUEST  => "GET",
        CURLOPT_HTTPHEADER     => [
            "currency: usd", "lang: en",
            "x-rapidapi-host: shein-api-v1.p.rapidapi.com",
            "x-rapidapi-key: 2a7b7d7ff7msh0fc41abd991d525p18c937jsn22528fc5c264",
        ],
    ]);
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    curl_close($curl);

    if (empty($response)) return ['success' => false, 'error' => 'Could not fetch product data'];
    $data = json_decode($response, true);
    if (!$data || $httpCode !== 200) return ['success' => false, 'error' => 'API HTTP ' . $httpCode];

    $detail = $data['info']['detail'] ?? $data['data']['detail'] ?? $data['detail']
           ?? $data['info']          ?? $data['data']            ?? $data;

    $name    = $detail['goods_name'] ?? $detail['goodsName'] ?? $detail['name']  ?? '';
    $goodsSn = $detail['goods_sn']   ?? $detail['goodsSn']   ?? '';
    $image   = $detail['goods_img']  ?? $detail['main_image'] ?? $detail['goodsImg'] ?? '';
    if (strpos($image, '//') === 0) $image = 'https:' . $image;
    if (strpos($image, '?')  !== false) $image = strtok($image, '?');

    $price = '';
    foreach (['retailPrice', 'salePrice'] as $pk) {
        if (!isset($detail[$pk])) continue;
        $raw = is_array($detail[$pk]) ? ($detail[$pk]['usdAmount'] ?? $detail[$pk]['amount'] ?? '') : (string)$detail[$pk];
        $raw = preg_replace('/[^\d.]/', '', $raw);
        if ($raw) { $price = $raw; break; }
    }

    return [
        'success'    => true,
        'product_id' => $productId,
        'product'    => ['goods_id' => $productId, 'goods_sn' => $goodsSn, 'name' => $name, 'image' => $image, 'price' => $price, 'source' => 'rapidapi'],
    ];
}

$method   = $_SERVER['REQUEST_METHOD'];
$sheinUrl = '';

if ($method === 'GET') {
    $sheinUrl = isset($_GET['url']) ? trim($_GET['url']) : '';
} else {
    $input = json_decode(file_get_contents('php://input'), true);
    $sheinUrl = $input['url'] ?? $_POST['url'] ?? '';
    $sheinUrl = trim($sheinUrl);
}

if (empty($sheinUrl)) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing url parameter']);
    exit();
}

$productId = extractSheinProductId($sheinUrl);

if (!$productId) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Could not extract product ID from URL', 'url' => $sheinUrl]);
    exit();
}

$result = fetchSheinProduct($productId, $sheinUrl);
ob_end_clean();

if (!$result['success']) {
    http_response_code(500);
}

echo json_encode($result, JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
} catch (Error $e) {
    ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
