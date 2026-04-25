part of 'quick_actions_row.dart';


/// Hero card that shows contextual content based on fasting state
class _HeroActionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;

    if (hasFast) {
      return _FastingHeroCard(
        fastingState: fastingState,
        isDark: isDark,
      );
    } else {
      return _PhotoHeroCard(isDark: isDark);
    }
  }
}


/// Hero card prompting to take progress photo
class _PhotoHeroCard extends ConsumerWidget {
  final bool isDark;

  const _PhotoHeroCard({required this.isDark});

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    HapticService.light();

    // Run the capture flow directly (angle → camera/gallery → editor)
    final result = await ProgressPhotoCaptureFlow.run(context);
    if (result == null) return; // User cancelled
    if (!context.mounted) return;

    final (editedFile, viewType) = result;

    // Upload the photo
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Uploading photo...'),
          ],
        ),
      ),
    );

    try {
      await ref
          .read(progressPhotosNotifierProvider(userId).notifier)
          .uploadPhoto(imageFile: editedFile, viewType: viewType);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${viewType.displayName} photo saved!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to Stats Photos tab after successful upload
        context.push('/stats?tab=1');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 22,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Take a progress photo to see your transformation',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Hero card showing fasting progress
class _FastingHeroCard extends ConsumerWidget {
  final FastingState fastingState;
  final bool isDark;

  const _FastingHeroCard({
    required this.fastingState,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final activeFast = fastingState.activeFast;

    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    // Calculate progress
    final elapsedMinutes = activeFast?.elapsedMinutes ?? 0;
    final goalMinutes = activeFast?.goalDurationMinutes ?? 960; // Default 16h
    final progress = (elapsedMinutes / goalMinutes).clamp(0.0, 1.0);
    final hours = elapsedMinutes ~/ 60;
    final mins = elapsedMinutes % 60;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.go('/fasting');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.timer,
                  size: 24,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fasting',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hours}h ${mins}m',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : Colors.black,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _EndFastButton(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}


/// End fast button with loading state
class _EndFastButton extends ConsumerStatefulWidget {
  final bool isDark;

  const _EndFastButton({required this.isDark});

  @override
  ConsumerState<_EndFastButton> createState() => _EndFastButtonState();
}


class _EndFastButtonState extends ConsumerState<_EndFastButton> {
  bool _isEnding = false;

  Future<void> _endFast() async {
    if (_isEnding) return;

    setState(() => _isEnding = true);
    HapticService.medium();

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) return;

      await ref.read(fastingProvider.notifier).endFast(userId: userId);

      if (mounted) {
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Fast ended successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF2D2D2D),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end fast: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.isDark ? Colors.white : Colors.black;
    final textOnButton = widget.isDark ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: _endFast,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _isEnding
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textOnButton,
                ),
              )
            : Text(
                'End',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textOnButton,
                ),
              ),
      ),
    );
  }
}



/// Grid action item with icon and label — delegates to the shared
/// [QuickActionTile] chrome.
class _GridActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDark;

  const _GridActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return QuickActionTile(
      isDark: isDark,
      onTap: onTap,
      icon: icon,
      label: label,
      iconColor: iconColor,
    );
  }
}

/// Type alias to the shared widget — keeps the bespoke grid widgets in
/// this file unchanged while routing every tile through the same chrome.
typedef _GridActionTile = QuickActionTile;


