import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';

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

              const Spacer(flex: 2),

              // Continue button
              _buildContinueButton(isDark),

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

  Widget _buildContinueButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _continue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
          shadowColor: AppColors.cyan.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.2, delay: 700.ms)
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
        )
        .shimmer(
          delay: 1500.ms,
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.2),
        );
  }
}
