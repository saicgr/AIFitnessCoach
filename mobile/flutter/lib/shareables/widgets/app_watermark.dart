import 'package:flutter/material.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// THE shareable watermark. Real `assets/images/app_icon.png` + "Zealova"
/// capitalized. Use in every template's footer.
class AppWatermark extends StatelessWidget {
  final bool enabled;
  final Color textColor;
  final double iconSize;
  final double fontSize;

  const AppWatermark({
    super.key,
    this.enabled = true,
    this.textColor = Colors.white,
    this.iconSize = 22,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(iconSize * 0.25),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _Fallback(size: iconSize),
          ),
        ),
        SizedBox(width: iconSize * 0.32),
        Text(
          '${Branding.appName}',
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  final double size;
  const _Fallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF9D4EDD)],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.bolt_rounded, size: size * 0.6, color: Colors.white),
    );
  }
}
