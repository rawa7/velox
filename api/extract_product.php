<?php
/**
 * Universal Product Extractor
 *
 * Endpoint : /api/extract_product.php
 * Method   : GET ?url=... or POST {"url":"..."}
 *
 * Response :
 *   {
 *     "success": true,
 *     "name":    "Product title",
 *     "image":   "https://...",
 *     "images":  ["https://...", ...],
 *     "price":   12.50,           // best-effort numeric
 *     "currency":"USD",
 *     "sku":     "ABCD1234",
 *     "color":   "Black",
 *     "site":    "zara",
 *     "final_url":"https://...",
 *   }
 *
 * Works with most modern e-commerce sites by reading:
 *   1. Site-specific JSON blobs (Zara, Trendyol, Noon, etc.)
 *   2. JSON-LD (schema.org/Product) — used by nearly every major retailer
 *   3. OpenGraph / Twitter Card meta tags
 *   4. Generic HTML fallbacks (<title>, <h1>, img selectors)
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

/* ─────────────────────────── INPUT ─────────────────────────── */

$url = '';
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $url = isset($_GET['url']) ? trim($_GET['url']) : '';
} else {
    $raw = file_get_contents('php://input');
    $input = $raw ? json_decode($raw, true) : null;
    $url = (is_array($input) ? ($input['url'] ?? '') : '') ?: ($_POST['url'] ?? '');
    $url = trim($url);
}

if ($url === '') {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing url parameter']);
    exit();
}

// Normalize — accept pasted strings that don't start with a scheme
if (!preg_match('#^https?://#i', $url)) {
    if (strpos($url, '//') === 0) {
        $url = 'https:' . $url;
    } elseif (preg_match('/-p-\d+/', $url) && strpos($url, ' ') === false && strpos($url, '/') === false) {
        // Trendyol slug pasted without domain
        $url = 'https://www.trendyol.com/' . ltrim($url, '/');
    } else {
        $url = 'https://' . ltrim($url, '/');
    }
}

/* ───────────────────────── HELPERS ────────────────────────── */

function http_get($url, $cookieJar = null, $extraHeaders = [], $replaceHeaders = false) {
    $ch = curl_init();
    $defaults = [
        'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language: en-US,en;q=0.9,ar;q=0.8',
        'Cache-Control: no-cache',
        'Pragma: no-cache',
        'Upgrade-Insecure-Requests: 1',
        'Sec-Fetch-Dest: document',
        'Sec-Fetch-Mode: navigate',
        'Sec-Fetch-Site: none',
        'Sec-Fetch-User: ?1',
    ];
    if ($replaceHeaders) {
        $headers = $extraHeaders;
    } else {
        // Merge but ensure extraHeaders override defaults with the same name.
        $byName = [];
        foreach (array_merge($defaults, $extraHeaders) as $h) {
            $name = strtolower(trim(strtok($h, ':')));
            $byName[$name] = $h;
        }
        $headers = array_values($byName);
    }

    curl_setopt_array($ch, [
        CURLOPT_URL             => $url,
        CURLOPT_RETURNTRANSFER  => true,
        CURLOPT_FOLLOWLOCATION  => true,
        CURLOPT_MAXREDIRS       => 10,
        CURLOPT_TIMEOUT         => 25,
        CURLOPT_CONNECTTIMEOUT  => 15,
        CURLOPT_SSL_VERIFYPEER  => false,
        CURLOPT_SSL_VERIFYHOST  => false,
        CURLOPT_ENCODING        => '',   // accept gzip/deflate/br
        CURLOPT_HTTP_VERSION    => CURL_HTTP_VERSION_1_1,
        CURLOPT_USERAGENT       => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15',
        CURLOPT_HTTPHEADER      => $headers,
    ]);
    if ($cookieJar) {
        curl_setopt($ch, CURLOPT_COOKIEJAR,  $cookieJar);
        curl_setopt($ch, CURLOPT_COOKIEFILE, $cookieJar);
    }

    $body      = curl_exec($ch);
    $finalUrl  = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
    $httpCode  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err       = curl_error($ch);
    curl_close($ch);

    return [
        'body'      => $body,
        'final_url' => $finalUrl,
        'http_code' => $httpCode,
        'error'     => $err,
    ];
}

