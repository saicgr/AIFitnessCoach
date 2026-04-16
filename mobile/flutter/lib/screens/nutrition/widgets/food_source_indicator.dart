import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../chat/widgets/fullscreen_image_viewer.dart';

/// Leading 28×28 (or custom) indicator showing the provenance of a food log:
///   • `imageUrl` present → tappable thumbnail (hero-transition into full-screen)
///   • `sourceType == 'barcode'`                        → QR icon
///   • `sourceType in chat/parse_*`                     → chat bubble icon
///   • `sourceType == 'restaurant'`                     → storefront icon
///   • `sourceType == 'image'` with no imageUrl yet     → camera placeholder
///     (e.g. pending upload — user still knows the row came from a photo)
///   • default (text / null)                            → subtle text-fields icon
class FoodSourceIndicator extends StatelessWidget {
  final String? imageUrl;
  final String? sourceType;
  final String? heroTag;
  /// Title to show in the fullscreen viewer's top pill (typically the
  /// dish/meal name). Optional — when null the viewer renders without a
  /// label.
  final String? viewerTitle;
  final double size;
  final Color mutedColor;

  const FoodSourceIndicator({
    super.key,
    required this.imageUrl,
    required this.sourceType,
    required this.mutedColor,
    this.heroTag,
    this.viewerTitle,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      final tag = heroTag ?? 'food-photo-$url';
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FullscreenImageViewer(
              imageUrl: url,
              heroTag: tag,
              title: viewerTitle,
            ),
          ));
        },
        child: Hero(
          tag: tag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  width: size,
                  height: size,
                  child: Center(
                    child: SizedBox(
                      width: size * 0.5,
                      height: size * 0.5,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: mutedColor,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _iconBox(Icons.broken_image_outlined),
            ),
          ),
        ),
      );
    }

    final IconData icon;
    switch (sourceType) {
      case 'barcode':
        icon = Icons.qr_code_scanner;
        break;
      case 'chat':
      case 'parse_app_screenshot':
      case 'parse_nutrition_label':
        icon = Icons.chat_bubble_outline_rounded;
        break;
      case 'restaurant':
        icon = Icons.storefront_outlined;
        break;
      case 'image':
        // Image source but URL absent (upload pending / failed) — show a camera
        // so the user at least knows the row came from a photo, not text.
        icon = Icons.photo_camera_outlined;
        break;
      default:
        icon = Icons.text_fields_rounded;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(
          icon,
          size: size * 0.58,
          color: mutedColor.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, size: size * 0.64, color: mutedColor),
        ),
      );
}

/// Convenience that uses the app's muted-text color without a caller needing
/// to resolve it every time.
class FoodSourceIndicatorThemed extends StatelessWidget {
  final String? imageUrl;
  final String? sourceType;
  final String? heroTag;
  final double size;
  final bool isDark;

  const FoodSourceIndicatorThemed({
    super.key,
    required this.imageUrl,
    required this.sourceType,
    required this.isDark,
    this.heroTag,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return FoodSourceIndicator(
      imageUrl: imageUrl,
      sourceType: sourceType,
      heroTag: heroTag,
      size: size,
      mutedColor: muted,
    );
  }
}
