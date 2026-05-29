import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import 'onboarding_experiments.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import 'cycle_onboarding_sheet.dart';
import 'pre_auth_quiz_screen.dart';

import '../../l10n/generated/app_localizations.dart';
/// Personal Info — name + date-of-birth, collected post-sign-in.
///
/// Onboarding v5.1.1: Name and DOB are the only fields that genuinely need
/// to be collected here; gender, height, current weight, and goal weight
/// were already captured on the pre-auth quiz body-metrics gate
/// ([QuizPersonalizationGate]). The save flow PUTs all five fields together
/// so [User.isPersonalInfoComplete] flips true on a single round-trip and
/// the router advances to /coach-selection.
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _nameCtrl = TextEditingController();
  String? _nameError;
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // If a previous run wrote a name to local quiz state (legacy v5.1
    // path), seed it. Strip the "User" backend default which would
    // otherwise feel uncannily prefilled.
    final seed = ref.read(preAuthQuizProvider).name?.trim() ?? '';
    if (seed.isNotEmpty && seed.toLowerCase() != 'user') {
      _nameCtrl.text = seed;
    }
    _dateOfBirth = ref.read(preAuthQuizProvider).dateOfBirth;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int? get _age {
    final dob = _dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String? _validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return 'Please enter a real name';
    if (RegExp(r'^(.)\1+$').hasMatch(trimmed.toLowerCase())) {
      return 'Please enter a real name';
    }
    const fakes = {
      'test', 'fake', 'user', 'name', 'noname', 'n/a', 'na', 'none',
      'unknown', 'anon', 'anonymous', 'admin', 'temp', 'demo',
      'asdf', 'qwerty', 'zxcv', 'abcd',
    };
    if (fakes.contains(trimmed.toLowerCase())) {
      return 'Please enter your real name';
    }
    return null;
  }

  bool get _canContinue {
    final ageOk = _age != null && _age! >= 16;
    return _nameCtrl.text.trim().isNotEmpty &&
        _nameError == null &&
        _dateOfBirth != null &&
        ageOk &&
        !_saving;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      helpText: 'Date of birth',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _save() async {
    if (!_canContinue) return;

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final quizData = ref.read(preAuthQuizProvider);

    // Quiz body-metrics gate is REQUIRED upstream. If somehow we landed
    // here without it (deep link, manual nav), bounce back to the quiz
    // rather than write a partial user record that would loop the router.
    if (quizData.gender == null ||
        quizData.heightCm == null ||
        quizData.weightKg == null) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).personalInfoPleaseCompleteTheBody)),
        );
        context.go('/pre-auth-quiz');
      }
      return;
    }

    try {
      // Persist locally so a re-entry (e.g. the user back-buttons here
      // before coach-selection completes) re-prefills name + DOB.
      await ref.read(preAuthQuizProvider.notifier).setBodyMetrics(
            name: name,
            dateOfBirth: _dateOfBirth,
            gender: quizData.gender,
            heightCm: quizData.heightCm!,
            weightKg: quizData.weightKg!,
            goalWeightKg: quizData.goalWeightKg ?? quizData.weightKg!,
            useMetric: quizData.useMetricUnits,
          );

      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        throw Exception('Missing user id — sign-in did not complete.');
      }

      // Single PUT writes name + DOB (this screen) + the quiz body
      // metrics so User.isPersonalInfoComplete flips true on the next
      // refresh and the router advances to /coach-selection.
      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {
          'name': name,
          'date_of_birth': _dateOfBirth!.toIso8601String().split('T').first,
          'gender': quizData.gender,
          'height_cm': quizData.heightCm,
          'weight_kg': quizData.weightKg,
          'target_weight_kg': quizData.goalWeightKg ?? quizData.weightKg,
        },
      );
      debugPrint('✅ [PersonalInfo] Saved name + DOB + body metrics');

      await ref.read(authStateProvider.notifier).refreshUser();

      ref.read(posthogServiceProvider).capture(
        eventName: 'onboarding_personal_info_completed',
        properties: <String, Object>{
          'has_dob': _dateOfBirth != null,
          if (_age != null) 'age': _age!,
        },
      );

      // Optional cycle-tracking setup — offered right after the gender
      // question per the cycle plan's gender-gating table. female → auto;
      // non-binary / other / prefer-not-to-say → behind a gentle opt-in;
      // male → never offered. The feature gate downstream is
      // `menstrual_tracking_enabled`, never gender — this step just sets it.
      if (mounted) {
        await _maybeOfferCycleSetup(userId, quizData.gender);
      }

      if (mounted) {
        // EXPERIMENT (default OFF): in the post-paywall treatment, personal-info
        // is the last step before the commitment pact (coach-selection + paywall
        // already happened). Otherwise it precedes coach-selection as before.
        context.go(OnboardingExperiments.personalInfoAfterPaywall
            ? '/commitment-pact'
            : '/coach-selection');
      }
    } catch (e, st) {
      debugPrint('❌ [PersonalInfo] Save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Offer the optional cycle-tracking setup step based on the user's gender.
  ///
  ///  * `female` → the setup sheet opens automatically.
  ///  * `non_binary` / `other` / `prefer_not_to_say` → a gentle yes/no first
  ///    ("Do you track a menstrual cycle?"); only a "yes" opens the sheet.
  ///  * `male` (or unknown) → never offered.
  ///
  /// Skipping leaves `menstrual_tracking_enabled` off — the user can still
  /// turn cycle tracking on later from Settings. No cycle data is sent to
  /// analytics; only a content-free completion event name is emitted.
  Future<void> _maybeOfferCycleSetup(String userId, String? gender) async {
    final g = gender?.toLowerCase();
    if (g == null || g == 'male') return; // never offered to male users

    bool proceed = g == 'female';
    if (!proceed) {
      // Optional opt-in for non-binary / other / prefer-not-to-say.
      final answer = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor:
                isDark ? AppColors.surface : AppColorsLight.surface,
            title: Text(AppLocalizations.of(context).personalInfoDoYouTrackA),
            content: const Text(
              'Zealova can predict your cycle and adapt workouts and '
              'nutrition around it. Entirely optional — you can change '
              'this any time in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppLocalizations.of(context).personalInfoNoThanks),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(AppLocalizations.of(context).personalInfoYesSetItUp),
              ),
            ],
          );
        },
      );
      proceed = answer == true;
    }

    if (!proceed || !mounted) return;

    final completed = await CycleOnboardingSheet.show(context, userId: userId);
    if (completed == true) {
      // Content-free event name only — never any cycle data.
      ref.read(posthogServiceProvider).capture(
        eventName: 'cycle_onboarding_completed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final fill = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final border = isDark
        ? AppColors.cardBorder
        : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      // resizeToAvoidBottomInset: true is the default — keyboard pushes the
      // body up, which on small phones (PLG110, ~5" screens) overflowed the
      // unscrolled Column by ~45-56px (Sentry FITWIZ-FLUTTER-7B / 7C).
      // Outer Scaffold + inner Expanded(SingleChildScrollView) lets the form
      // scroll under the keyboard while keeping the Continue button pinned.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // BouncingScrollPhysics so the form feels native on iOS too.
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).personalInfoACoupleFinalDetails,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).personalInfoWeUseTheseTo,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 28),

              // ── Name
              Text(
                AppLocalizations.of(context).personalInfoYourName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                onChanged: (v) {
                  setState(() {
                    _nameError = v.isEmpty ? null : _validateName(v);
                  });
                },
                style: TextStyle(
                  fontSize: 16,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).personalInfoFirstName,
                  hintStyle: TextStyle(color: textSecondary, fontSize: 16),
                  filled: true,
                  fillColor: fill,
                  errorText: _nameError,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // ── Date of birth
              Text(
                AppLocalizations.of(context).personalInfoDateOfBirth,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateOfBirth,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: textSecondary, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dateOfBirth == null
                              ? 'Pick your birth date'
                              : '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}'
                                  '${_age != null ? "  ·  age $_age" : ""}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _dateOfBirth == null ? textSecondary : textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: textSecondary),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 280.ms),

              if (_dateOfBirth != null && (_age ?? 0) < 16) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).personalInfoYouMustBeAt,
                  style: TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ],
                      // Bottom breathing room inside the scroll area so the
                      // last field doesn't sit flush against the pinned button.
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Continue (pinned at bottom of outer Column)
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _canContinue ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context).onboardingContinueButton,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 360.ms),
            ],
          ),
        ),
      ),
    );
  }
}
