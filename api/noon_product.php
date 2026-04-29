<?php
/**
 * Noon Single-Product Extraction API for the Flutter app.
 *
 * Endpoint: /api/noon_product.php
 * Method:   POST (JSON body { "url": "..." }) or GET (?url=...)
 *
 * Proxies the `noon6` RapidAPI service so the mobile app doesn't have to ship
 * the API key or deal with the raw response shape. Returns a normalized
 * payload shaped like `shein1product.php`:
 *
 *   {
 *     "success":    true|false,
 *     "product_id": String,
 *     "product": {
 *       "goods_id":  String,
 *       "goods_sn":  String,   // noon SKU, e.g. ZEAC849D301D69FA6C298Z
 *       "name":      String,
 *       "brand":     String,
 *       "image":     String,   // first image URL
 *       "images":    [ String, ... ],
 *       "price":     String    // "" if unknown
 *     }
 *   }
 *
 * Prices are returned as-is from noon6 (usually AED/SAR). The app already
 * handles currency conversion from the order's currency to Iraqi Dinar.
 */

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('memory_limit', '256M');
ini_set('max_execution_time', 45);

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

define('NOON_RAPIDAPI_HOST', 'noon6.p.rapidapi.com');
define('NOON_RAPIDAPI_KEY',  '2a7b7d7ff7msh0fc41abd991d525p18c937jsn22528fc5c264');

/**
 * Call the noon6 RapidAPI endpoint with the given noon URL and return the
 * decoded payload, or null on any error.
 */
function callNoonApi($noonUrl) {
    $api_url = 'https://' . NOON_RAPIDAPI_HOST . '/product-details?url=' . urlencode($noonUrl);

    $curl = curl_init();
    curl_setopt_array($curl, [
        CURLOPT_URL            => $api_url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING       => "",
        CURLOPT_MAXREDIRS      => 10,
        CURLOPT_TIMEOUT        => 30,
        CURLOPT_HTTP_VERSION   => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST  => "GET",
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_HTTPHEADER     => [
            "Content-Type: application/json",
            "x-rapidapi-host: " . NOON_RAPIDAPI_HOST,
            "x-rapidapi-key: "  . NOON_RAPIDAPI_KEY,
        ],
    ]);
    $response  = curl_exec($curl);
    $err       = curl_error($curl);
    $http_code = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    curl_close($curl);

    if ($err || empty($response)) {
        return ['raw' => null, 'http' => $http_code, 'error' => $err ?: 'Empty response'];
    }
    $data = json_decode($response, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        return ['raw' => $response, 'http' => $http_code, 'error' => 'Invalid JSON from noon6'];
    }
    return ['raw' => $data, 'http' => $http_code, 'error' => null];
}

/**
 * Pick the best price available from the noon6 response.
 *
 * The noon6 endpoint often returns a null top-level `price` even for real
 * products. When that happens we try, in order:
 *   1. Top-level `price` / `sale_price`
 *   2. A variant whose sku starts with the main sku (i.e. belongs to THIS
 *      product — noon variants share the base sku and add a suffix).
 * We deliberately IGNORE `offers[]` here: those are cross-sell items with
 * unrelated SKUs, so their prices don't belong to the current product.
 */
function pickNoonPrice($data) {
    $topPrice = $data['sale_price'] ?? $data['price'] ?? null;
    if (is_numeric($topPrice) && $topPrice > 0) {
        return (string)$topPrice;
    }

    $mainSku = isset($data['sku']) ? strtoupper((string)$data['sku']) : '';
    if (!empty($data['variants']) && is_array($data['variants'])) {
        foreach ($data['variants'] as $v) {
            if (!is_array($v)) continue;
            $vSku = isset($v['sku']) ? strtoupper((string)$v['sku']) : '';
            // Only trust the variant if its sku is clearly a child of the
            // product's sku (same prefix). Otherwise it might be unrelated.
            if ($mainSku !== '' && strpos($vSku, $mainSku) !== 0) continue;
            $vp = $v['sale_price'] ?? $v['price'] ?? null;
            if (is_numeric($vp) && $vp > 0) {
                return (string)$vp;
            }
        }
    }

    return '';
}

