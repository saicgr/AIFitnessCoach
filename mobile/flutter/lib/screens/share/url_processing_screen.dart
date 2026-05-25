/// UrlProcessingScreen — the dedicated SSE-progress UI for the URL
/// pipeline (`POST /share/fetch-url`). Long YouTube videos take 20-40 s
/// to process; the plan calls this out as non-negotiable because a
/// frozen spinner reads broken.
///
/// In the current implementation `ShareRouterScreen` handles all
/// payloads uniformly — but the plan calls for a dedicated screen so
/// the URL pipeline can render richer per-stage UI (transcribing,
/// chapters found, exercises discovered). This file is the dedicated
/// entry point. Routing is wired through the app shell: when an
/// incoming SharedPayload is a `SharedPayloadKind.url`, the shell
/// pushes this screen instead of `ShareRouterScreen`.
library url_processing_screen;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/imports_api_service.dart';
import '../../data/services/incoming_share_service.dart';
import 'share_chooser_sheet.dart';
import 'share_router_screen.dart';
import 'share_routing_table.dart';

class UrlProcessingScreen extends ConsumerStatefulWidget {
  const UrlProcessingScreen({super.key, required this.url, this.payload});

  final String url;
  final SharedPayload? payload;

  @override
  ConsumerState<UrlProcessingScreen> createState() =>
      _UrlProcessingScreenState();
}

class _UrlProcessingScreenState extends ConsumerState<UrlProcessingScreen> {
  String _statusLine = 'Fetching link…';
  final List<String> _exerciseFeed = [];
  String? _intent;
  String? _confidence;
  String? _sharedItemId;
  String? _error;
  bool _locked = false;
  StreamSubscription<ShareSseEvent>? _sub;
  Map<String, dynamic>? _doneEvent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    final api = ref.read(importsApiServiceProvider);
    final stream = api.fetchUrl(url: widget.url);
    _sub = stream.listen(_onEvent, onError: (e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  void _onEvent(ShareSseEvent evt) {
    if (!mounted) return;
    setState(() {
      switch (evt.stage) {
        case 'fetching':
          _statusLine = 'Reading from ${evt.data['source'] ?? 'the web'}…';
          break;
        case 'cache_hit':
          _statusLine = 'Found a recent copy — fast path…';
          break;
        case 'downloading_media':
          _statusLine = 'Downloading media…';
          break;
        case 'transcribing':
          _statusLine = 'Transcribing audio (${evt.data['duration_s'] ?? '…'} s)…';
          break;
        case 'fetched':
          final title = evt.data['title'];
          _statusLine = (title is String && title.isNotEmpty)
              ? 'Read “$title”…'
              : 'Got the contents…';
          break;
        case 'classifying':
          _statusLine = 'Choosing the right home…';
          break;
        case 'extracting':
          _statusLine = 'Pulling out the details…';
          break;
        case 'exercise_found':
          final idx = evt.data['index'] as int? ?? 0;
          final total = evt.data['of'] as int? ?? 0;
          final name = evt.data['name'] as String? ?? '';
          _exerciseFeed.add('${idx + 1}/$total · $name');
          _statusLine = 'Found exercise ${idx + 1} of $total: $name';
          break;
        case 'locked':
          _locked = true;
          _statusLine = (evt.data['message'] as String?) ?? 'This is locked.';
          break;
        case 'error':
          _error = (evt.data['message'] as String?) ?? 'Something went wrong.';
          break;
        case 'dedupe':
          _sharedItemId = evt.data['shared_item_id'] as String?;
          _statusLine = (evt.data['message'] as String?) ?? 'Already imported.';
          break;
        case 'done':
          _doneEvent = evt.data;
          _intent = evt.data['intent'] as String?;
          _confidence = evt.data['confidence'] as String?;
          _sharedItemId = evt.data['shared_item_id'] as String?;
          _statusLine = 'Done.';
          _finishWithRouting();
          break;
      }
    });
  }

  Future<void> _finishWithRouting() async {
    if (!mounted || _doneEvent == null) return;
    final intent = _intent ?? 'discuss';
    final dest = destinationForIntent(intent);
    final decision = ShareDecision(
      destination: dest,
      confidence: _confidence ?? 'medium',
      intent: intent,
      sharedItemId: _sharedItemId,
    );
    if (decision.isConfident) {
      _route(dest, decision);
    } else {
      final picked = await ShareChooserSheet.show(
        context,
        predicted: dest,
        predictionLabel: intent,
      );
      _route(picked ?? dest, decision);
    }
  }

  void _route(ShareDestination dest, ShareDecision decision) {
    Navigator.of(context).pop<ShareRouteResult>(ShareRouteResult(
      destination: dest,
      decision: decision,
      payload: widget.payload ?? SharedPayload(kind: SharedPayloadKind.url, urls: [widget.url]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importing link'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _error != null
              ? _buildError(theme)
              : _locked
                  ? _buildLocked(theme)
                  : _buildProgress(theme),
        ),
      ),
    );
  }

  Widget _buildProgress(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(_statusLine, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(_url(widget.url),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 24),
        if (_exerciseFeed.isNotEmpty)
          Expanded(
            child: ListView(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Exercises so far', style: theme.textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                for (final line in _exerciseFeed.reversed.take(8))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(line, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocked(ThemeData theme) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 36),
          const SizedBox(height: 12),
          Text(_statusLine, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text("Try pasting the caption or text instead.",
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Got it'),
          ),
        ],
      );

  Widget _buildError(ThemeData theme) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: 12),
          Text(_error ?? 'Something went wrong.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Close'),
          ),
        ],
      );

  String _url(String s) => s.replaceFirst(RegExp(r'^https?://'), '');
}
