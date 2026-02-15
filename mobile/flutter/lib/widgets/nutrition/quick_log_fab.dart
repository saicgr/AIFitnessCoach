import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../screens/nutrition/log_meal_sheet.dart';
import '../glass_sheet.dart';
import 'batch_portioning_sheet.dart';

/// Quick-Add FAB for nutrition logging
/// Expands to show: Camera, Barcode, Voice, Text options
/// One-tap access to any logging method
class QuickLogFAB extends StatefulWidget {
  final String userId;
  final VoidCallback? onLogComplete;

  const QuickLogFAB({
    super.key,
    required this.userId,
    this.onLogComplete,
  });

  @override
  State<QuickLogFAB> createState() => _QuickLogFABState();
}

class _QuickLogFABState extends State<QuickLogFAB>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  final SpeechToText _speechToText = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _isSpeechAvailable = await _speechToText.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticService.light();
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? AppColors.green : AppColorsLight.success;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Overlay to close on tap outside
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpanded,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black26),
            ),
          ),

        // Expanded options
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Voice option
            if (_isSpeechAvailable)
              _buildOption(
                index: 0,
                icon: _isListening ? Icons.mic : Icons.mic_none,
                label: _isListening ? 'Listening...' : 'Voice',
                color: Colors.purple,
                onTap: _startVoiceLogging,
              ),

            // Camera option
            _buildOption(
              index: 1,
              icon: Icons.camera_alt,
              label: 'Photo',
              color: Colors.blue,
              onTap: _openCameraLogging,
            ),

            // Barcode option
            _buildOption(
              index: 2,
              icon: Icons.qr_code_scanner,
              label: 'Scan',
              color: Colors.orange,
              onTap: _openBarcodeLogging,
            ),

            // Text option
            _buildOption(
              index: 3,
              icon: Icons.edit,
              label: 'Type',
              color: Colors.teal,
              onTap: _openTextLogging,
            ),

            // Batch Portioning option
            _buildOption(
              index: 4,
              icon: Icons.pie_chart,
              label: 'Batch',
              color: Colors.deepPurple,
              onTap: _openBatchPortioning,
            ),

            const SizedBox(height: 8),

            // Main FAB
            FloatingActionButton(
              onPressed: _toggleExpanded,
              backgroundColor: green,
              child: AnimatedRotation(
                turns: _isExpanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final delay = index * 0.1;
        final adjustedValue = (_expandAnimation.value - delay).clamp(0.0, 1.0 - delay) / (1.0 - delay);

        return Transform.translate(
          offset: Offset(0, 20 * (1 - adjustedValue)),
          child: Opacity(
            opacity: adjustedValue,
            child: child,
          ),
        );
      },
      child: _isExpanded
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: 'fab_$index',
                    onPressed: () {
                      HapticService.medium();
                      _toggleExpanded();
                      onTap();
                    },
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _startVoiceLogging() async {
    if (!_isSpeechAvailable) return;

    setState(() => _isListening = true);

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _openLogMealSheet(
            inputMethod: 'text',
            initialText: result.recognizedWords,
          );
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
    );

    // Timeout fallback
    await Future.delayed(const Duration(seconds: 30));
    if (_isListening && mounted) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _openCameraLogging() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null && mounted) {
      _openLogMealSheet(
        inputMethod: 'image',
        imageFile: File(pickedFile.path),
      );
    }
  }

  void _openBarcodeLogging() {
    _openLogMealSheet(inputMethod: 'barcode');
  }

  void _openTextLogging() {
    _openLogMealSheet(inputMethod: 'text');
  }

  void _openBatchPortioning() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: BatchPortioningSheet(
          isDark: isDark,
        ),
      ),
    ).then((result) {
      if (result != null) {
        widget.onLogComplete?.call();
      }
    });
  }

  void _openLogMealSheet({
    required String inputMethod,
    File? imageFile,
    String? initialText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: LogMealSheet(
          userId: widget.userId,
          isDark: isDark,
        ),
      ),
    ).then((_) {
      widget.onLogComplete?.call();
    });
  }
}

/// Compact version of the quick log FAB for smaller spaces
class QuickLogFABCompact extends StatelessWidget {
  final String userId;
  final VoidCallback? onLogComplete;

  const QuickLogFABCompact({
    super.key,
    required this.userId,
    this.onLogComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? AppColors.green : AppColorsLight.success;

    return FloatingActionButton(
      onPressed: () => _showQuickActions(context),
      backgroundColor: green,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showQuickActions(BuildContext context) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: _QuickActionsSheet(
          userId: userId,
          onLogComplete: onLogComplete,
        ),
      ),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  final String userId;
  final VoidCallback? onLogComplete;

  const _QuickActionsSheet({
    required this.userId,
    this.onLogComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Log Food',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Photo',
                  color: Colors.blue,
                  onTap: () => _openLogging(context, 'image'),
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.qr_code_scanner,
                  label: 'Scan',
                  color: Colors.orange,
                  onTap: () => _openLogging(context, 'barcode'),
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.edit,
                  label: 'Type',
                  color: Colors.teal,
                  onTap: () => _openLogging(context, 'text'),
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.mic,
                  label: 'Voice',
                  color: Colors.purple,
                  onTap: () => _openLogging(context, 'voice'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Batch Portioning Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickAction(
                  context,
                  icon: Icons.pie_chart,
                  label: 'Batch',
                  color: Colors.deepPurple,
                  onTap: () => _openLogging(context, 'batch'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimary
                  : AppColorsLight.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _openLogging(BuildContext context, String method) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (method == 'batch') {
      // Open batch portioning sheet
      showGlassSheet(
        context: context,
        builder: (_) => GlassSheet(
          showHandle: false,
          child: BatchPortioningSheet(
            isDark: isDark,
          ),
        ),
      ).then((result) {
        if (result != null) {
          onLogComplete?.call();
        }
      });
    } else if (method == 'image') {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null && context.mounted) {
        showGlassSheet(
          context: context,
          builder: (_) => GlassSheet(
            showHandle: false,
            child: LogMealSheet(
              userId: userId,
              isDark: isDark,
            ),
          ),
        ).then((_) => onLogComplete?.call());
      }
    } else {
      showGlassSheet(
        context: context,
        builder: (_) => GlassSheet(
          showHandle: false,
          child: LogMealSheet(
            userId: userId,
            isDark: isDark,
          ),
        ),
      ).then((_) => onLogComplete?.call());
    }
  }
}
