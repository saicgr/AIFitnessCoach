/// AI Gym-Equipment Importer — input sheet.
///
/// Lets a user populate a gym profile's equipment list from:
///   1. A PDF or DOCX file         (source=file)
///   2. One or more photos of the  (source=images)
///      gym / equipment wall
///   3. Pasted plain text          (source=text)
///   4. A URL (e.g. the gym's      (source=url)
///      "facilities" page)
///
/// Flow:
///   input tile tap → collect payload → presign + upload (if needed) →
///   POST /gym-profiles/{id}/import-equipment → poll /media-jobs/{id} every
///   2s up to 60s → push [ImportEquipmentResultSheet] with the extracted data.
///
/// See plan at /Users/saichetangrandhe/.claude/plans/pure-swinging-lighthouse.md
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/gym_profile_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../chat/widgets/media_picker_helper.dart';
import 'import_equipment_result_sheet.dart';

/// Maximum wall-clock time we will poll the job before surfacing a timeout.
const _kPollTimeout = Duration(seconds: 60);

/// Poll interval — matches the existing form-video analysis cadence.
const _kPollInterval = Duration(seconds: 2);

/// Maximum number of photos accepted in a single import.
const _kMaxPhotos = 10;

/// Bottom sheet that drives the equipment-import flow.
///
/// Pass in the target [gymProfileId]. The sheet does not create the profile
/// itself — callers must do so first (see `add_gym_profile_sheet.dart`).
class ImportEquipmentSheet extends ConsumerStatefulWidget {
  final String gymProfileId;

  /// Existing canonical equipment names already on the profile. The result
  /// sheet merges imported matches with this set so we never delete the
  /// user's prior selections.
  final List<String> existingEquipment;

  /// Existing equipment detail records (weight ranges etc.). Passed through
  /// unchanged when saving.
  final List<Map<String, dynamic>> existingEquipmentDetails;

  /// Current environment on the profile. Used as a fallback when the
  /// extractor can't infer one from the imported content.
  final String currentEnvironment;

  const ImportEquipmentSheet({
    super.key,
    required this.gymProfileId,
    required this.existingEquipment,
    required this.existingEquipmentDetails,
    required this.currentEnvironment,
  });

  @override
  ConsumerState<ImportEquipmentSheet> createState() =>
      _ImportEquipmentSheetState();
}

/// High-level UI state machine.
enum _Phase {
  /// Showing the 4 input-method tiles.
  chooseInput,

  /// Showing a text field (paste-text or paste-url).
  enterText,

  /// Uploading to S3 / waiting for the extractor.
  working,

  /// Polling finished (success or failure).
  done,
}

class _ImportEquipmentSheetState extends ConsumerState<ImportEquipmentSheet> {
  _Phase _phase = _Phase.chooseInput;

  /// Which input option the user picked. Drives the "enterText" variant.
  ImportSourceKind? _activeInput;

  String _working = '';
  String? _errorMessage;
  String? _jobId;

  final _textCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  Timer? _pollTimer;
  DateTime? _pollStart;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Input handlers
  // ---------------------------------------------------------------------------

