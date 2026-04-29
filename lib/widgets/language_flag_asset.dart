import 'package:flutter/material.dart';

/// Rounded flag image used on first-launch language selection and account language picker.
class LanguageFlagAsset extends StatelessWidget {
  const LanguageFlagAsset({
    super.key,
    required this.assetPath,
    this.width = 44,
    this.height = 30,
    this.fallback,
  });

  final String assetPath;
  final double width;
  final double height;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDDE1E6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            fallback ??
            Icon(Icons.flag_outlined, size: height * 0.55, color: Colors.grey),
      ),
    );
  }
}
