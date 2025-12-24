import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Header for the conversational onboarding screen.
class OnboardingHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onStartOver;

  const OnboardingHeader({
    super.key,
    required this.onBack,
    required this.onStartOver,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: colors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onBack();
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
            tooltip: 'Go back',
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: colors.cyanGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.cyan.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Fitness Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'Setting up your personalized plan...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: colors.textSecondary,
            ),
            onSelected: (value) {
              if (value == 'start_over') {
                onStartOver();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'start_over',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: colors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    const Text('Start Over'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
