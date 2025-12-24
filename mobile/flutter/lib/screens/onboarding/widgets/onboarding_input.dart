import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_colors.dart';

/// Text input area for the conversational onboarding screen.
class OnboardingInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool showDayPicker;
  final ValueChanged<String> onSubmit;

  const OnboardingInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.showDayPicker,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: colors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading && !showDayPicker,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: colors.textMuted),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.cyan),
                ),
              ),
              onSubmitted: onSubmit,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onSubmit(controller.text);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: colors.cyanGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.cyan.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
