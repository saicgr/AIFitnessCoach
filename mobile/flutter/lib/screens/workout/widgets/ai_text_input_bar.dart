/// AI Text Input Bar Widget
///
/// A collapsible input bar for adding exercises via natural language.
/// Supports text, image, and voice input.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/parsed_exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';

import '../../../l10n/generated/app_localizations.dart';
/// AI Text Input Bar for adding exercises via natural language
///
/// Supports DUAL modes:
/// 1. Set logging: "135*8, 145*6" -> logs sets for current exercise
/// 2. Add exercise: "3x10 deadlift at 135" -> adds new exercise
class AiTextInputBar extends ConsumerStatefulWidget {
  /// Workout ID to add exercises to
  final String workoutId;

  /// Whether user prefers kg or lbs
  final bool useKg;

  /// Current exercise name (for set logging context)
  final String? currentExerciseName;

  /// Current exercise index in workout
  final int? currentExerciseIndex;

  /// Last logged set weight (for smart shortcuts like +10, same, drop)
  final double? lastSetWeight;

  /// Last logged set reps
  final int? lastSetReps;

  /// Callback when V2 parsing completes (sets to log AND exercises to add)
  final void Function(ParseWorkoutInputV2Response result)? onV2Parsed;

  /// Legacy callback when exercises are successfully parsed
  final void Function(List<ParsedExercise> exercises) onExercisesParsed;

  /// Optional callback when dismissed
  final VoidCallback? onDismiss;

  /// When true, render as a 36×36 floating "✦" pill instead of the full
  /// inline bar. Tap expands. Used by Advanced mode to reclaim ~50px of
  /// table room. Easy mode and tablet/landscape pass false to keep the
  /// expanded bar (discoverability).
  final bool compact;

  const AiTextInputBar({
    super.key,
    required this.workoutId,
    this.useKg = false,
    this.currentExerciseName,
    this.currentExerciseIndex,
    this.lastSetWeight,
    this.lastSetReps,
    this.onV2Parsed,
    required this.onExercisesParsed,
    this.onDismiss,
    this.compact = false,
  });

  @override
  ConsumerState<AiTextInputBar> createState() => _AiTextInputBarState();
}

