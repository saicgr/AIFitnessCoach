import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/chat_quick_action.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/chat_quick_action_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import 'chat_prompt_pill.dart';

import '../../../l10n/generated/app_localizations.dart';
class ChatQuickPills extends ConsumerStatefulWidget {
  final void Function(String prompt) onSendPrompt;
  final void Function(ChatMediaMode mode, String contextPrompt) onOpenMediaPicker;
  final bool isLoading;

  const ChatQuickPills({
    super.key,
    required this.onSendPrompt,
    required this.onOpenMediaPicker,
    required this.isLoading,
  });

  @override
  ConsumerState<ChatQuickPills> createState() => _ChatQuickPillsState();
}

class _ChatQuickPillsState extends ConsumerState<ChatQuickPills> {
  void _handlePillTap(ChatQuickAction action) {
    if (widget.isLoading) return;
    HapticService.selection();

    if (action.behavior == ChatActionBehavior.sendPrompt && action.prompt != null) {
      widget.onSendPrompt(action.prompt!);
    } else if (action.behavior == ChatActionBehavior.openMediaPicker) {
      _showMiniMediaChoice(action);
    }
  }

  void _showMiniMediaChoice(ChatQuickAction action) {
    final isVideo = action.mediaMode == ChatMediaMode.video;

    final container = ProviderScope.containerOf(context, listen: false);
    container.read(floatingNavBarVisibleProvider.notifier).state = false;
    showGlassSheet<void>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);

