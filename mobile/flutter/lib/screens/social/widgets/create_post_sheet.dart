import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/social_service.dart' show PostVisibility, SocialActivityType;

/// UI representation for post visibility options
enum PostVisibilityOption {
  public('Public', Icons.public_rounded, 'Everyone can see this', PostVisibility.public),
  friends('Friends', Icons.people_rounded, 'Only friends can see this', PostVisibility.friends),
  privateOnly('Private', Icons.lock_rounded, 'Only you can see this', PostVisibility.private);

  final String label;
  final IconData icon;
  final String description;
  final PostVisibility serviceValue;

  const PostVisibilityOption(this.label, this.icon, this.description, this.serviceValue);
}

/// Post type options
enum PostType {
  progress('Progress Update', Icons.trending_up_rounded),
  photo('Photo', Icons.photo_camera_rounded),
  milestone('Milestone', Icons.emoji_events_rounded);

  final String label;
  final IconData icon;

  const PostType(this.label, this.icon);
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

  PostType _selectedType = PostType.progress;
  PostVisibilityOption _visibility = PostVisibilityOption.friends;
  File? _selectedImage;
  bool _isPosting = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    // Get userId from authStateProvider (consistent with rest of app)
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
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
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

      // Prepare activity data based on post type
      final activityData = <String, dynamic>{
        'caption': caption,
        'post_type': _selectedType.name,
      };

      // If there's an image, we'd normally upload it here
      // For now, we'll just include a flag
      if (_selectedImage != null) {
        activityData['has_image'] = true;
        // TODO: Implement image upload to storage
        // activityData['image_url'] = await uploadImage(_selectedImage!);
      }

      await socialService.createActivity(
        userId: _userId!,
        activityType: SocialActivityType.manualPost,
        activityData: activityData,
        visibility: _visibility.serviceValue,
      );

      if (mounted) {
        _showSnackBar('Post created successfully!');
        Navigator.pop(context, true); // Return true to indicate post created
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
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    style: TextStyle(color: AppColors.textMuted),
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
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
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
                  // Post type selector
                  _buildPostTypeSelector(isDark, cardBorder),

                  const SizedBox(height: 20),

                  // Caption input
                  _buildCaptionInput(isDark, cardBorder),

                  const SizedBox(height: 20),

                  // Image section
                  _buildImageSection(isDark, cardBorder),

                  const SizedBox(height: 20),

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
    );
  }

  Widget _buildPostTypeSelector(bool isDark, Color cardBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: PostType.values.map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != PostType.values.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedType = type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cyan.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.cyan : cardBorder.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type.icon,
                          color: isSelected ? AppColors.cyan : AppColors.textMuted,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.cyan : AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
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

  Widget _buildCaptionInput(bool isDark, Color cardBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _captionController,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: _getHintText(),
            hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
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
              borderSide: const BorderSide(color: AppColors.cyan, width: 2),
            ),
            counterStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  String _getHintText() {
    switch (_selectedType) {
      case PostType.progress:
        return 'Share your fitness progress...';
      case PostType.photo:
        return 'Add a caption to your photo...';
      case PostType.milestone:
        return 'Celebrate your milestone...';
    }
  }

  Widget _buildImageSection(bool isDark, Color cardBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),

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
                child: _buildImagePickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                  isDark: isDark,
                  cardBorder: cardBorder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImagePickerButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                  isDark: isDark,
                  cardBorder: cardBorder,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardBorder,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.pureBlack.withValues(alpha: 0.5)
              : AppColorsLight.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector(bool isDark, Color cardBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who can see this?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ...PostVisibilityOption.values.map((visibility) {
          final isSelected = _visibility == visibility;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _visibility = visibility);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cyan.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.cyan : cardBorder.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    visibility.icon,
                    color: isSelected ? AppColors.cyan : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visibility.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.cyan : null,
                          ),
                        ),
                        Text(
                          visibility.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
