import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/progress_photos.dart';
import '../comparison_layouts.dart';

// =============================================================================
// Layout Card (Step 1)
// =============================================================================

class ComparisonLayoutCard extends StatelessWidget {
  final ComparisonLayout layout;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const ComparisonLayoutCard({
    super.key,
    required this.layout,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.green.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.green
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LayoutPreviewIcon(
                    layout: layout,
                    isSelected: isSelected,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    layout.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.green
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    layout.aspectRatioHint,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Selected Photo Chip (Step 2)
// =============================================================================

class SelectedPhotoChip extends StatelessWidget {
  final ProgressPhoto photo;
  final String label;
  final int orderNumber;
  final ColorScheme colorScheme;
  final VoidCallback onRemove;

  const SelectedPhotoChip({
    super.key,
    required this.photo,
    required this.label,
    required this.orderNumber,
    required this.colorScheme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
            fit: BoxFit.cover,
          ),
          // Order badge
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$orderNumber',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 12, color: Colors.white),
              ),
            ),
          ),
          // Label at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: Colors.black54,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Photo Grid Card (Step 2)
// =============================================================================

class ComparisonPhotoGridCard extends StatelessWidget {
  final ProgressPhoto photo;
  final bool isSelected;
  final int? orderNumber;
  final bool enabled;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const ComparisonPhotoGridCard({
    super.key,
    required this.photo,
    required this.isSelected,
    this.orderNumber,
    required this.enabled,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(isSelected ? 5 : 8),
              child: CachedNetworkImage(
                imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
                fit: BoxFit.cover,
                color: !enabled && !isSelected
                    ? Colors.black.withOpacity(0.5)
                    : null,
                colorBlendMode:
                    !enabled && !isSelected ? BlendMode.darken : null,
              ),
            ),

            // Order badge
            if (isSelected && orderNumber != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$orderNumber',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Date + weight at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(photo.takenAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      photo.viewTypeEnum.displayName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (photo.formattedWeight != null)
                      Text(
                        photo.formattedWeight!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Toolbar Chip (Step 3)
// =============================================================================

class ComparisonToolbarChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const ComparisonToolbarChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    this.isLoading = false,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isActive ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            else if (isActive)
              Icon(Icons.check,
                  size: 14, color: colorScheme.primary)
            else
              Icon(icon,
                  size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Pannable Photo Widget
// =============================================================================

/// A photo widget that supports tap-to-select, pan, and pinch-to-zoom.
/// Pan/zoom only enabled when [isSelected] is true.
class PannablePhoto extends StatefulWidget {
  final ProgressPhoto photo;
  final BoxFit fit;
  final bool isSelected;
  final VoidCallback? onTap;

  const PannablePhoto({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<PannablePhoto> createState() => _PannablePhotoState();
}

class _PannablePhotoState extends State<PannablePhoto> {
  double _scale = 1.0;
  double _baseScale = 1.0;
  Alignment _alignment = Alignment.center;

  void _zoomIn() {
    setState(() {
      _scale = (_scale + 0.3).clamp(1.0, 4.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.3).clamp(1.0, 4.0);
      if (_scale <= 1.0) _alignment = Alignment.center;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            GestureDetector(
              onTap: widget.onTap,
              onScaleStart: (_) {
                _baseScale = _scale;
              },
              onScaleUpdate: (details) {
                if (!widget.isSelected) return;
                setState(() {
                  _scale =
                      (_baseScale * details.scale).clamp(1.0, 4.0);
                  final dx = details.focalPointDelta.dx /
                      (constraints.maxWidth * 0.5);
                  final dy = details.focalPointDelta.dy /
                      (constraints.maxHeight * 0.5);
                  _alignment = Alignment(
                    (_alignment.x - dx).clamp(-1.0, 1.0),
                    (_alignment.y - dy).clamp(-1.0, 1.0),
                  );
                });
              },
              child: ClipRect(
                child: Transform.scale(
                  scale: _scale,
                  child: SizedBox.expand(
                    child: CachedNetworkImage(
                      imageUrl: widget.photo.photoUrl,
                      fit: widget.fit,
                      alignment: _alignment,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.white54, size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Zoom +/- buttons (visible when selected)
            if (widget.isSelected)
              Positioned(
                bottom: 6,
                right: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ZoomButton(
                      icon: Icons.add,
                      onTap: _scale < 4.0 ? _zoomIn : null,
                    ),
                    const SizedBox(height: 4),
                    _ZoomButton(
                      icon: Icons.remove,
                      onTap: _scale > 1.0 ? _zoomOut : null,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ZoomButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(enabled ? 0.7 : 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.white70 : Colors.white24,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}

// =============================================================================
// Custom Clippers & Painters
// =============================================================================

/// Clips content to a vertical slice for the slider comparison
class SliderClipper extends CustomClipper<Rect> {
  final double position;

  SliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, position, size.height);
  }

  @override
  bool shouldReclip(covariant SliderClipper oldClipper) {
    return oldClipper.position != position;
  }
}

/// Clips content diagonally from bottom-left to top-right
class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant DiagonalClipper oldClipper) => false;
}

/// Paints a diagonal divider line from top-right to bottom-left
class DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DiagonalLinePainter oldDelegate) =>
      false;
}

/// Crosshatch diagonal pattern for canvas background decoration
class CanvasPatternPainter extends CustomPainter {
  final Color bgColor;

  CanvasPatternPainter(this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final isLight = bgColor.computeLuminance() > 0.5;
    final lineColor = isLight
        ? Colors.black.withOpacity(0.06)
        : Colors.white.withOpacity(0.06);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    // Diagonal lines (top-left to bottom-right)
    for (double i = -size.height; i < size.width + size.height; i += 32) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Crosshatch (top-right to bottom-left)
    for (double i = -size.height; i < size.width + size.height; i += 32) {
      canvas.drawLine(
        Offset(size.width - i, 0),
        Offset(size.width - i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPatternPainter oldDelegate) =>
      oldDelegate.bgColor != bgColor;
}
