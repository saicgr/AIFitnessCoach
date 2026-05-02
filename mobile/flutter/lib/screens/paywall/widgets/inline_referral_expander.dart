import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/posthog_service.dart';
import '../../onboarding/pre_auth_quiz_screen.dart';

/// Inline "Have a referral code?" expander for the paywall pricing screen.
///
/// Onboarding v5.1: replaces the standalone /referral-code screen. Users on
/// the paywall can tap "Have a referral code?" to expand a small input row,
/// validate against /onboarding/validate-referral, and have the discount
/// applied. No standalone screen needed.
class InlineReferralExpander extends ConsumerStatefulWidget {
  const InlineReferralExpander({super.key});

  @override
  ConsumerState<InlineReferralExpander> createState() =>
      _InlineReferralExpanderState();
}

class _InlineReferralExpanderState
    extends ConsumerState<InlineReferralExpander> {
  bool _expanded = false;
  bool _validating = false;
  String? _error;
  String? _success;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill if user already entered one earlier in the flow.
    final existing = ref.read(preAuthQuizProvider).referralCode;
    if (existing != null && existing.isNotEmpty) {
      _ctrl.text = existing;
      _success = 'Code applied';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _validating = true;
      _error = null;
      _success = null;
    });
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await dio.post(
        '/onboarding/validate-referral',
        data: {'code': code},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['valid'] == true) {
        await ref.read(preAuthQuizProvider.notifier).setReferralCode(code);
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        ref.read(posthogServiceProvider).capture(
              eventName: 'paywall_referral_applied',
              properties: {'code': code},
            );
        setState(() {
          _success =
              data?['discount_label'] as String? ?? 'Code applied!';
          _validating = false;
        });
      } else {
        setState(() {
          _error = data?['message'] as String? ?? 'Code not recognized';
          _validating = false;
        });
        HapticFeedback.lightImpact();
      }
    } catch (_) {
      setState(() {
        _error = "Couldn't validate. Try again.";
        _validating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle row
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _success != null
                        ? '✓ Referral code applied'
                        : 'Have a referral code?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          _success != null ? const Color(0xFF2ECC71) : textPrimary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded body
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          textCapitalization:
                              TextCapitalization.characters,
                          enabled: !_validating,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: 1.0,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ENTER CODE',
                            hintStyle: TextStyle(
                              color:
                                  textSecondary.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.elevated
                                : AppColorsLight.elevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.cardBorder
                                    : AppColorsLight.cardBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.orange,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _validating ? null : _apply,
                        child: Container(
                          height: 40,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFB366),
                                AppColors.orange,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: _validating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Apply',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 13, color: Color(0xFFE74C3C)),
                        const SizedBox(width: 4),
                        Text(_error!,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFE74C3C))),
                      ],
                    ),
                  ],
                  if (_success != null && _error == null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 13, color: Color(0xFF2ECC71)),
                        const SizedBox(width: 4),
                        Text(
                          _success!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2ECC71)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.1),
        ],
      ),
    );
  }
}