class _AiTextInputBarState extends ConsumerState<AiTextInputBar>
    with SingleTickerProviderStateMixin {
  // State
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isListening = false;
  String? _errorMessage;

  /// User explicitly toggled expand/collapse this session — don't fight them
  /// when widget.compact flips back. Resets next workout (StatefulWidget
  /// disposes when leaving the screen).
  bool _userOverrodeCompact = false;
  bool _showedCompactTooltip = false;

  // Controllers
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _speechToText = SpeechToText();
  final _imagePicker = ImagePicker();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  bool _speechInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Speech init is deferred until the user taps the mic. Calling
    // _speechToText.initialize() is what triggers the OS microphone prompt,
    // and we don't want that dialog popping up on workout start.
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _ensureSpeechInitialized() async {
    if (_speechInitialized) return;
    try {
      await _speechToText.initialize();
    } catch (e) {
      debugPrint('Speech recognition not available: $e');
    }
    _speechInitialized = true;
  }

  void _expand({bool focusVoice = false}) {
    setState(() {
      _isExpanded = true;
      _userOverrodeCompact = true; // sticky until session end
    });
    _animationController.forward();
    _focusNode.requestFocus();
    HapticFeedback.lightImpact();
    if (focusVoice) {
      // Long-press on the compact pill jumps directly into voice input.
      // Tiny delay so the field has time to mount + claim focus first.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _toggleVoiceInput();
      });
    }
  }

  /// Compact 36px-tall pill shown in Advanced mode. Bottom-LEFT anchored
  /// inside its parent so it doesn't collide with Sergeant Max's avatar
  /// (bottom-right). The parent passes `compact: true` based on
  /// `workoutUiModeProvider.mode == WorkoutUiMode.advanced`.
  Widget _buildCompactPill(bool isDark, Color accentColor) {
    final pillBg = isDark ? AppColors.elevated : Colors.white;
    final pillBorder = isDark ? AppColors.cardBorder : Colors.grey.shade300;

    // First-time discoverability tooltip (auto-dismiss 3s).
    if (!_showedCompactTooltip) {
      _showedCompactTooltip = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).aiTextInputTapToAddExercises),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Semantics(
          label: AppLocalizations.of(context).aiTextInputOpenAiExerciseInput,
          button: true,
          child: GestureDetector(
            onTap: _expand,
            onLongPress: () => _expand(focusVoice: true),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: pillBg,
                shape: BoxShape.circle,
                border: Border.all(color: pillBorder),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: accentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExamplesDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: isDark ? AppColors.orange : AppColors.orange,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).aiTextInputAiExerciseInput,
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Set logging section
              Text(
                AppLocalizations.of(context).aiTextInputLogSetsForCurrent,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildExampleRow('"135*8" → 135 lbs × 8 reps', isDark),
              _buildExampleRow('"135*8, 145*6, 155*5"', isDark),
              _buildExampleRow('"+10" → add 10 to last weight', isDark),
              _buildExampleRow('"same" → repeat last set', isDark),
              const SizedBox(height: 16),

              // Add exercises section
              Text(
                AppLocalizations.of(context).aiTextInputAddNewExercises,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildExampleRow('"3x10 deadlift at 135"', isDark),
              _buildExampleRow('"bench 5x5 225lbs"', isDark),
              _buildExampleRow('"pull-ups 3x12, dips 3x10"', isDark),
              const SizedBox(height: 16),

              // Image/voice section
              Row(
                children: [
                  Icon(Icons.camera_alt, size: 16, color: isDark ? AppColors.textMuted : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).aiTextInputPhotoOfWorkoutLog,
                      style: TextStyle(
                        color: isDark ? AppColors.textMuted : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.mic, size: 16, color: isDark ? AppColors.textMuted : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).aiTextInputSpeakNaturallyDid135,
                      style: TextStyle(
                        color: isDark ? AppColors.textMuted : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).weightIncrementsGotIt,
              style: TextStyle(
                color: isDark ? AppColors.orange : AppColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleRow(String example, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? AppColors.orange : AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              example,
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : Colors.black87,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _collapse() {
    _focusNode.unfocus();
    _animationController.reverse().then((_) {
      setState(() {
        _isExpanded = false;
        _errorMessage = null;
        // In compact mode, an explicit collapse means "go back to the pill".
        // Note: typed-but-unsent text is preserved on the controller, which
        // is intentional — re-expanding restores the draft.
        if (widget.compact) _userOverrodeCompact = false;
      });
    });
  }

  Future<void> _parseInput() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter weight×reps or exercise');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) throw Exception('User not logged in');

      final repo = ref.read(workoutRepositoryProvider);

      // Use V2 API if callback is provided (supports set logging + exercises)
      if (widget.onV2Parsed != null) {
        final result = await repo.parseWorkoutInputV2(
          userId: userId,
          workoutId: widget.workoutId,
          currentExerciseName: widget.currentExerciseName,
          currentExerciseIndex: widget.currentExerciseIndex,
          lastSetWeight: widget.lastSetWeight,
          lastSetReps: widget.lastSetReps,
          inputText: text,
          useKg: widget.useKg,
        );

        if (result != null && result.hasData) {
          _textController.clear();
          _collapse();
          widget.onV2Parsed!(result);
        } else {
          setState(() {
            _errorMessage = result?.warnings.isNotEmpty == true
                ? result!.warnings.first
                : 'Could not parse input';
          });
        }
      } else {
        // Fallback to legacy V1 API
        final result = await repo.parseWorkoutInput(
          userId: userId,
          workoutId: widget.workoutId,
          inputText: text,
          useKg: widget.useKg,
        );

        if (result != null && result.exercises.isNotEmpty) {
          _textController.clear();
          _collapse();
          widget.onExercisesParsed(result.exercises);
        } else {
          setState(() {
            _errorMessage = result?.warnings.isNotEmpty == true
                ? result!.warnings.first
                : 'Could not parse any exercises';
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to parse: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        await _parseImage(File(image.path));
      }
    } catch (e) {
      setState(() => _errorMessage = 'Camera not available');
    }
  }

  Future<void> _openGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        await _parseImage(File(image.path));
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not access gallery');
    }
  }

  Future<void> _parseImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) throw Exception('User not logged in');

      final repo = ref.read(workoutRepositoryProvider);

      // Use V2 API if callback is provided
      if (widget.onV2Parsed != null) {
        final result = await repo.parseWorkoutInputV2(
          userId: userId,
          workoutId: widget.workoutId,
          currentExerciseName: widget.currentExerciseName,
          currentExerciseIndex: widget.currentExerciseIndex,
          lastSetWeight: widget.lastSetWeight,
          lastSetReps: widget.lastSetReps,
          imageBase64: base64Image,
          inputText: _textController.text.trim().isNotEmpty
              ? _textController.text.trim()
              : null,
          useKg: widget.useKg,
        );

        if (result != null && result.hasData) {
          _textController.clear();
          _collapse();
          widget.onV2Parsed!(result);
        } else {
          setState(() {
            _errorMessage = result?.warnings.isNotEmpty == true
                ? result!.warnings.first
                : 'Could not parse data from image';
          });
        }
      } else {
        // Fallback to legacy V1 API
        final result = await repo.parseWorkoutInput(
          userId: userId,
          workoutId: widget.workoutId,
          imageBase64: base64Image,
          inputText: _textController.text.trim().isNotEmpty
              ? _textController.text.trim()
              : null,
          useKg: widget.useKg,
        );

        if (result != null && result.exercises.isNotEmpty) {
          _textController.clear();
          _collapse();
          widget.onExercisesParsed(result.exercises);
        } else {
          setState(() {
            _errorMessage = result?.warnings.isNotEmpty == true
                ? result!.warnings.first
                : 'Could not parse any exercises from image';
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to parse image');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleVoiceInput() async {
    HapticFeedback.mediumImpact();

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
      // Parse the collected text
      if (_textController.text.trim().isNotEmpty) {
        await _parseInput();
      }
    } else {
      // First-tap initialization — this triggers the OS microphone permission
      // prompt the first time. Deferred from initState so the prompt only
      // appears when the user has explicitly chosen to use voice input.
      await _ensureSpeechInitialized();
      if (!_speechToText.isAvailable) {
        setState(() => _errorMessage = 'Voice input not available');
        return;
      }

      setState(() => _isListening = true);

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    // Compact mode = Advanced E/A toggle wants a small ✦ pill instead of the
    // full bar. The user can still expand by tapping, and once they do we
    // honor that for the rest of the session via _userOverrodeCompact.
    final shouldRenderCompactPill =
        widget.compact && !_isExpanded && !_userOverrodeCompact;

    if (shouldRenderCompactPill) {
      return _buildCompactPill(isDark, accentColor);
    }

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isExpanded
                  ? accentColor.withOpacity(0.5)
                  : (isDark ? AppColors.cardBorder : Colors.grey.shade300),
              width: _isExpanded ? 1.5 : 1,
            ),
            boxShadow: _isExpanded
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Collapsed or header
              _buildHeader(isDark, accentColor),

              // Expanded content
              if (_isExpanded) ...[
                _buildExpandedContent(isDark, accentColor),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color accentColor) {
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade600;

    if (!_isExpanded) {
      // Collapsed state - tap to expand
      return GestureDetector(
        onTap: _expand,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).aiTextInputAddExercisesWithAi,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
              // Info button
              GestureDetector(
                onTap: () => _showExamplesDialog(context, isDark),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: textMuted,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more,
                size: 20,
                color: textMuted,
              ),
            ],
          ),
        ),
      );
    }

    // Expanded header with close button
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 18,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).aiTextInputLogSetsAddExercises,
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: isDark ? AppColors.textMuted : Colors.grey.shade600,
            ),
            onPressed: _collapse,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(bool isDark, Color accentColor) {
    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade600;
    final inputBg = isDark ? AppColors.nearBlack : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text input - larger for multiple workout entries
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).aiTextInputLogSets1358,
                hintStyle: TextStyle(
                  color: textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: null, // Grows indefinitely based on content
              minLines: 4,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.red,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons row - compact buttons
          Row(
            children: [
              // Camera
              _ActionButton(
                icon: Icons.camera_alt_outlined,
                onTap: _isLoading ? null : _openCamera,
                isDark: isDark,
              ),
              const SizedBox(width: 6),

              // Gallery
              _ActionButton(
                icon: Icons.photo_library_outlined,
                onTap: _isLoading ? null : _openGallery,
                isDark: isDark,
              ),
              const SizedBox(width: 6),

              // Voice
              _ActionButton(
                icon: _isListening ? Icons.mic : Icons.mic_none,
                onTap: _isLoading ? null : _toggleVoiceInput,
                isDark: isDark,
                isActive: _isListening,
                activeColor: AppColors.red,
              ),

              const Spacer(),

              // Send button - smaller
              GestureDetector(
                onTap: _isLoading ? null : _parseInput,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? accentColor.withOpacity(0.5)
                        : accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward,
                          color: isDark ? Colors.black : Colors.white,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact action button for camera/gallery/mic
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isActive;
  final Color? activeColor;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? (activeColor ?? AppColors.orange).withOpacity(0.2)
        : (isDark ? AppColors.nearBlack : Colors.grey.shade200);
    final iconColor = isActive
        ? (activeColor ?? AppColors.orange)
        : (isDark ? AppColors.textMuted : Colors.grey.shade600);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 16,
        ),
      ),
    );
  }
}
