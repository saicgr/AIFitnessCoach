import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

/// Enhanced Exercise Notes Sheet with audio, photo, and expandable text input
class EnhancedNotesSheet extends StatefulWidget {
  final String? initialNotes;
  final String? initialAudioPath;
  final List<String>? initialPhotoPaths;
  final Function(String notes, String? audioPath, List<String> photoPaths) onSave;

  const EnhancedNotesSheet({
    super.key,
    this.initialNotes,
    this.initialAudioPath,
    this.initialPhotoPaths,
    required this.onSave,
  });

  @override
  State<EnhancedNotesSheet> createState() => _EnhancedNotesSheetState();
}

class _EnhancedNotesSheetState extends State<EnhancedNotesSheet> {
  late TextEditingController _notesController;
  late FocusNode _notesFocusNode;

  // Expansion state
  bool _isExpanded = false;

  // Audio recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  Timer? _recordingTimer;

  // Photo state
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _photoPaths = [];

  // Voice-to-text state
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _notesFocusNode = FocusNode();
    _audioPath = widget.initialAudioPath;
    _photoPaths = List.from(widget.initialPhotoPaths ?? []);

    // Listen to audio player state
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _playbackPosition = position);
      }
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _audioDuration = duration);
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
    });

    // Initialize speech-to-text
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    if (_isListening) _speechToText.stop();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Audio Recording
  // ─────────────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check permission
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }

      // Get temp directory for audio file
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/exercise_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: audioPath,
      );

      HapticService.medium();
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start timer to track duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingDuration += const Duration(seconds: 1));
        }
      });
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();

      HapticService.success();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      setState(() => _isPlaying = true);
    }
    HapticService.light();
  }

  void _deleteAudio() {
    HapticService.medium();
    setState(() {
      _audioPath = null;
      _playbackPosition = Duration.zero;
      _audioDuration = Duration.zero;
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Photo Input
  // ─────────────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        HapticService.success();
        setState(() => _photoPaths.add(image.path));
      }
    } catch (e) {
      debugPrint('❌ Error picking image from camera: $e');
    }
  }

  Future<void> _openGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        HapticService.success();
        setState(() => _photoPaths.addAll(images.map((x) => x.path)));
      }
    } catch (e) {
      debugPrint('❌ Error picking images from gallery: $e');
    }
  }

  void _removePhoto(int index) {
    HapticService.light();
    setState(() => _photoPaths.removeAt(index));
  }

  // ─────────────────────────────────────────────────────────────────
  // Voice-to-Text
  // ─────────────────────────────────────────────────────────────────

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      HapticService.light();
      setState(() => _isListening = false);
    } else {
      HapticService.medium();
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            // Append transcribed text to notes
            final currentText = _notesController.text;
            final newText = result.recognizedWords;
            _notesController.text = currentText.isEmpty
                ? newText
                : '$currentText $newText';
            _notesController.selection = TextSelection.fromPosition(
              TextPosition(offset: _notesController.text.length),
            );
            setState(() => _isListening = false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: false,
          listenMode: stt.ListenMode.confirmation,
        ),
        localeId: 'en_US',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Save and close
  // ─────────────────────────────────────────────────────────────────

  void _save() {
    widget.onSave(_notesController.text, _audioPath, _photoPaths);
    Navigator.pop(context);
  }

  // ─────────────────────────────────────────────────────────────────
  // Build UI
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = AppColors.purple;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with expand button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2_outlined, color: accentColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Exercise Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_notesController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              HapticService.light();
                              setState(() => _notesController.clear());
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            HapticService.light();
                            setState(() => _isExpanded = !_isExpanded);
                          },
                          child: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: textMuted,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input toolbar
                _buildInputToolbar(isDark, textMuted, accentColor),
                const SizedBox(height: 12),

                // Listening indicator (voice-to-text)
                if (_isListening) _buildListeningIndicator(),

                // Recording indicator
                if (_isRecording) _buildRecordingIndicator(),

                // Audio preview
                if (_audioPath != null && !_isRecording)
                  _buildAudioPreview(isDark, textColor, textMuted, accentColor),

                // Photo previews
                if (_photoPaths.isNotEmpty)
                  _buildPhotoPreview(isDark),

                // Expandable text area
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: TextField(
                    controller: _notesController,
                    focusNode: _notesFocusNode,
                    maxLines: _isExpanded ? 10 : 4,
                    minLines: _isExpanded ? 6 : 2,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add notes about form, cues, or modifications...',
                      hintStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: accentColor,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),

                // Done button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildInputToolbar(bool isDark, Color textMuted, Color accentColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Voice-to-text button (transcription)
          _buildToolbarButton(
            icon: _isListening ? Icons.hearing : Icons.keyboard_voice,
            label: _isListening ? 'Listening...' : 'Dictate',
            onTap: _toggleListening,
            isActive: _isListening,
            activeColor: AppColors.cyan,
            isDark: isDark,
            textMuted: textMuted,
            accentColor: accentColor,
          ),
          const SizedBox(width: 8),
          // Audio recording button (voice memo)
          _buildToolbarButton(
            icon: _isRecording ? Icons.stop : Icons.mic,
            label: _isRecording ? 'Stop' : 'Record',
            onTap: _toggleRecording,
            isActive: _isRecording,
            activeColor: AppColors.error,
            isDark: isDark,
            textMuted: textMuted,
            accentColor: accentColor,
          ),
          const SizedBox(width: 8),
          // Camera button
          _buildToolbarButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _openCamera,
            isDark: isDark,
            textMuted: textMuted,
            accentColor: accentColor,
          ),
          const SizedBox(width: 8),
          // Gallery button
          _buildToolbarButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: _openGallery,
            isDark: isDark,
            textMuted: textMuted,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
    required bool isDark,
    required Color textMuted,
    required Color accentColor,
  }) {
    final bgColor = isActive
        ? (activeColor ?? accentColor).withValues(alpha: 0.2)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05));
    final iconColor = isActive ? (activeColor ?? accentColor) : textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: activeColor ?? accentColor, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Pulsing cyan dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: value),
                  shape: BoxShape.circle,
                ),
              );
            },
            onEnd: () => setState(() {}),
          ),
          const SizedBox(width: 12),
          Text(
            'Listening... speak now',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.cyan,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleListening,
            child: Icon(
              Icons.close,
              color: AppColors.cyan,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Pulsing red dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: value),
                  shape: BoxShape.circle,
                ),
              );
            },
            onEnd: () => setState(() {}),
          ),
          const SizedBox(width: 12),
          Text(
            'Recording...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(bool isDark, Color textColor, Color textMuted, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Play/pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Progress indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Note',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _audioDuration.inMilliseconds > 0
                      ? _playbackPosition.inMilliseconds / _audioDuration.inMilliseconds
                      : 0,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDuration(_playbackPosition)} / ${_formatDuration(_audioDuration)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          GestureDetector(
            onTap: _deleteAudio,
            child: Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _photoPaths.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_photoPaths[index]),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removePhoto(index),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Show the enhanced notes sheet as a modal bottom sheet
void showEnhancedNotesSheet(
  BuildContext context, {
  String? initialNotes,
  String? initialAudioPath,
  List<String>? initialPhotoPaths,
  required Function(String notes, String? audioPath, List<String> photoPaths) onSave,
}) {
  showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      child: EnhancedNotesSheet(
        initialNotes: initialNotes,
        initialAudioPath: initialAudioPath,
        initialPhotoPaths: initialPhotoPaths,
        onSave: onSave,
      ),
    ),
  );
}
