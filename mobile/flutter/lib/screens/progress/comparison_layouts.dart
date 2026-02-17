import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Layout templates for photo comparisons
enum ComparisonLayout {
  sideBySide(2, 'Side by Side', '1:1 or 4:5', Icons.view_column),
  slider(2, 'Slider', '1:1', Icons.compare),
  verticalStack(2, 'Vertical Stack', '9:16', Icons.view_agenda),
  story(2, 'Story', '9:16', Icons.phone_android),
  diagonalSplit(2, 'Diagonal Split', '1:1', Icons.content_cut),
  polaroid(2, 'Polaroid', '1:1', Icons.photo),
  triptych(3, 'Timeline', '1:1 or 16:9', Icons.view_week),
  fourPanel(4, '4-Panel Grid', '1:1', Icons.grid_view),
  monthlyGrid(0, 'Monthly Grid', '1:1', Icons.calendar_view_month);

  final int photoCount; // 0 = variable (3-12)
  final String displayName;
  final String aspectRatioHint;
  final IconData icon;

  const ComparisonLayout(
    this.photoCount,
    this.displayName,
    this.aspectRatioHint,
    this.icon,
  );

  /// Whether this layout requires exactly 2 photos
  bool get isTwoPhoto => photoCount == 2;

  /// Whether this layout supports variable photo count
  bool get isVariable => photoCount == 0;

  /// Minimum photos needed
  int get minPhotos => isVariable ? 3 : photoCount;

  /// Maximum photos allowed
  int get maxPhotos => isVariable ? 12 : photoCount;

  /// Get the layout value string for API
  String get value => name;

  /// Parse from string
  static ComparisonLayout fromString(String value) {
    return ComparisonLayout.values.firstWhere(
      (l) => l.name == value || l.value == value,
      orElse: () => ComparisonLayout.sideBySide,
    );
  }

  /// Get photo labels based on layout type
  List<String> getLabels(int count) {
    switch (this) {
      case ComparisonLayout.sideBySide:
      case ComparisonLayout.slider:
      case ComparisonLayout.verticalStack:
      case ComparisonLayout.diagonalSplit:
      case ComparisonLayout.polaroid:
      case ComparisonLayout.story:
        return ['Before', 'After'];
      case ComparisonLayout.triptych:
        return ['Start', 'Mid', 'End'];
      case ComparisonLayout.fourPanel:
        return ['Photo 1', 'Photo 2', 'Photo 3', 'Photo 4'];
      case ComparisonLayout.monthlyGrid:
        return List.generate(count, (i) => 'Photo ${i + 1}');
    }
  }
}

/// 2-photo layout group
const twoPhotoLayouts = [
  ComparisonLayout.sideBySide,
  ComparisonLayout.slider,
  ComparisonLayout.verticalStack,
  ComparisonLayout.story,
  ComparisonLayout.diagonalSplit,
  ComparisonLayout.polaroid,
];

/// Multi-photo layout group
const multiPhotoLayouts = [
  ComparisonLayout.triptych,
  ComparisonLayout.fourPanel,
  ComparisonLayout.monthlyGrid,
];

/// Export aspect ratios
enum ExportAspectRatio {
  square('1:1', 1080, 1080),
  portrait('4:5', 1080, 1350),
  story('9:16', 1080, 1920);

  final String label;
  final int width;
  final int height;

  const ExportAspectRatio(this.label, this.width, this.height);

  double get ratio => width / height;
  Size get size => Size(width.toDouble(), height.toDouble());

  static ExportAspectRatio fromString(String value) {
    return ExportAspectRatio.values.firstWhere(
      (r) => r.label == value,
      orElse: () => ExportAspectRatio.square,
    );
  }
}

/// Widget that renders a mini layout preview icon
class LayoutPreviewIcon extends StatelessWidget {
  final ComparisonLayout layout;
  final bool isSelected;
  final double size;

  const LayoutPreviewIcon({
    super.key,
    required this.layout,
    this.isSelected = false,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected ? AppColors.green : colorScheme.outline;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _LayoutPreviewPainter(layout: layout, color: color),
      ),
    );
  }
}

