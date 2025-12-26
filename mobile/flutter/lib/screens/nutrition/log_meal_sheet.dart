import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/main_shell.dart';

/// Shows the log meal bottom sheet from anywhere in the app
Future<void> showLogMealSheet(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final userId = await ref.read(apiClientProvider).getUserId();

  if (userId == null || !context.mounted) return;

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LogMealSheet(userId: userId, isDark: isDark),
  );

  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;
}

/// Bottom sheet for logging meals with multiple input methods
class LogMealSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const LogMealSheet({super.key, required this.userId, required this.isDark});

  @override
  ConsumerState<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<LogMealSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MealType _selectedMealType = MealType.lunch;
  bool _isLoading = false;
  String? _error;

  final _descriptionController = TextEditingController();
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    // Describe tab is now at index 0 (default)
    _tabController = TabController(length: 5, vsync: this, initialIndex: 0);
    _selectedMealType = _getDefaultMealType();
  }

  MealType _getDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 17) return MealType.snack;
    return MealType.dinner;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.logFoodFromImage(
        userId: widget.userId,
        mealType: _selectedMealType.value,
        imageFile: File(image.path),
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar(response.totalCalories);
        ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _logFromText() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.logFoodFromText(
        userId: widget.userId,
        description: description,
        mealType: _selectedMealType.value,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        // Show rainbow confirmation dialog
        final confirmed = await _showRainbowNutritionConfirmation(response, description);
        if (confirmed == true && mounted) {
          Navigator.pop(context);
          _showSuccessSnackbar(response.totalCalories);
          ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Analyze food from text and return the response for preview
  /// NOTE: This method does NOT set _isLoading to avoid rebuilding and losing _DescribeTab state
  Future<LogFoodResponse?> _analyzeFood() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return null;

    // Don't set _isLoading here - let _DescribeTab manage its own loading state
    // to avoid being unmounted and losing _analyzedResponse
    setState(() {
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.logFoodFromText(
        userId: widget.userId,
        description: description,
        mealType: _selectedMealType.value,
      );

      return response;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return null;
    }
  }

  /// Log an already analyzed food response
  void _logAnalyzedFood(LogFoodResponse response) {
    Navigator.pop(context);
    _showSuccessSnackbar(response.totalCalories);
    ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
  }

  Future<bool?> _showRainbowNutritionConfirmation(LogFoodResponse response, String description) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Rainbow colors for nutrition values
    const caloriesColor = Color(0xFFFF6B6B);  // Red/Coral
    const proteinColor = Color(0xFFFFD93D);   // Yellow/Gold
    const carbsColor = Color(0xFF6BCB77);     // Green
    const fatColor = Color(0xFF4D96FF);       // Blue
    const fiberColor = Color(0xFF9B59B6);     // Purple

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nearBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFFFD93D), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Estimated Nutrition',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant, size: 20, color: textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rainbow nutrition grid
            _RainbowNutritionCard(
              icon: Icons.local_fire_department,
              label: 'Calories',
              value: '${response.totalCalories}',
              unit: 'kcal',
              color: caloriesColor,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RainbowNutritionCard(
                    icon: Icons.fitness_center,
                    label: 'Protein',
                    value: response.proteinG.toStringAsFixed(1),
                    unit: 'g',
                    color: proteinColor,
                    isDark: isDark,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RainbowNutritionCard(
                    icon: Icons.grain,
                    label: 'Carbs',
                    value: response.carbsG.toStringAsFixed(1),
                    unit: 'g',
                    color: carbsColor,
                    isDark: isDark,
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RainbowNutritionCard(
                    icon: Icons.opacity,
                    label: 'Fat',
                    value: response.fatG.toStringAsFixed(1),
                    unit: 'g',
                    color: fatColor,
                    isDark: isDark,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RainbowNutritionCard(
                    icon: Icons.eco,
                    label: 'Fiber',
                    value: (response.fiberG ?? 0).toStringAsFixed(1),
                    unit: 'g',
                    color: fiberColor,
                    isDark: isDark,
                    compact: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'These values are AI estimates based on your description.',
              style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6BCB77),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 18),
                SizedBox(width: 8),
                Text('Log This'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (_hasScanned) return;
    _hasScanned = true;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final product = await repository.lookupBarcode(barcode);

      if (mounted) {
        final confirmed = await _showProductConfirmation(product);
        if (confirmed == true) {
          final response = await repository.logFoodFromBarcode(
            userId: widget.userId,
            barcode: barcode,
            mealType: _selectedMealType.value,
          );

          if (mounted) {
            Navigator.pop(context);
            _showSuccessSnackbar(response.totalCalories);
            ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
          }
        } else {
          setState(() {
            _isLoading = false;
            _hasScanned = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasScanned = false;
        _error = e.toString();
      });
    }
  }

  Future<bool?> _showProductConfirmation(BarcodeProduct product) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nearBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Found Product', style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            if (product.brand != null) ...[
              const SizedBox(height: 4),
              Text(product.brand!, style: TextStyle(color: textMuted)),
            ],
            const SizedBox(height: 16),
            _NutritionInfoRow(
              label: 'Calories',
              value: '${product.caloriesPer100g.toInt()} kcal/100g',
              isDark: isDark,
            ),
            _NutritionInfoRow(
              label: 'Protein',
              value: '${product.proteinPer100g.toStringAsFixed(1)}g/100g',
              isDark: isDark,
            ),
            _NutritionInfoRow(
              label: 'Carbs',
              value: '${product.carbsPer100g.toStringAsFixed(1)}g/100g',
              isDark: isDark,
            ),
            _NutritionInfoRow(
              label: 'Fat',
              value: '${product.fatPer100g.toStringAsFixed(1)}g/100g',
              isDark: isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: teal),
            child: const Text('Log This'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(int calories) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged $calories kcal'),
        backgroundColor: widget.isDark ? AppColors.success : AppColorsLight.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Text(
                  'Log a Meal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Meal type selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: MealType.values.map((type) {
                final isSelected = _selectedMealType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMealType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? teal.withValues(alpha: 0.2) : elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? teal : cardBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(type.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? teal : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.edit, size: 18), text: 'Describe'),
                Tab(icon: Icon(Icons.camera_alt, size: 18), text: 'Photo'),
                Tab(icon: Icon(Icons.mic, size: 18), text: 'Voice'),
                Tab(icon: Icon(Icons.qr_code_scanner, size: 18), text: 'Scan'),
                Tab(icon: Icon(Icons.flash_on, size: 18), text: 'Quick'),
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.error : AppColorsLight.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.error : AppColorsLight.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: isDark ? AppColors.error : AppColorsLight.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: isDark ? AppColors.error : AppColorsLight.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: teal),
                    const SizedBox(height: 16),
                    Text('Analyzing your food...', style: TextStyle(color: textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DescribeTab(
                    controller: _descriptionController,
                    onAnalyze: _analyzeFood,
                    onLog: _logAnalyzedFood,
                    isDark: isDark,
                  ),
                  _PhotoTab(onPickImage: _pickImage, isDark: isDark),
                  _VoiceTab(
                    onSubmit: (text) {
                      _descriptionController.text = text;
                      _logFromText();
                    },
                    isDark: isDark,
                  ),
                  _ScanTab(onBarcodeDetected: _handleBarcodeScan, isDark: isDark),
                  _QuickTab(
                    userId: widget.userId,
                    mealType: _selectedMealType,
                    onLogged: () {
                      Navigator.pop(context);
                      ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Photo Tab
// ─────────────────────────────────────────────────────────────────

class _PhotoTab extends StatelessWidget {
  final void Function(ImageSource) onPickImage;
  final bool isDark;

  const _PhotoTab({required this.onPickImage, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onPickImage(ImageSource.camera),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: teal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt, size: 48, color: teal),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Take a Photo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI will identify and estimate nutrition',
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onPickImage(ImageSource.gallery),
              icon: Icon(Icons.photo_library, color: cyan),
              label: Text('Choose from Gallery', style: TextStyle(color: cyan)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: cyan),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Voice Tab
// ─────────────────────────────────────────────────────────────────

class _VoiceTab extends StatefulWidget {
  final void Function(String) onSubmit;
  final bool isDark;

  const _VoiceTab({required this.onSubmit, required this.isDark});

  @override
  State<_VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<_VoiceTab> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              // Auto-submit if we have text
              if (_recognizedText.isNotEmpty) {
                widget.onSubmit(_recognizedText);
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusMessage = 'Error: ${error.errorMsg}';
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _statusMessage = _speechAvailable ? '' : 'Speech recognition not available';
        });
      }
    } catch (e) {
      debugPrint('Speech init error: $e');
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _statusMessage = 'Could not initialize speech recognition';
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      setState(() => _statusMessage = 'Speech recognition not available');
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _statusMessage = '';
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic button
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(_isListening ? 40 : 32),
                    decoration: BoxDecoration(
                      color: _isListening ? coral.withValues(alpha: 0.2) : teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [BoxShadow(color: coral.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)]
                          : null,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      size: 48,
                      color: _isListening ? coral : teal,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isListening ? 'Listening...' : 'Tap to Speak',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 8),
                Text('Describe what you ate', style: TextStyle(fontSize: 14, color: textMuted)),

                // Show recognized text
                if (_recognizedText.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: teal.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote, size: 16, color: teal),
                            const SizedBox(width: 8),
                            Text('You said:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: teal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recognizedText,
                          style: TextStyle(fontSize: 16, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _recognizedText = '');
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try Again'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () => widget.onSubmit(_recognizedText),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Log This'),
                      ),
                    ],
                  ),
                ] else ...[
                  // Show example when no text recognized
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: elevated, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Example:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
                        const SizedBox(height: 8),
                        Text(
                          '"I had two scrambled eggs with toast and a glass of orange juice"',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status message or tip
          if (_statusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.warning : AppColorsLight.warning).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: isDark ? AppColors.warning : AppColorsLight.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 20, color: teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Speak naturally - AI will estimate nutrition from your description',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Describe Tab - Two-step flow: Analyze → Preview → Log
// ─────────────────────────────────────────────────────────────────

class _DescribeTab extends StatefulWidget {
  final TextEditingController controller;
  final Future<LogFoodResponse?> Function() onAnalyze;
  final void Function(LogFoodResponse) onLog;
  final bool isDark;

  const _DescribeTab({
    required this.controller,
    required this.onAnalyze,
    required this.onLog,
    required this.isDark,
  });

  @override
  State<_DescribeTab> createState() => _DescribeTabState();
}

class _DescribeTabState extends State<_DescribeTab> {
  LogFoodResponse? _analyzedResponse;
  bool _isAnalyzing = false;

  // Rainbow colors for nutrition values
  static const caloriesColor = Color(0xFFFF6B6B);
  static const proteinColor = Color(0xFFFFD93D);
  static const carbsColor = Color(0xFF6BCB77);
  static const fatColor = Color(0xFF4D96FF);
  static const fiberColor = Color(0xFF9B59B6);

  Future<void> _handleAnalyze() async {
    if (widget.controller.text.trim().isEmpty) return;

    debugPrint('🍎 [LogMeal] Starting analysis...');
    setState(() => _isAnalyzing = true);
    final response = await widget.onAnalyze();
    debugPrint('🍎 [LogMeal] Analyze response: $response');
    debugPrint('🍎 [LogMeal] Calories: ${response?.totalCalories}, Protein: ${response?.proteinG}, Carbs: ${response?.carbsG}, Fat: ${response?.fatG}');
    debugPrint('🍎 [LogMeal] mounted: $mounted, setting _analyzedResponse');
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _analyzedResponse = response;
      });
      debugPrint('🍎 [LogMeal] _analyzedResponse set to: $_analyzedResponse');
    }
  }

  void _handleEdit() {
    setState(() => _analyzedResponse = null);
  }

  void _handleLog() {
    if (_analyzedResponse != null) {
      widget.onLog(_analyzedResponse!);
    }
  }

  void _appendText(String text) {
    if (widget.controller.text.isNotEmpty && !widget.controller.text.endsWith(', ')) {
      widget.controller.text += ', ';
    }
    widget.controller.text += text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    // If we have analyzed nutrition, show the preview
    if (_analyzedResponse != null) {
      return _buildNutritionPreview(isDark, textPrimary, textMuted, textSecondary, elevated, teal);
    }

    // Otherwise show the input form
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What did you eat?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            maxLines: 5,
            minLines: 3,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g., 2 eggs, toast with butter, and a glass of orange juice',
              hintStyle: TextStyle(color: textMuted),
              filled: true,
              fillColor: elevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickSuggestion(label: 'Coffee', onTap: () => _appendText('coffee'), isDark: isDark),
              _QuickSuggestion(label: 'Eggs', onTap: () => _appendText('2 eggs'), isDark: isDark),
              _QuickSuggestion(label: 'Toast', onTap: () => _appendText('toast'), isDark: isDark),
              _QuickSuggestion(label: 'Salad', onTap: () => _appendText('salad'), isDark: isDark),
              _QuickSuggestion(label: 'Chicken', onTap: () => _appendText('chicken breast'), isDark: isDark),
              _QuickSuggestion(label: 'Rice', onTap: () => _appendText('1 cup rice'), isDark: isDark),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _handleAnalyze,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(
                _isAnalyzing ? 'Analyzing...' : 'Analyze with AI',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                disabledBackgroundColor: teal.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionPreview(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color textSecondary,
    Color elevated,
    Color teal,
  ) {
    final response = _analyzedResponse!;
    final description = widget.controller.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with edit option
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFFFD93D), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Estimated Nutrition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ),
              TextButton.icon(
                onPressed: _handleEdit,
                icon: Icon(Icons.edit, size: 16, color: textMuted),
                label: Text('Edit', style: TextStyle(color: textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Food description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant, size: 20, color: textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overall Meal Score Card (if available)
          if (response.overallMealScore != null || response.goalAlignmentPercentage != null)
            _OverallMealScoreCard(
              score: response.overallMealScore,
              alignmentPercentage: response.goalAlignmentPercentage,
              isDark: isDark,
            ),
          if (response.overallMealScore != null || response.goalAlignmentPercentage != null)
            const SizedBox(height: 16),

          // Collapsible Food Items Section
          if (response.foodItems.isNotEmpty)
            _CollapsibleFoodItemsSection(
              foodItems: response.foodItemsRanked,
              isDark: isDark,
            ),
          if (response.foodItems.isNotEmpty)
            const SizedBox(height: 16),

          // Nutrition cards
          _RainbowNutritionCard(
            icon: Icons.local_fire_department,
            label: 'Calories',
            value: '${response.totalCalories}',
            unit: 'kcal',
            color: caloriesColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RainbowNutritionCard(
                  icon: Icons.fitness_center,
                  label: 'Protein',
                  value: response.proteinG.toStringAsFixed(1),
                  unit: 'g',
                  color: proteinColor,
                  isDark: isDark,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RainbowNutritionCard(
                  icon: Icons.grain,
                  label: 'Carbs',
                  value: response.carbsG.toStringAsFixed(1),
                  unit: 'g',
                  color: carbsColor,
                  isDark: isDark,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RainbowNutritionCard(
                  icon: Icons.opacity,
                  label: 'Fat',
                  value: response.fatG.toStringAsFixed(1),
                  unit: 'g',
                  color: fatColor,
                  isDark: isDark,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RainbowNutritionCard(
                  icon: Icons.eco,
                  label: 'Fiber',
                  value: (response.fiberG ?? 0).toStringAsFixed(1),
                  unit: 'g',
                  color: fiberColor,
                  isDark: isDark,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Suggestion Card (if available)
          if (response.aiSuggestion != null ||
              (response.encouragements != null && response.encouragements!.isNotEmpty) ||
              (response.warnings != null && response.warnings!.isNotEmpty))
            _AISuggestionCard(
              suggestion: response.aiSuggestion,
              encouragements: response.encouragements,
              warnings: response.warnings,
              recommendedSwap: response.recommendedSwap,
              isDark: isDark,
            ),
          if (response.aiSuggestion != null ||
              (response.encouragements != null && response.encouragements!.isNotEmpty) ||
              (response.warnings != null && response.warnings!.isNotEmpty))
            const SizedBox(height: 16),

          Text(
            'These values are AI estimates based on your description.',
            style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Log button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLog,
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Log This Meal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6BCB77),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSuggestion extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickSuggestion({required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder),
        ),
        child: Text('+ $label', style: TextStyle(fontSize: 12, color: textSecondary)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Scan Tab
// ─────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  final void Function(String) onBarcodeDetected;
  final bool isDark;

  const _ScanTab({required this.onBarcodeDetected, required this.isDark});

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  MobileScannerController? _controller;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_hasDetected) return;
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null) {
                        _hasDetected = true;
                        widget.onBarcodeDetected(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: teal, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Scan a Barcode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Point your camera at a product barcode',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Tab
// ─────────────────────────────────────────────────────────────────

class _QuickTab extends ConsumerWidget {
  final String userId;
  final MealType mealType;
  final VoidCallback onLogged;
  final bool isDark;

  const _QuickTab({
    required this.userId,
    required this.mealType,
    required this.onLogged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionProvider);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final recentItems = <String, Map<String, dynamic>>{};
    for (final log in state.recentLogs.take(20)) {
      for (final item in log.foodItems) {
        if (!recentItems.containsKey(item.name)) {
          recentItems[item.name] = {
            'name': item.name,
            'calories': item.calories ?? 0,
          };
        }
      }
    }

    if (recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'No recent items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textSecondary),
            ),
            const SizedBox(height: 8),
            Text('Log some meals to see them here', style: TextStyle(fontSize: 14, color: textMuted)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'RECENT ITEMS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        ...recentItems.values.take(10).map((item) => _QuickFoodItem(
              name: item['name'] as String,
              calories: item['calories'] as int,
              onTap: () async {
                final repository = ref.read(nutritionRepositoryProvider);
                try {
                  await repository.logFoodFromText(
                    userId: userId,
                    description: item['name'] as String,
                    mealType: mealType.value,
                  );
                  onLogged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to log: $e')),
                    );
                  }
                }
              },
              isDark: isDark,
            )),
      ],
    );
  }
}

class _QuickFoodItem extends StatelessWidget {
  final String name;
  final int calories;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickFoodItem({
    required this.name,
    required this.calories,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                ),
                Text('$calories kcal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: teal)),
                const SizedBox(width: 8),
                Icon(Icons.add_circle, color: teal, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────

class _NutritionInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _NutritionInfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textMuted)),
          Text(value, style: TextStyle(color: textSecondary)),
        ],
      ),
    );
  }
}

/// Rainbow-colored nutrition card for AI estimates
class _RainbowNutritionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;
  final bool compact;

  const _RainbowNutritionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: value,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: ' $unit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Overall Meal Score Card
// ─────────────────────────────────────────────────────────────────

class _OverallMealScoreCard extends StatelessWidget {
  final int? score;
  final int? alignmentPercentage;
  final bool isDark;

  const _OverallMealScoreCard({
    this.score,
    this.alignmentPercentage,
    required this.isDark,
  });

  Color _getScoreColor() {
    if (score == null) return Colors.grey;
    if (score! >= 8) return const Color(0xFF6BCB77);  // Green
    if (score! >= 5) return const Color(0xFFFFD93D);  // Yellow
    return const Color(0xFFFF6B6B);  // Red
  }

  String _getScoreLabel() {
    if (score == null) return 'N/A';
    if (score! >= 8) return 'Excellent';
    if (score! >= 6) return 'Good';
    if (score! >= 4) return 'Neutral';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final scoreColor = _getScoreColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Circular score indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.15),
              border: Border.all(color: scoreColor, width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score?.toString() ?? '-',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    '/10',
                    style: TextStyle(
                      fontSize: 10,
                      color: scoreColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, size: 18, color: scoreColor),
                    const SizedBox(width: 6),
                    Text(
                      'Goal Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getScoreLabel()} - ${score ?? 0}/10',
                  style: TextStyle(
                    fontSize: 12,
                    color: scoreColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (alignmentPercentage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: alignmentPercentage! / 100,
                            backgroundColor: textMuted.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(scoreColor),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$alignmentPercentage%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Goal alignment',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Collapsible Food Items Section
// ─────────────────────────────────────────────────────────────────

class _CollapsibleFoodItemsSection extends StatefulWidget {
  final List<FoodItemRanking> foodItems;
  final bool isDark;

  const _CollapsibleFoodItemsSection({
    required this.foodItems,
    required this.isDark,
  });

  @override
  State<_CollapsibleFoodItemsSection> createState() => _CollapsibleFoodItemsSectionState();
}

class _CollapsibleFoodItemsSectionState extends State<_CollapsibleFoodItemsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.list_alt, size: 20, color: teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.foodItems.length} Food Items',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Tap to ${_isExpanded ? 'hide' : 'see'} details',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: cardBorder),
                ...widget.foodItems.map((item) => _FoodItemRankingCard(
                  item: item,
                  isDark: widget.isDark,
                )),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _FoodItemRankingCard extends StatelessWidget {
  final FoodItemRanking item;
  final bool isDark;

  const _FoodItemRankingCard({required this.item, required this.isDark});

  Color _getScoreColor() {
    if (item.goalScore == null) return Colors.grey;
    if (item.goalScore! >= 8) return const Color(0xFF6BCB77);  // Green
    if (item.goalScore! >= 5) return const Color(0xFFFFD93D);  // Yellow
    return const Color(0xFFFF6B6B);  // Red
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final scoreColor = _getScoreColor();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Score badge
          if (item.goalScore != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  '${item.goalScore}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 36),
          const SizedBox(width: 12),
          // Food info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                if (item.amount != null)
                  Text(
                    item.amount!,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                if (item.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.reason!,
                      style: TextStyle(
                        fontSize: 11,
                        color: scoreColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Calories
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.calories ?? 0}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                'kcal',
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AI Suggestion Card
// ─────────────────────────────────────────────────────────────────

class _AISuggestionCard extends StatelessWidget {
  final String? suggestion;
  final List<String>? encouragements;
  final List<String>? warnings;
  final String? recommendedSwap;
  final bool isDark;

  const _AISuggestionCard({
    this.suggestion,
    this.encouragements,
    this.warnings,
    this.recommendedSwap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    const encourageColor = Color(0xFF6BCB77);  // Green
    const warningColor = Color(0xFFFF6B6B);    // Red
    const swapColor = Color(0xFF4D96FF);       // Blue

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teal.withValues(alpha: 0.1),
            teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology, size: 20, color: teal),
              ),
              const SizedBox(width: 10),
              Text(
                'Coach Tip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          // Encouragements
          if (encouragements != null && encouragements!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...encouragements!.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.thumb_up, size: 14, color: encourageColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e,
                      style: TextStyle(fontSize: 13, color: encourageColor),
                    ),
                  ),
                ],
              ),
            )),
          ],

          // Warnings
          if (warnings != null && warnings!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings!.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, size: 14, color: warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w,
                      style: TextStyle(fontSize: 13, color: warningColor),
                    ),
                  ),
                ],
              ),
            )),
          ],

          // General suggestion
          if (suggestion != null && suggestion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              suggestion!,
              style: TextStyle(fontSize: 13, color: textPrimary),
            ),
          ],

          // Recommended swap
          if (recommendedSwap != null && recommendedSwap!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: swapColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: swapColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 18, color: swapColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendedSwap!,
                      style: TextStyle(
                        fontSize: 12,
                        color: swapColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
