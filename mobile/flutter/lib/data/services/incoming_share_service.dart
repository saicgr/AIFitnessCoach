/// Wraps the `receive_sharing_intent` plugin into a single Riverpod stream
/// that the app shell listens to. Emits a [SharedPayload] every time the
/// user shares something INTO Zealova (iOS Share Extension / Android
/// ACTION_SEND).
library incoming_share_service;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// What kind of payload arrived.
enum SharedPayloadKind { images, video, audio, text, url, pdf, files, mixed }

class SharedPayload {
  SharedPayload({
    required this.kind,
    this.localFilePaths = const [],
    this.text,
    this.urls = const [],
  });

  /// What kind of share is this — drives initial routing decisions in
  /// [ShareRouterScreen] before any classifier call is made.
  final SharedPayloadKind kind;

  /// Local file paths handed over by the share extension. The host app
  /// owns reading them and uploading to S3.
  final List<String> localFilePaths;

  /// Plain text payload (Notes share, AI assistant share, etc.).
  final String? text;

  /// URLs extracted out of the share. Most URL shares arrive as a
  /// `text/plain` with the URL inside; we extract it here.
  final List<String> urls;

  bool get isEmpty =>
      localFilePaths.isEmpty &&
      (text == null || text!.isEmpty) &&
      urls.isEmpty;

  /// Treat as a single image-class share when all media items are images.
  bool get isSingleImage =>
      kind == SharedPayloadKind.images && localFilePaths.length == 1;

  bool get isMulti => localFilePaths.length > 1;
}

class IncomingShareService {
  IncomingShareService();

  /// Broadcasts payloads. Listen in [ShareRouterScreen] (or wherever) and
  /// push the router screen on every emit.
  final StreamController<SharedPayload> _controller =
      StreamController<SharedPayload>.broadcast();
  Stream<SharedPayload> get stream => _controller.stream;

  StreamSubscription<List<SharedMediaFile>>? _mediaSub;
  bool _initialized = false;