  Future<void> _pickPdf() async {
    try {
      final picked = await MediaPickerHelper.pickDocument(context: context);
      if (picked == null) return; // user cancelled
      if (!mounted) return;

      setState(() {
        _phase = _Phase.working;
        _working = 'Uploading ${picked.file.path.split('/').last}...';
        _errorMessage = null;
      });

      final chatRepo = ref.read(chatRepositoryProvider);
      final gymRepo = ref.read(gymProfileRepositoryProvider);

      // Presign + upload
      final presign = await chatRepo.getPresignedUrl(
        filename: picked.file.path.split('/').last,
        contentType: picked.mimeType,
        mediaType: 'document',
        expectedSizeBytes: picked.sizeBytes,
      );
      final presignedUrl =
          (presign['presigned_url'] ?? presign['url']) as String;
      final s3Key = presign['s3_key'] as String;
      final fields = presign['presigned_fields'] as Map<String, dynamic>?;

      await chatRepo.uploadToS3(
        presignedUrl: presignedUrl,
        fields: fields,
        file: picked.file,
        contentType: picked.mimeType,
      );

      if (!mounted) return;
      setState(() => _working = 'Analyzing your gym equipment (Gemini is reading your PDF)...');

      final job = await gymRepo.importEquipment(
        gymProfileId: widget.gymProfileId,
        source: ImportSource.file(s3Key: s3Key, mimeType: picked.mimeType),
      );
      _beginPolling(job.jobId, sourceLabel: 'PDF');
    } on MediaValidationException catch (e) {
      _failWith(e.message);
    } catch (e, st) {
      debugPrint('❌ [ImportEquipment] PDF flow: $e\n$st');
      _failWith('Failed to upload PDF: $e');
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final mediaList =
          await MediaPickerHelper.pickMultipleImages(context: context);
      if (mediaList.isEmpty) return; // user cancelled / none selected
      if (!mounted) return;

      final selected = mediaList.take(_kMaxPhotos).toList();

      setState(() {
        _phase = _Phase.working;
        _working = 'Uploading ${selected.length} photo(s)...';
        _errorMessage = null;
      });

      final chatRepo = ref.read(chatRepositoryProvider);
      final gymRepo = ref.read(gymProfileRepositoryProvider);

      // Batch presign → parallel upload (mirrors chat flow).
      final fileSpecs = selected
          .map((m) => <String, dynamic>{
                'filename': m.file.path.split('/').last,
                'content_type': m.mimeType,
                'media_type': 'image',
                'expected_size_bytes': m.sizeBytes,
              })
          .toList();
      final presigned =
          await chatRepo.getBatchPresignedUrls(files: fileSpecs);

      await Future.wait(List.generate(selected.length, (i) async {
        final media = selected[i];
        final entry = presigned[i];
        await chatRepo.uploadToS3(
          presignedUrl: entry['presigned_url'] as String,
          fields: entry['presigned_fields'] as Map<String, dynamic>?,
          file: media.file,
          contentType: media.mimeType,
        );
      }));

      final s3Keys =
          presigned.map((e) => e['s3_key'] as String).toList(growable: false);

      if (!mounted) return;
      setState(() => _working = 'Analyzing your gym equipment (Gemini is reading your photos)...');

      final job = await gymRepo.importEquipment(
        gymProfileId: widget.gymProfileId,
        source: ImportSource.images(s3Keys: s3Keys),
      );
      _beginPolling(job.jobId, sourceLabel: 'photos');
    } on MediaValidationException catch (e) {
      _failWith(e.message);
    } catch (e, st) {
      debugPrint('❌ [ImportEquipment] Photos flow: $e\n$st');
      _failWith('Failed to upload photos: $e');
    }
  }

  Future<void> _submitText() async {
    final raw = _textCtrl.text.trim();
    if (raw.length < 4) {
      _failWith('Please paste at least a few words of equipment text.');
      return;
    }
    setState(() {
      _phase = _Phase.working;
      _working = 'Analyzing your gym equipment (Gemini is reading your text)...';
      _errorMessage = null;
    });
    try {
      final gymRepo = ref.read(gymProfileRepositoryProvider);
      final job = await gymRepo.importEquipment(
        gymProfileId: widget.gymProfileId,
        source: ImportSource.text(rawText: raw),
      );
      _beginPolling(job.jobId, sourceLabel: 'text');
    } catch (e, st) {
      debugPrint('❌ [ImportEquipment] Text flow: $e\n$st');
      _failWith('Failed to submit text: $e');
    }
  }

