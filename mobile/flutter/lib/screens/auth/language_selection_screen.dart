import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';
import '../../data/repositories/auth_repository.dart';

/// Language selection screen shown before welcome slides
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  Language _selectedLanguage = SupportedLanguages.english;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isDropdownOpen = false;

  // Sign-in state
  bool _isLoading = false;
  String? _loadingMessage;
  final List<String> _loadingMessages = [
    'Connecting to server...',
    'Waking up backend (cold start)...',
    'Almost there...',
    'Verifying credentials...',
  ];

  List<Language> get _filteredLanguages {
    if (_searchQuery.isEmpty) {
      return SupportedLanguages.all;
    }
    return SupportedLanguages.all.where((lang) {
      final query = _searchQuery.toLowerCase();
      return lang.name.toLowerCase().contains(query) ||
          lang.nativeName.toLowerCase().contains(query) ||
          lang.code.toLowerCase().contains(query);
    }).toList();
  }

  void _selectLanguage(Language language) {
    HapticFeedback.lightImpact();

    // Show message for coming soon languages
    if (language.isComingSoon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${language.name} support coming soon!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.purple,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedLanguage = language;
      _isDropdownOpen = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> _continue() async {
    HapticFeedback.mediumImpact();
    await ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);
    if (mounted) {
      context.go('/welcome');
    }
  }

  Future<void> _signInWithGoogle() async {
    // Save language preference first
    await ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);

    setState(() {
      _isLoading = true;
      _loadingMessage = _loadingMessages[0];
    });

    // Cycle through loading messages for long waits (Render cold start)
    int messageIndex = 0;
    final messageTimer = Stream.periodic(
      const Duration(seconds: 3),
      (_) => _loadingMessages[++messageIndex % _loadingMessages.length],
    ).listen((message) {
      if (mounted && _isLoading) {
        setState(() => _loadingMessage = message);
      }
    });

    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();
    } finally {
      messageTimer.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App branding
              _buildBranding(isDark),

              const Spacer(flex: 1),

              // Language selection
              _buildLanguageSection(isDark, textSecondary),

              const Spacer(flex: 1),

              // Sign in section
              _buildSignInSection(isDark, textSecondary),

              const SizedBox(height: 16),

              // Or continue to learn more
              _buildContinueSection(isDark, textSecondary),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(bool isDark) {
    return Column(
      children: [
        // App icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.cyanGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppColors.pureBlack,
            size: 48,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8), delay: 200.ms),

        const SizedBox(height: 24),

        // App name with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.cyan, AppColors.purple],
          ).createShader(bounds),
          child: Text(
            'AI Fitness Coach',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Your personalized workout companion',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildLanguageSection(bool isDark, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Select Language',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 12),

        // Language dropdown
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isDropdownOpen = !_isDropdownOpen);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDropdownOpen ? AppColors.cyan : cardBorder,
                width: _isDropdownOpen ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Selected language flag/icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _selectedLanguage.code.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Language name - native name (English name)
                Expanded(
                  child: Text(
                    _selectedLanguage.name == _selectedLanguage.nativeName
                        ? _selectedLanguage.nativeName
                        : '${_selectedLanguage.nativeName} (${_selectedLanguage.name})',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                // Dropdown arrow
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isDropdownOpen ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

        // Dropdown options
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isDropdownOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search languages...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.glassSurface
                          : AppColorsLight.glassSurface,
                    ),
                  ),
                ),
                // Language list
                ..._filteredLanguages.map((language) {
                  final isSelected = language == _selectedLanguage;
                  return InkWell(
                    onTap: () => _selectLanguage(language),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.cyan.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border(
                          top: BorderSide(
                            color: cardBorder.withOpacity(0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Language code badge
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.cyan.withOpacity(0.2)
                                  : (isDark
                                      ? AppColors.glassSurface
                                      : AppColorsLight.glassSurface),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                language.code.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected
                                      ? AppColors.cyan
                                      : textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Language name - native name (English name)
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  language.name == language.nativeName
                                      ? language.nativeName
                                      : '${language.nativeName} (${language.name})',
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.cyan
                                        : (isDark
                                            ? AppColors.textPrimary
                                            : AppColorsLight.textPrimary),
                                  ),
                                ),
                                if (language.isComingSoon) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.purple.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.purple.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Text(
                                      'Coming Soon',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.purple,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Checkmark
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.cyan,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_filteredLanguages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No languages found',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInSection(bool isDark, Color textSecondary) {
    final authState = ref.watch(authStateProvider);
    final buttonColor = isDark ? Colors.white : AppColorsLight.elevated;
    final buttonTextColor = isDark ? Colors.black87 : AppColorsLight.textPrimary;

    return Column(
      children: [
        // Google Sign In button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: buttonTextColor,
              disabledBackgroundColor: buttonColor.withOpacity(0.5),
              elevation: isDark ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: isDark
                    ? BorderSide.none
                    : BorderSide(color: AppColorsLight.cardBorder, width: 1),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.black54 : AppColorsLight.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _loadingMessage ?? 'Signing in...',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.black54 : AppColorsLight.textMuted,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: buttonTextColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

        // Error message
        if (authState.status == AuthStatus.error && authState.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authState.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().shake(),
      ],
    );
  }

  Widget _buildContinueSection(bool isDark, Color textSecondary) {
    return Column(
      children: [
        // Divider with "or"
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 700.ms),

        const SizedBox(height: 16),

        // Learn more button
        GestureDetector(
          onTap: _continue,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Learn more about AI Fitness Coach',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.cyan,
                size: 18,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }
}
