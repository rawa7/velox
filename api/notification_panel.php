<?php
// Simple admin panel to send notifications
require_once __DIR__ . '/../resources/config.php';

// Get available statuses
$statuses_query = "SELECT id, name FROM statue ORDER BY CASE WHEN id < 0 THEN 1 ELSE 0 END, id";
$statuses_result = mysqli_query($conn, $statuses_query);
$statuses = [];
while ($row = mysqli_fetch_assoc($statuses_result)) {
    $statuses[] = $row;
}

// Get customers who have FCM tokens (only those with the app installed)
$customers_query = "SELECT DISTINCT b.id, b.name, b.phone, COUNT(f.id) as token_count
                    FROM buyer b
                    INNER JOIN fcm_tokens f ON b.id = f.customer_id
                    WHERE b.is_active = 1 AND f.is_active = 1
                    GROUP BY b.id, b.name, b.phone
                    ORDER BY b.name";
$customers_result = mysqli_query($conn, $customers_query);
$customers = [];
while ($row = mysqli_fetch_assoc($customers_result)) {
    $customers[] = $row;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Notification Center - Velox Shopping</title>
    <!-- Select2 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: #333; margin-bottom: 10px; }
        .subtitle { color: #666; margin-bottom: 30px; }
        .card {
            background: white;
            border-radius: 8px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .card h2 {
            color: #333;
            margin-bottom: 15px;
            font-size: 18px;
            display: flex;
            align-items: center;
        }
        .card h2::before {
            content: '📢';
            margin-right: 10px;
            font-size: 24px;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            color: #555;
            font-weight: 500;
        }
        input, select, textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        textarea {
            min-height: 80px;
            resize: vertical;
        }
        button {
            background: #007bff;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: background 0.2s;
        }
        button:hover {
            background: #0056b3;
        }
        button:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        .result {
            margin-top: 15px;
            padding: 15px;
            border-radius: 4px;
            display: none;
        }
        .result.success {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
        }
        .result.error {
            background: #f8d7da;
            border: 1px solid #f5c6cb;
            color: #721c24;
        }
        .result pre {
            margin-top: 10px;
            background: rgba(0,0,0,0.1);
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
            font-size: 12px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            background: #007bff;
            color: white;
            border-radius: 12px;
            font-size: 12px;
            margin-left: 10px;
        }
        /* Select2 customization */
        .select2-container {
            width: 100% !important;
        }
        .select2-container--default .select2-selection--single {
            height: 40px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .select2-container--default .select2-selection--single .select2-selection__rendered {
            line-height: 38px;
            padding-left: 10px;
        }
        .select2-container--default .select2-selection--single .select2-selection__arrow {
            height: 38px;
        }
        .select2-dropdown {
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .select2-container--default .select2-results__option--highlighted[aria-selected] {
            background-color: #007bff;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔔 Notification Center</h1>
        <p class="subtitle">Send database notifications + FCM push notifications to customers</p>
        
        <div class="grid">
            <!-- Notify by Status -->
            <div class="card">
                <h2>Notify by Order Status</h2>
                <form id="statusForm">
                    <div class="form-group">
                        <label>Select Status:</label>
                        <select name="status_id" id="status_select" class="select2-dropdown" required>
                            <option value="">-- Select Status --</option>
                            <?php foreach ($statuses as $status): ?>
                                <option value="<?= $status['id'] ?>">
                                    <?= htmlspecialchars($status['name']) ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Title (optional):</label>
                        <input type="text" name="title" placeholder="Leave empty for default">
                    </div>
                    <div class="form-group">
                        <label>Message (optional):</label>
                        <textarea name="message" placeholder="Leave empty for default"></textarea>
                    </div>
                    <button type="submit">Send Notifications</button>
                    <div class="result" id="statusResult"></div>
                </form>
            </div>

            <!-- Pending Payments -->
            <div class="card">
                <h2>Payment Reminders</h2>
                <p style="color: #666; margin-bottom: 15px;">
                    Send payment reminders to customers with unpaid approved orders.
                </p>
                <form id="paymentForm">
                    <button type="submit">Send Payment Reminders</button>
                    <div class="result" id="paymentResult"></div>
                </form>
            </div>

            <!-- System Announcement -->
            <div class="card">
                <h2>Send Announcement to All</h2>
                <form id="announcementForm">
                    <div class="form-group">
                        <label>Title: *</label>
                        <input type="text" name="title" required placeholder="System Maintenance">
                    </div>
                    <div class="form-group">
                        <label>Message: *</label>
                        <textarea name="message" required placeholder="Our system will be under maintenance..."></textarea>
                    </div>
                    <button type="submit">Send to All Customers</button>
                    <div class="result" id="announcementResult"></div>
                </form>
            </div>

            <!-- Custom Notification -->
            <div class="card">
                <h2>Custom Notification</h2>
                <p style="color: #666; margin-bottom: 15px;">
                    Send notification to a specific customer (only customers with app installed are shown).
                </p>
                <form id="customForm">
                    <div class="form-group">
                        <label>Customer: * <span class="badge"><?= count($customers) ?> with app</span></label>
                        <select name="customer_id" id="customer_select" class="select2-dropdown" required>
                            <option value="">-- Select Customer --</option>
                            <?php foreach ($customers as $customer): ?>
                                <option value="<?= $customer['id'] ?>">
                                    C<?= str_pad($customer['id'], 2, '0', STR_PAD_LEFT) ?> - <?= htmlspecialchars($customer['name']) ?> (<?= $customer['token_count'] ?> device<?= $customer['token_count'] > 1 ? 's' : '' ?>)
                                </option>
                            <?php endforeach; ?>
                        </select>
                        <?php if (empty($customers)): ?>
                            <small style="color: #dc3545;">No customers with app installed found.</small>
                        <?php endif; ?>
                    </div>
                    <div class="form-group">
                        <label>Title: *</label>
                        <input type="text" name="title" required placeholder="Important Update">
                    </div>
                    <div class="form-group">
                        <label>Message: *</label>
                        <textarea name="message" required placeholder="Your custom message..."></textarea>
                    </div>
                    <div class="form-group">
                        <label>Type:</label>
                        <select name="type" id="type_select" class="select2-dropdown">
                            <option value="general">General</option>
                            <option value="order">Order</option>
                            <option value="payment">Payment</option>
                            <option value="delivery">Delivery</option>
                            <option value="system">System</option>
                            <option value="account">Account</option>
                        </select>
                    </div>
                    <button type="submit">Send Notification</button>
                    <div class="result" id="customResult"></div>
                </form>
            </div>
        </div>
    </div>

    <!-- jQuery (required for Select2) -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <!-- Select2 JS -->
    <script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
    
    <script>
        // Initialize Select2 on dropdowns
        $(document).ready(function() {
            // Customer dropdown
            $('#customer_select').select2({
                placeholder: '-- Select Customer --',
                allowClear: true,
                width: '100%',
                theme: 'default'
            });
            
            // Status dropdown
            $('#status_select').select2({
                placeholder: '-- Select Status --',
                allowClear: true,
                width: '100%',
                theme: 'default'
            });
            
            // Type dropdown
            $('#type_select').select2({
                placeholder: 'Select type',
                allowClear: false,
                width: '100%',
                theme: 'default',
                minimumResultsForSearch: -1 // Hide search box for short list
            });
        });
    </script>
    
    <script>
        async function sendNotification(action, formData) {
            const data = { action, ...formData };
            
            const response = await fetch('notification_center.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
            
            return await response.json();
        }

        function showResult(elementId, success, message, data = null) {
            const el = document.getElementById(elementId);
            el.className = 'result ' + (success ? 'success' : 'error');
            el.style.display = 'block';
            
            let html = '<strong>' + message + '</strong>';
            if (data) {
                html += '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            }
            el.innerHTML = html;
            
            setTimeout(() => {
                el.style.display = 'none';
            }, 10000);
        }

        // Status Form
        document.getElementById('statusForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = e.target.querySelector('button');
            btn.disabled = true;
            btn.textContent = 'Sending...';
            
            const formData = {
                status_id: parseInt(e.target.status_id.value),
                title: e.target.title.value || null,
                message: e.target.message.value || null
            };
            
            const result = await sendNotification('notify_by_status', formData);
            showResult('statusResult', result.success, result.message, result.data);
            
            btn.disabled = false;
            btn.textContent = 'Send Notifications';
            e.target.reset();
            $('#status_select').val(null).trigger('change');
        });

        // Payment Form
        document.getElementById('paymentForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = e.target.querySelector('button');
            btn.disabled = true;
            btn.textContent = 'Sending...';
            
            const result = await sendNotification('notify_pending_payments', {});
            showResult('paymentResult', result.success, result.message, result.data);
            
            btn.disabled = false;
            btn.textContent = 'Send Payment Reminders';
        });

        // Announcement Form
        document.getElementById('announcementForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = e.target.querySelector('button');
            btn.disabled = true;
            btn.textContent = 'Sending...';
            
            const formData = {
                title: e.target.title.value,
                message: e.target.message.value
            };
            
            const result = await sendNotification('send_announcement', formData);
            showResult('announcementResult', result.success, result.message, result.data);
            
            btn.disabled = false;
            btn.textContent = 'Send to All Customers';
            e.target.reset();
        });

        // Custom Form
        document.getElementById('customForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = e.target.querySelector('button');
            btn.disabled = true;
            btn.textContent = 'Sending...';
            
            const formData = {
                customer_id: parseInt(e.target.customer_id.value),
                title: e.target.title.value,
                message: e.target.message.value,
                type: e.target.type.value
            };
            
            const result = await sendNotification('custom_notification', formData);
            showResult('customResult', result.success, result.message, result.data);
            
            btn.disabled = false;
            btn.textContent = 'Send Notification';
            e.target.reset();
            $('#customer_select').val(null).trigger('change');
            $('#type_select').val('general').trigger('change');
        });
    </script>
</body>
</html>

