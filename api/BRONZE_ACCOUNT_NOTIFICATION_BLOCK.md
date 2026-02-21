# Bronze Account Notification Block - Implementation Summary

## Overview
Bronze accounts (usertype = 5) are now **completely excluded** from receiving any notifications, both in the SQL database and via Firebase Cloud Messaging (FCM).

## What Was Changed

### 1. **API Notification Center** (`api/notification_center.php`)
   - ✅ Modified `sendCompleteNotification()` function to check usertype before sending
   - ✅ Added bronze account check that returns early with skip status
   - ✅ Updated `notifyOrdersByStatus()` query to exclude bronze accounts: `AND (b.usertype IS NULL OR b.usertype != 5)`
   - ✅ Updated `notifyPendingPayments()` query to exclude bronze accounts
   - ✅ Updated `sendAnnouncementToAll()` query to exclude bronze accounts

### 2. **Notification Helper** (`api/notification_helper.php`)
   - ✅ Modified `sendNotification()` function to check usertype before saving to database
   - ✅ Returns `false` for bronze accounts (notification not saved)
   - ✅ Updated `sendSystemNotificationToAll()` query to exclude bronze accounts

### 3. **FCM Helper** (`api/fcm_helper.php`)
   - ✅ Modified `sendFirebaseNotificationToCustomer()` function to check usertype
   - ✅ Returns early with error message for bronze accounts
   - ✅ FCM push notifications will NOT be sent to bronze accounts

### 4. **Send Notification API** (`api/send_notification.php`)
   - ✅ Added bronze account check when customer_id is provided
   - ✅ Returns HTTP 403 error for bronze accounts
   - ✅ Prevents manual notification sending to bronze accounts

## How It Works

### Database Notifications (SQL)
When any code calls `sendNotification()`:
1. Function checks customer's usertype from `buyer` table
2. If usertype = 5 (bronze), function returns `false` immediately
3. Notification is **NOT saved** to `notifications` table
4. No database record is created

### Firebase Push Notifications (FCM)
When any code calls `sendFirebaseNotificationToCustomer()`:
1. Function checks customer's usertype from `buyer` table
2. If usertype = 5 (bronze), function returns early with skip message
3. FCM API is **NOT called**
4. No push notification is sent to customer's device(s)

### Notification Campaigns
All notification campaigns now exclude bronze accounts in their SQL queries:

**Before:**
```sql
SELECT ... FROM buyer WHERE is_active = 1
```

**After:**
```sql
SELECT ... FROM buyer WHERE is_active = 1 AND (usertype IS NULL OR usertype != 5)
```

## Affected Features

### ✅ Blocked for Bronze Accounts:
1. **Order Status Notifications** - No notifications when order status changes
2. **Payment Reminders** - No payment reminder notifications
3. **System Announcements** - No broadcast announcements
4. **Custom Notifications** - Manual notifications from admin panel
5. **Delivery Updates** - No delivery status notifications
6. **All Other Notifications** - Complete block on all notification types

### What Still Works:
- Bronze accounts can still:
  - Login to the app
  - Place orders
  - View their orders
  - Make payments
  - Access all app features
- They just won't receive any notifications (database or push)

## Testing

To verify bronze accounts are blocked:

### Test 1: Check Database
```sql
-- Create a test notification (will be blocked)
SELECT sendNotification(
    (SELECT id FROM buyer WHERE usertype = 5 LIMIT 1),
    'Test',
    'This should not save',
    'test'
);

-- Verify no notification was created
SELECT COUNT(*) FROM notifications 
WHERE customer_id = (SELECT id FROM buyer WHERE usertype = 5 LIMIT 1)
AND created_at > NOW() - INTERVAL 1 MINUTE;
-- Should return 0
```

### Test 2: Check API Response
```bash
# Try to send notification to bronze account
curl -X POST https://ruyadream.com/velox/api/notification_center.php \
  -H "Content-Type: application/json" \
  -d '{
    "action": "custom_notification",
    "customer_id": <bronze_customer_id>,
    "title": "Test",
    "message": "This should be skipped"
  }'

# Response should show: "skipped": true, "skip_reason": "Bronze account..."
```

### Test 3: Check Notification Campaigns
```bash
# Send announcement to all (should skip bronze accounts)
curl -X POST https://ruyadream.com/velox/api/notification_center.php \
  -H "Content-Type: application/json" \
  -d '{
    "action": "send_announcement",
    "title": "Test Announcement",
    "message": "Bronze accounts should not receive this"
  }'

# Check that bronze accounts didn't receive it
# Count should be 0 for bronze accounts
```

## Bronze Account Identification

**Bronze Account Usertype ID:** 5

**Check if a customer is bronze:**
```sql
SELECT id, name, usertype 
FROM buyer 
WHERE usertype = 5;
```

**Check all usertype values:**
```sql
SELECT ut.id, ut.name, COUNT(b.id) as customer_count
FROM usertype ut
LEFT JOIN buyer b ON b.usertype = ut.id
GROUP BY ut.id, ut.name;
```

## Response Format Changes

When a notification is skipped for bronze accounts, the response includes:

```json
{
    "customer_id": 123,
    "database": false,
    "fcm": false,
    "skipped": true,
    "skip_reason": "Bronze account - notifications disabled"
}
```

## Files Modified

1. `/api/notification_center.php` - Main notification center
2. `/api/notification_helper.php` - Core notification functions
3. `/api/fcm_helper.php` - Firebase messaging helper
4. `/api/send_notification.php` - Direct notification API

## Backward Compatibility

✅ **Fully backward compatible**
- All existing code continues to work
- Bronze accounts are silently skipped
- No errors are thrown
- Other account types work normally

## Implementation Date
December 23, 2025

## Notes
- Bronze account type is defined in signup.php as default usertype = 5
- All notification blocking is done at the function level
- No changes needed to calling code
- Works automatically for all existing and future notification calls
- Both database AND Firebase notifications are blocked
- Queries are optimized to exclude bronze accounts at database level

