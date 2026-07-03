/// Log Cardio — manual entry for a finished cardio session.
///
/// 2026-07 revamp: restyled into the Signature design language (ThemeColors +
/// ZType, hairline borders, single accent) replacing the legacy electric-blue
/// look. Structure: Describe-it AI autofill hero → activity chips → location
/// chips → duration card with quick-pick minutes → optional details →
/// weather (outdoor only) → notes → save. All logging/parse logic is
/// unchanged — only the visual layer moved.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/cardio_session.dart';
import '../../data/providers/cardio_session_provider.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';

class LogCardioScreen extends ConsumerStatefulWidget {
  final String? workoutId;

  const LogCardioScreen({super.key, this.workoutId});

  @override
  ConsumerState<LogCardioScreen> createState() => _LogCardioScreenState();
}

class _LogCardioScreenState extends ConsumerState<LogCardioScreen> {
  String? _userId;
  CardioType _selectedType = CardioType.running;
  CardioLocation _selectedLocation = CardioLocation.outdoor;
  WeatherCondition? _selectedWeather;

  // Form controllers
  final _durationController = TextEditingController(text: '30');
  final _distanceController = TextEditingController();
  final _avgHeartRateController = TextEditingController();
  final _maxHeartRateController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  // NL quick-entry (Calorii-audit P4.3): "30 min brisk walk" → auto-fill.
  final _describeController = TextEditingController();
  bool _parsing = false;

  // Focus nodes for keyboard handling
  final _durationFocus = FocusNode();
  final _distanceFocus = FocusNode();
  final _avgHrFocus = FocusNode();
  final _maxHrFocus = FocusNode();
  final _caloriesFocus = FocusNode();
  final _notesFocus = FocusNode();

