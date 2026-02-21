<?php
// Lightweight Firebase Cloud Messaging helper using HTTP v1 API and Service Account JSON

// IMPORTANT: Do NOT echo sensitive details. Return only safe messages.

// Path to your service account JSON. Keep it outside web root if possible.
define('FCM_SERVICE_ACCOUNT_JSON_PATH', __DIR__ . '/velox-99b00-4888e7cb5a54.json');

/**
 * Ensure the fcm_tokens table exists.
 */
function ensureFcmTableExists(mysqli $conn): void {
    $createSql = "CREATE TABLE IF NOT EXISTS `fcm_tokens` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `customer_id` INT NULL,
        `token` VARCHAR(255) NOT NULL,
        `platform` VARCHAR(32) NULL,
        `device_id` VARCHAR(128) NULL,
        `is_active` TINYINT(1) NOT NULL DEFAULT 1,
        `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
        `last_seen` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uniq_token` (`token`),
        KEY `idx_customer_id` (`customer_id`),
        KEY `idx_device_id` (`device_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";
    mysqli_query($conn, $createSql);
}

/**
 * Base64 URL-safe encoding without padding.
 */
function base64UrlEncode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

/**
 * Get an OAuth2 access token for the Firebase Messaging scope using the service account JSON.
 * Caches the token in /tmp to reduce token requests.
 */
function getFirebaseAccessToken(): ?string {
    static $cachedToken = null;
    static $cachedExpiry = 0;

    $now = time();
    if ($cachedToken && $cachedExpiry - 60 > $now) {
        return $cachedToken;
    }

    $cacheFile = sys_get_temp_dir() . '/fcm_access_token.cache.json';
    if (!$cachedToken && file_exists($cacheFile)) {
        $cached = json_decode(file_get_contents($cacheFile), true);
        if (!empty($cached['access_token']) && !empty($cached['exp']) && ($cached['exp'] - 60) > $now) {
            $cachedToken = $cached['access_token'];
            $cachedExpiry = (int)$cached['exp'];
            return $cachedToken;
        }
    }

    $json = @file_get_contents(FCM_SERVICE_ACCOUNT_JSON_PATH);
    if ($json === false) {
        return null;
    }
    $sa = json_decode($json, true);
    if (!$sa || empty($sa['client_email']) || empty($sa['private_key']) || empty($sa['token_uri'])) {
        return null;
    }

    $header = ['alg' => 'RS256', 'typ' => 'JWT'];
    $claims = [
        'iss' => $sa['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => $sa['token_uri'],
        'iat' => $now,
        'exp' => $now + 3600,
    ];

    $jwtHeader = base64UrlEncode(json_encode($header));
    $jwtClaims = base64UrlEncode(json_encode($claims));
    $unsigned = $jwtHeader . '.' . $jwtClaims;

    $privateKey = openssl_pkey_get_private($sa['private_key']);
    if ($privateKey === false) {
        return null;
    }

    $signature = '';
    $ok = openssl_sign($unsigned, $signature, $privateKey, OPENSSL_ALGO_SHA256);
    openssl_pkey_free($privateKey);
    if (!$ok) {
        return null;
    }
    $signedJwt = $unsigned . '.' . base64UrlEncode($signature);

    // Exchange JWT for access token
    $postFields = http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $signedJwt,
    ]);

    $ch = curl_init($sa['token_uri']);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => $postFields,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/x-www-form-urlencoded',
        ],
        CURLOPT_TIMEOUT => 20,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200 || !$response) {
        return null;
    }
    $tokenResp = json_decode($response, true);
    if (empty($tokenResp['access_token'])) {
        return null;
    }

    $cachedToken = $tokenResp['access_token'];
    $cachedExpiry = $now + (int)($tokenResp['expires_in'] ?? 3600);

    // Persist token cache
    @file_put_contents($cacheFile, json_encode([
        'access_token' => $cachedToken,
        'exp' => $cachedExpiry,
    ]));

    return $cachedToken;
}

/**
 * Send a single FCM HTTP v1 message payload.
 */
function sendFcmHttpV1(array $message): array {
    $json = @file_get_contents(FCM_SERVICE_ACCOUNT_JSON_PATH);
    if ($json === false) {
        return ['success' => false, 'message' => 'Service account JSON not found'];
    }
    $sa = json_decode($json, true);
    if (!$sa || empty($sa['project_id'])) {
        return ['success' => false, 'message' => 'Invalid service account JSON'];
    }

    $accessToken = getFirebaseAccessToken();
    if (!$accessToken) {
        return ['success' => false, 'message' => 'Failed to obtain access token'];
    }

    $url = 'https://fcm.googleapis.com/v1/projects/' . rawurlencode($sa['project_id']) . '/messages:send';
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS => json_encode(['message' => $message]),
        CURLOPT_TIMEOUT => 20,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr = curl_error($ch);
    curl_close($ch);

    if ($response === false) {
        return ['success' => false, 'message' => 'cURL error: ' . $curlErr];
    }

    $respBody = json_decode($response, true);
    if ($httpCode >= 200 && $httpCode < 300) {
        return ['success' => true, 'response' => $respBody];
    }
    return ['success' => false, 'status' => $httpCode, 'response' => $respBody];
}

/**
 * Send notification to a specific device token.
 */
function sendFirebaseNotificationToToken(string $token, string $title, string $body, array $data = []): array {
    $message = [
        'token' => $token,
        'notification' => [
            'title' => $title,
            'body' => $body,
        ],
        'data' => array_map('strval', $data),
    ];
    return sendFcmHttpV1($message);
}

/**
 * Send notification to all active tokens of a customer.
 * Bronze accounts (usertype = 5) will NOT receive FCM notifications.
 */
function sendFirebaseNotificationToCustomer(mysqli $conn, int $customerId, string $title, string $body, array $data = []): array {
    ensureFcmTableExists($conn);
    
    // Check if customer has bronze account (usertype = 5)
    // Bronze accounts should NOT receive FCM notifications
    $usertype_check = mysqli_query($conn, "SELECT usertype FROM buyer WHERE id = " . intval($customerId));
    if ($usertype_check && $usertype_row = mysqli_fetch_assoc($usertype_check)) {
        if (intval($usertype_row['usertype']) === 5) {
            // Skip FCM notification for bronze accounts
            return ['success' => false, 'message' => 'Bronze account - FCM notifications disabled', 'skipped' => true];
        }
    }
    
    $tokens = [];
    $res = mysqli_query($conn, "SELECT token FROM fcm_tokens WHERE customer_id = " . intval($customerId) . " AND is_active = 1");
    while ($row = mysqli_fetch_assoc($res)) {
        if (!empty($row['token'])) {
            $tokens[] = $row['token'];
        }
    }
    if (empty($tokens)) {
        return ['success' => false, 'message' => 'No active tokens for customer'];
    }

    $results = [];
    foreach ($tokens as $t) {
        $results[$t] = sendFirebaseNotificationToToken($t, $title, $body, $data);
    }
    return ['success' => true, 'results' => $results];
}

?>


