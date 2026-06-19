import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/user_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/repositories/share_ai_repository.dart';
import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'card_editor_controller.dart';

/// Workstream F AI affordances for the card editor — opened from the editor's
/// top-bar "AI" button. Two cost-gated, explicit-tap features:
///
///  - **F1 AI restyle** — turns the chosen photo into a preset style (figurine
///    / anime / comic / trading-card) via `POST /share/ai-restyle`. The result
///    becomes the card background and a visible AI-disclosure badge is dropped
///    on the canvas (transparency requirement). Daily quota shown; cap-reached
///    and kill-switch-off are handled gracefully.
///  - **F2 AI insight line** — a one-liner about the share's data, tone-toggled
///    supportive ↔ savage, dropped as a text element. Falls back silently to
///    the deterministic server line (never blocks, never blank).
///
/// This is a [ConsumerWidget] hosted inside a modal sheet so the plain
/// [StatefulWidget] editor can stay Riverpod-free. All network calls fire only
/// on an explicit user tap (cost discipline).
class AiShareSheet extends ConsumerStatefulWidget {
  final CardEditorController controller;
  final Shareable data;

  /// The currently-chosen photo for restyle. Either a local file path (camera
  /// roll / capture) or an http(s) S3 URL (logged food photo). Null disables
  /// F1 with an explanatory note.
  final String? photoPathOrUrl;

  const AiShareSheet({
    super.key,
    required this.controller,
    required this.data,
    required this.photoPathOrUrl,
  });

  /// Opens the AI sheet. Returns nothing — it mutates [controller] in place.
  static Future<void> show(
    BuildContext context, {
    required CardEditorController controller,
    required Shareable data,
    required String? photoPathOrUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiShareSheet(
        controller: controller,
        data: data,
        photoPathOrUrl: photoPathOrUrl,
      ),
    );
  }

  @override
  ConsumerState<AiShareSheet> createState() => _AiShareSheetState();
}

class _AiShareSheetState extends ConsumerState<AiShareSheet> {
  RestyleQuota? _quota;
  bool _loadingQuota = true;
  bool _restyling = false;
  bool _fetchingLine = false;
  String _tone = 'supportive';
  String? _error;

  bool get _isFood =>
      widget.data.kind == ShareableKind.foodLog ||
      widget.data.kind == ShareableKind.nutrition;

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      final q = await ref.read(shareAiRepositoryProvider).restyleQuota();
      if (!mounted) return;
      setState(() {
        _quota = q;
        _loadingQuota = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Quota read failure → treat F1 as unavailable (no silent enable).
      setState(() {
        _quota = const RestyleQuota(
            usedToday: 0, dailyCap: 0, remaining: 0, enabled: false);
        _loadingQuota = false;
      });
    }
  }

  // ─────────────────────────── F1 restyle ───────────────────────────────────