function detect_site($url) {
    $h = strtolower(parse_url($url, PHP_URL_HOST) ?? '');
    if (strpos($h, 'shein')     !== false) return 'shein';
    if (strpos($h, 'zara.')     !== false) return 'zara';
    if (strpos($h, 'trendyol')  !== false) return 'trendyol';
    if (strpos($h, 'noon.')     !== false) return 'noon';
    if (strpos($h, 'mango.')    !== false) return 'mango';
    if (strpos($h, '.hm.com')   !== false || strpos($h, 'www2.hm.com') !== false || strpos($h, 'hm.com') !== false) return 'hm';
    if (strpos($h, 'amazon.')   !== false) return 'amazon';
    if (strpos($h, 'aliexpress')!== false) return 'aliexpress';
    if (strpos($h, 'asos.')     !== false) return 'asos';
    if (strpos($h, 'namshi.')   !== false) return 'namshi';
    if (strpos($h, 'farfetch.') !== false) return 'farfetch';
    if (strpos($h, 'nike.')     !== false) return 'nike';
    if (strpos($h, 'adidas.')   !== false) return 'adidas';
    if (strpos($h, 'pullandbear')!== false)return 'pullandbear';
    if (strpos($h, 'bershka')   !== false) return 'bershka';
    if (strpos($h, 'stradivarius')!== false)return 'stradivarius';
    if (strpos($h, 'massimodutti')!== false)return 'massimodutti';
    if (strpos($h, 'ebay.')     !== false) return 'ebay';
    return 'generic';
}

function make_absolute($url, $base) {
    if (!is_string($url) || $url === '') return $url;
    if (preg_match('#^https?://#i', $url)) return $url;
    if (strpos($url, '//') === 0) return 'https:' . $url;
    $p = parse_url($base);
    if (!$p || empty($p['scheme']) || empty($p['host'])) return $url;
    if (strpos($url, '/') === 0) return $p['scheme'] . '://' . $p['host'] . $url;
    $path = isset($p['path']) ? rtrim(dirname($p['path']), '/') : '';
    return $p['scheme'] . '://' . $p['host'] . $path . '/' . $url;
}

