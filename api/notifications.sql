-- Notifications table for customer notifications
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(50) DEFAULT 'general',
  `is_read` tinyint(1) DEFAULT 0,
  `related_id` int(11) DEFAULT NULL,
  `related_type` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `is_read` (`is_read`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add foreign key constraint
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_customer_fk` 
  FOREIGN KEY (`customer_id`) REFERENCES `buyer` (`id`) ON DELETE CASCADE;

-- Sample notifications for testing
-- INSERT INTO `notifications` (`customer_id`, `title`, `message`, `type`, `is_read`, `related_id`, `related_type`) VALUES
-- (1, 'Order Confirmed', 'Your order #12345 has been confirmed and is being processed.', 'order', 0, 12345, 'order'),
-- (1, 'Payment Received', 'Your payment of $500 has been received successfully.', 'payment', 0, 101, 'payment'),
-- (1, 'Order Shipped', 'Your order #12345 has been shipped and is on the way.', 'order', 0, 12345, 'order'),
-- (1, 'System Announcement', 'We have updated our terms and conditions. Please review them.', 'system', 1, NULL, NULL);