        return GlassSheet(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(action.icon, size: 18, color: action.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MiniPickerOption(
                  icon: isVideo ? Icons.videocam_outlined : Icons.camera_alt_outlined,
                  label: isVideo ? AppLocalizations.of(context).mediaPickerHelperRecordVideo : AppLocalizations.of(context).progressTakePhoto,
                  color: action.color,
                  onTap: () {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    widget.onOpenMediaPicker(
                      isVideo ? ChatMediaMode.recordVideo : ChatMediaMode.camera,
                      action.examplePrompt ?? '',
                    );
                  },
                ),
                const SizedBox(height: 8),
                _MiniPickerOption(
                  icon: isVideo ? Icons.video_library_outlined : Icons.photo_library_outlined,
                  label: isVideo ? AppLocalizations.of(context).mediaPickerHelperChooseVideo : AppLocalizations.of(context).mediaPickerHelperChoosePhoto,
                  color: action.color,
                  onTap: () {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    widget.onOpenMediaPicker(
                      isVideo ? ChatMediaMode.video : ChatMediaMode.gallery,
                      action.examplePrompt ?? '',
                    );
                  },
                ),
                if (!isVideo) ...[
                  const SizedBox(height: 8),
                  _MiniPickerOption(
                    icon: Icons.collections_outlined,
                    label: AppLocalizations.of(context).mediaPickerHelperChooseMultiplePhotos,
                    color: action.color,
                    onTap: () {
                      Navigator.pop(ctx);
                      HapticService.selection();
                      widget.onOpenMediaPicker(
                        ChatMediaMode.multipleImages,
                        action.examplePrompt ?? '',
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
        );
      },
    ).whenComplete(() {
      Future.microtask(() {
        try {
          container.read(floatingNavBarVisibleProvider.notifier).state = true;
        } catch (_) {}
      });
    });
  }

  void _showMoreSheet() {
    HapticService.selection();
    showGlassSheet(
      context: context,
      builder: (context) => _ChatQuickActionsSheet(
        onAction: _handlePillTap,
        onEditMode: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardOpen) return const SizedBox.shrink();

    final pills = ref.watch(chatVisiblePillsProvider);
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      // MINIMUM height, not a fixed one. A hard `height: 40` clipped the pill
      // for anyone above ~1.3× text scale — and the app's own accessibility
      // presets go to 1.5×, with senior mode pinned at 1.35× — so the strip
      // that was fixed for horizontal clipping (E2E #33) would have clipped
      // vertically instead. Measured natural pill heights: 35 / 37 / 40 / 41 /
      // 44 at 1.0 / 1.15 / 1.3 / 1.35 / 1.5.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
          child: Row(
          children: [
            Expanded(
              // Wider right-edge fade than before (7% read as a rendering
              // glitch on a pill clipped mid-word — "Analyze M…", E2E #33).
              // The fade now runs under the pinned More button, which is the
              // real affordance: it never scrolls away, so there is always a
              // visible "there is more here" control at the end of the strip.
              // Register row 108: the fade was a FIXED FRACTION of the
              // viewport (stops 0.82 → 1.0), so it dissolved the right-hand
              // 18% of the strip — roughly 70px on a phone — and whichever
              // pill parked there was faded mid-word. "Nutrition Tips" read as
              // "Nutrition T…", which looks like a truncation bug rather than
              // a scroll hint. There is no TextOverflow to find here; the
              // glyphs are being eaten by this mask.
              //
              // Now a fixed narrow edge instead: the fade is the last 12
              // logical px, which is gutter, not text. It still signals "more
              // to the right" without destroying a word, and the pinned More
              // button remains the real affordance.
              child: ShaderMask(
                shaderCallback: (rect) {
                  const fadeWidth = 12.0;
                  final solidStop = rect.width <= fadeWidth
                      ? 0.0
                      : (rect.width - fadeWidth) / rect.width;
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.0, solidStop, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Same pill as every other prompt surface in chat.
                      ...pills.map((action) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChatPromptPill(
                              label: action.label,
                              icon: action.icon,
                              enabled: !widget.isLoading,
                              onTap: () => _handlePillTap(action),
                              onLongPress: _showMoreSheet,
                            ),
                          )),
                      // Breathing room so the last pill can scroll clear of
                      // the fade instead of dying under the More button.
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
              ),
            ),
            _MorePill(
              isDark: isDark,
              colors: colors,
              onTap: _showMoreSheet,
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// Trailing "more actions" control, pinned at the end of the strip so it never
/// scrolls out of reach. Same family as [ChatPromptPill] — accent tint,
/// stadium shape — because it is the same kind of thing.
class _MorePill extends StatelessWidget {
  final bool isDark;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _MorePill({
    required this.isDark,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = colors.accent;
    return Material(
      color: accent.withValues(alpha: 0.10),
      shape: StadiumBorder(
        side: BorderSide(color: accent.withValues(alpha: 0.30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // No haptic here — the only callback passed in is `_showMoreSheet`,
        // which already fires a selection haptic. Firing one here too made
        // tapping More buzz twice.
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Icon(Icons.more_horiz, size: 18, color: accent),
        ),
      ),
    );
  }
}

class _MiniPickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniPickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// "More" Actions Sheet
// ─────────────────────────────────────────────────────────────────

class _ChatQuickActionsSheet extends ConsumerStatefulWidget {
  final void Function(ChatQuickAction action) onAction;
  final VoidCallback onEditMode;

  const _ChatQuickActionsSheet({
    required this.onAction,
    required this.onEditMode,
  });

  @override
  ConsumerState<_ChatQuickActionsSheet> createState() => _ChatQuickActionsSheetState();
}

const _chatActionCategories = <String, List<String>>{
  'Form Analysis': ['check_form', 'compare_form'],
  'Nutrition': ['scan_food', 'analyze_menu', 'calorie_check', 'nutrition_advice', 'meal_prep'],
  // Issue 2: identify_equipment lives under Workout because the result
  // routes into Swap/Add flows in the active workout (or quick-workout
  // generation if no active workout).
  'Workout': ['quick_workout', 'identify_equipment'],
  'Recovery': ['recovery_tips', 'injury_help'],
};

class _ChatQuickActionsSheetState extends ConsumerState<_ChatQuickActionsSheet> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isEditMode) {
      return _buildEditMode(context, isDark);
    }
    return _buildNormalMode(context, isDark);
  }

  Widget _buildNormalMode(BuildContext context, bool isDark) {
    final colors = ThemeColors.of(context);

    return GlassSheet(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).chatQuickPillsChatActions,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 20, color: colors.textMuted),
                      onPressed: () {
                        HapticService.light();
                        setState(() => _isEditMode = true);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  AppLocalizations.of(context).chatQuickPillsTapAnActionTo,
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              ),

              for (final entry in _chatActionCategories.entries) ...[
                _buildSectionHeader(entry.key, colors.textMuted),
                const SizedBox(height: 8),
                ...entry.value.map((id) {
                  final action = chatQuickActionRegistry[id];
                  if (action == null) return const SizedBox.shrink();
                  return _ActionRow(
                    action: action,
                    colors: colors,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAction(action);
                    },
                  );
                }),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditMode(BuildContext context, bool isDark) {
    final colors = ThemeColors.of(context);
    final order = ref.watch(chatQuickActionOrderProvider);

    return GlassSheet(
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).chatQuickPillsCustomizeShortcuts,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isEditMode = false),
                    child: Text(
                      AppLocalizations.of(context).commonDone,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.cyan : const Color(0xFF0891B2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                AppLocalizations.of(context).chatQuickPillsDragToReorderTop,
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final elevation = Tween<double>(begin: 0, end: 8).evaluate(animation);
                      return Material(
                        elevation: elevation,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                onReorderStart: (_) => HapticFeedback.mediumImpact(),
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.lightImpact();
                  ref.read(chatQuickActionOrderProvider.notifier).reorder(oldIndex, newIndex);
                },
                itemCount: order.length,
                itemBuilder: (context, index) {
                  final actionId = order[index];
                  final action = chatQuickActionRegistry[actionId]!;
                  final isTop5 = index < 5;
                  final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

                  return Container(
                    key: ValueKey(actionId),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isTop5
                          ? action.color.withOpacity(isDark ? 0.12 : 0.08)
                          : elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isTop5
                          ? Border.all(color: action.color.withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle, color: colors.textMuted, size: 20),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: action.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(action.icon, color: action.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (isTop5)
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsetsDirectional.only(end: 12),
                            decoration: BoxDecoration(
                              color: action.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(chatQuickActionOrderProvider.notifier).resetToDefault();
                },
                child: Text(
                  AppLocalizations.of(context).quickActionsResetToDefault,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final ChatQuickAction action;
  final ThemeColors colors;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionRow({
    required this.action,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, size: 18, color: action.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      action.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
