import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import 'edit_personal_info_sheet.dart';

/// Shared "User Card" — avatar + display name + email + bio + edit pencil.
/// Mounted at the top of both the You-hub Overview tab AND the Profile sub-
/// tab so the same edit affordance is reachable from either entry point.
///
/// Tapping anywhere opens [EditPersonalInfoSheet]; on save it refreshes the
/// auth-state user and re-fetches the bio so the card stays in sync.
///
/// Visual style is intentionally hidden chrome — neutral surface, no accent
/// tint, no "Profile" label since the user already knows whose profile
/// they're looking at.
class UserCard extends ConsumerStatefulWidget {
  const UserCard({super.key});

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
    final photoUrl = user?.photoUrl;
    // Signature monogram fallback — the spec's `.ny-av` rounded-square avatar
    // carrying the first initial when there's no photo.
    final initial =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'Y';

    return GestureDetector(
      onTap: () {
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
      },
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
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: fg,
                        ),
                      ),
                      if (userEmail.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          userEmail,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
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
}
