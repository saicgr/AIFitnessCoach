import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class CustomColorLabCard extends ConsumerWidget {
  final BeastThemeData theme;
  const CustomColorLabCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom Color Lab', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
          const SizedBox(height: 4),
          Text('Fine-tune accent color with HSV picker', style: TextStyle(fontSize: 11, color: theme.textMuted)),
          const SizedBox(height: 16),
          _HSVColorPicker(
            currentAccent: ref.watch(accentColorProvider),
            onColorSelected: (accent) {
              ref.read(accentColorProvider.notifier).setAccent(accent);
            },
          ),
        ],
      ),
    );
  }
}

/// HSV Color Picker with saturation/brightness area and hue slider.
class _HSVColorPicker extends StatefulWidget {
  final AccentColor currentAccent;
  final ValueChanged<AccentColor> onColorSelected;

  const _HSVColorPicker({
    required this.currentAccent,
    required this.onColorSelected,
  });

  @override
  State<_HSVColorPicker> createState() => _HSVColorPickerState();
}

class _HSVColorPickerState extends State<_HSVColorPicker> {
  late double _hue;        // 0-360
  late double _saturation; // 0-1
  late double _brightness; // 0-1
  late AccentColor? _matchedPreset;

  @override
  void initState() {
    super.initState();
    _initFromAccentColor(widget.currentAccent);
  }

  @override
  void didUpdateWidget(_HSVColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAccent != widget.currentAccent) {
      _initFromAccentColor(widget.currentAccent);
    }
  }

  void _initFromAccentColor(AccentColor accent) {
    final color = accent.previewColor;
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;
    _matchedPreset = accent;
  }

  Color get _currentColor => HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();

  AccentColor _findClosestPreset() {
    final currentColor = _currentColor;
    AccentColor closest = AccentColor.orange;
    double minDistance = double.infinity;

    for (final accent in AccentColor.values) {
      final presetColor = accent.previewColor;
      final dr = ((currentColor.r - presetColor.r) * 255).abs();
      final dg = ((currentColor.g - presetColor.g) * 255).abs();
      final db = ((currentColor.b - presetColor.b) * 255).abs();
      final distance = dr + dg + db;

      if (distance < minDistance) {
        minDistance = distance;
        closest = accent;
      }
    }

    return closest;
  }

  void _onColorChanged() {
    final closest = _findClosestPreset();
    setState(() => _matchedPreset = closest);
    widget.onColorSelected(closest);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      children: [
        // Saturation/Brightness picker area
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanStart: (details) => _updateSaturationBrightness(details.localPosition, constraints),
                onPanUpdate: (details) => _updateSaturationBrightness(details.localPosition, constraints),
                onTapDown: (details) => _updateSaturationBrightness(details.localPosition, constraints),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _SaturationBrightnessPainter(hue: _hue),
                    ),
                    Positioned(
                      left: _saturation * constraints.maxWidth - 12,
                      top: (1 - _brightness) * constraints.maxHeight - 12,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentColor,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Hue slider with preview circle
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanStart: (details) => _updateHue(details.localPosition.dx, constraints.maxWidth),
                      onPanUpdate: (details) => _updateHue(details.localPosition.dx, constraints.maxWidth),
                      onTapDown: (details) => _updateHue(details.localPosition.dx, constraints.maxWidth),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(constraints.maxWidth, 32),
                            painter: _HueGradientPainter(),
                          ),
                          Positioned(
                            left: (_hue / 360) * constraints.maxWidth - 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 16,
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_matchedPreset != null)
          Text(
            'Matched: ${_matchedPreset!.displayName}',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
      ],
    );
  }

  void _updateSaturationBrightness(Offset position, BoxConstraints constraints) {
    HapticFeedback.selectionClick();
    setState(() {
      _saturation = (position.dx / constraints.maxWidth).clamp(0.0, 1.0);
      _brightness = 1.0 - (position.dy / constraints.maxHeight).clamp(0.0, 1.0);
    });
    _onColorChanged();
  }

  void _updateHue(double x, double width) {
    HapticFeedback.selectionClick();
    setState(() {
      _hue = ((x / width) * 360).clamp(0.0, 360.0);
    });
    _onColorChanged();
  }
}

/// Painter for the saturation/brightness gradient area.
class _SaturationBrightnessPainter extends CustomPainter {
  final double hue;

  _SaturationBrightnessPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final baseColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    final saturationGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, baseColor],
    );

    final brightnessGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );

    final satPaint = Paint()..shader = saturationGradient.createShader(rect);
    canvas.drawRect(rect, satPaint);

    final brightPaint = Paint()..shader = brightnessGradient.createShader(rect);
    canvas.drawRect(rect, brightPaint);
  }

  @override
  bool shouldRepaint(_SaturationBrightnessPainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

/// Custom painter for the rainbow hue gradient strip.
class _HueGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final colors = List.generate(
      13,
      (i) => HSVColor.fromAHSV(1.0, i * 30.0, 1.0, 1.0).toColor(),
    );

    final gradient = LinearGradient(colors: colors);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
