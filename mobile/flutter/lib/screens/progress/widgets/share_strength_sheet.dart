import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/scores.dart';
import '../../../data/services/share_service.dart';
import '../../../utils/image_capture_utils.dart';
import '../../../widgets/glass_sheet.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';
import 'body_score_overlay.dart';

/// Share Strength bottom sheet with body diagram templates.
///
/// Shows a carousel of 3 shareable templates and options to:
/// - Share to Instagram Stories
/// - Share via system share sheet
/// - Save to gallery
class ShareStrengthSheet extends ConsumerStatefulWidget {
  final AllStrengthScores scores;

  const ShareStrengthSheet({super.key, required this.scores});

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    AllStrengthScores scores,
  ) async {
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => ShareStrengthSheet(scores: scores),
    );
  }

  @override
  ConsumerState<ShareStrengthSheet> createState() => _ShareStrengthSheetState();
}

class _ShareStrengthSheetState extends ConsumerState<ShareStrengthSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSharing = false;
  bool _isSaving = false;
  bool _showWatermark = true;

  final List<GlobalKey> _captureKeys = List.generate(3, (_) => GlobalKey());

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _templateNames => ['Body Score', 'Muscle Summary', 'Split View'];

  Color _getLevelColor(StrengthLevel level) {
    switch (level) {
      case StrengthLevel.elite:
        return const Color(0xFF9C27B0);
      case StrengthLevel.advanced:
        return const Color(0xFF2196F3);
      case StrengthLevel.intermediate:
        return const Color(0xFF4CAF50);
      case StrengthLevel.novice:
        return const Color(0xFFFF9800);
      case StrengthLevel.beginner:
        return const Color(0xFF9E9E9E);
    }
  }

  Future<Uint8List?> _captureCurrentTemplate() async {
    return await ImageCaptureUtils.captureWidgetWithSize(
      _captureKeys[_currentPage],
      width: ImageCaptureUtils.instagramStoriesSize.width,
      height: ImageCaptureUtils.instagramStoriesSize.height,
      pixelRatio: 1.0,
    );
  }

  Future<void> _shareToInstagram() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }
      final result = await ShareService.shareToInstagramStories(bytes);
      if (result.success) {
        if (mounted) {
          Navigator.pop(context);
          _showSuccess('Opening Instagram...');
        }
      } else {
        _showError('Could not open Instagram');
      }
    } catch (e) {
      _showError('Failed to share');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareGeneric() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }
      await ShareService.shareGeneric(
        bytes,
        caption: 'Check out my strength scores!',
      );
    } catch (e) {
      _showError('Failed to share');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }
      final saveResult = await ShareService.saveToGallery(bytes);
      if (!saveResult.success) {
        _showError(saveResult.error ?? 'Failed to save image');
        return;
      }
      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Saved to device!');
      }
    } catch (e) {
      _showError('Failed to save');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassSheet(
      maxHeightFraction: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                const Text(
                  'Share Strength',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Watermark toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.branding_watermark_rounded,
                  size: 18,
                  color: _showWatermark
                      ? (isDark ? AppColors.accent : AppColorsLight.accent)
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Show Watermark',
                  style: TextStyle(
                    fontSize: 14,
                    color: _showWatermark ? null : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _showWatermark,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _showWatermark = value);
                  },
                  activeTrackColor: isDark ? AppColors.accent : AppColorsLight.accent,
                  activeThumbColor: isDark ? AppColors.accentContrast : AppColorsLight.accentContrast,
                ),
              ],
            ),
          ),

          // Template carousel
          Expanded(child: _buildTemplateCarousel()),

          // Page indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_templateNames.length, (index) {
                final isActive = _currentPage == index;
                final accent = isDark ? AppColors.accent : AppColorsLight.accent;
                final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: EdgeInsets.symmetric(
                      horizontal: isActive ? 12 : 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accent
                          : isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _templateNames[index],
                      style: TextStyle(
                        color: isActive
                            ? accentContrast
                            : isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              24, 0, 24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildShareButton(
                        onPressed: _shareToInstagram,
                        icon: Icons.camera_alt_rounded,
                        label: 'Instagram',
                        isPrimary: true,
                        isLoading: _isSharing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildShareButton(
                        onPressed: _shareGeneric,
                        icon: Icons.share_rounded,
                        label: 'Share',
                        isPrimary: false,
                        isLoading: _isSharing,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildShareButton(
                    onPressed: _saveToGallery,
                    icon: Icons.save_alt_rounded,
                    label: 'Save to Gallery',
                    isPrimary: false,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Template Carousel ──────────────────────────────────────────────

  Widget _buildTemplateCarousel() {
    final scores = widget.scores;
    final levelColor = _getLevelColor(scores.level);
    final topMuscles = scores.sortedMuscleScores.take(5).toList();

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() => _currentPage = index);
      },
      children: [
        // Template 1: Body Score Card (9:16 story)
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[0],
            child: InstagramStoryWrapper(
              backgroundGradient: const [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF21262D)],
              child: _BodyScoreTemplate(
                scores: scores,
                levelColor: levelColor,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),

        // Template 2: Muscle Summary Card
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[1],
            child: InstagramStoryWrapper(
              backgroundGradient: const [Color(0xFF1A1A2E), Color(0xFF2D1B4E), Color(0xFF1A1A2E)],
              child: _MuscleSummaryTemplate(
                scores: scores,
                levelColor: levelColor,
                topMuscles: topMuscles,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),

        // Template 3: Split View Card
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[2],
            child: InstagramStoryWrapper(
              backgroundGradient: const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
              child: _SplitViewTemplate(
                scores: scores,
                levelColor: levelColor,
                topMuscles: topMuscles,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isLoading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: accentContrast,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(accentContrast),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(textColor),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 1: Body Score Card
// ═══════════════════════════════════════════════════════════════════════════

class _BodyScoreTemplate extends StatelessWidget {
  final AllStrengthScores scores;
  final Color levelColor;
  final bool showWatermark;

  const _BodyScoreTemplate({
    required this.scores,
    required this.levelColor,
    required this.showWatermark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 640,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Header
            Text(
              'STRENGTH SCORE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),

            // Score ring + level
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: scores.overallScore / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${scores.overallScore}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                scores.overallLevel.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Body diagram (static)
            Expanded(
              child: BodyScoreOverlay(
                muscleScores: scores.muscleScores,
                isDark: true,
                interactive: false,
              ),
            ),

            if (showWatermark) ...[
              const SizedBox(height: 12),
              const AppWatermark(),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 2: Muscle Summary Card
// ═══════════════════════════════════════════════════════════════════════════

class _MuscleSummaryTemplate extends StatelessWidget {
  final AllStrengthScores scores;
  final Color levelColor;
  final List<StrengthScoreData> topMuscles;
  final bool showWatermark;

  const _MuscleSummaryTemplate({
    required this.scores,
    required this.levelColor,
    required this.topMuscles,
    required this.showWatermark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 640,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Header
            Text(
              'MUSCLE BREAKDOWN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),

            // Overall score row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: scores.overallScore / 100,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${scores.overallScore}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scores.overallLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                    Text(
                      '${scores.muscleScores.length} muscle groups',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Body diagram (smaller)
            SizedBox(
              height: 260,
              child: BodyScoreOverlay(
                muscleScores: scores.muscleScores,
                isDark: true,
                height: 260,
                interactive: false,
              ),
            ),
            const SizedBox(height: 16),

            // Top 5 muscles list
            Text(
              'TOP MUSCLES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            ...topMuscles.map((muscle) => _buildMuscleRow(muscle)),

            const Spacer(),

            if (showWatermark) const AppWatermark(),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleRow(StrengthScoreData muscle) {
    final color = Color(muscle.levelColor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              muscle.muscleGroupDisplayName,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${muscle.strengthScore}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 3: Split View Card
// ═══════════════════════════════════════════════════════════════════════════

class _SplitViewTemplate extends StatelessWidget {
  final AllStrengthScores scores;
  final Color levelColor;
  final List<StrengthScoreData> topMuscles;
  final bool showWatermark;

  const _SplitViewTemplate({
    required this.scores,
    required this.levelColor,
    required this.topMuscles,
    required this.showWatermark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 640,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            // Overall score at top
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: scores.overallScore / 100,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${scores.overallScore}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STRENGTH SCORE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: Colors.white54,
                      ),
                    ),
                    Text(
                      scores.overallLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Split: body diagram left, muscle list right
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: body diagram
                  Expanded(
                    flex: 5,
                    child: BodyScoreOverlay(
                      muscleScores: scores.muscleScores,
                      isDark: true,
                      interactive: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right: muscle scores list
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'TOP SCORES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...topMuscles.map((m) => _buildCompactMuscleRow(m)),
                        const Spacer(),
                        // Weakest
                        if (scores.weakestMuscles.isNotEmpty) ...[
                          Text(
                            'FOCUS AREAS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...scores.weakestMuscles.take(3).map(
                                (m) => _buildCompactMuscleRow(m),
                              ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (showWatermark) ...[
              const SizedBox(height: 8),
              const AppWatermark(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMuscleRow(StrengthScoreData muscle) {
    final color = Color(muscle.levelColor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              muscle.muscleGroupDisplayName,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${muscle.strengthScore}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
