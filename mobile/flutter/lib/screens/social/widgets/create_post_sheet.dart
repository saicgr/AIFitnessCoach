import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/services/social_service.dart' show PostVisibility, SocialActivityType;
import '../../../data/services/social_image_service.dart';
import '../../../core/services/posthog_service.dart';
import '../../../widgets/app_snackbar.dart';

/// UI representation for post visibility options
enum PostVisibilityOption {
  public('Public', Icons.public_rounded, PostVisibility.public),
  friends('Friends', Icons.people_rounded, PostVisibility.friends),
  privateOnly('Private', Icons.lock_rounded, PostVisibility.private);

  final String label;
  final IconData icon;
  final PostVisibility serviceValue;

  const PostVisibilityOption(this.label, this.icon, this.serviceValue);
}

/// Reddit-style flair tags for posts
enum PostFlair {
  fitness('Fitness', Icons.fitness_center_rounded, Color(0xFF06B6D4)),
  progress('Progress', Icons.trending_up_rounded, Color(0xFF22C55E)),
  milestone('Milestone', Icons.emoji_events_rounded, Color(0xFFF97316)),
  nutrition('Nutrition', Icons.restaurant_rounded, Color(0xFFA855F7)),
  motivation('Motivation', Icons.bolt_rounded, Color(0xFFEAB308)),
  question('Question', Icons.help_outline_rounded, Color(0xFF3B82F6));

  final String label;
  final IconData icon;
  final Color color;

  const PostFlair(this.label, this.icon, this.color);
}

/// Create Post Sheet - Bottom sheet for creating or editing manual posts
///
/// Also supports sharing a workout to the social feed via [workoutPreFill].
class CreatePostSheet extends ConsumerStatefulWidget {
  /// If provided, the sheet operates in edit mode with pre-populated fields.
  final Map<String, dynamic>? existingActivity;

  /// If provided, pre-fills the sheet with workout data for sharing to social.
  /// Expected keys: 'name', 'type', 'difficulty', 'duration_minutes',
  /// 'exercises_count', 'workout_id'.
  final Map<String, dynamic>? workoutPreFill;

  const CreatePostSheet({
    super.key,
    this.existingActivity,
    this.workoutPreFill,
  });

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final Set<PostFlair> _selectedFlairs = {PostFlair.fitness};
  PostVisibilityOption _visibility = PostVisibilityOption.friends;
  List<File> _selectedImages = [];
  File? _selectedVideo;
  File? _videoThumbnail;
  bool _isPosting = false;
  String? _userId;
  static const int _maxImages = 5;

  // Workout stats state
  bool _exercisesExpanded = false;
  final Set<String> _enabledStats = {'volume', 'duration', 'exercises'};
  int? _waterMl;
  bool _loadingWater = false;

