import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'navigation/app_router.dart';
import 'widgets/floating_chat/global_chat_bubble.dart';

class AiFitnessCoachApp extends ConsumerWidget {
  const AiFitnessCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AI Fitness Coach',
      debugShowCheckedModeBanner: false,
      theme: AppThemeLight.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Wrap the entire app with GlobalChatBubble for Messenger-style chat
        // This ensures the bubble appears on ALL screens
        return GlobalChatBubble(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
