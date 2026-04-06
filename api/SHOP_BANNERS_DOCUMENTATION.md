# Shop Banners System Documentation

## Overview
The Shop Banners system allows you to create promotional banners that link to specific products in your shop. These banners can be displayed in a carousel/slider in your mobile app or website, and when clicked, they navigate users directly to the product detail page.

## Features
✅ Create banners linked to specific products
✅ Upload custom banner images (or use product image)
✅ Multi-language support (English, Kurdish, Arabic)
✅ Control banner order/position
✅ Enable/disable banners
✅ Full CRUD operations via API
✅ Automatic product information included

## Database Structure

### Table: `shop_banners`

```sql
CREATE TABLE shop_banners (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    title_kurdish VARCHAR(255),
    title_arabic VARCHAR(255),
    description TEXT,
    description_kurdish TEXT,
    description_arabic TEXT,
    product_id INT NOT NULL,
    image_id INT,
    position INT DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES shop(id) ON DELETE CASCADE,
    FOREIGN KEY (image_id) REFERENCES files(id) ON DELETE SET NULL
);
```

### Fields Explanation:
- **title**: Main banner title (English)
- **title_kurdish/title_arabic**: Translated titles
- **description**: Banner description/subtitle
- **product_id**: Links to product in `shop` table
- **image_id**: Custom banner image (optional, uses product image if null)
- **position**: Order of display (lower numbers first)
- **is_active**: Show/hide banner (1=active, 0=hidden)

## API Endpoints

### 1. GET - Fetch All Active Banners

**Endpoint:** `GET /api/shop_banners.php`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "banner_id": 1,
      "title": "Summer Sale!",
      "title_kurdish": "فرۆشتنی هاوینە",
      "title_arabic": "تخفيضات الصيف",
      "description": "Get 50% off on selected items",
      "description_kurdish": "50% داشکاندن لەسەر بەرهەمە هەڵبژێردراوەکان",
      "description_arabic": "احصل على خصم 50% على منتجات مختارة",
      "product_id": 53,
      "product_name": "MANGO",
      "product_name_kurdish": "MANGO",
      "product_name_arabic": "MANGO",
      "product_price": 85.00,
      "product_category": "WOMEN",
      "brand_name": "MANGO",
      "position": 0,
      "banner_image": "https://veloxshoppingiq.com/uploads/banner_abc123.jpg",
      "product_image": "https://veloxshoppingiq.com/uploads/6396.PNG",
      "created_at": "2025-12-24 12:00:00"
    }
  ]
}
```

### 2. POST - Create New Banner

**Endpoint:** `POST /api/shop_banners.php`

**Content-Type:** `multipart/form-data`

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| title | string | Yes | Banner title (English) |
| title_kurdish | string | No | Banner title (Kurdish) |
| title_arabic | string | No | Banner title (Arabic) |
| description | text | No | Banner description |
| description_kurdish | text | No | Description (Kurdish) |
| description_arabic | text | No | Description (Arabic) |
| product_id | integer | Yes | ID of product to link |
| banner_image | file | No | Banner image (max 2MB) |
| position | integer | No | Display order (default: 0) |
| is_active | integer | No | 1 or 0 (default: 1) |

**Success Response:**
```json
{
  "success": true,
  "banner_id": 5
}
```

**Error Response:**
```json
{
  "error": "Product not found"
}
```

### 3. PUT - Update Banner

**Endpoint:** `PUT /api/shop_banners.php`

**Content-Type:** `application/x-www-form-urlencoded`

**Parameters:** Same as POST + `banner_id`

### 4. DELETE - Delete Banner

**Endpoint:** `DELETE /api/shop_banners.php`

**Content-Type:** `application/json`

**Body:**
```json
{
  "banner_id": 1
}
```

**Success Response:**
```json
{
  "success": true
}
```

## Management Interface

Access the web-based management interface at:
```
https://veloxshoppingiq.com/api/test_shop_banners.html
```

Features:
- ✅ View all banners in a grid
- ✅ Create new banners with form
- ✅ Upload banner images
- ✅ Select products from dropdown
- ✅ Delete banners
- ✅ View API documentation

## Flutter Implementation

### 1. Fetch Banners

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class BannerService {
  static const String API_URL = 'https://veloxshoppingiq.com/api/shop_banners.php';
  
  Future<List<dynamic>> fetchBanners() async {
    try {
      final response = await http.get(Uri.parse(API_URL));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }
}
```

