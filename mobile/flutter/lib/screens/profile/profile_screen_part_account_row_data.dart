part of 'profile_screen.dart';


/// Helper data class for account group card rows.
class _AccountRowData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _AccountRowData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });
}


/// Widget to manage custom equipment from profile
class _CustomEquipmentManager extends StatefulWidget {
  final ScrollController scrollController;
  final WidgetRef ref;

  const _CustomEquipmentManager({
    required this.scrollController,
    required this.ref,
  });

  @override
  State<_CustomEquipmentManager> createState() =>
      _CustomEquipmentManagerState();
}


class _CustomEquipmentManagerState extends State<_CustomEquipmentManager> {
  List<String> _customEquipment = [];
  final _textController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadCustomEquipment();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomEquipment() async {
    debugPrint('🏋️ [CustomEquipment] Loading custom equipment...');
    try {
      final authState = widget.ref.read(authStateProvider);
      _userId = authState.user?.id;

      if (_userId == null) {
        debugPrint('⚠️ [CustomEquipment] User not logged in');
        setState(() => _isLoading = false);
        return;
      }

      // Fetch user data to get custom_equipment
      final apiClient = widget.ref.read(apiClientProvider);
      final response = await apiClient.get('/users/$_userId');

      if (response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        final customEquipmentData = userData['custom_equipment'];

        List<String> equipment = [];
        if (customEquipmentData != null) {
          if (customEquipmentData is List) {
            equipment = List<String>.from(customEquipmentData);
          } else if (customEquipmentData is String &&
              customEquipmentData.isNotEmpty) {
            try {
              final decoded = jsonDecode(customEquipmentData);
              if (decoded is List) {
                equipment = List<String>.from(decoded);
              }
            } catch (e) {
              debugPrint('⚠️ [CustomEquipment] Error parsing: $e');
            }
          }
        }

        debugPrint(
            '✅ [CustomEquipment] Loaded ${equipment.length} custom equipment items');
        setState(() {
          _customEquipment = equipment;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ [CustomEquipment] Error loading: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCustomEquipment() async {
    if (_userId == null) return;

    setState(() => _isSaving = true);
    debugPrint(
        '💾 [CustomEquipment] Saving ${_customEquipment.length} items...');

    try {
      final apiClient = widget.ref.read(apiClientProvider);
      await apiClient.put(
        '/users/$_userId',
        data: {
          'custom_equipment': _customEquipment,
        },
      );
      debugPrint('✅ [CustomEquipment] Saved successfully');
    } catch (e) {
      debugPrint('❌ [CustomEquipment] Error saving: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to save: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addEquipment(String name) async {
    if (name.trim().isEmpty) return;

    final trimmed = name.trim();
    if (_customEquipment.contains(trimmed)) {
      AppSnackBar.info(context, '$trimmed is already in your list');
      return;
    }

    setState(() {
      _customEquipment.add(trimmed);
    });
    _textController.clear();

    await _saveCustomEquipment();

    if (mounted) {
      AppSnackBar.success(context, 'Added "$trimmed" to your equipment');
    }
  }

  Future<void> _removeEquipment(String name) async {
    setState(() {
      _customEquipment.remove(name);
    });

    await _saveCustomEquipment();

    if (mounted) {
      AppSnackBar.info(context, 'Removed "$name"');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Monochrome accent
    final accentColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    return Column(
      children: [
        // Add Equipment Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Enter equipment name...',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _addEquipment,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addEquipment(_textController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Equipment List
        Expanded(
          child: _customEquipment.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No custom equipment yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add equipment above to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _customEquipment.length,
                  itemBuilder: (context, index) {
                    final equipment = _customEquipment[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.pureBlack
                            : AppColorsLight.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          equipment,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 22,
                          ),
                          onPressed: () => _removeEquipment(equipment),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Card for training focus settings (primary goal & muscle focus points)
class _TrainingFocusCard extends ConsumerWidget {
  const _TrainingFocusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.colors(context).accent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/settings/training-focus');
      },
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Training Focus',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Primary goal & muscle priorities',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Horizontally scrollable row of synced (Health Connect / Apple Health)
/// workouts. Each card is tinted by the workout's granular kind (walking =
/// green, cycling = blue…). A dashed "See all" card trails the list and
/// opens the full history screen.
class _SyncedWorkoutsRow extends ConsumerWidget {
  final Color elevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;

  const _SyncedWorkoutsRow({
    required this.elevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncedWorkouts = ref.watch(syncedWorkoutsProvider);

    if (syncedWorkouts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Text(
          'No synced workouts yet',
          style: TextStyle(fontSize: 13, color: textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }

    final count = syncedWorkouts.length;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final height = (156 * textScale).clamp(156.0, 210.0);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count + 1, // +1 for "See all" trailing card
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == count) {
            return _SeeAllSyncedCard(count: count, height: height);
          }
          return _SyncedWorkoutCard(
            workout: syncedWorkouts[index],
            height: height,
          );
        },
      ),
    );
  }
}

class _SyncedWorkoutCard extends ConsumerWidget {
  final Workout workout;
  final double height;

  const _SyncedWorkoutCard({required this.workout, required this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadata = workout.generationMetadata ?? {};
    final kindRaw = metadata['hc_activity_kind'] as String? ?? workout.type;
    final kind = SyncedKind.fromString(kindRaw);
    final palette = kind.palette(isDark);
    final sourceApp = metadata['source_app'] as String?
        ?? metadata['source_app_name'] as String?
        ?? (Theme.of(context).platform == TargetPlatform.iOS
            ? 'Apple Health'
            : 'Health Connect');
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final dateLabel = _formatDateShort(workout.scheduledDate);
    final metricChips = _topMetricsFor(kind, metadata, workout);

    // Primary = user-visible workout name (from the source app, e.g.
    // "Imported Cardio Workout", "Morning Run"). Secondary = activity
    // kind tag ("Walking"/"Cycling") so both are visible.
    final primaryTitle = (workout.name?.trim().isNotEmpty ?? false)
        ? workout.name!.trim()
        : kind.label;
    final kindTag = (workout.name?.trim().isNotEmpty ?? false) &&
            kind != SyncedKind.other
        ? kind.label
        : null;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        // Hide the floating nav bar while the detail is on top — it
        // otherwise floats over the session/RPE content.
        ref.read(floatingNavBarVisibleProvider.notifier).state = false;
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) => SyncedWorkoutDetailScreen(workout: workout),
          ),
        )
            .whenComplete(() {
          ref.read(floatingNavBarVisibleProvider.notifier).state = true;
        });
      },
      child: Container(
        width: 180,
        height: height,
        decoration: BoxDecoration(
          color: palette.bg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: palette.fg.withValues(alpha: isDark ? 0.28 : 0.35),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -14,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.21,
                  child: Icon(
                    kind.icon,
                    size: 96,
                    color: palette.fg.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KindAvatar(kind: kind, size: 36),
                      if (kindTag != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: palette.fg.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              kindTag.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: palette.fg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            primaryTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dateLabel${workout.durationMinutes != null ? ' · ${workout.durationMinutes} min' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                          if (metricChips.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                for (int i = 0; i < metricChips.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Flexible(child: metricChips[i]),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sourceApp,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: palette.fg.withValues(alpha: isDark ? 0.9 : 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pick up to two best-available metric chips for the card using the
  /// kind's default metric priority, falling back gracefully when data is
  /// missing.
  List<Widget> _topMetricsFor(
    SyncedKind kind,
    Map<String, dynamic> metadata,
    Workout workout,
  ) {
    final results = <Widget>[];
    for (final key in kind.heroMetricOrder) {
      final chip = _chipForMetric(key, metadata, workout);
      if (chip != null) {
        results.add(chip);
        if (results.length >= 2) break;
      }
    }
    return results;
  }

  Widget? _chipForMetric(
    String key,
    Map<String, dynamic> metadata,
    Workout workout,
  ) {
    switch (key) {
      case 'distance_m':
        final m = (metadata['distance_m'] ?? metadata['distance_meters']) as num?;
        if (m == null || m <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.distance,
          value: _formatDistance(m.toDouble()),
          unit: _distanceUnitLabel(),
        );
      case 'calories_active':
        final c = (metadata['calories_active'] ?? metadata['calories_burned']) as num?;
        if (c == null || c <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.calories,
          value: _formatInt(c),
          unit: 'kcal',
        );
      case 'steps':
        final s = (metadata['steps'] ?? metadata['total_steps']) as num?;
        if (s == null || s <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.steps,
          value: _formatInt(s),
          unit: 'steps',
        );
      case 'avg_heart_rate':
        final h = metadata['avg_heart_rate'] as num?;
        if (h == null || h <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.heartRate,
          value: _formatInt(h),
          unit: 'bpm',
        );
      case 'max_heart_rate':
        final h = metadata['max_heart_rate'] as num?;
        if (h == null || h <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.heartRate,
          value: _formatInt(h),
          unit: 'peak',
        );
      case 'duration':
        if (workout.durationMinutes == null) return null;
        return MetricChip(
          dotColor: MetricColors.duration,
          value: _formatDuration(workout.durationMinutes!),
        );
      case 'elevation_gain_m':
        final e = metadata['elevation_gain_m'] as num?;
        if (e == null || e <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.elevation,
          value: _formatInt(e),
          unit: 'm gain',
        );
      case 'avg_speed_mps':
        final s = metadata['avg_speed_mps'] as num?;
        if (s == null || s <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.pace,
          value: (s.toDouble() * 2.23694).toStringAsFixed(1),
          unit: 'mph',
        );
      case 'pace_sec_per_km':
        final p = metadata['pace_sec_per_km'] as num?;
        if (p == null || p <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.pace,
          value: _formatPacePerMile(p.toDouble()),
          unit: '/mi',
        );
      case 'avg_respiratory_rate':
        final r = metadata['avg_respiratory_rate'] as num?;
        if (r == null || r <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.respRate,
          value: _formatInt(r),
          unit: 'br/min',
        );
      default:
        return null;
    }
  }

  String _formatDateShort(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatDistance(double meters) {
    // Default to miles for US; meters fallback if very short.
    if (meters < 50) return '${meters.round()}m';
    final miles = meters * 0.000621371;
    return miles.toStringAsFixed(miles >= 10 ? 1 : 2);
  }

  String _distanceUnitLabel() => 'mi';

  String _formatInt(num v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.round().toString();
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }

  String _formatPacePerMile(double secPerKm) {
    // secPerKm → sec per mile
    final secPerMi = secPerKm * 1.609344;
    final m = (secPerMi ~/ 60).toInt();
    final s = (secPerMi % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Trailing "See all" card that opens the full synced-workout history
/// screen. Shares dimensions with the main cards so the strip stays clean.
class _SeeAllSyncedCard extends StatelessWidget {
  final int count;
  final double height;

  const _SeeAllSyncedCard({required this.count, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/profile/synced-workouts');
      },
      child: CustomPaint(
        painter: _DashedBorderPainter(color: accent, radius: 16),
        child: Container(
          width: 180,
          height: height,
          decoration: BoxDecoration(
            color: elevated.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count session${count == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  static const double _dashLen = 6;
  static const double _gapLen = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double d = 0;
      while (d < m.length) {
        final end = (d + _dashLen).clamp(0, m.length).toDouble();
        canvas.drawPath(m.extractPath(d, end), paint);
        d = end + _gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

