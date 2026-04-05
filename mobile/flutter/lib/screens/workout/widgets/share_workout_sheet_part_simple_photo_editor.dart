part of 'share_workout_sheet.dart';


/// Simple photo editor for basic image manipulation
class _SimplePhotoEditor extends StatefulWidget {
  final Uint8List imageBytes;
  final String workoutName;

  const _SimplePhotoEditor({
    required this.imageBytes,
    required this.workoutName,
  });

  @override
  State<_SimplePhotoEditor> createState() => _SimplePhotoEditorState();
}


class _SimplePhotoEditorState extends State<_SimplePhotoEditor> {
  double _brightness = 0.0;
  double _contrast = 1.0;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColorsLight.background,
      appBar: AppBar(
        title: const Text('Edit Image'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSharing ? null : _shareEdited,
            child: Text(
              'Share',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            child: Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_buildColorMatrix()),
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Edit controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brightness slider
                Row(
                  children: [
                    Icon(Icons.brightness_6_rounded, color: AppColors.cyan),
                    const SizedBox(width: 12),
                    const Text('Brightness'),
                    const Spacer(),
                    Text('${(_brightness * 100).toInt()}%'),
                  ],
                ),
                Slider(
                  value: _brightness,
                  min: -0.5,
                  max: 0.5,
                  onChanged: (value) => setState(() => _brightness = value),
                  activeColor: AppColors.cyan,
                ),

                const SizedBox(height: 16),

                // Contrast slider
                Row(
                  children: [
                    Icon(Icons.contrast_rounded, color: AppColors.purple),
                    const SizedBox(width: 12),
                    const Text('Contrast'),
                    const Spacer(),
                    Text('${(_contrast * 100).toInt()}%'),
                  ],
                ),
                Slider(
                  value: _contrast,
                  min: 0.5,
                  max: 1.5,
                  onChanged: (value) => setState(() => _contrast = value),
                  activeColor: AppColors.purple,
                ),

                const SizedBox(height: 16),

                // Reset button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _brightness = 0.0;
                        _contrast = 1.0;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> _buildColorMatrix() {
    // Simple brightness and contrast matrix
    final b = _brightness;
    final c = _contrast;
    final t = (1.0 - c) / 2.0;

    return [
      c, 0, 0, 0, b * 255 + t * 255,
      0, c, 0, 0, b * 255 + t * 255,
      0, 0, c, 0, b * 255 + t * 255,
      0, 0, 0, 1, 0,
    ];
  }

  Future<void> _shareEdited() async {
    setState(() => _isSharing = true);

    try {
      // For now, share the original image with filters applied
      // In a full implementation, we'd capture the filtered image
      await ShareService.shareGeneric(
        widget.imageBytes,
        caption: 'Just crushed my ${widget.workoutName} workout!',
      );

      if (mounted) {
        Navigator.pop(context, widget.imageBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}


/// Full-screen image preview dialog with pinch-to-zoom
class _ImagePreviewDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final String templateName;

  const _ImagePreviewDialog({
    required this.imageBytes,
    required this.templateName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Image with pinch-to-zoom
          Center(
            child: Hero(
              tag: 'preview_$templateName',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Template name label
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                templateName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Hint at bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pinch to zoom • Tap anywhere to close',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

