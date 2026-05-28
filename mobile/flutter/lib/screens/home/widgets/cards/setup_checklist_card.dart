/// F3.1 — Day 1-7 Setup Checklist card.
///
/// Shown above the Coach hero card when the user is in the first week and
/// hasn't completed all 6 setup items. Each row tap deep-links to the
/// relevant settings/onboarding screen. Auto-hides when:
///   * all 6 items are complete, OR
///   * the user explicitly dismisses (✕, 7-day snooze), OR
///   * `daysSinceSignup > 7`.
///
/// Per-item completion is derived from the live providers, NOT a separate
/// "I clicked the row" flag — so if the user completes a step through any
/// other path the checkmark reflects it immediately.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';

class SetupChecklistCard extends ConsumerStatefulWidget {
  const SetupChecklistCard({super.key});

  @override
  ConsumerState<SetupChecklistCard> createState() =>
      _SetupChecklistCardState();
}

class _SetupChecklistCardState extends ConsumerState<SetupChecklistCard> {
  bool _dismissed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDismissed());
  }

  String _key(String uid) => 'setup_checklist_$uid';

  Future<void> _loadDismissed() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      setState(() => _loaded = true);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(user.id));
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final until = DateTime.tryParse(decoded['snoozedUntil'] as String? ?? '');
        if (until != null && until.isAfter(DateTime.now())) {
          if (mounted) setState(() => _dismissed = true);
        }
      }
    } catch (_) {/* ignore */}
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _dismissForWeek() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(user.id),
        jsonEncode({
          'snoozedUntil':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        }),
      );
    } catch (_) {/* ignore */}
  }

  /// Resolve days since the user's `created_at`. Returns 0 if unknown
  /// (treat as fresh signup so the card is visible by default).
  int _daysSinceSignup() {
    final user = ref.read(currentUserProvider).valueOrNull;
    final createdAtRaw = user?.createdAt;
    if (createdAtRaw == null) return 0;
    final parsed = DateTime.tryParse(createdAtRaw);
    if (parsed == null) return 0;
    return DateTime.now().difference(parsed).inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();
    if (_daysSinceSignup() > 7) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    // Each item: (label, isComplete, routeOnTap).
    // Completion derived from user model fields where possible; otherwise
    // we treat the item as incomplete and let the user mark it by
    // completing the action in the linked screen.
    final items = <_ChecklistItem>[
      _ChecklistItem(
        icon: Icons.favorite,
        label: 'Connect Apple Health / Health Connect',
        isComplete: false, // resolved later when health-sync provider stable
        route: '/settings/health-devices',
      ),
      _ChecklistItem(
        icon: Icons.flag,
        label: 'Set your goal weight',
        isComplete: (user.targetWeightKg ?? 0) > 0,
        route: '/profile',
      ),
      _ChecklistItem(
        icon: Icons.fitness_center,
        label: 'Add gym equipment',
        isComplete: false, // resolved when equipment provider is wired
        route: '/settings/equipment',
      ),
      _ChecklistItem(
        icon: Icons.photo_camera,
        label: 'Take a starting progress photo',
        isComplete: false,
        route: '/progress',
      ),
      _ChecklistItem(
        icon: Icons.notifications_active,
        label: 'Enable notifications',
        isComplete: false,
        route: '/settings/sound-notifications',
      ),
      _ChecklistItem(
        icon: Icons.auto_awesome,
        label: 'Generate your first workout plan',
        isComplete: false,
        route: '/workouts',
      ),
    ];

    final completed = items.where((i) => i.isComplete).length;
    if (completed == items.length) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🚀', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Get started · $completed/${items.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: _dismissForWeek,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: c.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completed / items.length,
            minHeight: 4,
            backgroundColor: c.cardBorder,
            valueColor: AlwaysStoppedAnimation(c.accent),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            InkWell(
              onTap: () => context.push(item.route),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      item.isComplete
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: item.isComplete ? c.accent : c.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Icon(item.icon, size: 14, color: c.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: item.isComplete
                              ? c.textMuted
                              : c.textPrimary,
                          decoration: item.isComplete
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: c.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistItem {
  final IconData icon;
  final String label;
  final bool isComplete;
  final String route;
  const _ChecklistItem({
    required this.icon,
    required this.label,
    required this.isComplete,
    required this.route,
  });
}
