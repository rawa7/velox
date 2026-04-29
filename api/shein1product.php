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

/**
 * Try to pull a product ID out of a SHEIN share page.
 *
 * Returns `null` for clear failures and `'__CART_SHARE__'` as a special
 * sentinel when the page is a cart share (multiple items). The caller should
 * NOT fall back to scanning the page for arbitrary product IDs in that case,
 * because the share page also shows unrelated "recommended" products whose
 * IDs would otherwise be picked up and misrepresented as the user's item.
 */
function extractIdFromSharePage($url) {
    $result = fetchPageContent($url);
    if ($result['error'] || !$result['content']) return null;
    $content = $result['content'];
    $finalUrl = $result['final_url'];

    if (preg_match('/-p-(\d+)\.html/i', $finalUrl, $matches)) return $matches[1];

    // Inspect the shareInfo blob SHEIN embeds in the HTML. It tells us whether
    // the share is a single product or a cart. For cart shares we bail out
    // early instead of guessing a product ID from page recommendations.
    if (preg_match('/var\s+shareInfo\s*=\s*(\{[^;]+\})\s*;?/s', $content, $matches)) {
        $shareInfo = json_decode($matches[1], true);
        if ($shareInfo && json_last_error() === JSON_ERROR_NONE) {
            $isCartShare = !empty($shareInfo['cart_share']);
            if (!empty($shareInfo['id']) && is_numeric($shareInfo['id'])) {
                return $shareInfo['id'];
            }
            if (!empty($shareInfo['shareId']) && is_numeric($shareInfo['shareId'])) {
                return $shareInfo['shareId'];
            }
            if ($isCartShare) {
                // Multi-item cart share with no resolvable single product.
                // Signal the caller instead of returning a random page ID.
                return '__CART_SHARE__';
            }
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

    $isShareLink = preg_match('/api-shein\.shein\.com|sharejump|shein\.com\/h5\/share|shein\.com\/share|shein\.top/i', $url);
    if ($isShareLink) {
        $productId = extractIdFromSharePage($url);
        if ($productId === '__CART_SHARE__') return '__CART_SHARE__';
        if ($productId) return $productId;

        // Fallback: api-shein.shein.com/h5/sharejump?link=XXX often 404s
        // server-side, but the same short code resolves via shein.top/XXX.
        // Extract the `link` query param and retry there.
        $qs = parse_url($url, PHP_URL_QUERY);
        if ($qs) {
            parse_str($qs, $p2);
            $shortCode = $p2['link'] ?? $p2['code'] ?? $p2['share_code'] ?? null;
            if ($shortCode && preg_match('/^[A-Za-z0-9_\-]{4,}$/', $shortCode)) {
                $alt = 'https://shein.top/' . $shortCode;
                $pid = extractIdFromSharePage($alt);
                if ($pid === '__CART_SHARE__') return '__CART_SHARE__';
                if ($pid) return $pid;
            }
        }
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

function fetchSheinProduct($productId) {
    $curl = curl_init();
    curl_setopt_array($curl, [
        CURLOPT_URL => "https://shein-api-v1.p.rapidapi.com/api/v1/product/productDetail5/" . $productId,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => "",
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => "GET",
        CURLOPT_HTTPHEADER => [
            "currency: usd",
            "lang: en",
            "x-rapidapi-host: shein-api-v1.p.rapidapi.com",
            "x-rapidapi-key: 2a7b7d7ff7msh0fc41abd991d525p18c937jsn22528fc5c264"
        ],
    ]);
    $response = curl_exec($curl);
    $err = curl_error($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    curl_close($curl);
    if ($err) return ['success' => false, 'error' => 'cURL Error: ' . $err];
    if (empty($response)) return ['success' => false, 'error' => 'Empty response', 'http_code' => $httpCode];
    $data = json_decode($response, true);
    if (json_last_error() !== JSON_ERROR_NONE) return ['success' => false, 'error' => 'Invalid JSON', 'http_code' => $httpCode];
    if ($httpCode !== 200) return ['success' => false, 'error' => 'HTTP ' . $httpCode, 'response' => $data];

    // Locate the detail object — try every known response structure.
    // The RapidAPI response now returns data as an indexed list:
    //   { success: true, data: [ { detail: {...}, attrSize: [...], ... } ] }
    // Previously it sometimes returned data/info as a direct object.
    $detail = null;

    // If data/info is an indexed list, unwrap the first element first.
    $unwrap = function($node) {
        if (is_array($node) && !empty($node)
            && array_keys($node) === range(0, count($node) - 1)) {
            return $node[0];
        }
        return $node;
    };
    $root    = $data;
    $dataNode = isset($data['data']) ? $unwrap($data['data']) : null;
    $infoNode = isset($data['info']) ? $unwrap($data['info']) : null;

    if (is_array($infoNode) && isset($infoNode['detail']) && is_array($infoNode['detail'])) {
        $detail = $infoNode['detail'];
    } elseif (is_array($dataNode) && isset($dataNode['detail']) && is_array($dataNode['detail'])) {
        $detail = $dataNode['detail'];
    } elseif (isset($data['detail']) && is_array($data['detail'])) {
        $detail = $data['detail'];
    } elseif (is_array($infoNode) && !empty($infoNode)) {
        $detail = $infoNode;
    } elseif (is_array($dataNode) && !empty($dataNode)) {
        $detail = $dataNode;
    } else {
        // Last resort: use root of response
        $detail = $data;
    }

    // Read fields directly from $detail only (no recursive search to avoid
    // picking up data from recommendation/related-product arrays)
    $name    = $detail['goods_name'] ?? $detail['goodsName'] ?? $detail['name']  ?? $detail['title'] ?? '';
    $goodsSn = $detail['goods_sn']   ?? $detail['goodsSn']   ?? $detail['sn']    ?? $detail['sku']   ?? '';
    $goodsId = $detail['goods_id']   ?? $detail['goodsId']   ?? $productId;
    $image   = $detail['goods_img']  ?? $detail['main_image'] ?? $detail['goodsImg'] ?? $detail['img'] ?? '';

    // Normalize protocol-relative URLs (//img.ltwebstatic.com/...) to https
    if (is_string($image) && strpos($image, '//') === 0) {
        $image = 'https:' . $image;
    }
    // Strip query params that can break CDN access
    if (is_string($image) && strpos($image, '?') !== false) {
        $image = strtok($image, '?');
    }

    // Price — only one level deep
    $price = '';
    foreach (['retailPrice', 'salePrice', 'price'] as $priceKey) {
        if (!isset($detail[$priceKey])) continue;
        $pNode = $detail[$priceKey];
        if (is_array($pNode)) {
            $raw = $pNode['usdAmount'] ?? $pNode['amount'] ?? $pNode['amountWithSymbol'] ?? '';
        } else {
            $raw = (string)$pNode;
        }
        $raw = preg_replace('/[^\d.]/', '', $raw);
        if ($raw !== '') { $price = $raw; break; }
    }

    $product = [
        'goods_id' => $goodsId,
        'goods_sn' => $goodsSn ?? '',
        'name'     => $name    ?? '',
        'image'    => $image   ?? '',
        'price'    => $price,
    ];

    return [
        'success'    => true,
        'product_id' => $productId,
        'product'    => $product,
        '_debug' => [
            'queried_product_id' => $productId,
            'top_keys'           => array_keys($data),
            'detail_keys'        => is_array($detail) ? array_keys($detail) : null,
        ],
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

if ($productId === '__CART_SHARE__') {
    // The link points to a multi-item cart share, not a single product.
    // Refuse to guess a product ID here — the Flutter app uses
    // `is_cart_share` to show a cart-specific hint instead.
    ob_end_clean();
    http_response_code(400);
    echo json_encode([
        'success'       => false,
        'is_cart_share' => true,
        'error'         => 'This link is a SHEIN cart share with multiple items. Please add items manually or paste individual product URLs.',
        'url'           => $sheinUrl,
    ]);
    exit();
}

if (!$productId) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Could not extract product ID from URL', 'url' => $sheinUrl]);
    exit();
}

$result = fetchSheinProduct($productId);
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
