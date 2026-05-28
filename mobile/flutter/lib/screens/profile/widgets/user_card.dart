import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
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
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final muted = fg.withValues(alpha: 0.55);
    final surface = fg.withValues(alpha: isDark ? 0.05 : 0.04);
    final border = fg.withValues(alpha: 0.08);
    final userName =
        user?.displayName ?? user?.name ?? user?.username ?? 'You';
    final userEmail = user?.email ?? '';
    final photoUrl = user?.photoUrl;

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
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fg.withValues(alpha: 0.08),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.person, color: muted, size: 28),
                        )
                      : Icon(Icons.person, color: muted, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      if (userEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: TextStyle(fontSize: 13, color: muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined, size: 16, color: muted),
              ],
            ),
            if (_bioLoaded && _bio != null && _bio!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _bio!,
                  style: TextStyle(fontSize: 13, color: fg),
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