  /// Wire the OS-level streams into our [stream]. Idempotent — safe to
  /// call multiple times from app shell init.
  ///
  /// Handles BOTH cold-start (the share that launched the app) and the
  /// warm path (share while the app is foregrounded).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Cold-start: any share that triggered the app launch.
      final initial =
          await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) {
        final p = _payloadFromMedia(initial);
        if (!p.isEmpty) _controller.add(p);
      }

      // Warm path — every subsequent share while the app is alive.
      _mediaSub = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen((items) {
        final p = _payloadFromMedia(items);
        if (!p.isEmpty) _controller.add(p);
      }, onError: (e, st) {
        // ignore: avoid_print
        print('❌ [IncomingShare] media stream error: $e');
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('❌ [IncomingShare] init failed: $e\n$st');
    }
  }

  Future<void> dispose() async {
    await _mediaSub?.cancel();
    await _controller.close();
  }

  /// Tells the plugin we've consumed the initial intent. Call AFTER routing
  /// so re-opening the app doesn't replay the share.
  void resetInitial() {
    try {
      ReceiveSharingIntent.instance.reset();
    } catch (_) {
      // plugin may not expose reset on every version — best effort
    }
  }

  // ---------------------------------------------------------------------------
  // Payload classification
  // ---------------------------------------------------------------------------

  SharedPayload _payloadFromMedia(List<SharedMediaFile> items) {
    if (items.isEmpty) {
      return SharedPayload(kind: SharedPayloadKind.text);
    }

    final filePaths = <String>[];
    final imageOnly = <String>[];
    final videoOnly = <String>[];
    final audioOnly = <String>[];
    final fileOnly = <String>[];
    String? textPayload;
    final urls = <String>[];

    for (final m in items) {
      switch (m.type) {
        case SharedMediaType.image:
          if (m.path.isNotEmpty) {
            filePaths.add(m.path);
            imageOnly.add(m.path);
          }
          break;
        case SharedMediaType.video:
          if (m.path.isNotEmpty) {
            filePaths.add(m.path);
            videoOnly.add(m.path);
          }
          break;
        case SharedMediaType.file:
          if (m.path.isNotEmpty) {
            filePaths.add(m.path);
            final lower = m.path.toLowerCase();
            if (_looksLikeAudio(lower)) {
              audioOnly.add(m.path);
            } else if (_looksLikePdf(lower)) {
              fileOnly.add(m.path); // PDF
            } else {
              fileOnly.add(m.path);
            }
          }
          break;
        case SharedMediaType.text:
          final t = m.path; // text shares deliver text in `path` per plugin
          if (t.isNotEmpty) {
            // Pull URLs out — most "share link from Safari" payloads arrive as
            // text/plain containing the URL.
            final extracted = _extractUrls(t);
            if (extracted.isNotEmpty) {
              urls.addAll(extracted);
            }
            textPayload = (textPayload ?? '') + (textPayload == null ? '' : '\n') + t;
          }
          break;
        case SharedMediaType.url:
          urls.add(m.path);
          break;
      }
    }

    // Decide kind. URL wins if present and there are no media files; text
    // wins if there's a non-URL text body.
    if (filePaths.isEmpty && urls.isNotEmpty && (textPayload == null || _onlyContainsUrls(textPayload, urls))) {
      return SharedPayload(kind: SharedPayloadKind.url, urls: urls);
    }
    if (filePaths.isEmpty && textPayload != null && textPayload.isNotEmpty) {
      return SharedPayload(kind: SharedPayloadKind.text, text: textPayload, urls: urls);
    }

    // PDF — single file with .pdf extension
    if (filePaths.length == 1 && _looksLikePdf(filePaths.first.toLowerCase())) {
      return SharedPayload(kind: SharedPayloadKind.pdf, localFilePaths: filePaths);
    }
    // Audio — single audio file
    if (filePaths.length == 1 && _looksLikeAudio(filePaths.first.toLowerCase())) {
      return SharedPayload(kind: SharedPayloadKind.audio, localFilePaths: filePaths);
    }
    // Video — single video file
    if (videoOnly.length == 1 && imageOnly.isEmpty && audioOnly.isEmpty && fileOnly.isEmpty) {
      return SharedPayload(kind: SharedPayloadKind.video, localFilePaths: filePaths);
    }
    // Images-only (one or more)
    if (imageOnly.isNotEmpty && videoOnly.isEmpty && audioOnly.isEmpty && fileOnly.isEmpty) {
      return SharedPayload(kind: SharedPayloadKind.images, localFilePaths: imageOnly);
    }

    // Mixed (multiple files, mixed types) — let the router classify.
    return SharedPayload(
      kind: SharedPayloadKind.mixed,
      localFilePaths: filePaths,
      text: textPayload,
      urls: urls,
    );
  }

  // ---------------------------------------------------------------------------
  // Heuristics
  // ---------------------------------------------------------------------------

  static const _audioExts = {
    '.m4a', '.mp3', '.wav', '.caf', '.aac', '.flac', '.ogg', '.oga', '.opus',
  };
  static const _pdfExts = {'.pdf'};

  static bool _looksLikeAudio(String pathLower) =>
      _audioExts.any(pathLower.endsWith);
  static bool _looksLikePdf(String pathLower) =>
      _pdfExts.any(pathLower.endsWith);

  static final RegExp _urlRe = RegExp(r'https?://\S+', caseSensitive: false);

  static List<String> _extractUrls(String text) {
    final out = <String>[];
    for (final m in _urlRe.allMatches(text)) {
      out.add(m.group(0)!.replaceAll(RegExp(r'[)\.,;]+$'), ''));
    }
    return out;
  }

  /// True when [text] is essentially just the URLs we already extracted.
  static bool _onlyContainsUrls(String text, List<String> urls) {
    final stripped = text.trim();
    if (urls.isEmpty) return false;
    String remaining = stripped;
    for (final u in urls) {
      remaining = remaining.replaceAll(u, '');
    }
    remaining = remaining.replaceAll(RegExp(r'\s+'), '').trim();
    return remaining.length < 6;
  }

  /// Provided so the iOS extension fallback path (zealova://share/v1?ids=...)
  /// can register inbound shares manually.
  void pushManualPayload(SharedPayload p) {
    if (!p.isEmpty) _controller.add(p);
  }
}

/// Singleton — exposed via Riverpod so the app shell + ShareRouterScreen
/// can both listen / dispatch.
final incomingShareServiceProvider =
    Provider<IncomingShareService>((ref) => IncomingShareService());

/// Convenience StreamProvider for any widget that just wants the latest
/// incoming share.
final incomingShareStreamProvider =
    StreamProvider<SharedPayload>((ref) {
  final svc = ref.watch(incomingShareServiceProvider);
  return svc.stream;
});

/// Reference-typed for callers that need to ensure init() ran exactly once.
class IncomingShareInitGuard {
  IncomingShareInitGuard._();
  static final IncomingShareInitGuard instance = IncomingShareInitGuard._();
  bool _done = false;
  Future<void> ensureInit(IncomingShareService svc) async {
    if (_done) return;
    _done = true;
    if (Platform.isIOS || Platform.isAndroid) {
      await svc.init();
    }
  }
}