  Future<void> _submitUrl() async {
    final raw = _urlCtrl.text.trim();
    // Basic validation — backend does the real thing. We're just preventing
    // obvious garbage from hitting the network.
    final valid = raw.startsWith('http://') || raw.startsWith('https://');
    if (!valid) {
      _failWith('Please enter a valid URL starting with http:// or https://');
      return;
    }
    setState(() {
      _phase = _Phase.working;
      _working = 'Analyzing your gym equipment (Gemini is reading the page)...';
      _errorMessage = null;
    });
    try {
      final gymRepo = ref.read(gymProfileRepositoryProvider);
      final job = await gymRepo.importEquipment(
        gymProfileId: widget.gymProfileId,
        source: ImportSource.url(url: raw),
      );
      _beginPolling(job.jobId, sourceLabel: 'URL');
    } catch (e, st) {
      debugPrint('❌ [ImportEquipment] URL flow: $e\n$st');
      _failWith('Failed to submit URL: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Polling
  // ---------------------------------------------------------------------------

  void _beginPolling(String jobId, {required String sourceLabel}) {
    if (!mounted) return;
    _jobId = jobId;
    _pollStart = DateTime.now();
    setState(() {
      _phase = _Phase.working;
      _working = 'Analyzing your gym (Gemini is reading your $sourceLabel)...';
    });
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _pollOnce());
    // Also fire immediately.
    _pollOnce();
  }

  Future<void> _pollOnce() async {
    if (!mounted || _jobId == null) return;
    try {
      final status = await ref
          .read(gymProfileRepositoryProvider)
          .pollMediaJob(_jobId!);

      if (!mounted) return;

      if (status.isSuccess && status.equipmentResult != null) {
        _pollTimer?.cancel();
        setState(() => _phase = _Phase.done);
        _openResultSheet(status.equipmentResult!);
        return;
      }

      if (status.status == 'failed') {
        _pollTimer?.cancel();
        _failWith(status.errorMessage ??
            'Equipment extraction failed on the server.');
        return;
      }

      // Timeout guard — 60s is plenty for 1 PDF or 10 photos.
      if (_pollStart != null &&
          DateTime.now().difference(_pollStart!) > _kPollTimeout) {
        _pollTimer?.cancel();
        _failWith('Import is taking longer than expected. Please try again.');
        return;
      }
    } catch (e, st) {
      debugPrint('❌ [ImportEquipment] Poll error: $e\n$st');
      // Transient network errors shouldn't kill the poll loop; the timeout
      // will fire eventually. Only fail fast on permanent errors.
      // Keep polling.
    }
  }

  void _failWith(String message) {
    _pollTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.done;
      _errorMessage = message;
    });
  }

  void _reset() {
    _pollTimer?.cancel();
    setState(() {
      _phase = _Phase.chooseInput;
      _activeInput = null;
      _working = '';
      _errorMessage = null;
      _jobId = null;
      _pollStart = null;
    });
  }

