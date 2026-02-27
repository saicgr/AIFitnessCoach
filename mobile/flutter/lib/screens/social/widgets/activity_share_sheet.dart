import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/share_service.dart';
import '../../../utils/image_capture_utils.dart';
import 'activity_share_card.dart';

/// Activity Share Sheet - Bottom sheet for sharing social feed posts as branded card images
///
/// Features:
/// - 3 aspect ratio options (Story 9:16, Square 1:1, Portrait 4:5)
/// - 5 visual template themes in a swipeable carousel
/// - Inline caption editor with live preview
/// - Watermark toggle
/// - Share to Instagram Stories, system share, save to gallery, copy text
class ActivityShareSheet extends StatefulWidget {
  final String userName;
  final String activityType;
  final Map<String, dynamic> activityData;
  final DateTime timestamp;

  const ActivityShareSheet({
    super.key,
    required this.userName,
    required this.activityType,
    required this.activityData,
    required this.timestamp,
  });

  @override
  State<ActivityShareSheet> createState() => _ActivityShareSheetState();
}

class _ActivityShareSheetState extends State<ActivityShareSheet> {
  bool _showWatermark = true;
  bool _isSharing = false;
  bool _isSaving = false;
  bool _isEditingCaption = false;

  ShareAspectRatio _selectedRatio = ShareAspectRatio.story;
  String? _editedCaption;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final TextEditingController _captionController;
  final FocusNode _captionFocusNode = FocusNode();

  // Capture keys for each template
  final List<GlobalKey> _captureKeys =
      List.generate(ShareTemplate.values.length, (_) => GlobalKey());

  static const _templateNames = [
    'Dark',
    'Bold',
    'Neon',
    'Light',
    'Glass',
  ];

  static const _templates = ShareTemplate.values;

