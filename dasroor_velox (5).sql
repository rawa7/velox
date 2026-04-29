-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Apr 14, 2026 at 08:53 AM
-- Server version: 10.11.16-MariaDB
-- PHP Version: 8.4.19

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `dasroor_velox`
--

-- --------------------------------------------------------

--
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`id`, `name`, `description`, `is_active`, `created_at`) VALUES
(1, 'Main Account', 'Primary business account', 1, '2026-02-05 11:32:47'),
(2, 'Cash', 'Cash payments', 1, '2026-02-05 11:32:47'),
(3, 'Bank Transfer', 'Bank transfer payments', 1, '2026-02-05 11:32:47'),
(4, 'Credit Card', 'Credit card payments', 1, '2026-02-05 11:32:47'),
(5, 'account 2 ', '', 1, '2026-02-05 11:42:51');

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `id` int(11) NOT NULL,
  `name` varchar(125) NOT NULL,
  `password` varchar(125) NOT NULL,
  `role` varchar(30) NOT NULL DEFAULT 'admin'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`id`, `name`, `password`, `role`) VALUES
(4, 'admin', 'HawreMustafa123123', 'admin'),
(12, 'Salih', 'salih123123', 'customer_service'),
(13, 'Abdulla', 'abdulla123123', 'customer_service'),
(14, 'Nariman', 'nariman123123', 'customer_service'),
(15, 'Zheer', '123123zheer', 'storage'),
(17, 'Danel', '123123danel', 'storage'),
(18, 'Akam', '123123akam', 'storage');

-- --------------------------------------------------------

--
-- Table structure for table `admin_notifications`
--

CREATE TABLE `admin_notifications` (
  `id` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `type` varchar(50) NOT NULL,
  `actor` varchar(100) DEFAULT NULL,
  `actor_type` varchar(50) DEFAULT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `message` text DEFAULT NULL,
  `meta` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`meta`)),
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `read_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin_notifications`
--

INSERT INTO `admin_notifications` (`id`, `created_at`, `type`, `actor`, `actor_type`, `entity_type`, `entity_id`, `title`, `message`, `meta`, `is_read`, `read_at`) VALUES
(1, '2026-04-06 17:57:26', 'item_edit', 'Admin', 'admin', 'item', 1, 'Item updated', 'Item #1 updated', '{\"customer_id\":\"3\"}', 1, '2026-04-06 18:27:30'),
(2, '2026-04-06 18:05:13', 'item_edit', 'Admin', 'admin', 'item', 1, 'Item updated', 'Item #1 updated', '{\"customer_id\":\"3\"}', 1, '2026-04-06 18:27:30');

-- --------------------------------------------------------

--
-- Table structure for table `bank`
--

CREATE TABLE `bank` (
  `id` int(11) NOT NULL,
  `amount` double NOT NULL,
  `note` text NOT NULL,
  `date` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `banners`
--

CREATE TABLE `banners` (
  `id` int(11) NOT NULL,
  `image` varchar(255) NOT NULL,
  `link` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `position` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `note` varchar(125) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `banners`
--

INSERT INTO `banners` (`id`, `image`, `link`, `is_active`, `position`, `created_at`, `note`) VALUES
(1, '32', 'https://abayaislamiya.com/', 1, 1, '2026-01-27 08:59:41', ''),
(2, '33', '', 1, 2, '2026-02-23 09:30:14', '');

-- --------------------------------------------------------

--
-- Table structure for table `box`
--

CREATE TABLE `box` (
  `id` int(11) NOT NULL,
  `name` varchar(155) NOT NULL,
  `statueid` varchar(15) NOT NULL,
  `status` enum('active','in_transit','delivered','archived') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `description` text DEFAULT NULL,
  `purchase_price` decimal(10,2) DEFAULT 0.00 COMMENT 'Manual entry: Price we paid for the box',
  `account_id` int(11) DEFAULT NULL,
  `archived_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `box_tracking`
--

CREATE TABLE `box_tracking` (
  `id` int(11) NOT NULL,
  `box_id` int(11) NOT NULL COMMENT 'Foreign key to box table',
  `tracking_number` varchar(255) NOT NULL COMMENT 'Tracking number',
  `status` varchar(100) DEFAULT 'Created' COMMENT 'Tracking status',
  `notes` text DEFAULT NULL COMMENT 'Optional notes about this tracking',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `brand`
--

CREATE TABLE `brand` (
  `id` int(11) NOT NULL,
  `name` varchar(155) NOT NULL,
  `image` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `brand`
--

INSERT INTO `brand` (`id`, `name`, `image`) VALUES
(1, 'zara', '2'),
(2, 'trendyol', '3'),
(3, 'shein', '8001');

-- --------------------------------------------------------

--
-- Table structure for table `buyer`
--

CREATE TABLE `buyer` (
  `id` int(11) NOT NULL,
  `name` varchar(155) NOT NULL,
  `phone` varchar(155) NOT NULL,
  `address` varchar(155) NOT NULL,
  `instagram` varchar(250) NOT NULL,
  `facebook` varchar(250) NOT NULL,
  `round` int(11) NOT NULL,
  `email` varchar(155) NOT NULL,
  `usertype` int(11) NOT NULL,
  `password` varchar(50) NOT NULL,
  `is_active` int(11) NOT NULL DEFAULT 1,
  `delivery` int(11) NOT NULL,
  `cityid` int(11) DEFAULT NULL COMMENT 'Customer city'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `buyer`
--

INSERT INTO `buyer` (`id`, `name`, `phone`, `address`, `instagram`, `facebook`, `round`, `email`, `usertype`, `password`, `is_active`, `delivery`, `cityid`) VALUES
(1, 'rawa dlshad hussein', '07507746088', 'zanko 92st', '', '', 0, 'rawadlshad7@gmail.com', 1, '123123', 1, 0, 1),
(2, 'mustafa salah', '07509', '075067676', '', '', 0, '', 4, '123123', 1, 0, NULL),
(3, 'Hawre Barzinji', '07506968080', 'hawler, ganjan city', 'hawre_barzinji', '', 0, '', 4, '123123', 1, 0, NULL),
(4, 'Nariman Tofiq', '07507440233', 'rwandz', '', '', 0, '', 5, '123123', 1, 0, NULL),
(5, 'Noor Shwan anwar ', ' 750 182 9990', 'dream city 842', '', '', 0, '', 5, '', 0, 0, NULL),
(6, 'rawa dlshad hussein', '07507746089', 'zanko 92st', '', '', 0, 'rawadlshad7@gmail.com', 8, '123123', 1, 0, 1),
(7, 'rawa', '07507746090', 'zanko92', '', '', 0, '', 5, '123123', 1, 0, NULL),
(9, 'emad', '+9647504991556', 'Zanko 92 st', '', '', 0, '', 5, '123123', 1, 0, NULL),
(10, 'Hawre Barzinji', '+9647506968080', 'Ganjan City, Erbil', '', '', 0, '', 5, '123123', 1, 0, NULL),
(11, 'Danel Jabbar', '+9647801171172', 'ankawa', '', '', 0, '', 5, '123123', 1, 0, NULL),
(12, 'Mustafa', '+9647501444045', 'Royal City', '', '', 0, '', 5, '@Instakurd99', 1, 0, NULL),
(13, 'Rawa Yasen', '07510592783', 'koya, Erbil', '', '', 0, '', 5, 'rawa12345678', 1, 0, NULL),
(14, 'qala', '+9647509067777', 'qala', '', '', 0, '', 5, 'qala12345', 1, 0, NULL),
(15, 'maso', '07701387481', 'eskan', '', '', 0, '', 5, 'maso78', 1, 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `buyerpay`
--

CREATE TABLE `buyerpay` (
  `id` int(11) NOT NULL,
  `buyerid` int(11) NOT NULL,
  `amount` double NOT NULL,
  `dinarconvert` int(11) NOT NULL,
  `sellerid` int(11) NOT NULL,
  `date` varchar(100) NOT NULL,
  `note` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `category`
--

CREATE TABLE `category` (
  `id` int(11) NOT NULL,
  `name` varchar(155) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `category`
--

INSERT INTO `category` (`id`, `name`) VALUES
(1, 'Clothes'),
(2, 'Home Applince'),
(3, 'home decor');

-- --------------------------------------------------------

--
-- Table structure for table `city`
--

CREATE TABLE `city` (
  `id` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `delivery_fee` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Delivery fee for this city (IQD)',
  `shein_rule` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Apply Shein delivery fee rule (0=no, 1=yes)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `city`
--

INSERT INTO `city` (`id`, `name`, `delivery_fee`, `shein_rule`) VALUES
(1, 'hawler ', 2500.00, 1),
(2, 'slemani', 4000.00, 0),
(3, 'dhok', 0.00, 0),
(4, 'ranya ', 0.00, 0),
(5, 'karkuk', 4000.00, 0);

-- --------------------------------------------------------

--
-- Table structure for table `currency`
--

CREATE TABLE `currency` (
  `id` int(11) NOT NULL,
  `currencyname` varchar(40) NOT NULL,
  `currencysign` varchar(5) NOT NULL,
  `currencycode` varchar(5) NOT NULL,
  `currencyconvert` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `currency`
--

INSERT INTO `currency` (`id`, `currencyname`, `currencysign`, `currencycode`, `currencyconvert`) VALUES
(1, 'Dolar', '$', 'USD', 1),
(2, 'Lira', '₺', 'TRY', 42.6),
(3, 'Drham', 'AED', 'AED', 3.6),
(4, 'Pound', '£', 'GBP', 0.68),
(5, 'euro', '€', 'EUR', 0.8);

-- --------------------------------------------------------

--
-- Table structure for table `deliveries`
--

CREATE TABLE `deliveries` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL COMMENT 'Customer who received the delivery',
  `customer_name` varchar(255) NOT NULL COMMENT 'Customer name (denormalized)',
  `items_json` text NOT NULL COMMENT 'JSON array of item IDs delivered',
  `items_count` int(11) DEFAULT 0 COMMENT 'Number of items in this delivery',
  `total_items_dinar` decimal(15,2) DEFAULT 0.00 COMMENT 'Total dinar value of items',
  `shipping_company` varchar(255) DEFAULT NULL COMMENT 'Name of shipping company',
  `shipping_company_cost` decimal(15,2) DEFAULT 0.00 COMMENT 'What we pay the shipping company (IQD)',
  `shipping_charged` decimal(15,2) DEFAULT 0.00 COMMENT 'What we charge the customer for shipping (IQD)',
  `shipping_profit` decimal(15,2) GENERATED ALWAYS AS (`shipping_charged` - `shipping_company_cost`) STORED COMMENT 'Our profit from shipping',
  `amount_paid` decimal(15,2) DEFAULT 0.00 COMMENT 'Amount customer paid (IQD)',
  `payment_method` varchar(100) DEFAULT 'cash' COMMENT 'Payment method used',
  `notes` text DEFAULT NULL,
  `delivered_by` varchar(100) DEFAULT NULL COMMENT 'Admin/staff who processed delivery',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `expense`
--

CREATE TABLE `expense` (
  `id` int(11) NOT NULL,
  `amount` double NOT NULL,
  `note` text NOT NULL,
  `date` varchar(25) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `expense_categories`
--

CREATE TABLE `expense_categories` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `budget_type` enum('office','operating') NOT NULL,
  `icon` varchar(50) DEFAULT 'fas fa-tag',
  `color` varchar(20) DEFAULT '#667eea',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `expense_categories`
--

INSERT INTO `expense_categories` (`id`, `name`, `budget_type`, `icon`, `color`, `is_active`, `created_at`) VALUES
(1, 'Food & Beverages', 'office', 'fas fa-utensils', '#e74c3c', 1, '2026-02-05 10:20:45'),
(2, 'Electricity', 'office', 'fas fa-bolt', '#f1c40f', 1, '2026-02-05 10:20:45'),
(3, 'Water', 'office', 'fas fa-tint', '#3498db', 1, '2026-02-05 10:20:45'),
(4, 'Internet & Phone', 'office', 'fas fa-wifi', '#9b59b6', 1, '2026-02-05 10:20:45'),
(5, 'Office Supplies', 'office', 'fas fa-paperclip', '#1abc9c', 1, '2026-02-05 10:20:45'),
(6, 'Cleaning', 'office', 'fas fa-broom', '#2ecc71', 1, '2026-02-05 10:20:45'),
(7, 'Maintenance', 'office', 'fas fa-wrench', '#e67e22', 1, '2026-02-05 10:20:45'),
(8, 'Rent', 'office', 'fas fa-building', '#34495e', 1, '2026-02-05 10:20:45'),
(9, 'Other Office', 'office', 'fas fa-ellipsis-h', '#95a5a6', 1, '2026-02-05 10:20:45'),
(10, 'Shipping Costs', 'operating', 'fas fa-shipping-fast', '#3498db', 1, '2026-02-05 10:20:45'),
(11, 'Packaging', 'operating', 'fas fa-box', '#e67e22', 1, '2026-02-05 10:20:45'),
(12, 'Customs & Duties', 'operating', 'fas fa-passport', '#9b59b6', 1, '2026-02-05 10:20:45'),
(13, 'Storage', 'operating', 'fas fa-warehouse', '#34495e', 1, '2026-02-05 10:20:45'),
(14, 'Transportation', 'operating', 'fas fa-truck', '#1abc9c', 1, '2026-02-05 10:20:45'),
(15, 'Insurance', 'operating', 'fas fa-shield-alt', '#2ecc71', 1, '2026-02-05 10:20:45'),
(16, 'Staff Salary', 'operating', 'fas fa-users', '#e74c3c', 1, '2026-02-05 10:20:45'),
(17, 'Commission', 'operating', 'fas fa-percentage', '#f1c40f', 1, '2026-02-05 10:20:45'),
(18, 'Other Operating', 'operating', 'fas fa-ellipsis-h', '#95a5a6', 1, '2026-02-05 10:20:45');

-- --------------------------------------------------------

--
-- Table structure for table `fcm_tokens`
--

CREATE TABLE `fcm_tokens` (
  `id` int(10) UNSIGNED NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `token` varchar(255) NOT NULL,
  `platform` varchar(32) DEFAULT NULL,
  `device_id` varchar(128) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `last_seen` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `files`
--

CREATE TABLE `files` (
  `id` int(11) NOT NULL,
  `filename` varchar(250) NOT NULL,
  `filesize` int(11) NOT NULL,
  `web_path` varchar(250) NOT NULL,
  `system_path` varchar(250) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `files`
--

INSERT INTO `files` (`id`, `filename`, `filesize`, `web_path`, `system_path`) VALUES
(1, 'Zara_(retailer)-Logo.wine.png', 51552, '/uploads/1.png', '/home/dasroor/public_html/ruyadream.com/uploads/1.png'),
(2, 'Zara_(retailer)-Logo.wine.png', 51552, '/velox/uploads/2.png', '/home/dasroor/public_html/ruyadream.com/velox/uploads/2.png'),
(3, 'trendyol-logo-png_seeklogo-346740.png', 5278, '/velox/uploads/3.png', '/home/dasroor/public_html/ruyadream.com/velox/uploads/3.png'),
(4, 'shein.png', 1280, '/velox/uploads/4.png', '/home/dasroor/public_html/ruyadream.com/velox/uploads/4.png'),
(5, 'images.jpeg', 5678, '/velox/uploads/5.jpeg', '/home/dasroor/public_html/ruyadream.com/velox/uploads/5.jpeg'),
(6, '1_org_zoom.jpg', 129340, '/images/6.jpg', '../images/6.jpg'),
(7, '1_org_zoom.jpg', 129340, '/images/7.jpg', '../images/7.jpg'),
(8, '382.webp', 8644, '/images/8.webp', '../images/8.webp'),
(9, '1_org_zoom.jpg', 129340, '/images/9.jpg', '../images/9.jpg'),
(10, '1_org_zoom.jpg', 129340, '/images/10.jpg', '../images/10.jpg'),
(11, '1_org_zoom.jpg', 129340, '/images/11.jpg', '../images/11.jpg'),
(12, '1_org_zoom.jpg', 129340, '/images/12.jpg', '../images/12.jpg'),
(13, '1_org_zoom.jpg', 969558, '/images/13.jpg', '../images/13.jpg'),
(14, '1_org_zoom.jpg', 969558, '/images/14.jpg', '../images/14.jpg'),
(15, '1_org_zoom.jpg', 969558, '/images/15.jpg', '../images/15.jpg'),
(16, 'product_1771661484732.jpg', 15300, '/images/16.jpg', '../images/16.jpg'),
(17, 'shein_1771661569868.jpg', 29354, '/images/17.jpg', '../images/17.jpg'),
(18, 'shein_1771662732702.jpg', 29354, '/images/18.jpg', '../images/18.jpg'),
(19, 'shein_1771664006307.jpg', 29354, '/images/19.jpg', '../images/19.jpg'),
(20, 'shein_1771664588801.jpg', 29354, '/images/20.jpg', '../images/20.jpg'),
(21, 'image_picker_363218C6-7D22-45A4-A180-E7A1A1CF93F2-25749-000001045A35816A.png', 270618, '/images/21.png', '../images/21.png'),
(22, 'shein_1771665624796.jpg', 29354, '/images/22.jpg', '../images/22.jpg'),
(23, 'image_picker_646E20AC-E316-4483-A199-3A871B7A2E45-25749-0000012BCDF2E1B4.png', 270618, '/images/23.png', '../images/23.png'),
(24, 'product_1771672319928.jpg', 26861, '/images/24.jpg', '../images/24.jpg'),
(25, 'product_1771672478324.jpg', 21927, '/images/25.jpg', '../images/25.jpg'),
(26, 'image_picker_315483CF-BB63-45AD-B1C3-D7B648B79A1E-25749-0000013117B8AEF1.jpg', 56912, '/images/26.jpg', '../images/26.jpg'),
(27, 'product_1771674704764.jpg', 4390, '/images/27.jpg', '../images/27.jpg'),
(28, 'shein_1771783101999.jpg', 29354, '/images/28.jpg', '../images/28.jpg'),
(31, 'image_picker_B9921B17-6F68-48AF-81BD-CC670F735A67-61816-000001CD020D09BB.jpg', 50849, '/images/31.jpg', '../images/31.jpg'),
(32, '8kg.png', 63956, '/uploads/32.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/32.png'),
(33, '55.png', 102073, '/uploads/33.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/33.png'),
(3088, '3088.PNG', 4920, '/uploads/3088.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/3088.PNG'),
(3435, '3435.png', 3956, '/uploads/3435.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/3435.png'),
(3437, '3437.PNG', 6145, '/uploads/3437.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/3437.PNG'),
(3498, '3498.PNG', 2357, '/uploads/3498.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/3498.PNG'),
(3721, '3721.PNG', 1822, '/uploads/3721.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/3721.PNG'),
(3722, '3722.PNG', 6019, '/uploads/3722.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/3722.PNG'),
(3814, '3814.PNG', 2030, '/uploads/3814.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/3814.PNG'),
(3987, '3987.PNG', 3667, '/uploads/3987.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/3987.PNG'),
(4054, '4054.PNG', 3942, '/uploads/4054.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4054.PNG'),
(4279, '4279.PNG', 1765, '/uploads/4279.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4279.PNG'),
(4424, '4424.PNG', 3968, '/uploads/4424.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4424.PNG'),
(4515, '4515.PNG', 7563, '/uploads/4515.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4515.PNG'),
(4526, '4526.PNG', 3733, '/uploads/4526.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4526.PNG'),
(4557, '4557.jpeg', 274733, '/uploads/4557.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4557.jpeg'),
(4558, '4558.jpeg', 363497, '/uploads/4558.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4558.jpeg'),
(4559, '4559.jpeg', 411741, '/uploads/4559.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4559.jpeg'),
(4560, '4560.jpeg', 429340, '/uploads/4560.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4560.jpeg'),
(4561, '4561.jpeg', 411741, '/uploads/4561.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4561.jpeg'),
(4562, '4562.jpeg', 429340, '/uploads/4562.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4562.jpeg'),
(4563, '4563.jpeg', 411741, '/uploads/4563.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4563.jpeg'),
(4564, '4564.jpeg', 429340, '/uploads/4564.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4564.jpeg'),
(4565, '4565.jpeg', 374036, '/uploads/4565.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4565.jpeg'),
(4566, '4566.jpeg', 373991, '/uploads/4566.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4566.jpeg'),
(4567, '4567.jpeg', 393834, '/uploads/4567.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4567.jpeg'),
(4568, '4568.jpeg', 318079, '/uploads/4568.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4568.jpeg'),
(4569, '4569.jpeg', 124132, '/uploads/4569.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4569.jpeg'),
(4570, '4570.jpeg', 149226, '/uploads/4570.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4570.jpeg'),
(4571, '4571.jpeg', 114047, '/uploads/4571.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4571.jpeg'),
(4572, '4572.jpeg', 149840, '/uploads/4572.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4572.jpeg'),
(4573, '4573.jpeg', 393834, '/uploads/4573.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4573.jpeg'),
(4574, '4574.jpeg', 318079, '/uploads/4574.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4574.jpeg'),
(4575, '4575.jpeg', 153523, '/uploads/4575.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4575.jpeg'),
(4576, '4576.jpeg', 171351, '/uploads/4576.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4576.jpeg'),
(4577, '4577.jpeg', 313331, '/uploads/4577.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4577.jpeg'),
(4578, '4578.jpeg', 351606, '/uploads/4578.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4578.jpeg'),
(4579, '4579.jpeg', 97593, '/uploads/4579.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4579.jpeg'),
(4580, '4580.jpeg', 180447, '/uploads/4580.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4580.jpeg'),
(4582, '4582.jpeg', 144155, '/uploads/4582.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4582.jpeg'),
(4583, '4583.jpeg', 353550, '/uploads/4583.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4583.jpeg'),
(4584, '4584.jpeg', 393547, '/uploads/4584.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4584.jpeg'),
(4585, '4585.jpeg', 388008, '/uploads/4585.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4585.jpeg'),
(4586, '4586.jpeg', 486256, '/uploads/4586.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4586.jpeg'),
(4587, '4587.jpeg', 347556, '/uploads/4587.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4587.jpeg'),
(4588, '4588.jpeg', 403777, '/uploads/4588.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4588.jpeg'),
(4589, '4589.jpeg', 388008, '/uploads/4589.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4589.jpeg'),
(4712, '4712.PNG', 2818, '/uploads/4712.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4712.PNG'),
(4922, '4922.PNG', 1553, '/uploads/4922.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4922.PNG'),
(4977, '4977.png', 3568, '/uploads/4977.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4977.png'),
(4978, '4978.png', 1888, '/uploads/4978.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4978.png'),
(4979, '4979.png', 2100, '/uploads/4979.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4979.png'),
(4981, '4981.png', 3238, '/uploads/4981.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4981.png'),
(4984, '4984.png', 2421, '/uploads/4984.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4984.png'),
(4985, '4985.png', 6930, '/uploads/4985.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4985.png'),
(4986, '4986.png', 3502, '/uploads/4986.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4986.png'),
(4990, '4990.png', 1608, '/uploads/4990.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4990.png'),
(4992, '4992.png', 2736, '/uploads/4992.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4992.png'),
(4994, '4994.png', 1439, '/uploads/4994.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/4994.png'),
(5016, '5016.PNG', 3784, '/uploads/5016.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/5016.PNG'),
(5220, '5220.PNG', 2699, '/uploads/5220.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/5220.PNG'),
(5365, '5365.PNG', 335, '/uploads/5365.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/5365.PNG'),
(5517, '5517.PNG', 335, '/uploads/5517.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/5517.PNG'),
(6073, '6073.PNG', 2308, '/uploads/6073.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6073.PNG'),
(6118, '6118.PNG', 2291, '/uploads/6118.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6118.PNG'),
(6394, '6394.PNG', 113859, '/uploads/6394.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6394.PNG'),
(6395, '6395.PNG', 227021, '/uploads/6395.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6395.PNG'),
(6396, '6396.PNG', 279622, '/uploads/6396.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6396.PNG'),
(6407, '6407.jpg', 430499, '/uploads/6407.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6407.jpg'),
(6408, '6408.jpg', 99568, '/uploads/6408.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6408.jpg'),
(6410, '6410.png', 279622, '/uploads/6410.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6410.png'),
(6416, '6416.PNG', 112070, '/uploads/6416.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6416.PNG'),
(6417, '6417.PNG', 447576, '/uploads/6417.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6417.PNG'),
(6418, '6418.jpg', 46937, '/uploads/6418.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6418.jpg'),
(6419, '6419.PNG', 132942, '/uploads/6419.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6419.PNG'),
(6420, '6420.jpg', 25755, '/uploads/6420.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6420.jpg'),
(6421, '6421.PNG', 376863, '/uploads/6421.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6421.PNG'),
(6422, '6422.PNG', 169888, '/uploads/6422.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6422.PNG'),
(6423, '6423.PNG', 45400, '/uploads/6423.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6423.PNG'),
(6424, '6424.PNG', 51733, '/uploads/6424.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6424.PNG'),
(6425, '6425.PNG', 89155, '/uploads/6425.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6425.PNG'),
(6426, '6426.PNG', 172306, '/uploads/6426.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6426.PNG'),
(6427, '6427.PNG', 139106, '/uploads/6427.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6427.PNG'),
(6429, '6429.PNG', 116755, '/uploads/6429.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6429.PNG'),
(6430, '6430.PNG', 120189, '/uploads/6430.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6430.PNG'),
(6431, '6431.PNG', 195466, '/uploads/6431.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6431.PNG'),
(6433, '6433.PNG', 291270, '/uploads/6433.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6433.PNG'),
(6434, '6434.PNG', 95038, '/uploads/6434.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6434.PNG'),
(6436, '6436.jpg', 39981, '/uploads/6436.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6436.jpg'),
(6440, '6440.PNG', 274506, '/uploads/6440.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6440.PNG'),
(6442, '6442.PNG', 281466, '/uploads/6442.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6442.PNG'),
(6443, '6443.PNG', 212467, '/uploads/6443.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6443.PNG'),
(6448, '6448.PNG', 253359, '/uploads/6448.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6448.PNG'),
(6450, '6450.PNG', 364746, '/uploads/6450.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6450.PNG'),
(6451, '6451.PNG', 369027, '/uploads/6451.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6451.PNG'),
(6454, '6454.PNG', 326627, '/uploads/6454.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6454.PNG'),
(6456, '6456.PNG', 350775, '/uploads/6456.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6456.PNG'),
(6457, '6457.PNG', 267728, '/uploads/6457.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6457.PNG'),
(6496, '6496.PNG', 47749, '/uploads/6496.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6496.PNG'),
(6497, '6497.PNG', 2674, '/uploads/6497.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6497.PNG'),
(6525, '6525.PNG', 28835, '/uploads/6525.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6525.PNG'),
(6603, '6603.PNG', 335, '/uploads/6603.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/6603.PNG'),
(7040, '7040.jpeg', 100587, '/uploads/7040.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7040.jpeg'),
(7041, '7041.jpeg', 200436, '/uploads/7041.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7041.jpeg'),
(7042, '7042.jpeg', 267683, '/uploads/7042.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7042.jpeg'),
(7044, '7044.jpg', 128597, '/uploads/7044.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7044.jpg'),
(7045, '7045.jpg', 121438, '/uploads/7045.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7045.jpg'),
(7046, '7046.jpg', 195444, '/uploads/7046.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7046.jpg'),
(7048, '7048.jpeg', 111683, '/uploads/7048.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7048.jpeg'),
(7049, '7049.jpeg', 94417, '/uploads/7049.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7049.jpeg'),
(7050, '7050.jpeg', 110264, '/uploads/7050.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7050.jpeg'),
(7051, '7051.jpeg', 159023, '/uploads/7051.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7051.jpeg'),
(7052, '7052.jpeg', 162913, '/uploads/7052.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7052.jpeg'),
(7053, '7053.jpeg', 121373, '/uploads/7053.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7053.jpeg'),
(7056, '7056.jpeg', 84967, '/uploads/7056.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7056.jpeg'),
(7057, '7057.jpg', 22128, '/uploads/7057.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7057.jpg'),
(7059, '7059.PNG', 120270, '/uploads/7059.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7059.PNG'),
(7060, '7060.PNG', 325560, '/uploads/7060.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7060.PNG'),
(7061, '7061.jpeg', 186479, '/uploads/7061.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7061.jpeg'),
(7062, '7062.jpeg', 220470, '/uploads/7062.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7062.jpeg'),
(7063, '7063.jpeg', 120099, '/uploads/7063.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7063.jpeg'),
(7064, '7064.jpeg', 115021, '/uploads/7064.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7064.jpeg'),
(7065, '7065.jpeg', 143051, '/uploads/7065.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7065.jpeg'),
(7066, '7066.jpeg', 101498, '/uploads/7066.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7066.jpeg'),
(7067, '7067.jpeg', 149621, '/uploads/7067.jpeg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7067.jpeg'),
(7068, '7068.PNG', 344536, '/uploads/7068.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7068.PNG'),
(7069, '7069.PNG', 391945, '/uploads/7069.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7069.PNG'),
(7070, '7070.PNG', 379730, '/uploads/7070.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7070.PNG'),
(7071, '7071.PNG', 481705, '/uploads/7071.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7071.PNG'),
(7074, '7074.PNG', 68086, '/uploads/7074.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7074.PNG'),
(7080, '7080.jpg', 10063, '/uploads/7080.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7080.jpg'),
(7081, '7081.jpg', 44905, '/uploads/7081.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7081.jpg'),
(7082, '7082.jpg', 51911, '/uploads/7082.jpg', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7082.jpg'),
(7084, '7084.PNG', 203005, '/uploads/7084.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7084.PNG'),
(7253, '7253.png', 33421, '/uploads/7253.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7253.png'),
(7542, '7542.PNG', 8354, '/uploads/7542.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7542.PNG'),
(7560, '7560.PNG', 326992, '/uploads/7560.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7560.PNG'),
(7561, '7561.PNG', 292118, '/uploads/7561.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7561.PNG'),
(7562, '7562.PNG', 332584, '/uploads/7562.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7562.PNG'),
(7568, '7568.PNG', 176371, '/uploads/7568.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7568.PNG'),
(7569, '7569.PNG', 204546, '/uploads/7569.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7569.PNG'),
(7571, '7571.JPG', 65521, '/uploads/7571.JPG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7571.JPG'),
(7573, '7573.JPG', 7116, '/uploads/7573.JPG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7573.JPG'),
(7575, '7575.JPG', 11831, '/uploads/7575.JPG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7575.JPG'),
(7763, '7763.PNG', 335, '/uploads/7763.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7763.PNG'),
(7827, '7827.JPG', 5156, '/uploads/7827.JPG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7827.JPG'),
(7848, '7848.PNG', 335, '/uploads/7848.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7848.PNG'),
(7892, '7892.PNG', 335, '/uploads/7892.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7892.PNG'),
(7991, '7991.PNG', 335, '/uploads/7991.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7991.PNG'),
(7998, '7998.PNG', 335, '/uploads/7998.PNG', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7998.PNG'),
(7999, '43.png', 51795, '/uploads/7999.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/7999.png'),
(8000, 'product_1771843827112.jpg', 4390, '/images/8000.jpg', '../images/8000.jpg'),
(8001, '14.png', 95571, '/uploads/8001.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/8001.png'),
(8002, 'product_1771848334028.jpg', 9716, '/images/8002.jpg', '../images/8002.jpg'),
(8003, 'product_1771848962276.jpg', 9716, '/images/8003.jpg', '../images/8003.jpg'),
(8004, 'product_1771849270162.jpg', 9716, '/images/8004.jpg', '../images/8004.jpg'),
(8005, 'product_1771849327065.jpg', 279113, '/images/8005.jpg', '../images/8005.jpg'),
(8006, 'shein_1774912312049.jpg', 44413, '/images/8006.jpg', '../images/8006.jpg'),
(8007, 'product_1775475715987.jpg', 9716, '/images/8007.jpg', '../images/8007.jpg'),
(8008, 'product_1775480251553.jpg', 57387, '/images/8008.jpg', '../images/8008.jpg'),
(8009, '3.png', 430650, '/uploads/8009.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/8009.png'),
(8010, '3.png', 430650, '/uploads/8010.png', '/home/dasroor/public_html/veloxshoppingiq.com/uploads/8010.png'),
(8011, 'shein_1775490554610.jpg', 76096, '/images/8011.jpg', '../images/8011.jpg'),
(8012, 'shein_1775546371239.jpg', 44413, '/images/8012.jpg', '../images/8012.jpg'),
(8013, 'item_1775549084091.jpg', 9716, '/images/8013.jpg', '../images/8013.jpg'),
(8014, 'product_1775772591638.jpg', 9716, '/images/8014.jpg', '../images/8014.jpg'),
(8015, 'shein_1775772640944.jpg', 51591, '/images/8015.jpg', '../images/8015.jpg'),
(8016, 'product_1775976002296.jpg', 5210, '/images/8016.jpg', '../images/8016.jpg'),
(8017, 'product_1776117624629.jpg', 22694, '/images/8017.jpg', '../images/8017.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `items`
--

CREATE TABLE `items` (
  `id` int(11) NOT NULL,
  `serial` varchar(8) DEFAULT NULL,
  `has_sub_items` tinyint(1) DEFAULT 0 COMMENT '1 = grouped item with sub-items, 0 = regular item',
  `customer_id` int(11) NOT NULL,
  `websiteid` int(11) NOT NULL,
  `country` enum('Turkey','Germany','USA','UAE','Shein') NOT NULL,
  `link` text NOT NULL,
  `size` text NOT NULL,
  `qty` int(11) NOT NULL,
  `itemprice` double NOT NULL,
  `cargo` decimal(10,2) DEFAULT 0.00,
  `shippingprice` double NOT NULL,
  `tax` double NOT NULL,
  `commission` double NOT NULL,
  `totalprice` double NOT NULL,
  `rate` decimal(10,4) DEFAULT 1.0000 COMMENT 'Exchange rate for currency conversion',
  `total_dinar` decimal(10,2) DEFAULT 0.00 COMMENT 'Total price in dinar (totalprice * rate)',
  `in_iraq_delivery` decimal(10,2) DEFAULT 0.00 COMMENT 'Additional delivery cost in Iraqi Dinar',
  `converttodinar` double NOT NULL,
  `status` double NOT NULL,
  `box_id` int(11) DEFAULT NULL,
  `image` int(11) NOT NULL,
  `adminid` int(11) NOT NULL,
  `added_by` varchar(50) DEFAULT 'app' COMMENT 'Source: whatsapp, instagram, or app',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `date` text NOT NULL,
  `currency_id` int(11) NOT NULL,
  `paymentstatus` tinyint(1) NOT NULL,
  `color` varchar(150) NOT NULL,
  `note` text NOT NULL,
  `brand_id` int(11) DEFAULT NULL,
  `pcountry` enum('Turkey','Germany','USA','UAE','Shein') DEFAULT NULL,
  `cost_price` decimal(10,2) DEFAULT NULL COMMENT 'Manual cost price for profit calculation',
  `warehouse_location` varchar(20) DEFAULT NULL COMMENT 'Warehouse shelf location e.g. A1, B3, Top Shelf'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `items`
--

INSERT INTO `items` (`id`, `serial`, `has_sub_items`, `customer_id`, `websiteid`, `country`, `link`, `size`, `qty`, `itemprice`, `cargo`, `shippingprice`, `tax`, `commission`, `totalprice`, `rate`, `total_dinar`, `in_iraq_delivery`, `converttodinar`, `status`, `box_id`, `image`, `adminid`, `added_by`, `created_at`, `date`, `currency_id`, `paymentstatus`, `color`, `note`, `brand_id`, `pcountry`, `cost_price`, `warehouse_location`) VALUES
(1, 'DEQ4DPQ0', 1, 3, 1, 'Shein', 'https://api-shein.shein.com/h5/sharejump/appjump?link=lAiTh6bIg63_b&localcountry=AE&shc=2_lAiTh6bIg63&url_from=GM76129161245', '', 1, 658.03, 0.00, 0, 0, 0, 658, 1400.0000, 921250.00, 0.00, 1, 3, NULL, 8006, 0, 'app', '2026-03-30 23:14:23', '', 1, 0, '', '[I12urop9zuom] فستان أنيق بأكمام طويلة مزود بياقة قميص للفتيات الناشئات، تصميم مكون من قطعتين، مناسب للارتداء اليومي والرسمي في فصول الربيع والخريف والشتاء x1 @ 14.12\r\n[I0c8gdc2xc78] سوار مضفر بزخرفة تاج فاخر من الفولاذ المقاوم للصدأ للرجال قطعة واحدة، مناسب للاستخدام اليومي، هدية مثالية لأعياد ميلاد صديق صبي أو صديق x1 @ 3.81\r\n[I0c8gdc8u44t] سوار مضفر بزخرفة تاج فاخر من الفولاذ المقاوم للصدأ للرجال قطعة واحدة، مناسب للاستخدام اليومي، هدية مثالية لأعياد ميلاد صديق صبي أو صديق x1 @ 3.81\r\n[I7mmenbyc3ytx1] ساعة نسائية موضة، مزينة بفراشة، قرص دائري مرصع بالراين ستون، حركة كوارتز بسيطة، مناسبة للارتداء اليومي، هدية عيد ميلاد، حفلة، عطلة، خيار جودة x1 @ 2.74\r\n[I64pz9v9b494] 6 قطع / مجموعة معدن خاصرة مشبك ألومنيوم مع دبابيس، ديكور ماس وفراشة حديث، اكسسوار خاصرة للمنزل، مناسب للنساء والفتيات لتضييق خصر البنطلون والزينة (4/6/1 قطعة) x1 @ 1.33\r\n[I53bdlxn5jlh] حزام سلسلة مزين بالزهور والخرز الاصطناعي للحفلات والهالوين والصيف والمدرسة والخريف x1 @ 2.13\r\n[I6503e9r4ep8] 1 قطعة مشبك شعر نسائي جديد بتصميم فراشة كبيرة مطرزة بخرز وشبكة، تاج رأس حلو مناسب للتصوير، إكسسوارات شعر شتوية، مشبك شعر عادي لعيد الحب، هدية إكسسوارات عيد الحب، مشبك أنيق للشاطئ والعطلات الصيفية x1 @ 1.86\r\n[I724hrkj8l3t] طقم قلادة إينامل بتصميم فراشة بيضاء، قلادة خونرة عالية الجودة أنيقة وعصرية وبسيطة x1 @ 1.60\r\n[I59h2r1o1f3i] 24 ملصق أظافر على شكل زهور، أظافر جل ثلاثية الأبعاد بشكل لوز، إنشاء أظافر زهرية زرقاء، تصميم ديكور اللؤلؤ، أظافر أكريليك فرنسية للضغط، مجموعة أظافر مزيفة مناسبة للارتداء لفترة طويلة، تشمل: 1 جل جيلي و 1 ملف أظافر، سهلة الارتداء، فن أظافر الزهور، مناسبة لأظافر الصيف، العمل اليومي، الحفلات، لوازم الأظافر x1 @ 1.51\r\n[I97r6wofuyv0] خاتم مفتوح قابل للتعديل بلؤلؤ صناعي للنساء، أسلوب حداثة الموضة x1 @ 1.03\r\n[I05zcovvesr4] ROMWE حزام سلسلة مزخرف بفراشة x1 @ 2.93\r\n[I3ml7pzefahif6] ساعة يد نسائية فاخرة صغيرة الحجم بعقارب مربعة من الفولاذ المقاوم للصدأ بطراز عتيق، ساعة كوارتز أنيقة وبسيطة مناسبة للارتداء اليومي والمناسبات x1 @ 4.94\r\n[I5mkfgerwyw7uy] دبوس وشاح من اللؤلؤ الاصطناعي، إكسسوار عملي يمكن تثبيته على الأوشحة والسترات والجواكت لمنع تلف الملابس، أنيق وعملي x1 @ 1.07\r\n[I8mkfgerx56xfy] دبوس وشاح من اللؤلؤ الاصطناعي، إكسسوار عملي يمكن تثبيته على الأوشحة والسترات والجواكت لمنع تلف الملابس، أنيق وعملي x1 @ 1.07\r\n[I02i1jye4lhr] سوار أنيق مزين باللؤلؤ والراين للبنات قطعة واحدة x1 @ 1.26\r\n[I56s1tq0rr8n] قلادة أنيقة وعصرية بتصميم على شكل حرف Y متعددة الطبقات، مناسبة للارتداء اليومي للنساء، هدايا مجوهرات للخطوبة، قلادات زفاف للارتداء في عيد الحب x1 @ 1.26\r\n[I0n2ts3b3xb] Modelyn فستان حفلة أنيق مع أكمام متسعة، مزين بالراين ستون، قماش متنوع، مخصر عند الخصر x1 @ 19.45\r\n[I12x7hpkibuh] قطعة واحدة من أساور إصبع نسائية عصرية وبسيطة، سوار سلسلة بسيط، مناسب للارتداء اليومي للنساء، كذلك هدية رائعة للمناسبات (سلسلة مصنوعة يدويًا مقطعة حسب المقاس، عدد متغير من الخرز، حجم متغير من الراين) x1 @ 1.31\r\n[I98yyrwtfc6j] 1 قطعة خاتم مفتوح من الزركونيا ذو صفين، مناسب للارتداء اليومي x1 @ 1.82\r\n[I92ixs9iurn6] زوج أقراط زهرية بسيطة من الاكريليك للنساء (ألوان البتلات عشوائية) x1 @ 2.40\r\n[I47mlqttm2bb] 1 سوار لسيدة بتصميم فريد من اللؤلؤ البروكات الحظ بشكل قلب، إكسسوار مجوهرات راقية x1 @ 1.48\r\n[I83umihndm0s] 1 مجوهرات زهرة سوار القفازات x1 @ 1.60\r\n[I8zx4szjs1qf] طقم مكون من 4 قطع (قلادة، أقراط، خاتم، سوار) مرصع بالكريستال بتصميم التاج، اكسسوارات الزفاف / العروس للاحتفالات والأعياد والعروض الفنية، اكسسوارات الشعر (حجاب العروس)رمضان x1 @ 4.49\r\n[I0zgyrwefitc] Yasmyna جلابيات قفاطين فستان ماكسي تركي للنساء والعباءة العربية التقليدية x1 @ 19.18\r\n[I8czjoqyoyzy] Yasmyna فستان ماكسي تركي للنساء والعباءة العربية التقليدية x1 @ 19.71\r\n[I4bbfso9lsuu] Yasmyna جلابيات قفاطين فستان أنيق للنساء بياقة على شكل حرف V وأكمام طويلة مزين بنقشة من الترتر على شكل فراشة x1 @ 19.06\r\n[I82yevr7bz2o] 24 قطعة أظافر مزيفة مزينة بالراين ستون الذهبي ثلاثي الأبعاد غير متماثل ذات طراز عصري رجعي، تعزز مظهرك بأناقة وأناقة. مناسبة للفتيات والسيدات الأنيقات والأنيقات للاستخدام اليومي. ملصقات أظافر للضغط عليها، لوازم فن الأظافر x1 @ 1.80\r\n[I490t18wtaco] 3 قطع طقم مجوهرات قلادة + أقراط أنيقة للنساء، تصميم معدني مجوف أنيق بزهور وفراشات مع خرز اصطناعي، قلادة طويلة، إكسسوارات متعددة الاستخدامات x1 @ 2.66\r\n[I9mj1f4m15p65v] مشبك شعر كبير بشكل فراشة وردية للنساء، إكسسوارات شعر أنيقة x1 @ 1.12\r\n[I3251b21cxok] سوار نسائي بتصميم هندسي ملون من الزركونيا، عصري وطازج للصيف قطعة واحدة x1 @ 1.86\r\n[I3vn2i9c83xx] مشبك شعر فراشة مزين باللؤلؤ والراين كبير الحجم للشعر المضفر، باللون الوردي، مناسب للاستخدام اليومي والحفلات وعيد الحب، اكسسوارات شعر للنساء للاستخدام في الشاطئ والعطلات الصيفية x1 @ 1.86\r\n[I53wfwq2ex6x] مشبك شعر كبير مزين بالخرز الاصطناعي والراين بشكل فراشة، أنيق وجذاب للكعكة، اكسسوار وردي مناسب للخروجات اليومية والمناسبات، عيد الحب، اكسسوارات الشعر، مشبك شعر، مشبك فك، مشبك شعر، مشبك فك، للملابس الصيفية والشتوية للنساء x1 @ 1.86\r\n[I84w2leyjge1] Andkiss سوار من الخرز المرصع بزخرفة اللؤلؤ الاصطناعيرمضان x1 @ 1.31\r\n[I29actvrm0rf] Al Najma رمضان فستان عربي أنيق بأكمام طويلة مطرز بطبعات زهرية على طوق الياقة، مصنوع من نسيج جاكار مُنسوج باللون الأخضر x1 @ 22.10\r\n[I1mm5qb1xosqd4] 30 قطعة من ملصقات أظافر أكريليك على شكل لب/قلب لون أحمر بشكل لوز متوسط الحجم، طقم أظافر صناعية ثلاثية الأبعاد بزخرفة فيونكة، مناسبة لصالونات الأظافر والفتيات والنساء للاستخدام اليومي والمناسبات والهدايا x1 @ 1.60\r\n[I7mm0b0jl1l09v] 24 ملصق أظافر جل زهري ثلاثي الأبعاد بشكل اللوز، تصميم فرنسي أبيض، مناسب لمجموعة أظافر أكريليك، يتضمن 1 جل جيلي و 1 ملف أظافر، مناسب للصيف، DIY للنساء والفتيات لاستخدام يومي، العمل، الدراسة والحفلات x1 @ 1.49\r\n[I475ojwpcxcl] مجموعة مجوهرات نسائية جديدة لصيف أسلوب الريف العطلة، بقلادة زهرة مينا زرقاء غير متماثلة ، أقراط زوج واحد ، خاتم واحد ، سوار واحد (باستثناء علبة الهدية) x1 @ 4.93\r\n[I475ojwobbu5] مجموعة من قطعة عقد بشكل زهري متناسق وأقراط وخاتم وسوار، طقم مجوهرات نسائية (لا يشتمل على علبة هدايا) x1 @ 4.34\r\n[I3wurjes3ds2] طقم مجوهرات للنساء مكون من: 1 قلادة بتعليقة زهرة وردية متدرجة الطبقة غير متماثلة مصنوعة يدويًا، 1 زوج من الأقراط، 1 خاتم، 1 سوار، 1 أسورة (بدون علبة هدايا) x1 @ 4.69\r\n[I528hwo7l311] ساعة كوارتز أنيقة للنساء 1قطعة بسلسلة قابلة للتعديل ذات خرز ذهبي، علبة بلون الذهب الوردي، وقرص أم اللؤلؤ المنسوج، مناسبة للمناسبات الرسمية x1 @ 2.61\r\n[I56mxsvvb7xp] ساعة سوار للنساء برؤية كريستال مقطوع ماس وخرزة كبيرة واحدة، ساعة كوارتز بسيطة x1 @ 3.01\r\n[I61bm9kjn4li] زوج أقراط حلقية على شكل C مزين بالخرز الصناعي ذو تصميم راقي فاخر مناسب للنساء في الأناقة الشخصية والأحداث والحفلاترمضان x1 @ 1.03\r\n[I8u8o7njgx75] خاتم مرصع بالزركونيا المكعبة والخرز الاصطناعي، هدية مجوهرات للنساء في عيد الزفاف والذكرى السنوية x1 @ 1.76\r\n[I820f7srmc6o] SHEIN بنطلون جينز أزرق فينتاج مبطن حراريًا مع خصر غير متماثل فضفاض، للفتيات، مناسب للخريف والشتاء، أنيق للفتيات في x1 @ 12.25\r\n[I14cj1hw8b2o] SHEIN بنطلون جينز لفتاة يافعة بيت Y2K كاجول متهالك أزرق قصمية فضفاض، بنطلون جينز كاجوال فضفاض للبنات للربيع والصيف للأيام العطلة x1 @ 12.23\r\n[I22n91diomj9] مجموعة قبعة شمسية للفتيات بطبعات زهور وحقيبة 2 قطعة، مناسبة للزي الربيعي / الصيفي الخاص بالعطلات، لبس اليومي، حماية من الأشعة فوق البنفسجية x1 @ 3.23\r\n[I3860bz3snb0] قميص تي شيرت بدون أكمام بتصميم أشجار وشورت هاواي مرن الخصر قطعتان للأولاد x1 @ 6.01\r\n[I5d3bmf6k9ca] صنادل كعب عالي للبنات، أحذية جلالية مرصعة بالترتر بألوان نمط للبنات الصغيرات، مناسبة للأداء والعروض والحفلات x1 @ 18.38\r\n[I72qejthuqs7] قبعة شمسية وحقيبة أطفال الأجزاء تحتوي على طبعة فراشة كرتونية، قبعة شاطئ قطنية لطيفة للأولاد والبنات في الحياة اليومية أو العطلات x1 @ 5.52\r\n[I09c3wmkru7q] SHEIN تي شيرت أنيق بأكمام قصيرة بطبعة ديناصور لصبي المراهقين، مجموعة مطبوعة بتصميم الديناصور مكونة من قطعتين مناسبة للصيف x1 @ 7.24\r\n[I852tto2fblv] SHEIN مجموعة قميص كاجوال ذو رقبة دائرية وشورت للأولاد المراهقين 2 قطعة، بتصميم بسيط، صيفي x1 @ 7.72\r\n[I48rqnk1x8b8] SHEIN توب ملابس علوية آزرق وأصفر بطبعة ظل أشجار النخيل وألوان الغروب المناسب للشباب، مناسب للصيف والشاطئ والعطلات والأنشطة الخارجية x1 @ 4.26\r\n[I06uo4kouv19] SHEIN مايوه طقم متكامل بطبعات استوائية واحدة للفتيات، مع معطف كيمونو. x1 @ 7.85\r\n[I674weinhv36] SHEIN مجموعة ملابس علوية كاميسول مطرز ثلاثي الأبعاد وبقصة غير متماثلة مع بنطلون كاجوال طويل للفتيات في الصيف، قطعتين x1 @ 7.19\r\n[I357hk2z8pnf] SHEIN زي شاطئي لطفلة، ملابس علوية بلا أكمام مريح مطاطي مع بنطلون واسع الأرجل ، صيف / شتاء x1 @ 5.95\r\n[I66x2bxtabgb] 3 قطع طقم بنات مراهقات مكون من ملابس علوية كامي مطبوع عليه حرف بروكلين + ملابس علوية شبكية + شورت، طقم صيفي عصري للخارج، مناسب كهدية صيفية x1 @ 8.71\r\n[I78jvc9f05bk] SHEIN 2 قطعة / مجموعة طقم ملابس نسائية رياضي كاجوال، تشمل: تيشيرت جرافيك 56 مطبوع عليه شعار \"كل يوم مميز\" وأكمام ملونة متباينة، شورت دراجة متناسق، مناسب للصيف، الرياضة، اللياقة البدنية، التسوق والأنشطة الاجتماعية x1 @ 5.25\r\n[I6493k3h97vx] حقيبة يد أنيقة مزينة بالجليتر وتقليد اللؤلؤ للحفلات المسائية x1 @ 6.66\r\n[I94uwmo9145t] نظارات شمسية رائجة وعصرية للأطفال الذين تتراوح أعمارهم بين 4-10 سنوات، ذات إطار مربع كبير وإطارات \"Love\" عالية الجودة ومتعددة الاستخدامات ومناسبة للخروجات اليومية ولضروريات الارتداء x1 @ 5.06\r\n[I97yla2m733i] 1 قطعة من الإكسسوارات الزخرفية المتفكّكة بألوان كرتونية صلبة مصنوعة من السيليكون، مناسب للحقيبة اليدوية وحقيبة الشاطئ والاستخدام الخارجي وألعاب الشاطئ وأيضًا كهدية عيد ميلاد x1 @ 4.26\r\n[I17xqyyl27ud] مجموعة مشط مربع وزجاجة رذاذ 7 قطع، مشط بلاستيكي مضاد للكهرباء الساكنة بطباعة برج إيفل الكرتونية، مشبك شعر محمول بنمط، زجاجة رذاذ ضغط عالي، مناسبة للأطفال والفتيات، لأنواع الشعر العادية، مقبض ABS متين، تصميم مربع جميل، طقم أدوات تصفيف الشعر x1 @ 5.27\r\n[I92ixwa7m5x1] فستان صيفي للبنت الصغيرة بطبعة زهرية وحواف مكرمشة مع أشرطة مربعة، تصميم منعش، ضروري الامتلاك x1 @ 5.95\r\n[I2d1x8mohp3o] زوج من صنادل رياضية للأطفال اللون الخاكي، أحذية شاطئ للأطفال الصغار، أحذية صيفية عادية للمشي للرضع، نعال ناعمة وجميلة x1 @ 6.90\r\n[I53ujckf5vjc] SHEIN Elladie kids مجموعة من ملابس علوية بدون أكمام طباعة قلب بسيط أمامي وتنورة قصيرة للفتيات الصغيرات، 2 قطعة x1 @ 8.39\r\n[I176dw8ogixp] SHEIN 3 طقم بدلة رياضية للبنات مطبوع بطبعة الكاموفلاج والقلوب والزهور والأشكال الهندسية الملونة x1 @ 10.39\r\n[I983idv3ihpl] شبشب مفتوح الأصبع مريح، صنادل شاطئ خفيفة الوزن وقابلة للتنفس للبنات، مناسبة للأنشطة الخارجية x1 @ 7.90\r\n[I7s5brlfpuqh] حقيبة ظهر أطفال ضد للماء تصميم رسوم كارتون أرنب ديكور x1 @ 11.19\r\n[I1abave71108] بدلة قصيرة لطيفة مطبوعة بنقش الزهور للفتاة الشابة بأكتاف عارية وردية بحاشية مزينة بالريش، مثالي لعطلة الصيف x1 @ 8.40\r\n[I3brjx0ymlww] زوج من أحذية الأطفال المسطحة الأنيقة، أحذية أطفال مسطحة جديدة، أحذية بنات مزينة بفيونكة x1 @ 10.11\r\n[I5mkmh580yqv31] SHEIN Genkimix Kids مجموعة قميص كامي مطرز ثلاثي الأبعاد وبتصميم غير متماثل مع بنطلون كاجوال للبنات في الصيف، 2 قطعة/مجموعة x1 @ 7.73\r\n[I271b8zek5nq] بدلة سباحة مطبوعة بأنماط عشوائية لفتاة صغيرة x1 @ 9.06\r\n[I25k3rxup0ly] SHEIN طقم بنطال جينز وسترة بلا أكمام بنمط أنيق للفتيات، ملابس خريف/شتاء للأطفال، ملابس عودة للمدرسة وحفلات عودة للمنزل، طقم أنيق قطعتين x1 @ 16.52\r\n[I3cm55nog6j8] بدلة سباحة للبنات الصغيرات بكتف واحد وبدون أكمام مع فتحات جانبية وتنورة شبكية. هذه البدلة الأنيقة والكاجوال والأنيقة مثالية للسباحة والعطلات وبدلات السباحة الصيفية للبنات الصغيرات. x1 @ 6.13\r\n[I14cghzgzzrt] SHEIN طقم قميص بستراب شبكي بزخرفة وردية ثلاثية الأبعاد وتنورة بعقدة جميلة لفتاة صغيرة، صيفي بلون صلب 2 قطعة x1 @ 11.89\r\n[I6mj8j1uzrs6nw] مجموعة قميص وبنطلون بأكمام قصيرة وياقة طاقم للفتيان المراهقين، بتصميم كاجوال بسيط وأنيق، بطبعات الديناصور والكامفلاج والرسومات اليدوية الجرافيتية، بقصة فضفاضة مريحة وأنيقة x1 @ 9.06\r\n[I138hnmnpsng] SHEIN لباس علوي بدون أكمام بطبعة استوائية و تنورة بحافة متموجة لفتاة صغيرة x1 @ 5.70\r\n[I6elf4hlrha8] SHEIN لباس علوي علوي بشريط حروف وشورت دولفين لفتاة صغيرة x1 @ 5.45\r\n[I16iw0w4owho] نظارات أطفال جميلة بزهور وأذنين دب، بطاقة عرض فقط، بدون شحن x1 @ 3.01\r\n[I2d7f5zkvfbt] زوج من صنادل بيج مسطحة للبنات، لون أحادي من جلد البولي يوريثان مع حزام قابل للتعديل، تصميم إبزيم لؤلؤي لامع، مفتوحة من الأمام، صنادل رومانية أنيقة وجميلة للشاطئ، مناسبة للبنات من عمر 3-12 سنة، للاستخدام اليومي، الشاطئ، الحفلات، الربيع/الصيف x1 @ 7.94\r\n[I97k2f1pwvkg] 2 قطعة مجموعة ملابس علوية نصف كم مطبوعة بالفراشات وبنطلون جوغر بلون قطعي للفتيات الصغيرات للصيف x1 @ 6.00\r\n[I7mkavgqjnl96n] SHEIN مجموعة من قطعتين تتكون من قميص كامي مطبوع عليه حرف وشورت مطبوع عليه نجوم، بتصميم عصري ومناسب لفرقة K-POP، مناسب للصيف x1 @ 4.80\r\n[I5mjsocfeeyr9n] SHEIN مجموعة ملابس علوية وبنطلون بطبعة أرنب وفهد، ملابس علوية بأكمام قصيرة وياقة دائرية فضفاض وبنطلون ضيق، مناسبة للبنات الصغيرات للارتداء اليومي في الربيع والصيف، للسفر والتنسيق والمنزل والعطلات والخارج والمزرعة والاسترخاء، 2 قطعة/مجموعة x1 @ 5.73\r\n[I92c1mdqlw4w] صنادل خفيفة الوزن وقابلة للتنفس ذات موضة كاجوال مريحة للبنات ، صيفي x1 @ 8.53\r\n[I59ostur2zow] زوج من صنادل الأميرة ذات الكعب العالي والرجعية للبنات، أحذية شاطئ ذات نعل ناعم، صيفية x1 @ 7.88\r\n[I95dslicln9t] طقم ملابس علوية كامي بدون أكمام مزينة بالكشكشة + شورت مزين بطبعة زهرة عباد الشمس قطعتين x1 @ 5.86\r\n[I69aa1ib1rrx] زوج حذاء شاطئ فلات لبنات رضع ذهبي لامع، حزام مرصع بالراين ملون ، مصنوع من جلد البو المنسوج ، تصميم ذو فتحة للأصابع ومزين باللؤلؤ والفراشة ، صندل فاخر بتصميم إنزلاقي ، مناسب للبنات الرضع في اليومي ، الكاجوال ، الشاطئ ، الحفلات ، الصيف x1 @ 4.80\r\n[I2399l9rq848] فستان حفلة للفتاة الصغيرة من الدانتيل والتول المزخرف بأزهار ثلاثية الأبعاد وتصميم ملتصق على الكتف، فستان أنيق لحفلات عيد ميلاد الفتيات ، فستان سهرة أنيق لحفلات البيانو والعروض الأميرية x1 @ 23.87\r\n[I37nivvjr2rw] 4 قطع طقم سيدة شابة بسيط بنقشة قلب مكفوفة x1 @ 9.86\r\n[I841a2lt0p3n] أحذية أميرة ذات قاع ناعم وفيونكة جديدة للبنات، أنيقة وحلوة، مناسبة للربيع والخريف x1 @ 7.24\r\n[I73ou2hg3vzk] SHEIN رمضان بنت طفل بتفاصيل رفرف دنيم صديري & محبوك مضلع رومبير كامي x1 @ 10.64\r\n[I6tkucri72do] طقم جمبسوت قميص بنات صلبة مخطط 3قطع/مجموعة x1 @ 7.99\r\n[I059n7m1zxmw] زوج واحد من الصنادل المفتوحة الأنف المزينة بزهور أنيقة وجميلة للبنات الصغيرات، خفيفة الوزن ومنفذة للهواء، مناسبة للداخل والخارج والمناسبات x2 @ 8.20\r\n[I74diox0ixdi] مجموعة قميص وشورت مزخرفة بزهور ثلاثية الأبعاد عصرية للفتيات الشابات، صيفي x1 @ 7.81\r\n[I51an8lhkwy1] SHEIN قميص سباغيتي كامي مطرز بالدانتيل المثقوب ويحمل قوس بالأمام ، وبنطلون بتصميم الزنبقة لفتاة صغيرة x1 @ 8.38\r\n[I31xizdvzs21] SHEIN طقم قميص أكمام قصيرة وشورت فوق المراهقة مكون من 2 قطع x1 @ 9.65\r\n[I7342damj5fc] 2 قطعة مجموعة بلوزة مكشكشة + تنورة ذات خصر مرتفع برقبة مكشكشة، ناعمة ومريحة الملبس ومرحة، مناسبة للفتيات من عمر 4-7 سنوات للرحلات والسفر وحفلات الشاطئ في الربيع والصيف x3 @ 6.31\r\n[I54lvto3k10p] Cozy Pixies زوج من الصنادل المسطحة الجميلة للأطفال البنات، مزخرفة بفيونكة ملونة للأجازات والأعياد، مناسبة للربيع والصيف x1 @ 11.90 (by Admin) (by Admin)', NULL, '', NULL, NULL),
(2, 'MF61F925', 0, 6, 0, 'Turkey', 'https://veloxshoppingiq.com/uploads/7575.JPG', 'N/A', 1, 9000, 0.00, 0, 0, 0, 9000, 1.0000, 0.00, 0.00, 0, 1, NULL, 8007, 0, 'app', '2026-04-06 11:41:56', '', 0, 0, '', 'blue laverne bakhur x1 @ 9,000 د.ع', NULL, NULL, NULL, NULL),
(3, 'DHIVFXQC', 0, 1, 0, 'Turkey', 'https://veloxshoppingiq.com/uploads/7074.PNG', 'N/A', 1, 38, 0.00, 0, 0, 0, 38, 1.0000, 0.00, 0.00, 0, 1, NULL, 8008, 0, 'app', '2026-04-06 12:57:31', '', 0, 0, '', 'zara x1 @ 38 د.ع', NULL, NULL, NULL, NULL),
(4, '4244PBUW', 1, 3, 0, 'Turkey', 'https://api-shein.shein.com/h5/sharejump/appjump?link=lADQPIKgZn1_b&localcountry=KW&shc=2_lADQPIKgZn1&url_from=GM76129161245', 'N/A', 1, 826.14, 0.00, 0, 0, 0, 826.14, 1.0000, 0.00, 0.00, 0, 1, NULL, 8011, 0, 'app', '2026-04-06 15:49:58', '', 0, 0, '', '[I91pjd2fpcxh] اثنين من أكمام الثلج الفضفاضة عصرية ولطيفة مضادة لأشعة الشمس للقيادة وركوب الدراجاترمضان x1 @ 2.10\n[I274ttgq5t75] 1 زوج / 4 أزواج / 5 أزواج من الأكمام الحمائية من الأشعة فوق البنفسجية بتصميم مضغوط مناسب للجنسين للجولف والسلة والدراجات والصيد والقيادة والجري والتجديف والبستنة x2 @ 3.20\n[I446mui69lij] حماية ذراع الشمس 2 قطعة / مجموعة للربيع والصيف والخريف، حرير الجليد، مناسب للقيادة في الهواء الطلق والحماية من الأشعة فوق البنفسجية، الأكمام الكبيرة بالإضافة الى قفازات الحماية من الشمس x1 @ 2.13\n[I53q1zsv7wsq] Manfinity Campus Court قميص كاجوال بياقة طاقم وأكمام طويلة مع طباعة حرفية، خريف x1 @ 16.25\n[I03hnvotsl1t] Manfinity Homme قميص كاجوال بأكمام طويلة وأزرار أمامية مربعات، للارتداء اليومي، للخريف x1 @ 15.11\n[I1mkgbgli5co9e] Fractyr Fractyr قميص تي شيرت رجالي بطبعة شكل بسيطة عصرية، قصير الأكمام، ملائم للارتداء اليومي والشارع x1 @ 8.49\n[I2b69hkkj46z] On feet& in love أحذية نسائية أنيقة وعصرية ذات أصبع قدم مدبب وحزام مفتوح من الأمام، مناسبة للارتداء مع الفساتين والكعب والصنادل، صنادل ذات كعب عالي للصيف x1 @ 18.11\n[I037qam3yr2d] SHEIN EZwear تي شيرت كاجوال أسود طويل الأكمام مضبوط التفصيل، تصميم رقبة عميقة على شكل V مزين بالدانتيل، مناسب للخريف/الشتاء x1 @ 6.39\n[I83y5yitjhav] SHEIN EZwear بنطلون نسائي واسع الساق للاستخدام اليومي والعطلات، مناسب للصيف، مناسب للعطلات x1 @ 9.05\n[I0dbxyi6f0bv] 3 قطع/قطعة واحدة بطول 37 سم (14.57 بوصة) باللون الأسود والبني والرمادي والسلحفاة، شريط رأس بلاستيكي خفيف الوزن غير قابل للانزلاق، ملحقات شعر أنيقة وبسيطة متعددة الاستخدامات مناسبة للارتداء اليومي والكاجوال والحفلات والتنقل والشاطئ والعطلات وتصفيف الشعر وغسل الوجه والمكياج ومطابقة الملابس، شريط رأس، شريط شعر، إكسسوارات الرأس x1 @ 1.04\n[I630dajgfkqb] زوج من النظارات الشمسية المربعة المعدنية الأنيقة للسيدات، نظارات شمس أنيقة للشاطئ، اكسسوارات للشاطئ للسيدات، نظارات شمس للبسطاء للبلوزة والجينز والبنطلون الرياضي والهوديي والسترات والفساتين والقمصان ذات الأكمام الطويلة، ظلال أنيقة لخروجات العائلة والسفر والإجازات الصيفية على الشاطئ والأنشطة الخارجية x1 @ 3.20\n[I5bse95phau9] GDTME كتاب تلوين سيارة الانجراف الخيالية: تصميم بسيط جريء، رسومات سيارات جميلة وممتعة، مساحة تلوين مريحة، مناسب للطلاب والمراهقين، يخفف الضغط ويعزز الإبداع، هدية مثالية لعيد الميلاد وعيد الأب والعودة إلى المدرسة - 24 صفحة أحادية الجانب، يأتي مع 5 ملصقات عشوائية x1 @ 3.20\n[I277mznvh5to] صنادل كاجوال للبنات، وصول جديد أحذية شبشب مسطحة للأطفال الصغار والكبار، أحذية شاطئ للأطفال البنات x1 @ 4.79\n[I14shoeb5v6f] 4 قطع/عبوة جوارب باليه للأطفال البنات بنقشة جاكارد العشب، سراويل ضيقة رقيقة جدًا وقابلة للتنفس، مناسبة للبنات في الصيف x1 @ 5.48\n[I5covdnfxz4u] 48 صفحة كتاب تمارين تتبع الحروف الأبجدية للأطفال | ممارسة الحروف من A-Z، مناسب للمرحلة التمهيدية والروضة | كتاب ممارسة الكتابة المبكرة الممتع، يتضمن صفحات للرسم، وممارسة الكلمات السحرية، هدية رائعة وكتاب كتابة باللغة الإنجليزية عملي ومتين، مثالي لموسم العودة إلى المدرسة. x1 @ 2.17\n[I39b9c7476g9] زوج من صنادل بنات صغيرات الحجم لون أحمر وردي، صنادل رومانية خفيفة منقوشة بفيونكة كبيرة، حزام مطاطي، نعل مضاد للانزلاق، مناسبة لفتيات تتراوح أعمارهن من 3 إلى 15 عامًا للاستخدام اليومي والحفلات والسفر في الربيع والصيف 2025 x1 @ 7.19\n[I48haznntvy0] SHEIN Elladie kids فستان أنيق بلون سادة للفتيات الصغيرات. التصميم الأنيق للأكمام المرفرفة يضيف سحرًا جذابًا، والقصة على شكل حرف A تمنح سلاسة وكرم. الزخرفات الزهرية ثلاثية الأبعاد تُظهر الأناقة. مناسب لمناسبات متنوعة: للعب في الخارج يجذب الانتباه بسهولة؛ للاستخدام اليومي في المنزل مريح وحر؛ لحضور الحفلات مبهر وأنيق بنظرة. خيار أزياء مثالي للأميرات الصغيرات x1 @ 6.43\n[I37mt1mvogmc] Elladie kids مجموعة سترة وشورت نسيج ملمس أصفر للفتيات الصغيرات، تصميم أنيق، ملابس صيفية فريدة للفتيات في العطلات الصيفية x1 @ 7.19\n[I07mlpytjhwa] Elladie kids مجموعة قطعتين لفتاة صغيرة موديل صيفي جديد، بلوزة قطنية مطرزة بأكمام قصيرة وياقة مكسرة، بنطال قطني مستقيم الساق، ملابس عملية بطراز رجعي مناسبة للفتيات x1 @ 14.38\n[I7740r2ty2yc] SHEIN Genkimix Kids طقم فتاة شابة كاجوال مكون من 2 قطع، قميص كامسول مخطط وبنطلون. طقم كاجوال صيفي للأولاد والبنات مكون من 2 قطع.طقم ملابس صيفي للبنات الصغيرات مكون من 2 قطع. x1 @ 6.21\n[I42rjr8hy6o4] SHEIN Genkimix Kids 6 قطع ملابس علوية بياقة مستديرة للأولاد الصغار باللون الأبيض الأملس، قماش محبوك ناعم ومريح، مناسب للارتداء اليومي والرياضة والعطلات، يمكن ارتداؤه مع شورت رياضي أو جينز، مثالي للمدرسة والعطلات والأعياد والسفر والاسترخاء والاستجمام في الصيف x1 @ 11.72\n[I69r62u137qi] كتاب تلوين للبالغين مكون من 24 صفحة، بمقاس 7.9 * 7.9 بوصة، بتصميم كرتوني، مناسب للمراهقين والبالغين، رائع للحفلات والهدايا والاسترخاء، فن كرتوني، لوحات جذابة. هدية عيد الأم، العودة إلى المدرسة، K-Pop، لوازم مدرسية، كتب تلوين، قرطاسية، هدايا عيد الفصح، ديكور الغرفة، لوازم المكتب، هدايا، تفضيلات الحفلات، ألعاب، لوازم حفلة تخرج 2026 x1 @ 3.30\n[I53qadbndp02] بدلة سباحة قطعة واحدة للبنات، ذات طباعة توجيهية، مناسبة للبنات x1 @ 5.45\n[I0mm9yrzjub7yo] مجموعة بيجامة بطبعة خروف كرتوني لطيف بأكمام قصيرة وبنطلون طويل للفتيات الصغيرات، وردي ورمادي، 2 قطعة/طقم x1 @ 5.33\n[I23ok8tjp26c] SHEIN 5 قطع/عبوة ملابس داخلية من الحرير الخفيف بطبعات رسومات الفتاة جذابة مع فيونكة، مريحة ومناسبة كملابس خارجية x1 @ 9.05\n[I2mkdqlcuorl5t] سلسلة كتب الصور \"أنا مستعد\"، قصص النمو الهادئة للاستقلالية والمشاعر والصداقة والحياة المدرسية، قراءة جهرية داعمة لبناء الثقة والاستعداد، صفحات مصورة دافئة x1 @ 3.38\n[I1mkdqlcubksph] سلسلة كتب الصور \"أنا مستعد\"، قصص النمو الهادئة للاستقلالية والمشاعر والصداقة والحياة المدرسية، قراءة جهرية داعمة لبناء الثقة والاستعداد، صفحات مصورة دافئة x1 @ 3.38\n[I0mkdqlcuzrlqz] سلسلة كتب الصور \"أنا مستعد\"، قصص النمو الهادئة للاستقلالية والمشاعر والصداقة والحياة المدرسية، قراءة جهرية داعمة لبناء الثقة والاستعداد، صفحات مصورة دافئة x1 @ 3.38\n[I53407vfxk2k] FoBianJie رأس فرشاة المرحاض القابلة للاستبدال ذات رائحة المحيط الأزرق، ديكور حمام، ديكور الخريف x1 @ 4.87\n[I05bc8pd5cvb] SHEIN LMoss Kids مجموعة للفتيات الصغيرات x1 @ 6.19\n[I1clfmj1xd7m] LMoss Kids فستان كاجوال للفتاة الصغيرة بطبعة زهور صغيرة وكشكشة على الذيل x1 @ 6.70\n[I23ig5dffrth] SHEIN LMoss Kids مجموعة بيجامات للفتيات الصغيرات بطبعات كرتونية كاواييي، أرنب أزرق، خياطة، طراز راقص، طباعة زهور أومبير، طباعة فيونكة وردية، مناسبة للصيف والخريف والشتاء، لأجواء كاجوال وكمبوس ورياضية، للنزهات والخروجات والأنشطة المنزلية والمدرسية x1 @ 9.13\n[I19w6j2f6yn4] SHEIN بدلة سباحة للبنات، بدلة سباحة قطعة واحدة للبنات الصغيرات، بدلة سباحة قطعة واحدة كاجوال وأنيقة بطبعات أوراق باللون الوردي، مصنوعة من قماش محبوك محافظ بدون أكمام وشورت، مناسبة للسباحة والعطلات الصيفية والشاطئ وحمام السباحة وحفلات الصيف والأوقات الترفيهية، بدلة سباحة قطعة واحدة للأطفال باللون الوردي وبدلة سباحة طويلة للأطفال باللون الوردي والأزرق x1 @ 4.79\n[I7mk3t3mn4akpb] كتاب أوزبورن للرفع والكشف: لماذا يجب أن أقول آسف؟ كتاب معرفة علمي تعليمي مبكر للأطفال بأسئلة وإجابات x1 @ 5.49\n[I2df35g5gck6] BASUSARRI ملابس علوية كامسول مع تريم كشكش وبنطلون ساق واسعة، طقم أنيق للسيدات، بدلة صيفية كاجوال للفتيات x1 @ 6.13\n[I08lkasu3iis] 1/2 قطعة جوارب طفل صيفية رقيقة بيضاء، جوارب فاخرة منقطة بالراينستونز براقة رفيعة، جوارب عادية كلاسيكية مريحة وعصرية، مناسبة للحياة اليومية، العطلات، العودة إلى المدرسة x1 @ 3.46\n[I83mshl4gun1] SHEIN ChillGRL مجموعة بنطلون وتي شيرت كاجوال للبنات المراهقات، تي شيرت بياقة مستديرة وأكمام قصيرة مطرز بنقشة الفراشة، وبنطلون كارجو، طقم أزياء عصري للربيع/الصيف، قطعتان x1 @ 12.52\n[I6b2xvajgzvw] حقيبة تسوق صغيرة عصرية من جلد PU مقاوم للماء، بقفل معدني أحادي اللون بتصميم بسيط، مناسبة للتسوق والحمل، للنساء الشابات وطلاب الجامعة والمهنيين الشباب وموظفي المكاتب. مثالية للمكتب والمدرسة والعمل والأنشطة الخارجية والسفر والخروج. عرض خاص لرأس السنة الجديدة. x1 @ 8.92\n[I51rtkp02mf1] ملابس علوية نسائية صيفية مثيرة مع أكمام قصيرة وياقة عالية مرصعة بالراين ستاند، مناسبة للحفلات والعطلات الربيعية x1 @ 7.82\n[I88lgqq08wts] أداة إزالة الرؤوس السوداء - مستخرج الرؤوس السوداء الأرغونومي، منظف مسام الوجه الناعم، كشارة وجه سيليكونية للتنظيف العميق، كشارة وجه مقشرة للبشرة الجنسين، أداة العناية بالبشرة لإزالة الرؤوس السوداء من الأنف، ملحقات تنظيف المسام سهلة الاستخدام x1 @ 1.07\n[I07cela3hqv0] صنادل نسائية ذات كعب عالٍ رفيع بطرف مدبب باللون الأسود مع إبزيم معدني قابل للطي، صنادل بكعب ستيليتو جذاب، مجموعة ربيع/صيف جديدة 2025، كعب عالٍ باللون البني x1 @ 15.18\n[I07cela3bs3g] صنادل نسائية ذات كعب عالٍ رفيع بطرف مدبب باللون الأسود مع إبزيم معدني قابل للطي، صنادل بكعب ستيليتو جذاب، مجموعة ربيع/صيف جديدة 2025، كعب عالٍ باللون البني x1 @ 15.18\n[I29vix2alnyw] 1 قطعة لعبة دعائية، سكين بلاستيكي قابل للسحب، حيلة سحرية، دعابة، سكين مزيف، مضحك x1 @ 1.32\n[I2mjlhmztapdv7] 1/2/3/4 قطعة حزام نسائي ذو شكل حرف U بسيط للخصر الرفيع، تصميم راقي متعدد الاستخدامات للفساتين والمعاطف، مناسب للاستخدام اليومي والعمل، هدية x1 @ 3.79\n[I57r0qgcm5tx] بدلة نسائية سوداء ضيقة، بدلة جسم شفافة مطرزة بالدانتيل ذات ياقة عالية وأكمام طويلة باللون الأسود، طراز شارع جذاب وعملي، مناسبة للتصوير الفوتوغرافي في الشارع، الارتداء اليومي، عطلة الشاطئ، النادي الليلي، حفلات العزاب، المواعدة، عيد الحب، الكرنفال، مهرجانات الموسيقى، بدلة نسائية مطرزة بالدانتيل x1 @ 9.81\n[I5mkpfykg5fdb0] لعبة ضغط جبنة كبيرة واقعية، كرة توفو قابلة للضغط بتأخر الارتداد، كرة ضغط إبداعية للتخفيف من التوتر، ملمس ناعم ولزج، هدية رائعة لعيد الميلاد والمناسبات x1 @ 2.11\n[I3mjxz606fg18t] 1/2/3 قطعة من ألعاب الإجهاد القابلة للضغط: كرات خبز ملونة صغيرة للضغط عليها، أجهزة مضادة للإجهاد بطيئة الارتداد، كرات عجين خبز واقعية مزيفة، ألعاب حسية قابلة للتمدد للمكتب والاسترخاء المنزلي، هدية مثالية للعائلة والأصدقاء x1 @ 2.10\n[I123p3pvc78f] Weeklong فستان نسائي أنيق بأكمام واسعة وطباعة نمر من قماش لامع، مناسب للمكتب والحفلات والمناسبات الرسمية x1 @ 21.30\n[I7c5998j7x33] 3 طقم أقراط مشبك نحاسية مرصعة بالزركونيا بتصميم بسيط وأنيق، متعددة الاستخدامات للمواعدة والحفلات والارتداء اليومي، هدية عيد الميلاد للأصدقاء والأمهات x1 @ 2.00\n[I7mkdz0w2h5e4u] لعبة ضغط مالت كبيرة 2026 الجديدة، متوفرة بألوان متعددة، هدية مثالية - هدية عيد ميلاد - هدية للأولاد - هدية للبنات - هدية عيد الميلاد - لعبة مطاطية x1 @ 1.84\n[I9bemfw3kpwl] 16000 قطعة من الراين الجيلي الملون 40 لون، لزخرفة الأظافر، أحجار مسطحة الظهر بمقاس 3مم/4مم/5مم، مناسبة للصنع اليدوي، مجموعة لامعة، يمكن استخدامها للملابس والأحذية والأظافر والمكياج وتطعيم الألماس وغيرها x1 @ 8.02\n[I3dciqydde6w] Zivah بنطلون كتان بني مطوي مع جيوب سحاب وخصر مطاطي قابل للتعديل، مناسب للاستخدام اليومي والرسمي والحفلات والمناسبات والسفر والشاطئ والعطلات والحفلات الموسيقية وحفلات التخرج والزفاف وغيرها من المناسبات x1 @ 11.72\n[I23tipjwg0ha] 1 قطعة حزام أنيق وعصري من مواد سبيكة عالية الجودة للنساء، حزام أنيق بلون واحد مناسب للشباب والنساء متوسطات السن، يعزز الأنوثة، حزام رفيع مشبوك يدويًا على شكل حرف U، يتناسب مع البنطلونات/التنانير الكلاسيكية، مناسب للارتداء اليومي في المكتب والمدرسة والأنشطة اليومية والرياضة والسفر والشارع والملابس والمناسبات مثل عيد الهالوين x1 @ 3.73\n[I11oyyt534lp] Flirla تي شيرت شبابي للسيدات بياقة دائرية وأكمام قصيرة، طباعة أرقام وحروف بتصميم لطيف وعصري، بأسلوب ضبط قوام رشيق، طبعات جرافيك بالأعلى x1 @ 4.56\n[I2d4aymftrlq] صنادل نسائية ذات كعب رفيع عصرية وأنيقة، بتصميم فتحة للأصابع مزين بفيونكة، ذات لون أحادي وتصميم منصة، مناسبة للفساتين في المناسبات الرسمية أو غير الرسمية x1 @ 10.85\n[I12g8q78viaa] Dewbera بنطلون رياضي نسائي فضفاض ذو ساق مستقيمة مع جيوب، خصر مزين بشريط متباين، خصر مطاطي مرن عالي المطاطية، مناسب للارتداء اليومي العادي، الجري، اليوغا، الجيم، التنس، الجولف، خلال فصلي الخريف والشتاء x1 @ 11.98\n[I4mjjvydsutroz] Resyla تي شيرت نسائي ضيق بياقة مستديرة مطبوع بنمط نمر، مناسب للربيع والصيف، تصميم متعدد الاستخدامات x1 @ 5.31\n[I25vmevwnlyg] DAZY تي شيرت نسائي بأكمام قصيرة وياقة طاقم ضيق في الشكل وأساسي وعصري مناسب للصيف قطعة واحدة x1 @ 4.07\n[I81al2j3orou] DAZY تي شيرت كاجوال للنساء بياقة دائرية وأكمام قصيرة بلون واحد x1 @ 4.82\n[I215tzrckgi8] صنادل نسائية عصرية ذات كعب عالي رفيع مفتوحة من الأمام، مصنوعة من شبكة صيفية، تصميم بسيط وشامل للمناسبات الرسمية، أصابع القدم مدببة وأنيقة x1 @ 12.25\n[I4bakg70s8ev] SHEIN PETITE بنطلون كاجوال للنساء بخطوط جانبية سوداء مع خصر مطاطي، فضفاض وعملي x1 @ 10.00\n[I35qib2ccu0f] تي شيرت كاجوال للنساء بياقة مستديرة وأكمام قصيرة بطباعة ألوان متباينة x1 @ 4.57\n[I0803uxe9lmt] Joudiya بنطلون طويل أساسي بلون سادة للنساء، صيفي رمضان x1 @ 11.45\n[I08kqrona5a1] صنادل نسائية مقاس كبير ذات كعب عالي أبيض مربع الأصبع، صنادل كاجوال من الجلد سهلة الارتداء للشاطئ، أحذية صيفية عصرية للخارج x1 @ 9.69\n[I16kcufdwwe4] UREREM مجموعة جاكيت رقبة دائرية وبنطلون واسع الساق بتصميم عتيق، أسلوب مدينة كاجوال ومريح، قماش منسوج 170 جرام للصيف x1 @ 19.97\n[I74hbts0n5fg] SHUZIA احذية مفتوحة الأصابع للسيدات ذات كعب منحني شفاف، صنادل عصرية x1 @ 15.71\n[I5ml6gkad8dols] فستان ماكسي أنيق بأكمام بلا أكمام وخصر مفلفل بلون أحادي لربيع/صيف 2026، فستان ماكسي أنيق للنساء، ملابس شارع عصرية، فستان ربيعي، ملابس حفل موسيقي، ملابس عطلة للنساء، فستان لضيف الزفاف، ملابس عطلة للنساء، ملابس رأس السنة الجديدة للنساء، فستان حفلة، فستان كاجوال للنساء، فستان صيفي للنساء، ملابس عيد الحب للنساء x1 @ 15.71\n[I3mm2uroa239s0] SUMWON طقم بنطلون واسع الساق وقميص مطبوع بالأرجواني، ملابس كاجوال مريحة للبنات x1 @ 10.94\n[I0miznhhhbtgvm] SUMWON مجموعة كاجوال من بلوزة مطبوع عليها نص مكتوب وبنطلون واسع الساق مع أكمام قصيرة للفتيات، مناسبة للعطلات x1 @ 14.91\n[I1947szuhofa] SHEIN طقم قطعتين: توب كاجول بأكمام قصيرة مطبوع بنقشات كرتونية للفتيات، وبنطلون واسع، مناسب للصيف x1 @ 5.49\n[I1czthieqlik] زوج من صنادل البنات الوردية الحلوة ذات الحزامين القابلة للتعديل، من جلد اصطناعي ناعم، مسامي وغير انزلاقي، مفتوحة الأصابع بتصميم جميل مناسبة للصيف والنزهات والخروج مع الأصدقاء x1 @ 10.50\n[I63g5hjvyejk] SHEIN زي عادي للأطفال الصغار للعودة إلى المدرسة أو الإجازة، يشمل: - تيشرت بياقة مستديرة وأكمام قصيرة بطباعة أشجار النخيل - شورت قماش منسوج مطاطي الخصر مخطط مع جيوب مناسب لحفلات عيد الميلاد، الحفلات، العروض، الحفلات، المدرسة، السفر، الرياضة، الربيع والصيف مجموعة متناسقة للأولاد الصغار مكونة من قطعتين x1 @ 8.26\n[I65d3dlxdmuu] 6 قطع مجموعة بيجاما من قميص كم قصير وشورت بنقوش لطيفة للفتيات الصغيرات من سلسلة المحيط x1 @ 14.91\n[I373qbawrzwr] بنطلون أبيض للأولاد مع إبزيم في الخصر، مناسب للحفلات والعطلات والتجمعات x1 @ 5.33\n[I2mjs98zjixaqn] بنطلون أبيض للأولاد مع تصميم إبزيم الخصر، مناسب للحفلات والمهرجانات والتجمعات x1 @ 5.33\n[I236x2d1gvhl] PrepCrw مجموعة ملابس علوية أكمام قصيرة ذو ياقة مخطط أسود وأبيض وبنطلون أبيض لصبي صغير، أنيقة وعصرية للمدرسة والمناسبات الكاجوال والخروجات والمهرجانات في الربيع والصيف، 2 قطعة x1 @ 9.59\n[I779p0bv2ozf] SHEIN مجموعة كاجوال 2 قطعة لما الأم والابنة، تي شيرت بياقة دائرية وكتف منخفض وسراويل، طباعة حرفية، ملابس كاجوال مناسبة للارتداء اليومي والمدرسة في الربيع والخريف، عيد الحب، مُطابقة الأم والابنة، ومُطابقة الأخوات x1 @ 7.72\n[I07co2rleg9h] CUCCOO BIZCHIC أحذية سهلة الارتداء بكعب أسطواني، عملية وشاملة لعيد الميلاد x1 @ 15.71\n[I6cfgrylyszc] SHEIN مجموعة قميص وبنطلون مخطط صيفي عادي للأولاد المراهقين، عبوتان x1 @ 8.44\n[I24ngdm438g9] بلوزة بياقة مكسرة للنساء، لون أبيض أحادي بسيط للارتداء اليومي الكاجوال في الربيع x1 @ 9.59\n[I3iiwx0r1ioa] SHEIN 5 علب سروال داخلي مربعي لأولاد صغار، ملابس داخلية للأولاد من القطن، سراويل داخلية للأولاد الصغار x1 @ 8.89\n[I89awz4ktdvw] SHEIN 4 قطعة/مجموعة سراويل داخلية للأولاد البيضاء الأساسية الكاجوال المريحة والقطنية المنفذة للهواء x1 @ 6.92\n[I04k3k8d8pnd] قميص أبيض قصير الأكمام للنساء، متعدد الاستخدامات للارتداء اليومي، مناسب لجميع الفصول الصيفية x1 @ 8.26\n[I33wd30j7418] فستان أميرة للبنات الصغيرات من عمر 3 إلى 7 سنوات، طويل الأكمام مع شراشيب من الشبك، لحفلات عيد الميلاد في فصلي الخريف والربيع x1 @ 10.15\n[I89s3ae7mxqz] Vintaside Kids فستان شبكي مزهر للبنات، أنيق بطراز الريف، وجميل، متعدد الاستخدامات للربيع/الصيف x1 @ 11.19\n[I44cjf1kodj1] مجموعة من قطعتين: بلوزة كم قصير مطبوعة بحرف وشجرة النخيل ، وشورت مجموعة للأولاد x1 @ 7.19\n[I18hiym0j28g] أحذية شاطئ أطفال صيفية جديدة بطراز بسيط عتيق، صنادل بنات شاطئ، أحذية أولاد أنيقة طرية القاع للخارج، أطفال ورضع x1 @ 9.54\n[I53hrhbv8x88] Dazy Kids ملابس بنات جينز، عطلة خريفية x1 @ 20.24\n[I4323n32q7yn] SHEIN Glamorique Kids فستان بنات للبنات الصغيرات بأكمام مكسرة مطرزة وطبقة مزدوجة من الشبك، فستان تنورة خط A فساتين الحزب والإجازة الأميرية x1 @ 9.05\n[I3mjqxjrju3cl9] 6 قطع/مجموعة بيجامة قصيرة الأكمام وشورت مطبوعة برسومات الحفارة والتحكم في الألعاب للأولاد، بدلة منزلية خفيفة الوزن x1 @ 11.95\n[I784exciakve] 6 قطع/مجموعة بيجامات صيفية كرتونية للبنات، طقم قصير الأكمام وشورت، بيجامات خفيفة للفتيات الصغيرات، طباعة دب كرتوني وأرنب x1 @ 11.95\n[I1mjgueey9uywh] 6 قطع/مجموعة بيجامة قصيرة الأكمام مع طباعة ديناصور كرتوني ومتحكم ألعاب للأولاد، بدلة منزلية خفيفة الوزن x1 @ 11.95\n[I5anakzoi47h] Playful Pals مجموعة من قطعتين للأطفال الصغار: ملابس علوية كاجوال مريحة بطبعة جرافيك وياقة دائرية وشورت مخطط، مناسبة للعب في الخارج والارتداء اليومي في الربيع والصيف x1 @ 6.66\n[I2bmmxexg4rc] SHEIN طقم قميص كاجوال قصير الأكمام وسروال ضيق للأطفال الصغار مزين برسومات القطط والحيوانات الكرتونية الجميلة x1 @ 6.20\n[I972zy8254o3] SHEIN Explorewe تيشرت مطبوع برسم الدب مع إزار قياسي 2 قطعة، طقم ملابس كاجوال أنيق ومزخرف بطبعات زهور ملونة للفتيات x1 @ 5.98\n[I314gkqw49z7] EMERY ROSE مجموعة قميص وتنورة للنساء لون سادة للعطلات الاستجمامية، 2 قطعة x1 @ 14.91\n[I2mk5h5z00p6xp] Siren Gaze بدلة كاجوال للنساء تتكون من قميص ذو طيات وبنطلون، لونين سادة x1 @ 13.85\n[I09khq11l5f4] مجموعة مكونة من قطعتين من قمصان رياضية كاجوال للأولاد الصغار وبنطلونات بيضاء طويلة بياقات دائرية مخططة وبأسلوب ياباني وكوري فضفاض، مناسبة للأطفال للاستخدام اليومي، للمدرسة، للسفر، للرياضة، للربيع والصيف، وللمناسبات مثل أعياد الميلاد، الحفلات المسائية، الحفلات، الزفاف، المعمودية، حفلات العودة للمدرسة x1 @ 7.46\n[I64tiemq87a8] SHEIN مجموعة مكونة من قطعتين: بلوزة بسوست مع غطاء للرأس وشريط واسع مزخرف ، وشورت من قماش منسوج أسود بتصميم سهل ومريح للاستخدام اليومي للصبي الصغير x1 @ 10.65', NULL, NULL, NULL, NULL),
(5, '1JSPG38C', 1, 3, 0, 'Turkey', 'https://api-shein.shein.com/h5/sharejump/appjump?link=lAiTh6bIg63_b&localcountry=AE&shc=2_lAiTh6bIg63&url_from=GM76129161245', 'N/A', 1, 743.1, 0.00, 0, 0, 0, 743.1, 1.0000, 0.00, 0.00, 0, 1, NULL, 8012, 0, 'app', '2026-04-07 07:20:23', '', 0, 0, '', '[sk2409118240043092] فستان أنيق بأكمام طويلة مزود بياقة قميص للفتيات الناشئات، تصميم مكون من قطعتين، مناسب للارتداء اليومي والرسمي في فصول الربيع والخريف والشتاء x5 @ 14.11\n[sj2405072316170705] سوار مضفر بزخرفة تاج فاخر من الفولاذ المقاوم للصدأ للرجال قطعة واحدة، مناسب للاستخدام اليومي، هدية مثالية لأعياد ميلاد صديق صبي أو صديق x3 @ 3.99\n[sj2405072316170705] سوار مضفر بزخرفة تاج فاخر من الفولاذ المقاوم للصدأ للرجال قطعة واحدة، مناسب للاستخدام اليومي، هدية مثالية لأعياد ميلاد صديق صبي أو صديق x1 @ 3.99\n[sj25101569692082725] ساعة نسائية موضة، مزينة بفراشة، قرص دائري مرصع بالراين ستون، حركة كوارتز بسيطة، مناسبة للارتداء اليومي، هدية عيد ميلاد، حفلة، عطلة، خيار جودة x5 @ 3.01\n[sh2411293162152332] 6 قطع / مجموعة معدن خاصرة مشبك ألومنيوم مع دبابيس، ديكور ماس وفراشة حديث، اكسسوار خاصرة للمنزل، مناسب للنساء والفتيات لتضييق خصر البنطلون والزينة (4/6/1 قطعة) x1 @ 1.33\n[sc2302107081814412] حزام سلسلة مزين بالزهور والخرز الاصطناعي للحفلات والهالوين والصيف والمدرسة والخريف x1 @ 2.13\n[sc25042009959690966] 1 قطعة مشبك شعر نسائي جديد بتصميم فراشة كبيرة مطرزة بخرز وشبكة، تاج رأس حلو مناسب للتصوير، إكسسوارات شعر شتوية، مشبك شعر عادي لعيد الحب، هدية إكسسوارات عيد الحب، مشبك أنيق للشاطئ والعطلات الصيفية x8 @ 1.86\n[sj2408117888056750] طقم قلادة إينامل بتصميم فراشة بيضاء، قلادة خونرة عالية الجودة أنيقة وعصرية وبسيطة x1 @ 1.60\n[sb25042181865745850] 24 ملصق أظافر على شكل زهور، أظافر جل ثلاثية الأبعاد بشكل لوز، إنشاء أظافر زهرية زرقاء، تصميم ديكور اللؤلؤ، أظافر أكريليك فرنسية للضغط، مجموعة أظافر مزيفة مناسبة للارتداء لفترة طويلة، تشمل: 1 جل جيلي و 1 ملف أظافر، سهلة الارتداء، فن أظافر الزهور، مناسبة لأظافر الصيف، العمل اليومي، الحفلات، لوازم الأظافر x4 @ 1.60\n[sj2310141344608800] خاتم مفتوح قابل للتعديل بلؤلؤ صناعي للنساء، أسلوب حداثة الموضة x1 @ 1.07\n[rc2211221116151129] ROMWE حزام سلسلة مزخرف بفراشة x1 @ 2.93\n[sj25092189924929095] ساعة يد نسائية فاخرة صغيرة الحجم بعقارب مربعة من الفولاذ المقاوم للصدأ بطراز عتيق، ساعة كوارتز أنيقة وبسيطة مناسبة للارتداء اليومي والمناسبات x1 @ 5.59\n[sh260115204511034888041] دبوس وشاح من اللؤلؤ الاصطناعي، إكسسوار عملي يمكن تثبيته على الأوشحة والسترات والجواكت لمنع تلف الملابس، أنيق وعملي x1 @ 1.01\n[sh260115204511034888041] دبوس وشاح من اللؤلؤ الاصطناعي، إكسسوار عملي يمكن تثبيته على الأوشحة والسترات والجواكت لمنع تلف الملابس، أنيق وعملي x1 @ 1.01\n[sk25052272386256258] سوار أنيق مزين باللؤلؤ والراين للبنات قطعة واحدة x1 @ 1.60\n[sc25022065075427387] قلادة أنيقة وعصرية بتصميم على شكل حرف Y متعددة الطبقات، مناسبة للارتداء اليومي للنساء، هدايا مجوهرات للخطوبة، قلادات زفاف للارتداء في عيد الحب x1 @ 1.33\n[sz25061391808265551] Modelyn فستان حفلة أنيق مع أكمام متسعة، مزين بالراين ستون، قماش متنوع، مخصر عند الخصر x1 @ 19.44\n[sj25021744349195132] قطعة واحدة من أساور إصبع نسائية عصرية وبسيطة، سوار سلسلة بسيط، مناسب للارتداء اليومي للنساء، كذلك هدية رائعة للمناسبات (سلسلة مصنوعة يدويًا مقطعة حسب المقاس، عدد متغير من الخرز، حجم متغير من الراين) x1 @ 1.33\n[sj2204127444649805] 1 قطعة خاتم مفتوح من الزركونيا ذو صفين، مناسب للارتداء اليومي x1 @ 1.86\n[sj25013127734697359] زوج أقراط زهرية بسيطة من الاكريليك للنساء (ألوان البتلات عشوائية) x1 @ 2.40\n[sj25040149373828308] 1 سوار لسيدة بتصميم فريد من اللؤلؤ البروكات الحظ بشكل قلب، إكسسوار مجوهرات راقية x1 @ 1.60\n[sj2306262200097077] 1 مجوهرات زهرة سوار القفازات x1 @ 1.60\n[sj2406203796306351] طقم مكون من 4 قطع (قلادة، أقراط، خاتم، سوار) مرصع بالكريستال بتصميم التاج، اكسسوارات الزفاف / العروس للاحتفالات والأعياد والعروض الفنية، اكسسوارات الشعر (حجاب العروس)رمضان x1 @ 4.59\n[sz25031183298506046] Yasmyna جلابيات قفاطين فستان ماكسي تركي للنساء والعباءة العربية التقليدية x1 @ 19.44\n[sz25031183298532047] Yasmyna فستان ماكسي تركي للنساء والعباءة العربية التقليدية x1 @ 19.71\n[sz25031183298595441] Yasmyna جلابيات قفاطين فستان أنيق للنساء بياقة على شكل حرف V وأكمام طويلة مزين بنقشة من الترتر على شكل فراشة x1 @ 19.97\n[sb2408276428433304] 24 قطعة أظافر مزيفة مزينة بالراين ستون الذهبي ثلاثي الأبعاد غير متماثل ذات طراز عصري رجعي، تعزز مظهرك بأناقة وأناقة. مناسبة للفتيات والسيدات الأنيقات والأنيقات للاستخدام اليومي. ملصقات أظافر للضغط عليها، لوازم فن الأظافر x1 @ 1.86\n[sj25052605292672983] 3 قطع طقم مجوهرات قلادة + أقراط أنيقة للنساء، تصميم معدني مجوف أنيق بزهور وفراشات مع خرز اصطناعي، قلادة طويلة، إكسسوارات متعددة الاستخدامات x1 @ 2.66\n[sc251211203095091493559] مشبك شعر كبير بشكل فراشة وردية للنساء، إكسسوارات شعر أنيقة x1 @ 1.60\n[sj25051527452281883] سوار نسائي بتصميم هندسي ملون من الزركونيا، عصري وطازج للصيف قطعة واحدة x1 @ 1.86\n[sc2406154260820066] مشبك شعر فراشة مزين باللؤلؤ والراين كبير الحجم للشعر المضفر، باللون الوردي، مناسب للاستخدام اليومي والحفلات وعيد الحب، اكسسوارات شعر للنساء للاستخدام في الشاطئ والعطلات الصيفية x1 @ 1.61\n[sc2406154260804229] مشبك شعر كبير مزين بالخرز الاصطناعي والراين بشكل فراشة، أنيق وجذاب للكعكة، اكسسوار وردي مناسب للخروجات اليومية والمناسبات، عيد الحب، اكسسوارات الشعر، مشبك شعر، مشبك فك، مشبك شعر، مشبك فك، للملابس الصيفية والشتوية للنساء x1 @ 1.86\n[sw2106212716289831] Andkiss سوار من الخرز المرصع بزخرفة اللؤلؤ الاصطناعيرمضان x1 @ 1.33\n[sz251113250953263900] Al Najma رمضان فستان عربي أنيق بأكمام طويلة مطرز بطبعات زهرية على طوق الياقة، مصنوع من نسيج جاكار مُنسوج باللون الأخضر x1 @ 23.17\n[sb260228105241655498835] 30 قطعة من ملصقات أظافر أكريليك على شكل لب/قلب لون أحمر بشكل لوز متوسط الحجم، طقم أظافر صناعية ثلاثية الأبعاد بزخرفة فيونكة، مناسبة لصالونات الأظافر والفتيات والنساء للاستخدام اليومي والمناسبات والهدايا x1 @ 1.60\n[sb260224154610627879677] 24 ملصق أظافر جل زهري ثلاثي الأبعاد بشكل اللوز، تصميم فرنسي أبيض، مناسب لمجموعة أظافر أكريليك، يتضمن 1 جل جيلي و 1 ملف أظافر، مناسب للصيف، DIY للنساء والفتيات لاستخدام يومي، العمل، الدراسة والحفلات x1 @ 1.74\n[sj25030841616721321] مجموعة مجوهرات نسائية جديدة لصيف أسلوب الريف العطلة، بقلادة زهرة مينا زرقاء غير متماثلة ، أقراط زوج واحد ، خاتم واحد ، سوار واحد (باستثناء علبة الهدية) x1 @ 5.33\n[sj25030841616770555] مجموعة من قطعة عقد بشكل زهري متناسق وأقراط وخاتم وسوار، طقم مجوهرات نسائية (لا يشتمل على علبة هدايا) x1 @ 4.53\n[sj25030916268635832] طقم مجوهرات للنساء مكون من: 1 قلادة بتعليقة زهرة وردية متدرجة الطبقة غير متماثلة مصنوعة يدويًا، 1 زوج من الأقراط، 1 خاتم، 1 سوار، 1 أسورة (بدون علبة هدايا) x1 @ 5.06\n[sj2406081900015875] ساعة كوارتز أنيقة للنساء 1قطعة بسلسلة قابلة للتعديل ذات خرز ذهبي، علبة بلون الذهب الوردي، وقرص أم اللؤلؤ المنسوج، مناسبة للمناسبات الرسمية x1 @ 2.61\n[sj25040785207461466] ساعة سوار للنساء برؤية كريستال مقطوع ماس وخرزة كبيرة واحدة، ساعة كوارتز بسيطة x1 @ 3.20\n[sj2412111338133934] زوج أقراط حلقية على شكل C مزين بالخرز الصناعي ذو تصميم راقي فاخر مناسب للنساء في الأناقة الشخصية والأحداث والحفلاترمضان x1 @ 1.07\n[sj2310108441157563] خاتم مرصع بالزركونيا المكعبة والخرز الاصطناعي، هدية مجوهرات للنساء في عيد الزفاف والذكرى السنوية x1 @ 1.86\n[sk2408061256442033] SHEIN بنطلون جينز أزرق فينتاج مبطن حراريًا مع خصر غير متماثل فضفاض، للفتيات، مناسب للخريف والشتاء، أنيق للفتيات في x1 @ 12.25\n[sk2411131157577615] SHEIN بنطلون جينز لفتاة يافعة بيت Y2K كاجول متهالك أزرق قصمية فضفاض، بنطلون جينز كاجوال فضفاض للبنات للربيع والصيف للأيام العطلة x1 @ 13.05\n[sk2405128876605932] مجموعة قبعة شمسية للفتيات بطبعات زهور وحقيبة 2 قطعة، مناسبة للزي الربيعي / الصيفي الخاص بالعطلات، لبس اليومي، حماية من الأشعة فوق البنفسجية x1 @ 3.36\n[sk2405174517255599] قميص تي شيرت بدون أكمام بتصميم أشجار وشورت هاواي مرن الخصر قطعتان للأولاد x1 @ 6.26\n[sk25011828196044438] صنادل كعب عالي للبنات، أحذية بريق قوس للأطفال للمناسبات الرسمية والحفلات والعروض المسرحية x1 @ 18.38\n[sk2402250968009260] قبعة شمسية وحقيبة أطفال الأجزاء تحتوي على طبعة فراشة كرتونية، قبعة شاطئ قطنية لطيفة للأولاد والبنات في الحياة اليومية أو العطلات x1 @ 5.38\n[sk25061255161341531] SHEIN تي شيرت أنيق بأكمام قصيرة بطبعة ديناصور لصبي المراهقين، مجموعة مطبوعة بتصميم الديناصور مكونة من قطعتين مناسبة للصيف x1 @ 7.99\n[sk25040899886888958] SHEIN مجموعة قميص كاجوال ذو رقبة دائرية وشورت للأولاد المراهقين 2 قطعة، بتصميم بسيط، صيفي x1 @ 8.26\n[sk25051966060666471] SHEIN توب ملابس علوية آزرق وأصفر بطبعة ظل أشجار النخيل وألوان الغروب المناسب للشباب، مناسب للصيف والشاطئ والعطلات والأنشطة الخارجية x1 @ 4.53\n[sk2212295153386003] SHEIN مايوه طقم متكامل بطبعات استوائية واحدة للفتيات، مع معطف كيمونو. x1 @ 8.26\n[sk25031160720281563] SHEIN مجموعة ملابس علوية كاميسول مطرز ثلاثي الأبعاد وبقصة غير متماثلة مع بنطلون كاجوال طويل للفتيات في الصيف، قطعتين x1 @ 7.72\n[sk2402282354238549] SHEIN زي شاطئي لطفلة، ملابس علوية بلا أكمام مريح مطاطي مع بنطلون واسع الأرجل ، صيف / شتاء x1 @ 6.39\n[sk2406271937703572] 3 قطع طقم بنات مراهقات مكون من ملابس علوية كامي مطبوع عليه حرف بروكلين + ملابس علوية شبكية + شورت، طقم صيفي عصري للخارج، مناسب كهدية صيفية x1 @ 9.32\n[sk25051042369836514] SHEIN 2 قطعة / مجموعة طقم ملابس نسائية رياضي كاجوال، تشمل: تيشيرت جرافيك 56 مطبوع عليه شعار \"كل يوم مميز\" وأكمام ملونة متباينة، شورت دراجة متناسق، مناسب للصيف، الرياضة، اللياقة البدنية، التسوق والأنشطة الاجتماعية x1 @ 5.59\n[sk2307135121557554] حقيبة يد أنيقة مزينة بالجليتر وتقليد اللؤلؤ للحفلات المسائية x1 @ 6.66\n[sk2404155459473568] نظارات شمسية رائجة وعصرية للأطفال الذين تتراوح أعمارهم بين 4-10 سنوات، ذات إطار مربع كبير وإطارات \"Love\" عالية الجودة ومتعددة الاستخدامات ومناسبة للخروجات اليومية ولضروريات الارتداء x1 @ 5.06\n[sk25041529122089615] 1 قطعة من الإكسسوارات الزخرفية المتفكّكة بألوان كرتونية صلبة مصنوعة من السيليكون، مناسب للحقيبة اليدوية وحقيبة الشاطئ والاستخدام الخارجي وألعاب الشاطئ وأيضًا كهدية عيد ميلاد x1 @ 4.26\n[sk25041437494702210] مجموعة مشط مربع وزجاجة رذاذ 7 قطع، مشط بلاستيكي مضاد للكهرباء الساكنة بطباعة برج إيفل الكرتونية، مشط شعر محمول بنمط، زجاجة رذاذ ضغط عالي، مناسبة للمراهقين وأنواع الشعر العادية، مقبض ABS متين، تصميم مربع جميل، مجموعة أدوات تصفيف الشعر x1 @ 5.33\n[sk2407110448472245] فستان صيفي للبنت الصغيرة بطبعة زهرية وحواف مكرمشة مع أشرطة مربعة، تصميم منعش، ضروري الامتلاك x1 @ 6.39\n[sk251113925399692023] زوج من صنادل رياضية للأطفال اللون الخاكي، أحذية شاطئ للأطفال الصغار، أحذية صيفية عادية للمشي للرضع، نعال ناعمة وجميلة x1 @ 6.94\n[sk2312295939556658] SHEIN Elladie kids مجموعة من ملابس علوية بدون أكمام طباعة قلب بسيط أمامي وتنورة قصيرة للفتيات الصغيرات، 2 قطعة x1 @ 9.05\n[sk25031312090662626] SHEIN 3 طقم بدلة رياضية للبنات مطبوع بطبعة الكاموفلاج والقلوب والزهور والأشكال الهندسية الملونة x1 @ 10.39\n[sa2407101714440838] شبشب مفتوح الأصبع مريح، صنادل شاطئ خفيفة الوزن وقابلة للتنفس للبنات، مناسبة للأنشطة الخارجية x1 @ 7.90\n[sg2206216474420808] حقيبة ظهر أطفال ضد للماء تصميم رسوم كارتون أرنب ديكور x1 @ 11.19\n[sk2403123450010483] بدلة قصيرة لطيفة مطبوعة بنقش الزهور للفتاة الشابة بأكتاف عارية وردية بحاشية مزينة بالريش، مثالي لعطلة الصيف x1 @ 8.79\n[sa2409267491739117] زوج من أحذية الأطفال المسطحة الأنيقة، أحذية أطفال مسطحة جديدة، أحذية بنات مزينة بفيونكة x1 @ 10.10\n[sk260120185117633051374] SHEIN Genkimix Kids مجموعة قميص كامي مطرز ثلاثي الأبعاد وبتصميم غير متماثل مع بنطلون كاجوال للبنات في الصيف، 2 قطعة/مجموعة x1 @ 7.72\n[sk25030741719707252] بدلة سباحة مطبوعة بأنماط عشوائية لفتاة صغيرة x1 @ 9.05\n[sk25061964540010881] SHEIN طقم بنطال جينز وسترة بلا أكمام بنمط أنيق للفتيات، ملابس خريف/شتاء للأطفال، ملابس عودة للمدرسة وحفلات عودة للمنزل، طقم أنيق قطعتين x1 @ 16.51\n[sk251025169414225951] بدلة سباحة للبنات الصغيرات بكتف واحد وبدون أكمام مع فتحات جانبية وتنورة شبكية. هذه البدلة الأنيقة والكاجوال والأنيقة مثالية للسباحة والعطلات وبدلات السباحة الصيفية للبنات الصغيرات. x1 @ 6.13\n[sk2403069370548475] SHEIN طقم قميص بستراب شبكي بزخرفة وردية ثلاثية الأبعاد وتنورة بعقدة جميلة لفتاة صغيرة، صيفي بلون صلب 2 قطعة x1 @ 12.78\n[sk251216195669433811027] مجموعة قميص وبنطلون بأكمام قصيرة وياقة طاقم للفتيان المراهقين، بتصميم كاجوال بسيط وأنيق، بطبعات الديناصور والكامفلاج والرسومات اليدوية الجرافيتية، بقصة فضفاضة مريحة وأنيقة x1 @ 9.05\n[sk2202286810952502] SHEIN لباس علوي بدون أكمام بطبعة استوائية و تنورة بحافة متموجة لفتاة صغيرة x1 @ 6.13\n[sk2204014942274331] SHEIN لباس علوي علوي بشريط حروف وشورت دولفين لفتاة صغيرة x1 @ 5.86\n[sk2406211728171851] نظارات أطفال جميلة بزهور وأذنين دب، بطاقة عرض فقط، بدون شحن x1 @ 3.20\n[sk25032959135605059] 2 قطعة مجموعة ملابس علوية نصف كم مطبوعة بالفراشات وبنطلون جوغر بلون قطعي للفتيات الصغيرات للصيف x1 @ 6.13\n[sk260112155925490737407] SHEIN مجموعة من قطعتين تتكون من قميص كامي مطبوع عليه حرف وشورت مطبوع عليه نجوم، بتصميم عصري ومناسب لفرقة K-POP، مناسب للصيف x1 @ 4.79\n[sk251230222046467209763] SHEIN مجموعة ملابس علوية وبنطلون بطبعة أرنب وفهد، ملابس علوية بأكمام قصيرة وياقة دائرية فضفاض وبنطلون ضيق، مناسبة للبنات الصغيرات للارتداء اليومي في الربيع والصيف، للسفر والتنسيق والمنزل والعطلات والخارج والمزرعة والاسترخاء، 2 قطعة/مجموعة x1 @ 6.39\n[sk2408208014065615] صنادل خفيفة الوزن وقابلة للتنفس ذات موضة كاجوال مريحة للبنات ، صيفي x1 @ 8.52\n[sa251130021664662543] زوج من صنادل الأميرة ذات الكعب العالي والرجعية للبنات، أحذية شاطئ ذات نعل ناعم، صيفية x1 @ 7.91\n[sk2412278611868272] طقم ملابس علوية كامي بدون أكمام مزينة بالكشكشة + شورت مزين بطبعة زهرة عباد الشمس قطعتين x1 @ 5.86\n[sk25032919143233088] زوج حذاء شاطئ فلات لبنات رضع ذهبي لامع، حزام مرصع بالراين ملون ، مصنوع من جلد البو المنسوج ، تصميم ذو فتحة للأصابع ومزين باللؤلؤ والفراشة ، صندل فاخر بتصميم إنزلاقي ، مناسب للبنات الرضع في اليومي ، الكاجوال ، الشاطئ ، الحفلات ، الصيف x1 @ 5.18\n[sk2407155884572153] فستان حفلة للفتاة الصغيرة من الدانتيل والتول المزخرف بأزهار ثلاثية الأبعاد وتصميم ملتصق على الكتف، فستان أنيق لحفلات عيد ميلاد الفتيات ، فستان سهرة أنيق لحفلات البيانو والعروض الأميرية x1 @ 24.52\n[sk25040265292232260] 4 قطع طقم سيدة شابة بسيط بنقشة قلب مكفوفة x1 @ 9.85\n[sa251130095171487281] أحذية أميرة ذات قاع ناعم وفيونكة جديدة للبنات، أنيقة وحلوة، مناسبة للربيع والخريف x1 @ 7.24\n[sk2306194904906900] SHEIN بنت طفل بتفاصيل رفرف دنيم صديري & محبوك مضلع رومبير كامي x1 @ 11.45\n[sk2406175605030303] طقم جمبسوت قميص بنات صلبة مخطط 3قطع/مجموعة x1 @ 7.99\n[sa2406224852311107] زوج واحد من الصنادل المفتوحة الأنف المزينة بزهور أنيقة وجميلة للبنات الصغيرات، خفيفة الوزن ومنفذة للهواء، مناسبة للداخل والخارج والمناسبات x1 @ 8.20\n[sk2404126266434659] مجموعة قميص وشورت مزخرفة بزهور ثلاثية الأبعاد عصرية للفتيات الشابات، صيفي x1 @ 7.99\n[sk2112081731771277] SHEIN قميص سباغيتي كامي مطرز بالدانتيل المثقوب ويحمل قوس بالأمام ، وبنطلون بتصميم الزنبقة لفتاة صغيرة x1 @ 9.05\n[sk2211306672892913] SHEIN طقم قميص أكمام قصيرة وشورت فوق المراهقة مكون من 2 قطع x1 @ 10.65\n[sk2501037237695846] 2 قطعة مجموعة بلوزة مكشكشة + تنورة ذات خصر مرتفع برقبة مكشكشة، ناعمة ومريحة الملبس ومرحة، مناسبة للفتيات من عمر 4-7 سنوات للرحلات والسفر وحفلات الشاطئ في الربيع والصيف x1 @ 6.30\n[sa2411244211272119] Cozy Pixies زوج من الصنادل المسطحة الجميلة للأطفال البنات، مزخرفة بفيونكة ملونة للأجازات والأعياد، مناسبة للربيع والصيف x1 @ 12.52', NULL, NULL, NULL, NULL),
(6, 'GAS30OTW', 0, 3, 0, 'Turkey', 'https://veloxshoppingiq.com/uploads/7575.JPG', 'N/A', 1, 9000, 0.00, 0, 0, 0, 9000, 1.0000, 0.00, 0.00, 0, 1, NULL, 8013, 0, 'app', '2026-04-07 08:04:44', '', 0, 0, '', 'blue laverne bakhur x1 @ 9,000 د.ع', NULL, NULL, NULL, NULL),
(7, '6KILSNAS', 0, 3, 0, 'Turkey', 'https://veloxshoppingiq.com/uploads/7575.JPG', 'N/A', 1, 9000, 0.00, 0, 0, 0, 9000, 1.0000, 0.00, 0.00, 0, 1, NULL, 8014, 0, 'app', '2026-04-09 22:09:51', '', 0, 0, '', 'blue laverne bakhur x1 @ 9,000 د.ع', NULL, NULL, NULL, NULL),
(8, 'ZSZ8WE10', 1, 3, 0, 'Turkey', 'https://api-shein.shein.com/h5/sharejump/appjump?link=l0Wj8WJUKKF_b&localcountry=KW&shc=2_l0Wj8WJUKKF&url_from=GM76129161245', 'N/A', 1, 26.29, 0.00, 0, 0, 0, 26.29, 1.0000, 0.00, 0.00, 0, 1, NULL, 8015, 0, 'app', '2026-04-09 22:11:00', '', 0, 0, '', '[sb2309087392508592] Asiteo 1 قطعة غراء شفاف للرموش الصناعية سعة 5 مل، غراء رموش مقاوم للماء، أداة مكياج سريعة الجفاف وطويلة الأمد x2 @ 1.60\n[sb25102201401606598] Pudaier كريم الشفاه المقاوم للماء - لمعة الشفاه غير اللزجة والتي لا تترك بقع، ثابتة في الكوب، طويلة الأمد، سهلة الاستخدام، ذات نهاية مطفأة x1 @ 2.40\n[s180925520479767] SHEIN Clasi قميص سيدات موحد اللون كاجوال، بأكمام طويلة x2 @ 8.52\n[sb25053053433449333] مكوّر رموش ذهبي وردي، مقبض جيلي شفاف وردي، مكوّر رموش يدوي محمول عالي الجودة، يخلق رموش ملتوية في أي وقت، أداة تجميل، مناسب للاستخدام المنزلي والتجاري، مناسب أيضًا للتوزيع، صديق للسفر، أداة مكياج بأسعار معقولة، هدية للنساء، هدية لها، هدية عيد الحب، هدايا، سفر، أشياء رخيصة، ضروريات السفر x1 @ 1.60\n[sb25021566982844177] 5 أزواج من رموش عين القطة والثعلب الشفافة من NAIJEMA، طبيعية المظهر، ناعمة ومجعدة، إطالة الرموش، بطراز كرتوني، رموش دراماتيكية، مناسبة للمكياج اليومي، شرائط رموش، رموش مزيفة x1 @ 2.05', NULL, NULL, NULL, NULL);
INSERT INTO `items` (`id`, `serial`, `has_sub_items`, `customer_id`, `websiteid`, `country`, `link`, `size`, `qty`, `itemprice`, `cargo`, `shippingprice`, `tax`, `commission`, `totalprice`, `rate`, `total_dinar`, `in_iraq_delivery`, `converttodinar`, `status`, `box_id`, `image`, `adminid`, `added_by`, `created_at`, `date`, `currency_id`, `paymentstatus`, `color`, `note`, `brand_id`, `pcountry`, `cost_price`, `warehouse_location`) VALUES
(9, 'O4T2U3OP', 0, 1, 0, 'Turkey', 'https://veloxshoppingiq.com/uploads/7573.JPG', 'N/A', 2, 180, 0.00, 0, 0, 0, 360, 1.0000, 0.00, 0.00, 0, 1, NULL, 8016, 0, 'app', '2026-04-12 06:40:02', '', 0, 0, '', 'King Tobacco x2 @ 90 د.ع', NULL, NULL, NULL, NULL),
(10, 'X4L6UP9X', 0, 3, 0, 'Turkey', 'http://ciderhere.com/g63702', 'N/A', 1, 24.9, 0.00, 0, 0, 0, 24.9, 1.0000, 0.00, 0.00, 0, 1, NULL, 8017, 0, 'app', '2026-04-13 22:00:39', '', 0, 0, '', 'Knit Fabric Round Neckline Floral Contrasting Binding Cut Out Knotted Short Sleeve Top For School Holiday x1', NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `itemstatusupdate`
--

CREATE TABLE `itemstatusupdate` (
  `id` int(11) NOT NULL,
  `itemid` int(11) NOT NULL,
  `oldstatus` int(11) DEFAULT 0,
  `newstatus` int(11) NOT NULL,
  `notes` text DEFAULT NULL,
  `changed_by` varchar(50) DEFAULT 'admin',
  `date` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `itemstatusupdate`
--

INSERT INTO `itemstatusupdate` (`id`, `itemid`, `oldstatus`, `newstatus`, `notes`, `changed_by`, `date`) VALUES
(1, 1, 0, 1, 'Item created via API', 'admin', '2026-03-30 23:14:23'),
(2, 2, 0, 1, 'Item created via API', 'admin', '2026-04-06 11:41:56'),
(3, 3, 0, 1, 'Item created via API', 'admin', '2026-04-06 12:57:31'),
(4, 1, 1, 2, 'Status changed via edit form', 'admin', '2026-04-06 14:57:26'),
(5, 4, 0, 1, 'Item created via API', 'admin', '2026-04-06 15:49:58'),
(6, 5, 0, 1, 'Item created via API', 'admin', '2026-04-07 07:20:23'),
(7, 6, 0, 1, 'Item created via API', 'admin', '2026-04-07 08:04:44'),
(8, 7, 0, 1, 'Item created via API', 'admin', '2026-04-09 22:09:51'),
(9, 8, 0, 1, 'Item created via API', 'admin', '2026-04-09 22:11:00'),
(10, 1, 2, 3, 'Customer accepted via API - Enhanced validation passed', 'admin', '2026-04-09 22:14:22'),
(11, 9, 0, 1, 'Item created via API', 'admin', '2026-04-12 06:40:02'),
(12, 10, 0, 1, 'Item created via API', 'admin', '2026-04-13 22:00:39');

-- --------------------------------------------------------

--
-- Table structure for table `item_details`
--

CREATE TABLE `item_details` (
  `id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL COMMENT 'Foreign key to items table',
  `item_code` varchar(255) DEFAULT NULL COMMENT 'User-entered item code/name',
  `serial` varchar(255) DEFAULT NULL COMMENT 'Product serial/SKU (e.g., goods_sn from SHEIN)',
  `image` text DEFAULT NULL COMMENT 'Product image URL',
  `qty` int(11) DEFAULT 1,
  `price` decimal(10,2) DEFAULT 0.00,
  `subtotal` decimal(10,2) GENERATED ALWAYS AS (`qty` * `price`) STORED COMMENT 'Auto-calculated: qty * price',
  `status` enum('pending','done','lost','damaged') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `size` varchar(100) DEFAULT NULL COMMENT 'Item size (e.g. M, L, One Size)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `item_details`
--

INSERT INTO `item_details` (`id`, `item_id`, `item_code`, `serial`, `image`, `qty`, `price`, `status`, `created_at`, `size`) VALUES
(195, 1, 'فستان أنيق بأكمام طويلة مزود بياقة قميص للفتيات الناشئات، تصميم مكون من قطعتين، مناسب للارتداء اليومي والرسمي في فصول الربيع والخريف والشتاء', 'I12urop9zuom', 'https://img.ltwebstatic.com/v4/j/pi/2025/06/27/fd/1750989601d6ff26456210ae7a6e972893bb66dda4.jpg', 1, 14.12, 'pending', '2026-04-06 15:05:13', ''),
(196, 1, 'سوار مضفر بزخرفة تاج فاخر من الفولاذ المقاوم للصدأ للرجال قطعة واحدة، مناسب للاستخدام اليومي، هدية مثالية لأعياد ميلاد صديق صبي أو صديق', 'I0c8gdc2xc78', 'https://img.ltwebstatic.com/images3_spmp/2024/05/17/3d/1715949678db86b60ea800ab22a9272c27a3a0a670_square.png', 1, 3.81, 'pending', '2026-04-06 15:05:13', ''),
(197, 1, 'سوار مضفر بزخرفة تاج فاخر من الفولاذ المقاوم للصدأ للرجال قطعة واحدة، مناسب للاستخدام اليومي، هدية مثالية لأعياد ميلاد صديق صبي أو صديق', 'I0c8gdc8u44t', 'https://img.ltwebstatic.com/images3_spmp/2024/05/17/3d/1715949678db86b60ea800ab22a9272c27a3a0a670_square.png', 1, 3.81, 'pending', '2026-04-06 15:05:13', ''),
(198, 1, 'ساعة نسائية موضة، مزينة بفراشة، قرص دائري مرصع بالراين ستون، حركة كوارتز بسيطة، مناسبة للارتداء اليومي، هدية عيد ميلاد، حفلة، عطلة، خيار جودة', 'I7mmenbyc3ytx1', 'https://img.ltwebstatic.com/v4/j/spmp/2026/03/06/b7/1772786279710855bc3314e70262aea2cde30e8e68.jpg', 1, 2.74, 'pending', '2026-04-06 15:05:13', ''),
(199, 1, '6 قطع / مجموعة معدن خاصرة مشبك ألومنيوم مع دبابيس، ديكور ماس وفراشة حديث، اكسسوار خاصرة للمنزل، مناسب للنساء والفتيات لتضييق خصر البنطلون والزينة (4/6/1 قطعة)', 'I64pz9v9b494', 'https://img.ltwebstatic.com/images3_spmp/2024/11/29/b4/17328639620323304fbfbc8304dc8196b870a3c7ea.jpg', 1, 1.33, 'pending', '2026-04-06 15:05:13', ''),
(200, 1, 'حزام سلسلة مزين بالزهور والخرز الاصطناعي للحفلات والهالوين والصيف والمدرسة والخريف', 'I53bdlxn5jlh', 'https://img.ltwebstatic.com/images3_pi/2023/02/14/1676372848d1f813766ab84286551890dcda50f8c8.jpg', 1, 2.13, 'pending', '2026-04-06 15:05:13', ''),
(201, 1, '1 قطعة مشبك شعر نسائي جديد بتصميم فراشة كبيرة مطرزة بخرز وشبكة، تاج رأس حلو مناسب للتصوير، إكسسوارات شعر شتوية، مشبك شعر عادي لعيد الحب، هدية إكسسوارات عيد الحب، مشبك أنيق للشاطئ والعطلات الصيفية', 'I6503e9r4ep8', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/25/4b/17640413726d37a9a536265e0ae10e55cdd5002378.jpg', 1, 1.86, 'pending', '2026-04-06 15:05:13', ''),
(202, 1, 'طقم قلادة إينامل بتصميم فراشة بيضاء، قلادة خونرة عالية الجودة أنيقة وعصرية وبسيطة', 'I724hrkj8l3t', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/13/df/1749791439600d8a1b995f186aac2edc8f3858074a.jpg', 1, 1.60, 'pending', '2026-04-06 15:05:13', ''),
(203, 1, '24 ملصق أظافر على شكل زهور، أظافر جل ثلاثية الأبعاد بشكل لوز، إنشاء أظافر زهرية زرقاء، تصميم ديكور اللؤلؤ، أظافر أكريليك فرنسية للضغط، مجموعة أظافر مزيفة مناسبة للارتداء لفترة طويلة، تشمل: 1 جل جيلي و 1 ملف أظافر، سهلة الارتداء، فن أظافر الزهور، مناسبة لأ', 'I59h2r1o1f3i', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/14/b4/1749883788a6cce847ae5cf386a5cf34c5a8446a1e.jpg', 1, 1.51, 'pending', '2026-04-06 15:05:13', ''),
(204, 1, 'خاتم مفتوح قابل للتعديل بلؤلؤ صناعي للنساء، أسلوب حداثة الموضة', 'I97r6wofuyv0', 'https://img.ltwebstatic.com/images3_spmp/2024/01/04/b1/17043380676f5530826b72e081e6f40524557804f4.jpg', 1, 1.03, 'pending', '2026-04-06 15:05:13', ''),
(205, 1, 'ROMWE حزام سلسلة مزخرف بفراشة', 'I05zcovvesr4', 'https://img.ltwebstatic.com/images3_pi/2022/12/07/16703790559487bffaf42d81abf17371f7d9b8f9f4.jpg', 1, 2.93, 'pending', '2026-04-06 15:05:13', ''),
(206, 1, 'ساعة يد نسائية فاخرة صغيرة الحجم بعقارب مربعة من الفولاذ المقاوم للصدأ بطراز عتيق، ساعة كوارتز أنيقة وبسيطة مناسبة للارتداء اليومي والمناسبات', 'I3ml7pzefahif6', 'https://img.ltwebstatic.com/v4/j/spmp/2026/02/04/28/17701902976840e25cfc552b6616946be784d107d3.jpg', 1, 4.94, 'pending', '2026-04-06 15:05:13', ''),
(207, 1, 'دبوس وشاح من اللؤلؤ الاصطناعي، إكسسوار عملي يمكن تثبيته على الأوشحة والسترات والجواكت لمنع تلف الملابس، أنيق وعملي', 'I5mkfgerwyw7uy', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/15/16/176848164565da1fc3f4f33fa81983f7762bbd8e4e_square.jpg', 1, 1.07, 'pending', '2026-04-06 15:05:13', ''),
(208, 1, 'دبوس وشاح من اللؤلؤ الاصطناعي، إكسسوار عملي يمكن تثبيته على الأوشحة والسترات والجواكت لمنع تلف الملابس، أنيق وعملي', 'I8mkfgerx56xfy', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/15/16/176848164565da1fc3f4f33fa81983f7762bbd8e4e_square.jpg', 1, 1.07, 'pending', '2026-04-06 15:05:13', ''),
(209, 1, 'سوار أنيق مزين باللؤلؤ والراين للبنات قطعة واحدة', 'I02i1jye4lhr', 'https://img.ltwebstatic.com/v4/j/spmp/2025/08/11/65/1754896040f35def61a0c07386f2eb27b346fcad42.jpg', 1, 1.26, 'pending', '2026-04-06 15:05:13', ''),
(210, 1, 'قلادة أنيقة وعصرية بتصميم على شكل حرف Y متعددة الطبقات، مناسبة للارتداء اليومي للنساء، هدايا مجوهرات للخطوبة، قلادات زفاف للارتداء في عيد الحب', 'I56s1tq0rr8n', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/01/63/1746068187bf25f2fbd0a71319b1a9006907c67a51.jpg', 1, 1.26, 'pending', '2026-04-06 15:05:13', ''),
(211, 1, 'Modelyn فستان حفلة أنيق مع أكمام متسعة، مزين بالراين ستون، قماش متنوع، مخصر عند الخصر', 'I0n2ts3b3xb', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/06/2f/1772763332279a0e0c6c0a4a0601384fb19676c8be.jpg', 1, 19.45, 'pending', '2026-04-06 15:05:13', ''),
(212, 1, 'قطعة واحدة من أساور إصبع نسائية عصرية وبسيطة، سوار سلسلة بسيط، مناسب للارتداء اليومي للنساء، كذلك هدية رائعة للمناسبات (سلسلة مصنوعة يدويًا مقطعة حسب المقاس، عدد متغير من الخرز، حجم متغير من الراين)', 'I12x7hpkibuh', 'https://img.ltwebstatic.com/images3_spmp/2025/02/17/70/1739754577cd2e941ac7216a7d7c1f8941bc3e2b26.jpg', 1, 1.31, 'pending', '2026-04-06 15:05:13', ''),
(213, 1, '1 قطعة خاتم مفتوح من الزركونيا ذو صفين، مناسب للارتداء اليومي', 'I98yyrwtfc6j', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/04/9d/17569744076102e9324802fe1d30b5241b423fe920.jpg', 1, 1.82, 'pending', '2026-04-06 15:05:13', ''),
(214, 1, 'زوج أقراط زهرية بسيطة من الاكريليك للنساء (ألوان البتلات عشوائية)', 'I92ixs9iurn6', 'https://img.ltwebstatic.com/images3_spmp/2025/01/31/22/17383052683a96c9baf1c0744f08411e1c8c7b9ca4.jpg', 1, 2.40, 'pending', '2026-04-06 15:05:13', ''),
(215, 1, '1 سوار لسيدة بتصميم فريد من اللؤلؤ البروكات الحظ بشكل قلب، إكسسوار مجوهرات راقية', 'I47mlqttm2bb', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/01/c5/1743490025696e39bdb61ccde8c1443a7ca30684d0.jpg', 1, 1.48, 'pending', '2026-04-06 15:05:13', ''),
(216, 1, '1 مجوهرات زهرة سوار القفازات', 'I83umihndm0s', 'https://img.ltwebstatic.com/images3_spmp/2023/06/26/1687757754d05bc0f83e8deb1b96ca770bbc1e1155.jpg', 1, 1.60, 'pending', '2026-04-06 15:05:13', ''),
(217, 1, 'طقم مكون من 4 قطع (قلادة، أقراط، خاتم، سوار) مرصع بالكريستال بتصميم التاج، اكسسوارات الزفاف / العروس للاحتفالات والأعياد والعروض الفنية، اكسسوارات الشعر (حجاب العروس)رمضان', 'I8zx4szjs1qf', 'https://img.ltwebstatic.com/images3_spmp/2024/06/20/d5/1718892733c36d19e80a35d0a0f1b1d2d2eb53d68b.jpg', 1, 4.49, 'pending', '2026-04-06 15:05:13', ''),
(218, 1, 'Yasmyna جلابيات قفاطين فستان ماكسي تركي للنساء والعباءة العربية التقليدية', 'I0zgyrwefitc', 'https://img.ltwebstatic.com/v4/j/pi/2025/08/20/dc/17556691777d147f67a331a0f607331329edd57ecc.jpg', 1, 19.18, 'pending', '2026-04-06 15:05:13', ''),
(219, 1, 'Yasmyna فستان ماكسي تركي للنساء والعباءة العربية التقليدية', 'I8czjoqyoyzy', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/11/85/17654254269bed9f0539b614cd6fee6d11c5539b4c.jpg', 1, 19.71, 'pending', '2026-04-06 15:05:13', ''),
(220, 1, 'Yasmyna جلابيات قفاطين فستان أنيق للنساء بياقة على شكل حرف V وأكمام طويلة مزين بنقشة من الترتر على شكل فراشة', 'I4bbfso9lsuu', 'https://img.ltwebstatic.com/v4/j/pi/2025/10/27/ef/176156083408668f828e6d3c557359065fce969bd1.jpg', 1, 19.06, 'pending', '2026-04-06 15:05:13', ''),
(221, 1, '24 قطعة أظافر مزيفة مزينة بالراين ستون الذهبي ثلاثي الأبعاد غير متماثل ذات طراز عصري رجعي، تعزز مظهرك بأناقة وأناقة. مناسبة للفتيات والسيدات الأنيقات والأنيقات للاستخدام اليومي. ملصقات أظافر للضغط عليها، لوازم فن الأظافر', 'I82yevr7bz2o', 'https://img.ltwebstatic.com/images3_spmp/2024/09/11/f2/1726051650465d0fe3a52764dfe4aef0766bb9e9ae.jpg', 1, 1.80, 'pending', '2026-04-06 15:05:13', ''),
(222, 1, '3 قطع طقم مجوهرات قلادة + أقراط أنيقة للنساء، تصميم معدني مجوف أنيق بزهور وفراشات مع خرز اصطناعي، قلادة طويلة، إكسسوارات متعددة الاستخدامات', 'I490t18wtaco', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/26/a8/17482315162d88e8cfe25d34873158d987d01630f2.jpg', 1, 2.66, 'pending', '2026-04-06 15:05:13', ''),
(223, 1, 'مشبك شعر كبير بشكل فراشة وردية للنساء، إكسسوارات شعر أنيقة', 'I9mj1f4m15p65v', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/11/8c/17654562686e638f0232b7e55cab9c4c71677558f4.jpg', 1, 1.12, 'pending', '2026-04-06 15:05:13', ''),
(224, 1, 'سوار نسائي بتصميم هندسي ملون من الزركونيا، عصري وطازج للصيف قطعة واحدة', 'I3251b21cxok', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/11/5f/175755743544ded686f657aa1174f71ff4661170a6.jpg', 1, 1.86, 'pending', '2026-04-06 15:05:13', ''),
(225, 1, 'مشبك شعر فراشة مزين باللؤلؤ والراين كبير الحجم للشعر المضفر، باللون الوردي، مناسب للاستخدام اليومي والحفلات وعيد الحب، اكسسوارات شعر للنساء للاستخدام في الشاطئ والعطلات الصيفية', 'I3vn2i9c83xx', 'https://img.ltwebstatic.com/images3_spmp/2024/06/15/c4/171845741186ea34fc5a17efb79f8c8fc7c2b72105.jpg', 1, 1.86, 'pending', '2026-04-06 15:05:13', ''),
(226, 1, 'مشبك شعر كبير مزين بالخرز الاصطناعي والراين بشكل فراشة، أنيق وجذاب للكعكة، اكسسوار وردي مناسب للخروجات اليومية والمناسبات، عيد الحب، اكسسوارات الشعر، مشبك شعر، مشبك فك، مشبك شعر، مشبك فك، للملابس الصيفية والشتوية للنساء', 'I53wfwq2ex6x', 'https://img.ltwebstatic.com/images3_spmp/2024/10/25/36/1729864410ac429f31ba7cf6ecc35ca937b944baa0.jpg', 1, 1.86, 'pending', '2026-04-06 15:05:13', ''),
(227, 1, 'Andkiss سوار من الخرز المرصع بزخرفة اللؤلؤ الاصطناعيرمضان', 'I84w2leyjge1', 'https://img.ltwebstatic.com/images3_pi/2022/10/10/1665369418c45d5e1cedac41e6cdfa1e6c3fc7c9e8.jpg', 1, 1.31, 'pending', '2026-04-06 15:05:13', ''),
(228, 1, 'Al Najma رمضان فستان عربي أنيق بأكمام طويلة مطرز بطبعات زهرية على طوق الياقة، مصنوع من نسيج جاكار مُنسوج باللون الأخضر', 'I29actvrm0rf', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/13/2d/17682927724395cd6c383ec717d14a08e015021a1c.jpg', 1, 22.10, 'pending', '2026-04-06 15:05:13', ''),
(229, 1, '30 قطعة من ملصقات أظافر أكريليك على شكل لب/قلب لون أحمر بشكل لوز متوسط الحجم، طقم أظافر صناعية ثلاثية الأبعاد بزخرفة فيونكة، مناسبة لصالونات الأظافر والفتيات والنساء للاستخدام اليومي والمناسبات والهدايا', 'I1mm5qb1xosqd4', 'https://img.ltwebstatic.com/v4/j/spmp/2026/02/28/ab/1772247189f629dbf8cd3a6e53fb3f726e5c508a79.jpg', 1, 1.60, 'pending', '2026-04-06 15:05:13', ''),
(230, 1, '24 ملصق أظافر جل زهري ثلاثي الأبعاد بشكل اللوز، تصميم فرنسي أبيض، مناسب لمجموعة أظافر أكريليك، يتضمن 1 جل جيلي و 1 ملف أظافر، مناسب للصيف، DIY للنساء والفتيات لاستخدام يومي، العمل، الدراسة والحفلات', 'I7mm0b0jl1l09v', 'https://img.ltwebstatic.com/v4/j/spmp/2026/02/24/31/1771919224073bc9feecc0d5abbb98e8c100d2c1d2.jpg', 1, 1.49, 'pending', '2026-04-06 15:05:13', ''),
(231, 1, 'مجموعة مجوهرات نسائية جديدة لصيف أسلوب الريف العطلة، بقلادة زهرة مينا زرقاء غير متماثلة ، أقراط زوج واحد ، خاتم واحد ، سوار واحد (باستثناء علبة الهدية)', 'I475ojwpcxcl', 'https://img.ltwebstatic.com/images3_spmp/2025/03/09/ca/1741484333c9200890c21d55e31d80c544fed4492b.jpg', 1, 4.93, 'pending', '2026-04-06 15:05:13', ''),
(232, 1, 'مجموعة من قطعة عقد بشكل زهري متناسق وأقراط وخاتم وسوار، طقم مجوهرات نسائية (لا يشتمل على علبة هدايا)', 'I475ojwobbu5', 'https://img.ltwebstatic.com/images3_spmp/2025/03/09/4c/1741484334d516f792863c1a0630d89b59e1fb7ff0.jpg', 1, 4.34, 'pending', '2026-04-06 15:05:13', ''),
(233, 1, 'طقم مجوهرات للنساء مكون من: 1 قلادة بتعليقة زهرة وردية متدرجة الطبقة غير متماثلة مصنوعة يدويًا، 1 زوج من الأقراط، 1 خاتم، 1 سوار، 1 أسورة (بدون علبة هدايا)', 'I3wurjes3ds2', 'https://img.ltwebstatic.com/v4/j/spmp/2025/07/21/b5/17530702941ecac11257f54619f4bbe669d8c302cb.jpg', 1, 4.69, 'pending', '2026-04-06 15:05:13', ''),
(234, 1, 'ساعة كوارتز أنيقة للنساء 1قطعة بسلسلة قابلة للتعديل ذات خرز ذهبي، علبة بلون الذهب الوردي، وقرص أم اللؤلؤ المنسوج، مناسبة للمناسبات الرسمية', 'I528hwo7l311', 'https://img.ltwebstatic.com/images3_spmp/2024/08/16/30/172377662426a24841dbb90ff3654f11c0ba081239_square.jpg', 1, 2.61, 'pending', '2026-04-06 15:05:13', ''),
(235, 1, 'ساعة سوار للنساء برؤية كريستال مقطوع ماس وخرزة كبيرة واحدة، ساعة كوارتز بسيطة', 'I56mxsvvb7xp', 'https://img.ltwebstatic.com/v4/j/spmp/2025/07/24/56/1753336111450ad60ce13a2e300e733288948a609d_square.jpg', 1, 3.01, 'pending', '2026-04-06 15:05:13', ''),
(236, 1, 'زوج أقراط حلقية على شكل C مزين بالخرز الصناعي ذو تصميم راقي فاخر مناسب للنساء في الأناقة الشخصية والأحداث والحفلاترمضان', 'I61bm9kjn4li', 'https://img.ltwebstatic.com/images3_spmp/2024/12/11/a9/1733904585703f8456c0ff943307d1fc2891f47ac3.jpg', 1, 1.03, 'pending', '2026-04-06 15:05:13', ''),
(237, 1, 'خاتم مرصع بالزركونيا المكعبة والخرز الاصطناعي، هدية مجوهرات للنساء في عيد الزفاف والذكرى السنوية', 'I8u8o7njgx75', 'https://img.ltwebstatic.com/images3_spmp/2023/10/10/ef/169690286238496d73e59ce2945a40b1870d0efbdc.jpg', 1, 1.76, 'pending', '2026-04-06 15:05:13', ''),
(238, 1, 'SHEIN بنطلون جينز أزرق فينتاج مبطن حراريًا مع خصر غير متماثل فضفاض، للفتيات، مناسب للخريف والشتاء، أنيق للفتيات في', 'I820f7srmc6o', 'https://img.ltwebstatic.com/images3_pi/2025/02/24/b5/174037488761aeb9927e1e7ee80808554dccada329.jpg', 1, 12.25, 'pending', '2026-04-06 15:05:13', ''),
(239, 1, 'SHEIN بنطلون جينز لفتاة يافعة بيت Y2K كاجول متهالك أزرق قصمية فضفاض، بنطلون جينز كاجوال فضفاض للبنات للربيع والصيف للأيام العطلة', 'I14cj1hw8b2o', 'https://img.ltwebstatic.com/images3_pi/2025/02/24/33/1740396700443b4ce098a5663bf7c2d5eff3cf1d8c.jpg', 1, 12.23, 'pending', '2026-04-06 15:05:13', ''),
(240, 1, 'مجموعة قبعة شمسية للفتيات بطبعات زهور وحقيبة 2 قطعة، مناسبة للزي الربيعي / الصيفي الخاص بالعطلات، لبس اليومي، حماية من الأشعة فوق البنفسجية', 'I22n91diomj9', 'https://img.ltwebstatic.com/images3_spmp/2024/05/12/ea/17155033887ac38e8c26130bb399795935a9c7f99a.jpg', 1, 3.23, 'pending', '2026-04-06 15:05:13', ''),
(241, 1, 'قميص تي شيرت بدون أكمام بتصميم أشجار وشورت هاواي مرن الخصر قطعتان للأولاد', 'I3860bz3snb0', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/30/3b/1745991752e4264087d36baf6a218875a5ceec0055.jpg', 1, 6.01, 'pending', '2026-04-06 15:05:13', ''),
(242, 1, 'صنادل كعب عالي للبنات، أحذية جلالية مرصعة بالترتر بألوان نمط للبنات الصغيرات، مناسبة للأداء والعروض والحفلات', 'I5d3bmf6k9ca', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/18/02/17634686494056d68532eca705f1aaa7d963b12c64.jpg', 1, 18.38, 'pending', '2026-04-06 15:05:13', ''),
(243, 1, 'قبعة شمسية وحقيبة أطفال الأجزاء تحتوي على طبعة فراشة كرتونية، قبعة شاطئ قطنية لطيفة للأولاد والبنات في الحياة اليومية أو العطلات', 'I72qejthuqs7', 'https://img.ltwebstatic.com/images3_spmp/2024/02/25/cb/1708870827caa28f8ed5033756986bc24a21ac1119.jpg', 1, 5.52, 'pending', '2026-04-06 15:05:13', ''),
(244, 1, 'SHEIN تي شيرت أنيق بأكمام قصيرة بطبعة ديناصور لصبي المراهقين، مجموعة مطبوعة بتصميم الديناصور مكونة من قطعتين مناسبة للصيف', 'I09c3wmkru7q', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/26/2f/1766749927f3b8f8c3b28d2ba1055b8ba94b83f539.jpg', 1, 7.24, 'pending', '2026-04-06 15:05:13', ''),
(245, 1, 'SHEIN مجموعة قميص كاجوال ذو رقبة دائرية وشورت للأولاد المراهقين 2 قطعة، بتصميم بسيط، صيفي', 'I852tto2fblv', 'https://img.ltwebstatic.com/v4/j/pi/2025/09/16/c6/17579872791775e90945cc1cf106325a8125136c6b.jpg', 1, 7.72, 'pending', '2026-04-06 15:05:13', ''),
(246, 1, 'SHEIN توب ملابس علوية آزرق وأصفر بطبعة ظل أشجار النخيل وألوان الغروب المناسب للشباب، مناسب للصيف والشاطئ والعطلات والأنشطة الخارجية', 'I48rqnk1x8b8', 'https://img.ltwebstatic.com/v4/j/pi/2025/05/23/59/17479383252ae218ab5fa6498365283b189e7fd3fa.jpg', 1, 4.26, 'pending', '2026-04-06 15:05:13', ''),
(247, 1, 'SHEIN مايوه طقم متكامل بطبعات استوائية واحدة للفتيات، مع معطف كيمونو.', 'I06uo4kouv19', 'https://img.ltwebstatic.com/images3_pi/2023/02/15/1676460900e61314639464b686301572207df00c33.jpg', 1, 7.85, 'pending', '2026-04-06 15:05:13', ''),
(248, 1, 'SHEIN مجموعة ملابس علوية كاميسول مطرز ثلاثي الأبعاد وبقصة غير متماثلة مع بنطلون كاجوال طويل للفتيات في الصيف، قطعتين', 'I674weinhv36', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/28/e3/17695659618f58d3420a8a9e0c884f836718b81521.jpg', 1, 7.19, 'pending', '2026-04-06 15:05:13', ''),
(249, 1, 'SHEIN زي شاطئي لطفلة، ملابس علوية بلا أكمام مريح مطاطي مع بنطلون واسع الأرجل ، صيف / شتاء', 'I357hk2z8pnf', 'https://img.ltwebstatic.com/images3_pi/2024/04/28/2b/1714289343bb603c4b7dcf11f236012c0eae32076c.jpg', 1, 5.95, 'pending', '2026-04-06 15:05:13', ''),
(250, 1, '3 قطع طقم بنات مراهقات مكون من ملابس علوية كامي مطبوع عليه حرف بروكلين + ملابس علوية شبكية + شورت، طقم صيفي عصري للخارج، مناسب كهدية صيفية', 'I66x2bxtabgb', 'https://img.ltwebstatic.com/v4/j/spmp/2025/03/21/68/17424915364bbb22293c6dd09c6c5f834760357f38.jpg', 1, 8.71, 'pending', '2026-04-06 15:05:13', ''),
(251, 1, 'SHEIN 2 قطعة / مجموعة طقم ملابس نسائية رياضي كاجوال، تشمل: تيشيرت جرافيك 56 مطبوع عليه شعار \"كل يوم مميز\" وأكمام ملونة متباينة، شورت دراجة متناسق، مناسب للصيف، الرياضة، اللياقة البدنية، التسوق والأنشطة الاجتماعية', 'I78jvc9f05bk', 'https://img.ltwebstatic.com/v4/j/pi/2025/05/19/da/17476361855223c2bf386eb1c4773cc668a1db3d74.jpg', 1, 5.25, 'pending', '2026-04-06 15:05:13', ''),
(252, 1, 'حقيبة يد أنيقة مزينة بالجليتر وتقليد اللؤلؤ للحفلات المسائية', 'I6493k3h97vx', 'https://img.ltwebstatic.com/images3_spmp/2023/07/13/16892273490a90d1d4051c7274d5219f3050974fc2.jpg', 1, 6.66, 'pending', '2026-04-06 15:05:13', ''),
(253, 1, 'نظارات شمسية رائجة وعصرية للأطفال الذين تتراوح أعمارهم بين 4-10 سنوات، ذات إطار مربع كبير وإطارات \"Love\" عالية الجودة ومتعددة الاستخدامات ومناسبة للخروجات اليومية ولضروريات الارتداء', 'I94uwmo9145t', 'https://img.ltwebstatic.com/images3_spmp/2024/04/15/2e/1713158753ef2ccb229458ab3eda24d3a68056194c.jpg', 1, 5.06, 'pending', '2026-04-06 15:05:13', ''),
(254, 1, '1 قطعة من الإكسسوارات الزخرفية المتفكّكة بألوان كرتونية صلبة مصنوعة من السيليكون، مناسب للحقيبة اليدوية وحقيبة الشاطئ والاستخدام الخارجي وألعاب الشاطئ وأيضًا كهدية عيد ميلاد', 'I97yla2m733i', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/15/e2/1744707522f9609fe626805b5b526c0c933b98dd17.jpg', 1, 4.26, 'pending', '2026-04-06 15:05:13', ''),
(255, 1, 'مجموعة مشط مربع وزجاجة رذاذ 7 قطع، مشط بلاستيكي مضاد للكهرباء الساكنة بطباعة برج إيفل الكرتونية، مشبك شعر محمول بنمط، زجاجة رذاذ ضغط عالي، مناسبة للأطفال والفتيات، لأنواع الشعر العادية، مقبض ABS متين، تصميم مربع جميل، طقم أدوات تصفيف الشعر', 'I17xqyyl27ud', 'https://img.ltwebstatic.com/v4/j/spmp/2026/03/27/0d/177458218999f809012f2ea3b6afa5a995b4563af8.jpg', 1, 5.27, 'pending', '2026-04-06 15:05:13', ''),
(256, 1, 'فستان صيفي للبنت الصغيرة بطبعة زهرية وحواف مكرمشة مع أشرطة مربعة، تصميم منعش، ضروري الامتلاك', 'I92ixwa7m5x1', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/21/e7/1745227156a12df0e6670b89892d2392aad94e0663.jpg', 1, 5.95, 'pending', '2026-04-06 15:05:13', ''),
(257, 1, 'زوج من صنادل رياضية للأطفال اللون الخاكي، أحذية شاطئ للأطفال الصغار، أحذية صيفية عادية للمشي للرضع، نعال ناعمة وجميلة', 'I2d1x8mohp3o', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/13/8f/1762969391367d70e03857aea333f20acbb876a179.jpg', 1, 6.90, 'pending', '2026-04-06 15:05:13', ''),
(258, 1, 'SHEIN Elladie kids مجموعة من ملابس علوية بدون أكمام طباعة قلب بسيط أمامي وتنورة قصيرة للفتيات الصغيرات، 2 قطعة', 'I53ujckf5vjc', 'https://img.ltwebstatic.com/images3_pi/2024/11/15/2c/1731650049e9c7ef2239e3ca2c79fb7388bea5b349.jpg', 1, 8.39, 'pending', '2026-04-06 15:05:13', ''),
(259, 1, 'SHEIN 3 طقم بدلة رياضية للبنات مطبوع بطبعة الكاموفلاج والقلوب والزهور والأشكال الهندسية الملونة', 'I176dw8ogixp', 'https://img.ltwebstatic.com/v4/j/pi/2025/04/16/42/17447726283472a107c9faf6fd63faee2c3455b698.jpg', 1, 10.39, 'pending', '2026-04-06 15:05:13', ''),
(260, 1, 'شبشب مفتوح الأصبع مريح، صنادل شاطئ خفيفة الوزن وقابلة للتنفس للبنات، مناسبة للأنشطة الخارجية', 'I983idv3ihpl', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/21/e0/17452064918e6ccf3725a080249ce7035620ff8632.jpg', 1, 7.90, 'pending', '2026-04-06 15:05:13', ''),
(261, 1, 'حقيبة ظهر أطفال ضد للماء تصميم رسوم كارتون أرنب ديكور', 'I7s5brlfpuqh', 'https://img.ltwebstatic.com/images3_spmp/2023/06/20/1687240838de959733eac5021e8746e23dad6fe588.jpg', 1, 11.19, 'pending', '2026-04-06 15:05:13', ''),
(262, 1, 'بدلة قصيرة لطيفة مطبوعة بنقش الزهور للفتاة الشابة بأكتاف عارية وردية بحاشية مزينة بالريش، مثالي لعطلة الصيف', 'I1abave71108', 'https://img.ltwebstatic.com/v4/j/spmp/2026/03/09/38/17730210334b4a9ce71074f52418f763d4454b0df7.jpg', 1, 8.40, 'pending', '2026-04-06 15:05:13', ''),
(263, 1, 'زوج من أحذية الأطفال المسطحة الأنيقة، أحذية أطفال مسطحة جديدة، أحذية بنات مزينة بفيونكة', 'I3brjx0ymlww', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/19/48/17582606350cde2b95cd6de498ee022cdf577f1abd.jpg', 1, 10.11, 'pending', '2026-04-06 15:05:13', ''),
(264, 1, 'SHEIN Genkimix Kids مجموعة قميص كامي مطرز ثلاثي الأبعاد وبتصميم غير متماثل مع بنطلون كاجوال للبنات في الصيف، 2 قطعة/مجموعة', 'I5mkmh580yqv31', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/30/83/1769742423400a5caf5e3e956193bda7fcda5ee547.jpg', 1, 7.73, 'pending', '2026-04-06 15:05:13', ''),
(265, 1, 'بدلة سباحة مطبوعة بأنماط عشوائية لفتاة صغيرة', 'I271b8zek5nq', 'https://img.ltwebstatic.com/images3_pi/2025/04/02/6e/174357592689f00930f16eb0c5a42ed699bec83096.jpg', 1, 9.06, 'pending', '2026-04-06 15:05:13', ''),
(266, 1, 'SHEIN طقم بنطال جينز وسترة بلا أكمام بنمط أنيق للفتيات، ملابس خريف/شتاء للأطفال، ملابس عودة للمدرسة وحفلات عودة للمنزل، طقم أنيق قطعتين', 'I25k3rxup0ly', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/25/da/17744102394c786b59c10e986a608dd5d5152b0ee1.jpg', 1, 16.52, 'pending', '2026-04-06 15:05:13', ''),
(267, 1, 'بدلة سباحة للبنات الصغيرات بكتف واحد وبدون أكمام مع فتحات جانبية وتنورة شبكية. هذه البدلة الأنيقة والكاجوال والأنيقة مثالية للسباحة والعطلات وبدلات السباحة الصيفية للبنات الصغيرات.', 'I3cm55nog6j8', 'https://img.ltwebstatic.com/v4/j/pi/2025/11/17/b7/1763345428810dae77c3de69a5d7538e17d78c7c54.jpg', 1, 6.13, 'pending', '2026-04-06 15:05:13', ''),
(268, 1, 'SHEIN طقم قميص بستراب شبكي بزخرفة وردية ثلاثية الأبعاد وتنورة بعقدة جميلة لفتاة صغيرة، صيفي بلون صلب 2 قطعة', 'I14cghzgzzrt', 'https://img.ltwebstatic.com/images3_pi/2024/04/15/0e/1713144589fa569c54a175bd5be73a66791ef0459f.jpg', 1, 11.89, 'pending', '2026-04-06 15:05:13', ''),
(269, 1, 'مجموعة قميص وبنطلون بأكمام قصيرة وياقة طاقم للفتيان المراهقين، بتصميم كاجوال بسيط وأنيق، بطبعات الديناصور والكامفلاج والرسومات اليدوية الجرافيتية، بقصة فضفاضة مريحة وأنيقة', 'I6mj8j1uzrs6nw', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/23/df/176647079549ad80a831bf5f797f4e752717f6f092.jpg', 1, 9.06, 'pending', '2026-04-06 15:05:13', ''),
(270, 1, 'SHEIN لباس علوي بدون أكمام بطبعة استوائية و تنورة بحافة متموجة لفتاة صغيرة', 'I138hnmnpsng', 'https://img.ltwebstatic.com/images3_pi/2022/03/16/1647398699472100c04576acd86c1af132b106e492.jpg', 1, 5.70, 'pending', '2026-04-06 15:05:13', ''),
(271, 1, 'SHEIN لباس علوي علوي بشريط حروف وشورت دولفين لفتاة صغيرة', 'I6elf4hlrha8', 'https://img.ltwebstatic.com/images3_pi/2022/04/22/1650632082b63b6e23137e9e98aec151bfb0bfbaeb.jpg', 1, 5.45, 'pending', '2026-04-06 15:05:13', ''),
(272, 1, 'نظارات أطفال جميلة بزهور وأذنين دب، بطاقة عرض فقط، بدون شحن', 'I16iw0w4owho', 'https://img.ltwebstatic.com/images3_spmp/2025/01/19/e2/17372188488db912c6e5ceef13bb5393ab602ef833.jpg', 1, 3.01, 'pending', '2026-04-06 15:05:13', ''),
(273, 1, 'زوج من صنادل بيج مسطحة للبنات، لون أحادي من جلد البولي يوريثان مع حزام قابل للتعديل، تصميم إبزيم لؤلؤي لامع، مفتوحة من الأمام، صنادل رومانية أنيقة وجميلة للشاطئ، مناسبة للبنات من عمر 3-12 سنة، للاستخدام اليومي، الشاطئ، الحفلات، الربيع/الصيف', 'I2d7f5zkvfbt', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/03/23/1746212960b0452d23e13f2b92cc64b2c160201bcc.jpg', 1, 7.94, 'pending', '2026-04-06 15:05:13', ''),
(274, 1, '2 قطعة مجموعة ملابس علوية نصف كم مطبوعة بالفراشات وبنطلون جوغر بلون قطعي للفتيات الصغيرات للصيف', 'I97k2f1pwvkg', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/24/4e/174548682311f7b7a1e8a435132fc67e8b03d9fefb.jpg', 1, 6.00, 'pending', '2026-04-06 15:05:13', ''),
(275, 1, 'SHEIN مجموعة من قطعتين تتكون من قميص كامي مطبوع عليه حرف وشورت مطبوع عليه نجوم، بتصميم عصري ومناسب لفرقة K-POP، مناسب للصيف', 'I7mkavgqjnl96n', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/15/f4/176845761598b79f682008f7ce8c08845eb8602b56.jpg', 1, 4.80, 'pending', '2026-04-06 15:05:13', ''),
(276, 1, 'SHEIN مجموعة ملابس علوية وبنطلون بطبعة أرنب وفهد، ملابس علوية بأكمام قصيرة وياقة دائرية فضفاض وبنطلون ضيق، مناسبة للبنات الصغيرات للارتداء اليومي في الربيع والصيف، للسفر والتنسيق والمنزل والعطلات والخارج والمزرعة والاسترخاء، 2 قطعة/مجموعة', 'I5mjsocfeeyr9n', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/08/32/1767863270213d28a6e80f97275cd1e44398d62432.jpg', 1, 5.73, 'pending', '2026-04-06 15:05:13', ''),
(277, 1, 'صنادل خفيفة الوزن وقابلة للتنفس ذات موضة كاجوال مريحة للبنات ، صيفي', 'I92c1mdqlw4w', 'https://img.ltwebstatic.com/images3_pi/2024/08/26/73/172466281336eee9ea615a39f74200e405c31e7b3f.jpg', 1, 8.53, 'pending', '2026-04-06 15:05:13', ''),
(278, 1, 'زوج من صنادل الأميرة ذات الكعب العالي والرجعية للبنات، أحذية شاطئ ذات نعل ناعم، صيفية', 'I59ostur2zow', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/30/a4/1764493772ebef0b395e7c4b53246d3bf395eb1640.jpg', 1, 7.88, 'pending', '2026-04-06 15:05:13', ''),
(279, 1, 'طقم ملابس علوية كامي بدون أكمام مزينة بالكشكشة + شورت مزين بطبعة زهرة عباد الشمس قطعتين', 'I95dslicln9t', 'https://img.ltwebstatic.com/images3_spmp/2024/12/27/17/1735281753f2e2d73d3942e42004f758f78e3b5700.jpg', 1, 5.86, 'pending', '2026-04-06 15:05:13', ''),
(280, 1, 'زوج حذاء شاطئ فلات لبنات رضع ذهبي لامع، حزام مرصع بالراين ملون ، مصنوع من جلد البو المنسوج ، تصميم ذو فتحة للأصابع ومزين باللؤلؤ والفراشة ، صندل فاخر بتصميم إنزلاقي ، مناسب للبنات الرضع في اليومي ، الكاجوال ، الشاطئ ، الحفلات ، الصيف', 'I69aa1ib1rrx', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/10/f0/1749550617a03a08920383089fe42bdacd0fa10980.jpg', 1, 4.80, 'pending', '2026-04-06 15:05:13', ''),
(281, 1, 'فستان حفلة للفتاة الصغيرة من الدانتيل والتول المزخرف بأزهار ثلاثية الأبعاد وتصميم ملتصق على الكتف، فستان أنيق لحفلات عيد ميلاد الفتيات ، فستان سهرة أنيق لحفلات البيانو والعروض الأميرية', 'I2399l9rq848', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/04/7f/1764847277c8c3d24a5513dbf298fa1829c388f960.jpg', 1, 23.87, 'pending', '2026-04-06 15:05:13', ''),
(282, 1, '4 قطع طقم سيدة شابة بسيط بنقشة قلب مكفوفة', 'I37nivvjr2rw', 'https://img.ltwebstatic.com/v4/j/pi/2025/05/13/b8/1747125653d60af0a4896522ba0d043d65c37defbf.jpg', 1, 9.86, 'pending', '2026-04-06 15:05:13', ''),
(283, 1, 'أحذية أميرة ذات قاع ناعم وفيونكة جديدة للبنات، أنيقة وحلوة، مناسبة للربيع والخريف', 'I841a2lt0p3n', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/08/03/17466867438032906df9594fb3c5c827bc4563d2c8.jpg', 1, 7.24, 'pending', '2026-04-06 15:05:13', ''),
(284, 1, 'SHEIN رمضان بنت طفل بتفاصيل رفرف دنيم صديري & محبوك مضلع رومبير كامي', 'I73ou2hg3vzk', 'https://img.ltwebstatic.com/images3_pi/2023/07/08/16888081027dda50a0e91c1ae5c345b4fbff5118f1.jpg', 1, 10.64, 'pending', '2026-04-06 15:05:13', ''),
(285, 1, 'طقم جمبسوت قميص بنات صلبة مخطط 3قطع/مجموعة', 'I6tkucri72do', 'https://img.ltwebstatic.com/images3_spmp/2024/07/28/18/1722131874d07f1b137a6cab8831d000a9d9549360.jpg', 1, 7.99, 'pending', '2026-04-06 15:05:13', ''),
(286, 1, 'زوج واحد من الصنادل المفتوحة الأنف المزينة بزهور أنيقة وجميلة للبنات الصغيرات، خفيفة الوزن ومنفذة للهواء، مناسبة للداخل والخارج والمناسبات', 'I059n7m1zxmw', 'https://img.ltwebstatic.com/images3_spmp/2024/12/22/5f/1734861467f34edd5007bce80c242b34db74765bfa.jpg', 2, 8.20, 'pending', '2026-04-06 15:05:13', ''),
(287, 1, 'مجموعة قميص وشورت مزخرفة بزهور ثلاثية الأبعاد عصرية للفتيات الشابات، صيفي', 'I74diox0ixdi', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/23/66/1766480172ededd1a6a3e8f10a634bc1a89f169074.jpg', 1, 7.81, 'pending', '2026-04-06 15:05:13', ''),
(288, 1, 'SHEIN قميص سباغيتي كامي مطرز بالدانتيل المثقوب ويحمل قوس بالأمام ، وبنطلون بتصميم الزنبقة لفتاة صغيرة', 'I51an8lhkwy1', 'https://img.ltwebstatic.com/v4/j/pi/2025/07/25/51/17534329645cd1cac6ad09dbf6ba41e208f9860ddf.jpg', 1, 8.38, 'pending', '2026-04-06 15:05:13', ''),
(289, 1, 'SHEIN طقم قميص أكمام قصيرة وشورت فوق المراهقة مكون من 2 قطع', 'I31xizdvzs21', 'https://img.ltwebstatic.com/images3_pi/2025/03/07/71/174133472276c37990618c42ff2e14c5b44a70abff.jpg', 1, 9.65, 'pending', '2026-04-06 15:05:13', ''),
(290, 1, '2 قطعة مجموعة بلوزة مكشكشة + تنورة ذات خصر مرتفع برقبة مكشكشة، ناعمة ومريحة الملبس ومرحة، مناسبة للفتيات من عمر 4-7 سنوات للرحلات والسفر وحفلات الشاطئ في الربيع والصيف', 'I7342damj5fc', 'https://img.ltwebstatic.com/images3_spmp/2025/02/25/5e/1740451404476cb5490269308018cafd70315dda39.jpg', 3, 6.31, 'pending', '2026-04-06 15:05:13', ''),
(291, 1, 'Cozy Pixies زوج من الصنادل المسطحة الجميلة للأطفال البنات، مزخرفة بفيونكة ملونة للأجازات والأعياد، مناسبة للربيع والصيف', 'I54lvto3k10p', 'https://img.ltwebstatic.com/images3_pi/2024/12/05/56/17333905578324881664a6dc7553e4b982cd43bcff.jpg', 1, 11.90, 'pending', '2026-04-06 15:05:13', ''),
(292, 4, 'اثنين من أكمام الثلج الفضفاضة عصرية ولطيفة مضادة لأشعة الشمس للقيادة وركوب الدراجاترمضان', 'I91pjd2fpcxh', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/02/eb/17461694466d07bedf44d5db5ce6b73ef2e9ccfcc8.jpg', 1, 2.10, 'pending', '2026-04-06 15:49:58', ''),
(293, 4, '1 زوج / 4 أزواج / 5 أزواج من الأكمام الحمائية من الأشعة فوق البنفسجية بتصميم مضغوط مناسب للجنسين للجولف والسلة والدراجات والصيد والقيادة والجري والتجديف والبستنة', 'I274ttgq5t75', 'https://img.ltwebstatic.com/images3_spmp/2025/03/11/28/1741684455413e0bcb2b31b2d5679e21d441e142e4_square.jpg', 2, 3.20, 'pending', '2026-04-06 15:49:58', ''),
(294, 4, 'حماية ذراع الشمس 2 قطعة / مجموعة للربيع والصيف والخريف، حرير الجليد، مناسب للقيادة في الهواء الطلق والحماية من الأشعة فوق البنفسجية، الأكمام الكبيرة بالإضافة الى قفازات الحماية من الشمس', 'I446mui69lij', 'https://img.ltwebstatic.com/images3_spmp/2025/01/21/12/17374266273b250fda51b0702f6402657b71ce0f3d.jpg', 1, 2.13, 'pending', '2026-04-06 15:49:58', ''),
(295, 4, 'Manfinity Campus Court قميص كاجوال بياقة طاقم وأكمام طويلة مع طباعة حرفية، خريف', 'I53q1zsv7wsq', 'https://img.ltwebstatic.com/images3_pi/2024/11/13/4d/17314757313b353031ed1890e3f5530c0f76d458cb.jpg', 1, 16.25, 'pending', '2026-04-06 15:49:58', ''),
(296, 4, 'Manfinity Homme قميص كاجوال بأكمام طويلة وأزرار أمامية مربعات، للارتداء اليومي، للخريف', 'I03hnvotsl1t', 'https://img.ltwebstatic.com/images3_pi/2024/11/01/a2/17304495627656fb521b0478951761ba178b49fd95.jpg', 1, 15.11, 'pending', '2026-04-06 15:49:58', ''),
(297, 4, 'Fractyr Fractyr قميص تي شيرت رجالي بطبعة شكل بسيطة عصرية، قصير الأكمام، ملائم للارتداء اليومي والشارع', 'I1mkgbgli5co9e', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/16/e0/1768533175fb84e1b31299633075b08161c7de4d70.jpg', 1, 8.49, 'pending', '2026-04-06 15:49:58', ''),
(298, 4, 'On feet& in love أحذية نسائية أنيقة وعصرية ذات أصبع قدم مدبب وحزام مفتوح من الأمام، مناسبة للارتداء مع الفساتين والكعب والصنادل، صنادل ذات كعب عالي للصيف', 'I2b69hkkj46z', 'https://img.ltwebstatic.com/v4/j/spmp/2025/10/26/d0/176145969713b06ba2e5823e68b502898ac96e052e.jpg', 1, 18.11, 'pending', '2026-04-06 15:49:58', ''),
(299, 4, 'SHEIN EZwear تي شيرت كاجوال أسود طويل الأكمام مضبوط التفصيل، تصميم رقبة عميقة على شكل V مزين بالدانتيل، مناسب للخريف/الشتاء', 'I037qam3yr2d', 'https://img.ltwebstatic.com/images3_pi/2024/10/08/bf/17283807352fc3d6ce673b5c61edebba94f42e7a3c.jpg', 1, 6.39, 'pending', '2026-04-06 15:49:58', ''),
(300, 4, 'SHEIN EZwear بنطلون نسائي واسع الساق للاستخدام اليومي والعطلات، مناسب للصيف، مناسب للعطلات', 'I83y5yitjhav', 'https://img.ltwebstatic.com/v4/j/pi/2025/10/18/9b/176076497621409b837f1ae09ee3d2b25df3d3b9d2.jpg', 1, 9.05, 'pending', '2026-04-06 15:49:58', ''),
(301, 4, '3 قطع/قطعة واحدة بطول 37 سم (14.57 بوصة) باللون الأسود والبني والرمادي والسلحفاة، شريط رأس بلاستيكي خفيف الوزن غير قابل للانزلاق، ملحقات شعر أنيقة وبسيطة متعددة الاستخدامات مناسبة للارتداء اليومي والكاجوال والحفلات والتنقل والشاطئ والعطلات وتصفيف الشعر وغ', 'I0dbxyi6f0bv', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/28/3d/1764344430ee926a2ef91be2c09ff2df50737d39fe.jpg', 1, 1.04, 'pending', '2026-04-06 15:49:58', ''),
(302, 4, 'زوج من النظارات الشمسية المربعة المعدنية الأنيقة للسيدات، نظارات شمس أنيقة للشاطئ، اكسسوارات للشاطئ للسيدات، نظارات شمس للبسطاء للبلوزة والجينز والبنطلون الرياضي والهوديي والسترات والفساتين والقمصان ذات الأكمام الطويلة، ظلال أنيقة لخروجات العائلة والسفر و', 'I630dajgfkqb', 'https://img.ltwebstatic.com/images3_spmp/2024/01/28/f0/170640193632b0eba7a89dd23b5b9703a156052c80.jpg', 1, 3.20, 'pending', '2026-04-06 15:49:58', ''),
(303, 4, 'GDTME كتاب تلوين سيارة الانجراف الخيالية: تصميم بسيط جريء، رسومات سيارات جميلة وممتعة، مساحة تلوين مريحة، مناسب للطلاب والمراهقين، يخفف الضغط ويعزز الإبداع، هدية مثالية لعيد الميلاد وعيد الأب والعودة إلى المدرسة - 24 صفحة أحادية الجانب، يأتي مع 5 ملصقات ع', 'I5bse95phau9', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/24/7d/17587028492fb771488857eb81eeafa6fa8312f382_square.jpg', 1, 3.20, 'pending', '2026-04-06 15:49:58', ''),
(304, 4, 'صنادل كاجوال للبنات، وصول جديد أحذية شبشب مسطحة للأطفال الصغار والكبار، أحذية شاطئ للأطفال البنات', 'I277mznvh5to', 'https://img.ltwebstatic.com/images3_spmp/2025/03/15/bc/17419704129d1f2e163abfca0e8fe56a315de6d197.jpg', 1, 4.79, 'pending', '2026-04-06 15:49:58', ''),
(305, 4, '4 قطع/عبوة جوارب باليه للأطفال البنات بنقشة جاكارد العشب، سراويل ضيقة رقيقة جدًا وقابلة للتنفس، مناسبة للبنات في الصيف', 'I14shoeb5v6f', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/07/5b/1746587042d67e1d07160c81825ab6c3b9004af2a5.jpg', 1, 5.48, 'pending', '2026-04-06 15:49:58', ''),
(306, 4, '48 صفحة كتاب تمارين تتبع الحروف الأبجدية للأطفال | ممارسة الحروف من A-Z، مناسب للمرحلة التمهيدية والروضة | كتاب ممارسة الكتابة المبكرة الممتع، يتضمن صفحات للرسم، وممارسة الكلمات السحرية، هدية رائعة وكتاب كتابة باللغة الإنجليزية عملي ومتين، مثالي لموسم الع', 'I5covdnfxz4u', 'https://img.ltwebstatic.com/v4/j/spmp/2025/10/28/4b/1761643799a90780563fe585b554e8b3935fd6b560.jpg', 1, 2.17, 'pending', '2026-04-06 15:49:58', ''),
(307, 4, 'زوج من صنادل بنات صغيرات الحجم لون أحمر وردي، صنادل رومانية خفيفة منقوشة بفيونكة كبيرة، حزام مطاطي، نعل مضاد للانزلاق، مناسبة لفتيات تتراوح أعمارهن من 3 إلى 15 عامًا للاستخدام اليومي والحفلات والسفر في الربيع والصيف 2025', 'I39b9c7476g9', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/11/33/17496497767e5b52bae35f5f0c0dacd0a643df2133.jpg', 1, 7.19, 'pending', '2026-04-06 15:49:58', ''),
(308, 4, 'SHEIN Elladie kids فستان أنيق بلون سادة للفتيات الصغيرات. التصميم الأنيق للأكمام المرفرفة يضيف سحرًا جذابًا، والقصة على شكل حرف A تمنح سلاسة وكرم. الزخرفات الزهرية ثلاثية الأبعاد تُظهر الأناقة. مناسب لمناسبات متنوعة: للعب في الخارج يجذب الانتباه بسهولة؛ ل', 'I48haznntvy0', 'https://img.ltwebstatic.com/v4/j/pi/2025/05/26/99/1748227909fd45d45320c613f82a1bc067952c639c.jpg', 1, 6.43, 'pending', '2026-04-06 15:49:58', ''),
(309, 4, 'Elladie kids مجموعة سترة وشورت نسيج ملمس أصفر للفتيات الصغيرات، تصميم أنيق، ملابس صيفية فريدة للفتيات في العطلات الصيفية', 'I37mt1mvogmc', 'https://img.ltwebstatic.com/v4/j/pi/2025/05/13/bb/174711908441928f82050f72f7dd9a1fdbd2f339ab.jpg', 1, 7.19, 'pending', '2026-04-06 15:49:58', ''),
(310, 4, 'Elladie kids مجموعة قطعتين لفتاة صغيرة موديل صيفي جديد، بلوزة قطنية مطرزة بأكمام قصيرة وياقة مكسرة، بنطال قطني مستقيم الساق، ملابس عملية بطراز رجعي مناسبة للفتيات', 'I07mlpytjhwa', 'https://img.ltwebstatic.com/v4/j/pi/2025/04/30/5e/1746008937aa2b1cef220f02654b9369fa436d3b94.jpg', 1, 14.38, 'pending', '2026-04-06 15:49:58', ''),
(311, 4, 'SHEIN Genkimix Kids طقم فتاة شابة كاجوال مكون من 2 قطع، قميص كامسول مخطط وبنطلون. طقم كاجوال صيفي للأولاد والبنات مكون من 2 قطع.طقم ملابس صيفي للبنات الصغيرات مكون من 2 قطع.', 'I7740r2ty2yc', 'https://img.ltwebstatic.com/v4/j/pi/2025/04/17/82/1744858811475592b36a68e75b0910b98cdf547f8d.jpg', 1, 6.21, 'pending', '2026-04-06 15:49:58', ''),
(312, 4, 'SHEIN Genkimix Kids 6 قطع ملابس علوية بياقة مستديرة للأولاد الصغار باللون الأبيض الأملس، قماش محبوك ناعم ومريح، مناسب للارتداء اليومي والرياضة والعطلات، يمكن ارتداؤه مع شورت رياضي أو جينز، مثالي للمدرسة والعطلات والأعياد والسفر والاسترخاء والاستجمام في ال', 'I42rjr8hy6o4', 'https://img.ltwebstatic.com/images3_pi/2025/03/23/8a/174265922464077c958ed06441c74daf64349d064e.jpg', 1, 11.72, 'pending', '2026-04-06 15:49:58', ''),
(313, 4, 'كتاب تلوين للبالغين مكون من 24 صفحة، بمقاس 7.9 * 7.9 بوصة، بتصميم كرتوني، مناسب للمراهقين والبالغين، رائع للحفلات والهدايا والاسترخاء، فن كرتوني، لوحات جذابة. هدية عيد الأم، العودة إلى المدرسة، K-Pop، لوازم مدرسية، كتب تلوين، قرطاسية، هدايا عيد الفصح، ديك', 'I69r62u137qi', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/03/4b/176473411028d6a9d52fddf89ea5a89894e3979842_square.jpg', 1, 3.30, 'pending', '2026-04-06 15:49:58', ''),
(314, 4, 'بدلة سباحة قطعة واحدة للبنات، ذات طباعة توجيهية، مناسبة للبنات', 'I53qadbndp02', 'https://img.ltwebstatic.com/images3_pi/2024/11/23/44/1732364009ecbd0bddbe4a3ab005dd9f03f5a9a449.jpg', 1, 5.45, 'pending', '2026-04-06 15:49:58', ''),
(315, 4, 'مجموعة بيجامة بطبعة خروف كرتوني لطيف بأكمام قصيرة وبنطلون طويل للفتيات الصغيرات، وردي ورمادي، 2 قطعة/طقم', 'I0mm9yrzjub7yo', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/09/29/17730527724691feafaaacf65f609a89e9d7fa88a3.jpg', 1, 5.33, 'pending', '2026-04-06 15:49:58', ''),
(316, 4, 'SHEIN 5 قطع/عبوة ملابس داخلية من الحرير الخفيف بطبعات رسومات الفتاة جذابة مع فيونكة، مريحة ومناسبة كملابس خارجية', 'I23ok8tjp26c', 'https://img.ltwebstatic.com/images3_pi/2024/10/30/31/17302520730f2b38e074814ed12b5e3c339cbdf8e5.jpg', 1, 9.05, 'pending', '2026-04-06 15:49:58', ''),
(317, 4, 'سلسلة كتب الصور \"أنا مستعد\"، قصص النمو الهادئة للاستقلالية والمشاعر والصداقة والحياة المدرسية، قراءة جهرية داعمة لبناء الثقة والاستعداد، صفحات مصورة دافئة', 'I2mkdqlcuorl5t', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/14/3c/176837792665b24ce3d8883820e56c1ff4807232a5_square.jpg', 1, 3.38, 'pending', '2026-04-06 15:49:58', ''),
(318, 4, 'سلسلة كتب الصور \"أنا مستعد\"، قصص النمو الهادئة للاستقلالية والمشاعر والصداقة والحياة المدرسية، قراءة جهرية داعمة لبناء الثقة والاستعداد، صفحات مصورة دافئة', 'I1mkdqlcubksph', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/14/3c/176837792665b24ce3d8883820e56c1ff4807232a5_square.jpg', 1, 3.38, 'pending', '2026-04-06 15:49:58', ''),
(319, 4, 'سلسلة كتب الصور \"أنا مستعد\"، قصص النمو الهادئة للاستقلالية والمشاعر والصداقة والحياة المدرسية، قراءة جهرية داعمة لبناء الثقة والاستعداد، صفحات مصورة دافئة', 'I0mkdqlcuzrlqz', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/14/3c/176837792665b24ce3d8883820e56c1ff4807232a5_square.jpg', 1, 3.38, 'pending', '2026-04-06 15:49:58', ''),
(320, 4, 'FoBianJie رأس فرشاة المرحاض القابلة للاستبدال ذات رائحة المحيط الأزرق، ديكور حمام، ديكور الخريف', 'I53407vfxk2k', 'https://img.ltwebstatic.com/images3_spmp/2024/02/05/dd/1707112739d402768c345049179e37d943113c816b.jpg', 1, 4.87, 'pending', '2026-04-06 15:49:58', ''),
(321, 4, 'SHEIN LMoss Kids مجموعة للفتيات الصغيرات', 'I05bc8pd5cvb', 'https://img.ltwebstatic.com/images3_pi/2025/03/04/3d/174105960948947a23757549877f11f26b945f4b85.jpg', 1, 6.19, 'pending', '2026-04-06 15:49:58', ''),
(322, 4, 'LMoss Kids فستان كاجوال للفتاة الصغيرة بطبعة زهور صغيرة وكشكشة على الذيل', 'I1clfmj1xd7m', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/09/d0/176525182237bec15c6569724bb5d5b480322f51e3.jpg', 1, 6.70, 'pending', '2026-04-06 15:49:58', ''),
(323, 4, 'SHEIN LMoss Kids مجموعة بيجامات للفتيات الصغيرات بطبعات كرتونية كاواييي، أرنب أزرق، خياطة، طراز راقص، طباعة زهور أومبير، طباعة فيونكة وردية، مناسبة للصيف والخريف والشتاء، لأجواء كاجوال وكمبوس ورياضية، للنزهات والخروجات والأنشطة المنزلية والمدرسية', 'I23ig5dffrth', 'https://img.ltwebstatic.com/v4/j/pi/2026/02/03/31/177009717090917ea7fbdcc6ab091954b419dd42ba.jpg', 1, 9.13, 'pending', '2026-04-06 15:49:58', ''),
(324, 4, 'SHEIN بدلة سباحة للبنات، بدلة سباحة قطعة واحدة للبنات الصغيرات، بدلة سباحة قطعة واحدة كاجوال وأنيقة بطبعات أوراق باللون الوردي، مصنوعة من قماش محبوك محافظ بدون أكمام وشورت، مناسبة للسباحة والعطلات الصيفية والشاطئ وحمام السباحة وحفلات الصيف والأوقات الترفي', 'I19w6j2f6yn4', 'https://img.ltwebstatic.com/v4/j/pi/2026/02/04/e0/1770168773e642b33ed2842ca02cef8e267e7d79fe.jpg', 1, 4.79, 'pending', '2026-04-06 15:49:58', ''),
(325, 4, 'كتاب أوزبورن للرفع والكشف: لماذا يجب أن أقول آسف؟ كتاب معرفة علمي تعليمي مبكر للأطفال بأسئلة وإجابات', 'I7mk3t3mn4akpb', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/07/ca/1767777471f53472513862daedc4c1da9455b6c305_square.jpg', 1, 5.49, 'pending', '2026-04-06 15:49:58', ''),
(326, 4, 'BASUSARRI ملابس علوية كامسول مع تريم كشكش وبنطلون ساق واسعة، طقم أنيق للسيدات، بدلة صيفية كاجوال للفتيات', 'I2df35g5gck6', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/07/28/17651004109fb3d2121439f8faf810942814488505.jpg', 1, 6.13, 'pending', '2026-04-06 15:49:58', ''),
(327, 4, '1/2 قطعة جوارب طفل صيفية رقيقة بيضاء، جوارب فاخرة منقطة بالراينستونز براقة رفيعة، جوارب عادية كلاسيكية مريحة وعصرية، مناسبة للحياة اليومية، العطلات، العودة إلى المدرسة', 'I08lkasu3iis', 'https://img.ltwebstatic.com/v4/j/spmp/2025/03/24/3f/17428096392c43d37b01c13a234ecac6e1a6a5cdbe.jpg', 1, 3.46, 'pending', '2026-04-06 15:49:58', ''),
(328, 4, 'SHEIN ChillGRL مجموعة بنطلون وتي شيرت كاجوال للبنات المراهقات، تي شيرت بياقة مستديرة وأكمام قصيرة مطرز بنقشة الفراشة، وبنطلون كارجو، طقم أزياء عصري للربيع/الصيف، قطعتان', 'I83mshl4gun1', 'https://img.ltwebstatic.com/v4/j/pi/2026/04/03/cf/1775145689ce82245d856e88eef4c7596ecd732a94.jpg', 1, 12.52, 'pending', '2026-04-06 15:49:58', ''),
(329, 4, 'حقيبة تسوق صغيرة عصرية من جلد PU مقاوم للماء، بقفل معدني أحادي اللون بتصميم بسيط، مناسبة للتسوق والحمل، للنساء الشابات وطلاب الجامعة والمهنيين الشباب وموظفي المكاتب. مثالية للمكتب والمدرسة والعمل والأنشطة الخارجية والسفر والخروج. عرض خاص لرأس السنة الجديد', 'I6b2xvajgzvw', 'https://img.ltwebstatic.com/v4/j/spmp/2025/08/25/26/1756117711bc702b2092ec35fb1d6a9e1cc17b02a4.jpg', 1, 8.92, 'pending', '2026-04-06 15:49:58', ''),
(330, 4, 'ملابس علوية نسائية صيفية مثيرة مع أكمام قصيرة وياقة عالية مرصعة بالراين ستاند، مناسبة للحفلات والعطلات الربيعية', 'I51rtkp02mf1', 'https://img.ltwebstatic.com/images3_spmp/2024/07/26/c6/172197981811307df48b04774e40ec5dae2756a2c8.jpg', 1, 7.82, 'pending', '2026-04-06 15:49:58', ''),
(331, 4, 'أداة إزالة الرؤوس السوداء - مستخرج الرؤوس السوداء الأرغونومي، منظف مسام الوجه الناعم، كشارة وجه سيليكونية للتنظيف العميق، كشارة وجه مقشرة للبشرة الجنسين، أداة العناية بالبشرة لإزالة الرؤوس السوداء من الأنف، ملحقات تنظيف المسام سهلة الاستخدام', 'I88lgqq08wts', 'https://img.ltwebstatic.com/v4/j/spmp/2025/10/15/2a/1760498874727cd48194b6f695a8a07bbdb2bb733b.jpg', 1, 1.07, 'pending', '2026-04-06 15:49:58', ''),
(332, 4, 'صنادل نسائية ذات كعب عالٍ رفيع بطرف مدبب باللون الأسود مع إبزيم معدني قابل للطي، صنادل بكعب ستيليتو جذاب، مجموعة ربيع/صيف جديدة 2025، كعب عالٍ باللون البني', 'I07cela3hqv0', 'https://img.ltwebstatic.com/images3_spmp/2025/03/20/14/1742454194896e773b6e35f555515af2532bde35f2.jpg', 1, 15.18, 'pending', '2026-04-06 15:49:58', ''),
(333, 4, 'صنادل نسائية ذات كعب عالٍ رفيع بطرف مدبب باللون الأسود مع إبزيم معدني قابل للطي، صنادل بكعب ستيليتو جذاب، مجموعة ربيع/صيف جديدة 2025، كعب عالٍ باللون البني', 'I07cela3bs3g', 'https://img.ltwebstatic.com/images3_spmp/2025/03/20/14/1742454194896e773b6e35f555515af2532bde35f2.jpg', 1, 15.18, 'pending', '2026-04-06 15:49:58', ''),
(334, 4, '1 قطعة لعبة دعائية، سكين بلاستيكي قابل للسحب، حيلة سحرية، دعابة، سكين مزيف، مضحك', 'I29vix2alnyw', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/17/19/17501380813cdc0c9f76b3f7846bbed13073a164d5.jpg', 1, 1.32, 'pending', '2026-04-06 15:49:58', ''),
(335, 4, '1/2/3/4 قطعة حزام نسائي ذو شكل حرف U بسيط للخصر الرفيع، تصميم راقي متعدد الاستخدامات للفساتين والمعاطف، مناسب للاستخدام اليومي والعمل، هدية', 'I2mjlhmztapdv7', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/25/f3/1766666507a7ad027365948eda0a5dd40e196faf8b.jpg', 1, 3.79, 'pending', '2026-04-06 15:49:58', ''),
(336, 4, 'بدلة نسائية سوداء ضيقة، بدلة جسم شفافة مطرزة بالدانتيل ذات ياقة عالية وأكمام طويلة باللون الأسود، طراز شارع جذاب وعملي، مناسبة للتصوير الفوتوغرافي في الشارع، الارتداء اليومي، عطلة الشاطئ، النادي الليلي، حفلات العزاب، المواعدة، عيد الحب، الكرنفال، مهرجانات', 'I57r0qgcm5tx', 'https://img.ltwebstatic.com/v4/j/spmp/2025/10/02/23/1759395797f5836699d577ef3e2167d90e2793e061.jpg', 1, 9.81, 'pending', '2026-04-06 15:49:58', ''),
(337, 4, 'لعبة ضغط جبنة كبيرة واقعية، كرة توفو قابلة للضغط بتأخر الارتداد، كرة ضغط إبداعية للتخفيف من التوتر، ملمس ناعم ولزج، هدية رائعة لعيد الميلاد والمناسبات', 'I5mkpfykg5fdb0', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/22/1c/17690856257e3b197e7b2c5bc811f99f97478388d3_square.jpg', 1, 2.11, 'pending', '2026-04-06 15:49:58', ''),
(338, 4, '1/2/3 قطعة من ألعاب الإجهاد القابلة للضغط: كرات خبز ملونة صغيرة للضغط عليها، أجهزة مضادة للإجهاد بطيئة الارتداد، كرات عجين خبز واقعية مزيفة، ألعاب حسية قابلة للتمدد للمكتب والاسترخاء المنزلي، هدية مثالية للعائلة والأصدقاء', 'I3mjxz606fg18t', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/23/b2/176915077389659d6768c922cf0621338a02a734ff_square.jpg', 1, 2.10, 'pending', '2026-04-06 15:49:58', ''),
(339, 4, 'Weeklong فستان نسائي أنيق بأكمام واسعة وطباعة نمر من قماش لامع، مناسب للمكتب والحفلات والمناسبات الرسمية', 'I123p3pvc78f', 'https://img.ltwebstatic.com/v4/j/pi/2025/09/19/e2/1758254619e17426d4a3e458256c37d029750dbd88.jpg', 1, 21.30, 'pending', '2026-04-06 15:49:58', ''),
(340, 4, '3 طقم أقراط مشبك نحاسية مرصعة بالزركونيا بتصميم بسيط وأنيق، متعددة الاستخدامات للمواعدة والحفلات والارتداء اليومي، هدية عيد الميلاد للأصدقاء والأمهات', 'I7c5998j7x33', 'https://img.ltwebstatic.com/v4/j/spmp/2025/10/10/97/1760075995eacfe73a3c036a97afa6ef00abf41593.jpg', 1, 2.00, 'pending', '2026-04-06 15:49:58', ''),
(341, 4, 'لعبة ضغط مالت كبيرة 2026 الجديدة، متوفرة بألوان متعددة، هدية مثالية - هدية عيد ميلاد - هدية للأولاد - هدية للبنات - هدية عيد الميلاد - لعبة مطاطية', 'I7mkdz0w2h5e4u', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/14/f3/176839202826ebe77a7d7d54fb42f20856cafbed62_square.jpg', 1, 1.84, 'pending', '2026-04-06 15:49:58', ''),
(342, 4, '16000 قطعة من الراين الجيلي الملون 40 لون، لزخرفة الأظافر، أحجار مسطحة الظهر بمقاس 3مم/4مم/5مم، مناسبة للصنع اليدوي، مجموعة لامعة، يمكن استخدامها للملابس والأحذية والأظافر والمكياج وتطعيم الألماس وغيرها', 'I9bemfw3kpwl', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/08/66/17572990476e3b801106213ab32c588fa625eff46f.jpg', 1, 8.02, 'pending', '2026-04-06 15:49:58', ''),
(343, 4, 'Zivah بنطلون كتان بني مطوي مع جيوب سحاب وخصر مطاطي قابل للتعديل، مناسب للاستخدام اليومي والرسمي والحفلات والمناسبات والسفر والشاطئ والعطلات والحفلات الموسيقية وحفلات التخرج والزفاف وغيرها من المناسبات', 'I3dciqydde6w', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/23/77/1766456938d500a6c9c88597ae9bfcf33d7b9dca53.jpg', 1, 11.72, 'pending', '2026-04-06 15:49:58', ''),
(344, 4, '1 قطعة حزام أنيق وعصري من مواد سبيكة عالية الجودة للنساء، حزام أنيق بلون واحد مناسب للشباب والنساء متوسطات السن، يعزز الأنوثة، حزام رفيع مشبوك يدويًا على شكل حرف U، يتناسب مع البنطلونات/التنانير الكلاسيكية، مناسب للارتداء اليومي في المكتب والمدرسة والأنشط', 'I23tipjwg0ha', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/01/32/175671190068f629f093b22d9d16780d55803629bc_square.jpg', 1, 3.73, 'pending', '2026-04-06 15:49:58', ''),
(345, 4, 'Flirla تي شيرت شبابي للسيدات بياقة دائرية وأكمام قصيرة، طباعة أرقام وحروف بتصميم لطيف وعصري، بأسلوب ضبط قوام رشيق، طبعات جرافيك بالأعلى', 'I11oyyt534lp', 'https://img.ltwebstatic.com/images3_pi/2024/07/26/31/172197464461145a37cfd98ba7e8b17abdaaf9c01c.jpg', 1, 4.56, 'pending', '2026-04-06 15:49:58', ''),
(346, 4, 'صنادل نسائية ذات كعب رفيع عصرية وأنيقة، بتصميم فتحة للأصابع مزين بفيونكة، ذات لون أحادي وتصميم منصة، مناسبة للفساتين في المناسبات الرسمية أو غير الرسمية', 'I2d4aymftrlq', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/19/71/1763566715dfb4c534a21bb278b16ad0607de961a2.jpg', 1, 10.85, 'pending', '2026-04-06 15:49:58', ''),
(347, 4, 'Dewbera بنطلون رياضي نسائي فضفاض ذو ساق مستقيمة مع جيوب، خصر مزين بشريط متباين، خصر مطاطي مرن عالي المطاطية، مناسب للارتداء اليومي العادي، الجري، اليوغا، الجيم، التنس، الجولف، خلال فصلي الخريف والشتاء', 'I12g8q78viaa', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/05/87/1772715689927bedb9f3c85ab0d38572d7b5d2f865.jpg', 1, 11.98, 'pending', '2026-04-06 15:49:58', ''),
(348, 4, 'Resyla تي شيرت نسائي ضيق بياقة مستديرة مطبوع بنمط نمر، مناسب للربيع والصيف، تصميم متعدد الاستخدامات', 'I4mjjvydsutroz', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/11/2b/17731934779b1f064f39bfcccc90d6708436a1f3f8.jpg', 1, 5.31, 'pending', '2026-04-06 15:49:58', ''),
(349, 4, 'DAZY تي شيرت نسائي بأكمام قصيرة وياقة طاقم ضيق في الشكل وأساسي وعصري مناسب للصيف قطعة واحدة', 'I25vmevwnlyg', 'https://img.ltwebstatic.com/images3_pi/2025/02/26/8a/17405637564a6e61d87e8964d52e163825204560ca.jpg', 1, 4.07, 'pending', '2026-04-06 15:49:58', ''),
(350, 4, 'DAZY تي شيرت كاجوال للنساء بياقة دائرية وأكمام قصيرة بلون واحد', 'I81al2j3orou', 'https://img.ltwebstatic.com/images3_pi/2025/01/22/3b/1737508220984b63fba0da57231ed26361963038b0.jpg', 1, 4.82, 'pending', '2026-04-06 15:49:58', ''),
(351, 4, 'صنادل نسائية عصرية ذات كعب عالي رفيع مفتوحة من الأمام، مصنوعة من شبكة صيفية، تصميم بسيط وشامل للمناسبات الرسمية، أصابع القدم مدببة وأنيقة', 'I215tzrckgi8', 'https://img.ltwebstatic.com/images3_spmp/2024/12/04/46/1733317448c5af936c00e642fde12ba02ec8934e25.jpg', 1, 12.25, 'pending', '2026-04-06 15:49:58', ''),
(352, 4, 'SHEIN PETITE بنطلون كاجوال للنساء بخطوط جانبية سوداء مع خصر مطاطي، فضفاض وعملي', 'I4bakg70s8ev', 'https://img.ltwebstatic.com/v4/j/pi/2025/09/18/4f/17581954474d54fce616cb39464dc15cbfd3f0b8d3.jpg', 1, 10.00, 'pending', '2026-04-06 15:49:58', ''),
(353, 4, 'تي شيرت كاجوال للنساء بياقة مستديرة وأكمام قصيرة بطباعة ألوان متباينة', 'I35qib2ccu0f', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/16/52/1750042123655a36ff9e09a9ad6782f14f6bcebc73.jpg', 1, 4.57, 'pending', '2026-04-06 15:49:58', ''),
(354, 4, 'Joudiya بنطلون طويل أساسي بلون سادة للنساء، صيفي رمضان', 'I0803uxe9lmt', 'https://img.ltwebstatic.com/v4/j/pi/2025/04/27/cc/174571761929205c8b5cf15c878607796b9c5282c7.jpg', 1, 11.45, 'pending', '2026-04-06 15:49:58', '');
INSERT INTO `item_details` (`id`, `item_id`, `item_code`, `serial`, `image`, `qty`, `price`, `status`, `created_at`, `size`) VALUES
(355, 4, 'صنادل نسائية مقاس كبير ذات كعب عالي أبيض مربع الأصبع، صنادل كاجوال من الجلد سهلة الارتداء للشاطئ، أحذية صيفية عصرية للخارج', 'I08kqrona5a1', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/11/ee/174695683030da7c7b2ba76a430d9bdac1013f50c5.jpg', 1, 9.69, 'pending', '2026-04-06 15:49:58', ''),
(356, 4, 'UREREM مجموعة جاكيت رقبة دائرية وبنطلون واسع الساق بتصميم عتيق، أسلوب مدينة كاجوال ومريح، قماش منسوج 170 جرام للصيف', 'I16kcufdwwe4', 'https://img.ltwebstatic.com/images3_spmp/2025/03/20/90/17424682868778eebc47d143030072407e59974810.jpg', 1, 19.97, 'pending', '2026-04-06 15:49:58', ''),
(357, 4, 'SHUZIA احذية مفتوحة الأصابع للسيدات ذات كعب منحني شفاف، صنادل عصرية', 'I74hbts0n5fg', 'https://img.ltwebstatic.com/v4/j/pi/2026/02/18/9f/1771377947385ba0b03f4b5e78e98a7c2dba3ed97c.jpg', 1, 15.71, 'pending', '2026-04-06 15:49:58', ''),
(358, 4, 'فستان ماكسي أنيق بأكمام بلا أكمام وخصر مفلفل بلون أحادي لربيع/صيف 2026، فستان ماكسي أنيق للنساء، ملابس شارع عصرية، فستان ربيعي، ملابس حفل موسيقي، ملابس عطلة للنساء، فستان لضيف الزفاف، ملابس عطلة للنساء، ملابس رأس السنة الجديدة للنساء، فستان حفلة، فستان كا', 'I5ml6gkad8dols', 'https://img.ltwebstatic.com/v4/j/spmp/2026/03/30/0a/1774853197ecc3fd3ce6895b3899bd42a1e1a0beea.jpg', 1, 15.71, 'pending', '2026-04-06 15:49:58', ''),
(359, 4, 'SUMWON طقم بنطلون واسع الساق وقميص مطبوع بالأرجواني، ملابس كاجوال مريحة للبنات', 'I3mm2uroa239s0', 'https://img.ltwebstatic.com/v4/j/sxfs/2026/03/13/f5/1773386268026eccfb14697280071f5c6effdcbb5e.jpg', 1, 10.94, 'pending', '2026-04-06 15:49:58', ''),
(360, 4, 'SUMWON مجموعة كاجوال من بلوزة مطبوع عليها نص مكتوب وبنطلون واسع الساق مع أكمام قصيرة للفتيات، مناسبة للعطلات', 'I0miznhhhbtgvm', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/06/5f/17676804427224120d36ac7c085af720fcff0684b0.jpg', 1, 14.91, 'pending', '2026-04-06 15:49:58', ''),
(361, 4, 'SHEIN طقم قطعتين: توب كاجول بأكمام قصيرة مطبوع بنقشات كرتونية للفتيات، وبنطلون واسع، مناسب للصيف', 'I1947szuhofa', 'https://img.ltwebstatic.com/v4/j/pi/2025/06/05/60/17490962245e6ca4f1cec99936ae9bac6effa47db2.jpg', 1, 5.49, 'pending', '2026-04-06 15:49:58', ''),
(362, 4, 'زوج من صنادل البنات الوردية الحلوة ذات الحزامين القابلة للتعديل، من جلد اصطناعي ناعم، مسامي وغير انزلاقي، مفتوحة الأصابع بتصميم جميل مناسبة للصيف والنزهات والخروج مع الأصدقاء', 'I1czthieqlik', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/26/de/176416556662ab13781a60a97b984391d5b9855424.jpg', 1, 10.50, 'pending', '2026-04-06 15:49:58', ''),
(363, 4, 'SHEIN زي عادي للأطفال الصغار للعودة إلى المدرسة أو الإجازة، يشمل: - تيشرت بياقة مستديرة وأكمام قصيرة بطباعة أشجار النخيل - شورت قماش منسوج مطاطي الخصر مخطط مع جيوب مناسب لحفلات عيد الميلاد، الحفلات، العروض، الحفلات، المدرسة، السفر، الرياضة، الربيع والصيف ', 'I63g5hjvyejk', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/28/a6/1769596965d3e5c976bb1132a4e6036f1fee6e78fb.jpg', 1, 8.26, 'pending', '2026-04-06 15:49:58', ''),
(364, 4, '6 قطع مجموعة بيجاما من قميص كم قصير وشورت بنقوش لطيفة للفتيات الصغيرات من سلسلة المحيط', 'I65d3dlxdmuu', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/16/3e/17658541482955138c63c5446e075af63093810ed7.jpg', 1, 14.91, 'pending', '2026-04-06 15:49:58', ''),
(365, 4, 'بنطلون أبيض للأولاد مع إبزيم في الخصر، مناسب للحفلات والعطلات والتجمعات', 'I373qbawrzwr', 'https://img.ltwebstatic.com/v4/j/pi/2025/06/04/fb/1749004264c12b4bc22e77c76d4ad59c09bc697dfc.jpg', 1, 5.33, 'pending', '2026-04-06 15:49:58', ''),
(366, 4, 'بنطلون أبيض للأولاد مع تصميم إبزيم الخصر، مناسب للحفلات والمهرجانات والتجمعات', 'I2mjs98zjixaqn', 'https://img.ltwebstatic.com/v4/j/pi/2026/04/01/e5/177503112473400dec8977fbc946316443563be671.jpg', 1, 5.33, 'pending', '2026-04-06 15:49:58', ''),
(367, 4, 'PrepCrw مجموعة ملابس علوية أكمام قصيرة ذو ياقة مخطط أسود وأبيض وبنطلون أبيض لصبي صغير، أنيقة وعصرية للمدرسة والمناسبات الكاجوال والخروجات والمهرجانات في الربيع والصيف، 2 قطعة', 'I236x2d1gvhl', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/25/7a/17666469143bbfae584461ea68d34ee781bd915c15.jpg', 1, 9.59, 'pending', '2026-04-06 15:49:58', ''),
(368, 4, 'SHEIN مجموعة كاجوال 2 قطعة لما الأم والابنة، تي شيرت بياقة دائرية وكتف منخفض وسراويل، طباعة حرفية، ملابس كاجوال مناسبة للارتداء اليومي والمدرسة في الربيع والخريف، عيد الحب، مُطابقة الأم والابنة، ومُطابقة الأخوات', 'I779p0bv2ozf', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/16/f9/17736283088996e88bcea40b9716b7630d2c37c8d2.jpg', 1, 7.72, 'pending', '2026-04-06 15:49:58', ''),
(369, 4, 'CUCCOO BIZCHIC أحذية سهلة الارتداء بكعب أسطواني، عملية وشاملة لعيد الميلاد', 'I07co2rleg9h', 'https://img.ltwebstatic.com/v4/j/pi/2025/04/29/6c/17459179914195e3c071b1fcc197f760654a50a3bd.jpg', 1, 15.71, 'pending', '2026-04-06 15:49:58', ''),
(370, 4, 'SHEIN مجموعة قميص وبنطلون مخطط صيفي عادي للأولاد المراهقين، عبوتان', 'I6cfgrylyszc', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/20/11/1768891498b9fadfe9c8cd47dccca181b4f22cb578.jpg', 1, 8.44, 'pending', '2026-04-06 15:49:58', ''),
(371, 4, 'بلوزة بياقة مكسرة للنساء، لون أبيض أحادي بسيط للارتداء اليومي الكاجوال في الربيع', 'I24ngdm438g9', 'https://img.ltwebstatic.com/images3_pi/2024/12/05/b4/173338252000ad2a53f184f66fb6229d0a0c9a4056.jpg', 1, 9.59, 'pending', '2026-04-06 15:49:58', ''),
(372, 4, 'SHEIN 5 علب سروال داخلي مربعي لأولاد صغار، ملابس داخلية للأولاد من القطن، سراويل داخلية للأولاد الصغار', 'I3iiwx0r1ioa', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/16/16/17736652115f613da0bcd6cb5dc16659d28157fa25.jpg', 1, 8.89, 'pending', '2026-04-06 15:49:58', ''),
(373, 4, 'SHEIN 4 قطعة/مجموعة سراويل داخلية للأولاد البيضاء الأساسية الكاجوال المريحة والقطنية المنفذة للهواء', 'I89awz4ktdvw', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/16/80/1773665418a215514a6813b2ca72e3020696439e03.jpg', 1, 6.92, 'pending', '2026-04-06 15:49:58', ''),
(374, 4, 'قميص أبيض قصير الأكمام للنساء، متعدد الاستخدامات للارتداء اليومي، مناسب لجميع الفصول الصيفية', 'I04k3k8d8pnd', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/27/bb/17457352967511d4d17e18b8efdf4f8a75be408688.jpg', 1, 8.26, 'pending', '2026-04-06 15:49:58', ''),
(375, 4, 'فستان أميرة للبنات الصغيرات من عمر 3 إلى 7 سنوات، طويل الأكمام مع شراشيب من الشبك، لحفلات عيد الميلاد في فصلي الخريف والربيع', 'I33wd30j7418', 'https://img.ltwebstatic.com/v4/j/spmp/2025/08/22/04/1755832950c12f52046d18b16875e33c45e97159f9.jpg', 1, 10.15, 'pending', '2026-04-06 15:49:58', ''),
(376, 4, 'Vintaside Kids فستان شبكي مزهر للبنات، أنيق بطراز الريف، وجميل، متعدد الاستخدامات للربيع/الصيف', 'I89s3ae7mxqz', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/28/a3/176956321801e9018b27413b0fa73c5cd55d9cd700.jpg', 1, 11.19, 'pending', '2026-04-06 15:49:58', ''),
(377, 4, 'مجموعة من قطعتين: بلوزة كم قصير مطبوعة بحرف وشجرة النخيل ، وشورت مجموعة للأولاد', 'I44cjf1kodj1', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/03/e1/174623861033b6b8b81bc18f6bf4f772cdaa46c377.jpg', 1, 7.19, 'pending', '2026-04-06 15:49:58', ''),
(378, 4, 'أحذية شاطئ أطفال صيفية جديدة بطراز بسيط عتيق، صنادل بنات شاطئ، أحذية أولاد أنيقة طرية القاع للخارج، أطفال ورضع', 'I18hiym0j28g', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/07/df/1746630236338e1afe35e4a4fb82da1abea0ebdd03.jpg', 1, 9.54, 'pending', '2026-04-06 15:49:58', ''),
(379, 4, 'Dazy Kids ملابس بنات جينز، عطلة خريفية', 'I53hrhbv8x88', 'https://img.ltwebstatic.com/images3_pi/2025/03/26/37/17429692935d4c291c21972a6a5e7ad7ff5be14a79.jpg', 1, 20.24, 'pending', '2026-04-06 15:49:58', ''),
(380, 4, 'SHEIN Glamorique Kids فستان بنات للبنات الصغيرات بأكمام مكسرة مطرزة وطبقة مزدوجة من الشبك، فستان تنورة خط A فساتين الحزب والإجازة الأميرية', 'I4323n32q7yn', 'https://img.ltwebstatic.com/images3_pi/2024/03/08/a9/1709864565b1cd59d85480c6bab571523dff8f70eb.jpg', 1, 9.05, 'pending', '2026-04-06 15:49:58', ''),
(381, 4, '6 قطع/مجموعة بيجامة قصيرة الأكمام وشورت مطبوعة برسومات الحفارة والتحكم في الألعاب للأولاد، بدلة منزلية خفيفة الوزن', 'I3mjqxjrju3cl9', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/29/cd/1766998468ff6ebaf5767d481d88e8e835206821d0.jpg', 1, 11.95, 'pending', '2026-04-06 15:49:58', ''),
(382, 4, '6 قطع/مجموعة بيجامات صيفية كرتونية للبنات، طقم قصير الأكمام وشورت، بيجامات خفيفة للفتيات الصغيرات، طباعة دب كرتوني وأرنب', 'I784exciakve', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/22/d0/1745298964605fee3f8dbc07d5207aaf150a47e860.jpg', 1, 11.95, 'pending', '2026-04-06 15:49:58', ''),
(383, 4, '6 قطع/مجموعة بيجامة قصيرة الأكمام مع طباعة ديناصور كرتوني ومتحكم ألعاب للأولاد، بدلة منزلية خفيفة الوزن', 'I1mjgueey9uywh', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/22/08/1766370124185131c56fe98a22afe7f7762d43b41c.jpg', 1, 11.95, 'pending', '2026-04-06 15:49:58', ''),
(384, 4, 'Playful Pals مجموعة من قطعتين للأطفال الصغار: ملابس علوية كاجوال مريحة بطبعة جرافيك وياقة دائرية وشورت مخطط، مناسبة للعب في الخارج والارتداء اليومي في الربيع والصيف', 'I5anakzoi47h', 'https://img.ltwebstatic.com/v4/j/pi/2025/08/18/a1/1755482736c8107a74cfd0cb67dd62783ee1830877.jpg', 1, 6.66, 'pending', '2026-04-06 15:49:58', ''),
(385, 4, 'SHEIN طقم قميص كاجوال قصير الأكمام وسروال ضيق للأطفال الصغار مزين برسومات القطط والحيوانات الكرتونية الجميلة', 'I2bmmxexg4rc', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/24/5f/1766566310e6e2f53e7271fe5aa79e2f5d6be7793b.jpg', 1, 6.20, 'pending', '2026-04-06 15:49:58', ''),
(386, 4, 'SHEIN Explorewe تيشرت مطبوع برسم الدب مع إزار قياسي 2 قطعة، طقم ملابس كاجوال أنيق ومزخرف بطبعات زهور ملونة للفتيات', 'I972zy8254o3', 'https://img.ltwebstatic.com/images3_pi/2025/03/06/40/17412208602558de2ec15ef7b4aad4623f509cc14f.jpg', 1, 5.98, 'pending', '2026-04-06 15:49:58', ''),
(387, 4, 'EMERY ROSE مجموعة قميص وتنورة للنساء لون سادة للعطلات الاستجمامية، 2 قطعة', 'I314gkqw49z7', 'https://img.ltwebstatic.com/v4/j/pi/2025/07/09/07/1752028918170cffdd574d0756e8babd9ea0311cc2.jpg', 1, 14.91, 'pending', '2026-04-06 15:49:58', ''),
(388, 4, 'Siren Gaze بدلة كاجوال للنساء تتكون من قميص ذو طيات وبنطلون، لونين سادة', 'I2mk5h5z00p6xp', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/19/d5/1768787475d5055502579ce1d5055b7e8be0f001a3.jpg', 1, 13.85, 'pending', '2026-04-06 15:49:58', ''),
(389, 4, 'مجموعة مكونة من قطعتين من قمصان رياضية كاجوال للأولاد الصغار وبنطلونات بيضاء طويلة بياقات دائرية مخططة وبأسلوب ياباني وكوري فضفاض، مناسبة للأطفال للاستخدام اليومي، للمدرسة، للسفر، للرياضة، للربيع والصيف، وللمناسبات مثل أعياد الميلاد، الحفلات المسائية، الح', 'I09khq11l5f4', 'https://img.ltwebstatic.com/v4/j/pi/2026/02/02/61/177001783936eb64c4113571955adbcaf6c56f2c08.jpg', 1, 7.46, 'pending', '2026-04-06 15:49:58', ''),
(390, 4, 'SHEIN مجموعة مكونة من قطعتين: بلوزة بسوست مع غطاء للرأس وشريط واسع مزخرف ، وشورت من قماش منسوج أسود بتصميم سهل ومريح للاستخدام اليومي للصبي الصغير', 'I64tiemq87a8', 'https://img.ltwebstatic.com/images3_pi/2025/02/08/db/173898218368afb41b70d250a7ef7bf2dec19ae23a.jpg', 1, 10.65, 'pending', '2026-04-06 15:49:58', ''),
(391, 5, 'فستان أنيق بأكمام طويلة مزود بياقة قميص للفتيات الناشئات، تصميم مكون من قطعتين، مناسب للارتداء اليومي والرسمي في فصول الربيع والخريف والشتاء', 'sk2409118240043092', 'https://img.ltwebstatic.com/v4/j/pi/2025/06/27/fd/1750989601d6ff26456210ae7a6e972893bb66dda4.jpg', 5, 14.11, 'pending', '2026-04-07 07:20:23', ''),
(392, 5, 'سوار مضفر بزخرفة تاج فاخر من الفولاذ المقاوم للصدأ للرجال قطعة واحدة، مناسب للاستخدام اليومي، هدية مثالية لأعياد ميلاد صديق صبي أو صديق', 'sj2405072316170705', 'https://img.ltwebstatic.com/images3_spmp/2024/05/17/3d/1715949678db86b60ea800ab22a9272c27a3a0a670_square.png', 3, 3.99, 'pending', '2026-04-07 07:20:23', ''),
(393, 5, 'سوار مضفر بزخرفة تاج فاخر من الفولاذ المقاوم للصدأ للرجال قطعة واحدة، مناسب للاستخدام اليومي، هدية مثالية لأعياد ميلاد صديق صبي أو صديق', 'sj2405072316170705', 'https://img.ltwebstatic.com/images3_spmp/2024/05/17/3d/1715949678db86b60ea800ab22a9272c27a3a0a670_square.png', 1, 3.99, 'pending', '2026-04-07 07:20:23', ''),
(394, 5, 'ساعة نسائية موضة، مزينة بفراشة، قرص دائري مرصع بالراين ستون، حركة كوارتز بسيطة، مناسبة للارتداء اليومي، هدية عيد ميلاد، حفلة، عطلة، خيار جودة', 'sj25101569692082725', 'https://img.ltwebstatic.com/v4/j/spmp/2026/03/06/b7/1772786279710855bc3314e70262aea2cde30e8e68.jpg', 5, 3.01, 'pending', '2026-04-07 07:20:23', ''),
(395, 5, '6 قطع / مجموعة معدن خاصرة مشبك ألومنيوم مع دبابيس، ديكور ماس وفراشة حديث، اكسسوار خاصرة للمنزل، مناسب للنساء والفتيات لتضييق خصر البنطلون والزينة (4/6/1 قطعة)', 'sh2411293162152332', 'https://img.ltwebstatic.com/images3_spmp/2024/11/29/b4/17328639620323304fbfbc8304dc8196b870a3c7ea.jpg', 1, 1.33, 'pending', '2026-04-07 07:20:23', ''),
(396, 5, 'حزام سلسلة مزين بالزهور والخرز الاصطناعي للحفلات والهالوين والصيف والمدرسة والخريف', 'sc2302107081814412', 'https://img.ltwebstatic.com/images3_pi/2023/02/14/1676372848d1f813766ab84286551890dcda50f8c8.jpg', 1, 2.13, 'pending', '2026-04-07 07:20:23', ''),
(397, 5, '1 قطعة مشبك شعر نسائي جديد بتصميم فراشة كبيرة مطرزة بخرز وشبكة، تاج رأس حلو مناسب للتصوير، إكسسوارات شعر شتوية، مشبك شعر عادي لعيد الحب، هدية إكسسوارات عيد الحب، مشبك أنيق للشاطئ والعطلات الصيفية', 'sc25042009959690966', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/25/4b/17640413726d37a9a536265e0ae10e55cdd5002378.jpg', 8, 1.86, 'pending', '2026-04-07 07:20:23', ''),
(398, 5, 'طقم قلادة إينامل بتصميم فراشة بيضاء، قلادة خونرة عالية الجودة أنيقة وعصرية وبسيطة', 'sj2408117888056750', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/13/df/1749791439600d8a1b995f186aac2edc8f3858074a.jpg', 1, 1.60, 'pending', '2026-04-07 07:20:23', ''),
(399, 5, '24 ملصق أظافر على شكل زهور، أظافر جل ثلاثية الأبعاد بشكل لوز، إنشاء أظافر زهرية زرقاء، تصميم ديكور اللؤلؤ، أظافر أكريليك فرنسية للضغط، مجموعة أظافر مزيفة مناسبة للارتداء لفترة طويلة، تشمل: 1 جل جيلي و 1 ملف أظافر، سهلة الارتداء، فن أظافر الزهور، مناسبة لأ', 'sb25042181865745850', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/14/b4/1749883788a6cce847ae5cf386a5cf34c5a8446a1e.jpg', 4, 1.60, 'pending', '2026-04-07 07:20:23', ''),
(400, 5, 'خاتم مفتوح قابل للتعديل بلؤلؤ صناعي للنساء، أسلوب حداثة الموضة', 'sj2310141344608800', 'https://img.ltwebstatic.com/images3_spmp/2024/01/04/b1/17043380676f5530826b72e081e6f40524557804f4.jpg', 1, 1.07, 'pending', '2026-04-07 07:20:23', ''),
(401, 5, 'ROMWE حزام سلسلة مزخرف بفراشة', 'rc2211221116151129', 'https://img.ltwebstatic.com/images3_pi/2022/12/07/16703790559487bffaf42d81abf17371f7d9b8f9f4.jpg', 1, 2.93, 'pending', '2026-04-07 07:20:23', ''),
(402, 5, 'ساعة يد نسائية فاخرة صغيرة الحجم بعقارب مربعة من الفولاذ المقاوم للصدأ بطراز عتيق، ساعة كوارتز أنيقة وبسيطة مناسبة للارتداء اليومي والمناسبات', 'sj25092189924929095', 'https://img.ltwebstatic.com/v4/j/spmp/2026/02/04/28/17701902976840e25cfc552b6616946be784d107d3.jpg', 1, 5.59, 'pending', '2026-04-07 07:20:23', ''),
(403, 5, 'دبوس وشاح من اللؤلؤ الاصطناعي، إكسسوار عملي يمكن تثبيته على الأوشحة والسترات والجواكت لمنع تلف الملابس، أنيق وعملي', 'sh260115204511034888041', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/15/16/176848164565da1fc3f4f33fa81983f7762bbd8e4e_square.jpg', 1, 1.01, 'pending', '2026-04-07 07:20:23', ''),
(404, 5, 'دبوس وشاح من اللؤلؤ الاصطناعي، إكسسوار عملي يمكن تثبيته على الأوشحة والسترات والجواكت لمنع تلف الملابس، أنيق وعملي', 'sh260115204511034888041', 'https://img.ltwebstatic.com/v4/j/spmp/2026/01/15/16/176848164565da1fc3f4f33fa81983f7762bbd8e4e_square.jpg', 1, 1.01, 'pending', '2026-04-07 07:20:23', ''),
(405, 5, 'سوار أنيق مزين باللؤلؤ والراين للبنات قطعة واحدة', 'sk25052272386256258', 'https://img.ltwebstatic.com/v4/j/spmp/2025/08/11/65/1754896040f35def61a0c07386f2eb27b346fcad42.jpg', 1, 1.60, 'pending', '2026-04-07 07:20:23', ''),
(406, 5, 'قلادة أنيقة وعصرية بتصميم على شكل حرف Y متعددة الطبقات، مناسبة للارتداء اليومي للنساء، هدايا مجوهرات للخطوبة، قلادات زفاف للارتداء في عيد الحب', 'sc25022065075427387', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/01/63/1746068187bf25f2fbd0a71319b1a9006907c67a51.jpg', 1, 1.33, 'pending', '2026-04-07 07:20:23', ''),
(407, 5, 'Modelyn فستان حفلة أنيق مع أكمام متسعة، مزين بالراين ستون، قماش متنوع، مخصر عند الخصر', 'sz25061391808265551', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/06/2f/1772763332279a0e0c6c0a4a0601384fb19676c8be.jpg', 1, 19.44, 'pending', '2026-04-07 07:20:23', ''),
(408, 5, 'قطعة واحدة من أساور إصبع نسائية عصرية وبسيطة، سوار سلسلة بسيط، مناسب للارتداء اليومي للنساء، كذلك هدية رائعة للمناسبات (سلسلة مصنوعة يدويًا مقطعة حسب المقاس، عدد متغير من الخرز، حجم متغير من الراين)', 'sj25021744349195132', 'https://img.ltwebstatic.com/images3_spmp/2025/02/17/70/1739754577cd2e941ac7216a7d7c1f8941bc3e2b26.jpg', 1, 1.33, 'pending', '2026-04-07 07:20:23', ''),
(409, 5, '1 قطعة خاتم مفتوح من الزركونيا ذو صفين، مناسب للارتداء اليومي', 'sj2204127444649805', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/04/9d/17569744076102e9324802fe1d30b5241b423fe920.jpg', 1, 1.86, 'pending', '2026-04-07 07:20:23', ''),
(410, 5, 'زوج أقراط زهرية بسيطة من الاكريليك للنساء (ألوان البتلات عشوائية)', 'sj25013127734697359', 'https://img.ltwebstatic.com/images3_spmp/2025/01/31/22/17383052683a96c9baf1c0744f08411e1c8c7b9ca4.jpg', 1, 2.40, 'pending', '2026-04-07 07:20:23', ''),
(411, 5, '1 سوار لسيدة بتصميم فريد من اللؤلؤ البروكات الحظ بشكل قلب، إكسسوار مجوهرات راقية', 'sj25040149373828308', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/01/c5/1743490025696e39bdb61ccde8c1443a7ca30684d0.jpg', 1, 1.60, 'pending', '2026-04-07 07:20:23', ''),
(412, 5, '1 مجوهرات زهرة سوار القفازات', 'sj2306262200097077', 'https://img.ltwebstatic.com/images3_spmp/2023/06/26/1687757754d05bc0f83e8deb1b96ca770bbc1e1155.jpg', 1, 1.60, 'pending', '2026-04-07 07:20:23', ''),
(413, 5, 'طقم مكون من 4 قطع (قلادة، أقراط، خاتم، سوار) مرصع بالكريستال بتصميم التاج، اكسسوارات الزفاف / العروس للاحتفالات والأعياد والعروض الفنية، اكسسوارات الشعر (حجاب العروس)رمضان', 'sj2406203796306351', 'https://img.ltwebstatic.com/images3_spmp/2024/06/20/d5/1718892733c36d19e80a35d0a0f1b1d2d2eb53d68b.jpg', 1, 4.59, 'pending', '2026-04-07 07:20:23', ''),
(414, 5, 'Yasmyna جلابيات قفاطين فستان ماكسي تركي للنساء والعباءة العربية التقليدية', 'sz25031183298506046', 'https://img.ltwebstatic.com/v4/j/pi/2025/08/20/dc/17556691777d147f67a331a0f607331329edd57ecc.jpg', 1, 19.44, 'pending', '2026-04-07 07:20:23', ''),
(415, 5, 'Yasmyna فستان ماكسي تركي للنساء والعباءة العربية التقليدية', 'sz25031183298532047', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/11/85/17654254269bed9f0539b614cd6fee6d11c5539b4c.jpg', 1, 19.71, 'pending', '2026-04-07 07:20:23', ''),
(416, 5, 'Yasmyna جلابيات قفاطين فستان أنيق للنساء بياقة على شكل حرف V وأكمام طويلة مزين بنقشة من الترتر على شكل فراشة', 'sz25031183298595441', 'https://img.ltwebstatic.com/v4/j/pi/2025/10/27/ef/176156083408668f828e6d3c557359065fce969bd1.jpg', 1, 19.97, 'pending', '2026-04-07 07:20:23', ''),
(417, 5, '24 قطعة أظافر مزيفة مزينة بالراين ستون الذهبي ثلاثي الأبعاد غير متماثل ذات طراز عصري رجعي، تعزز مظهرك بأناقة وأناقة. مناسبة للفتيات والسيدات الأنيقات والأنيقات للاستخدام اليومي. ملصقات أظافر للضغط عليها، لوازم فن الأظافر', 'sb2408276428433304', 'https://img.ltwebstatic.com/images3_spmp/2024/09/11/f2/1726051650465d0fe3a52764dfe4aef0766bb9e9ae.jpg', 1, 1.86, 'pending', '2026-04-07 07:20:23', ''),
(418, 5, '3 قطع طقم مجوهرات قلادة + أقراط أنيقة للنساء، تصميم معدني مجوف أنيق بزهور وفراشات مع خرز اصطناعي، قلادة طويلة، إكسسوارات متعددة الاستخدامات', 'sj25052605292672983', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/26/a8/17482315162d88e8cfe25d34873158d987d01630f2.jpg', 1, 2.66, 'pending', '2026-04-07 07:20:23', ''),
(419, 5, 'مشبك شعر كبير بشكل فراشة وردية للنساء، إكسسوارات شعر أنيقة', 'sc251211203095091493559', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/11/8c/17654562686e638f0232b7e55cab9c4c71677558f4.jpg', 1, 1.60, 'pending', '2026-04-07 07:20:23', ''),
(420, 5, 'سوار نسائي بتصميم هندسي ملون من الزركونيا، عصري وطازج للصيف قطعة واحدة', 'sj25051527452281883', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/11/5f/175755743544ded686f657aa1174f71ff4661170a6.jpg', 1, 1.86, 'pending', '2026-04-07 07:20:23', ''),
(421, 5, 'مشبك شعر فراشة مزين باللؤلؤ والراين كبير الحجم للشعر المضفر، باللون الوردي، مناسب للاستخدام اليومي والحفلات وعيد الحب، اكسسوارات شعر للنساء للاستخدام في الشاطئ والعطلات الصيفية', 'sc2406154260820066', 'https://img.ltwebstatic.com/images3_spmp/2024/06/15/c4/171845741186ea34fc5a17efb79f8c8fc7c2b72105.jpg', 1, 1.61, 'pending', '2026-04-07 07:20:23', ''),
(422, 5, 'مشبك شعر كبير مزين بالخرز الاصطناعي والراين بشكل فراشة، أنيق وجذاب للكعكة، اكسسوار وردي مناسب للخروجات اليومية والمناسبات، عيد الحب، اكسسوارات الشعر، مشبك شعر، مشبك فك، مشبك شعر، مشبك فك، للملابس الصيفية والشتوية للنساء', 'sc2406154260804229', 'https://img.ltwebstatic.com/images3_spmp/2024/10/25/36/1729864410ac429f31ba7cf6ecc35ca937b944baa0.jpg', 1, 1.86, 'pending', '2026-04-07 07:20:23', ''),
(423, 5, 'Andkiss سوار من الخرز المرصع بزخرفة اللؤلؤ الاصطناعيرمضان', 'sw2106212716289831', 'https://img.ltwebstatic.com/images3_pi/2022/10/10/1665369418c45d5e1cedac41e6cdfa1e6c3fc7c9e8.jpg', 1, 1.33, 'pending', '2026-04-07 07:20:23', ''),
(424, 5, 'Al Najma رمضان فستان عربي أنيق بأكمام طويلة مطرز بطبعات زهرية على طوق الياقة، مصنوع من نسيج جاكار مُنسوج باللون الأخضر', 'sz251113250953263900', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/13/2d/17682927724395cd6c383ec717d14a08e015021a1c.jpg', 1, 23.17, 'pending', '2026-04-07 07:20:23', ''),
(425, 5, '30 قطعة من ملصقات أظافر أكريليك على شكل لب/قلب لون أحمر بشكل لوز متوسط الحجم، طقم أظافر صناعية ثلاثية الأبعاد بزخرفة فيونكة، مناسبة لصالونات الأظافر والفتيات والنساء للاستخدام اليومي والمناسبات والهدايا', 'sb260228105241655498835', 'https://img.ltwebstatic.com/v4/j/spmp/2026/02/28/ab/1772247189f629dbf8cd3a6e53fb3f726e5c508a79.jpg', 1, 1.60, 'pending', '2026-04-07 07:20:23', ''),
(426, 5, '24 ملصق أظافر جل زهري ثلاثي الأبعاد بشكل اللوز، تصميم فرنسي أبيض، مناسب لمجموعة أظافر أكريليك، يتضمن 1 جل جيلي و 1 ملف أظافر، مناسب للصيف، DIY للنساء والفتيات لاستخدام يومي، العمل، الدراسة والحفلات', 'sb260224154610627879677', 'https://img.ltwebstatic.com/v4/j/spmp/2026/02/24/31/1771919224073bc9feecc0d5abbb98e8c100d2c1d2.jpg', 1, 1.74, 'pending', '2026-04-07 07:20:23', ''),
(427, 5, 'مجموعة مجوهرات نسائية جديدة لصيف أسلوب الريف العطلة، بقلادة زهرة مينا زرقاء غير متماثلة ، أقراط زوج واحد ، خاتم واحد ، سوار واحد (باستثناء علبة الهدية)', 'sj25030841616721321', 'https://img.ltwebstatic.com/images3_spmp/2025/03/09/ca/1741484333c9200890c21d55e31d80c544fed4492b.jpg', 1, 5.33, 'pending', '2026-04-07 07:20:23', ''),
(428, 5, 'مجموعة من قطعة عقد بشكل زهري متناسق وأقراط وخاتم وسوار، طقم مجوهرات نسائية (لا يشتمل على علبة هدايا)', 'sj25030841616770555', 'https://img.ltwebstatic.com/images3_spmp/2025/03/09/4c/1741484334d516f792863c1a0630d89b59e1fb7ff0.jpg', 1, 4.53, 'pending', '2026-04-07 07:20:23', ''),
(429, 5, 'طقم مجوهرات للنساء مكون من: 1 قلادة بتعليقة زهرة وردية متدرجة الطبقة غير متماثلة مصنوعة يدويًا، 1 زوج من الأقراط، 1 خاتم، 1 سوار، 1 أسورة (بدون علبة هدايا)', 'sj25030916268635832', 'https://img.ltwebstatic.com/v4/j/spmp/2025/07/21/b5/17530702941ecac11257f54619f4bbe669d8c302cb.jpg', 1, 5.06, 'pending', '2026-04-07 07:20:23', ''),
(430, 5, 'ساعة كوارتز أنيقة للنساء 1قطعة بسلسلة قابلة للتعديل ذات خرز ذهبي، علبة بلون الذهب الوردي، وقرص أم اللؤلؤ المنسوج، مناسبة للمناسبات الرسمية', 'sj2406081900015875', 'https://img.ltwebstatic.com/images3_spmp/2024/08/16/30/172377662426a24841dbb90ff3654f11c0ba081239_square.jpg', 1, 2.61, 'pending', '2026-04-07 07:20:23', ''),
(431, 5, 'ساعة سوار للنساء برؤية كريستال مقطوع ماس وخرزة كبيرة واحدة، ساعة كوارتز بسيطة', 'sj25040785207461466', 'https://img.ltwebstatic.com/v4/j/spmp/2025/07/24/56/1753336111450ad60ce13a2e300e733288948a609d_square.jpg', 1, 3.20, 'pending', '2026-04-07 07:20:23', ''),
(432, 5, 'زوج أقراط حلقية على شكل C مزين بالخرز الصناعي ذو تصميم راقي فاخر مناسب للنساء في الأناقة الشخصية والأحداث والحفلاترمضان', 'sj2412111338133934', 'https://img.ltwebstatic.com/images3_spmp/2024/12/11/a9/1733904585703f8456c0ff943307d1fc2891f47ac3.jpg', 1, 1.07, 'pending', '2026-04-07 07:20:23', ''),
(433, 5, 'خاتم مرصع بالزركونيا المكعبة والخرز الاصطناعي، هدية مجوهرات للنساء في عيد الزفاف والذكرى السنوية', 'sj2310108441157563', 'https://img.ltwebstatic.com/images3_spmp/2023/10/10/ef/169690286238496d73e59ce2945a40b1870d0efbdc.jpg', 1, 1.86, 'pending', '2026-04-07 07:20:23', ''),
(434, 5, 'SHEIN بنطلون جينز أزرق فينتاج مبطن حراريًا مع خصر غير متماثل فضفاض، للفتيات، مناسب للخريف والشتاء، أنيق للفتيات في', 'sk2408061256442033', 'https://img.ltwebstatic.com/images3_pi/2025/02/24/b5/174037488761aeb9927e1e7ee80808554dccada329.jpg', 1, 12.25, 'pending', '2026-04-07 07:20:23', ''),
(435, 5, 'SHEIN بنطلون جينز لفتاة يافعة بيت Y2K كاجول متهالك أزرق قصمية فضفاض، بنطلون جينز كاجوال فضفاض للبنات للربيع والصيف للأيام العطلة', 'sk2411131157577615', 'https://img.ltwebstatic.com/images3_pi/2025/02/24/33/1740396700443b4ce098a5663bf7c2d5eff3cf1d8c.jpg', 1, 13.05, 'pending', '2026-04-07 07:20:23', ''),
(436, 5, 'مجموعة قبعة شمسية للفتيات بطبعات زهور وحقيبة 2 قطعة، مناسبة للزي الربيعي / الصيفي الخاص بالعطلات، لبس اليومي، حماية من الأشعة فوق البنفسجية', 'sk2405128876605932', 'https://img.ltwebstatic.com/images3_spmp/2024/05/12/ea/17155033887ac38e8c26130bb399795935a9c7f99a.jpg', 1, 3.36, 'pending', '2026-04-07 07:20:23', ''),
(437, 5, 'قميص تي شيرت بدون أكمام بتصميم أشجار وشورت هاواي مرن الخصر قطعتان للأولاد', 'sk2405174517255599', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/30/3b/1745991752e4264087d36baf6a218875a5ceec0055.jpg', 1, 6.26, 'pending', '2026-04-07 07:20:23', ''),
(438, 5, 'صنادل كعب عالي للبنات، أحذية بريق قوس للأطفال للمناسبات الرسمية والحفلات والعروض المسرحية', 'sk25011828196044438', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/18/02/17634686494056d68532eca705f1aaa7d963b12c64.jpg', 1, 18.38, 'pending', '2026-04-07 07:20:23', ''),
(439, 5, 'قبعة شمسية وحقيبة أطفال الأجزاء تحتوي على طبعة فراشة كرتونية، قبعة شاطئ قطنية لطيفة للأولاد والبنات في الحياة اليومية أو العطلات', 'sk2402250968009260', 'https://img.ltwebstatic.com/images3_spmp/2024/02/25/cb/1708870827caa28f8ed5033756986bc24a21ac1119.jpg', 1, 5.38, 'pending', '2026-04-07 07:20:23', ''),
(440, 5, 'SHEIN تي شيرت أنيق بأكمام قصيرة بطبعة ديناصور لصبي المراهقين، مجموعة مطبوعة بتصميم الديناصور مكونة من قطعتين مناسبة للصيف', 'sk25061255161341531', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/26/2f/1766749927f3b8f8c3b28d2ba1055b8ba94b83f539.jpg', 1, 7.99, 'pending', '2026-04-07 07:20:23', ''),
(441, 5, 'SHEIN مجموعة قميص كاجوال ذو رقبة دائرية وشورت للأولاد المراهقين 2 قطعة، بتصميم بسيط، صيفي', 'sk25040899886888958', 'https://img.ltwebstatic.com/v4/j/pi/2025/09/16/c6/17579872791775e90945cc1cf106325a8125136c6b.jpg', 1, 8.26, 'pending', '2026-04-07 07:20:23', ''),
(442, 5, 'SHEIN توب ملابس علوية آزرق وأصفر بطبعة ظل أشجار النخيل وألوان الغروب المناسب للشباب، مناسب للصيف والشاطئ والعطلات والأنشطة الخارجية', 'sk25051966060666471', 'https://img.ltwebstatic.com/v4/j/pi/2025/05/23/59/17479383252ae218ab5fa6498365283b189e7fd3fa.jpg', 1, 4.53, 'pending', '2026-04-07 07:20:23', ''),
(443, 5, 'SHEIN مايوه طقم متكامل بطبعات استوائية واحدة للفتيات، مع معطف كيمونو.', 'sk2212295153386003', 'https://img.ltwebstatic.com/images3_pi/2023/02/15/1676460900e61314639464b686301572207df00c33.jpg', 1, 8.26, 'pending', '2026-04-07 07:20:23', ''),
(444, 5, 'SHEIN مجموعة ملابس علوية كاميسول مطرز ثلاثي الأبعاد وبقصة غير متماثلة مع بنطلون كاجوال طويل للفتيات في الصيف، قطعتين', 'sk25031160720281563', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/28/e3/17695659618f58d3420a8a9e0c884f836718b81521.jpg', 1, 7.72, 'pending', '2026-04-07 07:20:23', ''),
(445, 5, 'SHEIN زي شاطئي لطفلة، ملابس علوية بلا أكمام مريح مطاطي مع بنطلون واسع الأرجل ، صيف / شتاء', 'sk2402282354238549', 'https://img.ltwebstatic.com/images3_pi/2024/04/28/2b/1714289343bb603c4b7dcf11f236012c0eae32076c.jpg', 1, 6.39, 'pending', '2026-04-07 07:20:23', ''),
(446, 5, '3 قطع طقم بنات مراهقات مكون من ملابس علوية كامي مطبوع عليه حرف بروكلين + ملابس علوية شبكية + شورت، طقم صيفي عصري للخارج، مناسب كهدية صيفية', 'sk2406271937703572', 'https://img.ltwebstatic.com/v4/j/spmp/2026/04/05/98/1775373947f21ef138a3b28b028addd2af5ceab309.jpg', 1, 9.32, 'pending', '2026-04-07 07:20:23', ''),
(447, 5, 'SHEIN 2 قطعة / مجموعة طقم ملابس نسائية رياضي كاجوال، تشمل: تيشيرت جرافيك 56 مطبوع عليه شعار \"كل يوم مميز\" وأكمام ملونة متباينة، شورت دراجة متناسق، مناسب للصيف، الرياضة، اللياقة البدنية، التسوق والأنشطة الاجتماعية', 'sk25051042369836514', 'https://img.ltwebstatic.com/v4/j/pi/2025/05/19/da/17476361855223c2bf386eb1c4773cc668a1db3d74.jpg', 1, 5.59, 'pending', '2026-04-07 07:20:23', ''),
(448, 5, 'حقيبة يد أنيقة مزينة بالجليتر وتقليد اللؤلؤ للحفلات المسائية', 'sk2307135121557554', 'https://img.ltwebstatic.com/images3_spmp/2023/07/13/16892273490a90d1d4051c7274d5219f3050974fc2.jpg', 1, 6.66, 'pending', '2026-04-07 07:20:23', ''),
(449, 5, 'نظارات شمسية رائجة وعصرية للأطفال الذين تتراوح أعمارهم بين 4-10 سنوات، ذات إطار مربع كبير وإطارات \"Love\" عالية الجودة ومتعددة الاستخدامات ومناسبة للخروجات اليومية ولضروريات الارتداء', 'sk2404155459473568', 'https://img.ltwebstatic.com/images3_spmp/2024/04/15/2e/1713158753ef2ccb229458ab3eda24d3a68056194c.jpg', 1, 5.06, 'pending', '2026-04-07 07:20:23', ''),
(450, 5, '1 قطعة من الإكسسوارات الزخرفية المتفكّكة بألوان كرتونية صلبة مصنوعة من السيليكون، مناسب للحقيبة اليدوية وحقيبة الشاطئ والاستخدام الخارجي وألعاب الشاطئ وأيضًا كهدية عيد ميلاد', 'sk25041529122089615', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/15/e2/1744707522f9609fe626805b5b526c0c933b98dd17.jpg', 1, 4.26, 'pending', '2026-04-07 07:20:23', ''),
(451, 5, 'مجموعة مشط مربع وزجاجة رذاذ 7 قطع، مشط بلاستيكي مضاد للكهرباء الساكنة بطباعة برج إيفل الكرتونية، مشط شعر محمول بنمط، زجاجة رذاذ ضغط عالي، مناسبة للمراهقين وأنواع الشعر العادية، مقبض ABS متين، تصميم مربع جميل، مجموعة أدوات تصفيف الشعر', 'sk25041437494702210', 'https://img.ltwebstatic.com/v4/j/spmp/2026/04/05/b3/1775358276e06a57ef0db7bba3951aec31648ac84f.jpg', 1, 5.33, 'pending', '2026-04-07 07:20:23', ''),
(452, 5, 'فستان صيفي للبنت الصغيرة بطبعة زهرية وحواف مكرمشة مع أشرطة مربعة، تصميم منعش، ضروري الامتلاك', 'sk2407110448472245', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/21/e7/1745227156a12df0e6670b89892d2392aad94e0663.jpg', 1, 6.39, 'pending', '2026-04-07 07:20:23', ''),
(453, 5, 'زوج من صنادل رياضية للأطفال اللون الخاكي، أحذية شاطئ للأطفال الصغار، أحذية صيفية عادية للمشي للرضع، نعال ناعمة وجميلة', 'sk251113925399692023', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/13/8f/1762969391367d70e03857aea333f20acbb876a179.jpg', 1, 6.94, 'pending', '2026-04-07 07:20:23', ''),
(454, 5, 'SHEIN Elladie kids مجموعة من ملابس علوية بدون أكمام طباعة قلب بسيط أمامي وتنورة قصيرة للفتيات الصغيرات، 2 قطعة', 'sk2312295939556658', 'https://img.ltwebstatic.com/images3_pi/2024/11/15/2c/1731650049e9c7ef2239e3ca2c79fb7388bea5b349.jpg', 1, 9.05, 'pending', '2026-04-07 07:20:23', ''),
(455, 5, 'SHEIN 3 طقم بدلة رياضية للبنات مطبوع بطبعة الكاموفلاج والقلوب والزهور والأشكال الهندسية الملونة', 'sk25031312090662626', 'https://img.ltwebstatic.com/v4/j/pi/2025/04/16/42/17447726283472a107c9faf6fd63faee2c3455b698.jpg', 1, 10.39, 'pending', '2026-04-07 07:20:23', ''),
(456, 5, 'شبشب مفتوح الأصبع مريح، صنادل شاطئ خفيفة الوزن وقابلة للتنفس للبنات، مناسبة للأنشطة الخارجية', 'sa2407101714440838', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/21/e0/17452064918e6ccf3725a080249ce7035620ff8632.jpg', 1, 7.90, 'pending', '2026-04-07 07:20:23', ''),
(457, 5, 'حقيبة ظهر أطفال ضد للماء تصميم رسوم كارتون أرنب ديكور', 'sg2206216474420808', 'https://img.ltwebstatic.com/images3_spmp/2023/06/20/1687240838de959733eac5021e8746e23dad6fe588.jpg', 1, 11.19, 'pending', '2026-04-07 07:20:23', ''),
(458, 5, 'بدلة قصيرة لطيفة مطبوعة بنقش الزهور للفتاة الشابة بأكتاف عارية وردية بحاشية مزينة بالريش، مثالي لعطلة الصيف', 'sk2403123450010483', 'https://img.ltwebstatic.com/v4/j/spmp/2026/03/09/38/17730210334b4a9ce71074f52418f763d4454b0df7.jpg', 1, 8.79, 'pending', '2026-04-07 07:20:23', ''),
(459, 5, 'زوج من أحذية الأطفال المسطحة الأنيقة، أحذية أطفال مسطحة جديدة، أحذية بنات مزينة بفيونكة', 'sa2409267491739117', 'https://img.ltwebstatic.com/v4/j/spmp/2025/09/19/48/17582606350cde2b95cd6de498ee022cdf577f1abd.jpg', 1, 10.10, 'pending', '2026-04-07 07:20:23', ''),
(460, 5, 'SHEIN Genkimix Kids مجموعة قميص كامي مطرز ثلاثي الأبعاد وبتصميم غير متماثل مع بنطلون كاجوال للبنات في الصيف، 2 قطعة/مجموعة', 'sk260120185117633051374', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/30/83/1769742423400a5caf5e3e956193bda7fcda5ee547.jpg', 1, 7.72, 'pending', '2026-04-07 07:20:23', ''),
(461, 5, 'بدلة سباحة مطبوعة بأنماط عشوائية لفتاة صغيرة', 'sk25030741719707252', 'https://img.ltwebstatic.com/images3_pi/2025/04/02/6e/174357592689f00930f16eb0c5a42ed699bec83096.jpg', 1, 9.05, 'pending', '2026-04-07 07:20:23', ''),
(462, 5, 'SHEIN طقم بنطال جينز وسترة بلا أكمام بنمط أنيق للفتيات، ملابس خريف/شتاء للأطفال، ملابس عودة للمدرسة وحفلات عودة للمنزل، طقم أنيق قطعتين', 'sk25061964540010881', 'https://img.ltwebstatic.com/v4/j/pi/2026/03/25/da/17744102394c786b59c10e986a608dd5d5152b0ee1.jpg', 1, 16.51, 'pending', '2026-04-07 07:20:23', ''),
(463, 5, 'بدلة سباحة للبنات الصغيرات بكتف واحد وبدون أكمام مع فتحات جانبية وتنورة شبكية. هذه البدلة الأنيقة والكاجوال والأنيقة مثالية للسباحة والعطلات وبدلات السباحة الصيفية للبنات الصغيرات.', 'sk251025169414225951', 'https://img.ltwebstatic.com/v4/j/pi/2025/11/17/b7/1763345428810dae77c3de69a5d7538e17d78c7c54.jpg', 1, 6.13, 'pending', '2026-04-07 07:20:23', ''),
(464, 5, 'SHEIN طقم قميص بستراب شبكي بزخرفة وردية ثلاثية الأبعاد وتنورة بعقدة جميلة لفتاة صغيرة، صيفي بلون صلب 2 قطعة', 'sk2403069370548475', 'https://img.ltwebstatic.com/images3_pi/2024/04/15/0e/1713144589fa569c54a175bd5be73a66791ef0459f.jpg', 1, 12.78, 'pending', '2026-04-07 07:20:23', ''),
(465, 5, 'مجموعة قميص وبنطلون بأكمام قصيرة وياقة طاقم للفتيان المراهقين، بتصميم كاجوال بسيط وأنيق، بطبعات الديناصور والكامفلاج والرسومات اليدوية الجرافيتية، بقصة فضفاضة مريحة وأنيقة', 'sk251216195669433811027', 'https://img.ltwebstatic.com/v4/j/pi/2025/12/23/df/176647079549ad80a831bf5f797f4e752717f6f092.jpg', 1, 9.05, 'pending', '2026-04-07 07:20:23', ''),
(466, 5, 'SHEIN لباس علوي بدون أكمام بطبعة استوائية و تنورة بحافة متموجة لفتاة صغيرة', 'sk2202286810952502', 'https://img.ltwebstatic.com/images3_pi/2022/03/16/1647398699472100c04576acd86c1af132b106e492.jpg', 1, 6.13, 'pending', '2026-04-07 07:20:23', ''),
(467, 5, 'SHEIN لباس علوي علوي بشريط حروف وشورت دولفين لفتاة صغيرة', 'sk2204014942274331', 'https://img.ltwebstatic.com/images3_pi/2022/04/22/1650632082b63b6e23137e9e98aec151bfb0bfbaeb.jpg', 1, 5.86, 'pending', '2026-04-07 07:20:23', ''),
(468, 5, 'نظارات أطفال جميلة بزهور وأذنين دب، بطاقة عرض فقط، بدون شحن', 'sk2406211728171851', 'https://img.ltwebstatic.com/images3_spmp/2025/01/19/e2/17372188488db912c6e5ceef13bb5393ab602ef833.jpg', 1, 3.20, 'pending', '2026-04-07 07:20:23', ''),
(469, 5, '2 قطعة مجموعة ملابس علوية نصف كم مطبوعة بالفراشات وبنطلون جوغر بلون قطعي للفتيات الصغيرات للصيف', 'sk25032959135605059', 'https://img.ltwebstatic.com/v4/j/spmp/2025/04/24/4e/174548682311f7b7a1e8a435132fc67e8b03d9fefb.jpg', 1, 6.13, 'pending', '2026-04-07 07:20:23', ''),
(470, 5, 'SHEIN مجموعة من قطعتين تتكون من قميص كامي مطبوع عليه حرف وشورت مطبوع عليه نجوم، بتصميم عصري ومناسب لفرقة K-POP، مناسب للصيف', 'sk260112155925490737407', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/15/f4/176845761598b79f682008f7ce8c08845eb8602b56.jpg', 1, 4.79, 'pending', '2026-04-07 07:20:23', ''),
(471, 5, 'SHEIN مجموعة ملابس علوية وبنطلون بطبعة أرنب وفهد، ملابس علوية بأكمام قصيرة وياقة دائرية فضفاض وبنطلون ضيق، مناسبة للبنات الصغيرات للارتداء اليومي في الربيع والصيف، للسفر والتنسيق والمنزل والعطلات والخارج والمزرعة والاسترخاء، 2 قطعة/مجموعة', 'sk251230222046467209763', 'https://img.ltwebstatic.com/v4/j/pi/2026/01/08/32/1767863270213d28a6e80f97275cd1e44398d62432.jpg', 1, 6.39, 'pending', '2026-04-07 07:20:23', ''),
(472, 5, 'صنادل خفيفة الوزن وقابلة للتنفس ذات موضة كاجوال مريحة للبنات ، صيفي', 'sk2408208014065615', 'https://img.ltwebstatic.com/images3_pi/2024/08/26/73/172466281336eee9ea615a39f74200e405c31e7b3f.jpg', 1, 8.52, 'pending', '2026-04-07 07:20:23', ''),
(473, 5, 'زوج من صنادل الأميرة ذات الكعب العالي والرجعية للبنات، أحذية شاطئ ذات نعل ناعم، صيفية', 'sa251130021664662543', 'https://img.ltwebstatic.com/v4/j/spmp/2025/11/30/a4/1764493772ebef0b395e7c4b53246d3bf395eb1640.jpg', 1, 7.91, 'pending', '2026-04-07 07:20:23', ''),
(474, 5, 'طقم ملابس علوية كامي بدون أكمام مزينة بالكشكشة + شورت مزين بطبعة زهرة عباد الشمس قطعتين', 'sk2412278611868272', 'https://img.ltwebstatic.com/images3_spmp/2024/12/27/17/1735281753f2e2d73d3942e42004f758f78e3b5700.jpg', 1, 5.86, 'pending', '2026-04-07 07:20:23', ''),
(475, 5, 'زوج حذاء شاطئ فلات لبنات رضع ذهبي لامع، حزام مرصع بالراين ملون ، مصنوع من جلد البو المنسوج ، تصميم ذو فتحة للأصابع ومزين باللؤلؤ والفراشة ، صندل فاخر بتصميم إنزلاقي ، مناسب للبنات الرضع في اليومي ، الكاجوال ، الشاطئ ، الحفلات ، الصيف', 'sk25032919143233088', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/10/f0/1749550617a03a08920383089fe42bdacd0fa10980.jpg', 1, 5.18, 'pending', '2026-04-07 07:20:23', ''),
(476, 5, 'فستان حفلة للفتاة الصغيرة من الدانتيل والتول المزخرف بأزهار ثلاثية الأبعاد وتصميم ملتصق على الكتف، فستان أنيق لحفلات عيد ميلاد الفتيات ، فستان سهرة أنيق لحفلات البيانو والعروض الأميرية', 'sk2407155884572153', 'https://img.ltwebstatic.com/v4/j/spmp/2026/04/03/8b/177520603637111dd684f0d576b1d08ca10741d8a5.jpg', 1, 24.52, 'pending', '2026-04-07 07:20:23', ''),
(477, 5, '4 قطع طقم سيدة شابة بسيط بنقشة قلب مكفوفة', 'sk25040265292232260', 'https://img.ltwebstatic.com/v4/j/pi/2025/05/13/b8/1747125653d60af0a4896522ba0d043d65c37defbf.jpg', 1, 9.85, 'pending', '2026-04-07 07:20:23', ''),
(478, 5, 'أحذية أميرة ذات قاع ناعم وفيونكة جديدة للبنات، أنيقة وحلوة، مناسبة للربيع والخريف', 'sa251130095171487281', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/08/03/17466867438032906df9594fb3c5c827bc4563d2c8.jpg', 1, 7.24, 'pending', '2026-04-07 07:20:23', ''),
(479, 5, 'SHEIN بنت طفل بتفاصيل رفرف دنيم صديري & محبوك مضلع رومبير كامي', 'sk2306194904906900', 'https://img.ltwebstatic.com/images3_pi/2023/07/08/16888081027dda50a0e91c1ae5c345b4fbff5118f1.jpg', 1, 11.45, 'pending', '2026-04-07 07:20:23', ''),
(480, 5, 'طقم جمبسوت قميص بنات صلبة مخطط 3قطع/مجموعة', 'sk2406175605030303', 'https://img.ltwebstatic.com/images3_spmp/2024/07/28/18/1722131874d07f1b137a6cab8831d000a9d9549360.jpg', 1, 7.99, 'pending', '2026-04-07 07:20:23', ''),
(481, 5, 'زوج واحد من الصنادل المفتوحة الأنف المزينة بزهور أنيقة وجميلة للبنات الصغيرات، خفيفة الوزن ومنفذة للهواء، مناسبة للداخل والخارج والمناسبات', 'sa2406224852311107', 'https://img.ltwebstatic.com/images3_spmp/2024/12/22/5f/1734861467f34edd5007bce80c242b34db74765bfa.jpg', 1, 8.20, 'pending', '2026-04-07 07:20:23', ''),
(482, 5, 'مجموعة قميص وشورت مزخرفة بزهور ثلاثية الأبعاد عصرية للفتيات الشابات، صيفي', 'sk2404126266434659', 'https://img.ltwebstatic.com/v4/j/spmp/2025/12/23/66/1766480172ededd1a6a3e8f10a634bc1a89f169074.jpg', 1, 7.99, 'pending', '2026-04-07 07:20:23', ''),
(483, 5, 'SHEIN قميص سباغيتي كامي مطرز بالدانتيل المثقوب ويحمل قوس بالأمام ، وبنطلون بتصميم الزنبقة لفتاة صغيرة', 'sk2112081731771277', 'https://img.ltwebstatic.com/v4/j/pi/2025/07/25/51/17534329645cd1cac6ad09dbf6ba41e208f9860ddf.jpg', 1, 9.05, 'pending', '2026-04-07 07:20:23', ''),
(484, 5, 'SHEIN طقم قميص أكمام قصيرة وشورت فوق المراهقة مكون من 2 قطع', 'sk2211306672892913', 'https://img.ltwebstatic.com/images3_pi/2025/03/07/71/174133472276c37990618c42ff2e14c5b44a70abff.jpg', 1, 10.65, 'pending', '2026-04-07 07:20:23', ''),
(485, 5, '2 قطعة مجموعة بلوزة مكشكشة + تنورة ذات خصر مرتفع برقبة مكشكشة، ناعمة ومريحة الملبس ومرحة، مناسبة للفتيات من عمر 4-7 سنوات للرحلات والسفر وحفلات الشاطئ في الربيع والصيف', 'sk2501037237695846', 'https://img.ltwebstatic.com/images3_spmp/2025/02/25/5e/1740451404476cb5490269308018cafd70315dda39.jpg', 1, 6.30, 'pending', '2026-04-07 07:20:23', ''),
(486, 5, 'Cozy Pixies زوج من الصنادل المسطحة الجميلة للأطفال البنات، مزخرفة بفيونكة ملونة للأجازات والأعياد، مناسبة للربيع والصيف', 'sa2411244211272119', 'https://img.ltwebstatic.com/images3_pi/2024/12/05/56/17333905578324881664a6dc7553e4b982cd43bcff.jpg', 1, 12.52, 'pending', '2026-04-07 07:20:23', ''),
(487, 8, 'Asiteo 1 قطعة غراء شفاف للرموش الصناعية سعة 5 مل، غراء رموش مقاوم للماء، أداة مكياج سريعة الجفاف وطويلة الأمد', 'sb2309087392508592', 'https://img.ltwebstatic.com/v4/j/spmp/2025/06/04/7c/1749007869c287c9a80091ca4b8e36ac9d6ed05988.jpg', 2, 1.60, 'pending', '2026-04-09 22:11:00', ''),
(488, 8, 'Pudaier كريم الشفاه المقاوم للماء - لمعة الشفاه غير اللزجة والتي لا تترك بقع، ثابتة في الكوب، طويلة الأمد، سهلة الاستخدام، ذات نهاية مطفأة', 'sb25102201401606598', 'https://img.ltwebstatic.com/v4/j/spmp/2025/10/22/d5/176111167722fe35204eac27ec31853724b599efb0_square.jpg', 1, 2.40, 'pending', '2026-04-09 22:11:00', ''),
(489, 8, 'SHEIN Clasi قميص سيدات موحد اللون كاجوال، بأكمام طويلة', 's180925520479767', 'https://img.ltwebstatic.com/images3_pi/2024/01/10/b0/1704865555c88b8f812d902b47e6a3e3727ecef6b6.jpg', 2, 8.52, 'pending', '2026-04-09 22:11:00', ''),
(490, 8, 'مكوّر رموش ذهبي وردي، مقبض جيلي شفاف وردي، مكوّر رموش يدوي محمول عالي الجودة، يخلق رموش ملتوية في أي وقت، أداة تجميل، مناسب للاستخدام المنزلي والتجاري، مناسب أيضًا للتوزيع، صديق للسفر، أداة مكياج بأسعار معقولة، هدية للنساء، هدية لها، هدية عيد الحب، هدايا،', 'sb25053053433449333', 'https://img.ltwebstatic.com/v4/j/spmp/2026/03/19/90/17738832590073b9b563ad6ed161fc5a51851b8314.jpg', 1, 1.60, 'pending', '2026-04-09 22:11:00', ''),
(491, 8, '5 أزواج من رموش عين القطة والثعلب الشفافة من NAIJEMA، طبيعية المظهر، ناعمة ومجعدة، إطالة الرموش، بطراز كرتوني، رموش دراماتيكية، مناسبة للمكياج اليومي، شرائط رموش، رموش مزيفة', 'sb25021566982844177', 'https://img.ltwebstatic.com/v4/j/spmp/2025/05/09/80/1746803254c0eb0229db4b8d75b0069c80356f9170.jpg', 1, 2.05, 'pending', '2026-04-09 22:11:00', '');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(50) DEFAULT 'general',
  `is_read` tinyint(1) DEFAULT 0,
  `related_id` int(11) DEFAULT NULL,
  `related_type` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `customer_id`, `title`, `message`, `type`, `is_read`, `related_id`, `related_type`, `created_at`) VALUES
(4, 3, 'Order in processing', 'We are processing your order #1. No action needed right now.', 'order', 1, 1, 'order', '2026-04-06 14:57:26');

-- --------------------------------------------------------

--
-- Table structure for table `onboarding_slides`
--

CREATE TABLE `onboarding_slides` (
  `id` int(11) NOT NULL,
  `slide_order` int(11) NOT NULL DEFAULT 1,
  `image_path` varchar(500) DEFAULT NULL,
  `title_en` varchar(255) DEFAULT '',
  `title_ku` varchar(255) DEFAULT '',
  `title_ar` varchar(255) DEFAULT '',
  `body_en` text DEFAULT NULL,
  `body_ku` text DEFAULT NULL,
  `body_ar` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `onboarding_slides`
--

INSERT INTO `onboarding_slides` (`id`, `slide_order`, `image_path`, `title_en`, `title_ku`, `title_ar`, `body_en`, `body_ku`, `body_ar`, `is_active`, `updated_at`) VALUES
(1, 1, '/uploads/onboarding/slide_1_1775553840.png', 'Welcome', 'بخێربێیت', 'مرحباً', 'Welcome to Velox Shopping', 'بخێربێیت بۆ ڤێلۆکس', 'مرحباً بك في فيلوكس', 1, '2026-04-07 09:24:00'),
(2, 2, NULL, 'Track Orders', 'شوێنکردنی داواکاری', 'تتبع الطلبات', 'Track all your orders easily', 'بە ئاسانی هەموو داواکارییەکانت بشوێنبکەوە', 'تتبع جميع طلباتك بسهولة', 1, '2026-04-07 09:02:18'),
(3, 3, NULL, 'Fast Delivery', 'گەیاندنی خێرا', 'توصيل سريع', 'Fast and reliable delivery to your door', 'گەیاندنی خێرا و متمانەپێکراو بۆ دەرگاکەت', 'توصيل سريع وموثوق إلى بابك', 1, '2026-04-07 09:02:18');

-- --------------------------------------------------------

--
-- Table structure for table `paystatue`
--

CREATE TABLE `paystatue` (
  `id` int(11) NOT NULL,
  `name` varchar(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `paystatue`
--

INSERT INTO `paystatue` (`id`, `name`) VALUES
(1, 'office');

-- --------------------------------------------------------

--
-- Table structure for table `qr_scan_log`
--

CREATE TABLE `qr_scan_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `serial` varchar(255) DEFAULT NULL,
  `result` varchar(10) DEFAULT NULL,
  `error_type` varchar(50) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `round`
--

CREATE TABLE `round` (
  `id` int(11) NOT NULL,
  `round` varchar(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `round`
--

INSERT INTO `round` (`id`, `round`) VALUES
(1, 'Round'),
(2, 'No Round');

-- --------------------------------------------------------

--
-- Table structure for table `sellers`
--

CREATE TABLE `sellers` (
  `id` int(11) NOT NULL,
  `name` varchar(31) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sells`
--

CREATE TABLE `sells` (
  `id` int(11) NOT NULL,
  `sellerid` int(11) NOT NULL,
  `wakilid` varchar(150) NOT NULL,
  `date` varchar(55) NOT NULL,
  `wasltypeid` int(11) NOT NULL,
  `subtotal` double NOT NULL,
  `note` text NOT NULL,
  `paymentdate` varchar(40) NOT NULL,
  `complete` int(11) NOT NULL,
  `branchid` int(11) NOT NULL,
  `realdate` timestamp NOT NULL DEFAULT current_timestamp(),
  `id2` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shipping_companies`
--

CREATE TABLE `shipping_companies` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `shipping_companies`
--

INSERT INTO `shipping_companies` (`id`, `name`, `phone`, `is_active`, `created_at`) VALUES
(1, 'Self Pickup', NULL, 1, '2026-02-05 06:34:31'),
(2, 'Company Driver', NULL, 1, '2026-02-05 06:34:31'),
(3, 'Express Delivery', NULL, 1, '2026-02-05 06:34:31'),
(4, 'Standard Delivery', NULL, 1, '2026-02-05 06:34:31');

-- --------------------------------------------------------

--
-- Table structure for table `shop`
--

CREATE TABLE `shop` (
  `id` int(11) NOT NULL,
  `item_name` varchar(255) NOT NULL,
  `item_name_kurdish` varchar(255) DEFAULT NULL,
  `item_name_arabic` varchar(255) DEFAULT NULL,
  `item_type` varchar(100) NOT NULL,
  `item_category` varchar(100) NOT NULL,
  `item_category_kurdish` varchar(255) DEFAULT NULL,
  `item_category_arabic` varchar(255) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `imageid` int(11) DEFAULT NULL,
  `imageid2` int(11) DEFAULT NULL,
  `imageid3` int(11) DEFAULT NULL,
  `imageid4` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `item_description` text NOT NULL,
  `item_description_kurdish` text DEFAULT NULL,
  `item_description_arabic` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `shop`
--

INSERT INTO `shop` (`id`, `item_name`, `item_name_kurdish`, `item_name_arabic`, `item_type`, `item_category`, `item_category_kurdish`, `item_category_arabic`, `price`, `imageid`, `imageid2`, `imageid3`, `imageid4`, `created_at`, `updated_at`, `item_description`, `item_description_kurdish`, `item_description_arabic`) VALUES
(31, 'suit', 'قاط', 'قاط', '7', 'MEN', '', '', 290.00, 4557, 4558, NULL, NULL, '2025-11-22 19:12:32', '2025-12-22 21:01:15', 'DROP 6 / SIZE 46', '', ''),
(32, 'suit', 'قاط', 'قاط', '7', '', '', '', 150.00, 4559, 4560, NULL, NULL, '2025-11-22 19:16:47', '2025-12-24 10:41:07', 'DROP 6 / SIZE 48', '', ''),
(33, 'suit', 'قاط', '', '7', 'MEN', '', '', 150.00, 4561, 4562, NULL, NULL, '2025-11-22 19:17:16', '2025-12-22 21:01:10', 'DROP 6 SIZE / 50', '', ''),
(34, 'suit', 'قاط', 'قاط', '7', '', '', '', 150.00, 4563, 4564, NULL, NULL, '2025-11-22 19:17:48', '2025-12-24 10:40:56', 'DROP 6 SIZE / 52', '', ''),
(35, 'suit', 'قاط', 'قاط', '7', '', '', '', 290.00, 4565, 4566, NULL, NULL, '2025-11-22 19:18:21', '2025-11-22 19:23:06', 'DROP 6 / SIZE 48', '', ''),
(36, 'suit', 'قاط', 'قاط', '6', '', '', '', 120.00, 4567, 4568, NULL, NULL, '2025-11-22 19:19:07', '2025-11-22 19:23:16', 'DROP 6 / SIZE 48', '', ''),
(37, 'suit', 'قاط', 'قاط', '6', '', '', '', 110.00, 4569, 4570, NULL, NULL, '2025-11-22 19:21:24', '2025-11-22 19:23:25', 'DROP 6 / SIZE 48', '', ''),
(38, 'suit', 'قاط', 'قاط', '6', '', '', '', 110.00, 4571, 4572, NULL, NULL, '2025-11-22 19:21:53', '2025-11-22 19:23:41', 'DROP 6 SIZE / 50', '', ''),
(39, 'suit', 'قاط', 'قاط', '6', '', '', '', 110.00, 4573, 4574, NULL, NULL, '2025-11-22 19:22:24', '2025-11-22 19:23:57', 'DROP 6 SIZE / 52', '', ''),
(40, 'coat', 'كوت', 'كوت', '6', '', '', '', 45.00, 4575, NULL, NULL, NULL, '2025-11-22 19:25:04', '2025-11-22 19:26:06', 'SIZE M', '', ''),
(41, 'coat', 'كوت', 'كوت', '6', '', '', '', 55.00, 4576, NULL, NULL, NULL, '2025-11-22 19:25:23', '2025-11-22 19:26:15', 'SIZE M', '', ''),
(42, 'coat', 'كوت', 'كوت', '6', '', '', '', 55.00, 4577, 4578, NULL, NULL, '2025-11-22 19:25:50', '2025-11-22 19:26:23', 'SIZE M', '', ''),
(43, 'coat', 'كوت', 'كوت', '6', '', '', '', 55.00, 4579, NULL, NULL, NULL, '2025-11-22 19:27:03', '2025-11-22 19:27:10', 'SIZE M', '', ''),
(44, 'jacket', 'كوت', 'كوت', '6', '', '', '', 100.00, 4580, NULL, NULL, NULL, '2025-11-22 19:28:02', '2025-11-22 19:28:02', 'SIZE L', '', ''),
(45, 'jacket', 'كوت', 'كوت', '6', '', '', '', 40.00, 4582, NULL, NULL, NULL, '2025-11-22 19:29:26', '2025-11-22 19:29:26', 'SIZE M', '', ''),
(46, 'tie', 'رباط', 'رباط', '6', '', '', '', 15.00, 4583, NULL, NULL, NULL, '2025-11-22 19:31:44', '2025-11-22 19:31:44', '', '', ''),
(47, 'tie', 'رباط', 'رباط', '6', '', '', '', 15.00, 4584, NULL, NULL, NULL, '2025-11-22 19:32:03', '2025-11-22 19:32:03', '', '', ''),
(48, 'tie', 'رباط', 'رباط', '6', '', '', '', 15.00, 4585, NULL, NULL, NULL, '2025-11-22 19:32:26', '2025-11-22 19:32:26', '', '', ''),
(49, 'tie', 'رباط', 'رباط', '6', '', '', '', 15.00, 4586, NULL, NULL, NULL, '2025-11-22 19:32:41', '2025-11-23 19:38:24', '', '', ''),
(50, 'tie', 'رباط', 'رباط', '6', '', '', '', 15.00, 4587, NULL, NULL, NULL, '2025-11-22 19:33:40', '2025-11-22 19:33:40', '', '', ''),
(51, 'tie', 'رباط', 'رباط', '6', '', '', '', 15.00, 4588, NULL, NULL, NULL, '2025-11-22 19:33:53', '2025-11-22 19:33:53', '', '', ''),
(52, 'tie', 'رباط', 'رباط', '6', '', '', '', 15.00, 4589, NULL, NULL, NULL, '2025-11-22 19:34:18', '2025-11-22 19:34:18', '', '', ''),
(53, 'MANGO', 'MANGO', 'MANGO', '8', 'WOMEN', 'WOMEN', 'WOMEN', 85.00, 6396, 6394, 6395, 6410, '2025-12-24 11:20:47', '2025-12-24 16:42:19', 'SIZE L', 'SIZE L', 'SIZE L'),
(54, 'loreal bond repair', 'loreal bond repair', 'loreal bond repair', '9', 'COSMETIC', '', '', 15.00, 6407, NULL, NULL, NULL, '2025-12-24 16:15:34', '2025-12-24 16:15:34', 'loreal bond repair', '', ''),
(55, 'loreal glycolic gloss serum', 'loreal glycolic gloss serum', 'loreal glycolic gloss serum', '9', 'COSMETIC', '', '', 15.00, 6408, NULL, NULL, NULL, '2025-12-24 16:18:13', '2025-12-24 16:18:13', 'loreal glycolic gloss serum', '', ''),
(56, 'Elseve Loreal Paris 100 Ml ', 'Elseve Loreal Paris 100 Ml ', 'Elseve Loreal Paris 100 Ml ', '9', 'COSMETIC', '', '', 12.00, 6416, NULL, NULL, NULL, '2025-12-25 08:04:15', '2025-12-25 08:04:55', 'Elseve Loreal Paris 100 Ml ', '', ''),
(57, 'PHYTO PHYTOPHANERE CHEVEUX ET ONGLES', 'PHYTO PHYTOPHANERE CHEVEUX ET ONGLES', 'PHYTO PHYTOPHANERE CHEVEUX ET ONGLES', '10', 'COSMETIC', '', '', 30.00, 6417, NULL, NULL, NULL, '2025-12-25 08:08:11', '2025-12-25 08:08:11', 'PHYTO PHYTOPHANERE CHEVEUX ET ONGLES', '', ''),
(58, 'L\'Oreal Paris Revitalift Anti-Wrinkle and Firming Face Night Cream', 'L\'Oreal Paris Revitalift Anti-Wrinkle and Firming Face Night Cream', 'L\'Oreal Paris Revitalift Anti-Wrinkle and Firming Face Night Cream', '9', 'COSMETIC', '', '', 15.00, 6418, NULL, NULL, NULL, '2025-12-25 08:15:35', '2025-12-25 08:15:35', 'L\'Oreal Paris Revitalift Anti-Wrinkle and Firming Face Night Cream', '', ''),
(59, 'L\'Oreal Paris Revitalift Anti-Wrinkle and Firming Face DAY Cream', 'L\'Oreal Paris Revitalift Anti-Wrinkle and Firming Face DAY Cream', 'L\'Oreal Paris Revitalift Anti-Wrinkle and Firming Face DAY Cream', '9', 'COSMETIC', '', '', 15.00, 6419, NULL, NULL, NULL, '2025-12-25 08:18:06', '2025-12-25 08:18:06', 'L\'Oreal Paris Revitalift Anti-Wrinkle and Firming Face DAY Cream', '', ''),
(60, 'Loreal Paris Revitalift LOreal Paris Hydrating Cream Perfume Free', 'Loreal Paris Revitalift LOreal Paris Hydrating Cream Perfume Free', 'Loreal Paris Revitalift LOreal Paris Hydrating Cream Perfume Free', '9', 'COSMETIC', '', '', 15.00, 6420, NULL, NULL, NULL, '2025-12-25 08:20:03', '2025-12-25 08:20:03', 'Loreal Paris Revitalift LOreal Paris Hydrating Cream Perfume Free', '', ''),
(61, 'Nem Terapisi Aloe Vera Suyu Bakım Kremi Kuru 70 ml', 'Nem Terapisi Aloe Vera Suyu Bakım Kremi Kuru 70 ml', 'Nem Terapisi Aloe Vera Suyu Bakım Kremi Kuru 70 ml', '9', 'COSMETIC', 'Nem Terapisi Aloe Vera Suyu Bakım Kremi Kuru 70 ml', '', 15.00, 6421, NULL, NULL, NULL, '2025-12-25 08:22:52', '2025-12-25 08:22:52', '', '', ''),
(62, 'La Roche Posay Anthelios UVmune 400 Hydrating Cream SPF50+', 'La Roche Posay Anthelios UVmune 400 Hydrating Cream SPF50+', 'La Roche Posay Anthelios UVmune 400 Hydrating Cream SPF50+', '11', 'COSMETIC', '', '', 19.00, 6422, NULL, NULL, NULL, '2025-12-25 08:26:39', '2025-12-25 08:31:06', 'La Roche Posay Anthelios UVmune 400 Hydrating Cream SPF50+', '', ''),
(63, 'ANTHELIOS UVMUNE 400 OIL CONTROL GEL-CREAM SPF50+', 'ANTHELIOS UVMUNE 400 OIL CONTROL GEL-CREAM SPF50+', 'ANTHELIOS UVMUNE 400 OIL CONTROL GEL-CREAM SPF50+', '11', 'COSMETIC', '', '', 19.00, 6423, NULL, NULL, NULL, '2025-12-25 08:30:46', '2025-12-25 08:32:06', 'ANTHELIOS UVMUNE 400 OIL CONTROL GEL-CREAM SPF50+', '', ''),
(64, 'ANTHELIOS UVMUNE 400 INVISIBLE FLUID SPF50+', 'ANTHELIOS UVMUNE 400 INVISIBLE FLUID SPF50+', 'ANTHELIOS UVMUNE 400 INVISIBLE FLUID SPF50+', '11', 'COSMETIC', '', '', 19.00, 6424, NULL, NULL, NULL, '2025-12-25 08:34:07', '2025-12-25 08:34:07', 'ANTHELIOS UVMUNE 400 INVISIBLE FLUID SPF50+', '', ''),
(65, 'La Roche Posay - Anthelios UVMUNE 400 Anti Dark Spots Fluid SPF50+ 50ml', 'La Roche Posay - Anthelios UVMUNE 400 Anti Dark Spots Fluid SPF50+ 50ml', 'La Roche Posay - Anthelios UVMUNE 400 Anti Dark Spots Fluid SPF50+ 50ml', '11', 'COSMETIC', '', '', 19.00, 6425, NULL, NULL, NULL, '2025-12-25 08:36:51', '2025-12-25 08:36:51', 'La Roche Posay - Anthelios UVMUNE 400 Anti Dark Spots Fluid SPF50+ 50ml', '', ''),
(66, 'The Ordinary retinol 0.5 in squalane', 'The Ordinary retinol 0.5 in squalane', 'The Ordinary retinol 0.5 in squalane', '12', 'COSMETIC', '', '', 15.00, 6426, NULL, NULL, NULL, '2025-12-25 08:38:50', '2025-12-25 08:38:50', 'The Ordinary retinol 0.5 in squalane', '', ''),
(67, 'The Ordinary Alpha Arbutin 2% + HA ', 'The Ordinary Alpha Arbutin 2% + HA ', 'The Ordinary Alpha Arbutin 2% + HA ', '12', 'COSMETIC', '', '', 15.00, 6427, NULL, NULL, NULL, '2025-12-25 08:41:07', '2025-12-25 08:41:07', 'The Ordinary Alpha Arbutin 2% + HA ', '', ''),
(68, 'The Ordinary Salicylic Acid 2% Solution', 'The Ordinary Salicylic Acid 2% Solution', 'The Ordinary Salicylic Acid 2% Solution', '12', 'COSMETIC', '', '', 15.00, 6429, NULL, NULL, NULL, '2025-12-25 08:43:17', '2025-12-25 08:43:17', 'The Ordinary Salicylic Acid 2% Solution', '', ''),
(69, 'The Ordinary Niacinamide 10% + Zinc 1%', 'The Ordinary Niacinamide 10% + Zinc 1%', 'The Ordinary Niacinamide 10% + Zinc 1%', '12', 'COSMETIC', '', '', 15.00, 6430, NULL, NULL, NULL, '2025-12-25 08:44:51', '2025-12-25 08:44:51', 'The Ordinary Niacinamide 10% + Zinc 1%', '', ''),
(70, 'Clinique dramatically different moisturizing lotion', 'Clinique dramatically different moisturizing lotion', 'Clinique dramatically different moisturizing lotion', '13', 'COSMETIC', '', '', 35.00, 6431, NULL, NULL, NULL, '2025-12-25 08:47:56', '2025-12-25 08:47:56', 'Clinique dramatically different moisturizing lotion 125ml', '', ''),
(71, 'Minéral 89 Hyaluronic Acid Serum', 'Minéral 89 Hyaluronic Acid Serum', 'Minéral 89 Hyaluronic Acid Serum', '14', 'COSMETIC', '', '', 35.00, 6433, NULL, NULL, NULL, '2025-12-25 09:04:35', '2025-12-25 09:04:35', 'Minéral 89 Hyaluronic Acid Serum', '', ''),
(72, 'La Roche-Posay\'s innovation  Effaclar Duo+M', 'La Roche-Posay\'s innovation  Effaclar Duo+M', 'La Roche-Posay\'s innovation  Effaclar Duo+M', '11', 'COSMETIC', '', '', 18.00, 6434, NULL, NULL, NULL, '2025-12-25 09:08:46', '2025-12-25 09:08:46', 'La Roche-Posay\'s innovation  Effaclar Duo+M', '', ''),
(73, 'Eucerin advanced repair cream', 'Eucerin advanced repair cream', 'Eucerin advanced repair cream', '15', 'COSMETIC', '', '', 13.00, 6436, NULL, NULL, NULL, '2025-12-25 09:11:38', '2025-12-25 18:24:03', 'Eucerin advanced repair cream', '', ''),
(74, 'Scholl ExpertCare Foot Mask with Manuka Honey', 'Scholl ExpertCare Foot Mask with Manuka HoneyScoll ExpertCare Foot Mask with Manuka Honey', 'Scholl ExpertCare Foot Mask with Manuka Honey', '16', 'COSMETIC', '', '', 8.00, 6440, NULL, NULL, NULL, '2025-12-25 09:15:26', '2025-12-25 10:37:37', 'Scholl ExpertCare Foot Mask with Manuka Honey', '', ''),
(75, 'Prada  Paradoxe Radical Essence Parfum with Sandalwood &amp; Salted Pistachio', 'Prada  Paradoxe Radical Essence Parfum with Sandalwood &amp; Salted Pistachio', 'Prada  Paradoxe Radical Essence Parfum with Sandalwood &amp; Salted Pistachio', '17', 'PERFUME', '', '', 205.00, 6442, NULL, NULL, NULL, '2025-12-25 09:21:10', '2025-12-25 09:34:58', 'Prada  Paradoxe Radical Essence Parfum with Sandalwood &amp; Salted Pistachio 90ml', '', ''),
(76, 'Prada  Paradoxe Eau de Parfum with White Musk &amp; Amber', 'Prada  Paradoxe Eau de Parfum with White Musk &amp; Amber', 'Prada  Paradoxe Eau de Parfum with White Musk &amp; Amber', '17', 'PERFUME', '', '', 180.00, 6443, NULL, NULL, NULL, '2025-12-25 09:26:18', '2025-12-25 09:34:45', 'Prada  Paradoxe Eau de Parfum with White Musk &amp; Amber 90ml', '', ''),
(77, 'Prada  Paradoxe Virtual Flower Eau de Parfum with Musk &amp; Jasmine', 'Prada  Paradoxe Virtual Flower Eau de Parfum with Musk &amp; Jasmine', 'Prada  Paradoxe Virtual Flower Eau de Parfum with Musk &amp; Jasmine', '17', 'PERFUME', '', '', 180.00, 6448, NULL, NULL, NULL, '2025-12-25 09:40:33', '2025-12-25 09:40:33', 'Prada  Paradoxe Virtual Flower Eau de Parfum with Musk &amp; Jasmine 90ml', '', ''),
(78, 'Dolce&amp;Gabbana  Devotion Eau de Parfum Intense with Hazelnut &amp; Vanilla', 'Dolce&amp;Gabbana  Devotion Eau de Parfum Intense with Hazelnut &amp; Vanilla', 'Dolce&amp;Gabbana  Devotion Eau de Parfum Intense with Hazelnut &amp; Vanilla', '18', 'PERFUME', '', '', 175.00, 6450, NULL, NULL, NULL, '2025-12-25 09:54:45', '2025-12-25 09:54:45', 'Dolce&amp;Gabbana  Devotion Eau de Parfum Intense with Hazelnut &amp; Vanilla 100ml', '', ''),
(79, 'Dolce&amp;Gabbana  Devotion Eau de Parfum with Citrus &amp; Vanilla', 'Dolce&amp;Gabbana  Devotion Eau de Parfum with Citrus &amp; Vanilla', 'Dolce&amp;Gabbana  Devotion Eau de Parfum with Citrus &amp; Vanilla', '18', 'PERFUME', '', '', 174.00, 6451, NULL, NULL, NULL, '2025-12-25 09:57:07', '2025-12-25 09:57:07', 'Dolce&amp;Gabbana  Devotion Eau de Parfum with Citrus &amp; Vanilla 98ml', '', ''),
(80, 'Maison Baccarat Rouge 540 Parfum extract', 'Maison Baccarat Rouge 540 Parfum extract', 'Maison Baccarat Rouge 540 Parfum extract', '19', 'PERFUME', '', '', 395.00, 6454, NULL, NULL, NULL, '2025-12-25 10:07:03', '2025-12-25 10:07:03', 'Maison Baccarat Rouge 540 Parfum extract 70ml', '', ''),
(81, 'XERJOFF  Erba Pura', 'XERJOFF  Erba Pura', 'XERJOFF  Erba Pura', '20', 'PERFUME', '', '', 306.00, 6456, NULL, NULL, NULL, '2025-12-25 10:12:38', '2025-12-25 10:12:38', 'XERJOFF  Erba Pura 100 ml', '', ''),
(82, 'Xerjoff opera', 'Xerjoff opera', 'Xerjoff opera', '20', 'PERFUME', '', '', 332.00, 6457, NULL, NULL, NULL, '2025-12-25 10:16:53', '2025-12-25 10:16:53', 'xerjoff opera 100ml', '', ''),
(83, 'shirt', 'shirt', 'shirt', '8', 'KIDS', '', '', 15.00, 7040, 7041, 7042, NULL, '2026-01-04 16:01:23', '2026-01-04 16:01:23', 'size : 13-14 years', '', ''),
(84, 'ALDO', '', '', '21', 'BAGS', '', '', 55.00, 7044, 7045, 7046, NULL, '2026-01-04 16:07:57', '2026-01-04 16:07:57', '', '', ''),
(85, 'bags', '', '', '22', 'BAGS', '', '', 15.00, 7048, 7049, 7050, NULL, '2026-01-04 16:14:57', '2026-01-04 16:14:57', 'black', '', ''),
(86, 'Accessories', '', '', '22', 'ACCESSORIES', '', '', 2.50, 7051, 7052, 7053, NULL, '2026-01-04 16:22:10', '2026-01-04 16:22:10', '', '', ''),
(87, 'Accessories', '', '', '22', 'ACCESSORIES', '', '', 2.50, 7056, NULL, NULL, NULL, '2026-01-04 16:26:51', '2026-01-04 16:27:38', 'sunglass', '', ''),
(88, 'coxir', '', '', '5', 'COSMETIC', '', '', 20.00, 7057, NULL, NULL, NULL, '2026-01-04 16:31:41', '2026-01-04 16:31:53', 'coxir ULTRA HYALURONIC CLEANSING OIL-Hydrating Korean Oil ', '', ''),
(89, 'Tommy Hilfiger', '', '', '23', 'SHOES', '', '', 79.99, 7059, 7060, NULL, NULL, '2026-01-04 16:46:12', '2026-01-04 16:47:18', 'women size : 39 / 8.5us', '', ''),
(90, 'shoes', '', '', '22', 'SHOES', '', '', 15.00, 7061, 7062, 7063, NULL, '2026-01-04 16:53:05', '2026-01-04 16:53:05', 'size : EUR37', '', ''),
(91, 'shoes', '', '', '22', 'SHOES', '', '', 15.00, 7064, 7065, NULL, NULL, '2026-01-04 16:58:15', '2026-01-04 16:58:15', 'size : CN39', '', ''),
(92, 'shoes', '', '', '22', 'SHOES', '', '', 15.00, 7066, 7067, NULL, NULL, '2026-01-04 17:05:01', '2026-01-04 17:05:01', 'size : CN39', '', ''),
(93, 'Morfose Milk Therapy ', '', '', '5', 'COSMETIC', '', '', 8.00, 7068, 7069, NULL, NULL, '2026-01-04 17:37:51', '2026-01-04 17:37:51', 'Morfose Milk Therapy Çift Fazlı Saç Bakım Fön Suyu 400 ml', '', ''),
(94, 'Morfose Milk Therapy Saç Köpüğü ', '', '', '5', 'COSMETIC', '', '', 5.00, 7070, 7071, NULL, NULL, '2026-01-04 17:40:48', '2026-01-04 17:40:48', 'Morfose Milk Therapy Saç Köpüğü 200 ml - Besleyici, Koruyucu Etki', '', ''),
(95, 'zara', '', '', '24', 'SHOES', '', '', 38.00, 7074, NULL, NULL, NULL, '2026-01-04 17:48:39', '2026-01-04 17:49:40', 'size 37', '', ''),
(96, 'Calvin Klein Womens Hard Side Upright', '', '', '25', 'BAGS', '', '', 220.00, 7084, 7080, 7081, 7082, '2026-01-04 18:32:32', '2026-01-04 18:34:40', 'Calvin Klein Womens Hard Side Upright Spinner Light Weight Suitcase Luggage- Suitcase / size M', '', ''),
(97, 'coat', '', '', '26', 'MEN', '', '', 150.00, 7560, 7561, 7562, NULL, '2026-01-17 15:47:44', '2026-01-17 15:47:44', 'size XL', '', ''),
(98, 'Gissah set2', '', '', '27', 'PERFUME', '', '', 95.00, 7571, 7568, 7569, NULL, '2026-01-17 15:58:44', '2026-01-17 15:58:44', '', '', ''),
(99, 'King Tobacco', '', '', '28', 'PERFUME', '', '', 90.00, 7573, NULL, NULL, NULL, '2026-01-17 16:00:16', '2026-01-17 16:00:16', '200ml', '', ''),
(100, 'blue laverne bakhur', '', '', '3', 'PERFUME', '', '', 9000.00, 7575, NULL, NULL, NULL, '2026-01-17 16:01:08', '2026-02-23 11:20:01', '200ML', '', '');

-- --------------------------------------------------------

--
-- Table structure for table `shop_banners`
--

CREATE TABLE `shop_banners` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `title_kurdish` varchar(255) DEFAULT NULL,
  `title_arabic` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `description_kurdish` text DEFAULT NULL,
  `description_arabic` text DEFAULT NULL,
  `product_id` int(11) NOT NULL,
  `image_id` int(11) DEFAULT NULL,
  `position` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `shop_banners`
--

INSERT INTO `shop_banners` (`id`, `title`, `title_kurdish`, `title_arabic`, `description`, `description_kurdish`, `description_arabic`, `product_id`, `image_id`, `position`, `is_active`, `created_at`, `updated_at`) VALUES
(5, 'PRADA', '', '', '', '', '', 75, 6445, 1, 1, '2025-12-25 09:33:10', '2025-12-25 09:33:10'),
(7, 'SALE', '', '', '', '', '', 53, 6447, 2, 1, '2025-12-25 09:38:43', '2025-12-25 09:38:43'),
(8, 'DEVOTION', '', '', '', '', '', 78, 6452, 3, 1, '2025-12-25 09:58:54', '2025-12-25 09:58:54');

-- --------------------------------------------------------

--
-- Table structure for table `size`
--

CREATE TABLE `size` (
  `id` int(11) NOT NULL,
  `name` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `size`
--

INSERT INTO `size` (`id`, `name`) VALUES
(493, ''),
(596, ''),
(918, ' 80 A'),
(866, '.NONE'),
(793, '(0) XL'),
(794, '(1) XL'),
(94, '0'),
(95, '0 month'),
(96, '0-1'),
(93, '0-1 month'),
(97, '0-1 year'),
(98, '0-12 month'),
(99, '0-18 month'),
(100, '0-2 month'),
(101, '0-2 year'),
(102, '0-24 month'),
(103, '0-3 month'),
(104, '0-3 year'),
(105, '0-4 year'),
(106, '0-6 month'),
(107, '0-9 month'),
(108, '0.35 oz'),
(109, '0.5 kg'),
(356, '02-24'),
(111, '1 meter'),
(112, '1 month'),
(113, '1 year'),
(114, '1-1.5 year'),
(110, '1-1/2 years'),
(115, '1-12 month'),
(116, '1-2 month'),
(117, '1-2 year'),
(118, '1-3 month'),
(119, '1-3 year'),
(120, '1-4 year'),
(121, '1-6 month'),
(122, '1-6 year'),
(123, '1-9 month'),
(124, '1.5 month'),
(125, '1.5-2 year'),
(126, '1.5-2.5 year'),
(127, '1.5-4 year'),
(128, '1.5cm'),
(129, '1.7oz'),
(130, '10'),
(134, '10 year'),
(135, '10-11 year'),
(136, '10-12 year'),
(137, '10-13 year'),
(138, '10-14 year'),
(139, '10-16 year'),
(140, '10.5'),
(141, '10.5 M'),
(142, '10.5m/11.5w'),
(143, '10/12'),
(144, '100'),
(145, '100 B'),
(146, '100 c'),
(147, '100 D'),
(168, '100 E'),
(148, '100 ML'),
(149, '100*100'),
(150, '100*120'),
(151, '100*140'),
(152, '100*150'),
(153, '100*160'),
(86, '100*170'),
(154, '100*180'),
(87, '100*200'),
(155, '100*200'),
(169, '100*230'),
(156, '100*250'),
(157, '100*260'),
(158, '100*270'),
(159, '100*300'),
(160, '100*350'),
(161, '100*400'),
(162, '100*500'),
(170, '100*60'),
(163, '100*600'),
(171, '100*70'),
(164, '100*80'),
(165, '100/450'),
(166, '100/70'),
(167, '1000 ml'),
(856, '100B'),
(857, '100C'),
(172, '104'),
(173, '105'),
(175, '105*120'),
(176, '105*70'),
(177, '1050 ml'),
(178, '105B'),
(179, '105C'),
(174, '105cm'),
(180, '107*164'),
(131, '10kg'),
(132, '10ml'),
(181, '10mm'),
(133, '10oz'),
(182, '10w'),
(183, '10XL'),
(36, '10y'),
(184, '11'),
(203, '11 MM'),
(204, '11 US'),
(185, '11 year'),
(60, '11-12'),
(186, '11-12 year'),
(187, '11-13 year'),
(188, '11-14 year'),
(189, '11-8 us'),
(190, '11.5'),
(191, '110'),
(200, '110 B'),
(192, '110 C'),
(193, '110 cm'),
(196, '110-116 cm'),
(194, '110*110'),
(197, '110*150'),
(198, '110*160'),
(195, '110*40'),
(199, '110*40'),
(201, '115cm'),
(202, '116'),
(205, '12'),
(250, '12 L'),
(206, '12 month'),
(88, '12 tall'),
(208, '12 W'),
(209, '12 year'),
(210, '12-13 year'),
(37, '12-14 y'),
(211, '12-14 year'),
(212, '12-15 month'),
(213, '12-16 month'),
(214, '12-16 year'),
(75, '12-18'),
(215, '12-18 month'),
(216, '12-24 month'),
(217, '12.5'),
(89, '12.5cm'),
(218, '120'),
(245, '120 ml'),
(222, '120-300'),
(225, '120*120'),
(226, '120*140'),
(227, '120*150'),
(228, '120*160'),
(229, '120*170'),
(230, '120*175'),
(221, '120*180 '),
(231, '120*180'),
(232, '120*200'),
(233, '120*210'),
(234, '120*240'),
(235, '120*250'),
(236, '120*260'),
(219, '120*325'),
(237, '120*350'),
(238, '120*380'),
(239, '120*400'),
(240, '120*410'),
(241, '120*490'),
(220, '120*60'),
(242, '120*600'),
(243, '120*700'),
(223, '120*80'),
(224, '120*90'),
(244, '1200ml'),
(246, '122*128'),
(248, '125 ml'),
(247, '125cm'),
(249, '128'),
(83, '12m'),
(251, '12M'),
(207, '12oz'),
(252, '12Xl'),
(28, '12years'),
(253, '13'),
(254, '13 pro max'),
(70, '13 year'),
(255, '13 year'),
(256, '13-14 year'),
(257, '13-15'),
(259, '130*130cm'),
(90, '130*160'),
(260, '130*170'),
(261, '130*180'),
(262, '130*190'),
(263, '130*200'),
(264, '130C'),
(258, '130cm'),
(265, '133*190'),
(266, '133*195'),
(267, '134'),
(268, '135cm'),
(269, '13XL'),
(270, '14'),
(272, '14 Regular'),
(81, '14 year'),
(273, '14 year'),
(274, '14-15'),
(275, '14-15 year'),
(276, '14-16 year'),
(277, '14/15'),
(278, '14+'),
(279, '140'),
(280, '140*140'),
(281, '140*180'),
(282, '140*190'),
(283, '140*200'),
(284, '140*220'),
(285, '140*240'),
(286, '140*250'),
(287, '140*260'),
(288, '140*270'),
(289, '140*280'),
(290, '1400ml'),
(291, '140cm'),
(292, '143m'),
(293, '145cm'),
(294, '14inc'),
(271, '14ml'),
(295, '14XL'),
(297, '15 1/2'),
(296, '15 year'),
(299, '15-16 year'),
(300, '15-18 month'),
(301, '15-21'),
(302, '15.5'),
(303, '15.6inc'),
(298, '15*20'),
(304, '15/16'),
(305, '150'),
(307, '150*180'),
(308, '150*200'),
(309, '150*230'),
(310, '150*230'),
(311, '150*240'),
(312, '150*250'),
(313, '150*260'),
(314, '150*270'),
(315, '150*280'),
(316, '150*300'),
(306, '150ml'),
(926, '16 inch'),
(318, '16 short'),
(317, '16 year'),
(319, '16-17 month'),
(320, '16-17 year'),
(321, '16.5'),
(887, '160*220'),
(322, '17 year'),
(323, '17-18'),
(324, '17.5'),
(325, '18 cm'),
(326, '18 inch'),
(328, '18 month'),
(329, '18 regular'),
(330, '18-19'),
(331, '18-21 month'),
(332, '18-24 month'),
(333, '18-36 month'),
(334, '180*220'),
(327, '18ml'),
(335, '18ml'),
(336, '18W'),
(337, '19-20'),
(886, '1L'),
(880, '1pcs'),
(20, '1xl'),
(338, '1XL-2XL'),
(340, '2 meter'),
(341, '2 month'),
(342, '2 year'),
(68, '2 years'),
(343, '2-12 month'),
(344, '2-2.5 year'),
(346, '2-3 month'),
(345, '2-3 year'),
(347, '2-4 month'),
(348, '2-4 year'),
(929, '2-4 years'),
(349, '2-5 year'),
(350, '2-6 m'),
(351, '2.5'),
(352, '2.5-3 year'),
(894, '20'),
(354, '20-21'),
(355, '20-22'),
(357, '20-25'),
(358, '20-40'),
(359, '20.5'),
(360, '200'),
(91, '200*290'),
(361, '200ml'),
(353, '20ml'),
(362, '21'),
(363, '21-20'),
(364, '21-22'),
(365, '21-23'),
(366, '21-24 month'),
(367, '21-30'),
(368, '21.5'),
(369, '210cm'),
(371, '22 regular'),
(372, '22 UK'),
(373, '22-23'),
(374, '22-24'),
(375, '22.5'),
(376, '22.5-23.5'),
(377, '220'),
(370, '22cm'),
(72, '23'),
(379, '23-24'),
(380, '23-25'),
(381, '23-26'),
(382, '23-28'),
(383, '23-30'),
(384, '23.5'),
(386, '230*200'),
(387, '230*230'),
(385, '230ml'),
(388, '236ml'),
(389, '23cm'),
(71, '24'),
(390, '24'),
(391, '24 month'),
(392, '24-25'),
(393, '24-26'),
(394, '24-27'),
(395, '24-28'),
(396, '24-30'),
(397, '24-32'),
(398, '24-32 month'),
(399, '24-36'),
(400, '24-36 month'),
(401, '240ml'),
(84, '25'),
(402, '25'),
(403, '25-26'),
(404, '25-27'),
(405, '25-28'),
(406, '25-29'),
(407, '25-32'),
(408, '25-34'),
(409, '25.5'),
(410, '25/27'),
(411, '25/28'),
(412, '25/30'),
(413, '25/32'),
(414, '250ml'),
(39, '26'),
(415, '26'),
(417, '26-26'),
(418, '26-27'),
(419, '26-28'),
(420, '26-29'),
(421, '26-30'),
(416, '26-32'),
(422, '26.5'),
(423, '26/25'),
(424, '26/28'),
(425, '26/30'),
(426, '26/32'),
(427, '260'),
(428, '26W 30L'),
(73, '27'),
(429, '27'),
(430, '27-28'),
(431, '27-29'),
(432, '27-30'),
(433, '27-32'),
(434, '27-34'),
(435, '27.5'),
(436, '27/25'),
(437, '27/27'),
(438, '27/28'),
(439, '27/30'),
(440, '27/31'),
(441, '27/32'),
(442, '270ml'),
(74, '28'),
(443, '28'),
(444, '28-25'),
(445, '28-26'),
(446, '28-27'),
(447, '28-28'),
(448, '28-29'),
(449, '28-30'),
(450, '28-32'),
(451, '28-33'),
(452, '28-34'),
(453, '28.5'),
(454, '28/27'),
(455, '28/30'),
(456, '28/31'),
(457, '28/32'),
(458, '280*200'),
(49, '29'),
(459, '29'),
(460, '29-28'),
(461, '29-30'),
(462, '29-31'),
(463, '29-32'),
(464, '29-34'),
(465, '29-36'),
(466, '29/27'),
(467, '29/29'),
(468, '29/30'),
(469, '29/30'),
(470, '29/32'),
(471, '29/34'),
(472, '2A'),
(339, '2kg'),
(881, '2pcs'),
(473, '2T'),
(474, '2TB'),
(21, '2xl'),
(475, '2XL'),
(476, '2XL-3XL'),
(477, '2XS'),
(478, '3'),
(24, '3 mang '),
(481, '3 month'),
(670, '3 month'),
(479, '3 US 8'),
(29, '3 y'),
(69, '3 year '),
(482, '3 years'),
(483, '3-10 year'),
(484, '3-12 month'),
(485, '3-4 month '),
(486, '3-4 year'),
(487, '3-4.5'),
(488, '3-5 year'),
(26, '3-6 mang'),
(489, '3-6 month'),
(490, '3-6 year'),
(491, '3-7 year'),
(492, '3-8 yaer'),
(494, '3-9'),
(495, '3.5'),
(496, '3.5 year'),
(61, '30'),
(497, '30'),
(499, '30 gram'),
(498, '30 ml'),
(500, '30-27'),
(501, '30-28'),
(502, '30-29'),
(503, '30-30'),
(504, '30-31'),
(505, '30-32'),
(506, '30-33'),
(507, '30-34'),
(508, '30-45'),
(509, '30.5'),
(517, '30*35'),
(510, '30*40'),
(511, '30*50'),
(512, '30/30'),
(513, '30/32'),
(514, '30/34'),
(515, '30/36'),
(516, '300ml'),
(518, '31'),
(519, '31-26'),
(520, '31-27'),
(521, '31-28'),
(522, '31-30'),
(45, '31-32'),
(523, '31-32'),
(524, '31-34'),
(525, '31-36'),
(526, '31.5'),
(527, '32'),
(528, '32 D'),
(529, '32-27'),
(530, '32-28'),
(531, '32-30'),
(534, '32-31'),
(44, '32-32'),
(532, '32-32'),
(533, '32-33'),
(535, '32-34'),
(536, '32-36'),
(537, '32.5'),
(879, '320cm'),
(538, '32B'),
(539, '32DD'),
(540, '33'),
(541, '33 1/2'),
(542, '33-27'),
(543, '33-28'),
(545, '33-29'),
(544, '33-30'),
(546, '33-31'),
(547, '33-32'),
(548, '33-34'),
(549, '33-35'),
(551, '33-36'),
(552, '33-44'),
(553, '33-45'),
(550, '33.5'),
(554, '330'),
(76, '34'),
(555, '34'),
(574, '34'),
(560, '34 Petite'),
(561, '34 regular'),
(562, '34-27'),
(563, '34-28'),
(564, '34-29'),
(565, '34-30'),
(567, '34-31'),
(568, '34-32'),
(569, '34-33'),
(570, '34-34'),
(571, '34-35'),
(572, '34-36'),
(575, '34-38'),
(576, '34-40'),
(577, '34.5'),
(556, '34/27'),
(566, '3431'),
(557, '34A'),
(578, '34B'),
(558, '34C'),
(559, '34D'),
(65, '35'),
(579, '35'),
(580, '35-32'),
(581, '35-34'),
(582, '35-36'),
(583, '35-37'),
(584, '35-38'),
(586, '35-40'),
(587, '35-41'),
(588, '35.5'),
(589, '350ml'),
(57, '36'),
(590, '36 (S)'),
(591, '36 2/3'),
(592, '36 B'),
(594, '36 month'),
(595, '36 Petite'),
(597, '36 Regular'),
(613, '36 Regular'),
(611, '36 XS'),
(598, '36-29'),
(599, '36-30'),
(600, '36-31'),
(601, '36-32'),
(602, '36-34'),
(603, '36-36'),
(573, '36-37'),
(604, '36-38'),
(878, '36-39'),
(605, '36-40'),
(606, '36-41'),
(607, '36-42'),
(608, '36-44'),
(609, '36-46'),
(663, '36-49'),
(610, '36-L'),
(612, '36.5'),
(614, '36/sht'),
(615, '365ml'),
(616, '36C'),
(593, '36D'),
(617, '36T'),
(42, '37'),
(618, '37'),
(619, '37 1/3'),
(620, '37-38'),
(621, '37-39'),
(622, '37-40'),
(623, '37-41'),
(624, '37-42'),
(625, '37-43'),
(626, '37-44'),
(627, '37.5'),
(628, '375 ml'),
(6, '38'),
(629, '38'),
(631, '38 2/3'),
(634, '38 EUR'),
(633, '38 EUR (30US)'),
(635, '38 Petite'),
(636, '38 regular'),
(637, '38 sht'),
(638, '38-30'),
(639, '38-32'),
(640, '38-33'),
(641, '38-34'),
(642, '38-39'),
(643, '38-40'),
(644, '38-41'),
(645, '38-42'),
(646, '38.5'),
(40, '38.50'),
(630, '38(M)'),
(647, '38/28'),
(648, '38/29'),
(649, '38/30'),
(650, '38/32'),
(651, '385 ml'),
(632, '38B'),
(652, '38C'),
(653, '38D'),
(654, '38T'),
(5, '39'),
(655, '39'),
(656, '39 1/3'),
(585, '39-39'),
(657, '39-40'),
(658, '39-41'),
(659, '39-42'),
(660, '39-43'),
(661, '39-45'),
(662, '39-46'),
(664, '39.5'),
(665, '390ml'),
(480, '3mater'),
(666, '3mm'),
(882, '3pcs'),
(667, '3T'),
(22, '3xl'),
(668, '3XL'),
(669, '3XL-4XL'),
(671, '4'),
(672, '4 XL'),
(30, '4 y'),
(673, '4 year'),
(79, '4 years'),
(674, '4-5 month'),
(675, '4-5 year'),
(908, '4-5 years'),
(676, '4-6 month'),
(928, '4-6 years'),
(677, '4-7 year'),
(678, '4-8 year'),
(679, '4-9 month'),
(680, '4.5'),
(681, '4.5 year'),
(7, '40'),
(682, '40'),
(684, '40 (M)'),
(685, '40 1/2'),
(686, '40 2/3'),
(687, '40 D'),
(711, '40 EUR'),
(688, '40 L'),
(712, '40 L'),
(689, '40 Petite'),
(690, '40 Regular'),
(683, '40 sht'),
(691, '40 standart'),
(692, '40 TALL'),
(693, '40-31'),
(694, '40-32'),
(695, '40-33'),
(696, '40-41'),
(697, '40-42'),
(698, '40-43'),
(699, '40-44'),
(700, '40-45'),
(701, '40-46'),
(702, '40.5'),
(916, '40*140'),
(703, '40*30'),
(704, '40*40'),
(705, '40*50'),
(706, '40*60'),
(707, '40/32'),
(708, '400 ml'),
(709, '40B'),
(710, '40C'),
(713, '40T'),
(8, '41'),
(714, '41'),
(715, '41 1/3'),
(716, '41-42'),
(717, '41-43'),
(718, '41-44'),
(719, '41-45'),
(720, '41-46'),
(721, '41.5'),
(9, '42'),
(722, '42'),
(723, '42 1/3'),
(724, '42 2/3'),
(748, '42 2/3'),
(725, '42 B'),
(726, '42 CM'),
(727, '42 Petite'),
(728, '42 Regular'),
(729, '42 Regular /14'),
(730, '42 Tall'),
(731, '42-30'),
(732, '42-31'),
(733, '42-32'),
(734, '42-33'),
(735, '42-34'),
(736, '42-43'),
(737, '42-44'),
(738, '42-45'),
(739, '42-46'),
(740, '42.5'),
(741, '42/32'),
(742, '42/42'),
(743, '42c'),
(10, '43'),
(744, '43'),
(745, '43 (17)'),
(746, '43 1/3'),
(747, '43 1/4'),
(749, '43-44'),
(750, '43-45'),
(751, '43-46'),
(752, '43.5'),
(11, '44'),
(753, '44'),
(754, '44 1/2'),
(755, '44 2/3'),
(12, '45'),
(898, '45*45'),
(92, '450*190'),
(13, '46'),
(14, '47'),
(15, '48'),
(925, '48-50'),
(16, '49'),
(883, '4pcs'),
(23, '4xl'),
(54, '4xl'),
(31, '5 year'),
(906, '5-6 years'),
(871, '50'),
(899, '50*50'),
(896, '50*66'),
(920, '50*80'),
(867, '50*90'),
(922, '500cm'),
(51, '52'),
(917, '55*240'),
(884, '5pcs'),
(56, '5xl'),
(897, '6'),
(25, '6 mang'),
(813, '6 US'),
(66, '6 y'),
(32, '6 year'),
(909, '6-12 mounth '),
(47, '6-7'),
(907, '6-7 years'),
(930, '6-8 years'),
(877, '6-9 mang'),
(80, '6-9 mounth'),
(921, '6.5'),
(885, '6pcs'),
(927, '7'),
(33, '7 year'),
(46, '7-8'),
(50, '7.5'),
(826, '70B'),
(824, '70C'),
(825, '70D'),
(827, '75 A'),
(828, '75B'),
(829, '75C'),
(830, '75D'),
(831, '75E'),
(832, '75F'),
(833, '75G'),
(34, '8 year'),
(923, '8-10 years'),
(48, '8-9'),
(931, '8-9 years'),
(910, '8.5'),
(41, '80'),
(58, '80'),
(834, '80B'),
(838, '80B'),
(835, '80C'),
(839, '80C'),
(836, '80E'),
(840, '80E'),
(837, '80F'),
(841, '85'),
(842, '85A'),
(843, '85B'),
(844, '85C'),
(845, '85D'),
(846, '85E'),
(67, '8y'),
(43, '9'),
(27, '9 mang'),
(35, '9 year'),
(911, '9-10 years'),
(78, '9-12 m'),
(924, '9.5'),
(869, '9.5x25x15.5'),
(77, '9/12'),
(847, '90'),
(868, '90*150'),
(848, '90B'),
(849, '90C'),
(850, '90E'),
(851, '90ML'),
(852, '95B'),
(853, '95C'),
(855, '95E'),
(862, 'A'),
(863, 'B'),
(864, 'C'),
(901, 'CN 20'),
(902, 'CN 21'),
(903, 'CN 22'),
(904, 'CN 25'),
(775, 'CN 35'),
(776, 'CN 35.5'),
(777, 'CN 36'),
(779, 'CN 37'),
(780, 'CN 37.5'),
(781, 'CN 38'),
(782, 'CN 38.5'),
(783, 'CN 39'),
(784, 'CN 39.5'),
(785, 'CN 40'),
(786, 'CN 40.5'),
(787, 'CN 41'),
(788, 'CN 41.5'),
(789, 'CN 42'),
(822, 'CN12-13'),
(823, 'CN13-14'),
(818, 'CN15-16'),
(888, 'CN18-19'),
(889, 'CN20-21'),
(890, 'CN22-23'),
(378, 'CN23'),
(905, 'CN24'),
(891, 'CN24-25'),
(892, 'CN26-27'),
(893, 'CN28-29'),
(817, 'CN34'),
(819, 'CN36-37'),
(778, 'CN36.5'),
(820, 'CN38-39'),
(821, 'CN40-41'),
(865, 'D'),
(854, 'E'),
(808, 'EUR21'),
(809, 'EUR22'),
(810, 'EUR23'),
(811, 'EUR25'),
(812, 'EUR27'),
(53, 'ipad 7th'),
(756, 'Iphone 11'),
(758, 'Iphone 11 pro'),
(52, 'iphone 11 pro max'),
(757, 'Iphone 11pro max'),
(760, 'Iphone 12'),
(759, 'Iphone 12 pro'),
(761, 'Iphone 12 pro max'),
(762, 'Iphone 13'),
(874, 'Iphone 13 mini'),
(763, 'Iphone 13 pro'),
(764, 'Iphone 13 pro max'),
(765, 'Iphone 14'),
(766, 'Iphone 14 pro'),
(767, 'Iphone 14 pro max'),
(768, 'Iphone 15'),
(769, 'Iphone 15 plus'),
(770, 'Iphone 15 pro'),
(771, 'Iphone 15 pro max'),
(772, 'Iphone 16'),
(872, 'Iphone 16 plus'),
(773, 'Iphone 16 pro'),
(774, 'Iphone 16 pro max'),
(912, 'Iphone 17'),
(913, 'Iphone 17 pro'),
(914, 'Iphone 17 pro max'),
(873, 'Iphone plus '),
(876, 'Iphone XR'),
(875, 'Iphone12 mini'),
(4, 'LARGE'),
(792, 'large-slim fit'),
(919, 'M-L'),
(85, 'M/L'),
(801, 'M10/W10.5'),
(799, 'M10/W11'),
(802, 'M13/W14.5'),
(804, 'M14/W15.5'),
(796, 'M4/W5'),
(797, 'M6/W7'),
(800, 'M6/W7.5'),
(803, 'M9/W10'),
(798, 'M9/W9'),
(3, 'MEDIUM'),
(63, 'Medium '),
(807, 'NEWBORN'),
(59, 'NONE'),
(858, 'one size'),
(18, 'one-size'),
(82, 'one-size'),
(870, 'other'),
(55, 's-m'),
(64, 'sliper'),
(2, 'SMALL'),
(790, 'small Petite'),
(791, 'Small Regular'),
(859, 'soft'),
(860, 'ssoft'),
(861, 'SSTD'),
(900, 'STANDART'),
(815, 'UK 14'),
(816, 'UK 18'),
(814, 'UK12'),
(915, 'US 8'),
(1, 'XL'),
(19, 'xl'),
(805, 'XL/42'),
(795, 'XL/L'),
(806, 'XL/XXL'),
(38, 'xs'),
(62, 'XXL'),
(895, 'XXS');

-- --------------------------------------------------------

--
-- Table structure for table `statue`
--

CREATE TABLE `statue` (
  `id` int(11) NOT NULL,
  `name` varchar(155) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `statue`
--

INSERT INTO `statue` (`id`, `name`) VALUES
(-3, 'Refunded '),
(-2, 'Completed'),
(-1, 'Delivered to Erbil\n'),
(1, 'Created'),
(2, 'Processing'),
(3, 'Approved'),
(4, 'In Transit\n'),
(6, 'Rejected'),
(7, 'Created recintly'),
(13, 'Pending'),
(14, 'Canceled '),
(16, 'Purchased'),
(17, 'Out for delivery \n'),
(18, 'Store '),
(19, 'Erbil warehouse\n'),
(20, 'Awaiting Payment\n'),
(21, 'lost');

-- --------------------------------------------------------

--
-- Table structure for table `support_requests`
--

CREATE TABLE `support_requests` (
  `id` int(11) NOT NULL,
  `name` varchar(150) DEFAULT NULL,
  `phone` varchar(60) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int(11) NOT NULL,
  `transaction_type` enum('income','expense') NOT NULL,
  `budget_type` enum('office','operating') NOT NULL,
  `box_id` int(11) DEFAULT NULL,
  `category_id` int(11) DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  `note` text DEFAULT NULL,
  `reference` varchar(100) DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `usertype`
--

CREATE TABLE `usertype` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `name_ku` varchar(100) DEFAULT '',
  `name_ar` varchar(100) DEFAULT '',
  `limitt` int(11) NOT NULL,
  `color1` varchar(7) NOT NULL DEFAULT '#CCCCCC',
  `color2` varchar(7) NOT NULL DEFAULT '#999999',
  `text_color` varchar(7) NOT NULL DEFAULT '#FFFFFF'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `usertype`
--

INSERT INTO `usertype` (`id`, `name`, `name_ku`, `name_ar`, `limitt`, `color1`, `color2`, `text_color`) VALUES
(1, 'Silver', '', '', 100, '#9E9E9E', '#E0E0E0', '#FFFFFF'),
(2, 'Gold', '', '', 300, '#F9A825', '#FFD740', '#FFFFFF'),
(3, 'Platinum', '', '', 1000, '#90A4AE', '#CFD8DC', '#FFFFFF'),
(4, 'Diamond', 'دایمۆند', 'دایموند', 2000, '#00b8d4', '#80deea', '#ffffff'),
(5, 'bronze', '', '', 0, '#8D6E63', '#BCAAA4', '#FFFFFF'),
(6, 'gold plus', '', '', 600, '#F57F17', '#FFCA28', '#FFFFFF'),
(7, 'Platinum plus', '', '', 1600, '#546E7A', '#B0BEC5', '#FFFFFF'),
(8, 'Diamond plus', '', '', 4000, '#006064', '#00BCD4', '#FFFFFF');

-- --------------------------------------------------------

--
-- Table structure for table `wasl`
--

CREATE TABLE `wasl` (
  `id` int(11) NOT NULL,
  `sellesid` int(11) NOT NULL,
  `brandid` int(11) NOT NULL,
  `typeid` int(11) NOT NULL,
  `codeid` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` double NOT NULL,
  `subtotal` double NOT NULL,
  `itemtype` int(11) NOT NULL,
  `firstprice` double NOT NULL,
  `discount` double NOT NULL,
  `convertprice` int(11) NOT NULL,
  `dinarsubtotal` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `website`
--

CREATE TABLE `website` (
  `id` int(11) NOT NULL,
  `name` text NOT NULL,
  `link` text NOT NULL,
  `order_id` int(11) NOT NULL,
  `country` varchar(22) NOT NULL,
  `image_id` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `website`
--

INSERT INTO `website` (`id`, `name`, `link`, `order_id`, `country`, `image_id`) VALUES
(1, 'shein', 'https://shein.com', 2, 'UAE', '7999'),
(2, 'rawa', 'https://abayaislamiya.com/', 3, 'Germany', '8009'),
(3, 'ikj', 'jknj', 1, 'UAE', '8010');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `admin_notifications`
--
ALTER TABLE `admin_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_read` (`is_read`),
  ADD KEY `idx_created` (`created_at`),
  ADD KEY `idx_entity` (`entity_type`,`entity_id`);

--
-- Indexes for table `bank`
--
ALTER TABLE `bank`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `banners`
--
ALTER TABLE `banners`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `box`
--
ALTER TABLE `box`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD KEY `idx_account_id` (`account_id`);

--
-- Indexes for table `box_tracking`
--
ALTER TABLE `box_tracking`
  ADD PRIMARY KEY (`id`),
  ADD KEY `box_id` (`box_id`),
  ADD KEY `tracking_number` (`tracking_number`),
  ADD KEY `idx_box_tracking_status` (`status`);

--
-- Indexes for table `brand`
--
ALTER TABLE `brand`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `buyer`
--
ALTER TABLE `buyer`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone` (`phone`);

--
-- Indexes for table `buyerpay`
--
ALTER TABLE `buyerpay`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `category`
--
ALTER TABLE `category`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `city`
--
ALTER TABLE `city`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `currency`
--
ALTER TABLE `currency`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `deliveries`
--
ALTER TABLE `deliveries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_customer_id` (`customer_id`),
  ADD KEY `idx_shipping_company` (`shipping_company`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `expense`
--
ALTER TABLE `expense`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `expense_categories`
--
ALTER TABLE `expense_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `fcm_tokens`
--
ALTER TABLE `fcm_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_token` (`token`),
  ADD KEY `idx_customer_id` (`customer_id`),
  ADD KEY `idx_device_id` (`device_id`);

--
-- Indexes for table `files`
--
ALTER TABLE `files`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `serial` (`serial`),
  ADD KEY `idx_box_id` (`box_id`),
  ADD KEY `idx_has_sub_items` (`has_sub_items`),
  ADD KEY `idx_in_iraq_delivery` (`in_iraq_delivery`);

--
-- Indexes for table `itemstatusupdate`
--
ALTER TABLE `itemstatusupdate`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_itemid_date` (`itemid`,`date`),
  ADD KEY `idx_changed_by` (`changed_by`);

--
-- Indexes for table `item_details`
--
ALTER TABLE `item_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `item_id` (`item_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `customer_id` (`customer_id`),
  ADD KEY `is_read` (`is_read`),
  ADD KEY `created_at` (`created_at`);

--
-- Indexes for table `onboarding_slides`
--
ALTER TABLE `onboarding_slides`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `paystatue`
--
ALTER TABLE `paystatue`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `qr_scan_log`
--
ALTER TABLE `qr_scan_log`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `round`
--
ALTER TABLE `round`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sellers`
--
ALTER TABLE `sellers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sells`
--
ALTER TABLE `sells`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `shipping_companies`
--
ALTER TABLE `shipping_companies`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `shop`
--
ALTER TABLE `shop`
  ADD PRIMARY KEY (`id`),
  ADD KEY `imageid` (`imageid`),
  ADD KEY `idx_shop_type` (`item_type`),
  ADD KEY `idx_shop_category` (`item_category`),
  ADD KEY `idx_shop_price` (`price`);

--
-- Indexes for table `shop_banners`
--
ALTER TABLE `shop_banners`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `image_id` (`image_id`);

--
-- Indexes for table `size`
--
ALTER TABLE `size`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `name` (`name`);

--
-- Indexes for table `statue`
--
ALTER TABLE `statue`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `support_requests`
--
ALTER TABLE `support_requests`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `idx_budget_type` (`budget_type`),
  ADD KEY `idx_transaction_type` (`transaction_type`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_box_id` (`box_id`);

--
-- Indexes for table `usertype`
--
ALTER TABLE `usertype`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `wasl`
--
ALTER TABLE `wasl`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `website`
--
ALTER TABLE `website`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `admin_notifications`
--
ALTER TABLE `admin_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `bank`
--
ALTER TABLE `bank`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `banners`
--
ALTER TABLE `banners`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `box`
--
ALTER TABLE `box`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `box_tracking`
--
ALTER TABLE `box_tracking`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `brand`
--
ALTER TABLE `brand`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `buyer`
--
ALTER TABLE `buyer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `buyerpay`
--
ALTER TABLE `buyerpay`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `category`
--
ALTER TABLE `category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `city`
--
ALTER TABLE `city`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `currency`
--
ALTER TABLE `currency`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `deliveries`
--
ALTER TABLE `deliveries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `expense`
--
ALTER TABLE `expense`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `expense_categories`
--
ALTER TABLE `expense_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `fcm_tokens`
--
ALTER TABLE `fcm_tokens`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `files`
--
ALTER TABLE `files`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8018;

--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `itemstatusupdate`
--
ALTER TABLE `itemstatusupdate`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `item_details`
--
ALTER TABLE `item_details`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=492;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `onboarding_slides`
--
ALTER TABLE `onboarding_slides`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `paystatue`
--
ALTER TABLE `paystatue`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `qr_scan_log`
--
ALTER TABLE `qr_scan_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `round`
--
ALTER TABLE `round`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `sellers`
--
ALTER TABLE `sellers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sells`
--
ALTER TABLE `sells`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shipping_companies`
--
ALTER TABLE `shipping_companies`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `shop`
--
ALTER TABLE `shop`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

--
-- AUTO_INCREMENT for table `shop_banners`
--
ALTER TABLE `shop_banners`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `size`
--
ALTER TABLE `size`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=932;

--
-- AUTO_INCREMENT for table `statue`
--
ALTER TABLE `statue`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `support_requests`
--
ALTER TABLE `support_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `usertype`
--
ALTER TABLE `usertype`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `wasl`
--
ALTER TABLE `wasl`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=100;

--
-- AUTO_INCREMENT for table `website`
--
ALTER TABLE `website`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `box`
--
ALTER TABLE `box`
  ADD CONSTRAINT `box_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `box_tracking`
--
ALTER TABLE `box_tracking`
  ADD CONSTRAINT `box_tracking_ibfk_1` FOREIGN KEY (`box_id`) REFERENCES `box` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `item_details`
--
ALTER TABLE `item_details`
  ADD CONSTRAINT `item_details_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_customer_fk` FOREIGN KEY (`customer_id`) REFERENCES `buyer` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `shop`
--
ALTER TABLE `shop`
  ADD CONSTRAINT `shop_ibfk_1` FOREIGN KEY (`imageid`) REFERENCES `files` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `shop_banners`
--
ALTER TABLE `shop_banners`
  ADD CONSTRAINT `shop_banners_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `shop` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `shop_banners_ibfk_2` FOREIGN KEY (`image_id`) REFERENCES `files` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `expense_categories` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`box_id`) REFERENCES `box` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
