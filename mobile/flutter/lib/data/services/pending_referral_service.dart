import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Durable store for a referral code that was captured BEFORE the user
/// authenticated (deep-link tap, pasted in onboarding, etc.). The code is
/// consumed exactly once, right after sign-in completes.
///
/// Persistence rule: we use SharedPreferences (not in-memory) because the
/// user frequently leaves the app between tapping an invite link and
/// finishing Google/Apple signup — the install-from-App-Store path can
/// take minutes. Cleared on successful apply or on sign-out.
class PendingReferralService {
  static const String _key = 'pending_referral_code';
  // Codes are uppercase alphanumeric 4–12 chars (matches backend
  // apply_referral_code validation). Reject anything outside this shape
  // instead of silently storing garbage that the server would reject.
  static final RegExp _codeShape = RegExp(r'^[A-Z0-9]{4,12}$');

  /// Normalize a raw code from any source (deep link path segment, user
  /// paste, share text). Returns null if it can't be rescued — caller
  /// should show the "invalid code" error to the user in that case.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    // Strip whitespace, punctuation, and any non-alnum characters users
    // accidentally include when pasting ("Code: AB-CD 12" → "ABCD12").
    final cleaned = raw
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .trim();
    if (cleaned.isEmpty) return null;
    if (!_codeShape.hasMatch(cleaned)) return null;
    return cleaned;
  }

  /// Store a pending code. If [code] can't be normalized this is a no-op —
  /// we never want to persist a guaranteed-invalid value that will just
  /// produce a 400 after signup.
  static Future<bool> set(String code) async {
    final normalized = normalize(code);
    if (normalized == null) {
      debugPrint('⚠️ [PendingReferral] Refused to store invalid code: "$code"');
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalized);
    debugPrint('✅ [PendingReferral] Stored pending code: $normalized');
    return true;
  }

  /// Read without consuming. Returns null if no code pending.
  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<bool> hasPending() async {
    final code = await read();
    return code != null && code.isNotEmpty;
  }

  /// Clear the pending code — call after a successful apply, or on
  /// sign-out to prevent leaking one user's code into another's session.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    debugPrint('🧹 [PendingReferral] Cleared pending code');
  }
}