  @override
  void initState() {
    super.initState();
    _editedCaption = widget.activityData['caption'] as String?;
    _captionController = TextEditingController(text: _editedCaption ?? '');
    _captionFocusNode.addListener(() {
      if (!_captionFocusNode.hasFocus && _isEditingCaption) {
        setState(() => _isEditingCaption = false);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _captionController.dispose();
    _captionFocusNode.dispose();
    super.dispose();
  }

  Size _getCaptureSize() {
    switch (_selectedRatio) {
      case ShareAspectRatio.story:
        return ImageCaptureUtils.instagramStoriesSize;
      case ShareAspectRatio.square:
        return ImageCaptureUtils.instagramPostSize;
      case ShareAspectRatio.portrait:
        return ImageCaptureUtils.instagramPortraitSize;
    }
  }

  Future<Uint8List?> _captureCard() async {
    final size = _getCaptureSize();
    return await ImageCaptureUtils.captureWidgetWithSize(
      _captureKeys[_currentPage],
      width: size.width,
      height: size.height,
      pixelRatio: 1.0,
    );
  }

  Future<void> _shareToInstagram() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      final result = await ShareService.shareToInstagramStories(bytes);
      if (result.success && mounted) {
        Navigator.pop(context);
        _showSuccess('Opening Instagram...');
      } else if (result.error != null) {
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
      final bytes = await _captureCard();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      await ShareService.shareGeneric(
        bytes,
        caption: _buildShareText(),
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
      final bytes = await _captureCard();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      final result = await ShareService.saveToGallery(bytes);
      if (result.success && mounted) {
        Navigator.pop(context);
        _showSuccess('Saved to device!');
      } else {
        _showError(result.error ?? 'Failed to save image');
      }
    } catch (e) {
      _showError('Failed to save');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _copyText() {
    HapticFeedback.lightImpact();
    final text = _buildShareText();
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      Navigator.pop(context);
      _showSuccess('Copied to clipboard!');
    }
  }

  String _buildShareText() {
    final caption = _editedCaption ??
        widget.activityData['caption'] as String? ?? '';
    final workoutName = widget.activityData['workout_name'] as String? ?? '';

    switch (widget.activityType) {
      case 'workout_completed':
        final duration = widget.activityData['duration_minutes'] ?? 0;
        final exercises = widget.activityData['exercises_count'] ?? 0;
        return '${widget.userName} completed $workoutName on FitWiz! '
            '$duration min | $exercises exercises '
            '#FitWiz #Fitness #Workout';
      case 'personal_record':
        final exercise = widget.activityData['exercise_name'] ?? '';
        final value = widget.activityData['record_value'] ?? 0;
        final unit = widget.activityData['record_unit'] ?? '';
        return '${widget.userName} set a new PR on FitWiz! '
            '$exercise: $value $unit '
            '#FitWiz #PersonalRecord #Fitness';
      case 'achievement_earned':
        final name = widget.activityData['achievement_name'] ?? '';
        return '${widget.userName} unlocked "$name" on FitWiz! '
            '#FitWiz #Achievement #Fitness';
      case 'streak_milestone':
        final days = widget.activityData['streak_days'] ?? 0;
        return '${widget.userName} hit a $days-day streak on FitWiz! '
            '#FitWiz #Streak #Consistency';
      case 'challenge_victory':
        final challengerName =
            widget.activityData['challenger_name'] ?? '';
        return '${widget.userName} beat $challengerName\'s $workoutName on FitWiz! '
            '#FitWiz #Challenge #Victory';
      case 'manual_post':
        if (caption.isNotEmpty) {
          return '${widget.userName} on FitWiz: $caption #FitWiz';
        }
        return '${widget.userName} shared an update on FitWiz! #FitWiz';
      default:
        if (caption.isNotEmpty) {
          return '${widget.userName} on FitWiz: $caption';
        }
        return '${widget.userName} shared an update on FitWiz!';
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

  /// Background gradient for the InstagramStoryWrapper based on template + activity type
  List<Color> _getBackgroundGradient(ShareTemplate tmpl) {
    switch (tmpl) {
      case ShareTemplate.cleanLight:
        return const [
          Color(0xFFF0F0F0),
          Color(0xFFE8E8E8),
          Color(0xFFE0E0E0),
        ];
      case ShareTemplate.gradientBold:
        return _getGradientBoldBg();
      case ShareTemplate.neonGlow:
        return const [
          Color(0xFF030308),
          Color(0xFF020206),
          Color(0xFF010104),
        ];
      case ShareTemplate.glassMorphism:
        return const [
          Color(0xFF0F1525),
          Color(0xFF0A0F1A),
          Color(0xFF060A12),
        ];
      case ShareTemplate.darkMinimal:
        return _getActivityBg();
    }
  }

  List<Color> _getActivityBg() {
    switch (widget.activityType) {
      case 'workout_completed':
        return const [
          Color(0xFF1A0F00),
          Color(0xFF0F0800),
          Color(0xFF0A0500),
        ];
      case 'personal_record':
      case 'challenge_victory':
        return const [
          Color(0xFF2D1F00),
          Color(0xFF1A1200),
          Color(0xFF0D0A00),
        ];
      case 'achievement_earned':
        return const [
          Color(0xFF001A0F),
          Color(0xFF000F08),
          Color(0xFF000A05),
        ];
      case 'streak_milestone':
        return const [
          Color(0xFF1A0F00),
          Color(0xFF0F0800),
          Color(0xFF0A0500),
        ];
      case 'weight_milestone':
        return const [
          Color(0xFF1A0F2D),
          Color(0xFF0F081A),
          Color(0xFF0A050D),
        ];
      case 'manual_post':
        return const [
          Color(0xFF001A2E),
          Color(0xFF000F1A),
          Color(0xFF00050D),
        ];
      default:
        return const [
          Color(0xFF1A1A1A),
          Color(0xFF0D0D0D),
          Color(0xFF000000),
        ];
    }
  }

  List<Color> _getGradientBoldBg() {
    switch (widget.activityType) {
      case 'workout_completed':
        return const [
          Color(0xFF3D1C00),
          Color(0xFF2D1500),
          Color(0xFF1A0D00),
        ];
      case 'personal_record':
      case 'challenge_victory':
        return const [
          Color(0xFF3D2E00),
          Color(0xFF2D2200),
          Color(0xFF1A1500),
        ];
      case 'achievement_earned':
        return const [
          Color(0xFF003D1E),
          Color(0xFF002D16),
          Color(0xFF001A0D),
        ];
      default:
        return const [
          Color(0xFF0D1A3D),
          Color(0xFF0A132D),
          Color(0xFF060D1A),
        ];
    }
  }

  double _getPreviewAspectRatio() {
    switch (_selectedRatio) {
      case ShareAspectRatio.story:
        return 9.0 / 16.0;
      case ShareAspectRatio.square:
        return 1.0;
      case ShareAspectRatio.portrait:
        return 4.0 / 5.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

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
                        'Share Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Aspect ratio picker
                _buildAspectRatioPicker(isDark),

                const SizedBox(height: 12),

                // Template carousel
                Expanded(
                  child: _buildTemplateCarousel(),
                ),

                // Page indicator dots
                _buildPageIndicator(isDark),

                const SizedBox(height: 8),

                // Caption editor
                _buildCaptionEditor(isDark),

                const SizedBox(height: 8),

                // Watermark toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.branding_watermark_rounded,
                        size: 18,
                        color:
                            _showWatermark ? AppColors.cyan : Colors.grey,
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
                        activeTrackColor: AppColors.cyan,
                        activeThumbColor: Colors.white,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Instagram + More
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
                              label: 'More',
                              isPrimary: false,
                              isLoading: _isSharing,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Row 2: Save Image + Copy Text
                      Row(
                        children: [
                          Expanded(
                            child: _buildShareButton(
                              onPressed: _saveToGallery,
                              icon: Icons.save_alt_rounded,
                              label: 'Save Image',
                              isPrimary: false,
                              isLoading: _isSaving,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildShareButton(
                              onPressed: _copyText,
                              icon: Icons.copy_rounded,
                              label: 'Copy Text',
                              isPrimary: false,
                              isLoading: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ASPECT RATIO PICKER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAspectRatioPicker(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ShareAspectRatio.values.map((ratio) {
          final isSelected = _selectedRatio == ratio;
          final label = _ratioLabel(ratio);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedRatio = ratio);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.2)),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _ratioLabel(ShareAspectRatio ratio) {
    switch (ratio) {
      case ShareAspectRatio.story:
        return 'Story 9:16';
      case ShareAspectRatio.square:
        return 'Square 1:1';
      case ShareAspectRatio.portrait:
        return 'Portrait 4:5';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TEMPLATE CAROUSEL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTemplateCarousel() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _templates.length,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() {
          _currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        final tmpl = _templates[index];
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CapturableWidget(
              captureKey: _captureKeys[index],
              child: _buildWrappedCard(tmpl),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWrappedCard(ShareTemplate tmpl) {
    final bgGradient = _getBackgroundGradient(tmpl);

    return AspectRatio(
      aspectRatio: _getPreviewAspectRatio(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: ActivityShareCard(
            userName: widget.userName,
            activityType: widget.activityType,
            activityData: widget.activityData,
            timestamp: widget.timestamp,
            showWatermark: _showWatermark,
            template: tmpl,
            aspectRatio: _selectedRatio,
            editedCaption: _editedCaption,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAGE INDICATOR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPageIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_templates.length, (index) {
          final isActive = _currentPage == index;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 10 : 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark
                        ? Colors.grey.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _templateNames[index],
                style: TextStyle(
                  color: isActive
                      ? (isDark ? Colors.black : Colors.white)
                      : Colors.grey,
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CAPTION EDITOR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCaptionEditor(bool isDark) {
    final hasCaption = (_editedCaption ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          setState(() => _isEditingCaption = true);
          _captionFocusNode.requestFocus();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditingCaption
                  ? (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.3))
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: _isEditingCaption
              ? TextField(
                  controller: _captionController,
                  focusNode: _captionFocusNode,
                  maxLength: 200,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterStyle: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _editedCaption = value.isEmpty ? null : value;
                    });
                  },
                  onSubmitted: (_) {
                    setState(() => _isEditingCaption = false);
                  },
                )
              : Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasCaption ? _editedCaption! : 'Tap to add a caption...',
                        style: TextStyle(
                          fontSize: 14,
                          color: hasCaption
                              ? (isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.7))
                              : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.3)),
                          fontStyle:
                              hasCaption ? FontStyle.normal : FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARE BUTTON
  // ═══════════════════════════════════════════════════════════════
  Widget _buildShareButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isLoading,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan,
        side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.cyan),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }
}