function clean_text($s) {
    if (!is_string($s)) return $s;
    $s = html_entity_decode($s, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $s = preg_replace('/\s+/u', ' ', $s);
    return trim($s);
}

function to_number($v) {
    if (is_numeric($v)) return (float)$v;
    if (!is_string($v) || $v === '') return null;
    // Keep only digits, commas, dots, minus
    $s = preg_replace('/[^\d.,\-]/', '', $v);
    if ($s === '' || $s === '-' || $s === '.') return null;
    // Handle "1.299,99" (eu) vs "1,299.99" (us) vs "129900"
    $hasComma = strpos($s, ',') !== false;
    $hasDot   = strpos($s, '.') !== false;
    if ($hasComma && $hasDot) {
        // Whichever comes last is decimal separator
        if (strrpos($s, ',') > strrpos($s, '.')) {
            $s = str_replace('.', '', $s);
            $s = str_replace(',', '.', $s);
        } else {
            $s = str_replace(',', '', $s);
        }
    } elseif ($hasComma) {
        // Only comma — if looks like decimal (1-2 digits after), treat as decimal
        if (preg_match('/,\d{1,2}$/', $s)) $s = str_replace(',', '.', $s);
        else $s = str_replace(',', '', $s);
    }
    return is_numeric($s) ? (float)$s : null;
}

function normalize_currency($s) {
    if (!is_string($s) || $s === '') return null;
    $map = [
        '$' => 'USD', 'US$' => 'USD', 'USD' => 'USD',
        '€' => 'EUR', 'EUR' => 'EUR',
        '£' => 'GBP', 'GBP' => 'GBP',
        '¥' => 'JPY', 'JPY' => 'JPY',
        '₺' => 'TRY', 'TL' => 'TRY', 'TRY' => 'TRY',
        'AED' => 'AED', 'د.إ' => 'AED',
        'SAR' => 'SAR', 'ر.س' => 'SAR',
        'IQD' => 'IQD', 'د.ع' => 'IQD',
        'EGP' => 'EGP',
        'KWD' => 'KWD',
    ];
    $t = strtoupper(trim($s));
    if (isset($map[$s])) return $map[$s];
    if (isset($map[$t])) return $map[$t];
    return $t;
}

/** Get first meta content by property/name. */
function meta_content($doc, $keys) {
    if (!$doc) return null;
    $xp = new DOMXPath($doc);
    foreach ((array)$keys as $k) {
        $k = addslashes($k);
        foreach (["//meta[@property='$k']", "//meta[@name='$k']", "//meta[@itemprop='$k']"] as $q) {
            $nodes = @$xp->query($q);
            if ($nodes && $nodes->length > 0) {
                $c = $nodes->item(0)->getAttribute('content');
                if ($c !== '') return clean_text($c);
            }
        }
    }
    return null;
}

/** Parse all <script type="application/ld+json"> and return array of decoded arrays. */
function parse_ld_json($html) {
    $out = [];
    if (!preg_match_all('#<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>#is', $html, $m)) {
        return $out;
    }
    foreach ($m[1] as $raw) {
        $raw = trim($raw);
        if ($raw === '') continue;
        // Remove HTML comments sometimes wrapped around JSON
        $raw = preg_replace('/^<!\-\-|\-\->$/', '', $raw);
        $decoded = json_decode($raw, true);
        if ($decoded === null) {
            // Some sites have multiple concatenated JSON objects
            $raw2 = preg_replace('/,\s*([\]}])/', '$1', $raw);
            $decoded = json_decode($raw2, true);
        }
        if ($decoded !== null) $out[] = $decoded;
    }
    return $out;
}

/** Walk LD+JSON tree looking for a Product node. */
function find_ld_product($tree) {
    if (!is_array($tree)) return null;
    // Direct hit
    $type = $tree['@type'] ?? null;
    if (is_string($type) && strtolower($type) === 'product') return $tree;
    if (is_array($type)) {
        foreach ($type as $t) if (is_string($t) && strtolower($t) === 'product') return $tree;
    }
    // @graph
    if (isset($tree['@graph']) && is_array($tree['@graph'])) {
        foreach ($tree['@graph'] as $node) {
            $p = find_ld_product($node);
            if ($p) return $p;
        }
    }
    // Numeric array
    if (array_keys($tree) === range(0, count($tree) - 1)) {
        foreach ($tree as $node) {
            $p = find_ld_product($node);
            if ($p) return $p;
        }
    }
    // Nested children worth searching
    foreach (['mainEntity','itemListElement','subjectOf'] as $k) {
        if (isset($tree[$k])) {
            $p = find_ld_product($tree[$k]);
            if ($p) return $p;
        }
    }
    return null;
}

function extract_ld_price($offers) {
    if (!is_array($offers)) return [null, null];
    // offers can be an Offer, AggregateOffer, or an array of either
    $candidates = [];
    if (isset($offers['@type'])) {
        $candidates[] = $offers;
    } else {
        foreach ($offers as $o) {
            if (is_array($o)) $candidates[] = $o;
        }
    }
    foreach ($candidates as $o) {
        $t = strtolower($o['@type'] ?? '');
        $price    = $o['price']        ?? $o['lowPrice'] ?? $o['highPrice'] ?? null;
        $currency = $o['priceCurrency'] ?? null;
        if ($price === null && isset($o['priceSpecification'])) {
            $ps = $o['priceSpecification'];
            if (is_array($ps)) {
                $price    = $ps['price']         ?? $price;
                $currency = $ps['priceCurrency'] ?? $currency;
            }
        }
        if ($price !== null) return [to_number($price), normalize_currency($currency)];
    }
    return [null, null];
}

/**
 * Fetch a Zara product via the public JSON API ({url}?ajax=true).
 * Returns a normalized result array on success, or null to fall through to
 * generic extraction.
 */
function extract_zara_via_api($productUrl) {
    // Append ?ajax=true (preserve existing query string)
    $parts = parse_url($productUrl);
    if (!$parts || empty($parts['host']) || empty($parts['path'])) return null;

    // Only product pages have -pNNNN.html in the path
    if (!preg_match('/-p\d{5,}\.html$/i', $parts['path'])) return null;

    parse_str($parts['query'] ?? '', $q);
    $q['ajax'] = 'true';
    $parts['query'] = http_build_query($q);
    $ajaxUrl = $parts['scheme'] . '://' . $parts['host'] . $parts['path']
             . '?' . $parts['query'];

    $resp = http_get($ajaxUrl, null, [
        'Accept: application/json, text/plain, */*',
        'Accept-Language: en-US,en;q=0.9',
        'Referer: https://www.zara.com/',
        'X-Requested-With: XMLHttpRequest',
    ], true);
    if ($resp['error'] || empty($resp['body']) || $resp['http_code'] !== 200) {
        return null;
    }

    $data = json_decode($resp['body'], true);
    if (!is_array($data) || !isset($data['product'])) return null;
    $product = $data['product'];

    // Pick the requested color if v1 query param is present, else first color
    parse_str($parts['query'] ?? '', $q2);
    $wantedColorProductId = isset($q2['v1']) && is_numeric($q2['v1']) ? (int)$q2['v1'] : null;

    $colors = $product['detail']['colors'] ?? [];
    if (!is_array($colors) || empty($colors)) return null;

    $chosen = $colors[0];
    if ($wantedColorProductId) {
        foreach ($colors as $c) {
            if (isset($c['productId']) && (int)$c['productId'] === $wantedColorProductId) {
                $chosen = $c; break;
            }
        }
    }

    // Images: prefer extraInfo.deliveryUrl (no {width} template)
    $images = [];
    foreach (($chosen['xmedia'] ?? []) as $m) {
        $img = $m['extraInfo']['deliveryUrl'] ?? null;
        if (!$img && !empty($m['url'])) {
            $img = preg_replace('/\{width\}/i', '1024', $m['url']);
        }
        if ($img && !in_array($img, $images, true)) $images[] = $img;
    }

    // Price: stored in minor units (e.g. 16900000 -> 169000.00)
    $rawPrice = $chosen['price'] ?? ($chosen['sizes'][0]['price'] ?? null);
    $price = null;
    if ($rawPrice !== null && is_numeric($rawPrice)) {
        $price = ((float)$rawPrice) / 100.0;
    }

    $name  = $product['name'] ?? ($data['productMetaData'][0]['name'] ?? null);
    $ref   = $product['detail']['reference'] ?? $chosen['reference'] ?? null;
    $color = $chosen['name'] ?? null;

    if (empty($images) && empty($name)) return null;

    return [
        'success'   => true,
        'message'   => 'ok',
        'site'      => 'zara',
        'final_url' => $productUrl,
        'name'      => is_string($name) ? clean_text($name) : null,
        'image'     => $images[0] ?? null,
        'images'    => $images,
        'price'     => $price,
        'currency'  => null,
        'sku'       => is_string($ref) ? $ref : (string)$ref,
        'color'     => is_string($color) ? clean_text($color) : null,
        'size'      => null,
    ];
}

function extract_ld_images($img) {
    $out = [];
    if (is_string($img) && $img !== '') {
        $out[] = $img;
    } elseif (is_array($img)) {
        foreach ($img as $i) {
            if (is_string($i) && $i !== '') $out[] = $i;
            elseif (is_array($i) && !empty($i['url'])) $out[] = $i['url'];
        }
    }
    return $out;
}

/* ───────────────────────── EXTRACTION ────────────────────────── */

$site = detect_site($url);

// ───────── Zara fast path: use the official public JSON API ─────────
// Zara serves a full JSON payload at {product_url}?ajax=true that contains
// name, reference, colors, images and price without any HTML scraping.
if ($site === 'zara') {
    $zara = extract_zara_via_api($url);
    if ($zara !== null) {
        ob_end_clean();
        echo json_encode($zara, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit();
    }
}

// Zara requires a proper Accept-Language for the chosen locale, others too.
$extraHeaders = [];
if ($site === 'zara') {
    $extraHeaders[] = 'Referer: https://www.zara.com/';
}
if ($site === 'noon') {
    $extraHeaders[] = 'Referer: https://www.noon.com/';
}
if ($site === 'hm') {
    $extraHeaders[] = 'Referer: https://www2.hm.com/';
}

$cookieJar = tempnam(sys_get_temp_dir(), 'cookie_');
$resp = http_get($url, $cookieJar, $extraHeaders);

// If the first fetch looks like a bot-challenge page (tiny body, no useful
// markers), retry with a Googlebot user agent — many retailers whitelist it
// to keep their pages indexable.
$needsRetry = !$resp['error'] && !empty($resp['body'])
    && (strlen($resp['body']) < 6000
        || (stripos($resp['body'], 'ld+json') === false
            && stripos($resp['body'], 'og:image') === false
            && stripos($resp['body'], 'og:title') === false));
if ($needsRetry) {
    $gbotHeaders = array_merge($extraHeaders, [
        'From: googlebot(at)googlebot.com',
    ]);
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL             => $url,
        CURLOPT_RETURNTRANSFER  => true,
        CURLOPT_FOLLOWLOCATION  => true,
        CURLOPT_MAXREDIRS       => 10,
        CURLOPT_TIMEOUT         => 25,
        CURLOPT_CONNECTTIMEOUT  => 15,
        CURLOPT_SSL_VERIFYPEER  => false,
        CURLOPT_SSL_VERIFYHOST  => false,
        CURLOPT_ENCODING        => '',
        CURLOPT_COOKIEJAR       => $cookieJar,
        CURLOPT_COOKIEFILE      => $cookieJar,
        CURLOPT_USERAGENT       => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        CURLOPT_HTTPHEADER      => array_merge([
            'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language: en-US,en;q=0.9',
        ], $gbotHeaders),
    ]);
    $body2     = curl_exec($ch);
    $code2     = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $final2    = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
    curl_close($ch);
    if ($code2 >= 200 && $code2 < 400 && !empty($body2) && strlen($body2) > strlen($resp['body'])) {
        $resp['body']      = $body2;
        $resp['http_code'] = $code2;
        $resp['final_url'] = $final2;
    }
}

