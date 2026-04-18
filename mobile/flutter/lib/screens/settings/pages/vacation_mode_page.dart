import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/pill_app_bar.dart';

/// Vacation Mode settings page.
///
/// Lets the user pause non-critical push notifications + emails. Critical
/// notifications (billing, live chat, subscription lifecycle) still go through
/// — the backend enforces that whitelist in `notification_suppression.py`.
///
/// Start/end dates are both optional:
///   - start null  → active immediately
///   - end   null  → open-ended (user manually disables)
///   - both        → scheduled window
class VacationModePage extends ConsumerStatefulWidget {
  const VacationModePage({super.key});

  @override
  ConsumerState<VacationModePage> createState() => _VacationModePageState();
}

class _VacationModePageState extends ConsumerState<VacationModePage> {
  bool _saving = false;

  // Staged edits — applied on user action, not on every picker change.
  bool? _stagedEnabled;
  String? _stagedStart; // 'YYYY-MM-DD' or null
  String? _stagedEnd;
  bool _stagedStartCleared = false;
  bool _stagedEndCleared = false;

  static final _isoFmt = DateFormat('yyyy-MM-dd');
  static final _displayFmt = DateFormat('EEE, MMM d, yyyy');

  bool _currentEnabled() {
    final user = ref.read(authStateProvider).user;
    return _stagedEnabled ?? user?.inVacationMode ?? false;
  }

  String? _currentStart() {
    if (_stagedStartCleared) return null;
    final user = ref.read(authStateProvider).user;
    return _stagedStart ?? user?.vacationStartDate;
  }

  String? _currentEnd() {
    if (_stagedEndCleared) return null;
    final user = ref.read(authStateProvider).user;
    return _stagedEnd ?? user?.vacationEndDate;
  }

  bool _isActiveNow() {
    if (!_currentEnabled()) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final start = _parseDate(_currentStart());
    final end = _parseDate(_currentEnd());
    if (start != null && todayOnly.isBefore(start)) return false;
    if (end != null && todayOnly.isAfter(end)) return false;
    return true;
  }

  DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  String _formatDisplay(String? iso) {
    final d = _parseDate(iso);
    if (d == null) return 'Not set';
    return _displayFmt.format(d);
  }

