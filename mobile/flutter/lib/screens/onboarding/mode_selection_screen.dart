import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/accessibility/accessibility_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../widgets/senior/senior_button.dart';
import 'widgets/foldable_quiz_scaffold.dart';

/// Mode selection screen shown during onboarding
/// After user provides name/age, AI asks them to choose Normal or Senior mode
/// If age >= 55, recommends Senior mode
class ModeSelectionScreen extends ConsumerStatefulWidget {
  final int? userAge;
  final VoidCallback? onNormalSelected;
  final VoidCallback? onSeniorSelected;

  const ModeSelectionScreen({
    super.key,
    this.userAge,
    this.onNormalSelected,
    this.onSeniorSelected,
  });

  @override
  ConsumerState<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen> {
  AccessibilityMode? _selectedMode;
  bool _isSaving = false;

  bool get _recommendSenior => (widget.userAge ?? 0) >= 55;

  Future<void> _selectMode(AccessibilityMode mode) async {
    setState(() {
      _selectedMode = mode;
      _isSaving = true;
    });

    try {
      // Save accessibility mode
      await ref.read(accessibilityProvider.notifier).setMode(mode);

      if (mounted) {
        if (mode == AccessibilityMode.senior) {
          widget.onSeniorSelected?.call();
          // Navigate to senior onboarding (simplified visual flow)
          context.go('/senior-onboarding');
        } else {
          widget.onNormalSelected?.call();
          // Continue with normal AI onboarding
          context.pop();
        }
      }
    } catch (e) {
      debugPrint('Error selecting mode: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: 'Choose Your Experience',
          headerSubtitle: 'Select the mode that works best for you',
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 1),

                // Show header inline only on phone
                Consumer(builder: (context, ref, _) {
                  final windowState = ref.watch(windowModeProvider);
                  if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Experience',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select the mode that works best for you',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                }),

                // Normal Mode Option
                SeniorModeSelectionButton(
                  title: 'Normal Mode',
                  subtitle: 'Full features, standard design',
                  icon: Icons.apps,
                  isSelected: _selectedMode == AccessibilityMode.standard,
                  isRecommended: !_recommendSenior,
                  onPressed: () => _selectMode(AccessibilityMode.standard),
                ),

                const SizedBox(height: 20),

                // Senior Mode Option
                SeniorModeSelectionButton(
                  title: 'Senior Mode',
                  subtitle: 'Larger text, simpler navigation',
                  icon: Icons.accessibility_new,
                  isSelected: _selectedMode == AccessibilityMode.senior,
                  isRecommended: _recommendSenior,
                  onPressed: () => _selectMode(AccessibilityMode.senior),
                ),

                const Spacer(flex: 2),

                // Help text
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'You can always change this later in Settings',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? const Color(0xFFAAAAAA)
                                : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Loading indicator
                if (_isSaving)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget to show mode selection as quick reply buttons during AI onboarding
class ModeSelectionQuickReplies extends StatelessWidget {
  final int? userAge;
  final ValueChanged<AccessibilityMode> onModeSelected;

  const ModeSelectionQuickReplies({
    super.key,
    this.userAge,
    required this.onModeSelected,
  });

  bool get _recommendSenior => (userAge ?? 0) >= 55;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recommendSenior)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Senior Mode recommended for you',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ModeButton(
              label: 'Normal Mode',
              isRecommended: !_recommendSenior,
              onTap: () => onModeSelected(AccessibilityMode.standard),
            ),
            _ModeButton(
              label: 'Senior Mode',
              isRecommended: _recommendSenior,
              onTap: () => onModeSelected(AccessibilityMode.senior),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isRecommended;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isRecommended
          ? AppColors.accent.withOpacity(0.15)
          : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5)),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isRecommended
                  ? AppColors.accent
                  : (isDark
                      ? const Color(0xFF444444)
                      : const Color(0xFFDDDDDD)),
              width: isRecommended ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isRecommended
                      ? AppColors.accent
                      : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.star,
                  size: 18,
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