if ($cookieJar && file_exists($cookieJar)) @unlink($cookieJar);

if ($resp['error']) {
    ob_end_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Network error: ' . $resp['error'],
        'site'    => $site,
    ]);
    exit();
}

if ($resp['http_code'] < 200 || $resp['http_code'] >= 400 || empty($resp['body'])) {
    ob_end_clean();
    echo json_encode([
        'success'   => false,
        'message'   => 'Failed to load page (HTTP ' . $resp['http_code'] . ')',
        'site'      => $site,
        'final_url' => $resp['final_url'] ?? $url,
    ]);
    exit();
}

$html     = $resp['body'];
$finalUrl = $resp['final_url'] ?: $url;

// DOM
$doc = new DOMDocument();
libxml_use_internal_errors(true);
@$doc->loadHTML('<?xml encoding="UTF-8">' . $html);
libxml_clear_errors();

$data = [
    'name'     => null,
    'image'    => null,
    'images'   => [],
    'price'    => null,
    'currency' => null,
    'sku'      => null,
    'color'    => null,
    'size'     => null,
];

/* 1) JSON-LD — the most reliable source */
$ldBlocks = parse_ld_json($html);
$ldProduct = null;
foreach ($ldBlocks as $block) {
    $p = find_ld_product($block);
    if ($p) { $ldProduct = $p; break; }
}

