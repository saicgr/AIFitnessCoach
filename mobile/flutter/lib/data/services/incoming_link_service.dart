import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/referral_provider.dart';
import 'pending_referral_service.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// OS-level incoming-link handler for Universal Links / App Links / custom
/// schemes. Separate from `DeepLinkService` (which handles only widget-
/// originated links via the `home_widget` package).
///
/// Today it only handles referral-invite links — that's the production-
/// critical flow. Other app-wide deep links (e.g. `fitwiz://workout/...`)
/// come through `home_widget` and are handled there; if we later need
/// OS-level delivery for those, extend the switch in [_handle].
///
/// Accepted forms:
///   https://zealova.com/invite/ABC123   (Universal Link — requires AASA)
///   http://zealova.com/invite/ABC123
///   fitwiz://invite/ABC123            (custom scheme)
///   fitwiz://invite?code=ABC123       (share-sheet fallback)
///
/// Flow:
///   * signed-out → store in [PendingReferralService]; flush-on-auth hook
///     in `AuthStateNotifier` applies it right after signup completes.
///   * signed-in  → store + immediately call `applyCode` so the user sees
///     the result without waiting.
class IncomingLinkService {
  static const String _inviteSegment = 'invite';
  static const String _inviteHost = '${Branding.marketingDomain}';

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static bool _initialized = false;

  /// Wire cold-start + warm-start listeners. Idempotent.
  static Future<void> initialize(ProviderContainer container) async {
    if (_initialized) return;
    _initialized = true;

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri, container),
      onError: (e) => debugPrint('⚠️ [IncomingLink] stream error: $e'),
    );

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        debugPrint('🔍 [IncomingLink] cold-start URI: $initial');
        await _handle(initial, container);
      }
    } catch (e) {
      debugPrint('⚠️ [IncomingLink] getInitialLink failed: $e');
    }
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  static Future<void> _handle(Uri uri, ProviderContainer container) async {
    debugPrint('🔗 [IncomingLink] handling: $uri');

    // Supabase Auth callback (email confirm / magic link / OAuth).
    // Exchanges the PKCE `?code=` for a real session so the user lands
    // back in the app already signed in. Matches BOTH:
    //   zealova://auth/callback?code=...
    //   https://zealova.com/auth/callback?code=...
    //   fitwiz://auth/callback?code=...   (legacy scheme)
    final isAuthCallback =
        uri.queryParameters.containsKey('code') &&
            ((uri.scheme == 'zealova' || uri.scheme == 'fitwiz') &&
                    (uri.host == 'auth' ||
                        uri.pathSegments.contains('callback')) ||
                ((uri.scheme == 'https' || uri.scheme == 'http') &&
                    uri.host == _inviteHost &&
                    uri.pathSegments.isNotEmpty &&
                    uri.pathSegments.first == 'auth' &&
                    uri.pathSegments.length > 1 &&
                    uri.pathSegments[1] == 'callback'));
    if (isAuthCallback) {
      final code = uri.queryParameters['code']!;
      try {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        debugPrint('✅ [IncomingLink] Supabase session established from callback');
      } catch (e) {
        debugPrint('❌ [IncomingLink] exchangeCodeForSession failed: $e');
      }
      return;
    }

    final isHttpsInvite = (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == _inviteHost &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == _inviteSegment;
    final isCustomInvite = (uri.scheme == 'fitwiz' || uri.scheme == 'zealova') &&
        (uri.host == _inviteSegment ||
            uri.pathSegments.contains(_inviteSegment));

    if (!isHttpsInvite && !isCustomInvite) {
      // Not our concern — widget links go through home_widget channel.
      return;
    }

    // Extract code: path tail preferred, ?code=... fallback.
    String? raw;
    if (isHttpsInvite) {
      raw = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    } else {
      raw = uri.queryParameters['code'];
      raw ??= uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : (uri.host == _inviteSegment ? null : uri.host);
    }

    final normalized = PendingReferralService.normalize(raw);
    if (normalized == null) {
      debugPrint('⚠️ [IncomingLink] invite link had unusable code: "$raw"');
      return;
    }

    // Persist first so auth-flush can rescue the happy path below.
    await PendingReferralService.set(normalized);

    // Try immediate apply — will succeed when signed-in, fail silently
    // otherwise (expected; auth-flush will retry post-signup).
    try {
      final result = await container
          .read(referralApplyProvider.notifier)
          .apply(normalized);
      if (result.success) {
        await PendingReferralService.clear();
        debugPrint('✅ [IncomingLink] applied code immediately: $normalized');
      } else {
        debugPrint('🔍 [IncomingLink] apply returned success=false: ${result.message}');
      }
    } catch (e) {
      debugPrint('🔍 [IncomingLink] deferring apply until signed-in: $e');
    }
  }
}
