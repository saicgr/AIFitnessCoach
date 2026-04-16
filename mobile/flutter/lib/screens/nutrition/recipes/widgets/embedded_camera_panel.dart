/// Snapchat-style embedded camera preview used by the recipe import Photo tab.
///
/// Renders a live [CameraPreview] with shutter / flip / flash controls and a
/// gallery thumbnail fallback. Handles permission prompts, lifecycle, and
/// controller disposal so it can be safely mounted/unmounted as the tab changes.
library;

import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/haptic_service.dart';

enum _CameraState { initializing, ready, denied, error, unsupported }

class EmbeddedCameraPanel extends StatefulWidget {
  /// Called with a base64-encoded JPEG when the user captures or picks a photo.
  final ValueChanged<String> onCaptured;
  final Color accent;
  final bool isDark;
  final bool enabled;

  const EmbeddedCameraPanel({
    super.key,
    required this.onCaptured,
    required this.accent,
    required this.isDark,
    this.enabled = true,
  });

  @override
  State<EmbeddedCameraPanel> createState() => _EmbeddedCameraPanelState();
}

class _EmbeddedCameraPanelState extends State<EmbeddedCameraPanel>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  _CameraState _state = _CameraState.initializing;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.off;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didUpdateWidget(covariant EmbeddedCameraPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pause preview when tab is not active; resume when returning.
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _resumeCamera();
      } else {
        _pauseCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed && widget.enabled) {
      _resumeCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _state = _CameraState.unsupported;
          _errorMessage = 'No camera available on this device.';
        });
        return;
      }
      _cameras = cams;
      // Prefer the back camera if present
      _cameraIndex = cams.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _startController();
    } on CameraException catch (e) {
      _handleCameraException(e);
    } catch (e) {
      setState(() {
        _state = _CameraState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _startController() async {
    final ctrl = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      await ctrl.setFlashMode(_flashMode);
      _controller = ctrl;
      setState(() => _state = _CameraState.ready);
    } on CameraException catch (e) {
      await ctrl.dispose();
      _handleCameraException(e);
    }
  }

  void _handleCameraException(CameraException e) {
    if (kDebugMode) debugPrint('CameraException ${e.code}: ${e.description}');
    final denied = e.code == 'CameraAccessDenied' ||
        e.code == 'CameraAccessDeniedWithoutPrompt' ||
        e.code == 'CameraAccessRestricted';
    setState(() {
      _state = denied ? _CameraState.denied : _CameraState.error;
      _errorMessage = e.description ?? e.code;
    });
  }

  Future<void> _pauseCamera() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    try {
      await ctrl.pausePreview();
    } catch (_) {}
  }

  Future<void> _resumeCamera() async {
    final ctrl = _controller;
    if (ctrl == null) {
      if (_state == _CameraState.initializing || _state == _CameraState.ready) {
        await _initCamera();
      }
      return;
    }
    try {
      await ctrl.resumePreview();
    } catch (_) {}
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    HapticService.light();
    final ctrl = _controller;
    setState(() => _state = _CameraState.initializing);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await ctrl?.dispose();
    _controller = null;
    await _startController();
  }

  Future<void> _cycleFlash() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    HapticService.light();
    FlashMode next;
    switch (_flashMode) {
      case FlashMode.off:
        next = FlashMode.auto;
        break;
      case FlashMode.auto:
        next = FlashMode.always;
        break;
      default:
        next = FlashMode.off;
    }
    try {
      await ctrl.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {}
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    HapticService.medium();
    try {
      final file = await ctrl.takePicture();
      final bytes = await File(file.path).readAsBytes();
      if (!mounted) return;
      widget.onCaptured(base64Encode(bytes));
    } on CameraException catch (e) {
      _handleCameraException(e);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    HapticService.light();
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (f == null) return;
      final bytes = await File(f.path).readAsBytes();
      if (!mounted) return;
      widget.onCaptured(base64Encode(bytes));
    } catch (e) {
      if (kDebugMode) debugPrint('Gallery pick failed: $e');
    }
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.off: return Icons.flash_off_rounded;
      case FlashMode.auto: return Icons.flash_auto_rounded;
      case FlashMode.always: return Icons.flash_on_rounded;
      case FlashMode.torch: return Icons.flashlight_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          if (_state == _CameraState.ready) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final ctrl = _controller;
    if (_state == _CameraState.ready && ctrl != null && ctrl.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: ctrl.value.aspectRatio,
            child: CameraPreview(ctrl),
          ),
        ),
      );
    }
    return _buildStatusOverlay();
  }

  Widget _buildStatusOverlay() {
    final text = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bg = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;

    if (_state == _CameraState.initializing) {
      return Container(
        color: bg,
        child: Center(
          child: CircularProgressIndicator(color: widget.accent),
        ),
      );
    }

    final (icon, title, subtitle) = switch (_state) {
      _CameraState.denied => (
        Icons.no_photography_rounded,
        'Camera access denied',
        'Enable camera in Settings to photograph recipes.',
      ),
      _CameraState.unsupported => (
        Icons.videocam_off_rounded,
        'No camera available',
        'Use the gallery to pick an existing photo.',
      ),
      _ => (
        Icons.error_outline_rounded,
        'Camera unavailable',
        _errorMessage ?? 'Try again or use the gallery.',
      ),
    };

    return Container(
      color: bg,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: widget.accent),
          const SizedBox(height: 12),
          Text(title,
            style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(subtitle,
            style: TextStyle(color: muted, fontSize: 12),
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: Icon(Icons.photo_library_outlined, color: widget.accent),
            label: Text('From gallery', style: TextStyle(color: widget.accent)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: widget.accent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
          if (_state == _CameraState.denied || _state == _CameraState.error) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _state = _CameraState.initializing);
                _initCamera();
              },
              child: Text('Try again', style: TextStyle(color: widget.accent)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Stack(
      children: [
        // Top-left: flash
        Positioned(
          top: 12, left: 12,
          child: _CircleButton(icon: _flashIcon, onTap: _cycleFlash),
        ),
        // Top-right: flip
        if (_cameras.length > 1)
          Positioned(
            top: 12, right: 12,
            child: _CircleButton(icon: Icons.cameraswitch_rounded, onTap: _flipCamera),
          ),
        // Bottom controls row
        Positioned(
          left: 0, right: 0, bottom: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CircleButton(
                icon: Icons.photo_library_outlined,
                onTap: _pickFromGallery,
              ),
              _ShutterButton(onTap: _capture, busy: _capturing, accent: widget.accent),
              const SizedBox(width: 44), // spacer to balance gallery button
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool busy;
  final Color accent;
  const _ShutterButton({required this.onTap, required this.busy, required this.accent});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 76, height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3, color: accent),
                )
              : Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
