import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Profile header widget displaying user avatar, name, username, and email.
class ProfileHeader extends ConsumerWidget {
  final String name;
  final String? username;
  final String email;
  final String? photoUrl;
  final VoidCallback? onEditTap;

  const ProfileHeader({
    super.key,
    required this.name,
    this.username,
    required this.email,
    this.photoUrl,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);

    return Column(
      children: [
        _buildAvatar(context, colors),
        const SizedBox(height: 16),
        _buildName(context),
        if (username != null && username!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildUsername(context, colors),
        ],
        const SizedBox(height: 4),
        _buildEmail(context),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, ThemeColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.accent.withOpacity(0.7),
                colors.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: 48,
                      color: colors.accentContrast,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 48,
                  color: colors.accentContrast,
                ),
        ),
        // Edit button overlay
        if (onEditTap != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onEditTap?.call();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: colors.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildName(BuildContext context) {
    return Text(
      name,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildUsername(BuildContext context, ThemeColors colors) {
    return Text(
      '@$username',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _buildEmail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      email,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
    );
  }
}
