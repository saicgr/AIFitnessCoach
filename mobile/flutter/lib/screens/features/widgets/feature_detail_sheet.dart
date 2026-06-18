import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/feature_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/feature_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../models/feature_comment.dart';
import '../../../models/feature_request.dart';
import '../../../widgets/glass_sheet.dart';

/// Feature detail + threaded discussion, shown as a glass sheet.
/// Reads the feature from the loaded board list (no extra round-trip) and the
/// comments from [featureCommentsProvider].
class FeatureDetailSheet extends ConsumerStatefulWidget {
  final String featureId;

  const FeatureDetailSheet({super.key, required this.featureId});

  @override
  ConsumerState<FeatureDetailSheet> createState() => _FeatureDetailSheetState();
}

class _FeatureDetailSheetState extends ConsumerState<FeatureDetailSheet> {
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  FeatureRequest? _feature() {
    final list = ref.read(featuresProvider).asData?.value;
    if (list == null) return null;
    for (final f in list) {
      if (f.id == widget.featureId) return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Re-read so vote toggles inside the sheet reflect immediately.
    ref.watch(featuresProvider);
    final feature = _feature();
    final commentsAsync = ref.watch(featureCommentsProvider(widget.featureId));

    return GlassSheet(
      child: feature == null
          ? const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Feature not found')),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: vote + title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetVoteButton(
                        feature: feature,
                        accent: accent,
                        isDark: isDark,
                        onTap: () {
                          HapticService.light();
                          ref
                              .read(featuresProvider.notifier)
                              .toggleVote(feature.id);
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          feature.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    feature.description,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Discussion',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${feature.commentCount}',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: commentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Couldn't load the discussion.",
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                      data: (comments) =>
                          _buildComments(comments, isDark, textSecondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildComposer(isDark, accent),
                ],
              ),
            ),
    );
  }

  Widget _buildComments(
      List<FeatureComment> comments, bool isDark, Color textSecondary) {
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No comments yet. Start the conversation.',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: comments.length,
      itemBuilder: (context, index) =>
          _CommentTile(comment: comments[index], isDark: isDark),
    );
  }

  Widget _buildComposer(bool isDark, Color accent) {
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final onAccent =
        accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: TextField(
              controller: _commentController,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              style: TextStyle(fontSize: 14.5, color: textPrimary),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: 'Add a comment',
                hintStyle: TextStyle(fontSize: 14.5, color: textMuted),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _submitting ? null : _submitComment,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _submitting
                ? Padding(
                    padding: const EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: onAccent),
                  )
                : Icon(Icons.arrow_upward_rounded, color: onAccent, size: 22),
          ),
        ),
      ],
    );
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(featureRepositoryProvider).addComment(
            featureId: widget.featureId,
            userId: userId,
            body: body,
          );
      _commentController.clear();
      // Refresh the thread and the board (comment_count moved).
      ref.invalidate(featureCommentsProvider(widget.featureId));
      await ref.read(featuresProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SheetVoteButton extends StatelessWidget {
  final FeatureRequest feature;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _SheetVoteButton({
    required this.feature,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final voted = feature.userHasVoted;
    final idleBg = isDark ? AppColors.surface : AppColorsLight.surface;
    final idleBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final idleFg =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final onAccent =
        accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: voted ? accent : idleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: voted ? accent : idleBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_arrow_up_rounded,
                size: 24, color: voted ? onAccent : idleFg),
            Text(
              '${feature.voteCount}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: voted ? onAccent : idleFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final FeatureComment comment;
  final bool isDark;

  const _CommentTile({required this.comment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Indent threaded replies (cap the visual indent so deep threads stay readable).
    final indent = (comment.depth.clamp(0, 4)) * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.displayAuthor,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _relativeTime(comment.createdAt),
                style: TextStyle(fontSize: 11.5, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            comment.body,
            style: TextStyle(fontSize: 14, height: 1.35, color: textSecondary),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
