# SHEIN Cart Extraction - Integration Complete

## Overview
Successfully integrated the SHEIN cart extraction API into the Velox Flutter app. Users can now automatically extract multiple items from SHEIN cart/share links with a single tap.

## API Endpoint
```
POST https://veloxshoppingiq.com/api/shein_extract.php
```

## Features Implemented

### 1. API Service (`lib/services/api_service.dart`)
Added new method:
```dart
static Future<Map<String, dynamic>> extractSheinCart(String sheinLink)
```

### 2. Cart Item Model (`lib/models/cart_item_model.dart`)
Added factory method for SHEIN data:
```dart
factory CartItem.fromSheinJson(Map<String, dynamic> json)
```

Maps SHEIN API response to CartItem:
- `code` → `serialNumber` (SKU/good_sn)
- `name` → `itemName`
- `image` → `imageUrl`
- `price` → `price`
- `qty` → `quantity`

### 3. Add Order Screen (`lib/screens/add_order_screen.dart`)

#### New UI Elements:
- **Hint Text**: "Paste SHEIN cart/share link to auto-extract items"
- **Extract Button**: Prominent button with loading state
- **Success Message**: "✓ Successfully extracted X items from SHEIN cart!"

#### Enhanced Cart Items Display:
Each extracted item shows:
- ✅ **Serial Number** (good_sn/code from SHEIN)
- ✅ **Item Name** (product name in Arabic/English)
- ✅ **Product Image** (from SHEIN CDN)
- ✅ **Quantity** (with +/- controls)
- ✅ **Unit Price** (in USD)
- ✅ **Subtotal** (auto-calculated)

## User Flow

### Step 1: Paste SHEIN Link
```
Example link:
http://api-shein.shein.com/h5/sharejump/appjump?link=lhBZeA2AVi1_b&localcountry=SA&url_from=GM74734338020
```

### Step 2: Tap "Auto-Extract from SHEIN Cart"
- Button shows loading spinner
- API call to extraction endpoint
- Parse response

### Step 3: View Extracted Items
All items populate automatically with:
- Product photo
- Serial number (SKU code)
- Product name
- Quantity: 1 (adjustable)
- Price in USD
- Subtotal calculated

### Step 4: Edit & Submit
- Adjust quantities
- Add/remove items
- Change photos if needed
- Add notes
- Select size
- Submit order

## Cart Items Section Features

### Individual Item Card
```
┌─────────────────────────────────────────────┐
│ Item 1                            [Delete]   │
│ ┌─────┐                                      │
│ │ IMG │  Serial: sc2309200899940400          │
│ │     │  Name: نظارات برجعي                  │
│ └─────┘                                      │
│                                              │
│ Qty: [-] 1 [+]  Price: $2.67  = $2.67      │
└─────────────────────────────────────────────┘
```

### Total Display
```
┌─────────────────────────────────────────────┐
│ Total (Item Price):              $15.50     │
└─────────────────────────────────────────────┘
```

## API Response Example

### Success Response
```json
{
  "success": true,
  "message": "Successfully extracted 3 items from SHEIN cart",
  "items": [
    {
      "code": "sc2309200899940400",
      "name": "1 قطعة نظارات بطراز كبير الحجم برجعي",
      "image": "https://img.ltwebstatic.com/images3_spmp/2023/09/20/...",
      "price": 2.67,
      "qty": 1
    }
  ],
  "total_items": 3,
  "total_price": 8.01
}
```

### Error Handling
The app handles:
- Missing link
- Invalid SHEIN link
- Empty cart
- Expired links
- Network errors
- API failures

All errors show user-friendly messages.

## Size Selector Enhancement

### Searchable Dropdown
Replaced chip-based size selector with:
- 📱 **Bottom Sheet** - Slides up from bottom
- 🔍 **Search Box** - Filter sizes instantly
- 📋 **Scrollable List** - All sizes in clean layout
- ✅ **Selection Indicator** - Checkmark on selected
- 📊 **Result Count** - Shows "X sizes found"
- ❌ **Clear Button** - Reset search filter

Perfect for handling 100+ size options!

## Code Quality

### Type Safety
- Proper null handling
- Type casting from API response
- Optional fields handled gracefully

### Error Handling
- Try-catch blocks
- User-friendly error messages
- Network error detection
- API failure handling

### UI/UX
- Loading states
- Success feedback
- Error messages
- Responsive design
- Dark theme consistent

## Testing

### Test Link
```
http://api-shein.shein.com/h5/sharejump/appjump?link=lhBZeA2AVi1_b&localcountry=SA&url_from=GM74734338020
```

### Test Page
```
https://veloxshoppingiq.com/api/test_shein_extract.html
```

## Files Modified

1. ✅ `lib/services/api_service.dart` - Added extractSheinCart()
2. ✅ `lib/models/cart_item_model.dart` - Added fromSheinJson()
3. ✅ `lib/screens/add_order_screen.dart` - Integrated extraction & size search

## Next Steps (Optional Enhancements)

1. **Currency Conversion**: Convert USD to IQD automatically
2. **Link Validation**: Detect SHEIN links and show extract hint
3. **Bulk Edit**: Select multiple items for bulk quantity change
4. **History**: Save extracted carts for later
5. **Share**: Share order summary before submission

## Notes

- ✅ No authentication required (public API)
- ✅ Works with SHEIN cart and share links
- ✅ Handles Arabic and English product names
- ✅ Image URLs from SHEIN CDN
- ✅ Prices in USD (can be converted to IQD)
- ⚠️ SHEIN links may expire after some time
- ⚠️ RapidAPI rate limits may apply

## Support

For issues:
1. Check the test page first
2. Verify SHEIN link is valid
3. Check error message in response
4. Contact backend team if needed

---

**Status**: ✅ Complete & Tested
**Last Updated**: Feb 4, 2026
**Version**: 1.0