  bool get _isEditMode => widget.existingActivity != null;
  bool get _isWorkoutShare => widget.workoutPreFill != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (mounted) {
        setState(() => _userId = userId);
      }
    });

    // Pre-populate fields in edit mode
    if (_isEditMode) {
      final data = widget.existingActivity!['activity_data'] as Map<String, dynamic>? ?? {};
      _captionController.text = data['caption'] as String? ?? '';

      final flairNames = (data['flairs'] as List<dynamic>?)?.cast<String>() ?? [];
      _selectedFlairs.clear();
      for (final name in flairNames) {
        try {
          _selectedFlairs.add(PostFlair.values.firstWhere((f) => f.name == name));
        } catch (_) {}
      }
      if (_selectedFlairs.isEmpty) _selectedFlairs.add(PostFlair.fitness);
    }

    // Pre-populate fields for workout share
    if (_isWorkoutShare) {
      final w = widget.workoutPreFill!;
      final name = w['name'] as String? ?? 'Workout';
      final type = w['type'] as String? ?? '';
      final duration = w['duration_minutes'] as int?;
      final exerciseCount = w['exercises_count'] as int?;

      final parts = <String>[];
      if (type.isNotEmpty) parts.add(type);
      if (duration != null) parts.add('$duration min');
      if (exerciseCount != null) parts.add('$exerciseCount exercises');
      final details = parts.isNotEmpty ? ' (${parts.join(' · ')})' : '';

      _captionController.text = 'Check out my $name workout$details 🔥';
      _selectedFlairs
        ..clear()
        ..add(PostFlair.fitness);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedVideo != null) {
      _showSnackBar('Remove video before adding images', isError: true);
      return;
    }
    try {
      if (source == ImageSource.gallery) {
        // Multi-pick from gallery
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 70,
        );
        if (images.isNotEmpty) {
          setState(() {
            final remaining = _maxImages - _selectedImages.length;
            final toAdd = images.take(remaining).map((x) => File(x.path)).toList();
            _selectedImages.addAll(toAdd);
          });
          if (_selectedImages.length >= _maxImages) {
            _showSnackBar('Maximum $_maxImages images allowed');
          }
        }
      } else {
        // Single pick from camera
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 70,
        );
        if (image != null && _selectedImages.length < _maxImages) {
          setState(() {
            _selectedImages.add(File(image.path));
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Failed to pick image', isError: true);
    }
  }

  void _removeImage([int? index]) {
    HapticFeedback.lightImpact();
    setState(() {
      if (index != null && index < _selectedImages.length) {
        _selectedImages.removeAt(index);
      } else {
        _selectedImages.clear();
      }
    });
  }

  Future<void> _pickVideo() async {
    if (_selectedImages.isNotEmpty) {
      _showSnackBar('Remove images before adding a video', isError: true);
      return;
    }
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (video != null) {
        setState(() => _selectedVideo = File(video.path));
        // Generate thumbnail
        final thumbnailPath = await vt.VideoThumbnail.thumbnailFile(
          video: video.path,
          imageFormat: vt.ImageFormat.JPEG,
          maxWidth: 512,
          quality: 75,
        );
        if (thumbnailPath != null && mounted) {
          setState(() => _videoThumbnail = File(thumbnailPath));
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      _showSnackBar('Failed to pick video', isError: true);
    }
  }

  void _removeVideo() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedVideo = null;
      _videoThumbnail = null;
    });
  }

  Future<void> _createPost() async {
    if (_userId == null) {
      _showSnackBar('Please log in to post', isError: true);
      return;
    }

    final caption = _captionController.text.trim();
    if (caption.isEmpty && _selectedImages.isEmpty && _selectedVideo == null && !_isEditMode) {
      _showSnackBar('Please add some content to your post', isError: true);
      return;
    }

    setState(() => _isPosting = true);
    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);

      final activityData = <String, dynamic>{
        'caption': caption,
        'post_type': _selectedFlairs.isNotEmpty ? _selectedFlairs.first.name : 'fitness',
        'flairs': _selectedFlairs.map((f) => f.name).toList(),
      };

      if (_isEditMode) {
        // Edit mode: update existing activity
        final activityId = widget.existingActivity!['id'] as String;
        await socialService.editActivity(
          userId: _userId!,
          activityId: activityId,
          activityData: activityData,
        );

        if (mounted) {
          AppSnackBar.success(context, 'Post updated!');
          Navigator.pop(context, true);
        }
        return;
      }

      // Create mode - upload images or video
      if (_selectedImages.isNotEmpty) {
        _showSnackBar('Uploading image${_selectedImages.length > 1 ? 's' : ''}...');

        final imageService = ref.read(socialImageServiceProvider);
        final uploadedUrls = <String>[];

        for (final imageFile in _selectedImages) {
          final imageUrl = await imageService.uploadPostImage(
            imageFile: imageFile,
            userId: _userId!,
          );
          if (imageUrl != null) {
            uploadedUrls.add(imageUrl);
          } else {
            if (mounted) {
              _showSnackBar('Failed to upload an image. Please try again.', isError: true);
              setState(() => _isPosting = false);
            }
            return;
          }
        }

        activityData['has_image'] = true;
        activityData['image_url'] = uploadedUrls.first; // backward compat
        if (uploadedUrls.length > 1) {
          activityData['image_urls'] = uploadedUrls;
        }
      } else if (_selectedVideo != null) {
        _showSnackBar('Uploading video...');

        final imageService = ref.read(socialImageServiceProvider);

        // Upload thumbnail first
        String? thumbUrl;
        if (_videoThumbnail != null) {
          thumbUrl = await imageService.uploadPostImage(
            imageFile: _videoThumbnail!,
            userId: _userId!,
          );
        }

        // Upload video
        final videoUrl = await imageService.uploadPostImage(
          imageFile: _selectedVideo!,
          userId: _userId!,
        );

        if (videoUrl != null) {
          activityData['has_video'] = true;
          activityData['video_url'] = videoUrl;
          if (thumbUrl != null) {
            activityData['thumbnail_url'] = thumbUrl;
          }
        } else {
          if (mounted) {
            _showSnackBar('Failed to upload video. Please try again.', isError: true);
            setState(() => _isPosting = false);
          }
          return;
        }
      }

      // If sharing a workout, include workout metadata in activity data
      if (_isWorkoutShare) {
        final w = widget.workoutPreFill!;
        activityData['workout_name'] = w['name'] as String? ?? 'Workout';
        activityData['workout_type'] = w['type'] as String? ?? '';
        activityData['duration_minutes'] = w['duration_minutes'];
        activityData['exercises_count'] = w['exercises_count'];
        activityData['difficulty'] = w['difficulty'] as String? ?? '';

        // Include exercises performance data
        final exercises = w['exercises'] as List<Map<String, dynamic>>?;
        if (exercises != null && exercises.isNotEmpty) {
          activityData['exercises_performance'] = exercises;
        }

        // Include stats gated by user toggle
        if (_enabledStats.contains('volume')) {
          activityData['total_volume_lbs'] = w['total_volume_lbs'];
        }
        if (_enabledStats.contains('sets')) {
          activityData['total_sets'] = w['total_sets'];
        }
        if (_enabledStats.contains('reps')) {
          activityData['total_reps'] = w['total_reps'];
        }
        if (_enabledStats.contains('water') && _waterMl != null) {
          activityData['water_ml'] = _waterMl;
        }
      }

      await socialService.createActivity(
        userId: _userId!,
        activityType: _isWorkoutShare
            ? SocialActivityType.workoutShared
            : SocialActivityType.manualPost,
        activityData: activityData,
        visibility: _visibility.serviceValue,
      );

      ref.read(posthogServiceProvider).capture(
        eventName: 'social_post_created',
        properties: <String, Object>{
          'post_type': _isWorkoutShare ? 'workout_shared' : 'manual_post',
          'has_image': _selectedImages.isNotEmpty,
          'has_video': _selectedVideo != null,
        },
      );

      if (mounted) {
        AppSnackBar.success(
          context,
          _isWorkoutShare ? 'Workout shared!' : 'Post created successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error ${_isEditMode ? 'editing' : 'creating'} post: $e');
      if (mounted) {
        _showSnackBar('Failed to ${_isEditMode ? 'update' : 'create'} post. Please try again.', isError: true);
        setState(() => _isPosting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppSnackBar.error(context, message);
    } else {
      AppSnackBar.info(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
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
                  color: cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _isEditMode
                          ? 'Edit Post'
                          : _isWorkoutShare
                              ? 'Share Workout'
                              : 'Create Post',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton(
                      onPressed: _isPosting ? null : _createPost,
                      style: FilledButton.styleFrom(
                        backgroundColor: ref.colors(context).accent,
                        foregroundColor: ref.colors(context).accentContrast,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditMode ? 'Save' : 'Post'),
                    ),
                  ],
                ),
              ),

              Divider(color: cardBorder.withValues(alpha: 0.3), height: 1),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Caption input
                      _buildCaptionInput(isDark, cardBorder),

                      // Trending hashtags suggestions
                      _buildTrendingHashtags(isDark),

                      const SizedBox(height: 16),

                      // Workout stats (only for workout shares)
                      if (_isWorkoutShare) ...[
                        _buildWorkoutStats(isDark, cardBorder),
                        const SizedBox(height: 16),
                      ],

                      // Flair tags
                      _buildFlairTags(isDark, cardBorder),

                      const SizedBox(height: 16),

                      // Image section (hidden in edit mode — can't change image)
                      if (!_isEditMode) ...[
                        _buildImageSection(isDark, cardBorder),

                        const SizedBox(height: 16),

                        // Visibility selector
                        _buildVisibilitySelector(isDark, cardBorder),
                      ],

                      // Bottom padding for keyboard
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionInput(bool isDark, Color cardBorder) {
    final accentColor = ref.colors(context).accent;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Share your fitness journey...',
            hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.5)),
            filled: true,
            fillColor: isDark
                ? AppColors.pureBlack.withValues(alpha: 0.5)
                : AppColorsLight.pureWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            counterStyle: TextStyle(color: textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingHashtags(bool isDark) {
    final trendingAsync = ref.watch(trendingHashtagsProvider);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.colors(context).accent;

    return trendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (hashtags) {
        if (hashtags.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: hashtags.take(8).map<Widget>((tag) {
                  final name = tag['name'] as String? ?? '';
                  final count = tag['post_count'] as int? ?? 0;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final currentText = _captionController.text;
                      final hashtag = '#$name';
                      if (!currentText.contains(hashtag)) {
                        final separator = currentText.isEmpty || currentText.endsWith(' ') ? '' : ' ';
                        _captionController.text = '$currentText$separator$hashtag ';
                        _captionController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _captionController.text.length),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '#$name${count > 0 ? ' · $count' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: accentColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchWater() async {
    if (_loadingWater) return;
    setState(() => _loadingWater = true);

    try {
      final hydrationState = ref.read(hydrationProvider);
      int? totalMl = hydrationState.todaySummary?.totalMl;

      if (totalMl == null && _userId != null) {
        await ref.read(hydrationProvider.notifier).loadTodaySummary(_userId!);
        totalMl = ref.read(hydrationProvider).todaySummary?.totalMl;
      }

      if (mounted) {
        setState(() {
          _waterMl = totalMl ?? 0;
          _loadingWater = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching water: $e');
      if (mounted) {
        setState(() {
          _waterMl = 0;
          _loadingWater = false;
        });
      }
    }
  }

  Widget _buildWorkoutStats(bool isDark, Color cardBorder) {
    final w = widget.workoutPreFill!;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final exercises = w['exercises'] as List<Map<String, dynamic>>? ?? [];

    final volume = w['total_volume_lbs'] as int? ?? 0;
    final duration = w['duration_minutes'] as int? ?? 0;
    final exerciseCount = w['exercises_count'] as int? ?? exercises.length;
    final totalSets = w['total_sets'] as int? ?? 0;
    final totalReps = w['total_reps'] as int? ?? 0;

    String formatVolume(int lbs) {
      if (lbs >= 1000) {
        return '${(lbs / 1000).toStringAsFixed(1)}k lbs';
      }
      return '$lbs lbs';
    }

    final stats = <_StatPillData>[
      _StatPillData('volume', Icons.fitness_center_rounded, formatVolume(volume)),
      _StatPillData('duration', Icons.timer_rounded, '$duration min'),
      _StatPillData('exercises', Icons.list_rounded, '$exerciseCount exercises'),
      _StatPillData('sets', Icons.repeat_rounded, '$totalSets sets'),
      _StatPillData('reps', Icons.numbers_rounded, '$totalReps reps'),
      _StatPillData(
        'water',
        Icons.water_drop_rounded,
        _loadingWater
            ? '...'
            : _waterMl != null
                ? '$_waterMl ml'
                : 'Water',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Stats',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),

        // Stats pills row
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final stat = stats[index];
              final isEnabled = _enabledStats.contains(stat.key);
              return _buildStatPill(stat, isEnabled, isDark, cardBorder);
            },
          ),
        ),

        // Collapsible exercise list
        if (exercises.isNotEmpty) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _exercisesExpanded = !_exercisesExpanded);
            },
            child: Row(
              children: [
                Icon(
                  _exercisesExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _exercisesExpanded ? 'Hide exercises' : 'Show exercises',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_exercisesExpanded) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  final name = ex['name'] as String? ?? 'Exercise';
                  final sets = ex['sets'] as int?;
                  final reps = ex['reps'] as int?;
                  final weightKg = ex['weight_kg'] as double?;

                  final details = <String>[];
                  if (sets != null && reps != null) {
                    details.add('${sets}x$reps');
                  }
                  if (weightKg != null && weightKg > 0) {
                    final lbs = (weightKg * 2.20462).round();
                    details.add('@ $lbs lbs');
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${index + 1}.',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (details.isNotEmpty)
                          Text(
                            details.join(' '),
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStatPill(_StatPillData stat, bool isEnabled, bool isDark, Color cardBorder) {
    final cyanAccent = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isEnabled) {
            _enabledStats.remove(stat.key);
          } else {
            _enabledStats.add(stat.key);
            // Fetch water on first enable
            if (stat.key == 'water' && _waterMl == null) {
              _fetchWater();
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isEnabled ? cyanAccent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled ? cyanAccent : cardBorder.withValues(alpha: 0.5),
            width: isEnabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              stat.icon,
              size: 14,
              color: isEnabled ? cyanAccent : textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              stat.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
                color: isEnabled ? cyanAccent : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlairTags(bool isDark, Color cardBorder) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PostFlair.values.map((flair) {
            final isSelected = _selectedFlairs.contains(flair);
            final flairColor = flair.color;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedFlairs.remove(flair);
                  } else {
                    _selectedFlairs.add(flair);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? flairColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? flairColor : cardBorder.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      flair.icon,
                      size: 14,
                      color: isSelected ? flairColor : textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      flair.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? flairColor : textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageSection(bool isDark, Color cardBorder) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final hasMedia = _selectedImages.isNotEmpty || _selectedVideo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),

        // Show selected video preview
        if (_selectedVideo != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _videoThumbnail != null
                    ? Image.file(
                        _videoThumbnail!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.videocam_rounded, color: Colors.white, size: 48),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeVideo,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Video indicator badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Video', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],

        // Show selected images as horizontal thumbnail row (F1)
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + (_selectedImages.length < _maxImages ? 1 : 0),
              itemBuilder: (context, index) {
                // "Add more" button at end
                if (index == _selectedImages.length) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.pureBlack.withValues(alpha: 0.5)
                            : AppColorsLight.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, color: textMuted, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            'Add more',
                            style: TextStyle(color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Image thumbnail
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],

        // Media picker buttons (only when no media selected, or can add more images)
        if (!hasMedia)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pickImage(ImageSource.camera);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.pureBlack.withValues(alpha: 0.5)
                          : AppColorsLight.pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Camera',
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pickImage(ImageSource.gallery);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.pureBlack.withValues(alpha: 0.5)
                          : AppColorsLight.pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_rounded, color: textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Gallery',
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pickVideo();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.pureBlack.withValues(alpha: 0.5)
                          : AppColorsLight.pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_rounded, color: textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Video',
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildVisibilitySelector(bool isDark, Color cardBorder) {
    final accentColor = ref.colors(context).accent;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who can see this?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: PostVisibilityOption.values.map((visibility) {
            final isSelected = _visibility == visibility;
            final isLast = visibility == PostVisibilityOption.values.last;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _visibility = visibility);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : cardBorder.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          visibility.icon,
                          color: isSelected ? accentColor : textMuted,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visibility.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? accentColor : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Simple data holder for stat pill rendering.
class _StatPillData {
  final String key;
  final IconData icon;
  final String label;

  const _StatPillData(this.key, this.icon, this.label);
}