### 2. Display Banners in Carousel

```dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class BannersCarousel extends StatefulWidget {
  @override
  _BannersCarouselState createState() => _BannersCarouselState();
}

class _BannersCarouselState extends State<BannersCarousel> {
  List<dynamic> banners = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    loadBanners();
  }
  
  Future<void> loadBanners() async {
    final bannerService = BannerService();
    final fetchedBanners = await bannerService.fetchBanners();
    setState(() {
      banners = fetchedBanners;
      isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (banners.isEmpty) {
      return SizedBox.shrink();
    }
    
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 5),
        enlargeCenterPage: true,
        aspectRatio: 16/9,
        viewportFraction: 0.9,
      ),
      items: banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                // Navigate to product page
                Navigator.pushNamed(
                  context,
                  '/product',
                  arguments: {'product_id': banner['product_id']},
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner Image
                      Image.network(
                        banner['banner_image'] ?? banner['product_image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                      
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      
                      // Text overlay
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (banner['description'] != null)
                              Text(
                                banner['description'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 5),
                            Text(
                              '\$${banner['product_price']}',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
```

### 3. Use in Home Page

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shop')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banners Carousel
            BannersCarousel(),
            
            SizedBox(height: 20),
            
            // Rest of your home page content
            // Products grid, categories, etc.
          ],
        ),
      ),
    );
  }
}
```

## Testing Examples

### cURL Examples

**Get all banners:**
```bash
curl https://veloxshoppingiq.com/api/shop_banners.php
```

**Create a banner:**
```bash
curl -X POST https://veloxshoppingiq.com/api/shop_banners.php \
  -F "title=Summer Sale" \
  -F "description=50% off" \
  -F "product_id=53" \
  -F "position=1" \
  -F "banner_image=@/path/to/image.jpg"
```

**Delete a banner:**
```bash
curl -X DELETE https://veloxshoppingiq.com/api/shop_banners.php \
  -H "Content-Type: application/json" \
  -d '{"banner_id": 1}'
```

## Best Practices

1. **Banner Images:**
   - Recommended size: 1200x400px (3:1 ratio)
   - Max file size: 2MB
   - Formats: JPG, PNG, WEBP, GIF
   - If no custom image: product image is used automatically

2. **Banner Titles:**
   - Keep titles short (max 50 characters)
   - Make them attention-grabbing
   - Include call-to-action when possible

3. **Position:**
   - Use position field to control order
   - Lower numbers appear first
   - Use increments of 10 (10, 20, 30) for easy reordering

4. **Multi-language:**
   - Always provide English title/description
   - Add Kurdish/Arabic translations for better UX
   - App can select language based on user preference

## Troubleshooting

**Problem:** Banners not showing
- Check `is_active` is set to 1
- Verify product exists and is not deleted
- Check image paths are valid

**Problem:** Images not loading
- Verify image files exist in `/uploads/` directory
- Check file permissions (should be readable)
- Ensure URLs are properly formatted

**Problem:** "Product not found" error
- Verify product_id exists in `shop` table
- Check product hasn't been deleted

## Files Created

1. `/api/shop_banners.php` - Main API endpoint
2. `/api/test_shop_banners.html` - Management interface
3. `/api/SHOP_BANNERS_DOCUMENTATION.md` - This documentation

## Database Migration

The table is created automatically on first API call. To manually create:

```sql
CREATE TABLE IF NOT EXISTS shop_banners (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    title_kurdish VARCHAR(255),
    title_arabic VARCHAR(255),
    description TEXT,
    description_kurdish TEXT,
    description_arabic TEXT,
    product_id INT NOT NULL,
    image_id INT,
    position INT DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES shop(id) ON DELETE CASCADE,
    FOREIGN KEY (image_id) REFERENCES files(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Support

For issues or questions, contact the development team or refer to the test interface for live examples.