  /// Quick-pick minute presets shown under the duration field.
  static const _durationPresets = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'cardio_log_viewed');
    });
  }

  Future<void> _loadUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted) {
      setState(() => _userId = userId);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _avgHeartRateController.dispose();
    _maxHeartRateController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    _describeController.dispose();
    _durationFocus.dispose();
    _distanceFocus.dispose();
    _avgHrFocus.dispose();
    _maxHrFocus.dispose();
    _caloriesFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final loc = AppLocalizations.of(context);
    final isSaving = ref.watch(isCardioSavingProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: PillAppBar(title: loc.logCardioLogCardio),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Natural-language quick entry — the fastest path. Type it once
              // ("30 min brisk walk", "ran 5k") and auto-fill the form below.
              _sectionLabel(c, 'DESCRIBE IT'),
              const SizedBox(height: 10),
              _buildDescribeCard(c),

              const SizedBox(height: 26),

              _sectionLabel(c, loc.logCardioActivityType),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in CardioType.values)
                    _SelectChip(
                      colors: c,
                      icon: _typeIcon(type),
                      label: type.label,
                      selected: type == _selectedType,
                      onTap: () => setState(() => _selectedType = type),
                    ),
                ],
              ),

              const SizedBox(height: 26),

              _sectionLabel(c, loc.logCardioLocation),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final location in CardioLocation.values)
                    _SelectChip(
                      colors: c,
                      icon: _locationIcon(location),
                      label: location.label,
                      selected: location == _selectedLocation,
                      onTap: () => setState(() {
                        _selectedLocation = location;
                        // Weather only applies outdoors.
                        if (!location.isOutdoor) _selectedWeather = null;
                      }),
                    ),
                ],
              ),

              const SizedBox(height: 26),

              _sectionLabel(c, loc.logCardioDuration),
              const SizedBox(height: 10),
              _buildDurationCard(c),

              const SizedBox(height: 26),

              _sectionLabel(c, loc.logCardioOptionalDetails),
              const SizedBox(height: 10),
              _InputField(
                controller: _distanceController,
                focusNode: _distanceFocus,
                label: loc.workoutImportDistance,
                suffix: 'km',
                icon: Icons.straighten_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                colors: c,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      controller: _avgHeartRateController,
                      focusNode: _avgHrFocus,
                      label: loc.workoutDayDetailAvgHr,
                      suffix: 'bpm',
                      icon: Icons.favorite_outline,
                      keyboardType: TextInputType.number,
                      colors: c,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InputField(
                      controller: _maxHeartRateController,
                      focusNode: _maxHrFocus,
                      label: loc.workoutDayDetailMaxHr,
                      suffix: 'bpm',
                      icon: Icons.monitor_heart_outlined,
                      keyboardType: TextInputType.number,
                      colors: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InputField(
                controller: _caloriesController,
                focusNode: _caloriesFocus,
                label: loc.metricsDashboardCaloriesBurned,
                suffix: 'kcal',
                icon: Icons.local_fire_department_outlined,
                keyboardType: TextInputType.number,
                colors: c,
              ),

              // Weather (outdoor sessions only).
              if (_selectedLocation.isOutdoor) ...[
                const SizedBox(height: 26),
                _sectionLabel(c, loc.logCardioWeatherConditions),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final weather in WeatherCondition.values)
                      _SelectChip(
                        colors: c,
                        icon: _weatherIcon(weather),
                        label: weather.label,
                        selected: weather == _selectedWeather,
                        compact: true,
                        onTap: () => setState(
                          () => _selectedWeather =
                              weather == _selectedWeather ? null : weather,
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 26),

              _sectionLabel(c, 'NOTES'),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                focusNode: _notesFocus,
                maxLines: 3,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: _fieldDecoration(c).copyWith(
                  hintText: loc.logCardioHowDidTheSession,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              const SizedBox(height: 28),

              // Save
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isSaving ? null : _saveSession,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    disabledBackgroundColor: c.accent.withValues(alpha: 0.5),
                    foregroundColor: c.accentContrast,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.accentContrast,
                          ),
                        )
                      : Text(
                          loc.logCardioSaveCardioSession,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: c.accentContrast,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section pieces ─────────────────────────────────────────────────

  Widget _sectionLabel(ThemeColors c, String text) => Text(
        text.toUpperCase(),
        style: ZType.lbl(10, color: c.textMuted, letterSpacing: 1.6),
      );

  /// Describe-it hero: free text + accent Auto-fill action in one bordered
  /// card, so the AI path reads as the primary way in.
  Widget _buildDescribeCard(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 18, color: c.accent),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _describeController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _parseDescription(),
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. 30 min brisk walk, ran 5k…',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _parsing
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _parseDescription,
                  style: TextButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.accentContrast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Auto-fill',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
        ],
      ),
    );
  }

  /// Duration: big centred minutes field + one-tap presets.
  Widget _buildDurationCard(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.accent.withValues(alpha: 0.06), c.surface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: c.accent, size: 24),
              Expanded(
                child: TextField(
                  controller: _durationController,
                  focusNode: _durationFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: ZType.disp(34, color: c.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '30',
                    hintStyle: ZType.disp(34, color: c.textMuted),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Text('min', style: ZType.lbl(12, color: c.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, preset) in _durationPresets.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _PresetPill(
                    colors: c,
                    label: '$preset',
                    selected: _durationController.text == '$preset',
                    onTap: () {
                      HapticService.light();
                      setState(() => _durationController.text = '$preset');
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(ThemeColors c) => InputDecoration(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.cardBorder),
        ),
      );

  // ── Glyphs ─────────────────────────────────────────────────────────

  IconData _typeIcon(CardioType type) {
    switch (type) {
      case CardioType.running:
        return Icons.directions_run_rounded;
      case CardioType.cycling:
        return Icons.pedal_bike_rounded;
      case CardioType.rowing:
        return Icons.rowing_rounded;
      case CardioType.elliptical:
        // Closest material glyph to a cross-trainer's arm+leg stride; the old
        // dumbbell (fitness_center) read as strength, not cardio.
        return Icons.nordic_walking_rounded;
      case CardioType.swimming:
        return Icons.waves_rounded;
      case CardioType.walking:
        return Icons.directions_walk_rounded;
    }
  }

  IconData _locationIcon(CardioLocation location) {
    switch (location) {
      case CardioLocation.indoor:
        return Icons.home_rounded;
      case CardioLocation.outdoor:
        // A tree — the old nature_people glyph read as "person with balloon".
        return Icons.park_rounded;
      case CardioLocation.treadmill:
        // A belt — the old fitness_center dumbbell said "weights", not
        // treadmill.
        return Icons.conveyor_belt;
      case CardioLocation.track:
        return Icons.stadium_rounded;
      case CardioLocation.trail:
        return Icons.forest_rounded;
      case CardioLocation.pool:
        return Icons.pool_rounded;
    }
  }

  IconData _weatherIcon(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny_outlined;
      case WeatherCondition.cloudy:
        return Icons.cloud_outlined;
      case WeatherCondition.partlyCloudy:
        return Icons.cloud_queue_outlined;
      case WeatherCondition.rainy:
        return Icons.water_drop_outlined;
      case WeatherCondition.windy:
        return Icons.air_rounded;
      case WeatherCondition.hot:
        return Icons.thermostat_outlined;
      case WeatherCondition.cold:
        return Icons.ac_unit_outlined;
      case WeatherCondition.humid:
        return Icons.water_outlined;
    }
  }

  // ── Actions (unchanged logic) ──────────────────────────────────────

  Future<void> _saveSession() async {
    if (_userId == null) {
      _showError('User not authenticated');
      return;
    }

    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      _showError('Please enter a valid duration');
      return;
    }

    final distance = _distanceController.text.isNotEmpty
        ? double.tryParse(_distanceController.text)
        : null;
    final avgHr = _avgHeartRateController.text.isNotEmpty
        ? int.tryParse(_avgHeartRateController.text)
        : null;
    final maxHr = _maxHeartRateController.text.isNotEmpty
        ? int.tryParse(_maxHeartRateController.text)
        : null;
    final calories = _caloriesController.text.isNotEmpty
        ? int.tryParse(_caloriesController.text)
        : null;
    final notes =
        _notesController.text.isNotEmpty ? _notesController.text : null;

    final session = await ref.read(cardioProvider.notifier).logSession(
          userId: _userId!,
          cardioType: _selectedType,
          location: _selectedLocation,
          durationMinutes: duration,
          distanceKm: distance,
          avgHeartRate: avgHr,
          maxHeartRate: maxHr,
          caloriesBurned: calories,
          notes: notes,
          weatherCondition: _selectedLocation.isOutdoor ? _selectedWeather : null,
          workoutId: widget.workoutId,
        );

    if (session != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).logCardioScreenSessionLogged(_selectedType.label, session.formattedDuration)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(session);
    }
  }

  /// Parse the free-text description via the deterministic backend parser and
  /// pre-fill type/duration/distance/calories. (Calorii-audit P4.3.)
  Future<void> _parseDescription() async {
    final text = _describeController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _parsing = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post(
        '/cardio/parse-text',
        data: {'text': text},
      );
      final d = (res.data as Map).cast<String, dynamic>();
      if (!mounted) return;
      setState(() {
        final ct = d['cardio_type'] as String?;
        if (ct != null) _selectedType = CardioType.fromValue(ct);
        final dur = d['duration_minutes'];
        if (dur != null) _durationController.text = '$dur';
        final dist = d['distance_km'];
        if (dist != null) _distanceController.text = '${dist is num ? dist : dist}';
        final cal = d['calories_burned'];
        if (cal != null) _caloriesController.text = '$cal';
      });
    } catch (_) {
      if (mounted) {
        _showError('Couldn\'t read that. Try e.g. "30 min brisk walk".');
      }
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Select chip — shared by activity / location / weather rows
// ─────────────────────────────────────────────────────────────────

class _SelectChip extends StatelessWidget {
  final ThemeColors colors;
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _SelectChip({
    required this.colors,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final tint = selected ? c.accent : c.textMuted;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 8 : 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(c.accent.withValues(alpha: 0.13), c.surface)
              : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.accent : c.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 15 : 18, color: tint),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 12 : 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.textPrimary : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Duration preset pill
// ─────────────────────────────────────────────────────────────────

class _PresetPill extends StatelessWidget {
  final ThemeColors colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetPill({
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? c.accent : c.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? c.accentContrast : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Input field — hairline-bordered optional details
// ─────────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? suffix;
  final IconData icon;
  final TextInputType keyboardType;
  final ThemeColors colors;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.suffix,
    required this.icon,
    this.keyboardType = TextInputType.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : keyboardType == const TextInputType.numberWithOptions(decimal: true)
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.textMuted, fontSize: 13),
        suffixText: suffix,
        suffixStyle: TextStyle(color: c.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: c.textMuted, size: 19),
        filled: true,
        fillColor: c.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.cardBorder),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}
