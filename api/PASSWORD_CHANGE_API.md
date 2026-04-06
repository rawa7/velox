# Password Change API Documentation

## Overview
This API endpoint allows users to change their password by providing their current password and a new password.

## Endpoint
```
POST /api/change_password.php
```

## Authentication
No authentication token required. Users identify themselves using their phone number or customer ID.

## Request Parameters

### Form Data (POST)
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `phone` | string | Optional* | User's phone number |
| `customer_id` | integer | Optional* | User's customer ID |
| `current_password` | string | **Required** | Current password |
| `new_password` | string | **Required** | New password (minimum 4 characters) |

\* **Note:** Either `phone` OR `customer_id` must be provided (at least one is required)

## Validation Rules
1. Either phone or customer_id must be provided
2. Current password must be correct
3. New password must be at least 4 characters long
4. Account must be active (not disabled)

## Response Format

### Success Response
```json
{
    "success": true,
    "message": "Password changed successfully",
    "customer_id": 123,
    "phone": "07501234567"
}
```

### Error Responses

#### Missing Required Fields
```json
{
    "success": false,
    "error": "Current password and new password are required"
}
```

#### No Identifier Provided
```json
{
    "success": false,
    "error": "Phone number or customer ID is required"
}
```

#### Password Too Short
```json
{
    "success": false,
    "error": "New password must be at least 4 characters long"
}
```

#### User Not Found
```json
{
    "success": false,
    "error": "User not found"
}
```

#### Incorrect Current Password
```json
{
    "success": false,
    "error": "Current password is incorrect"
}
```

#### Account Disabled
```json
{
    "success": false,
    "error": "Account is disabled. Please contact administrator"
}
```

## Usage Examples

### Using cURL with Phone Number
```bash
curl -X POST https://veloxshoppingiq.com/api/change_password.php \
  -d "phone=07501234567" \
  -d "current_password=oldpass123" \
  -d "new_password=newpass456"
```

### Using cURL with Customer ID
```bash
curl -X POST https://veloxshoppingiq.com/api/change_password.php \
  -d "customer_id=123" \
  -d "current_password=oldpass123" \
  -d "new_password=newpass456"
```

### JavaScript/Fetch Example
```javascript
const formData = new FormData();
formData.append('phone', '07501234567');
formData.append('current_password', 'oldpass123');
formData.append('new_password', 'newpass456');

fetch('https://veloxshoppingiq.com/api/change_password.php', {
    method: 'POST',
    body: formData
})
.then(response => response.json())
.then(data => {
    if (data.success) {
        console.log('Password changed successfully!');
    } else {
        console.error('Error:', data.error);
    }
})
.catch(error => console.error('Request failed:', error));
```

### Flutter/Dart Example
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> changePassword({
  String? phone,
  int? customerId,
  required String currentPassword,
  required String newPassword,
}) async {
  final response = await http.post(
    Uri.parse('https://veloxshoppingiq.com/api/change_password.php'),
    body: {
      if (phone != null) 'phone': phone,
      if (customerId != null) 'customer_id': customerId.toString(),
      'current_password': currentPassword,
      'new_password': newPassword,
    },
  );

  final data = json.decode(response.body);
  
  if (data['success'] == true) {
    print('Password changed successfully!');
    print('Customer ID: ${data['customer_id']}');
  } else {
    print('Error: ${data['error']}');
  }
}

// Usage with phone
await changePassword(
  phone: '07501234567',
  currentPassword: 'oldpass123',
  newPassword: 'newpass456',
);

// Usage with customer ID
await changePassword(
  customerId: 123,
  currentPassword: 'oldpass123',
  newPassword: 'newpass456',
);
```

## Testing
A test page is available at:
```
https://veloxshoppingiq.com/api/test_change_password.html
```

This page provides an interactive form to test the API endpoint with real-time response display.

## Security Notes
1. Always use HTTPS in production
2. Passwords are currently stored in plain text (consider implementing password hashing in the future)
3. Consider implementing rate limiting to prevent brute force attacks
4. Consider adding password strength requirements (uppercase, numbers, special characters)

## HTTP Status Codes
- **200 OK**: Request processed successfully (check `success` field in JSON)
- The API returns 200 for both success and error cases; check the `success` field in the response

## CORS Headers
The API includes CORS headers allowing cross-origin requests from any domain:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: POST
Access-Control-Allow-Headers: Content-Type
```