  Future<void> _pickDate({required bool isStart}) async {
    HapticService.light();
    final currentIso = isStart ? _currentStart() : _currentEnd();
    final initial = _parseDate(currentIso) ?? DateTime.now();
    final first = isStart
        ? DateTime.now().subtract(const Duration(days: 30))
        : (_parseDate(_currentStart()) ?? DateTime.now());
    final last = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      helpText: isStart ? 'Vacation starts' : 'Vacation ends',
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _stagedStart = _isoFmt.format(picked);
        _stagedStartCleared = false;
      } else {
        _stagedEnd = _isoFmt.format(picked);
        _stagedEndCleared = false;
      }
    });
  }

  void _clearDate({required bool isStart}) {
    HapticService.light();
    setState(() {
      if (isStart) {
        _stagedStart = null;
        _stagedStartCleared = true;
      } else {
        _stagedEnd = null;
        _stagedEndCleared = true;
      }
    });
  }

  Future<void> _save() async {
    HapticService.medium();

    // Cross-field validation (mirrors backend check).
    final start = _parseDate(_currentStart());
    final end = _parseDate(_currentEnd());
    if (start != null && end != null && start.isAfter(end)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vacation start must be on or before end date'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);

    try {
      final updates = <String, dynamic>{};
      if (_stagedEnabled != null) {
        updates['in_vacation_mode'] = _stagedEnabled;
      }
      if (_stagedStart != null || _stagedStartCleared) {
        updates['vacation_start_date'] = _stagedStart ?? '';
      }
      if (_stagedEnd != null || _stagedEndCleared) {
        updates['vacation_end_date'] = _stagedEnd ?? '';
      }
      if (updates.isEmpty) {
        // Nothing to save — close the page.
        if (mounted) Navigator.of(context).maybePop();
        return;
      }

      await ref.read(authStateProvider.notifier).updateUserProfile(updates);

      if (!mounted) return;
      HapticService.success();
      // Reset staged state — server is now the source of truth.
      setState(() {
        _stagedEnabled = null;
        _stagedStart = null;
        _stagedEnd = null;
        _stagedStartCleared = false;
        _stagedEndCleared = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vacation mode settings saved'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _hasUnsavedChanges {
    return _stagedEnabled != null ||
        _stagedStart != null ||
        _stagedEnd != null ||
        _stagedStartCleared ||
        _stagedEndCleared;
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the UI rebuilds if the user refreshes profile elsewhere.
    ref.watch(authStateProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final enabled = _currentEnabled();
    final active = _isActiveNow();

    return Scaffold(
      backgroundColor: background,
      appBar: const PillAppBar(title: 'Vacation Mode'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(active, enabled, textPrimary, textMuted, elevated, cardBorder),
            const SizedBox(height: 16),
            _buildMainToggle(enabled, textPrimary, textMuted, elevated, cardBorder),
            const SizedBox(height: 16),
            _buildDatesCard(enabled, textPrimary, textMuted, elevated, cardBorder),
            const SizedBox(height: 16),
            _buildInfoCard(textPrimary, textMuted, elevated, cardBorder),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    bool active,
    bool enabled,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    final IconData icon;
    final Color accent;
    final String title;
    final String subtitle;

    if (active) {
      icon = Icons.beach_access_rounded;
      accent = const Color(0xFF4FC3F7);
      title = 'Vacation mode is active';
      final end = _currentEnd();
      subtitle = end != null
          ? 'Notifications are paused until ${_formatDisplay(end)}.'
          : 'Notifications are paused. Turn off anytime to resume.';
    } else if (enabled) {
      icon = Icons.event_rounded;
      accent = AppColors.orange;
      title = 'Scheduled';
      subtitle = 'Starts ${_formatDisplay(_currentStart())}.';
    } else {
      icon = Icons.notifications_active_rounded;
      accent = AppColors.success;
      title = 'Notifications are on';
      subtitle = 'Enable vacation mode below to pause non-critical reminders.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: textMuted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle(
    bool enabled,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 0.5),
      ),
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: _saving
            ? null
            : (v) {
                HapticFeedback.selectionClick();
                setState(() => _stagedEnabled = v);
              },
        title: Text(
          'Vacation Mode',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          enabled
              ? 'Suppressing non-critical notifications'
              : 'Receive all your notifications normally',
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
        secondary: Icon(
          Icons.beach_access_rounded,
          color: enabled ? const Color(0xFF4FC3F7) : textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDatesCard(
    bool enabled,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    final start = _currentStart();
    final end = _currentEnd();

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          _dateTile(
            label: 'Start date',
            hint: 'Leave empty to start immediately',
            iso: start,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onPick: enabled ? () => _pickDate(isStart: true) : null,
            onClear: (enabled && start != null) ? () => _clearDate(isStart: true) : null,
          ),
          Divider(height: 1, color: cardBorder),
          _dateTile(
            label: 'End date',
            hint: 'Leave empty for open-ended vacation',
            iso: end,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onPick: enabled ? () => _pickDate(isStart: false) : null,
            onClear: (enabled && end != null) ? () => _clearDate(isStart: false) : null,
          ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required String hint,
    required String? iso,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback? onPick,
    required VoidCallback? onClear,
  }) {
    return ListTile(
      enabled: onPick != null,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      subtitle: Text(
        iso != null ? _formatDisplay(iso) : hint,
        style: TextStyle(
          fontSize: 13,
          color: iso != null ? textPrimary : textMuted,
          fontStyle: iso != null ? FontStyle.normal : FontStyle.italic,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              icon: Icon(Icons.clear_rounded, size: 20, color: textMuted),
              tooltip: 'Clear',
              onPressed: onClear,
            ),
          Icon(Icons.calendar_today_rounded, size: 18, color: textMuted),
        ],
      ),
      onTap: onPick,
    );
  }

  Widget _buildInfoCard(
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    const points = [
      'Push nudges (workout, meal, streak, guilt) are paused',
      'Lifecycle emails (re-engagement, weekly summary) are paused',
      'Billing, subscription, and live-chat messages still come through',
      'Your streak and workout plan are untouched',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: textMuted),
              const SizedBox(width: 8),
              Text(
                'What vacation mode does',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _hasUnsavedChanges && !_saving;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSave ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4FC3F7),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                _hasUnsavedChanges ? 'Save Changes' : 'No Changes',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