if ($ldProduct) {
    $data['name']  = $data['name']  ?? clean_text($ldProduct['name']  ?? null);
    $data['sku']   = $data['sku']   ?? clean_text($ldProduct['sku']   ?? $ldProduct['mpn'] ?? $ldProduct['productID'] ?? null);
    $data['color'] = $data['color'] ?? clean_text($ldProduct['color'] ?? null);

    if (!empty($ldProduct['image'])) {
        foreach (extract_ld_images($ldProduct['image']) as $img) {
            $abs = make_absolute($img, $finalUrl);
            if (!in_array($abs, $data['images'], true)) $data['images'][] = $abs;
        }
    }
    if (!empty($ldProduct['offers'])) {
        [$p, $c] = extract_ld_price($ldProduct['offers']);
        if ($p !== null) $data['price']    = $data['price']    ?? $p;
        if ($c !== null) $data['currency'] = $data['currency'] ?? $c;
    }
}

/* 2) OpenGraph / Twitter / itemprop meta */
$data['name']  = $data['name']  ?? meta_content($doc, ['og:title', 'twitter:title']);
if (!$data['price']) {
    $p = meta_content($doc, ['product:price:amount', 'og:price:amount', 'price']);
    if ($p !== null) $data['price'] = to_number($p);
}
if (!$data['currency']) {
    $c = meta_content($doc, ['product:price:currency', 'og:price:currency']);
    if ($c) $data['currency'] = normalize_currency($c);
}
if (empty($data['images'])) {
    $og = meta_content($doc, ['og:image', 'og:image:secure_url', 'twitter:image', 'twitter:image:src']);
    if ($og) $data['images'][] = make_absolute($og, $finalUrl);
}

