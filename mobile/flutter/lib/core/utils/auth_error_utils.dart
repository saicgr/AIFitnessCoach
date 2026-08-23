/// Translate raw Supabase / repository auth errors into actionable copy.
/// Without this, users see strings like "Exception: AuthApiException(...)"
/// or "Invalid login credentials" without context — hard to act on.
String humanizeAuthError(String raw, {bool isSignUp = false}) {
  final lower = raw.toLowerCase();
  if (lower.contains('invalid login credentials') ||
      lower.contains('invalid email or password') ||
      lower.contains('wrong password')) {
    return isSignUp
        ? 'Could not create the account. Try a different email or password.'
        : "Email or password doesn't match our records. Tap Forgot Password if you need to reset.";
  }
  if (lower.contains('email not confirmed') ||
      lower.contains('verify your account') ||
      lower.contains('check your email')) {
    return 'Please confirm your email first — check your inbox for a verification link.';
  }
  if (lower.contains('user already registered') ||
      lower.contains('already exists') ||
      lower.contains('duplicate key')) {
    return 'An account with that email already exists. Try signing in instead.';
  }
  if (lower.contains('rate limit') || lower.contains('too many requests')) {
    return 'Too many attempts. Wait a minute and try again.';
  }
  if (lower.contains('network') ||
      lower.contains('socket') ||
      lower.contains('timed out') ||
      lower.contains('connection')) {
    return "Can't reach the server. Check your connection and try again.";
  }
  if (lower.contains('weak password') ||
      lower.contains('password is too short')) {
    return 'Use a stronger password — at least 8 characters with a letter and a number.';
  }
  // Never surface a raw exception / stack blob to the user (App Store
  // reviewers were seeing the full "DioException [bad response]: …"
  // dump). If the text still looks like one, fall back to generic copy.
  if (lower.contains('dioexception') ||
      lower.contains('requestoptions') ||
      lower.contains('stacktrace') ||
      lower.contains('status code of') ||
      raw.length > 160) {
    return isSignUp
        ? 'Could not create your account. Please try again.'
        : 'Sign-in failed. Please try again.';
  }
  // Strip the most verbose decoration before showing raw text as a fallback.
  return raw
      .replaceAll('Exception: ', '')
      .replaceAll(RegExp(r'^AuthApiException\([^)]*\)\s*:?\s*'), '')
      .trim();
}
