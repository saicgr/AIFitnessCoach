import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/injury_options.dart';
import '../data/repositories/auth_repository.dart';
import 'glass_sheet.dart';

/// Bottom sheet to add/remove the user's active injuries (limitations) from
/// anywhere outside the profile screen — currently the active-workout overflow
/// menu. Saving writes `active_injuries` via the auth notifier, which on the
/// backend (injury-2026-06 Phase 2) regenerates the UPCOMING plan under the new
/// safety constraints. The in-progress session is intentionally left untouched.
///
/// Returns `true` from [showInjuryLimitationsSheet] when the user saved a change.
Future<bool> showInjuryLimitationsSheet(BuildContext context) async {
  final result = await showGlassSheet<bool>(
    context: context,
    builder: (_) => const _InjuryLimitationsSheet(),
  );
  return result ?? false;
}

class _InjuryLimitationsSheet extends ConsumerStatefulWidget {
  const _InjuryLimitationsSheet();

  @override
  ConsumerState<_InjuryLimitationsSheet> createState() =>
      _InjuryLimitationsSheetState();
}

class _InjuryLimitationsSheetState
    extends ConsumerState<_InjuryLimitationsSheet> {
  late List<String> _selected;
  late final List<String> _original;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _selected = normalizeInjuryList(user?.injuriesList ?? const []);
    _original = List<String>.from(_selected);
  }

  bool get _changed {
    if (_selected.length != _original.length) return true;
    final a = _selected.toSet();
    final b = _original.toSet();
    return a.length != b.length || !a.containsAll(b);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Optimistic write — the notifier updates local state immediately and
      // persists + triggers backend regeneration of upcoming workouts.
      await ref
          .read(authStateProvider.notifier)
          .updateUserProfile({'active_injuries': _selected});
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final cardBorder =
        isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.12);

    // Preserve any custom/free-text injuries already set (e.g. onboarding 'other').
    final knownIds = kInjuryOptions.map((o) => o.$1).toSet();
    final extras = _selected.where((id) => !knownIds.contains(id)).toList();
    final entries = <(String, String)>[
      ...kInjuryOptions,
      for (final id in extras) (id, injuryLabelFor(id)),
    ];

    return GlassSheet(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.healing_rounded,
                      color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Injuries & limitations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to add or remove. Saving adapts your upcoming workouts to '
                'train safely around these — your current session stays as is.',
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.35),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entries.map((opt) {
                      final id = opt.$1;
                      final isSel = _selected.contains(id);
                      return GestureDetector(
                        onTap: _saving
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (isSel) {
                                    _selected.remove(id);
                                  } else {
                                    _selected.add(id);
                                  }
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.error.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isSel ? AppColors.error : cardBorder),
                          ),
                          child: Text(
                            opt.$2,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSel ? AppColors.error : textSecondary,
                              fontWeight:
                                  isSel ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_saving || !_changed) ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _selected.isEmpty
                              ? 'Save — no limitations'
                              : 'Save & adapt my plan',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
