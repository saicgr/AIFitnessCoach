import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Profile header widget displaying user avatar, name, and email.
class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAvatar(),
        const SizedBox(height: 16),
        _buildName(context),
        const SizedBox(height: 4),
        _buildEmail(context),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cyan, AppColors.purple],
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
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            )
          : const Icon(
              Icons.person,
              size: 48,
              color: Colors.white,
            ),
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

  Widget _buildEmail(BuildContext context) {
    return Text(
      email,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }
}
