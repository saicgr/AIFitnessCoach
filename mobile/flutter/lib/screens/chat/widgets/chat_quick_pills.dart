import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/chat_quick_action.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/chat_quick_action_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: SafeArea(
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
                  label: isVideo ? 'Record Video' : 'Take Photo',
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
                  label: isVideo ? 'Choose Video' : 'Choose Photo',
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
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
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...pills.map((action) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ChatPill(
                  action: action,
                  isDark: isDark,
                  colors: colors,
                  onTap: () => _handlePillTap(action),
                  onLongPress: _showMoreSheet,
                ),
              )),
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

class _ChatPill extends StatelessWidget {
  final ChatQuickAction action;
  final bool isDark;
  final ThemeColors colors;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatPill({
    required this.action,
    required this.isDark,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, size: 16, color: action.color),
                const SizedBox(width: 6),
                Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Icon(
              Icons.more_horiz,
              size: 18,
              color: colors.textMuted,
            ),
          ),
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
  'Workout': ['quick_workout'],
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
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chat Actions',
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
                  'Tap an action to use it. Long-press pills to reorder.',
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
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Customize Shortcuts',
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
                      'Done',
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
                'Drag to reorder. Top 5 appear as pills above the input bar.',
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
                            margin: const EdgeInsets.only(right: 12),
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
                  'Reset to Default',
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