  Future<void> _restyle(RestyleStyle style) async {
    if (_restyling) return;
    final userId = ref.read(currentUserIdProvider);
    final photo = widget.photoPathOrUrl;
    if (userId == null || photo == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _restyling = true;
      _error = null;
    });
    try {
      final repo = ref.read(shareAiRepositoryProvider);
      final isHttp = photo.startsWith('http');
      // Always upload bytes: a local file is read directly, an http(s) S3 URL
      // is fetched once (we hold the URL, not the raw key).
      final bytes = isHttp
          ? (await Dio().get<List<int>>(
              photo,
              options: Options(responseType: ResponseType.bytes),
            ))
              .data!
          : await File(photo).readAsBytes();
      final result = await repo.aiRestyle(
        userId: userId,
        style: style,
        imageBytes: Uint8List.fromList(bytes),
        filename: 'restyle.jpg',
      );
      // Swap the card background to the restyled (presigned) image.
      widget.controller.setBackground(
        CardBackground(
          kind: CardBackgroundKind.photo,
          photo: CardPhotoRef(staticPath: result.url),
          photoFit: BoxFit.cover,
        ),
      );
      // ALWAYS drop a visible AI-disclosure badge (transparency requirement).
      _addDisclosureBadge(result.disclosure);
      if (!mounted) return;
      setState(() {
        _quota = result.quota;
        _restyling = false;
      });
      // Capture the root messenger BEFORE popping — once this sheet is
      // dismissed `mounted` is false and `_toast` would silently no-op, which
      // made a successful restyle look like nothing happened.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(result.cached
              ? 'Restyled (from cache — free)'
              : 'Restyled with AI'),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _restyling = false;
        _error = _restyleError(e);
      });
    }
  }

  String _restyleError(Object e) {
    final s = e.toString();
    if (s.contains('429')) {
      return "You've hit today's AI restyle limit. Try again tomorrow.";
    }
    if (s.contains('503')) {
      return 'AI restyle is temporarily unavailable.';
    }
    return 'Could not restyle the photo — please try again.';
  }

  /// A small pill text element in the bottom-left corner declaring the image is
  /// AI-styled. Selectable/movable like any element but seeded on-canvas.
  void _addDisclosureBadge(String disclosure) {
    widget.controller.addElement(
      CardElement(
        id: CardDoc.newId(),
        type: CardElementType.text,
        transform: const ElementTransform(
          position: Offset(0.5, 0.95),
          size: Size(0.6, 0.035),
        ),
        props: TextProps(
          literal: '✨ $disclosure',
          fontSize: 22,
          color: Colors.white,
          align: TextAlign.center,
          highlightColor: Colors.black.withValues(alpha: 0.45),
          maxLines: 1,
        ),
      ),
    );
  }

  // ─────────────────────────── F2 insight line ──────────────────────────────

  Future<void> _addInsightLine() async {
    if (_fetchingLine) return;
    HapticFeedback.selectionClick();
    setState(() {
      _fetchingLine = true;
      _error = null;
    });
    try {
      final repo = ref.read(shareAiRepositoryProvider);
      InsightLine line;
      if (_isFood) {
        line = await repo.insightLineForFood(
          foodLogId: widget.data.foodLogId,
          date: widget.data.foodLogId == null
              ? (widget.data.dateIso ?? _todayIso())
              : null,
          tone: _tone,
        );
      } else {
        // Workout (or any non-food). Needs a workout id; if absent the
        // endpoint still returns a deterministic line keyed by date.
        if (widget.data.workoutId != null) {
          line = await repo.insightLineForWorkout(
            workoutId: widget.data.workoutId!,
            tone: _tone,
          );
        } else {
          // No workout id → fall back to a date-keyed line (deterministic).
          line = await repo.insightLineForFood(
            date: widget.data.dateIso ?? _todayIso(),
            tone: _tone,
          );
        }
      }
      if (line.isEmpty) {
        if (!mounted) return;
        setState(() => _fetchingLine = false);
        _toast('No insight for this one yet.');
        return;
      }
      _addLineElement(line.line);
      if (!mounted) return;
      setState(() => _fetchingLine = false);
      // Capture the root messenger before popping (see _restyle) so the
      // success confirmation actually shows after the sheet closes.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Insight line added — drag to position it.'),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchingLine = false;
        _error = 'Could not fetch an insight line — please try again.';
      });
    }
  }

  String _todayIso() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  void _addLineElement(String text) {
    // A roomy low-third caption block: tall enough that multi-line AI copy stays
    // readable instead of shrinking into a microscopic sliver. White text + a
    // soft drop shadow keeps it legible over any photo/restyle background.
    widget.controller.addElement(
      CardElement(
        id: CardDoc.newId(),
        type: CardElementType.text,
        transform: const ElementTransform(
          position: Offset(0.5, 0.62),
          size: Size(0.86, 0.30),
        ),
        effects: const ElementEffects(
          shadow: ShadowSpec(blur: 18),
        ),
        props: TextProps(
          literal: text,
          fontSize: 40,
          color: Colors.white,
          align: TextAlign.center,
          maxLines: 5,
          sizeMode: TextSizeMode.shrinkToFit,
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.of(context).accent;
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.8),
      decoration: const BoxDecoration(
        color: Color(0xFF14161B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              18, 12, 18, 18 + media.viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('AI touches',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Each runs only when you tap it.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBanner(_error!),
              ],
              const SizedBox(height: 20),
              _restyleSection(accent),
              const SizedBox(height: 24),
              _insightSection(accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text(msg,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  // ── F1 UI ──
  Widget _restyleSection(Color accent) {
    final hasPhoto = widget.photoPathOrUrl != null;
    final quota = _quota;
    final enabled = quota?.enabled ?? false;
    final remaining = quota?.remaining ?? 0;
    final capReached = enabled && remaining <= 0;

    String subtitle;
    if (_loadingQuota) {
      subtitle = 'Checking availability…';
    } else if (!enabled) {
      subtitle = 'AI restyle is unavailable right now.';
    } else if (!hasPhoto) {
      subtitle = 'Pick a photo backdrop first to restyle it.';
    } else if (capReached) {
      subtitle = "You've used all of today's restyles. Resets tomorrow.";
    } else {
      subtitle = '$remaining of ${quota?.dailyCap ?? 0} left today';
    }

    final canRestyle =
        enabled && hasPhoto && !capReached && !_restyling && !_loadingQuota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_fix_high_rounded, color: accent, size: 18),
            const SizedBox(width: 8),
            const Text('Restyle photo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        const SizedBox(height: 12),
        if (_restyling)
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Restyling…',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13)),
            ],
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final style in RestyleStyle.values)
                _styleChip(style, accent, canRestyle),
            ],
          ),
      ],
    );
  }

  Widget _styleChip(RestyleStyle style, Color accent, bool enabled) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? () => _restyle(style) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Text(
            style.label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ── F2 UI ──
  Widget _insightSection(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_rounded, color: accent, size: 18),
            const SizedBox(width: 8),
            const Text('Add an AI insight line',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text('A one-liner about this ${_isFood ? 'meal' : 'session'}.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            _toneChip('supportive', 'Supportive', accent),
            const SizedBox(width: 10),
            _toneChip('savage', 'Savage', accent),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _fetchingLine ? null : _addInsightLine,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _fetchingLine
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.add_rounded, size: 18),
            label: Text(_fetchingLine ? 'Fetching…' : 'Add insight line',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _toneChip(String value, String label, Color accent) {
    final selected = _tone == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tone = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.white.withValues(alpha: 0.12),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
