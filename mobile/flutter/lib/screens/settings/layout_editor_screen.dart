import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/home_layout.dart';
import '../../data/providers/local_layout_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/segmented_tab_bar.dart';
import 'widgets/preview_tile_mock.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/widgets/swipeable_hero_section.dart'
    show HomeFocus, homeFocusProvider;

part 'layout_editor_screen_part_toggles_tab.dart';


/// Screen for editing home screen layout with tabs for Toggles and Discover
class LayoutEditorScreen extends ConsumerStatefulWidget {
  const LayoutEditorScreen({super.key});

  @override
  ConsumerState<LayoutEditorScreen> createState() => _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends ConsumerState<LayoutEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasUserDefault = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserDefault();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'layout_editor_viewed');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserDefault() async {
    final hasDefault =
        await ref.read(localLayoutProvider.notifier).hasUserDefault();
    if (mounted) {
      setState(() => _hasUserDefault = hasDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.background : AppColorsLight.background;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final layoutState = ref.watch(localLayoutProvider);
    final accentColor = ref.colors(context).accent;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).programMenuButtonMySpace,
        actions: [
          PillAppBarAction(icon: Icons.refresh_rounded, onTap: _showResetDialog),
        ],
      ),
      body: Column(
        children: [
          // Styled TabBar
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            compact: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            tabs: [
              SegmentedTabItem(label: AppLocalizations.of(context).layoutEditorToggles),
              SegmentedTabItem(label: AppLocalizations.of(context).navDiscover),
            ],
          ),
          // Content
          Expanded(
            child: layoutState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).layoutEditorFailedToLoadLayout,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(localLayoutProvider.notifier).refresh(),
                      child: Text(AppLocalizations.of(context).buttonRetry),
                    ),
                  ],
                ),
              ),
              data: (layout) {
                if (layout == null) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context).layoutEditorNoLayoutFound,
                      style: TextStyle(color: textMuted),
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _TogglesTab(
                      layout: layout,
                      isDark: isDark,
                      elevatedColor: elevatedColor,
                      textColor: textColor,
                      textMuted: textMuted,
                    ),
                    _DiscoverTab(
                      isDark: isDark,
                      elevatedColor: elevatedColor,
                      textColor: textColor,
                      textMuted: textMuted,
                      hasUserDefault: _hasUserDefault,
                      onUserDefaultApplied: _checkUserDefault,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'set_default':
        _saveAsDefault();
        break;
      case 'apply_default':
        _applyUserDefault();
        break;
    }
  }

  void _showResetDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Text(AppLocalizations.of(context).layoutEditorResetLayout, style: TextStyle(color: textColor)),
        content: Text(
          'Reset to the app\'s original layout? This will undo all your customizations.',
          style: TextStyle(
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).buttonCancel,
                style: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColorsLight.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(localLayoutProvider.notifier).resetToAppDefault();
              HapticService.success();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).layoutEditorLayoutResetToOriginal),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(AppLocalizations.of(context).trophyFilterReset,
                style: TextStyle(
                    color: isDark
                        ? AppColors.cyan
                        : _darkenColor(AppColors.cyan))),
          ),
        ],
      ),
    );
  }

  void _saveAsDefault() async {
    await ref.read(localLayoutProvider.notifier).saveAsUserDefault();
    HapticService.success();
    setState(() => _hasUserDefault = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).layoutEditorSavedAsYourDefault),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyUserDefault() async {
    await ref.read(localLayoutProvider.notifier).applyUserDefault();
    HapticService.success();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).layoutEditorScreenAppliedYourDefaultLayout),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}
