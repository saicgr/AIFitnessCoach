import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/email_verification_provider.dart';

import '../l10n/generated/app_localizations.dart';
/// Slim, non-blocking "verify your email" banner shown at the top of the app
/// shell while the signed-in user has not yet confirmed their email.
///
/// Signup is soft-gated: the user is fully in the app regardless. This banner
/// is the gentle nudge. It auto-clears once verification status flips (the
/// user taps the link in the email); the status is re-checked on every app
/// resume. Tapping "Resend" re-issues the verification email.
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> with WidgetsBindingObserver {
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check on resume — the user may have just tapped the verify link in
    // their mail app and come back. This is what clears the banner.
    if (state == AppLifecycleState.resumed) {
      ref.read(emailVerificationProvider.notifier).refresh();
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    final status = await ref.read(emailVerificationProvider.notifier).resend();
    if (!mounted) return;
    setState(() => _resending = false);

    const messages = <String, String>{
      'sent': 'Verification email sent. Check your inbox.',
      'already_verified': 'Your email is already verified.',
      'cooldown': 'Just sent one. Give it a minute, then try again.',
      'error': 'Could not send right now. Check your connection.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messages[status] ?? messages['error']!),
        behavior: SnackBarBehavior.floating,
        backgroundColor: status == 'error' ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verified = ref.watch(emailVerificationProvider);
    final show = !verified;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: show ? Offset.zero : const Offset(0, -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: show ? null : 0,
        color: const Color(0xFF0E7490), // cyan-700 — distinct from offline orange
        child: show
            ? SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_outlined,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).emailVerificationBannerVerifyYourEmailTo,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _resending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : InkResponse(
                              onTap: _resend,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  AppLocalizations.of(context).emailVerificationBannerResend,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
