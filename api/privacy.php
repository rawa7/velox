<?php
header('Content-Type: text/html; charset=UTF-8');
?><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy – Velox Shopping</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: #f5f5f7;
            color: #1d1d1f;
            line-height: 1.7;
            font-size: 16px;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 60px 20px 50px;
            text-align: center;
        }

        .header h1 {
            font-size: 2.4rem;
            font-weight: 700;
            letter-spacing: -0.02em;
            margin-bottom: 10px;
        }

        .header p {
            font-size: 1rem;
            opacity: 0.85;
        }

        .container {
            max-width: 780px;
            margin: 0 auto;
            padding: 48px 24px 80px;
        }

        .card {
            background: #fff;
            border-radius: 18px;
            padding: 48px 44px;
            box-shadow: 0 4px 24px rgba(0,0,0,0.07);
        }

        h2 {
            font-size: 1.15rem;
            font-weight: 700;
            color: #1d1d1f;
            margin: 36px 0 10px;
            padding-bottom: 8px;
            border-bottom: 2px solid #f0f0f5;
        }

        h2:first-child { margin-top: 0; }

        p {
            color: #3a3a3c;
            margin-bottom: 12px;
        }

        ul {
            margin: 8px 0 12px 20px;
            color: #3a3a3c;
        }

        ul li {
            margin-bottom: 7px;
        }

        .highlight-box {
            background: #f5f5f7;
            border-left: 4px solid #667eea;
            border-radius: 8px;
            padding: 16px 20px;
            margin: 16px 0;
            color: #3a3a3c;
            font-size: 0.95rem;
        }

        .contact-box {
            background: linear-gradient(135deg, #667eea15, #764ba215);
            border: 1px solid #667eea30;
            border-radius: 12px;
            padding: 20px 24px;
            margin-top: 12px;
        }

        .contact-box p { margin: 0; color: #3a3a3c; }

        .updated {
            display: inline-block;
            background: #667eea15;
            color: #667eea;
            font-size: 0.85rem;
            font-weight: 500;
            padding: 5px 14px;
            border-radius: 20px;
            margin-bottom: 32px;
        }

        @media (max-width: 600px) {
            .header h1 { font-size: 1.8rem; }
            .card { padding: 28px 20px; }
        }
    </style>
</head>
<body>

<div class="header">
    <h1>Privacy Policy</h1>
    <p>Velox Shopping – Your trusted shopping service</p>
</div>

<div class="container">
    <div class="card">

        <span class="updated">Last updated: <?php echo date('F j, Y'); ?></span>

        <p>
            At <strong>Velox Shopping</strong>, we are committed to protecting your privacy.
            This Privacy Policy explains what information we collect, how we use it, and the choices you have.
            By using our application, you agree to the practices described in this policy.
        </p>

        <!-- 1 -->
        <h2>1. Information We Collect</h2>
        <p>We collect only the information necessary to provide our services to you:</p>
        <ul>
            <li><strong>Account Information:</strong> your name, phone number, email address, and delivery address when you register.</li>
            <li><strong>Order Details:</strong> product descriptions, sizes, quantities, prices, and any notes you provide when placing an order.</li>
            <li><strong>Payment Information:</strong> payment amounts and transaction records. We do not store full card or bank details.</li>
            <li><strong>Images:</strong> product photos you upload to help us identify items for your orders.</li>
            <li><strong>Device Information:</strong> device type and operating system version, used solely to ensure the app works correctly on your device.</li>
            <li><strong>Notification Preferences:</strong> whether you have enabled push notifications, so we can send you order updates.</li>
        </ul>

        <!-- 2 -->
        <h2>2. How We Use Your Information</h2>
        <p>We use the information we collect exclusively to operate and improve our service:</p>
        <ul>
            <li>To create and manage your account.</li>
            <li>To process, track, and fulfil your orders.</li>
            <li>To send you order status updates and delivery notifications.</li>
            <li>To calculate and display your account balance and transaction history.</li>
            <li>To respond to your inquiries and provide customer support.</li>
            <li>To detect and prevent fraudulent or unauthorized activity.</li>
            <li>To improve the performance, reliability, and features of our application.</li>
        </ul>

        <div class="highlight-box">
            We do <strong>not</strong> use your information for advertising, profiling, or any purpose unrelated to fulfilling your orders and managing your account.
        </div>

        <!-- 3 -->
        <h2>3. Information Sharing</h2>
        <p>
            We do <strong>not</strong> sell, rent, or trade your personal information to any third party.
            Your information is never shared with advertisers or marketing companies.
        </p>
        <p>
            Information is shared only in the following limited circumstances:
        </p>
        <ul>
            <li><strong>Internal Operations:</strong> our team uses your order and account details solely to process and deliver your orders.</li>
            <li><strong>Legal Requirements:</strong> we may disclose information if required to do so by applicable law or a valid legal process.</li>
        </ul>

        <!-- 4 -->
        <h2>4. Data Storage and Security</h2>
        <p>
            Your data is stored on secure servers. We apply appropriate technical and organizational measures
            to protect your information against unauthorized access, alteration, disclosure, or destruction.
        </p>
        <p>
            While we strive to use commercially acceptable means to protect your information, no method of
            electronic storage or transmission is completely secure. We cannot guarantee absolute security.
        </p>

        <!-- 5 -->
        <h2>5. Data Retention</h2>
        <p>
            We retain your personal information for as long as your account is active or as needed to provide
            you with our services. If you request account deletion, we will remove your personal data within a
            reasonable period, except where retention is required for legal or legitimate business purposes
            (such as outstanding orders or financial records).
        </p>

        <!-- 6 -->
        <h2>6. Push Notifications</h2>
        <p>
            We may send push notifications to your device to inform you about order updates, delivery status,
            and important account activity. You can enable or disable push notifications at any time through
            your device settings without affecting your ability to use the app.
        </p>

        <!-- 7 -->
        <h2>7. Your Rights and Choices</h2>
        <p>You have the following rights regarding your personal information:</p>
        <ul>
            <li><strong>Access:</strong> you may request a copy of the personal information we hold about you.</li>
            <li><strong>Correction:</strong> you may update or correct your account information at any time within the app.</li>
            <li><strong>Deletion:</strong> you may request the deletion of your account and associated personal data.</li>
            <li><strong>Notifications:</strong> you may opt out of push notifications through your device settings at any time.</li>
        </ul>
        <p>To exercise any of these rights, please contact us using the details in Section 10.</p>

        <!-- 8 -->
        <h2>8. Children's Privacy</h2>
        <p>
            Our application is not directed to children under the age of 13. We do not knowingly collect
            personal information from children. If you believe a child under 13 has provided us with their
            information, please contact us immediately and we will promptly remove the data.
        </p>

        <!-- 9 -->
        <h2>9. Changes to This Privacy Policy</h2>
        <p>
            We may update this Privacy Policy from time to time to reflect changes in our practices or for
            other operational, legal, or regulatory reasons. When we do, we will update the "Last updated"
            date at the top of this page.
        </p>
        <p>
            We encourage you to review this policy periodically. Continued use of our application after
            changes are posted constitutes your acceptance of the updated policy.
        </p>

        <!-- 10 -->
        <h2>10. Contact Us</h2>
        <p>
            If you have any questions, concerns, or requests regarding this Privacy Policy or our data
            practices, please contact our support team:
        </p>
        <div class="contact-box">
            <p><strong>Velox Shopping</strong><br>
            For support and privacy inquiries, please reach out to us directly through the app.</p>
        </div>

    </div>
</div>

</body>
</html>
