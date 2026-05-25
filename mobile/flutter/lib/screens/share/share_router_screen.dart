/// ShareRouterScreen — the in-app landing pad for every payload that
/// arrives via the system share sheet.
///
/// Lifecycle:
///   1. Receive [SharedPayload] from IncomingShareService.
///   2. Show "Sorting…" / "Reading…" / "Transcribing…" depending on kind.
///   3. Call the appropriate /share/* endpoint(s).
///   4. On high confidence — show a 1.8 s countdown card with override
///      chips, then auto-route on timeout.
///   5. On medium/low confidence — show ShareChooserSheet.
library share_router_screen;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/imports_api_service.dart';
import '../../data/services/incoming_share_service.dart';
import 'share_chooser_sheet.dart';
import 'share_routing_table.dart';

/// Entry point pushed by the app shell whenever a share lands.
class ShareRouterScreen extends ConsumerStatefulWidget {
  const ShareRouterScreen({super.key, required this.payload});
  final SharedPayload payload;

  @override
  ConsumerState<ShareRouterScreen> createState() => _ShareRouterScreenState();
}

enum _Phase { initializing, working, predicting, countdown, navigating, error, locked }

class _ShareRouterScreenState extends ConsumerState<ShareRouterScreen> {
  _Phase _phase = _Phase.initializing;
  String _statusLine = 'Receiving…';
  String _detail = '';
  Timer? _countdownTimer;
  int _countdownRemaining = 0;
  ShareDecision? _decision;
  String? _predictionLabel;
  String? _predictionWhy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPipeline());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Pipeline dispatch
  // ---------------------------------------------------------------------------

  Future<void> _runPipeline() async {
    final p = widget.payload;
    setState(() {
      _phase = _Phase.working;
      _statusLine = _initialStatusLine(p);
    });

    final api = ref.read(importsApiServiceProvider);
    try {
      switch (p.kind) {
        case SharedPayloadKind.text:
          await _runText(api, p.text ?? '');
          break;
        case SharedPayloadKind.url:
          await _runUrl(api, p.urls.isNotEmpty ? p.urls.first : '');
          break;
        case SharedPayloadKind.images:
          if (p.localFilePaths.length == 1) {
            await _runSingleImage(api, p.localFilePaths.first);
          } else {
            await _runMultiImage(api, p.localFilePaths);
          }
          break;
        case SharedPayloadKind.video:
          // For now route to form check via the existing import-exercise
          // flow. (Future: server-side workout extraction for long videos.)
          _decide(ShareDecision(
            destination: ShareDestination.formCheck,
            confidence: 'medium',
            contentType: 'exercise_form',
          ));
          break;
        case SharedPayloadKind.audio:
          await _runAudio(api, p.localFilePaths.first);
          break;
        case SharedPayloadKind.pdf:
          await _runPdf(api, p.localFilePaths.first);
          break;
        case SharedPayloadKind.files:
        case SharedPayloadKind.mixed:
          // Hand off to chooser — the user picks the right destination.
          _showChooserAndRoute(ShareDestination.chooser);
          break;
      }
    } catch (e) {
      _fail('Something went wrong. Try again?');
    }
  }

  String _initialStatusLine(SharedPayload p) {
    switch (p.kind) {
      case SharedPayloadKind.text:
        return 'Reading text…';
      case SharedPayloadKind.url:
        return 'Fetching link…';
      case SharedPayloadKind.images:
        return p.localFilePaths.length > 1 ? 'Sorting photos…' : 'Looking at photo…';
      case SharedPayloadKind.video:
        return 'Looking at video…';
      case SharedPayloadKind.audio:
        return 'Transcribing audio…';
      case SharedPayloadKind.pdf:
        return 'Reading PDF…';
      case SharedPayloadKind.files:
      case SharedPayloadKind.mixed:
        return 'Sorting…';
    }
  }

  // ---------------------------------------------------------------------------
  // Per-payload runners
  // ---------------------------------------------------------------------------

  Future<void> _runText(ImportsApiService api, String text) async {
    setState(() => _statusLine = 'Reading text…');
    final stream = api.importText(text: text);
    await for (final evt in stream) {
      if (!mounted) return;
      _handleSseEvent(evt);
    }
  }

  Future<void> _runUrl(ImportsApiService api, String url) async {
    if (url.isEmpty) {
      _fail('No link to import.');
      return;
    }
    setState(() => _statusLine = 'Fetching link…');
    final stream = api.fetchUrl(url: url);
    await for (final evt in stream) {
      if (!mounted) return;
      _handleSseEvent(evt);
    }
  }

  Future<void> _runSingleImage(ImportsApiService api, String filePath) async {
    setState(() => _statusLine = 'Looking at the photo…');
    final result = await api.classifyImage(filePath: filePath);
    _decide(ShareDecision(
      destination: destinationForContentType(result.contentType),
      confidence: result.confidence,
      contentType: result.contentType,
      s3Key: result.s3Key,
      sharedItemId: null, // returned in result object but unused on client for now
    ));
  }

  Future<void> _runMultiImage(ImportsApiService api, List<String> paths) async {
    // For multi-image we first classify each. To keep this slice small we
    // route to the chooser when results aren't unanimous (mirrors the
    // "grouped chooser" plan). A future enhancement uploads each image
    // then calls /share/classify-batch with s3 keys for parallelism.
    setState(() => _statusLine = 'Sorting ${paths.length} photos…');
    final hints = <String>{};
    String? lastContentType;
    for (final fp in paths) {
      try {
        final r = await api.classifyImage(filePath: fp);
        hints.add(r.routingHint);
        lastContentType = r.contentType;
      } catch (_) {
        hints.add('chooser');
      }
    }
    if (hints.length == 1 && lastContentType != null) {
      _decide(ShareDecision(
        destination: destinationForContentType(lastContentType),
        confidence: 'medium',
        contentType: lastContentType,
      ));
    } else {
      _showChooserAndRoute(ShareDestination.chooser);
    }
  }

  Future<void> _runAudio(ImportsApiService api, String filePath) async {
    setState(() => _statusLine = 'Transcribing audio…');
    final stream = api.importAudio(filePath: filePath);
    await for (final evt in stream) {
      if (!mounted) return;
      _handleSseEvent(evt);
    }
  }

  Future<void> _runPdf(ImportsApiService api, String filePath) async {
    setState(() => _statusLine = 'Reading PDF…');
    final stream = api.importPdf(filePath: filePath);
    await for (final evt in stream) {
      if (!mounted) return;
      _handleSseEvent(evt);
    }
  }

  // ---------------------------------------------------------------------------
  // SSE event router
  // ---------------------------------------------------------------------------

  void _handleSseEvent(ShareSseEvent evt) {
    final stage = evt.stage;
    final data = evt.data;
    switch (stage) {
      case 'received':
        // already in working state
        break;
      case 'fetching':
        setState(() => _statusLine = 'Fetching…');
        break;
      case 'downloading_media':
        setState(() => _statusLine = 'Downloading media…');
        break;
      case 'transcribing':
        setState(() => _statusLine = 'Transcribing…');
        break;
      case 'transcribed':
        setState(() => _detail = (data['transcript_preview'] as String? ?? '').trim());
        break;
      case 'reading_pdf':
      case 'read':
        setState(() => _statusLine = 'Reading PDF…');
        break;
      case 'classifying':
        setState(() => _statusLine = 'Choosing the right home…');
        break;
      case 'extracting':
        setState(() => _statusLine = 'Pulling out the details…');
        break;
      case 'exercise_found':
        final idx = data['index'] as int? ?? 0;
        final total = data['of'] as int? ?? 0;
        final name = data['name'] as String? ?? '';
        setState(() => _detail = 'Found ${idx + 1} of $total: $name');
        break;
      case 'locked':
        setState(() {
          _phase = _Phase.locked;
          _statusLine = data['message'] as String? ?? 'Locked content';
        });
        break;
      case 'error':
        _fail(data['message'] as String? ?? 'Something went wrong.');
        break;
      case 'done':
        _onSseDone(data);
        break;
    }
  }

  void _onSseDone(Map<String, dynamic> data) {
    final intent = data['intent'] as String?;
    final confidence = data['confidence'] as String? ?? 'medium';
    final sharedItemId = data['shared_item_id'] as String?;
    final why = data['why'] as String?;
    final dest = destinationForIntent(intent ?? 'discuss');
    _predictionWhy = why;
    _decide(ShareDecision(
      destination: dest,
      confidence: confidence,
      intent: intent,
      sharedItemId: sharedItemId,
    ));
  }

  // ---------------------------------------------------------------------------
  // Decision flow — countdown / chooser
  // ---------------------------------------------------------------------------

  void _decide(ShareDecision decision) {
    _decision = decision;
    _predictionLabel = _labelForDecision(decision);

    if (decision.destination == ShareDestination.chooser) {
      _showChooserAndRoute(ShareDestination.chooser);
      return;
    }

    if (decision.isConfident) {
      _startCountdown();
    } else {
      _showChooserAndRoute(decision.destination);
    }
  }

  void _startCountdown() {
    setState(() {
      _phase = _Phase.countdown;
      _countdownRemaining = 18; // 1.8 s @ 100 ms ticks
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdownRemaining--);
      if (_countdownRemaining <= 0) {
        t.cancel();
        _route(_decision!.destination);
      }
    });
  }

  Future<void> _showChooserAndRoute(ShareDestination predicted) async {
    if (!mounted) return;
    setState(() => _phase = _Phase.predicting);
    final picked = await ShareChooserSheet.show(
      context,
      predicted: predicted,
      predictionLabel: _predictionLabel,
      predictionWhy: _predictionWhy,
    );
    if (!mounted) return;
    _route(picked ?? predicted);
  }

  void _route(ShareDestination dest) {
    setState(() => _phase = _Phase.navigating);
    // Surface the destination to whatever pushed us. The simplest contract
    // is to pop with the picked destination + the decision context — the
    // dispatcher (app shell / IncomingShareService listener) handles the
    // actual navigation against the GoRouter.
    Navigator.of(context).pop<ShareRouteResult>(ShareRouteResult(
      destination: dest,
      decision: _decision,
      payload: widget.payload,
    ));
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _statusLine = message;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    switch (_phase) {
      case _Phase.countdown:
        body = _buildCountdownCard(theme);
        break;
      case _Phase.error:
        body = _buildError(theme);
        break;
      case _Phase.locked:
        body = _buildLocked(theme);
        break;
      case _Phase.navigating:
        body = const Center(child: CircularProgressIndicator());
        break;
      default:
        body = _buildWorking(theme);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imports'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: body,
      ),
    );
  }

  Widget _buildWorking(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(_statusLine, style: theme.textTheme.titleMedium),
          if (_detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownCard(ThemeData theme) {
    final progress = _countdownRemaining / 18;
    return Center(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sending to ${_predictionLabel ?? 'destination'}…',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              if (_predictionWhy != null && _predictionWhy!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _predictionWhy!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.tune),
                    label: const Text('Change'),
                    onPressed: () {
                      _countdownTimer?.cancel();
                      _showChooserAndRoute(_decision!.destination);
                    },
                  ),
                  FilledButton(
                    onPressed: () {
                      _countdownTimer?.cancel();
                      _route(_decision!.destination);
                    },
                    child: const Text('Go'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: 12),
          Text(_statusLine, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocked(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 36),
          const SizedBox(height: 12),
          Text(_statusLine, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Try pasting the caption or text instead.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String? _labelForDecision(ShareDecision d) {
    if (d.intent != null) {
      switch (d.intent) {
        case 'workout_extract':       return 'workout';
        case 'recipe_extract':        return 'recipe';
        case 'meal_plan_extract':     return 'meal plan';
        case 'food_log_extract':      return 'food log';
        case 'form_check':            return 'form check';
        case 'progress_log':          return 'progress photo';
        case 'tip_save':              return 'saved tip';
        case 'nutrition_question':    return 'AI Coach';
        case 'discuss':               return 'AI Coach';
      }
    }
    if (d.contentType != null) {
      switch (d.contentType) {
        case 'food_plate':
        case 'food_buffet':
        case 'app_screenshot':
          return 'food log';
        case 'food_menu':            return 'menu scan';
        case 'nutrition_label':      return 'nutrition label';
        case 'exercise_form':        return 'form check';
        case 'progress_photo':       return 'progress photo';
        case 'gym_equipment':        return 'equipment';
        case 'recipe_handwritten':   return 'recipe';
        case 'pantry_photo':         return 'pantry';
        case 'document':             return 'document';
      }
    }
    return null;
  }
}

/// Result the router screen pops with. The dispatcher (app shell) reads
/// this and runs the actual GoRouter navigation against the destination.
class ShareRouteResult {
  ShareRouteResult({required this.destination, required this.decision, required this.payload});
  final ShareDestination destination;
  final ShareDecision? decision;
  final SharedPayload payload;
}
