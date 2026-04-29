import 'package:flutter/material.dart';

/// Parses `#RRGGBB` or `#AARRGGBB` hex strings. Returns null if invalid.
Color? parseHexColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  }
  if (h.length == 8) {
    return Color(int.parse(h, radix: 16));
  }
  return null;
}
