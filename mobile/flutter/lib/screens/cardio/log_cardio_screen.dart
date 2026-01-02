import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/cardio_session.dart';
import '../../data/providers/cardio_session_provider.dart';
import '../../data/services/api_client.dart';

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

  // Focus nodes for keyboard handling
  final _durationFocus = FocusNode();
  final _distanceFocus = FocusNode();
  final _avgHrFocus = FocusNode();
  final _maxHrFocus = FocusNode();
  final _caloriesFocus = FocusNode();
  final _notesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserId();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final isSaving = ref.watch(isCardioSavingProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        title: Text('Log Cardio', style: TextStyle(color: textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.close, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cardio Type Section
              _SectionHeader(title: 'ACTIVITY TYPE', isDark: isDark)
                  .animate()
                  .fadeIn(),
              const SizedBox(height: 12),
              _CardioTypeSelector(
                selectedType: _selectedType,
                onSelect: (type) => setState(() => _selectedType = type),
                isDark: isDark,
              ).animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 24),

              // Location Section (Prominent)
              _SectionHeader(title: 'LOCATION', isDark: isDark)
                  .animate()
                  .fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
              _LocationSelector(
                selectedLocation: _selectedLocation,
                onSelect: (location) {
                  setState(() {
                    _selectedLocation = location;
                    // Clear weather if switching to indoor
                    if (!location.isOutdoor) {
                      _selectedWeather = null;
                    }
                  });
                },
                isDark: isDark,
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // Duration Input (Required)
              _SectionHeader(title: 'DURATION', isDark: isDark)
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              _DurationInput(
                controller: _durationController,
                focusNode: _durationFocus,
                isDark: isDark,
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 24),

              // Optional Fields Section
              _SectionHeader(title: 'OPTIONAL DETAILS', isDark: isDark)
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 12),

              // Distance
              _InputField(
                controller: _distanceController,
                focusNode: _distanceFocus,
                label: 'Distance',
                suffix: 'km',
                icon: Icons.straighten,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                isDark: isDark,
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 12),

              // Heart Rate Row
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      controller: _avgHeartRateController,
                      focusNode: _avgHrFocus,
                      label: 'Avg HR',
                      suffix: 'bpm',
                      icon: Icons.favorite_outline,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InputField(
                      controller: _maxHeartRateController,
                      focusNode: _maxHrFocus,
                      label: 'Max HR',
                      suffix: 'bpm',
                      icon: Icons.favorite,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),

              // Calories
              _InputField(
                controller: _caloriesController,
                focusNode: _caloriesFocus,
                label: 'Calories Burned',
                suffix: 'kcal',
                icon: Icons.local_fire_department,
                keyboardType: TextInputType.number,
                isDark: isDark,
              ).animate().fadeIn(delay: 450.ms),

              // Weather Selector (only for outdoor)
              if (_selectedLocation.isOutdoor) ...[
                const SizedBox(height: 24),
                _SectionHeader(title: 'WEATHER CONDITIONS', isDark: isDark)
                    .animate()
                    .fadeIn(delay: 500.ms),
                const SizedBox(height: 12),
                _WeatherSelector(
                  selectedWeather: _selectedWeather,
                  onSelect: (weather) =>
                      setState(() => _selectedWeather = weather),
                  isDark: isDark,
                ).animate().fadeIn(delay: 550.ms),
              ],

              const SizedBox(height: 24),

              // Notes
              _SectionHeader(title: 'NOTES', isDark: isDark)
                  .animate()
                  .fadeIn(delay: 600.ms),
              const SizedBox(height: 12),
              _NotesInput(
                controller: _notesController,
                focusNode: _notesFocus,
                isDark: isDark,
              ).animate().fadeIn(delay: 650.ms),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: electricBlue,
                    disabledBackgroundColor: electricBlue.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Cardio Session',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 700.ms).scale(delay: 700.ms),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

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
              '${_selectedType.label} session logged - ${session.formattedDuration}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(session);
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
// Section Header
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Cardio Type Selector
// ─────────────────────────────────────────────────────────────────

class _CardioTypeSelector extends StatelessWidget {
  final CardioType selectedType;
  final ValueChanged<CardioType> onSelect;
  final bool isDark;

  const _CardioTypeSelector({
    required this.selectedType,
    required this.onSelect,
    required this.isDark,
  });

  IconData _getIcon(CardioType type) {
    switch (type) {
      case CardioType.running:
        return Icons.directions_run;
      case CardioType.cycling:
        return Icons.directions_bike;
      case CardioType.rowing:
        return Icons.rowing;
      case CardioType.elliptical:
        return Icons.fitness_center;
      case CardioType.swimming:
        return Icons.pool;
      case CardioType.walking:
        return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final cardio = isDark ? AppColors.cardio : AppColorsLight.cardio;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: CardioType.values.map((type) {
        final isSelected = type == selectedType;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? cardio.withOpacity(0.15) : elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cardio : elevated,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIcon(type),
                  size: 20,
                  color: isSelected ? cardio : textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? textPrimary : textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Location Selector (Prominent)
// ─────────────────────────────────────────────────────────────────

class _LocationSelector extends StatelessWidget {
  final CardioLocation selectedLocation;
  final ValueChanged<CardioLocation> onSelect;
  final bool isDark;

  const _LocationSelector({
    required this.selectedLocation,
    required this.onSelect,
    required this.isDark,
  });

  IconData _getIcon(CardioLocation location) {
    switch (location) {
      case CardioLocation.indoor:
        return Icons.home;
      case CardioLocation.outdoor:
        return Icons.nature_people;
      case CardioLocation.treadmill:
        return Icons.fitness_center;
      case CardioLocation.track:
        return Icons.stadium;
      case CardioLocation.trail:
        return Icons.terrain;
      case CardioLocation.pool:
        return Icons.pool;
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: CardioLocation.values.map((location) {
          final isSelected = location == selectedLocation;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(location);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? cyan.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? cyan : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(location),
                    size: 28,
                    color: isSelected ? cyan : textMuted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    location.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? textPrimary : textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Duration Input
// ─────────────────────────────────────────────────────────────────

class _DurationInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;

  const _DurationInput({
    required this.controller,
    required this.focusNode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            electricBlue.withOpacity(0.15),
            electricBlue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: electricBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: electricBlue, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '30',
                hintStyle: TextStyle(color: textMuted),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            'minutes',
            style: TextStyle(
              fontSize: 18,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Input Field
// ─────────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? suffix;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isDark;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.suffix,
    required this.icon,
    this.keyboardType = TextInputType.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : keyboardType == const TextInputType.numberWithOptions(decimal: true)
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted),
        suffixText: suffix,
        suffixStyle: TextStyle(color: textMuted),
        prefixIcon: Icon(icon, color: textMuted, size: 20),
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Weather Selector
// ─────────────────────────────────────────────────────────────────

class _WeatherSelector extends StatelessWidget {
  final WeatherCondition? selectedWeather;
  final ValueChanged<WeatherCondition?> onSelect;
  final bool isDark;

  const _WeatherSelector({
    required this.selectedWeather,
    required this.onSelect,
    required this.isDark,
  });

  IconData _getIcon(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.cloudy:
        return Icons.cloud;
      case WeatherCondition.partlyCloudy:
        return Icons.cloud_queue;
      case WeatherCondition.rainy:
        return Icons.water_drop;
      case WeatherCondition.windy:
        return Icons.air;
      case WeatherCondition.hot:
        return Icons.thermostat;
      case WeatherCondition.cold:
        return Icons.ac_unit;
      case WeatherCondition.humid:
        return Icons.water;
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WeatherCondition.values.map((weather) {
        final isSelected = weather == selectedWeather;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(isSelected ? null : weather);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? orange.withOpacity(0.15) : elevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? orange : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIcon(weather),
                  size: 16,
                  color: isSelected ? orange : textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  weather.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? textPrimary : textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Notes Input
// ─────────────────────────────────────────────────────────────────

class _NotesInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;

  const _NotesInput({
    required this.controller,
    required this.focusNode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: 3,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        hintText: 'How did the session feel? Any notes...',
        hintStyle: TextStyle(color: textMuted),
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
