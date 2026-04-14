part of 'edit_personal_info_sheet.dart';

/// UI builder methods extracted from _EditPersonalInfoSheetState
extension _EditPersonalInfoSheetStateUI on _EditPersonalInfoSheetState {

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
        _buildSectionTitle('PROFILE PHOTO', textMuted, icon: Icons.photo_camera_outlined, accent: cyan),
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
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedPhotoFile != null
                      ? null
                      : _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                          ? Image.network(
                              _currentPhotoUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 48,
                                color: textMuted,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 48,
                              color: textMuted,
                            ),
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
            _buildSectionTitle(
              label,
              textMuted,
              icon: isHeight
                  ? Icons.height_rounded
                  : (label == 'TARGET WEIGHT'
                      ? Icons.flag_rounded
                      : Icons.monitor_weight_outlined),
              accent: cyan,
            ),
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