class _LayoutPreviewPainter extends CustomPainter {
  final ComparisonLayout layout;
  final Color color;

  _LayoutPreviewPainter({required this.layout, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;
    final pad = 6.0;
    final innerW = w - pad * 2;
    final innerH = h - pad * 2;

    switch (layout) {
      case ComparisonLayout.sideBySide:
        // Two rectangles side by side
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, pad, innerW * 0.47, innerH),
            const Radius.circular(3),
          ),
          strokePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pad + innerW * 0.53, pad, innerW * 0.47, innerH),
            const Radius.circular(3),
          ),
          strokePaint,
        );
        // Divider line
        canvas.drawLine(
          Offset(w / 2, pad),
          Offset(w / 2, h - pad),
          strokePaint,
        );
        break;

      case ComparisonLayout.slider:
        // Full rect with slider line
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, pad, innerW, innerH),
            const Radius.circular(3),
          ),
          strokePaint,
        );
        // Slider line with handle
        final sliderX = w * 0.55;
        canvas.drawLine(
          Offset(sliderX, pad),
          Offset(sliderX, h - pad),
          Paint()..color = color..strokeWidth = 2,
        );
        canvas.drawCircle(
          Offset(sliderX, h / 2),
          4,
          paint,
        );
        break;

      case ComparisonLayout.verticalStack:
        // Top and bottom rectangles
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, pad, innerW, innerH * 0.47),
            const Radius.circular(3),
          ),
          strokePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, pad + innerH * 0.53, innerW, innerH * 0.47),
            const Radius.circular(3),
          ),
          strokePaint,
        );
        break;

      case ComparisonLayout.story:
        // 9:16 outline with logo area at top and stats at bottom
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pad + innerW * 0.15, pad, innerW * 0.7, innerH),
            const Radius.circular(3),
          ),
          strokePaint,
        );
        // Small logo placeholder
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pad + innerW * 0.25, pad + 3, innerW * 0.2, 4),
            const Radius.circular(1),
          ),
          paint,
        );
        break;

      case ComparisonLayout.diagonalSplit:
        // Rectangle with diagonal line
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, pad, innerW, innerH),
            const Radius.circular(3),
          ),
          strokePaint,
        );
        canvas.drawLine(
          Offset(pad, h - pad),
          Offset(w - pad, pad),
          Paint()..color = color..strokeWidth = 1.5,
        );
        break;

      case ComparisonLayout.polaroid:
        // Two slightly rotated polaroid frames
        canvas.save();
        canvas.translate(w * 0.3, h * 0.5);
        canvas.rotate(-0.1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: innerW * 0.45, height: innerH * 0.55),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        canvas.restore();

        canvas.save();
        canvas.translate(w * 0.65, h * 0.5);
        canvas.rotate(0.08);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: innerW * 0.45, height: innerH * 0.55),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        canvas.restore();
        break;

      case ComparisonLayout.triptych:
        // Three panels side by side
        final panelW = innerW / 3.3;
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(pad + i * (panelW + 2), pad, panelW, innerH),
              const Radius.circular(2),
            ),
            strokePaint,
          );
        }
        break;

      case ComparisonLayout.fourPanel:
        // 2x2 grid
        final cellW = innerW * 0.47;
        final cellH = innerH * 0.47;
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 2; col++) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  pad + col * (cellW + innerW * 0.06),
                  pad + row * (cellH + innerH * 0.06),
                  cellW,
                  cellH,
                ),
                const Radius.circular(2),
              ),
              strokePaint,
            );
          }
        }
        break;

      case ComparisonLayout.monthlyGrid:
        // 3x2 small grid
        final cellW = innerW / 3.5;
        final cellH = innerH / 2.5;
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 3; col++) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  pad + col * (cellW + 2),
                  pad + row * (cellH + 2),
                  cellW,
                  cellH,
                ),
                const Radius.circular(1),
              ),
              strokePaint,
            );
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _LayoutPreviewPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.color != color;
  }
}
