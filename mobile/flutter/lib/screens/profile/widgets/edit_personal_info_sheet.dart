import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';

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
    _refreshAndLoadProfile();
  }

  Future<void> _refreshAndLoadProfile() async {
    await ref.read(authStateProvider.notifier).refreshUser();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
    );
  }

  Future<void> _removePhoto() async {
    setState(() {
      _selectedPhotoFile = null;
      _currentPhotoUrl = null;
    });
  }

  Future<void> _uploadPhoto() async {
    if (_selectedPhotoFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      final response = await apiClient.uploadFile(
        '${ApiConstants.users}/$userId/photo',
        _selectedPhotoFile!,
        fieldName: 'file',
      );

      if (response.data != null && response.data['photo_url'] != null) {
        setState(() {
          _currentPhotoUrl = response.data['photo_url'];
          _selectedPhotoFile = null;
        });
        debugPrint('✅ [EditProfile] Photo uploaded successfully');
      }
    } catch (e) {
      debugPrint('❌ [EditProfile] Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'activity_level': _selectedActivityLevel,
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

      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.elevated;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use monochrome accent
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
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
    return Expanded(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoSection(isDark, elevatedColor, cardBorder, textMuted, cyan),
              const SizedBox(height: 20),
              _buildNameAgeRow(isDark, elevatedColor, cardBorder, textMuted),
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

  Widget _buildPhotoSection(
    bool isDark,
    Color elevatedColor,
    Color cardBorder,
    Color textMuted,
    Color cyan,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PROFILE PHOTO', textMuted),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _isUploadingPhoto ? null : _showImageSourceDialog,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: elevatedColor,
                    border: Border.all(color: cardBorder, width: 2),
                    image: _selectedPhotoFile != null
                        ? DecorationImage(
                            image: FileImage(_selectedPhotoFile!),
                            fit: BoxFit.cover,
                          )
                        : _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_currentPhotoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: (_selectedPhotoFile == null &&
                          (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
                      ? Icon(
                          Icons.person,
                          size: 48,
                          color: textMuted,
                        )
                      : null,
                ),
                // Edit badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cyan,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                        width: 2,
                      ),
                    ),
                    child: _isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedPhotoFile != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _isUploadingPhoto ? null : _uploadPhoto,
              icon: _isUploadingPhoto
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cyan),
                    )
                  : Icon(Icons.cloud_upload, color: cyan),
              label: Text(
                _isUploadingPhoto ? 'Uploading...' : 'Upload Photo',
                style: TextStyle(color: cyan, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap to change photo',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildNameAgeRow(bool isDark, Color elevatedColor, Color cardBorder, Color textMuted) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('NAME', textMuted),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _nameController,
                hint: 'Your name',
                isDark: isDark,
                elevatedColor: elevatedColor,
                cardBorder: cardBorder,
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
              _buildSectionTitle('AGE', textMuted),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _ageController,
                hint: '25',
                isDark: isDark,
                elevatedColor: elevatedColor,
                cardBorder: cardBorder,
                keyboardType: TextInputType.number,
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('GENDER', textMuted),
        const SizedBox(height: 6),
        Row(
          children: _genderOptions.map((gender) {
            final isSelected = _selectedGender == gender;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _isSaving ? null : () => setState(() => _selectedGender = gender),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? cyan.withOpacity(0.2) : elevatedColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? cyan : cardBorder),
                  ),
                  child: Text(
                    gender[0].toUpperCase() + gender.substring(1),
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? cyan : textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACTIVITY LEVEL', textMuted),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: _activityLevels.asMap().entries.map((entry) {
              final index = entry.key;
              final (value, title, subtitle) = entry.value;
              final isSelected = _selectedActivityLevel == value;
              return Column(
                children: [
                  InkWell(
                    onTap: _isSaving ? null : () => setState(() => _selectedActivityLevel = value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? cyan : textMuted,
                                width: 2,
                              ),
                              color: isSelected ? cyan : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? cyan : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '($subtitle)',
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
                  if (index < _activityLevels.length - 1)
                    Divider(height: 1, color: cardBorder, indent: 40),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color textMuted) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color elevatedColor,
    required Color cardBorder,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isSaving,
      validator: validator,
      style: const TextStyle(fontSize: 14),
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
          borderSide: BorderSide(color: isDark ? AppColors.accent : AppColorsLight.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildUnitInput({
    required String label,
    required double? value,
    required bool isMetric,
    required ValueChanged<bool> onMetricChanged,
    required ValueChanged<double?> onValueChanged,
    required String metricUnit,
    required String imperialUnit,
    required bool isHeight,
    required bool isDark,
    required Color elevatedColor,
    required Color cardBorder,
    required Color textMuted,
    required Color cyan,
  }) {
    String displayValue = '';
    if (value != null) {
      if (isMetric) {
        displayValue = isHeight ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
      } else if (isHeight) {
        final totalInches = value / 2.54;
        final feet = totalInches / 12;
        displayValue = feet.toStringAsFixed(1);
      } else {
        final imperial = value * 2.20462;
        displayValue = imperial.toStringAsFixed(1);
      }
    }

    final suffix = isMetric ? metricUnit : imperialUnit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(label, textMuted),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isSaving ? null : () => onMetricChanged(true),
                  child: Text(
                    metricUnit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isMetric ? FontWeight.w700 : FontWeight.normal,
                      color: isMetric ? cyan : textMuted,
                    ),
                  ),
                ),
                Text(' / ', style: TextStyle(fontSize: 11, color: textMuted)),
                GestureDetector(
                  onTap: _isSaving ? null : () => onMetricChanged(false),
                  child: Text(
                    imperialUnit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: !isMetric ? FontWeight.w700 : FontWeight.normal,
                      color: !isMetric ? cyan : textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: TextField(
            controller: TextEditingController(text: displayValue),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSaving,
            style: const TextStyle(fontSize: 14),
            onChanged: (text) {
              if (text.isEmpty) {
                onValueChanged(null);
                return;
              }
              final parsed = double.tryParse(text);
              if (parsed == null) return;

              if (isMetric) {
                onValueChanged(parsed);
              } else if (isHeight) {
                onValueChanged(parsed * 12 * 2.54);
              } else {
                onValueChanged(parsed / 2.20462);
              }
            },
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                fontSize: 12,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
