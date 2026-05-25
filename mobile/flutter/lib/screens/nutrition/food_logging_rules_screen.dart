/// L3 "It remembers you" — Always-Rules management screen.
///
/// A user defines standing food-logging rules ("no bun", "I always use 0-cal
/// sweetener", "we cook low-oil South Indian", "skim milk not whole"). These
/// are auto-injected into every food photo + text analysis by the backend so
/// the user never re-types them.
///
/// C9 edge cases surfaced here:
///   * Rules are reviewable / editable — tap a rule to edit its text.
///   * Stale rule — each rule has an enable/disable toggle so a rule can be
///     parked without deleting it (diet changed).
///   * Conflicting rules — the backend returns a `conflicts` list; conflicting
///     pairs are surfaced in a warning banner for the user to resolve.
///   * Per-user — the screen always operates on the signed-in user's id.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/api_client.dart';
import '../../widgets/glass_sheet.dart';
import '../../data/services/haptic_service.dart';

import '../../l10n/generated/app_localizations.dart';
class FoodLoggingRulesScreen extends ConsumerStatefulWidget {
  const FoodLoggingRulesScreen({super.key});

  @override
  ConsumerState<FoodLoggingRulesScreen> createState() =>
      _FoodLoggingRulesScreenState();
}

class _FoodLoggingRulesScreenState
    extends ConsumerState<FoodLoggingRulesScreen> {
  bool _loading = true;
  String? _error;
  String? _userId;

  List<Map<String, dynamic>> _rules = [];
  List<Map<String, dynamic>> _conflicts = [];
  int _maxRules = 25;

  /// Example rules shown in the empty state so users understand the feature.
  static const List<String> _examples = [
    'No bun on my burgers',
    'I always use 0-calorie sweetener',
    'We cook low-oil South Indian food',
    'Skim milk, never whole milk',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _basePath =>
      '${ApiConstants.apiBaseUrl}/nutrition/preferences/$_userId/food-logging-rules';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = await ref.read(apiClientProvider).getUserId();
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'You must be signed in to manage rules.';
        });
        return;
      }
      _userId = uid;
      final resp = await ref.read(apiClientProvider).get(_basePath);
      _applyResponse(resp.data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your rules. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// Parse the standard {rules, conflicts, max_rules} response shape.
  void _applyResponse(dynamic data) {
    if (data is! Map) return;
    _rules = ((data['rules'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _conflicts = ((data['conflicts'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _maxRules = (data['max_rules'] as int?) ?? _maxRules;
  }

  Future<void> _addRule(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _userId == null) return;
    try {
      final resp = await ref
          .read(apiClientProvider)
          .post(_basePath, data: {'text': trimmed});
      if (!mounted) return;
      setState(() => _applyResponse(resp.data));
      HapticService.success();
    } catch (e) {
      _showError(_extractError(e, 'Could not add the rule.'));
    }
  }

  Future<void> _editRule(String ruleId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _userId == null) return;
    try {
      final resp = await ref
          .read(apiClientProvider)
          .patch('$_basePath/$ruleId', data: {'text': trimmed});
      if (!mounted) return;
      setState(() => _applyResponse(resp.data));
      HapticService.light();
    } catch (e) {
      _showError(_extractError(e, 'Could not update the rule.'));
    }
  }

  Future<void> _toggleRule(String ruleId, bool enabled) async {
    if (_userId == null) return;
    try {
      final resp = await ref
          .read(apiClientProvider)
          .patch('$_basePath/$ruleId', data: {'enabled': enabled});
      if (!mounted) return;
      setState(() => _applyResponse(resp.data));
      HapticService.light();
    } catch (e) {
      _showError(_extractError(e, 'Could not update the rule.'));
    }
  }

  Future<void> _deleteRule(String ruleId) async {
    if (_userId == null) return;
    try {
      final resp =
          await ref.read(apiClientProvider).delete('$_basePath/$ruleId');
      if (!mounted) return;
      setState(() => _applyResponse(resp.data));
      HapticService.medium();
    } catch (e) {
      _showError(_extractError(e, 'Could not delete the rule.'));
    }
  }

  String _extractError(Object e, String fallback) {
    try {
      // Dio errors carry the backend's {detail: "..."} payload.
      final dynamic dyn = e;
      final data = dyn.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
    } catch (_) {}
    return fallback;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(AppLocalizations.of(context).nutritionSettingsAlwaysRules,
            style: TextStyle(color: colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      floatingActionButton: (_loading || _error != null)
          ? null
          : FloatingActionButton.extended(
              backgroundColor: colors.accent,
              foregroundColor: colors.accentContrast,
              onPressed: _rules.length >= _maxRules
                  ? () => _showError(
                      'You can have at most $_maxRules rules. Delete one to add another.')
                  : () => _openEditor(colors),
              icon: const Icon(Icons.add_rounded),
              label: Text(AppLocalizations.of(context).foodLoggingRulesAddRule),
            ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(ThemeColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: colors.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textMuted)),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: Text(AppLocalizations.of(context).buttonRetry)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _buildIntro(colors),
        const SizedBox(height: 16),
        if (_conflicts.isNotEmpty) ...[
          _buildConflictBanner(colors),
          const SizedBox(height: 16),
        ],
        if (_rules.isEmpty)
          _buildEmptyState(colors)
        else
          ..._rules.map((r) => _buildRuleCard(colors, r)),
      ],
    );
  }

  Widget _buildIntro(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: colors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Standing rules Zealova applies to every food photo and text '
              'analysis — so you never re-type them. A per-log instruction '
              'always overrides a rule just for that one log.',
              style: TextStyle(
                  color: colors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).foodLoggingRulesConflictingRules,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These rules contradict each other. Edit or disable one so Zealova '
            'knows which to follow:',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ..._conflicts.map((c) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• "${c['rule_a_text']}"  vs  "${c['rule_b_text']}"',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).foodLoggingRulesNoRulesYet,
            style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a rule so Zealova logs your food the way you actually eat. '
            'For example:',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ..._examples.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _addRule(ex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            size: 18, color: colors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(ex,
                              style: TextStyle(
                                  color: colors.textPrimary, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRuleCard(ThemeColors colors, Map<String, dynamic> rule) {
    final id = (rule['id'] ?? '').toString();
    final text = (rule['text'] ?? '').toString();
    final enabled = rule['enabled'] != false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openEditor(colors, ruleId: id, initial: text),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: enabled
                          ? colors.textPrimary
                          : colors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration:
                          enabled ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                // Enable / disable — C9 stale-rule review without deleting.
                Switch(
                  value: enabled,
                  activeThumbColor: colors.accent,
                  onChanged: (v) => _toggleRule(id, v),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: colors.textMuted, size: 22),
                  onPressed: () => _confirmDelete(colors, id, text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      ThemeColors colors, String ruleId, String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.elevated,
        title: Text(AppLocalizations.of(context).foodLoggingRulesDeleteRule,
            style: TextStyle(color: colors.textPrimary)),
        content: Text('"$text"',
            style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).buttonDelete,
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _deleteRule(ruleId);
    }
  }

  /// Bottom-sheet editor used for both add (ruleId == null) and edit.
  Future<void> _openEditor(ThemeColors colors,
      {String? ruleId, String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final isEdit = ruleId != null;

    await showGlassSheet<void>(
      context: context,
      builder: (ctx) {
        return GlassSheet(
          opaque: true,
          child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? AppLocalizations.of(context).foodLoggingRulesEditRule : AppLocalizations.of(context).foodLoggingRulesNewAlwaysRule,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 200,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      AppLocalizations.of(context).foodLoggingRulesEGNoBun,
                  hintStyle: TextStyle(color: colors.textMuted),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentContrast,
                  ),
                  onPressed: () {
                    final v = controller.text.trim();
                    if (v.isEmpty) return;
                    Navigator.pop(ctx);
                    if (isEdit) {
                      _editRule(ruleId, v);
                    } else {
                      _addRule(v);
                    }
                  },
                  child: Text(isEdit ? AppLocalizations.of(context).buttonSave : AppLocalizations.of(context).foodLoggingRulesAddRule),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
    controller.dispose();
  }
}
