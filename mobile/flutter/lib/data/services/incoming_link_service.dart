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
    // Supabase ships TWO callback formats depending on the template:
    //   • PKCE flow    → ?code=...                    → exchangeCodeForSession
    //   • Classic OTP  → ?token_hash=...&type=signup  → verifyOTP
    // Both arrive on the same /auth/callback path, so we sniff the query
    // params and call whichever Supabase API matches. Matches:
    //   zealova://auth/callback?code=...
    //   https://zealova.com/auth/callback?code=...
    //   https://zealova.com/auth/callback?token_hash=...&type=signup
    //   fitwiz://auth/callback?...   (legacy scheme — pre-rebrand)
    final hasCode = uri.queryParameters.containsKey('code');
    final hasTokenHash = uri.queryParameters.containsKey('token_hash');
    final pathIsAuthCallback = (uri.scheme == 'zealova' ||
                uri.scheme == 'fitwiz') &&
            (uri.host == 'auth' || uri.pathSegments.contains('callback')) ||
        ((uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host == _inviteHost &&
            uri.pathSegments.isNotEmpty &&
            uri.pathSegments.first == 'auth');
    if (pathIsAuthCallback && (hasCode || hasTokenHash)) {
      try {
        if (hasCode) {
          final code = uri.queryParameters['code']!;
          await Supabase.instance.client.auth.exchangeCodeForSession(code);
          debugPrint(
              '✅ [IncomingLink] Supabase session established (PKCE)');
        } else {
          final tokenHash = uri.queryParameters['token_hash']!;
          final typeStr =
              uri.queryParameters['type']?.toLowerCase() ?? 'signup';
          final otpType = _parseOtpType(typeStr);
          await Supabase.instance.client.auth.verifyOTP(
            type: otpType,
            tokenHash: tokenHash,
          );
          debugPrint(
              '✅ [IncomingLink] Supabase session established (OTP type=$typeStr)');
        }
      } catch (e) {
        debugPrint('❌ [IncomingLink] auth-callback exchange failed: $e');
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

  /// Map a Supabase OTP `type` query-string value to the SDK enum.
  /// Email-template defaults: `signup` (verify new account),
  /// `recovery` (forgot-password reset), `email_change` (change-email
  /// confirm), `magiclink` (passwordless sign-in), `invite` (admin invite).
  static OtpType _parseOtpType(String type) {
    switch (type) {
      case 'recovery':
        return OtpType.recovery;
      case 'email_change':
        return OtpType.emailChange;
      case 'magiclink':
        return OtpType.magiclink;
      case 'invite':
        return OtpType.invite;
      case 'email':
      case 'signup':
      default:
        return OtpType.signup;
    }
  }
}
