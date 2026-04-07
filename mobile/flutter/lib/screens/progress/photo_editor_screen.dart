import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/pill_app_bar.dart';

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

class _EmojiSticker {
  String emoji;
  Offset position;
  double scale;
  double rotation;

  _EmojiSticker({
    required this.emoji,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  File? _editedImage;
  bool _showLogo = false;
  bool _isSaving = false;
  bool _showPoseHint = true;

  // Logo position and size
  Offset _logoPosition = const Offset(20, 20);
  double _logoScale = 1.0;
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _captureKey = GlobalKey();

  // For tracking drag
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;

  // Emoji stickers
  final List<_EmojiSticker> _emojiStickers = [];
  int? _activeEmojiIndex;
  Offset _emojiLastFocalPoint = Offset.zero;
  double _emojiLastScale = 1.0;
  double _emojiLastRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _editedImage = widget.imageFile;
    // Auto-dismiss pose hint after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showPoseHint = false);
    });
  }

  IconData get _poseIcon {
    switch (widget.viewTypeName.toLowerCase()) {
      case 'front':
        return Icons.accessibility_new;
      case 'back':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  Future<void> _cropImage() async {
    try {
      if (_editedImage == null) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _editedImage!.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: isDark ? AppColors.nearBlack : AppColorsLight.pureWhite,
            toolbarWidgetColor: isDark ? Colors.white : AppColorsLight.textPrimary,
            backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.nearWhite,
            activeControlsWidgetColor: isDark ? AppColors.cyan : AppColorsLight.accent,
            dimmedLayerColor: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.6),
            cropFrameColor: isDark ? AppColors.cyan : AppColorsLight.accent,
            cropGridColor: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.2),
            statusBarLight: !isDark,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            showCropGrid: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioPickerButtonHidden: false,
            rotateButtonsHidden: false,
            resetButtonHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _editedImage = File(croppedFile.path);
        });
      }
    } catch (e) {
      debugPrint('❌ [PhotoEditor] Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to crop image. Please try again.'),
          ),
        );
      }
      return;
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
      // If logo or emojis are shown, capture the composite image
      File? finalImage;
      if (_showLogo || _emojiStickers.isNotEmpty) {
        // Deselect active emoji so border doesn't appear in capture
        setState(() => _activeEmojiIndex = null);
        await Future.delayed(const Duration(milliseconds: 50));
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

  static const _emojiCategories = <String, List<String>>{
    '💪': [ // Fitness & Sports
      '💪', '🏋️', '🏃', '🚴', '🏊', '🤸', '🤼', '🤾', '⛹️', '🎯',
      '🤺', '🏄', '🚣', '🧗', '🏌️', '🏇', '⚽', '🏀', '🏈', '⚾',
      '🎾', '🏐', '🏓', '🥊', '🥋', '🥅', '🪃', '🛹', '🏂', '⛷️',
      '🛷', '🏒', '🥍', '🤿', '🏹', '🛶', '⛸️', '🎿', '🥏', '🪂',
      '🏋️‍♀️', '🏃‍♀️', '🚴‍♀️', '🏊‍♀️', '🤸‍♀️', '⛹️‍♀️', '🚵', '🚵‍♀️',
      '🤽', '🤽‍♀️', '🧘', '🧘‍♀️', '🧘‍♂️', '🏃‍♂️', '🚶', '🚶‍♀️',
    ],
    '🔥': [ // Fire & Energy
      '🔥', '⚡', '⭐', '🌟', '💥', '💫', '🪐', '✨', '🏆', '🎖️',
      '🥇', '🥈', '🥉', '🏅', '🎗️', '💯', '🎉', '🎊', '🎈', '👑',
      '💎', '💣', '🚀', '☄️', '🌋', '🌈', '☀️', '🌙', '💢', '💨',
      '🫡', '🦾', '🦿', '🧬', '⚔️', '🛡️', '🔱', '⚜️', '🏴', '🚩',
      '✊', '👊', '🤘', '🤙', '💪🏻', '💪🏼', '💪🏽', '💪🏾', '💪🏿',
      '🎆', '🎇', '🧨', '🪩', '🎭', '🔔', '📣', '🔊', '💡', '🔋',
    ],
    '😎': [ // Faces & Expressions
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
      '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '☺️', '😚',
      '😙', '🥲', '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭',
      '🫢', '🫣', '🤫', '🤔', '🫡', '🤐', '🤨', '😐', '😑', '😶',
      '🫥', '😏', '😒', '🙄', '😬', '🤥', '🫠', '😌', '😔', '😪',
      '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🥵', '🥶', '🥴',
      '😵', '😵‍💫', '🤯', '🤠', '🥳', '🥸', '😎', '🤓', '🧐', '😕',
      '🫤', '😟', '🙁', '☹️', '😮', '😯', '😲', '😳', '🥺', '🥹',
      '😦', '😧', '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣',
      '😞', '😓', '😩', '😫', '🥱', '😤', '😡', '😠', '🤬', '😈',
      '👿', '💀', '☠️', '💩', '🤡', '👹', '👺', '👻', '👽', '👾',
      '🤖', '😺', '😸', '😹', '😻', '😼', '😽', '🙀', '😿', '😾',
      '🙈', '🙉', '🙊', '🫶', '🫵', '🫰', '🫱', '🫲', '🫳', '🫴',
    ],
    '🍎': [ // Food & Nutrition
      '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐', '🍈',
      '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🫒', '🥑', '🍆',
      '🥔', '🥕', '🌽', '🌶️', '🫑', '🥒', '🥬', '🥦', '🧄', '🧅',
      '🍄', '🥜', '🫘', '🌰', '🍞', '🥐', '🥖', '🫓', '🥨', '🥯',
      '🥞', '🧇', '🧀', '🍖', '🍗', '🥩', '🥓', '🍔', '🍟', '🍕',
      '🌭', '🥪', '🌮', '🌯', '🫔', '🥙', '🧆', '🥚', '🍳', '🥘',
      '🍲', '🫕', '🥣', '🥗', '🍿', '🧈', '🧂', '🥫', '🍱', '🍘',
      '🍙', '🍚', '🍛', '🍜', '🍝', '🍠', '🍢', '🍣', '🍤', '🍥',
      '🥮', '🍡', '🥟', '🥠', '🥡', '🦀', '🦞', '🦐', '🦑', '🦪',
      '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰', '🧁', '🥧', '🍫',
      '🍬', '🍭', '🍮', '🍯', '🥤', '🧋', '🫗', '☕', '🍵', '🧃',
      '🥛', '🍼', '🫖', '🍶', '🍺', '🍻', '🥂', '🍷', '🍸', '🍹',
      '🍾', '🧊', '🥄', '🍽️', '🥢', '🧑‍🍳', '💧', '🔪', '🏺', '🫙',
    ],
    '❤️': [ // Hearts & Hands
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🩷', '🤍', '🤎',
      '💔', '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞', '💓', '💗', '💖', '💘',
      '💝', '💟', '♥️', '💌', '💐', '🌹', '🥀', '💋', '💏', '💑',
      '👍', '👎', '👊', '✊', '🤛', '🤜', '👏', '🙌', '🫶', '👐',
      '🤲', '🤝', '🙏', '✌️', '🤟', '🤘', '🤙', '👈', '👉', '👆',
      '👇', '☝️', '🫵', '🫰', '🫱', '🫲', '🫳', '🫴', '👋', '🤚',
      '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '🫰', '✍️', '🤳', '💅',
      '🦵', '🦶', '👂', '🦻', '👃', '👀', '👁️', '🧠', '🫀', '🫁',
      '🦷', '🦴', '👅', '👄', '🫦', '💬', '💭', '🗯️', '💤', '💫',
    ],
    '🎨': [ // Objects & Fun
      '🎨', '🎵', '🎶', '🎤', '🎧', '🎸', '🪕', '🎹', '🥁', '🪘',
      '🎺', '🎻', '🪗', '🎬', '🎠', '🎡', '🎢', '🎪', '🎭', '🎰',
      '📷', '📸', '📹', '🎥', '📽️', '📺', '📻', '📱', '💻', '⌨️',
      '🖥️', '🖨️', '🖱️', '💾', '💿', '📀', '⌚', '📡', '🔦', '💡',
      '🔋', '🪫', '🔌', '🧲', '🔮', '🎲', '🎮', '🕹️', '🧩', '🧸',
      '🪁', '🪀', '🎳', '🪄', '🎩', '📯', '🎼', '🪈', '🎙️', '📲',
      '💿', '🖊️', '🖋️', '✒️', '📝', '📚', '📖', '📰', '🗞️', '📌',
      '📎', '🖇️', '📏', '📐', '✂️', '🗃️', '🗂️', '📁', '📂', '🗄️',
      '🔒', '🔓', '🔑', '🗝️', '🧰', '🪛', '🔧', '🔨', '⛏️', '🪚',
      '🧲', '🧪', '🧫', '🧬', '🔬', '🔭', '📡', '💊', '💉', '🩺',
    ],
    '🐱': [ // Animals
      '🐱', '🐶', '🐯', '🦁', '🐻', '🐼', '🐨', '🐵', '🐒', '🦍',
      '🦧', '🐹', '🐭', '🐰', '🦊', '🐺', '🐗', '🐴', '🦄', '🐮',
      '🐷', '🐸', '🐲', '🐉', '🦎', '🐊', '🐢', '🐍', '🐙', '🦑',
      '🦐', '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈',
      '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺',
      '🦢', '🦩', '🕊️', '🦜', '🦚', '🦤', '🪶', '🐓', '🦃', '🦨',
      '🦝', '🦡', '🦫', '🦦', '🦥', '🐁', '🐀', '🐿️', '🦔', '🐾',
      '🐛', '🦋', '🐌', '🐝', '🐜', '🪲', '🐞', '🦗', '🪳', '🕷️',
      '🦂', '🐚', '🪸', '🪼', '🐠', '🦭', '🦬', '🐃', '🐂', '🐄',
      '🐎', '🐖', '🐏', '🐑', '🐐', '🦌', '🐕', '🐩', '🦮', '🐕‍🦺',
      '🐈', '🐈‍⬛', '🪺', '🐊', '🐘', '🦏', '🦛', '🐫', '🐪', '🦒',
    ],
    '🏔️': [ // Nature & Weather
      '🏔️', '🌊', '🏖️', '🌅', '🌄', '🌆', '🌇', '🌃', '🌁', '🌉',
      '🌌', '🌠', '🎑', '🏞️', '🌋', '🏜️', '🏝️', '🌍', '🌎', '🌏',
      '🌺', '🌹', '🌷', '🌻', '🌼', '🌸', '💮', '🏵️', '🌾', '🪻',
      '🪷', '🪹', '🫧', '🍀', '🍁', '🍂', '🍃', '🌿', '☘️', '🪴',
      '🌱', '🪵', '🪨', '🌵', '🌴', '🌳', '🌲', '🎋', '🎍', '🎄',
      '💐', '🌰', '🍄', '🐚', '🪸', '🪨', '🌙', '🌛', '🌜', '🌚',
      '🌝', '🌞', '☀️', '⭐', '🌟', '✨', '🌤️', '⛅', '🌥️', '☁️',
      '🌦️', '🌧️', '⛈️', '🌩️', '🌨️', '❄️', '☃️', '⛄', '🌬️', '💨',
      '🌪️', '🌫️', '🌈', '☔', '💧', '💦', '🫧', '🌊', '⚡', '🔥',
    ],
  };

  void _showEmojiPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.nearBlack : AppColorsLight.pureWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EmojiPickerSheet(
        onEmojiSelected: (emoji) {
          Navigator.pop(ctx);
          _addEmojiSticker(emoji);
        },
        categories: _emojiCategories,
      ),
    );
  }

  void _addEmojiSticker(String emoji) {
    setState(() {
      _emojiStickers.add(_EmojiSticker(
        emoji: emoji,
        position: Offset(
          100 + Random().nextDouble() * 100,
          200 + Random().nextDouble() * 100,
        ),
      ));
      _activeEmojiIndex = _emojiStickers.length - 1;
    });
  }

  void _removeEmojiSticker(int index) {
    setState(() {
      _emojiStickers.removeAt(index);
      _activeEmojiIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: bgColor,
      appBar: PillAppBar(
        title: 'Edit ${widget.viewTypeName} Photo',
        actions: [
          PillAppBarAction(icon: Icons.crop, onTap: _cropImage),
          PillAppBarAction(icon: Icons.branding_watermark, onTap: () => setState(() => _showLogo = !_showLogo)),
          PillAppBarAction(icon: Icons.emoji_emotions_outlined, onTap: _showEmojiPicker),
          PillAppBarAction(icon: Icons.save_outlined, visible: !_isSaving, onTap: _saveAndReturn),
        ],
      ),
      body: Stack(
        children: [
          // Full-bleed image area — never changes size
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (_activeEmojiIndex != null) {
                  setState(() => _activeEmojiIndex = null);
                }
              },
              child: Container(
                color: bgColor,
                child: Center(
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
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
                                  final delta = details.focalPoint - _lastFocalPoint;
                                  _logoPosition = Offset(
                                    _logoPosition.dx + delta.dx,
                                    _logoPosition.dy + delta.dy,
                                  );
                                  _lastFocalPoint = details.focalPoint;
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

                        // Emoji stickers
                        for (int i = 0; i < _emojiStickers.length; i++)
                          _buildEmojiOverlay(i),

                        // Pose guide hint
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IgnorePointer(
                            ignoring: !_showPoseHint,
                            child: AnimatedOpacity(
                              opacity: _showPoseHint ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 600),
                              child: GestureDetector(
                                onTap: () => setState(() => _showPoseHint = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.cyan.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_poseIcon,
                                          size: 16, color: AppColors.cyan),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.viewTypeName} pose',
                                        style: TextStyle(
                                          color:
                                              Colors.white.withValues(alpha: 0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom toolbar — overlays the image, never pushes it
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassSurface
                        : AppColorsLight.glassSurface.withValues(alpha: 0.85),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo size slider (compact)
                        if (_showLogo)
                          Row(
                            children: [
                              Icon(Icons.photo_size_select_small, size: 18, color: secondaryColor),
                              Expanded(
                                child: Slider(
                                  value: _logoScale,
                                  min: 0.5,
                                  max: 3.0,
                                  inactiveColor: borderColor,
                                  onChanged: (value) => setState(() => _logoScale = value),
                                ),
                              ),
                              Icon(Icons.photo_size_select_large, size: 18, color: secondaryColor),
                            ],
                          ),

                        // Active emoji controls (compact)
                        if (_activeEmojiIndex != null && _activeEmojiIndex! < _emojiStickers.length) ...[
                          Row(
                            children: [
                              Text(_emojiStickers[_activeEmojiIndex!].emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text('Size', style: TextStyle(color: secondaryColor, fontSize: 11)),
                              Expanded(
                                child: Slider(
                                  value: _emojiStickers[_activeEmojiIndex!].scale,
                                  min: 0.3,
                                  max: 5.0,
                                  inactiveColor: borderColor,
                                  onChanged: (value) => setState(() => _emojiStickers[_activeEmojiIndex!].scale = value),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removeEmojiSticker(_activeEmojiIndex!),
                                child: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 4),

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
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmojiOverlay(int index) {
    final sticker = _emojiStickers[index];
    final isActive = _activeEmojiIndex == index;
    // Compute the rendered size accounting for scale
    const baseSize = 56.0; // emoji font size 48 + padding 8
    final scaledSize = baseSize * sticker.scale;

    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onTap: () => setState(() => _activeEmojiIndex = isActive ? null : index),
        onScaleStart: (details) {
          _emojiLastFocalPoint = details.focalPoint;
          _emojiLastScale = sticker.scale;
          _emojiLastRotation = sticker.rotation;
          setState(() => _activeEmojiIndex = index);
        },
        onScaleUpdate: (details) {
          setState(() {
            // Drag
            final delta = details.focalPoint - _emojiLastFocalPoint;
            sticker.position = Offset(
              sticker.position.dx + delta.dx,
              sticker.position.dy + delta.dy,
            );
            _emojiLastFocalPoint = details.focalPoint;

            // Pinch to scale
            if (details.scale != 1.0) {
              sticker.scale = (_emojiLastScale * details.scale).clamp(0.3, 5.0);
            }

            // Rotate
            if (details.rotation != 0.0) {
              sticker.rotation = _emojiLastRotation + details.rotation;
            }
          });
        },
        child: SizedBox(
          width: scaledSize + 24, // extra space for handles
          height: scaledSize + 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The emoji itself centered
              Center(
                child: Transform.rotate(
                  angle: sticker.rotation,
                  child: Transform.scale(
                    scale: sticker.scale,
                    child: Container(
                      decoration: isActive
                          ? BoxDecoration(
                              border: Border.all(
                                color: AppColors.cyan.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        sticker.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ),
              ),
              // Delete button — top left
              if (isActive)
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => _removeEmojiSticker(index),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              // Resize handle — bottom right corner
              if (isActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanStart: (_) {
                      _emojiLastScale = sticker.scale;
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        // Diagonal drag distance → scale change
                        final delta = (details.delta.dx + details.delta.dy) * 0.01;
                        sticker.scale = (_emojiLastScale + delta).clamp(0.3, 5.0);
                        _emojiLastScale = sticker.scale;
                      });
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              // Rotate handle — top right corner
              if (isActive)
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onPanStart: (_) {
                      _emojiLastRotation = sticker.rotation;
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        sticker.rotation = _emojiLastRotation + details.delta.dx * 0.02;
                        _emojiLastRotation = sticker.rotation;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.rotate_right, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.accent;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
                    ? accentColor.withValues(alpha: 0.2)
                    : elevatedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? accentColor : borderColor,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? accentColor : secondaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? accentColor : secondaryColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitWizLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App icon from asset
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cyan, AppColors.purple],
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Logo text with shadow
        Text(
          'FitWiz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Scrollable emoji picker with category tabs and history
class _EmojiPickerSheet extends StatefulWidget {
  final void Function(String emoji) onEmojiSelected;
  final Map<String, List<String>> categories;

  const _EmojiPickerSheet({
    required this.onEmojiSelected,
    required this.categories,
  });

  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet> {
  // -1 = History tab, 0+ = emoji categories
  int _selectedCategory = -1;
  List<String> _history = [];
  static const _historyKey = 'sticker_history';
  static const _maxHistory = 30;

  static const _categoryLabels = [
    'Fitness', 'Fire', 'Faces', 'Food', 'Hearts', 'Objects', 'Animals', 'Nature',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_historyKey) ?? [];
    setState(() {
      _history = stored;
      // Default to first category if no history
      if (_history.isEmpty) _selectedCategory = 0;
    });
  }

  Future<void> _saveToHistory(String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(emoji); // Remove duplicate
    _history.insert(0, emoji); // Add to front
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }
    await prefs.setStringList(_historyKey, _history);
  }

  void _onEmojiTapped(String emoji) {
    _saveToHistory(emoji);
    widget.onEmojiSelected(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.accent;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final keys = widget.categories.keys.toList();
    final List<String> currentEmojis;
    if (_selectedCategory == -1) {
      currentEmojis = _history;
    } else {
      currentEmojis = widget.categories[keys[_selectedCategory]]!;
    }

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add Sticker',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Category tabs (History + emoji categories)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: keys.length + 1, // +1 for History
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final isHistory = index == 0;
                  final categoryIndex = isHistory ? -1 : index - 1;
                  final isSelected = _selectedCategory == categoryIndex;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = categoryIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.2)
                            : elevatedColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? accentColor : borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHistory) ...[
                            Icon(
                              Icons.history,
                              size: 18,
                              color: isSelected ? accentColor : secondaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'History',
                              style: TextStyle(
                                color: isSelected ? accentColor : secondaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            Text(keys[categoryIndex], style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              _categoryLabels[categoryIndex],
                              style: TextStyle(
                                color: isSelected ? accentColor : secondaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Emoji grid — scrollable
            Expanded(
              child: currentEmojis.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 40, color: mutedColor),
                          const SizedBox(height: 8),
                          Text(
                            'No stickers used yet',
                            style: TextStyle(color: mutedColor, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your recently used stickers will appear here',
                            style: TextStyle(color: mutedColor.withValues(alpha: 0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: currentEmojis.length,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => _onEmojiTapped(currentEmojis[index]),
                        child: Center(
                          child: Text(
                            currentEmojis[index],
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
