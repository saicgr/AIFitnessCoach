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


/// Horizontal scrollable row of month pills for accessing past Wrapped recaps.
class _WrappedSection extends ConsumerWidget {
  final Color elevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;

  const _WrappedSection({
    required this.elevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
  });

  static String _formatVolume(double lbs) {
    if (lbs >= 1000000) return '${(lbs / 1000000).toStringAsFixed(1)}M lbs';
    if (lbs >= 1000) return '${(lbs / 1000).toStringAsFixed(0)}K lbs';
    return '${lbs.toStringAsFixed(0)} lbs';
  }

  static String _monthName(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[(month - 1).clamp(0, 11)]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(wrappedSummaryProvider);
    final accent = ref.colors(context).accent;
    final accentGradient = ref.colors(context).accentGradient;

    return summaryAsync.when(
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildEmptyTeaser(context, accent, accentGradient),
      data: (summary) => _buildTeaser(context, summary, accent, accentGradient),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: textMuted),
        ),
      ),
    );
  }

  /// Compact teaser shown on profile — tapping navigates to MyWrappedScreen
  Widget _buildTeaser(BuildContext context, WrappedSummary summary, Color accent, LinearGradient accentGradient) {
    final hasAvailable = summary.available.isNotEmpty;

    if (!hasAvailable) {
      return _buildEmptyTeaser(context, accent, accentGradient);
    }

    final latest = summary.available.first;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/my-wrapped');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            width: 1.5,
            color: accent.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Personality gradient badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: accentGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  latest.personality != null
                      ? latest.personality!.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthName(latest.period),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (latest.personality != null)
                    Text(
                      latest.personality!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${latest.totalWorkouts} workouts  ·  ${_formatVolume(latest.totalVolumeLbs)}',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state teaser — still tappable to see the My Wrapped screen
  Widget _buildEmptyTeaser(BuildContext context, Color accent, LinearGradient accentGradient) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/my-wrapped');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: accentGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Center(
                child: Text('?', style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Wrapped',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Complete 3 workouts to unlock',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: textMuted,
            ),
          ],
        ),
      ),
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


/// Horizontally scrollable row of synced (Health Connect / Apple Health) workouts.
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

  IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
      case 'flexibility':
      case 'stretching':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.local_fire_department;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.sync_rounded;
    }
  }

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
          style: TextStyle(
            fontSize: 13,
            color: textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: syncedWorkouts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final workout = syncedWorkouts[index];
          final metadata = workout.generationMetadata ?? {};
          final sourceApp = metadata['source_app_name'] as String?;
          final dateStr = workout.scheduledDate?.split('T')[0] ?? '';

          return GestureDetector(
            onTap: () {
              HapticService.selection();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SyncedWorkoutDetailScreen(workout: workout),
                ),
              );
            },
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _iconForType(workout.type),
                        size: 16,
                        color: textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          workout.name ?? 'Workout',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (dateStr.isNotEmpty)
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  if (workout.durationMinutes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${workout.durationMinutes} min',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                  const Spacer(),
                  if (sourceApp != null)
                    Text(
                      sourceApp,
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

