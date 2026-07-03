/// Full-screen Cook Mode: the dish hero pinned up top, one big readable step
/// at a time, a progress bar, and prev/next — the last step becoming
/// "DONE — LOG IT". Steps come from the suggestion's `instructions` list.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/ingredient_analysis.dart';
import 'fridge_dish_card.dart';

class FridgeCookMode extends StatefulWidget {
  final PantrySuggestion suggestion;

  /// Called when the user finishes the last step ("DONE — LOG IT"). Typically
  /// logs the meal. May be async; the screen pops after it resolves.
  final Future<void> Function()? onDone;

  const FridgeCookMode({super.key, required this.suggestion, this.onDone});

  @override
  State<FridgeCookMode> createState() => _FridgeCookModeState();
}

class _FridgeCookModeState extends State<FridgeCookMode> {
  int _i = 0;
  bool _finishing = false;

  List<String> get _steps => widget.suggestion.instructions;

  Future<void> _next() async {
    if (_i < _steps.length - 1) {
      setState(() => _i++);
      return;
    }
    // Last step → finish + log.
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      if (widget.onDone != null) await widget.onDone!();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_i > 0) setState(() => _i--);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final s = widget.suggestion;
    final total = _steps.length;
    final isLast = _i == total - 1;
    final progress = total == 0 ? 0.0 : (_i + 1) / total;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: tc.textMuted, size: 22),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                  ),
                  Text('${_i + 1} / $total',
                      style: TextStyle(color: tc.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FridgeDishImage(imageUrl: s.imageUrl),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 8,
                        right: 12,
                        child: Text(
                          s.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZType.lbl(13, color: Colors.white, letterSpacing: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('STEP ${_i + 1}',
                  style: ZType.lbl(13, color: accent, letterSpacing: 2)),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    total == 0 ? 'No steps provided for this recipe.' : _steps[_i],
                    style: TextStyle(
                        color: tc.textPrimary,
                        fontSize: 25,
                        height: 1.35,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _navBtn(
                      label: '← BACK',
                      primary: false,
                      tc: tc,
                      onTap: _i > 0 ? _prev : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _navBtn(
                      label: isLast ? 'DONE — LOG IT ✓' : 'NEXT STEP →',
                      primary: true,
                      tc: tc,
                      onTap: _finishing ? null : _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn({
    required String label,
    required bool primary,
    required ThemeColors tc,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? tc.accent : Colors.transparent,
            border: primary ? null : Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: ZType.lbl(14,
                color: primary ? tc.accentContrast : tc.textPrimary, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }
}
