import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/repositories/progress_photos_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// Provider to load recent progress photos for the tile
final _recentPhotosProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final repo = ref.watch(progressPhotosRepositoryProvider);
  return repo.getPhotos(userId: userId, limit: 2);
});

/// Progress Photo Card - Shows recent photos or take-first-photo prompt
class ProgressPhotoCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const ProgressPhotoCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final photosAsync = ref.watch(_recentPhotosProvider);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/progress-photos');
      },
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: photosAsync.when(
          data: (photos) => photos.length >= 2
              ? _buildWithPhotos(
                  photos,
                  textColor: textColor,
                  textMuted: textMuted,
                  accentColor: accentColor,
                )
              : _buildEmpty(
                  textColor: textColor,
                  textMuted: textMuted,
                  accentColor: accentColor,
                ),
          loading: () => _buildLoading(textMuted: textMuted),
          error: (_, __) => _buildEmpty(
            textColor: textColor,
            textMuted: textMuted,
            accentColor: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildWithPhotos(
    List<dynamic> photos, {
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Progress Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildThumbnail(photos[0], textMuted: textMuted)),
            const SizedBox(width: 8),
            Expanded(child: _buildThumbnail(photos[1], textMuted: textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail(dynamic photo, {required Color textMuted}) {
    final url = photo.thumbnailUrl ?? photo.photoUrl;
    final date = photo.takenAt as DateTime;
    final dateStr = '${date.day}/${date.month}';

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: textMuted.withValues(alpha: 0.1),
                child: Icon(Icons.image_not_supported, color: textMuted, size: 24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }

  Widget _buildEmpty({
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Progress Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Icon(Icons.camera_alt_outlined, color: textMuted, size: 32),
              const SizedBox(height: 8),
              Text(
                'Take your first photo',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoading({required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, color: textMuted, size: 20),
            const SizedBox(width: 8),
            Text(
              'Progress Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