/**
 * Light URL cleanup. We pass the URL almost as-is to noon6 — it handles
 * most share/locale variations internally — but we strip tracking params
 * that can occasionally throw it off.
 */
function cleanNoonUrl($url) {
    $url = trim($url);
    $parts = parse_url($url);
    if (!$parts || empty($parts['host'])) return $url;

    $drop = ['utm_source','utm_medium','utm_campaign','utm_term','utm_content',
             'gclid','fbclid','ref','referrer'];
    if (!empty($parts['query'])) {
        parse_str($parts['query'], $qs);
        foreach ($drop as $k) unset($qs[$k]);
        $parts['query'] = http_build_query($qs);
    }

    $scheme = $parts['scheme'] ?? 'https';
    $host   = $parts['host'];
    $path   = $parts['path'] ?? '';
    $q      = !empty($parts['query']) ? '?' . $parts['query'] : '';
    return $scheme . '://' . $host . $path . $q;
}

// ── Read input ──────────────────────────────────────────────────────────────
$method  = $_SERVER['REQUEST_METHOD'];
$noonUrl = '';
if ($method === 'GET') {
    $noonUrl = isset($_GET['url']) ? trim($_GET['url']) : '';
} else {
    $input   = json_decode(file_get_contents('php://input'), true);
    $noonUrl = $input['url'] ?? $_POST['url'] ?? '';
    $noonUrl = trim((string)$noonUrl);
}

if (empty($noonUrl)) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing url parameter']);
    exit();
}

if (stripos($noonUrl, 'noon.com') === false) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Not a noon.com URL']);
    exit();
}

// Noon's mobile web often shows category/store URLs in the address bar
// (e.g. https://www.noon.com/uae-en/noon-supermarket/) instead of the real
// product URL. Those have no SKU and can't be resolved — fail fast with a
// dedicated flag so the app can show a "use the Share button" hint.
if (!preg_match('#/([ZN][A-Z0-9]{8,})/p(?:/|\?|$)#', $noonUrl)) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode([
        'success'         => false,
        'needs_share_url' => true,
        'error'           => 'This noon link has no product ID. Open the product on noon and tap Share to copy the real product link.',
    ]);
    exit();
}

// ── Call the API ────────────────────────────────────────────────────────────
$cleanUrl = cleanNoonUrl($noonUrl);
$result   = callNoonApi($cleanUrl);

if ($result['error'] !== null || !is_array($result['raw'])) {
    ob_end_clean();
    http_response_code(502);
    echo json_encode([
        'success'   => false,
        'error'     => 'Noon API error: ' . ($result['error'] ?? 'unknown'),
        'http_code' => $result['http'] ?? 0,
    ]);
    exit();
}

$data = $result['raw'];

// The RapidAPI wrapper uses `status: success` / `status: error`, OR some
// errors come back as `{ "error": "Unknown error" }` with HTTP 200.
if (isset($data['error']) && empty($data['title'])) {
    ob_end_clean();
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'error'   => 'Noon: ' . (string)$data['error'],
    ]);
    exit();
}
if (isset($data['status']) && $data['status'] !== 'success') {
    ob_end_clean();
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'error'   => 'Noon: unexpected status ' . (string)$data['status'],
    ]);
    exit();
}

// ── Normalize ───────────────────────────────────────────────────────────────
$sku   = isset($data['sku'])   ? (string)$data['sku']   : '';
$title = isset($data['title']) ? (string)$data['title'] : '';
$brand = isset($data['brand']) ? (string)$data['brand'] : '';

$images = [];
if (!empty($data['images']) && is_array($data['images'])) {
    foreach ($data['images'] as $img) {
        if (is_string($img) && $img !== '') $images[] = $img;
    }
}
$image = !empty($images) ? $images[0] : '';

$price = pickNoonPrice($data);

$product = [
    'goods_id' => $sku,
    'goods_sn' => $sku,
    'name'     => $title,
    'brand'    => $brand,
    'image'    => $image,
    'images'   => $images,
    'price'    => $price,
];

ob_end_clean();
echo json_encode([
    'success'    => true,
    'product_id' => $sku,
    'product'    => $product,
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

} catch (Exception $e) {
    ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
} catch (Error $e) {
    ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