/* 3) Site-specific extraction */
if ($site === 'zara') {
    // Zara embeds rich product data inside <script> blocks
    // Try: window.zara.viewPayload -> product data
    if (preg_match('#<script[^>]*>\s*window\[\'zara\-app\-root\'\].*?</script>#is', $html, $mm)) {
        // unused — but keep bailout
    }
    // Zara product page contains JSON with "mainImgs":[{"url":"..."}] etc.
    if (preg_match_all('#"url"\s*:\s*"(https?://static\.zara\.net/photos/[^"]+)"#i', $html, $m)) {
        foreach ($m[1] as $img) {
            $img = str_replace('\\/', '/', $img);
            // Zara URLs often have {width} template — swap with 1024
            $img = preg_replace('/\{width\}/i', '1024', $img);
            if (!in_array($img, $data['images'], true)) $data['images'][] = $img;
        }
    }
    // Price inside embedded JSON: "price":499000  (minor units, 3 decimals for some locales)
    if ($data['price'] === null && preg_match('#"price"\s*:\s*(\d{2,9})#', $html, $m)) {
        $raw = (int)$m[1];
        // Zara stores in minor units (hundreds). Try both and pick reasonable.
        $guess = $raw / 100;
        if ($guess > 0) $data['price'] = $guess;
    }
    if (!$data['sku'] && preg_match('#"reference"\s*:\s*"([A-Z0-9\/\-]+)"#i', $html, $m)) {
        $data['sku'] = $m[1];
    } elseif (!$data['sku'] && preg_match('/-p(\d{6,})\.html/i', $finalUrl, $m)) {
        $data['sku'] = $m[1];
    }
}

if ($site === 'noon') {
    // Noon has rich JSON in window.__NUXT__ / state
    if (preg_match('#"product_code"\s*:\s*"([^"]+)"#', $html, $m)) {
        if (!$data['sku']) $data['sku'] = $m[1];
    }
    if (preg_match_all('#"image_keys"\s*:\s*\[(.*?)\]#s', $html, $m)) {
        if (!empty($m[1][0]) && preg_match_all('#"([^"]+)"#', $m[1][0], $k)) {
            foreach ($k[1] as $key) {
                $img = 'https://f.nooncdn.com/p/' . $key . '.jpg';
                if (!in_array($img, $data['images'], true)) $data['images'][] = $img;
            }
        }
    }
    if ($data['price'] === null && preg_match('#"sale_price"\s*:\s*([0-9.]+)#', $html, $m)) {
        $data['price'] = to_number($m[1]);
    }
    if (!$data['currency']) $data['currency'] = 'AED';
}

if ($site === 'trendyol') {
    if (preg_match_all('#https://cdn\.dsmcdn\.com/[^"\s<>]+\.(?:jpg|jpeg|png|webp)#i', $html, $m)) {
        foreach ($m[0] as $img) {
            $img = strtok($img, '?');
            if (!in_array($img, $data['images'], true)) $data['images'][] = $img;
        }
    }
    if (!$data['sku'] && preg_match('/"contentId"\s*:\s*(\d+)/', $html, $m)) {
        $data['sku'] = $m[1];
    }
}

if ($site === 'hm') {
    if (preg_match_all('#https?://(?:lp2\.hm\.com|image\.hm\.com)/content/dam/[^"\'\s<>]+\.(?:jpg|jpeg|png|webp)#i', $html, $m)) {
        foreach ($m[0] as $img) {
            if (!in_array($img, $data['images'], true)) $data['images'][] = $img;
        }
    }
}

if ($site === 'amazon') {
    if (empty($data['images']) && preg_match('#"hiRes":"(https://[^"]+)"#', $html, $m)) {
        $data['images'][] = str_replace('\\/', '/', $m[1]);
    }
    if (!$data['name'] && preg_match('#<span[^>]*id=["\']productTitle["\'][^>]*>(.*?)</span>#is', $html, $m)) {
        $data['name'] = clean_text($m[1]);
    }
}

