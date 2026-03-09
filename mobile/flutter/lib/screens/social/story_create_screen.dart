import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/social_provider.dart';

/// Story creation flow (F11)
/// - Camera/gallery picker
/// - Preview with optional caption text field overlay
/// - Upload via presigned URL
/// - Create story record via socialService.createStory
class StoryCreateScreen extends ConsumerStatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  ConsumerState<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends ConsumerState<StoryCreateScreen> {
  File? _selectedImage;
  final _captionController = TextEditingController();
  bool _isUploading = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedImage == null || _isUploading) return;

    setState(() => _isUploading = true);

    try {
      final socialService = ref.read(socialServiceProvider);
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
      const contentType = 'image/jpeg';

      // Get presigned URL
      final presignData = await socialService.getStoryPresignedUrl(
        fileName,
        contentType,
      );

      final uploadUrl = presignData['upload_url'] as String?;
      final mediaUrl = presignData['media_url'] as String?;
      final storageKey = presignData['storage_key'] as String?;

      if (uploadUrl == null || mediaUrl == null) {
        throw Exception('Invalid presigned URL response');
      }

      // Upload file to presigned URL using dart:io HttpClient
      // (same pattern as social_image_service.dart)
      final bytes = await _selectedImage!.readAsBytes();
      final httpClient = HttpClient();
      try {
        final request = await httpClient.putUrl(Uri.parse(uploadUrl));
        request.headers.set('Content-Type', contentType);
        request.contentLength = bytes.length;
        request.add(bytes);
        final response = await request.close();

        if (response.statusCode != 200 && response.statusCode != 204) {
          final body = await response.transform(utf8.decoder).join();
          throw Exception('Upload failed: ${response.statusCode} - $body');
        }
      } finally {
        httpClient.close();
      }

      // Create story record
      await socialService.createStory(
        mediaUrl: mediaUrl,
        mediaType: 'image',
        storageKey: storageKey,
        caption: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
      );

      // Refresh stories feed
      ref.invalidate(storiesFeedProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error uploading story: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload story: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = ref.colors(context);
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // If no image selected, show picker options
    if (_selectedImage == null) {
      return _buildPickerScreen(context, isDark, colors, backgroundColor);
    }

    // Show preview with caption
    return _buildPreviewScreen(context, isDark, colors, backgroundColor);
  }

  Widget _buildPickerScreen(
    BuildContext context,
    bool isDark,
    ThemeColors colors,
    Color backgroundColor,
  ) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          'New Story',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 80,
              color: textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'Share a moment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your story will be visible for 24 hours',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                  colors: colors,
                ),
                const SizedBox(width: 24),
                _buildPickerButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                  colors: colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: colors.accent),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewScreen(
    BuildContext context,
    bool isDark,
    ThemeColors colors,
    Color backgroundColor,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image preview
          Image.file(
            _selectedImage!,
            fit: BoxFit.contain,
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Bottom: caption + upload button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption field
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 2,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      counterStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Upload button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isUploading ? null : _handleUpload,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.accentContrast,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isUploading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.accentContrast,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isUploading ? 'Uploading...' : 'Share Story',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isUploading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
