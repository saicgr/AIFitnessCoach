import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/injury_options.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/injury_limitations_sheet.dart';
import 'edit_personal_info_sheet.dart';

/// Shared "User Card" — avatar + display name + bio, plus (on the editable
/// Profile sub-tab only) the email + tap-to-copy unique user ID + edit pencil.
/// Mounted at the top of both the You-hub Overview tab AND the Profile sub-
/// tab. The Overview mount is a read-only glance (name only) so the email
/// isn't shown redundantly on both surfaces.
///
/// Tapping anywhere opens [EditPersonalInfoSheet]; on save it refreshes the
/// auth-state user and re-fetches the bio so the card stays in sync.
///
/// Visual style is intentionally hidden chrome — neutral surface, no accent
/// tint, no "Profile" label since the user already knows whose profile
/// they're looking at.
class UserCard extends ConsumerStatefulWidget {
  /// Whether this card carries the edit affordance (pencil + tap-to-edit).
  /// The Profile sub-tab is the canonical place to edit identity, so the
  /// Overview tab mounts the card with [editable] = false to avoid a second,
  /// redundant "edit profile" entry point on the same hub.
  final bool editable;
  const UserCard({super.key, this.editable = true});

  @override
  ConsumerState<UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<UserCard> {
  String? _bio;
  bool _bioLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBio());
  }

  Future<void> _loadBio() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;
      final api = ref.read(apiClientProvider);
      final response = await api.get('${ApiConstants.users}/$userId');
      if (response.statusCode == 200 && response.data != null && mounted) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _bio = data['bio'] as String?;
          _bioLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _bioLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final userName =
        user?.displayName ?? user?.name ?? user?.username ?? 'You';
    final userEmail = user?.email ?? '';
    // Shareable Zealova handle (unique, indexed on users.username) — surfaced
    // instead of the raw UUID so the value is human-friendly AND usable for
    // future social/add-by-handle. Falls back to nothing (we never show the
    // bare UUID).
    final handle = user?.username ?? '';
    // Active injuries (canonical ids, e.g. 'lower_back') surfaced as removable
    // chips below the handle. Stored as ids, rendered via injuryLabelFor.
    final injuries = user == null
        ? const <String>[]
        : normalizeInjuryList(user.injuriesList);
    final photoUrl = user?.photoUrl;
    // The Overview tab mounts this as a read-only glance; identity details
    // (email + handle) live only on the editable Profile sub-tab so the
    // hub doesn't show the same email twice.
    final showIdentityDetails = widget.editable;
    // Signature monogram fallback — the spec's `.ny-av` rounded-square avatar
    // carrying the first initial when there's no photo.
    final initial =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'Y';

    return GestureDetector(
      onTap: widget.editable
          ? () {
              HapticFeedback.lightImpact();
              showGlassSheet(
                context: context,
                builder: (_) => const EditPersonalInfoSheet(),
              ).then((result) {
                if (result == true) {
                  ref.read(authStateProvider.notifier).refreshUser();
                  _loadBio();
                }
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : AppColorsLight.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Rounded-square framed avatar (the `.ny-av` grammar), monogram
                // fallback in Anton.
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.elevated
                        : AppColorsLight.elevated,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: isDark
                            ? AppColors.cardBorder
                            : AppColorsLight.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(initial,
                              style: ZType.disp(22, color: fg)),
                        )
                      : Text(initial, style: ZType.disp(22, color: fg)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        // Long-press the name to copy the username; tap still
                        // bubbles up to the card's edit gesture.
                        behavior: HitTestBehavior.opaque,
                        onLongPress: showIdentityDetails
                            ? () => _copyToClipboard(
                                context, userName, 'Username copied')
                            : null,
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: fg,
                          ),
                        ),
                      ),
                      if (showIdentityDetails && userEmail.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          userEmail,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (showIdentityDetails && handle.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _UserHandleChip(handle: handle),
                      ],
                      if (showIdentityDetails) ...[
                        const SizedBox(height: 7),
                        _buildInjurySection(injuries, isDark),
                      ],
                    ],
                  ),
                ),
                if (widget.editable)
                  const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textMuted),
              ],
            ),
            if (_bioLoaded && _bio != null && _bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _bio!,
                  style: TextStyle(fontSize: 13, height: 1.35, color: fg),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Injuries row: a leading "Injuries" caption, one removable chip per active
  /// injury, and an always-present "+ Add" chip that opens the full picker.
  /// Both removing and adding persist via `updateUserProfile` which triggers
  /// the backend to regenerate upcoming workouts under the new safety
  /// constraints — we then refresh the Next-Workout hero so it reflects them.
  Widget _buildInjurySection(List<String> injuries, bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Injuries',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 0.1,
          ),
        ),
        ...injuries.map(
          (id) => _InjuryChip(
            label: injuryLabelFor(id),
            onRemove: () => _removeInjury(id, injuries),
          ),
        ),
        _AddInjuryChip(
          hasInjuries: injuries.isNotEmpty,
          onTap: _editInjuries,
        ),
      ],
    );
  }

  /// Remove a single injury and persist + regenerate.
  void _removeInjury(String id, List<String> current) {
    HapticFeedback.lightImpact();
    final next = current.where((e) => e != id).toList();
    ref
        .read(authStateProvider.notifier)
        .updateUserProfile({'active_injuries': next});
    // Backend regenerates upcoming workouts under the new constraints; refresh
    // the Next-Workout hero so it reflects the change.
    ref.invalidate(todayWorkoutProvider);
  }

  /// Open the canonical injury picker to add / manage injuries.
  Future<void> _editInjuries() async {
    HapticFeedback.lightImpact();
    final changed = await showInjuryLimitationsSheet(context);
    if (changed == true && mounted) {
      // The sheet already persisted via updateUserProfile (auth state updated);
      // refresh the regenerated workout so the hero stays in sync.
      ref.invalidate(todayWorkoutProvider);
    }
  }
}

/// Copies [text] to the clipboard with a haptic tick + confirmation snackbar.
void _copyToClipboard(BuildContext context, String text, String message) {
  HapticFeedback.selectionClick();
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Tap-to-copy Zealova handle pill shown only on the Profile sub-tab. Shows the
/// user's unique `@username` (not the raw UUID) — human-friendly and shareable,
/// ready for future social/add-by-handle. Styled as an explicit bordered button
/// (background + copy icon) so it reads as interactive.
class _UserHandleChip extends StatelessWidget {
  const _UserHandleChip({required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      // Own gesture so tapping the handle copies it instead of opening the editor.
      behavior: HitTestBehavior.opaque,
      onTap: () => _copyToClipboard(context, handle, 'Zealova ID copied'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '@$handle',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.copy_rounded,
                size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// A single active-injury chip ("Lower Back ✕"). The ✕ removes the injury via
/// its own gesture so the tap doesn't bubble to the card's edit handler.
class _InjuryChip extends StatelessWidget {
  const _InjuryChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 3, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.healing, size: 12, color: AppColors.error),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.close_rounded,
                  size: 13, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "+ Add" chip that opens the injury picker. Reads "Add injury" when the
/// user has none yet (clearer first-run affordance), "Add" once chips exist.
class _AddInjuryChip extends StatelessWidget {
  const _AddInjuryChip({required this.hasInjuries, required this.onTap});

  final bool hasInjuries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 13, color: AppColors.green),
            const SizedBox(width: 3),
            Text(
              hasInjuries ? 'Add' : 'Add injury',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.green,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