/// Presets shown inside the Custom water picker. Covers sip-sized amounts
/// (for when someone is just sipping during a workout) through very large
/// refills (gym water jugs, Stanley-style mugs). The 250ml–1L range stays
/// on the main sheet; this list deliberately omits those four to avoid
/// duplicating affordances.
const List<({int ml, String label, String hint, IconData icon})>
    _customWaterPresets = [
  (ml: 30, label: 'Sip', hint: '30 ml', icon: Icons.water_drop_outlined),
  (ml: 60, label: 'Small sip', hint: '60 ml', icon: Icons.opacity_outlined),
  (ml: 100, label: 'Mouthful', hint: '100 ml', icon: Icons.local_cafe_outlined),
  (ml: 150, label: 'Small cup', hint: '150 ml', icon: Icons.local_cafe_rounded),
  (ml: 200, label: 'Glass', hint: '200 ml', icon: Icons.wine_bar_outlined),
  (ml: 350, label: 'Tall glass', hint: '350 ml', icon: Icons.wine_bar_rounded),
  (ml: 1250, label: 'Big bottle', hint: '1.25 L', icon: Icons.sports_bar_outlined),
  (ml: 1500, label: 'Sports bottle', hint: '1.5 L', icon: Icons.sports_bar_rounded),
  (ml: 2000, label: 'Large jug', hint: '2 L', icon: Icons.propane_tank_outlined),
  (ml: 2500, label: 'XL jug', hint: '2.5 L', icon: Icons.propane_tank_rounded),
];

