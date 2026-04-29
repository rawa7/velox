<?php
/**
 * SHEIN Cart Extraction API for Flutter App
 *
 * Endpoint: /api/shein_extract.php
 * Method:   POST (JSON body { "shein_link": "..." }) or GET (?shein_link=...)
 *
 * Response on success:
 *   {
 *     "success": true,
 *     "message": "...",
 *     "items": [ { code, name, image, price, qty }, ... ],
 *     "total_items": N,
 *     "total_price": X.XX
 *   }
 *
 * Response on failure:
 *   {
 *     "success": false,
 *     "message": "...",
 *     "is_cart_share": true|false,   // true if link is clearly a cart share
 *     "items": [],
 *     "total_items": 0,
 *     "total_price": 0
 *   }
 *
 * The `is_cart_share` flag is read by the Flutter app so it can show a
 * cart-specific hint instead of falling back to the single-product API.
 *
 * NOTE: Prices are returned in USD (SHEIN's currency).
 *       Convert to local currency in the app using the current exchange rate.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

define('RAPIDAPI_KEY', '2a7b7d7ff7msh0fc41abd991d525p18c937jsn22528fc5c264');
define('RAPIDAPI_HOST', 'shein-api-v1.p.rapidapi.com');

$shein_link = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $shein_link = $input['shein_link'] ?? $_POST['shein_link'] ?? '';
} else {
    $shein_link = $_GET['shein_link'] ?? '';
}
$shein_link = trim((string)$shein_link);

function respond_fail($message, $is_cart_share = false) {
    echo json_encode([
        'success'       => false,
        'message'       => $message,
        'is_cart_share' => (bool)$is_cart_share,
        'items'         => [],
        'total_items'   => 0,
        'total_price'   => 0,
    ]);
    exit;
}

if (empty($shein_link)) {
    respond_fail('Missing parameter: shein_link');
}
if (stripos($shein_link, 'shein') === false) {
    respond_fail('Invalid SHEIN link. Please provide a valid SHEIN cart or share link.');
}

// ── Detect a cart-share URL ─────────────────────────────────────────────────
// These are share links produced by SHEIN's "Share my cart" feature.
$is_cart_share_url = (bool)preg_match(
    '#(api-shein\.shein\.com/h5/sharejump/appjump|shein\.com/h5/sharejump|shein\.com/share|shein\.top)#i',
    $shein_link
);

// ── Build a list of URL variants to try against the RapidAPI endpoint ───────
// The cart/shareurl endpoint is picky: sometimes it only resolves `appurl`
// instead of `appjump`, or prefers the shein.top short link. We try each
// variant in sequence and use the first one that returns a non-empty payload.
$variants = [$shein_link];

// Swap appjump ↔ appurl
if (stripos($shein_link, '/sharejump/appjump') !== false) {
    $variants[] = str_ireplace('/sharejump/appjump', '/sharejump/appurl', $shein_link);
}
if (stripos($shein_link, '/sharejump/appurl') !== false) {
    $variants[] = str_ireplace('/sharejump/appurl', '/sharejump/appjump', $shein_link);
}

// If the link has a `link=XXX` short code, try shein.top/XXX
$parsed_qs = [];
$qs = parse_url($shein_link, PHP_URL_QUERY);
if ($qs) { parse_str($qs, $parsed_qs); }
$short_code = $parsed_qs['link'] ?? $parsed_qs['code'] ?? $parsed_qs['share_code'] ?? null;
if ($short_code && preg_match('/^[A-Za-z0-9_\-]{4,}$/', $short_code)) {
    $variants[] = 'https://shein.top/' . $short_code;
}

$variants = array_values(array_unique($variants));

function call_shein_cart_api($url) {
    $api_url = 'https://' . RAPIDAPI_HOST . '/api/v1/cart/shareurl?link=' . urlencode($url);
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
            "currency: usd",
            "lang: en",
            "x-rapidapi-host: " . RAPIDAPI_HOST,
            "x-rapidapi-key: "  . RAPIDAPI_KEY,
        ],
    ]);
    $response  = curl_exec($curl);
    $http_code = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $err       = curl_error($curl);
    curl_close($curl);

    if ($err || $http_code !== 200 || !$response) {
        return null;
    }
    $data = json_decode($response, true);
    if (!is_array($data)) return null;
    return $data;
}

// ── Call the API for each variant until one returns real items ──────────────
$data_items = null;
$last_msg   = '';
foreach ($variants as $v) {
    $data = call_shein_cart_api($v);
    if (!$data) { $last_msg = 'API request failed'; continue; }
    if (empty($data['success']) || !isset($data['data'])) {
        $last_msg = 'API reported failure';
        continue;
    }
    $payload = $data['data'];
    if ($payload === null) { $last_msg = 'Empty payload'; continue; }

    // Some responses wrap items in data.goods
    if (is_array($payload) && isset($payload['goods']) && is_array($payload['goods'])) {
        $payload = $payload['goods'];
    }
    if (is_array($payload) && !empty($payload)) {
        $data_items = $payload;
        break;
    }
    $last_msg = 'No items in payload';
}

if (!is_array($data_items) || empty($data_items)) {
    respond_fail(
        $is_cart_share_url
            ? "We couldn't read the items in this SHEIN cart share. The link may have expired or be region-locked. Please open the link in SHEIN and paste the individual product URLs."
            : 'No items found. The link may be invalid or expired.',
        $is_cart_share_url
    );
}

// ── Normalize items ─────────────────────────────────────────────────────────
$products    = [];
$total_price = 0;
$total_qty   = 0;

foreach ($data_items as $item) {
    if (!is_array($item)) continue;

    $sku_code     = $item['goods_sn']   ?? 'UNKNOWN';
    $product_name = $item['goods_name'] ?? ($item['name'] ?? '');

    $image_url = '';
    if (!empty($item['goods_img'])) {
        $image_url = (strpos($item['goods_img'], 'http') === 0)
            ? $item['goods_img']
            : 'https:' . $item['goods_img'];
    } elseif (!empty($item['goods_thumb'])) {
        $image_url = (strpos($item['goods_thumb'], 'http') === 0)
            ? $item['goods_thumb']
            : 'https:' . $item['goods_thumb'];
    }

    $price = 0;
    foreach (['salePrice', 'sale_price', 'retailPrice', 'retail_price'] as $k) {
        if (isset($item[$k]['usdAmount'])) {
            $price = floatval($item[$k]['usdAmount']);
            if ($price > 0) break;
        }
    }

    $qty = isset($item['quantity']) ? (int)$item['quantity'] : 1;
    if ($qty < 1) $qty = 1;

    if (!empty($sku_code)) {
        $products[] = [
            'code'  => $sku_code,
            'name'  => $product_name,
            'image' => $image_url,
            'price' => $price,
            'qty'   => $qty,
        ];
        $total_price += $price * $qty;
        $total_qty   += $qty;
    }
}

if (count($products) === 0) {
    respond_fail('No valid items found in the cart', $is_cart_share_url);
}

echo json_encode([
    'success'     => true,
    'message'     => 'Successfully extracted ' . count($products) . ' items from SHEIN cart',
    'items'       => $products,
    'total_items' => $total_qty,
    'total_price' => round($total_price, 2),
]);
