import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../../data/services/api_client.dart';

/// Tracks whether the signed-in user's email is verified, driving the in-app
/// "verify your email" banner.
///
/// Signup is soft-gated — the app is fully usable while unverified — so this
/// is a pure nudge. It FAILS OPEN: any network/parse error is treated as
/// "verified" so a transient failure can never nag a user who is actually
/// fine. State `true` = verified (no banner); `false` = show the banner.
class EmailVerificationNotifier extends StateNotifier<bool> {
  EmailVerificationNotifier(this._ref) : super(true) {
    refresh();
  }

  final Ref _ref;

  /// Re-checks `/auth/email/status`. Called on creation and on app resume.
  Future<void> refresh() async {
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.get(
        '${ApiConstants.baseUrl}/api/v1/auth/email/status',
      );
      final data = res.data;
      final verified = data is Map ? data['verified'] == true : true;
      if (mounted) state = verified;
    } catch (_) {
      if (mounted) state = true; // fail-open — never nag on an error
    }
  }

  /// Re-issues + resends the verification email. Returns a status string:
  /// 'sent' | 'already_verified' | 'cooldown' | 'error'.
  Future<String> resend() async {
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.post(
        '${ApiConstants.baseUrl}/api/v1/auth/email/resend-verification',
      );
      final data = res.data;
      if (data is Map && data['already_verified'] == true) {
        if (mounted) state = true;
        return 'already_verified';
      }
      if (data is Map && data['sent'] == true) return 'sent';
      if (data is Map && data['reason'] == 'cooldown') return 'cooldown';
      return 'error';
    } catch (_) {
      return 'error';
    }
  }
}

/// `true` = email verified (banner hidden); `false` = show the verify banner.
final emailVerificationProvider =
    StateNotifierProvider<EmailVerificationNotifier, bool>(
  (ref) => EmailVerificationNotifier(ref),
);
