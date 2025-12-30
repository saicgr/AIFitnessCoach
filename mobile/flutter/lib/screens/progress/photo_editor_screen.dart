import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';

/// Photo editor screen with cropping and FitWiz logo overlay
class PhotoEditorScreen extends StatefulWidget {
  final File imageFile;
  final String viewTypeName;

  const PhotoEditorScreen({
    super.key,
    required this.imageFile,
    required this.viewTypeName,
  });

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  File? _editedImage;
  bool _showLogo = true;
  bool _isSaving = false;

  // Logo position and size
  Offset _logoPosition = const Offset(20, 20);
  double _logoScale = 1.0;
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _captureKey = GlobalKey();

  // For tracking drag
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();
    _editedImage = widget.imageFile;
  }

  Future<void> _cropImage() async {
    if (_editedImage == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _editedImage!.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: AppColors.nearBlack,
          toolbarWidgetColor: Colors.white,
          backgroundColor: AppColors.pureBlack,
          activeControlsWidgetColor: AppColors.cyan,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      setState(() {
        _editedImage = File(croppedFile.path);
      });
    }
  }

  Future<File?> _captureEditedImage() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  Future<void> _saveAndReturn() async {
    setState(() => _isSaving = true);

    try {
      // If logo is shown, capture the composite image
      File? finalImage;
      if (_showLogo) {
        finalImage = await _captureEditedImage();
      }
      finalImage ??= _editedImage;

      if (mounted && finalImage != null) {
        Navigator.pop(context, finalImage);
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        title: Text('Edit ${widget.viewTypeName} Photo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Crop button
          IconButton(
            icon: const Icon(Icons.crop),
            tooltip: 'Crop',
            onPressed: _cropImage,
          ),
          // Toggle logo button
          IconButton(
            icon: Icon(
              _showLogo ? Icons.branding_watermark : Icons.branding_watermark_outlined,
              color: _showLogo ? AppColors.cyan : null,
            ),
            tooltip: _showLogo ? 'Hide Logo' : 'Show Logo',
            onPressed: () => setState(() => _showLogo = !_showLogo),
          ),
          // Save button
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _saveAndReturn,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // Image with logo overlay
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _captureKey,
                child: Container(
                  color: AppColors.pureBlack,
                  child: Stack(
                    children: [
                      // The image
                      if (_editedImage != null)
                        Image.file(
                          _editedImage!,
                          key: _imageKey,
                          fit: BoxFit.contain,
                        ),

                      // Moveable/Resizable FitWiz logo
                      if (_showLogo)
                        Positioned(
                          left: _logoPosition.dx,
                          top: _logoPosition.dy,
                          child: GestureDetector(
                            onScaleStart: (details) {
                              _lastFocalPoint = details.focalPoint;
                              _lastScale = _logoScale;
                            },
                            onScaleUpdate: (details) {
                              setState(() {
                                // Handle drag
                                final delta = details.focalPoint - _lastFocalPoint;
                                _logoPosition = Offset(
                                  _logoPosition.dx + delta.dx,
                                  _logoPosition.dy + delta.dy,
                                );
                                _lastFocalPoint = details.focalPoint;

                                // Handle pinch-to-scale
                                if (details.scale != 1.0) {
                                  _logoScale = (_lastScale * details.scale)
                                      .clamp(0.5, 3.0);
                                }
                              });
                            },
                            child: Transform.scale(
                              scale: _logoScale,
                              child: _buildFitWizLogo(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.nearBlack,
              border: Border(
                top: BorderSide(
                  color: AppColors.cardBorder,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instructions
                  if (_showLogo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Drag logo to move • Pinch to resize',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Logo size slider
                  if (_showLogo)
                    Row(
                      children: [
                        Icon(
                          Icons.photo_size_select_small,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        Expanded(
                          child: Slider(
                            value: _logoScale,
                            min: 0.5,
                            max: 3.0,
                            activeColor: AppColors.cyan,
                            inactiveColor: AppColors.cardBorder,
                            onChanged: (value) {
                              setState(() => _logoScale = value);
                            },
                          ),
                        ),
                        Icon(
                          Icons.photo_size_select_large,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolButton(
                        icon: Icons.crop,
                        label: 'Crop',
                        onTap: _cropImage,
                      ),
                      _buildToolButton(
                        icon: _showLogo
                            ? Icons.branding_watermark
                            : Icons.branding_watermark_outlined,
                        label: _showLogo ? 'Hide Logo' : 'Show Logo',
                        onTap: () => setState(() => _showLogo = !_showLogo),
                        isActive: _showLogo,
                      ),
                      _buildToolButton(
                        icon: Icons.refresh,
                        label: 'Reset Logo',
                        onTap: () {
                          setState(() {
                            _logoPosition = const Offset(20, 20);
                            _logoScale = 1.0;
                          });
                        },
                        enabled: _showLogo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.cyan.withValues(alpha: 0.2)
                    : AppColors.elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppColors.cyan : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.cyan : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.cyan : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitWizLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo icon with gradient
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Logo text
          const Text(
            'FitWiz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
