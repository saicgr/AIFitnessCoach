/// Phase-2 §2.11: "Help improve nutrition data" toggle + delete-contributions
/// destructive action. Lives in Settings → Privacy & Data.
///
/// When ON (default): novel-dish Gemini fallback results auto-upsert into
/// food_overrides_user_contributed for THIS user, AND aggregate into the
/// daily cross-user promotion job (which auto-promotes convergent dishes
/// to the global canonical DB).
///
/// When OFF: existing rows still serve THIS user's lookups (their data);
/// new novel dishes don't write to user_contributed; cross-user job
/// excludes them. Their data is NOT auto-deleted — separate "Delete my
/// contributions" button below for explicit removal (privacy §D1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';

import '../../../l10n/generated/app_localizations.dart';
class ContributeFoodDataSection extends ConsumerStatefulWidget {
  const ContributeFoodDataSection({super.key});

  @override
  ConsumerState<ContributeFoodDataSection> createState() =>
      _ContributeFoodDataSectionState();
}

class _ContributeFoodDataSectionState
    extends ConsumerState<ContributeFoodDataSection> {
  bool _enabled = true; // default ON, matches users.contribute_food_data DEFAULT TRUE
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCurrent();
  }

  Future<void> _fetchCurrent() async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.get('/users/me');
      final data = (resp.data as Map?) ?? {};
      if (!mounted) return;
      setState(() {
        _enabled = (data['contribute_food_data'] as bool?) ?? true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load setting';
      });
    }
  }

  Future<void> _toggle(bool newValue) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      await client.patch(
        '/users/me/contribute-food-data',
        data: {'contribute_food_data': newValue},
      );
      if (!mounted) return;
      setState(() {
        _enabled = newValue;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save — please try again';
      });
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).contributeFoodDataDeleteFoodContributions),
        content: const Text(
          'This permanently removes every dish you\'ve contributed to the '
          'community nutrition cache. Your own food log stays intact.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).buttonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.delete('/users/me/contributed-foods');
      final data = (resp.data as Map?) ?? {};
      final n = (data['deleted_rows'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n == 0
                ? AppLocalizations.of(context).contributeFoodDataNoContributionsToDelete
                : 'Deleted $n contributed dish${n == 1 ? '' : 'es'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).contributeFoodDataCouldNotDeletePlease)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).contributeFoodDataHelpImproveNutritionData,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'When you log a novel dish (one not in our database), we save the '
            'estimated nutrition so the next time you log it, it\'s instant. '
            'When 5+ users converge on the same dish, it gets added to the '
            'global database — making it instant for everyone.',
            style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    _enabled
                        ? AppLocalizations.of(context).contributeFoodDataSharingNovelDishesRecommen
                        : 'Not sharing novel dishes',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: _enabled,
                  onChanged: _saving ? null : (v) => _toggle(v),
                  activeColor: accent,
                ),
              ],
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _deleting ? null : _confirmAndDelete,
            icon: _deleting
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, size: 18),
            label: Text(AppLocalizations.of(context).contributeFoodDataDeleteMyFoodContributions),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
