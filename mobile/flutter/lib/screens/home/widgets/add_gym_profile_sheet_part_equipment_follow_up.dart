part of 'add_gym_profile_sheet.dart';


/// Follow-up suggestion shown after selecting certain equipment
class _EquipmentFollowUp {
  final String suggest;
  final String title;
  final String subtitle;

  const _EquipmentFollowUp({
    required this.suggest,
    required this.title,
    required this.subtitle,
  });
}


/// A horizontal hue gradient bar with a brightness row for picking custom colors
class _ColorScalePicker extends StatefulWidget {
  final Color? selectedColor;
  final bool isDark;
  final ValueChanged<Color> onColorSelected;

  const _ColorScalePicker({
    required this.selectedColor,
    required this.isDark,
    required this.onColorSelected,
  });

  @override
  State<_ColorScalePicker> createState() => _ColorScalePickerState();
}


class _ColorScalePickerState extends State<_ColorScalePicker> {
  double _hue = 0;
  double _saturation = 1.0;
  double _brightness = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.selectedColor != null) {
      final hsv = HSVColor.fromColor(widget.selectedColor!);
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _brightness = hsv.value;
    }
  }

  void _onHuePanUpdate(DragUpdateDetails details, double width) {
    final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _hue = ratio * 360);
    widget.onColorSelected(HSVColor.fromAHSV(1, _hue, _saturation, _brightness).toColor());
  }

  void _onHueTapDown(TapDownDetails details, double width) {
    final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _hue = ratio * 360);
    widget.onColorSelected(HSVColor.fromAHSV(1, _hue, _saturation, _brightness).toColor());
  }

  void _onBrightnessPanUpdate(DragUpdateDetails details, double width) {
    final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _brightness = ratio);
    widget.onColorSelected(HSVColor.fromAHSV(1, _hue, _saturation, _brightness).toColor());
  }

  void _onBrightnessTapDown(TapDownDetails details, double width) {
    final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _brightness = ratio);
    widget.onColorSelected(HSVColor.fromAHSV(1, _hue, _saturation, _brightness).toColor());
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = HSVColor.fromAHSV(1, _hue, _saturation, _brightness).toColor();
    final hueColor = HSVColor.fromAHSV(1, _hue, 1, 1).toColor();
    final isActive = widget.selectedColor != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hue bar
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return GestureDetector(
              onPanUpdate: (d) => _onHuePanUpdate(d, barWidth),
              onTapDown: (d) => _onHueTapDown(d, barWidth),
              child: Stack(
                children: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (_hue / 360 * barWidth - 12).clamp(0.0, barWidth - 24),
                    top: 0,
                    child: Container(
                      width: 24,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hueColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
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

        const SizedBox(height: 10),

        // Brightness bar
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return GestureDetector(
              onPanUpdate: (d) => _onBrightnessPanUpdate(d, barWidth),
              onTapDown: (d) => _onBrightnessTapDown(d, barWidth),
              child: Stack(
                children: [
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black,
                          hueColor,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (_brightness * barWidth - 10).clamp(0.0, barWidth - 20),
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 28,
                      decoration: BoxDecoration(
                        color: currentColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
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

        if (isActive) ...[
          const SizedBox(height: 12),
          // Selected custom color preview
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.15),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