/// Shared custom-amount picker. Returns the chosen ml value, or null if the
/// user cancelled. Same visual language as the main Log Water sheet so the
/// two feel like one flow.
///
/// Supports presets from sip-sized (30 ml) through XL jug (2.5 L) plus a
/// free-form numeric input clamped to [1, 5000] ml — that upper bound is
/// ~2× the high end of a normal day of water and still safe to pass to the
/// hydration RPC.
Future<int?> showCustomWaterAmountPicker(
  BuildContext context, {
  required bool isDark,
}) async {
  final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
  final accent = quickActionRegistry['water']!.color;

  return showGlassSheet<int>(
    context: context,
    builder: (sheetContext) {
      int? selectedPresetMl;
      final controller = TextEditingController();
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final typed = int.tryParse(controller.text.trim());
          final typedValid = typed != null && typed >= 1 && typed <= 5000;
          final resolvedMl = typedValid ? typed : selectedPresetMl;

          void pick(int ml) {
            setSheetState(() {
              selectedPresetMl = ml;
              controller.clear();
            });
          }

          return GlassSheet(
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.78,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Custom amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sip to XL jug, or type exactly',
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Exact-ml input first — typing should be the
                            // primary affordance for users who already know
                            // the amount they want to log.
                            TextField(
                              controller: controller,
                              keyboardType: const TextInputType.numberWithOptions(),
                              autofocus: false,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. 180',
                                suffixText: 'ml',
                                hintStyle: TextStyle(
                                  color: textMuted.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (_) => setSheetState(() {
                                // Typing overrides any selected preset so
                                // the user's last interaction always wins.
                                if (controller.text.isNotEmpty) {
                                  selectedPresetMl = null;
                                }
                              }),
                            ),
                            if (controller.text.isNotEmpty && !typedValid)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Enter 1–5000 ml',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: textMuted.withValues(alpha: 0.2),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'or pick a preset',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textMuted,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: textMuted.withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _customWaterPresets.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.05,
                              ),
                              itemBuilder: (_, i) {
                                final p = _customWaterPresets[i];
                                final isSelected = selectedPresetMl == p.ml &&
                                    !typedValid;
                                return _CustomWaterPresetTile(
                                  ml: p.ml,
                                  label: p.label,
                                  hint: p.hint,
                                  icon: p.icon,
                                  isDark: isDark,
                                  isSelected: isSelected,
                                  onTap: () => pick(p.ml),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: resolvedMl == null
                                  ? null
                                  : () => Navigator.pop(sheetContext, resolvedMl),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                disabledBackgroundColor:
                                    accent.withValues(alpha: 0.4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                resolvedMl == null
                                    ? 'Log'
                                    : 'Log $resolvedMl ml',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Shared water quick-add sheet. Public so other entry points (Habits
/// section's "Log Now" button) can open the same picker the home grid uses
/// — consistent UX, single source of truth for sizes/copy.
///
/// Sizes must match [_WaterGridActionItemState._waterSizes]; kept in lock-step
/// by mirroring the list here and gated behind the same hydrationProvider
/// quickLog call.
Future<void> showWaterQuickAddSheet(BuildContext context, WidgetRef ref) async {
  HapticService.medium();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

  const sizes = <({int ml, String label, IconData icon})>[
    (ml: 250, label: '250ml', icon: Icons.local_cafe_outlined),
    (ml: 500, label: '500ml', icon: Icons.water_drop_outlined),
    (ml: 750, label: '750ml', icon: Icons.water_drop),
    (ml: 1000, label: '1L', icon: Icons.waves),
  ];

  ref.read(floatingNavBarVisibleProvider.notifier).state = false;
  try {
    await showGlassSheet(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Log Water',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select amount to log',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ...sizes.map((size) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _WaterSizeOption(
                            ml: size.ml,
                            label: size.label,
                            icon: size.icon,
                            isDark: isDark,
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              await _logWaterWithFeedback(
                                context: context,
                                ref: ref,
                                amountMl: size.ml,
                              );
                            },
                          ),
                        ),
                      );
                    }),
                    // Custom tile — opens a follow-up picker covering sip
                    // through XL jug plus a typed ml field. Kept as a
                    // sibling Expanded so the grid stays a single row.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _WaterSizeOption(
                          ml: 0,
                          label: 'Custom',
                          icon: Icons.tune_rounded,
                          isDark: isDark,
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            final chosen = await showCustomWaterAmountPicker(
                              context,
                              isDark: isDark,
                            );
                            if (chosen == null) return;
                            if (!context.mounted) return;
                            await _logWaterWithFeedback(
                              context: context,
                              ref: ref,
                              amountMl: chosen,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.go('/nutrition?tab=2');
                },
                child: Text(
                  'Open Hydration Tracker',
                  style: TextStyle(
                    color: quickActionRegistry['water']!.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  } finally {
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  }
}

/// Water grid action item with tap to add default and long-press for options
class _WaterGridActionItem extends ConsumerStatefulWidget {
  final bool isDark;

  const _WaterGridActionItem({required this.isDark});

  @override
  ConsumerState<_WaterGridActionItem> createState() => _WaterGridActionItemState();
}


class _WaterGridActionItemState extends ConsumerState<_WaterGridActionItem> {
  bool _isLoading = false;
  static const int _defaultWaterMl = 500;

  static const List<({int ml, String label, IconData icon})> _waterSizes = [
    (ml: 250, label: '250ml', icon: Icons.local_cafe_outlined),
    (ml: 500, label: '500ml', icon: Icons.water_drop_outlined),
    (ml: 750, label: '750ml', icon: Icons.water_drop),
    (ml: 1000, label: '1L', icon: Icons.waves),
  ];

  Future<void> _quickAddWater(int amountMl) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticService.medium();

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to track hydration'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final success = await ref.read(hydrationProvider.notifier).quickLog(
            userId: userId,
            drinkType: 'water',
            amountMl: amountMl,
          );

      if (mounted) {
        if (success) {
          HapticService.success();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('+${amountMl}ml water logged'),
                ],
              ),
              backgroundColor: quickActionRegistry['water']!.color,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to log water. Please try again.'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log water. Please try again.'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showWaterSizeOptions() {
    HapticService.medium();
    final isDark = widget.isDark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Log Water',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select amount to log',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ..._waterSizes.map((size) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _WaterSizeOption(
                            ml: size.ml,
                            label: size.label,
                            icon: size.icon,
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(context);
                              _quickAddWater(size.ml);
                            },
                          ),
                        ),
                      );
                    }),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _WaterSizeOption(
                          ml: 0,
                          label: 'Custom',
                          icon: Icons.tune_rounded,
                          isDark: isDark,
                          onTap: () async {
                            Navigator.pop(context);
                            if (!mounted) return;
                            final chosen = await showCustomWaterAmountPicker(
                              context,
                              isDark: isDark,
                            );
                            if (chosen == null) return;
                            if (!mounted) return;
                            _quickAddWater(chosen);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/nutrition?tab=2');
                },
                child: Text(
                  'Open Hydration Tracker',
                  style: TextStyle(
                    color: quickActionRegistry['water']!.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).then((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final waterColor = quickActionRegistry['water']!.color;
    return _GridActionTile(
      isDark: widget.isDark,
      onTap: _showWaterSizeOptions,
      onLongPress: () => _quickAddWater(_defaultWaterMl),
      label: 'Water',
      iconColor: waterColor,
      iconChild: _isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: waterColor,
              ),
            )
          : Icon(Icons.water_drop_outlined, size: 18, color: waterColor),
    );
  }
}


/// Mood grid action item - opens mood picker sheet
class _MoodGridActionItem extends ConsumerWidget {
  final bool isDark;

  const _MoodGridActionItem({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GridActionTile(
      isDark: isDark,
      onTap: () => showMoodPickerSheet(context, ref),
      label: 'Mood',
      icon: Icons.mood_outlined,
      iconColor: quickActionRegistry['mood']!.color,
    );
  }
}


/// Weight grid action item - shows weight logging bottom sheet
class _WeightGridActionItem extends ConsumerWidget {
  final bool isDark;

  const _WeightGridActionItem({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GridActionTile(
      isDark: isDark,
      onTap: () {
        HapticService.light();
        showLogWeightSheet(context, ref);
      },
      onLongPress: () {
        HapticService.light();
        context.push('/measurements');
      },
      label: 'Weight',
      icon: Icons.monitor_weight_outlined,
      iconColor: quickActionRegistry['weight']!.color,
    );
  }
}


/// Fasting grid action item - shows status or navigates to fasting screen
class _FastGridActionItem extends ConsumerWidget {
  final bool isDark;

  const _FastGridActionItem({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;
    final fastColor = quickActionRegistry['fasting']!.color;

    String label = 'Fasting';
    if (hasFast && fastingState.activeFast != null) {
      final elapsed = fastingState.activeFast!.elapsedMinutes;
      final hours = elapsed ~/ 60;
      final mins = elapsed % 60;
      label = '${hours}h ${mins}m';
    }

    return _GridActionTile(
      isDark: isDark,
      onTap: () {
        HapticService.light();
        context.go('/fasting');
      },
      label: label,
      iconColor: fastColor,
      iconChild: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(
            hasFast ? Icons.timer : Icons.timer_outlined,
            size: 18,
            color: fastColor,
          ),
          if (hasFast)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// Individual water size option in the bottom sheet
class _WaterSizeOption extends StatelessWidget {
  final int ml;
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _WaterSizeOption({
    required this.ml,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.cardBorder.withValues(alpha: 0.3)
        : AppColorsLight.cardBorder.withValues(alpha: 0.3);
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: quickActionRegistry['water']!.color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared "log a water amount + show the success snackbar" helper used by
/// [showWaterQuickAddSheet] — mirrors the inline logic the grid-item path
/// keeps in [_WaterGridActionItemState._quickAddWater], so both entry
/// points behave identically (haptic + snackbar + provider refresh)
/// regardless of which sheet opened them.
Future<void> _logWaterWithFeedback({
  required BuildContext context,
  required WidgetRef ref,
  required int amountMl,
}) async {
  final userId = await ref.read(apiClientProvider).getUserId();
  if (userId == null) return;
  final success = await ref.read(hydrationProvider.notifier).quickLog(
        userId: userId,
        drinkType: 'water',
        amountMl: amountMl,
      );
  if (!success || !context.mounted) return;
  HapticService.success();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text('+${amountMl}ml water logged'),
        ],
      ),
      backgroundColor: quickActionRegistry['water']!.color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Preset tile inside the Custom water amount picker. Shares the visual
/// language of [_WaterSizeOption] but adds a selected-state ring so the
/// user can see what the "Log …" button will log when they tap it, plus
/// a small subtitle (`"30 ml"`, `"1.25 L"`) since labels alone ("Sip",
/// "Big bottle") don't convey the volume precisely.
class _CustomWaterPresetTile extends StatelessWidget {
  final int ml;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomWaterPresetTile({
    required this.ml,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = quickActionRegistry['water']!.color;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final baseCard = isDark
        ? AppColors.cardBorder.withValues(alpha: 0.3)
        : AppColorsLight.cardBorder.withValues(alpha: 0.3);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.15) : baseCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: accent),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