if ($site === 'aliexpress') {
    if (preg_match('#window\.runParams\s*=\s*(\{.*?\});#s', $html, $m)) {
        $obj = json_decode($m[1], true);
        if (is_array($obj)) {
            $imgs = $obj['data']['imageModule']['imagePathList'] ?? [];
            foreach ((array)$imgs as $i) {
                if (is_string($i) && $i !== '' && !in_array($i, $data['images'], true)) $data['images'][] = $i;
            }
        }
    }
}

/* 4) Generic HTML fallbacks */
if (!$data['name']) {
    $xp = new DOMXPath($doc);
    $h1 = @$xp->query('//h1')->item(0);
    if ($h1) $data['name'] = clean_text($h1->textContent);
    if (!$data['name']) {
        $t = @$xp->query('//title')->item(0);
        if ($t) $data['name'] = clean_text($t->textContent);
    }
}

if (empty($data['images'])) {
    // Try common product-image selectors
    $xp = new DOMXPath($doc);
    $candidates = [
        "//meta[@itemprop='image']/@content",
        "//img[@itemprop='image']/@src",
        "//picture//img/@src",
        "//img[contains(@class,'product') or contains(@class,'Product')]/@src",
        "//img[contains(@class,'product') or contains(@class,'Product')]/@data-src",
        "//img[contains(@src,'/product')]/@src",
    ];
    foreach ($candidates as $q) {
        $nodes = @$xp->query($q);
        if (!$nodes) continue;
        foreach ($nodes as $n) {
            $v = trim($n->nodeValue);
            if ($v === '') continue;
            if (stripos($v, 'placeholder') !== false) continue;
            if (stripos($v, 'data:image') === 0) continue;
            $abs = make_absolute($v, $finalUrl);
            if (!in_array($abs, $data['images'], true)) $data['images'][] = $abs;
            if (count($data['images']) >= 6) break 2;
        }
    }
}

/* 5) Post-process */
$data['name']   = $data['name']   ? clean_text($data['name'])   : null;
$data['sku']    = $data['sku']    ? clean_text($data['sku'])    : null;
$data['color']  = $data['color']  ? clean_text($data['color'])  : null;
$data['images'] = array_values(array_unique(array_filter(array_map(function($u) use ($finalUrl) {
    if (!is_string($u) || $u === '') return null;
    $u = str_replace('\\/', '/', $u);
    $u = make_absolute($u, $finalUrl);
    return $u;
}, $data['images']))));

// Primary image
if (!empty($data['images'])) $data['image'] = $data['images'][0];

// Price sanity — if we have no price yet, look for price-like nodes in DOM
if ($data['price'] === null) {
    $xp = new DOMXPath($doc);
    $priceQueries = [
        "//*[@itemprop='price']/@content",
        "//*[@itemprop='price']",
        "//*[@data-price]/@data-price",
        "//*[contains(@class,'price') and not(self::link)]",
    ];
    foreach ($priceQueries as $q) {
        $nodes = @$xp->query($q);
        if (!$nodes) continue;
        foreach ($nodes as $n) {
            $txt = trim($n->nodeValue);
            if ($txt === '') continue;
            $num = to_number($txt);
            if ($num !== null && $num > 0) {
                $data['price'] = $num;
                // Try to grab currency from same text
                if (!$data['currency'] && preg_match('/[A-Z]{3}|\$|€|£|¥|₺/u', $txt, $cm)) {
                    $data['currency'] = normalize_currency($cm[0]);
                }
                break 2;
            }
        }
    }
}

$success = !empty($data['images']) || !empty($data['name']);

ob_end_clean();
echo json_encode([
    'success'   => $success,
    'message'   => $success ? 'ok' : 'Could not extract product details from this page.',
    'site'      => $site,
    'final_url' => $finalUrl,
    'name'      => $data['name'],
    'image'     => $data['image'] ?? null,
    'images'    => $data['images'],
    'price'     => $data['price'],
    'currency'  => $data['currency'],
    'sku'       => $data['sku'],
    'color'     => $data['color'],
    'size'      => $data['size'],
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
