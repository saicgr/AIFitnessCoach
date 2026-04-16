/// Routes meal_reminder / log_recipe push notifications into their target UI.
///
/// Pattern:
///  - The FCM listener (`notification_service_ext._handleMessageOpenedApp`)
///    parses the push `data` payload and stores a pending action on
///    [RecipeNotificationRouter.pending].
///  - On the next frame, a screen with a live [BuildContext] + [WidgetRef]
///    calls [RecipeNotificationRouter.consume] which shows a confirm-and-log
///    bottom sheet pre-filled with recipe + meal_type + servings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../screens/nutrition/grocery/grocery_list_screen.dart';
import '../repositories/nutrition_repository.dart';
import 'api_client.dart';

class RecipeNotificationActionData {
  final String action;     // 'log_recipe' | 'open_grocery_list'
  final String? recipeId;
  final String? mealType;
  final double servings;
  final String? scheduledLogId;
  final String? cookEventId;
  final String? groceryListId;

  const RecipeNotificationActionData({
    required this.action,
    this.recipeId,
    this.mealType,
    this.servings = 1.0,
    this.scheduledLogId,
    this.cookEventId,
    this.groceryListId,
  });
}

class RecipeNotificationRouter {
  /// Set by the FCM open-app handler; consumed by the next live screen.
  static RecipeNotificationActionData? pending;

  /// If there is a pending action, show the appropriate sheet and clear it.
  /// Call from `MainShell.didChangeDependencies` or similar entry point.
  static Future<void> consume(BuildContext context, WidgetRef ref) async {
    final action = pending;
    if (action == null) return;
    pending = null;

    if (action.action == 'log_recipe' &&
        action.recipeId != null &&
        action.recipeId!.isNotEmpty &&
        action.mealType != null) {
      await _showConfirmLogSheet(context, ref, action);
      return;
    }

    if (action.action == 'open_grocery_list' &&
        action.groceryListId != null &&
        action.groceryListId!.isNotEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final userId = await ref.read(apiClientProvider).getUserId() ?? '';
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroceryListScreen(
            listId: action.groceryListId!,
            userId: userId,
            isDark: isDark,
          ),
        ),
      );
    }
  }

  static Future<void> _showConfirmLogSheet(
      BuildContext context, WidgetRef ref, RecipeNotificationActionData data) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      builder: (sheetCtx) => _ConfirmLogSheet(data: data, isDark: isDark),
    );
  }
}

class _ConfirmLogSheet extends ConsumerStatefulWidget {
  final RecipeNotificationActionData data;
  final bool isDark;
  const _ConfirmLogSheet({required this.data, required this.isDark});

  @override
  ConsumerState<_ConfirmLogSheet> createState() => _ConfirmLogSheetState();
}

class _ConfirmLogSheetState extends ConsumerState<_ConfirmLogSheet> {
  late double _servings;
  late String _mealType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _servings = widget.data.servings;
    _mealType = widget.data.mealType ?? 'lunch';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Text('Log scheduled meal?',
              style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.restaurant_menu, color: accent),
            title: Text('Meal slot: $_mealType', style: TextStyle(color: text)),
            subtitle: Text('Servings: ${_servings.toStringAsFixed(2)}',
                style: TextStyle(color: muted)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _confirm,
                  icon: const Icon(Icons.check),
                  label: Text(_saving ? 'Logging…' : 'Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final userId = await ref.read(apiClientProvider).getUserId() ?? '';
      await ref.read(nutritionRepositoryProvider).logRecipe(
            userId: userId,
            recipeId: widget.data.recipeId!,
            mealType: _mealType,
            servings: _servings,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meal logged')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Log failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
