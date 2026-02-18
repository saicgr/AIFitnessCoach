import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/social_service.dart' show PostVisibility, SocialActivityType;
import '../../../data/services/social_image_service.dart';

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
  fitness('Fitness', Icons.fitness_center_rounded),
  progress('Progress', Icons.trending_up_rounded),
  milestone('Milestone', Icons.emoji_events_rounded),
  nutrition('Nutrition', Icons.restaurant_rounded),
  motivation('Motivation', Icons.bolt_rounded),
  question('Question', Icons.help_outline_rounded);

  final String label;
  final IconData icon;

  const PostFlair(this.label, this.icon);
}

/// Create Post Sheet - Bottom sheet for creating manual posts
class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final Set<PostFlair> _selectedFlairs = {PostFlair.fitness};
  PostVisibilityOption _visibility = PostVisibilityOption.friends;
  File? _selectedImage;
  bool _isPosting = false;
  String? _userId;

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
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Failed to pick image');
    }
  }

  void _removeImage() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _createPost() async {
    if (_userId == null) {
      _showSnackBar('Please log in to post');
      return;
    }

    final caption = _captionController.text.trim();
    if (caption.isEmpty && _selectedImage == null) {
      _showSnackBar('Please add some content to your post');
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

      if (_selectedImage != null) {
        _showSnackBar('Uploading image...');

        final imageService = ref.read(socialImageServiceProvider);
        final imageUrl = await imageService.uploadPostImage(
          imageFile: _selectedImage!,
          userId: _userId!,
        );

        if (imageUrl != null) {
          activityData['has_image'] = true;
          activityData['image_url'] = imageUrl;
        } else {
          if (mounted) {
            _showSnackBar('Failed to upload image. Please try again.');
            setState(() => _isPosting = false);
          }
          return;
        }
      }

      await socialService.createActivity(
        userId: _userId!,
        activityType: SocialActivityType.manualPost,
        activityData: activityData,
        visibility: _visibility.serviceValue,
      );

      if (mounted) {
        _showSnackBar('Post created successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      if (mounted) {
        _showSnackBar('Failed to create post. Please try again.');
        setState(() => _isPosting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                    const Text(
                      'Create Post',
                      style: TextStyle(
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
                          : const Text('Post'),
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

                      const SizedBox(height: 16),

                      // Flair tags
                      _buildFlairTags(isDark, cardBorder),

                      const SizedBox(height: 16),

                      // Image section
                      _buildImageSection(isDark, cardBorder),

                      const SizedBox(height: 16),

                      // Visibility selector
                      _buildVisibilitySelector(isDark, cardBorder),

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

  Widget _buildFlairTags(bool isDark, Color cardBorder) {
    final accentColor = ref.colors(context).accent;
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
                  color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accentColor : cardBorder.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      flair.icon,
                      size: 14,
                      color: isSelected ? accentColor : textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      flair.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? accentColor : textMuted,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),

        if (_selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeImage,
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
            ],
          )
        else
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
              const SizedBox(width: 12),
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
