import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/training_intensity_provider.dart';
import '../../../data/models/training_intensity.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../core/services/posthog_service.dart';
import '../../../utils/share_report_helper.dart';
import '../../../widgets/pill_app_bar.dart';

// Import linked exercises types
export '../../../data/models/training_intensity.dart' show LinkedExercise, ExerciseLinkSuggestion;

part 'my_1rms_screen_part_one_r_m_card.dart';


/// Screen for viewing and editing user's stored 1RMs
class My1RMsScreen extends ConsumerStatefulWidget {
  const My1RMsScreen({super.key});

  @override
  ConsumerState<My1RMsScreen> createState() => _My1RMsScreenState();
}

class _My1RMsScreenState extends ConsumerState<My1RMsScreen> {
  bool _isAutoPopulating = false;
  final GlobalKey _reportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'my_1rms_viewed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final oneRMsState = ref.watch(userOneRMsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
      appBar: PillAppBar(
        title: 'My 1RMs',
        actions: [
          if (!oneRMsState.isLoading && oneRMsState.oneRMs.isNotEmpty)
            PillAppBarAction(
              icon: Icons.ios_share_rounded,
              onTap: () => shareReportScreen(
                context: context,
                repaintKey: _reportKey,
                caption: 'My FitWiz 1-rep max report',
                subject: 'My 1RMs',
              ),
            ),
          if (!oneRMsState.isLoading)
            PillAppBarAction(
              icon: Icons.auto_awesome,
              onTap: _autoPopulate,
            ),
        ],
      ),
      body: oneRMsState.isLoading || _isAutoPopulating
          ? const Center(child: CircularProgressIndicator())
          : oneRMsState.oneRMs.isEmpty
              ? _buildEmptyState(context, isDark, textPrimary, textMuted)
              : RepaintBoundary(
                  key: _reportKey,
                  child: Container(
                    color: isDark
                        ? AppColors.pureBlack
                        : AppColorsLight.background,
                    child: _buildList(context, oneRMsState.oneRMs, isDark,
                        textPrimary, textMuted, elevated, cardBorder),
                  ),
                ),
      // Hide the FAB on empty state and while loading — the primary CTA
      // lives INSIDE the empty state as a FilledButton so there aren't
      // two competing affordances floating on an otherwise blank screen.
      floatingActionButton: (oneRMsState.isLoading ||
              _isAutoPopulating ||
              oneRMsState.oneRMs.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddOneRMSheet(context),
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add 1RM'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    // Scale the header-to-CTA gap with text scaler so large accessibility
    // settings don't cram the icon/title/buttons together.
    final scaler = MediaQuery.textScalerOf(context);
    final headerGap = scaler.scale(24.0).clamp(24.0, 40.0);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          // Cap CTA column width so the FilledButton doesn't stretch to
          // absurd widths on tablets.
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 80,
                color: textMuted.withValues(alpha: 0.5),
              ),
              SizedBox(height: headerGap),
              Text(
                'No 1RMs Recorded',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your max lifts to get personalized weight recommendations based on your training intensity.',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: headerGap),
              // Primary CTA — auto-populate is the much higher-leverage
              // first action for a brand-new user with existing workout
              // history. Disabled while the request is in flight.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isAutoPopulating ? null : _autoPopulate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Auto-populate from workout history'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Secondary CTA — manual entry.
              TextButton.icon(
                onPressed: _isAutoPopulating
                    ? null
                    : () => _showAddOneRMSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add manually'),
                style: TextButton.styleFrom(
                  foregroundColor: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<UserExercise1RM> oneRMs,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    // Sort alphabetically
    final sorted = List<UserExercise1RM>.from(oneRMs)
      ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(userOneRMsProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final rm = sorted[index];
          return _OneRMCard(
            oneRM: rm,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            elevated: elevated,
            cardBorder: cardBorder,
            onEdit: () => _showEditOneRMSheet(context, rm),
            onDelete: () => _deleteOneRM(rm),
          );
        },
      ),
    );
  }

  Future<void> _autoPopulate() async {
    setState(() => _isAutoPopulating = true);

    final response = await ref.read(userOneRMsProvider.notifier).autoPopulate();

    setState(() => _isAutoPopulating = false);

    if (response != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: response.count > 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _showAddOneRMSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _AddEditOneRMSheet(
          onSave: (exerciseName, weight, source) async {
            final success = await ref.read(userOneRMsProvider.notifier).setOneRM(
              exerciseName: exerciseName,
              oneRepMaxKg: weight,
              source: source,
            );
            if (success && mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _showEditOneRMSheet(BuildContext context, UserExercise1RM oneRM) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _AddEditOneRMSheet(
          existingOneRM: oneRM,
          onSave: (exerciseName, weight, source) async {
            final success = await ref.read(userOneRMsProvider.notifier).setOneRM(
              exerciseName: exerciseName,
              oneRepMaxKg: weight,
              source: source,
            );
            if (success && mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteOneRM(UserExercise1RM oneRM) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete 1RM?'),
        content: Text('Remove ${oneRM.exerciseName} from your saved 1RMs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(userOneRMsProvider.notifier).deleteOneRM(oneRM.exerciseName);
    }
  }
}