  void _openResultSheet(ExtractedEquipmentResult result) {
    if (!mounted) return;
    // Pop the import sheet and open the result sheet — the result sheet is
    // its own modal so the user can cancel out of review without losing the
    // original "Add Gym Profile" sheet underneath.
    Navigator.of(context).pop();
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: ImportEquipmentResultSheet(
          gymProfileId: widget.gymProfileId,
          existingEquipment: widget.existingEquipment,
          existingEquipmentDetails: widget.existingEquipmentDetails,
          currentEnvironment: widget.currentEnvironment,
          result: result,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                if (_phase != _Phase.chooseInput && _phase != _Phase.working)
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                    onPressed: _reset,
                  ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_awesome_rounded,
                      color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Equipment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Let AI read your gym\'s equipment list',
                        style:
                            TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(isDark, textPrimary, textSecondary, accent)),
        ],
      ),
    );
  }

  Widget _buildBody(
      bool isDark, Color textPrimary, Color textSecondary, Color accent) {
    switch (_phase) {
      case _Phase.chooseInput:
        return _buildChooser(isDark, textPrimary, textSecondary, accent);
      case _Phase.enterText:
        return _buildTextEntry(isDark, textPrimary, textSecondary, accent);
      case _Phase.working:
        return _buildWorking(isDark, textPrimary, textSecondary, accent);
      case _Phase.done:
        return _buildError(isDark, textPrimary, textSecondary, accent);
    }
  }

  // --- input chooser ---------------------------------------------------------

  Widget _buildChooser(
      bool isDark, Color textPrimary, Color textSecondary, Color accent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InputTile(
          icon: Icons.picture_as_pdf_rounded,
          tint: const Color(0xFFE11D48),
          label: 'Upload PDF or Word',
          description: 'Your gym\'s equipment list or facility brochure',
          onTap: _pickPdf,
        ),
        const SizedBox(height: 12),
        _InputTile(
          icon: Icons.photo_library_rounded,
          tint: const Color(0xFF0EA5E9),
          label: 'Take photos of your gym',
          description: 'Up to $_kMaxPhotos photos — equipment walls, racks, machine tags',
          onTap: _pickPhotos,
        ),
        const SizedBox(height: 12),
        _InputTile(
          icon: Icons.text_fields_rounded,
          tint: const Color(0xFF22C55E),
          label: 'Paste text',
          description: 'Copy a list from a website, email, or doc',
          onTap: () {
            setState(() {
              _activeInput = ImportSourceKind.text;
              _phase = _Phase.enterText;
              _errorMessage = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _InputTile(
          icon: Icons.link_rounded,
          tint: const Color(0xFFF59E0B),
          label: 'Paste a URL',
          description: 'Link to your gym\'s equipment / facilities page',
          onTap: () {
            setState(() {
              _activeInput = ImportSourceKind.url;
              _phase = _Phase.enterText;
              _errorMessage = null;
            });
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Everything imported goes to a review screen — we never overwrite your equipment without your confirmation.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- text/url entry --------------------------------------------------------

  Widget _buildTextEntry(
      bool isDark, Color textPrimary, Color textSecondary, Color accent) {
    final isUrl = _activeInput == ImportSourceKind.url;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUrl ? 'Paste the URL' : 'Paste equipment text',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isUrl
                ? 'Any public webpage listing gym equipment.'
                : 'Copy/paste a list from anywhere — we will extract equipment names.',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 16),
          if (isUrl)
            TextField(
              controller: _urlCtrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: TextStyle(color: textPrimary),
              decoration: _inputDecoration(
                isDark: isDark,
                hint: 'https://yourgym.com/equipment',
                icon: Icons.link_rounded,
                textSecondary: textSecondary,
                accent: accent,
              ),
            )
          else
            TextField(
              controller: _textCtrl,
              autofocus: true,
              maxLines: 8,
              minLines: 6,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: _inputDecoration(
                isDark: isDark,
                hint:
                    'e.g.\nDumbbells 5-100 lb\n2x Squat racks\nLeg press (plate-loaded)\nTreadmills x4\nCable station...',
                icon: Icons.text_fields_rounded,
                textSecondary: textSecondary,
                accent: accent,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isUrl ? _submitUrl : _submitText,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Analyze',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String hint,
    required IconData icon,
    required Color textSecondary,
    required Color accent,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: textSecondary),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 2),
      ),
    );
  }

  // --- working ---------------------------------------------------------------

  Widget _buildWorking(
      bool isDark, Color textPrimary, Color textSecondary, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _working.isNotEmpty ? _working : 'Working...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This usually takes 10–30 seconds.',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // --- error / done ----------------------------------------------------------

  Widget _buildError(
      bool isDark, Color textPrimary, Color textSecondary, Color accent) {
    final msg = _errorMessage ?? 'Something went wrong.';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Import failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(color: textSecondary)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Visual input tile — icon, colored background, label, description, chevron.
class _InputTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _InputTile({
    required this.icon,
    required this.tint,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tint.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary),
          ],
        ),
      ),
    );
  }
}

