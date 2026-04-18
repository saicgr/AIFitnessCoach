import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'edit_personal_info_sheet_ui.dart';


/// Bottom sheet for editing personal information.
class EditPersonalInfoSheet extends ConsumerStatefulWidget {
  const EditPersonalInfoSheet({super.key});

  @override
  ConsumerState<EditPersonalInfoSheet> createState() => _EditPersonalInfoSheetState();
}

class _EditPersonalInfoSheetState extends ConsumerState<EditPersonalInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  String? _email;
  String _selectedGender = 'male';
  String _selectedActivityLevel = 'moderately_active';
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  double? _heightCm;
  double? _weightKg;
  double? _targetWeightKg;

  bool _isHeightMetric = true;
  bool _isWeightMetric = true;

  String? _currentPhotoUrl;
  File? _selectedPhotoFile;
  final ImagePicker _imagePicker = ImagePicker();

  static const _genderOptions = ['male', 'female', 'other'];
  static const _activityLevels = [
    ('sedentary', 'Sedentary', 'Little or no exercise'),
    ('lightly_active', 'Lightly Active', '1-3 days/week'),
    ('moderately_active', 'Moderately Active', '3-5 days/week'),
    ('very_active', 'Very Active', '6-7 days/week'),
    ('extremely_active', 'Extremely Active', 'Athlete level'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _refreshAndLoadProfile();
  }

  Future<void> _refreshAndLoadProfile() async {
    await ref.read(authStateProvider.notifier).refreshUser();
    _loadCurrentProfile();
    _loadBio();
  }

  Future<void> _loadBio() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('${ApiConstants.users}/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        final bio = userData['bio'] as String?;
        if (mounted && bio != null && bio.isNotEmpty) {
          setState(() {
            _bioController.text = bio;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading bio: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadCurrentProfile() {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    if (user != null) {
      setState(() {
        _nameController.text = user.displayName;
        _ageController.text = user.age?.toString() ?? '';
        _selectedGender = user.gender ?? 'male';
        _selectedActivityLevel = user.activityLevel ?? 'moderately_active';
        _heightCm = user.heightCm;
        _weightKg = user.weightKg;
        _targetWeightKg = user.targetWeightKg;
        _currentPhotoUrl = user.photoUrl;
        _email = user.email;
        _emailController.text = user.email ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhotoFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('❌ [EditProfile] Error picking image: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to pick image: $e');
      }
    }
  }

  void _showImageSourceDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: isDark ? AppColors.accent : AppColorsLight.accent),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: isDark ? AppColors.accent : AppColorsLight.accent),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_currentPhotoUrl != null || _selectedPhotoFile != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removePhoto() async {
    setState(() {
      _selectedPhotoFile = null;
      _currentPhotoUrl = null;
    });
  }

  /// Upload photo to S3. Returns true on success, false on failure.
  Future<bool> _uploadPhoto() async {
    if (_selectedPhotoFile == null) return false;

    setState(() => _isUploadingPhoto = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      debugPrint('🔍 [EditProfile] Uploading photo to ${ApiConstants.users}/$userId/photo');
      final response = await apiClient.uploadFile(
        '${ApiConstants.users}/$userId/photo',
        _selectedPhotoFile!,
        fieldName: 'file',
      );

      debugPrint('🔍 [EditProfile] Upload response status: ${response.statusCode}');
      debugPrint('🔍 [EditProfile] Upload response data: ${response.data}');

      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final photoUrl = data['photo_url'] as String?;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          setState(() {
            _currentPhotoUrl = photoUrl;
            _selectedPhotoFile = null;
          });
          debugPrint('✅ [EditProfile] Photo uploaded successfully: $photoUrl');
          // Refresh auth state so the profile header reflects the new photo immediately
          await ref.read(authStateProvider.notifier).refreshUser();
          return true;
        }
      }
      debugPrint('⚠️ [EditProfile] Upload response missing photo_url');
      if (mounted) {
        AppSnackBar.error(context, 'Photo upload failed — no URL returned');
      }
      return false;
    } catch (e) {
      debugPrint('❌ [EditProfile] Error uploading photo: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to upload photo: $e');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      // Auto-upload photo if user picked one but hasn't uploaded yet
      if (_selectedPhotoFile != null) {
        debugPrint('🔍 [EditProfile] Auto-uploading photo before save...');
        final uploadSuccess = await _uploadPhoto();
        if (!uploadSuccess) {
          debugPrint('⚠️ [EditProfile] Photo upload failed, continuing with profile save');
        }
      }

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'activity_level': _selectedActivityLevel,
        'bio': _bioController.text.trim(),
      };

      if (_heightCm != null) {
        data['height_cm'] = _heightCm;
      }
      if (_weightKg != null) {
        data['weight_kg'] = _weightKg;
      }
      if (_targetWeightKg != null) {
        data['target_weight_kg'] = _targetWeightKg;
      }
      if (_ageController.text.isNotEmpty) {
        data['age'] = int.tryParse(_ageController.text);
      }

      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: data,
      );

      // If email changed, update via Supabase Auth (sends confirmation link)
      bool emailChanged = false;
      final newEmail = _emailController.text.trim();
      if (newEmail.isNotEmpty && newEmail != _email) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(email: newEmail),
          );
          emailChanged = true;
          debugPrint('✅ [EditProfile] Email update requested, confirmation link sent');
        } catch (e) {
          debugPrint('❌ [EditProfile] Email update failed: $e');
          if (mounted) {
            AppSnackBar.error(context, 'Email update failed: $e');
          }
        }
      }

      await ref.read(authStateProvider.notifier).refreshUser();
      debugPrint('✅ [EditProfile] Profile saved and user refreshed');

      if (mounted) {
        // Show snackbar BEFORE popping so it attaches to a valid scaffold
        AppSnackBar.success(
          context,
          emailChanged
              ? 'Profile updated. Check your new email for a confirmation link.'
              : 'Profile updated successfully',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ [EditProfile] Save profile error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.error(context, 'Failed to update profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Respect the user's selected accent from AccentColorScope — falls back to orange
    final accentColor = AccentColorScope.of(context).getColor(isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => GlassSheet(
        showHandle: false,
        child: Column(
          children: [
            _buildHandle(textMuted),
            _buildTitle(context, accentColor),
            if (_isLoading)
              Expanded(child: Center(child: CircularProgressIndicator(color: accentColor)))
            else
              _buildForm(
                scrollController,
                isDark,
                elevatedColor,
                textMuted,
                textSecondary,
                cardBorder,
                accentColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(Color textMuted) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: textMuted,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, Color cyan) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: cyan),
          const SizedBox(width: 12),
          Text(
            'Edit Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cyan),
                  )
                : Text('Save', style: TextStyle(color: cyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    ScrollController scrollController,
    bool isDark,
    Color elevatedColor,
    Color textMuted,
    Color textSecondary,
    Color cardBorder,
    Color cyan,
  ) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Expanded(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoSection(isDark, elevatedColor, cardBorder, textMuted, cyan),
              const SizedBox(height: 20),
              _buildEmailField(isDark, elevatedColor, cardBorder, textMuted, cyan),
              const SizedBox(height: 14),
              _buildNameAgeRow(isDark, elevatedColor, cardBorder, textMuted, cyan),
              const SizedBox(height: 14),
              _buildBioField(isDark, elevatedColor, cardBorder, textMuted, cyan),
              const SizedBox(height: 14),
              _buildGenderSelector(elevatedColor, cardBorder, textSecondary, cyan, textMuted),
              const SizedBox(height: 14),
              _buildHeightWeightRow(isDark, elevatedColor, cardBorder, textMuted, cyan),
              const SizedBox(height: 14),
              _buildTargetWeight(isDark, elevatedColor, cardBorder, textMuted, cyan),
              const SizedBox(height: 14),
              _buildActivityLevel(elevatedColor, cardBorder, textMuted, textSecondary, cyan),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(bool isDark, Color elevatedColor, Color cardBorder, Color textMuted, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('EMAIL', textMuted, icon: Icons.mail_outline, accent: accent),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _emailController,
          hint: 'your@email.com',
          isDark: isDark,
          elevatedColor: elevatedColor,
          cardBorder: cardBorder,
          accent: accent,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty && !value.contains('@')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNameAgeRow(bool isDark, Color elevatedColor, Color cardBorder, Color textMuted, Color accent) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('NAME', textMuted, icon: Icons.person_outline, accent: accent),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _nameController,
                hint: 'Your name',
                isDark: isDark,
                elevatedColor: elevatedColor,
                cardBorder: cardBorder,
                accent: accent,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('AGE', textMuted, icon: Icons.cake_outlined, accent: accent),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _ageController,
                hint: '25',
                isDark: isDark,
                elevatedColor: elevatedColor,
                cardBorder: cardBorder,
                accent: accent,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioField(bool isDark, Color elevatedColor, Color cardBorder, Color textMuted, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('BIO', textMuted, icon: Icons.notes_rounded, accent: accent),
        const SizedBox(height: 6),
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          enabled: !_isSaving,
          style: const TextStyle(fontSize: 14),
          // Ensure the field scrolls above the keyboard when focused inside
          // the DraggableScrollableSheet, which doesn't auto-resize.
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 120,
          ),
          decoration: InputDecoration(
            hintText: 'Tell us about yourself...',
            hintStyle: TextStyle(
              color: textMuted.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: elevatedColor,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(
    Color elevatedColor,
    Color cardBorder,
    Color textSecondary,
    Color cyan,
    Color textMuted,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('GENDER', textMuted, icon: Icons.wc_rounded, accent: cyan),
        const SizedBox(height: 10),
        Row(
          children: _genderOptions.map((gender) {
            final isSelected = _selectedGender == gender;
            final label = gender[0].toUpperCase() + gender.substring(1);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: gender == _genderOptions.last ? 0 : 8,
                ),
                child: GestureDetector(
                  onTap: _isSaving
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedGender = gender);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [cyan, cyan.withValues(alpha: 0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? cyan : cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeightWeightRow(
    bool isDark,
    Color elevatedColor,
    Color cardBorder,
    Color textMuted,
    Color cyan,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildUnitInput(
            label: 'HEIGHT',
            value: _heightCm,
            isMetric: _isHeightMetric,
            onMetricChanged: (isMetric) => setState(() => _isHeightMetric = isMetric),
            onValueChanged: (value) => setState(() => _heightCm = value),
            metricUnit: 'cm',
            imperialUnit: 'ft',
            isHeight: true,
            isDark: isDark,
            elevatedColor: elevatedColor,
            cardBorder: cardBorder,
            textMuted: textMuted,
            cyan: cyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUnitInput(
            label: 'WEIGHT',
            value: _weightKg,
            isMetric: _isWeightMetric,
            onMetricChanged: (isMetric) => setState(() => _isWeightMetric = isMetric),
            onValueChanged: (value) => setState(() => _weightKg = value),
            metricUnit: 'kg',
            imperialUnit: 'lbs',
            isHeight: false,
            isDark: isDark,
            elevatedColor: elevatedColor,
            cardBorder: cardBorder,
            textMuted: textMuted,
            cyan: cyan,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetWeight(
    bool isDark,
    Color elevatedColor,
    Color cardBorder,
    Color textMuted,
    Color cyan,
  ) {
    return _buildUnitInput(
      label: 'TARGET WEIGHT',
      value: _targetWeightKg,
      isMetric: _isWeightMetric,
      onMetricChanged: (isMetric) => setState(() => _isWeightMetric = isMetric),
      onValueChanged: (value) => setState(() => _targetWeightKg = value),
      metricUnit: 'kg',
      imperialUnit: 'lbs',
      isHeight: false,
      isDark: isDark,
      elevatedColor: elevatedColor,
      cardBorder: cardBorder,
      textMuted: textMuted,
      cyan: cyan,
    );
  }

  Widget _buildActivityLevel(
    Color elevatedColor,
    Color cardBorder,
    Color textMuted,
    Color textSecondary,
    Color cyan,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACTIVITY LEVEL', textMuted, icon: Icons.directions_run_rounded, accent: cyan),
        const SizedBox(height: 10),
        ..._activityLevels.map((entry) {
          final (value, title, subtitle) = entry;
          final isSelected = _selectedActivityLevel == value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _isSaving
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedActivityLevel = value);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            cyan.withValues(alpha: 0.22),
                            cyan.withValues(alpha: 0.10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : elevatedColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cyan : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? cyan : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? cyan : textMuted,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? cyan : textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Onboarding-style label: rounded icon badge + Title Case label (16px w600).
  Widget _buildSectionTitle(String title, Color textMuted, {IconData? icon, Color? accent}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    // Normalize ALL-CAPS tokens to Title Case so the Edit Profile sheet matches
    // the onboarding wording style ("Bio" not "BIO").
    final display = title
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );
    if (icon == null || accent == null) {
      return Text(display, style: labelStyle);
    }
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: accent),
        ),
        const SizedBox(width: 8),
        Text(display, style: labelStyle),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color elevatedColor,
    required Color cardBorder,
    required Color accent,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isSaving,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      cursorColor: accent,
      scrollPadding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 120,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: elevatedColor,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
