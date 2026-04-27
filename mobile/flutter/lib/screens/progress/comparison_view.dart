import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/models/progress_photos.dart';
import '../../data/repositories/measurements_repository.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../widgets/pill_app_bar.dart';
import 'comparison_layouts.dart';
import 'comparison_export_service.dart';
import 'share_templates/progress_share_data.dart';
import 'share_templates/progress_share_gallery_screen.dart';
import 'share_templates/progress_share_templates.dart';
import 'widgets/ghost_overlay_widget.dart';
import 'widgets/comparison_enums.dart';
import 'widgets/comparison_supporting_widgets.dart';
import 'package:fitwiz/core/constants/branding.dart';

// Re-export enums so existing importers still work
export 'widgets/comparison_enums.dart';

part 'comparison_view_ui.dart';

part 'comparison_view_ext.dart';


// =============================================================================
// ComparisonView - 3-Step Comparison Editor
// Step 1: Choose Layout | Step 2: Select Photos | Step 3: Customize & Export
// =============================================================================

class ComparisonView extends ConsumerStatefulWidget {
  final String userId;
  final PhotoComparison? existingComparison;

  const ComparisonView({
    super.key,
    required this.userId,
    this.existingComparison,
  });

  @override
  ConsumerState<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends ConsumerState<ComparisonView> {
  // Step management
  int _currentStep = 0; // 0=layout, 1=photos, 2=customize

  // Step 1: Layout
  ComparisonLayout _selectedLayout = ComparisonLayout.sideBySide;

  // Step 2: Photos
  List<ProgressPhoto> _selectedPhotos = [];
  PhotoViewType? _filterViewType;

  // Step 3: Customize
  ComparisonSettings _settings = const ComparisonSettings();
  double _sliderPosition = 0.5;
  Offset _logoPosition = const Offset(16, 16);
  bool _showStats = true;
  Map<int, Offset> _datePositions = {};
  Offset _statsPosition = const Offset(-1, -1); // sentinel = use default
  int _selectedPhotoIndex = -1; // -1 = none selected
  bool _isLoadingAiSummary = false;
  String? _aiSummary;
  bool _isSaving = false;
  final GlobalKey _captureKey = GlobalKey();

  // Rich stats
  Set<StatCategory> _enabledStatCategories = {StatCategory.duration, StatCategory.weight};
  bool _showPhotoWeights = true;

  // Style controls
  DatePosition _datePosition = DatePosition.left;
  PhotoShape _photoShape = PhotoShape.rectangle;
  double _squircleRadius = 12.0;
  bool _photoBorderEnabled = false;
  Color _photoBorderColor = Colors.white;
  double _photoBorderWidth = 2.0;
  double _photoSpacing = 2.0;

  // Ghost overlay controls
  bool _ghostOverlayEnabled = false;
  double _ghostOpacity = 0.4;

  // Branding / logo
  bool _showUsername = false;
  String _logoVariant = 'auto'; // 'auto' | 'original' | 'light' | 'dark'

  // Per-photo date overrides (only affects rendered chip, not the underlying photo)
  final Map<int, DateTime> _dateOverrides = {};

  // CTA preset (e.g., "START NOW" pill on the bottom image)
  bool _showCta = false;
  String _ctaText = 'START NOW';
  String _ctaStyle = 'pill_light';
  Offset _ctaPosition = const Offset(-1, -1); // sentinel = use default

  @override
  void initState() {
    super.initState();
    _initFromExisting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressPhotosNotifierProvider(widget.userId).notifier).loadAll();
    });
  }

  void _initFromExisting() {
    final existing = widget.existingComparison;
    if (existing == null) return;

    if (existing.layout != null) {
      _selectedLayout = ComparisonLayout.fromString(existing.layout!);
    }
    if (existing.settingsJson != null) {
      _settings = ComparisonSettings.fromJson(existing.settingsJson!);
      _logoPosition = Offset(_settings.logoDx, _settings.logoDy);
      _showStats = _settings.showStats;

      for (final entry in _settings.datePositions.entries) {
        if (entry.value.length == 2) {
          _datePositions[entry.key] = Offset(entry.value[0], entry.value[1]);
        }
      }

      if (_settings.statsPosition != null && _settings.statsPosition!.length == 2) {
        _statsPosition = Offset(_settings.statsPosition![0], _settings.statsPosition![1]);
      }

      _enabledStatCategories = _settings.enabledStatCategories
          .map((s) => StatCategory.fromString(s))
          .whereType<StatCategory>()
          .toSet();
      if (_enabledStatCategories.isEmpty) {
        _enabledStatCategories = {StatCategory.duration, StatCategory.weight};
      }
      _showPhotoWeights = _settings.showPhotoWeights;

      _datePosition = DatePosition.values.firstWhere(
        (d) => d.name == _settings.datePosition,
        orElse: () => DatePosition.left,
      );
      _photoShape = PhotoShape.fromString(_settings.photoShape);
      _squircleRadius = _settings.squircleRadius;
      _photoBorderEnabled = _settings.photoBorderEnabled;
      _photoBorderColor = _parseBorderColor(_settings.photoBorderColor);
      _photoBorderWidth = _settings.photoBorderWidth;
      _photoSpacing = _settings.photoSpacing;
      _showUsername = _settings.showUsername;
      _logoVariant = _settings.logoVariant;
      for (final entry in _settings.dateOverrides.entries) {
        final dt = DateTime.tryParse(entry.value);
        if (dt != null) _dateOverrides[entry.key] = dt;
      }
      _showCta = _settings.showCta;
      _ctaText = _settings.ctaText;
      _ctaStyle = _settings.ctaStyle;
      if (_settings.ctaPosition != null && _settings.ctaPosition!.length == 2) {
        _ctaPosition = Offset(_settings.ctaPosition![0], _settings.ctaPosition![1]);
      }
    }
    if (existing.aiSummary != null) {
      _aiSummary = existing.aiSummary;
    }

    _selectedPhotos = [existing.beforePhoto, existing.afterPhoto];
    _currentStep = 2;
  }

  // ---------------------------------------------------------------------------
  // Computed helpers
  // ---------------------------------------------------------------------------

  bool get _hasEnoughPhotos {
    final layout = _selectedLayout;
    if (layout.isVariable) return _selectedPhotos.length >= layout.minPhotos;
    return _selectedPhotos.length == layout.photoCount;
  }

  int get _maxPhotoCount => _selectedLayout.maxPhotos;

  Color _resolveBackgroundColor(ColorScheme colorScheme) {
    switch (_settings.backgroundColor) {
      case '#FFFFFF': return Colors.white;
      case 'theme': return colorScheme.surface;
      case 'gradient_midnight': return const Color(0xFF1a1a2e);
      case 'gradient_ocean': return const Color(0xFF0f2027);
      case 'gradient_ember': return const Color(0xFF2d1b3d);
      case 'gradient_forest': return const Color(0xFF0a1612);
      case '#000000':
      default: return Colors.black;
    }
  }

  BoxDecoration _resolveBackgroundDecoration(ColorScheme colorScheme) {
    switch (_settings.backgroundColor) {
      case 'gradient_midnight':
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
          borderRadius: BorderRadius.circular(4),
        );
      case 'gradient_ocean':
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
          ),
          borderRadius: BorderRadius.circular(4),
        );
      case 'gradient_ember':
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2d1b3d), Color(0xFF6b2737), Color(0xFFc94b4b)],
          ),
          borderRadius: BorderRadius.circular(4),
        );
      case 'gradient_forest':
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0a1612), Color(0xFF1a3a2a), Color(0xFF2d5a42)],
          ),
          borderRadius: BorderRadius.circular(4),
        );
      default:
        return BoxDecoration(
          color: _resolveBackgroundColor(colorScheme),
          borderRadius: BorderRadius.circular(4),
        );
    }
  }

  ExportAspectRatio get _exportRatio =>
      ExportAspectRatio.fromString(_settings.exportAspectRatio);

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      body: Column(
        children: [
          _buildStepIndicator(colorScheme),
          Expanded(child: _buildStepContent(colorScheme)),
          _buildBottomBar(colorScheme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    const titles = ['Choose Layout', 'Select Photos', 'Customize'];
    return PillAppBar(
      title: titles[_currentStep],
      onBack: () {
        if (_currentStep > 0 && widget.existingComparison == null) {
          setState(() => _currentStep--);
        } else {
          Navigator.pop(context);
        }
      },
      actions: [
        PillAppBarAction(
          icon: Icons.auto_awesome,
          visible: _currentStep == 2 && !_isSaving && _selectedPhotos.length >= 2,
          onTap: _openViralGallery,
        ),
        PillAppBarAction(
          icon: Icons.save_outlined,
          visible: _currentStep == 2 && !_isSaving,
          onTap: _saveComparison,
        ),
        PillAppBarAction(
          icon: Icons.share_outlined,
          visible: _currentStep == 2 && !_isSaving,
          onTap: _shareComparison,
        ),
      ],
    );
  }

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    const labels = ['Layout', 'Photos', 'Customize'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: List.generate(5, (i) {
          if (i.isOdd) {
            final beforeStep = i ~/ 2;
            final isCompleted = beforeStep < _currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? colorScheme.primary : colorScheme.outlineVariant,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < _currentStep;
          final isActive = stepIndex == _currentStep;
          return GestureDetector(
            onTap: stepIndex < _currentStep
                ? () => setState(() => _currentStep = stepIndex)
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isActive ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isCompleted || isActive ? colorScheme.primary : colorScheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive || isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLayoutGroup({
    required String title,
    required List<ComparisonLayout> layouts,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
          ),
          itemCount: layouts.length,
          itemBuilder: (context, index) {
            final layout = layouts[index];
            return ComparisonLayoutCard(
              layout: layout,
              isSelected: _selectedLayout == layout,
              onTap: () => setState(() => _selectedLayout = layout),
              colorScheme: colorScheme,
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3 - Customize & Export
  // ===========================================================================

  Widget _buildCustomizeStep(ColorScheme colorScheme) {
    final bgColor = _resolveBackgroundColor(colorScheme);

    return Column(
      children: [
        _buildTemplatesStrip(colorScheme),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: AspectRatio(
                aspectRatio: _exportRatio.ratio,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: Container(
                    decoration: _resolveBackgroundDecoration(colorScheme),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: _computeCanvasPhotoPadding(),
                            child: _buildCanvasLayout(bgColor),
                          ),
                        ),
                        if (_ghostOverlayEnabled &&
                            _selectedLayout != ComparisonLayout.ghostOverlay &&
                            _selectedPhotos.length >= 2)
                          Positioned.fill(
                            child: Padding(
                              padding: _computeCanvasPhotoPadding(),
                              child: GhostOverlayWidget(
                                beforeImageUrl: _selectedPhotos[0].photoUrl,
                                opacity: _ghostOpacity,
                                showGuides: true,
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: CanvasPatternPainter(bgColor)),
                          ),
                        ),
                        if (_showStats && _buildRichStatsData() != null)
                          _buildDraggableStatsBar(bgColor),
                        if (_settings.showAiSummary && _aiSummary != null)
                          Positioned(left: 0, right: 0, bottom: 0, child: _buildAiSummaryOverlay(bgColor)),
                        if (_settings.showDates) _buildDateOverlays(),
                        if (_showCta) _buildCtaOverlay(bgColor),
                        if (_settings.showLogo)
                          Positioned(
                            left: _logoPosition.dx, top: _logoPosition.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) => setState(() => _logoPosition += details.delta),
                              child: _buildBrandingPill(bgColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildToolbar(colorScheme),
      ],
    );
  }

  EdgeInsets _computeCanvasPhotoPadding() {
    double bottom = 0;
    if (_settings.showAiSummary && _aiSummary != null) bottom += 60;
    final statsH = _computeStatsBarHeight();
    if (statsH > 0) bottom += statsH;
    return EdgeInsets.only(bottom: bottom);
  }

  BorderRadius? get _shapeBorderRadius {
    switch (_photoShape) {
      case PhotoShape.squircle: return BorderRadius.circular(_squircleRadius);
      case PhotoShape.circle: return BorderRadius.circular(9999);
      case PhotoShape.rectangle: return null;
    }
  }

  Widget _applyLayoutShapeAndBorder(Widget content) {
    final br = _shapeBorderRadius;
    if (br != null) content = ClipRRect(borderRadius: br, child: content);
    if (_photoBorderEnabled && _photoBorderWidth > 0) {
      content = Container(
        decoration: BoxDecoration(border: Border.all(color: _photoBorderColor, width: _photoBorderWidth), borderRadius: br),
        child: content,
      );
    }
    return content;
  }

  Widget _buildPhotoWidget(ProgressPhoto photo, int index, {BoxFit fit = BoxFit.cover}) {
    final isSelected = _selectedPhotoIndex == index;
    final weight = _showPhotoWeights ? _resolvePhotoWeight(photo) : null;
    final br = _shapeBorderRadius;

    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        PannablePhoto(
          photo: photo, fit: fit, isSelected: isSelected,
          onTap: () => setState(() => _selectedPhotoIndex = _selectedPhotoIndex == index ? -1 : index),
        ),
        if (weight != null)
          Positioned(
            left: 0, right: 0, bottom: 6,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                  child: Text('${weight.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        if (isSelected)
          IgnorePointer(child: Container(decoration: BoxDecoration(border: Border.all(color: AppColors.green, width: 2.5), borderRadius: br))),
        if (isSelected)
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => setState(() { _selectedPhotos.removeAt(index); _selectedPhotoIndex = -1; _resetOverlayPositions(); }),
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 1)),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );

    if (br != null) content = ClipRRect(borderRadius: br, child: content);
    if (_photoBorderEnabled && _photoBorderWidth > 0) {
      content = Container(
        decoration: BoxDecoration(border: Border.all(color: _photoBorderColor, width: _photoBorderWidth), borderRadius: br),
        child: br != null
            ? ClipRRect(borderRadius: BorderRadius.circular(max(0, (br.topLeft.x) - _photoBorderWidth)), child: Stack(fit: StackFit.expand, children: [content]))
            : content,
      );
    }
    return content;
  }

  Widget _buildSliderLayout() {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.length < 2) return _buildPhotoWidget(photos.first, 0);
    return LayoutBuilder(builder: (context, constraints) {
      Widget content = GestureDetector(
        onHorizontalDragUpdate: (details) => setState(() { _sliderPosition += details.delta.dx / constraints.maxWidth; _sliderPosition = _sliderPosition.clamp(0.0, 1.0); }),
        child: Stack(children: [
          SizedBox.expand(child: CachedNetworkImage(imageUrl: photos[1].photoUrl, fit: BoxFit.cover, memCacheWidth: 600, memCacheHeight: 600)),
          ClipRect(clipper: SliderClipper(_sliderPosition * constraints.maxWidth), child: SizedBox.expand(child: CachedNetworkImage(imageUrl: photos[0].photoUrl, fit: BoxFit.cover, memCacheWidth: 600, memCacheHeight: 600))),
          Positioned(left: _sliderPosition * constraints.maxWidth - 16, top: 0, bottom: 0, child: SizedBox(width: 32, child: Center(child: Container(width: 3, color: Colors.white, child: Center(child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)]), child: const Icon(Icons.compare_arrows, color: Colors.black87, size: 18))))))),
          Positioned(top: 8, left: 8, child: _buildLabel('Before')),
          Positioned(top: 8, right: 8, child: _buildLabel('After')),
        ]),
      );
      return _applyLayoutShapeAndBorder(content);
    });
  }

  double _dateAlignX(double segmentLeft, double segmentWidth, double chipWidth) {
    switch (_datePosition) {
      case DatePosition.left: return segmentLeft + 6;
      case DatePosition.center: return segmentLeft + (segmentWidth - chipWidth) / 2;
      case DatePosition.right: return segmentLeft + segmentWidth - chipWidth - 6;
    }
  }

  Offset _computeDefaultDatePosition(int index, int totalPhotos, BoxConstraints constraints) {
    final isHorizontal = _selectedLayout == ComparisonLayout.sideBySide || _selectedLayout == ComparisonLayout.triptych;
    const chipW = 80.0;
    final aiH = (_settings.showAiSummary && _aiSummary != null) ? 60.0 : 0.0;
    final bottomOffset = aiH + 8;
    if (isHorizontal && totalPhotos > 1) {
      final segmentWidth = constraints.maxWidth / totalPhotos;
      return Offset(_dateAlignX(index * segmentWidth, segmentWidth, chipW), constraints.maxHeight - bottomOffset - 24);
    }
    if (_selectedLayout == ComparisonLayout.verticalStack && totalPhotos >= 2) {
      final segmentHeight = constraints.maxHeight / totalPhotos;
      return Offset(_dateAlignX(0, constraints.maxWidth, chipW), (index + 1) * segmentHeight - bottomOffset - 24);
    }
    if (totalPhotos >= 2) {
      if (index == 0) return Offset(_dateAlignX(0, constraints.maxWidth / 2, chipW), constraints.maxHeight - bottomOffset - 24);
      return Offset(_dateAlignX(constraints.maxWidth / 2, constraints.maxWidth / 2, chipW), constraints.maxHeight - bottomOffset - 24);
    }
    return Offset(_dateAlignX(0, constraints.maxWidth, chipW), constraints.maxHeight - bottomOffset - 24);
  }

  Widget _buildDateOverlays() {
    if (_selectedPhotos.isEmpty) return const SizedBox.shrink();
    final labels = _selectedLayout.getLabels(_selectedPhotos.length);
    final photosToLabel = _selectedPhotos.take(labels.length).toList();
    return Positioned.fill(child: LayoutBuilder(builder: (context, constraints) {
      // Bottom chrome that chips must sit above — stats bar + AI summary.
      // We re-clamp each render so stored positions (from earlier drags, a
      // saved comparison, or a default computed when the canvas was taller)
      // stay visible and never overlap the AI summary. Without this,
      // toggling AI Summary leaves cached chip Y's inside the summary strip,
      // and switching to Squircle (which adds the Radius slider and shrinks
      // the canvas) pushes cached chip Y's below the visible bounds.
      const chipHeight = 24.0;
      const chipWidth = 80.0;
      const chipGap = 4.0;
      final aiH =
          (_settings.showAiSummary && _aiSummary != null) ? 60.0 : 0.0;
      final maxChipX =
          max(0.0, constraints.maxWidth - chipWidth);
      final maxChipY = max(
        0.0,
        constraints.maxHeight - aiH - chipHeight - chipGap,
      );
      return Stack(children: photosToLabel.asMap().entries.map((entry) {
        final i = entry.key;
        final photo = entry.value;
        final rawPos = _datePositions[i] ??
            _computeDefaultDatePosition(i, photosToLabel.length, constraints);
        final pos = Offset(
          rawPos.dx.clamp(0.0, maxChipX),
          rawPos.dy.clamp(0.0, maxChipY),
        );
        final displayedDate = _dateOverrides[i] ?? photo.takenAt;
        return Positioned(left: pos.dx, top: pos.dy, child: GestureDetector(
          onPanUpdate: (details) => setState(() {
            final current = _datePositions[i] ?? _computeDefaultDatePosition(i, photosToLabel.length, constraints);
            _datePositions[i] = Offset(
              (current.dx + details.delta.dx).clamp(0.0, maxChipX),
              (current.dy + details.delta.dy).clamp(0.0, maxChipY),
            );
          }),
          onTap: () => _pickDateOverride(i, displayedDate),
          child: _buildDateChip(displayedDate),
        ));
      }).toList());
    }));
  }

  Future<void> _pickDateOverride(int index, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _dateOverrides[index] = picked);
    }
  }

  // ---------------------------------------------------------------------------
  // Color helpers
  // ---------------------------------------------------------------------------

  static Color _parseBorderColor(String hex) {
    switch (hex) {
      case '#FFFFFF': return Colors.white;
      case '#000000': return Colors.black;
      case '#4CAF50': return const Color(0xFF4CAF50);
      case '#2196F3': return const Color(0xFF2196F3);
      case '#FF9800': return const Color(0xFFFF9800);
      default: return Colors.white;
    }
  }

  static String _borderColorToHex(Color c) {
    if (c == Colors.white) return '#FFFFFF';
    if (c == Colors.black) return '#000000';
    if (c.value == 0xFF4CAF50) return '#4CAF50';
    if (c.value == 0xFF2196F3) return '#2196F3';
    if (c.value == 0xFFFF9800) return '#FF9800';
    return '#FFFFFF';
  }

  // ---------------------------------------------------------------------------
  // Weight resolution & measurement helpers
  // ---------------------------------------------------------------------------

  double? _resolvePhotoWeight(ProgressPhoto photo) {
    if (photo.bodyWeightKg != null) return photo.bodyWeightKg;
    final measState = ref.read(measurementsProvider);
    final weightHistory = measState.historyByType[MeasurementType.weight];
    if (weightHistory == null || weightHistory.isEmpty) return null;
    return _findClosestMeasurementValue(weightHistory, photo.takenAt);
  }

  double? _findClosestMeasurementValue(List<MeasurementEntry> history, DateTime target) {
    MeasurementEntry? closest;
    int closestDiff = 8;
    for (final entry in history) {
      final diff = entry.recordedAt.difference(target).inDays.abs();
      if (diff < closestDiff) { closestDiff = diff; closest = entry; }
    }
    return closest?.value;
  }

  double _computeStatsBarHeight() {
    final data = _buildRichStatsData();
    if (data == null || !_showStats) return 0;
    return max(36, data.length * 22.0 + 16);
  }

  Widget _buildDraggableStatsBar(Color bgColor) {
    return Positioned.fill(child: LayoutBuilder(builder: (context, constraints) {
      final aiH = (_settings.showAiSummary && _aiSummary != null) ? 60.0 : 0.0;
      final barH = _computeStatsBarHeight();
      final defaultPos = Offset(0, constraints.maxHeight - aiH - barH);
      final pos = _statsPosition.dx < 0 ? defaultPos : _statsPosition;
      return Stack(children: [Positioned(left: pos.dx, top: pos.dy, width: constraints.maxWidth, child: GestureDetector(
        onPanUpdate: (details) => setState(() {
          final current = _statsPosition.dx < 0 ? defaultPos : _statsPosition;
          _statsPosition = Offset((current.dx + details.delta.dx).clamp(0, 0), (current.dy + details.delta.dy).clamp(0, constraints.maxHeight - barH));
        }),
        child: _buildStatsBar(bgColor),
      ))]);
    }));
  }

  void _resetOverlayPositions() { _datePositions.clear(); _statsPosition = const Offset(-1, -1); _selectedPhotoIndex = -1; }

  // ---------------------------------------------------------------------------
  // Toolbar (Step 3)
  // ---------------------------------------------------------------------------

  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          ComparisonToolbarChip(label: 'Logo', icon: Icons.auto_awesome, isActive: _settings.showLogo, colorScheme: colorScheme, onTap: () => setState(() => _settings = _settings.copyWith(showLogo: !_settings.showLogo))),
          const SizedBox(width: 8),
          ComparisonToolbarChip(label: 'Username', icon: Icons.alternate_email, isActive: _showUsername, colorScheme: colorScheme, onTap: () => setState(() => _showUsername = !_showUsername)),
          const SizedBox(width: 8),
          ComparisonToolbarChip(label: 'Stats', icon: Icons.bar_chart, isActive: _showStats, colorScheme: colorScheme, onTap: () => setState(() => _showStats = !_showStats)),
          const SizedBox(width: 8),
          ComparisonToolbarChip(label: 'Weights', icon: Icons.monitor_weight_outlined, isActive: _showPhotoWeights, colorScheme: colorScheme, onTap: () => setState(() => _showPhotoWeights = !_showPhotoWeights)),
          const SizedBox(width: 8),
          ComparisonToolbarChip(label: 'Dates', icon: Icons.calendar_today, isActive: _settings.showDates, colorScheme: colorScheme, onTap: () => setState(() => _settings = _settings.copyWith(showDates: !_settings.showDates))),
          const SizedBox(width: 8),
          ComparisonToolbarChip(label: 'AI Summary', icon: Icons.auto_fix_high, isActive: _settings.showAiSummary, isLoading: _isLoadingAiSummary, colorScheme: colorScheme, onTap: _handleAiSummaryToggle),
          const SizedBox(width: 8),
          ComparisonToolbarChip(label: 'Ghost', icon: Icons.layers_outlined, isActive: _ghostOverlayEnabled, colorScheme: colorScheme, onTap: () => setState(() => _ghostOverlayEnabled = !_ghostOverlayEnabled)),
          const SizedBox(width: 8),
          ComparisonToolbarChip(label: 'CTA', icon: Icons.flash_on, isActive: _showCta, colorScheme: colorScheme, onTap: () => setState(() { _showCta = !_showCta; if (_showCta) _ctaPosition = const Offset(-1, -1); })),
          const SizedBox(width: 16),
          _buildBgColorPicker(colorScheme),
          const SizedBox(width: 16),
          ..._buildAspectRatioChips(colorScheme),
        ])),
        _buildStatCategoryPills(colorScheme),
        _buildDatePositionPills(colorScheme),
        _buildStyleControls(colorScheme),
        _buildGhostOpacitySlider(colorScheme),
        _buildCtaControls(colorScheme),
      ])),
    );
  }

  Widget _buildStatCategoryPills(ColorScheme colorScheme) {
    return AnimatedSize(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut, child: _showStats
        ? Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: StatCategory.values.map((cat) {
            final isActive = _enabledStatCategories.contains(cat);
            return Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
              onTap: () => setState(() { if (isActive) _enabledStatCategories.remove(cat); else _enabledStatCategories.add(cat); _statsPosition = const Offset(-1, -1); }),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150), height: 28, padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: isActive ? colorScheme.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: isActive ? colorScheme.primary : colorScheme.outlineVariant, width: 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(cat.icon, size: 13, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(cat.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
                ]),
              ),
            ));
          }).toList()))
        : const SizedBox.shrink());
  }

  Widget _buildDatePositionPills(ColorScheme colorScheme) {
    return AnimatedSize(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut, child: _settings.showDates
        ? Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
            Text('Align', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            ...DatePosition.values.map((pos) {
              final isActive = _datePosition == pos;
              return Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
                onTap: () => setState(() { _datePosition = pos; _datePositions.clear(); }),
                child: AnimatedContainer(duration: const Duration(milliseconds: 150), height: 28, padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: isActive ? colorScheme.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: isActive ? colorScheme.primary : colorScheme.outlineVariant, width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(pos.icon, size: 13, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant), const SizedBox(width: 4), Text(pos.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant))]),
                ),
              ));
            }),
          ]))
        : const SizedBox.shrink());
  }

  Widget _buildStyleControls(ColorScheme colorScheme) {
    return Padding(padding: const EdgeInsets.only(top: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        Text('Shape', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        ...PhotoShape.values.map((shape) {
          final isActive = _photoShape == shape;
          return Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
            onTap: () => setState(() => _photoShape = shape),
            child: AnimatedContainer(duration: const Duration(milliseconds: 150), height: 28, padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: isActive ? colorScheme.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: isActive ? colorScheme.primary : colorScheme.outlineVariant, width: 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(shape.icon, size: 13, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant), const SizedBox(width: 4), Text(shape.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant))]),
            ),
          ));
        }),
        const SizedBox(width: 12),
        ComparisonToolbarChip(label: 'Border', icon: Icons.border_style, isActive: _photoBorderEnabled, colorScheme: colorScheme, onTap: () => setState(() => _photoBorderEnabled = !_photoBorderEnabled)),
      ])),
      AnimatedSize(duration: const Duration(milliseconds: 200), child: _photoShape == PhotoShape.squircle
          ? Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [Text('Radius', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)), Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)), child: Slider(value: _squircleRadius, min: 0, max: 48, onChanged: (v) => setState(() => _squircleRadius = v)))), SizedBox(width: 28, child: Text('${_squircleRadius.round()}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)))]))
          : const SizedBox.shrink()),
      AnimatedSize(duration: const Duration(milliseconds: 200), child: _photoBorderEnabled
          ? Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
              Text('Width', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              SizedBox(width: 100, child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)), child: Slider(value: _photoBorderWidth, min: 1, max: 8, onChanged: (v) => setState(() => _photoBorderWidth = v)))),
              Text('${_photoBorderWidth.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 12),
              ..._buildBorderColorDots(colorScheme),
            ]))
          : const SizedBox.shrink()),
      Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
        Text('Gap', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)), child: Slider(value: _photoSpacing, min: 0, max: 24, onChanged: (v) => setState(() => _photoSpacing = v)))),
        SizedBox(width: 28, child: Text('${_photoSpacing.round()}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
      ])),
      AnimatedSize(duration: const Duration(milliseconds: 200), child: _settings.showLogo
          ? Padding(padding: const EdgeInsets.only(top: 8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              Text('Logo', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              ..._buildLogoVariantPills(colorScheme),
            ])))
          : const SizedBox.shrink()),
    ]));
  }

  List<Widget> _buildLogoVariantPills(ColorScheme colorScheme) {
    const variants = <MapEntry<String, (String, IconData)>>[
      MapEntry('auto', ('Auto', Icons.brightness_auto)),
      MapEntry('original', ('Original', Icons.palette_outlined)),
      MapEntry('light', ('Light', Icons.light_mode)),
      MapEntry('dark', ('Dark', Icons.dark_mode)),
    ];
    return variants.map((entry) {
      final isActive = _logoVariant == entry.key;
      final label = entry.value.$1;
      final icon = entry.value.$2;
      return Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
        onTap: () => setState(() => _logoVariant = entry.key),
        child: AnimatedContainer(duration: const Duration(milliseconds: 150), height: 28, padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: isActive ? colorScheme.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: isActive ? colorScheme.primary : colorScheme.outlineVariant, width: 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
          ]),
        ),
      ));
    }).toList();
  }

  Widget _buildGhostOpacitySlider(ColorScheme colorScheme) {
    return AnimatedSize(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut, child: _ghostOverlayEnabled && _selectedPhotos.length >= 2
        ? Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
            Icon(Icons.opacity, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('Ghost', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)), child: Slider(value: _ghostOpacity, min: 0.1, max: 0.9, onChanged: (v) => setState(() => _ghostOpacity = v)))),
            SizedBox(width: 32, child: Text('${(_ghostOpacity * 100).round()}%', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
          ]))
        : const SizedBox.shrink());
  }

  List<Widget> _buildBorderColorDots(ColorScheme colorScheme) {
    final colors = <MapEntry<Color, String>>[const MapEntry(Colors.white, '#FFFFFF'), const MapEntry(Colors.black, '#000000'), const MapEntry(Color(0xFF4CAF50), '#4CAF50'), const MapEntry(Color(0xFF2196F3), '#2196F3'), const MapEntry(Color(0xFFFF9800), '#FF9800')];
    return colors.map((entry) {
      final isSelected = _photoBorderColor.value == entry.key.value;
      return Padding(padding: const EdgeInsets.only(right: 4), child: GestureDetector(onTap: () => setState(() => _photoBorderColor = entry.key), child: Container(width: 20, height: 20, decoration: BoxDecoration(color: entry.key, shape: BoxShape.circle, border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant, width: isSelected ? 2 : 1)))));
    }).toList();
  }

  Widget _buildBgColorPicker(ColorScheme colorScheme) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('BG', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
      const SizedBox(width: 6),
      _buildColorDot(color: Colors.black, isSelected: _settings.backgroundColor == '#000000', onTap: () => setState(() => _settings = _settings.copyWith(backgroundColor: '#000000'))),
      const SizedBox(width: 4),
      _buildColorDot(color: Colors.white, isSelected: _settings.backgroundColor == '#FFFFFF', onTap: () => setState(() => _settings = _settings.copyWith(backgroundColor: '#FFFFFF'))),
      const SizedBox(width: 4),
      _buildColorDot(color: colorScheme.surface, isSelected: _settings.backgroundColor == 'theme', borderColor: colorScheme.outline, onTap: () => setState(() => _settings = _settings.copyWith(backgroundColor: 'theme'))),
      const SizedBox(width: 8),
      _buildGradientDot(colors: const [Color(0xFF1a1a2e), Color(0xFF0f3460)], isSelected: _settings.backgroundColor == 'gradient_midnight', onTap: () => setState(() => _settings = _settings.copyWith(backgroundColor: 'gradient_midnight'))),
      const SizedBox(width: 4),
      _buildGradientDot(colors: const [Color(0xFF0f2027), Color(0xFF2c5364)], isSelected: _settings.backgroundColor == 'gradient_ocean', onTap: () => setState(() => _settings = _settings.copyWith(backgroundColor: 'gradient_ocean'))),
      const SizedBox(width: 4),
      _buildGradientDot(colors: const [Color(0xFF2d1b3d), Color(0xFFc94b4b)], isSelected: _settings.backgroundColor == 'gradient_ember', onTap: () => setState(() => _settings = _settings.copyWith(backgroundColor: 'gradient_ember'))),
      const SizedBox(width: 4),
      _buildGradientDot(colors: const [Color(0xFF0a1612), Color(0xFF2d5a42)], isSelected: _settings.backgroundColor == 'gradient_forest', onTap: () => setState(() => _settings = _settings.copyWith(backgroundColor: 'gradient_forest'))),
    ]);
  }

  List<Widget> _buildAspectRatioChips(ColorScheme colorScheme) {
    return ExportAspectRatio.values.map((ratio) {
      final isSelected = _settings.exportAspectRatio == ratio.label;
      return Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
        onTap: () => setState(() { _settings = _settings.copyWith(exportAspectRatio: ratio.label); _resetOverlayPositions(); }),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? colorScheme.primary : Colors.transparent, width: 1.5)),
          child: Text(ratio.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant))),
      ));
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Bottom bar (steps 0 & 1)
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(ColorScheme colorScheme) {
    if (_currentStep == 2) return const SizedBox.shrink();
    final canProceed = _currentStep == 0 ? true : _hasEnoughPhotos;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: colorScheme.surface, border: Border(top: BorderSide(color: colorScheme.outlineVariant))),
      child: SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: canProceed ? () {
          if (_currentStep == 0 && _selectedPhotos.length > _maxPhotoCount) _selectedPhotos = _selectedPhotos.sublist(0, _maxPhotoCount);
          if (_currentStep <= 1) _resetOverlayPositions();
          setState(() => _currentStep++);
        } : null,
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: Text(_currentStep == 0 ? 'Next: Select Photos' : 'Next: Customize'),
      )),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _handleAiSummaryToggle() {
    if (_settings.showAiSummary) { setState(() => _settings = _settings.copyWith(showAiSummary: false)); return; }
    if (_aiSummary != null) { setState(() => _settings = _settings.copyWith(showAiSummary: true)); return; }
    _loadAiSummary();
  }

  Future<void> _loadAiSummary() async {
    if (_selectedPhotos.length < 2) return;
    setState(() => _isLoadingAiSummary = true);
    try {
      final first = _selectedPhotos.first;
      final last = _selectedPhotos.last;
      final days = last.takenAt.difference(first.takenAt).inDays.abs();
      double? weightChange;
      if (first.bodyWeightKg != null && last.bodyWeightKg != null) weightChange = last.bodyWeightKg! - first.bodyWeightKg!;
      final summary = await ref.read(progressPhotosRepositoryProvider).getAiSummary(beforePhotoUrl: first.photoUrl, afterPhotoUrl: last.photoUrl, daysBetween: days, weightChangeKg: weightChange);
      if (mounted) setState(() { _aiSummary = summary; _isLoadingAiSummary = false; _settings = _settings.copyWith(showAiSummary: true); });
    } catch (e) {
      if (mounted) { setState(() => _isLoadingAiSummary = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate AI summary: $e'), backgroundColor: Theme.of(context).colorScheme.error)); }
    }
  }

  Future<void> _saveComparison() async {
    if (_selectedPhotos.length < 2) return;
    setState(() { _isSaving = true; _selectedPhotoIndex = -1; });
    try {
      final datePosMap = <int, List<double>>{};
      for (final entry in _datePositions.entries) datePosMap[entry.key] = [entry.value.dx, entry.value.dy];
      final dateOverridesMap = <int, String>{};
      for (final entry in _dateOverrides.entries) dateOverridesMap[entry.key] = entry.value.toIso8601String();
      final finalSettings = _settings.copyWith(
        layout: _selectedLayout.value, logoDx: _logoPosition.dx, logoDy: _logoPosition.dy, showStats: _showStats,
        datePositions: datePosMap, statsPosition: _statsPosition.dx >= 0 ? [_statsPosition.dx, _statsPosition.dy] : null,
        enabledStatCategories: _enabledStatCategories.map((c) => c.name).toList(), showPhotoWeights: _showPhotoWeights,
        datePosition: _datePosition.name, photoShape: _photoShape.name, squircleRadius: _squircleRadius,
        photoBorderEnabled: _photoBorderEnabled, photoBorderColor: _borderColorToHex(_photoBorderColor), photoBorderWidth: _photoBorderWidth, photoSpacing: _photoSpacing,
        showUsername: _showUsername, logoVariant: _logoVariant, dateOverrides: dateOverridesMap,
        showCta: _showCta, ctaText: _ctaText, ctaStyle: _ctaStyle,
        ctaPosition: _ctaPosition.dx >= 0 ? [_ctaPosition.dx, _ctaPosition.dy] : null,
      );
      final labels = _selectedLayout.getLabels(_selectedPhotos.length);
      final photosJsonList = _selectedPhotos.asMap().entries.map((entry) => {'photo_id': entry.value.id, 'order': entry.key, 'label': labels[min(entry.key, labels.length - 1)]}).toList();
      final notifier = ref.read(progressPhotosNotifierProvider(widget.userId).notifier);
      if (widget.existingComparison != null) {
        await notifier.updateComparison(comparisonId: widget.existingComparison!.id, layout: _selectedLayout.value, settingsJson: finalSettings.toJson(), aiSummary: _aiSummary, photosJson: photosJsonList);
      } else {
        final created = await notifier.createComparison(beforePhotoId: _selectedPhotos.first.id, afterPhotoId: _selectedPhotos.last.id, title: '${_selectedLayout.displayName} Comparison');
        if (created == null) throw Exception('Failed to create comparison');
        await notifier.updateComparison(comparisonId: created.id, layout: _selectedLayout.value, settingsJson: finalSettings.toJson(), aiSummary: _aiSummary, photosJson: photosJsonList);
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Comparison saved!'), backgroundColor: Theme.of(context).colorScheme.primary)); Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) { setState(() => _isSaving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Theme.of(context).colorScheme.error)); }
    }
  }

  // ---------------------------------------------------------------------------
  // CTA overlay ("START NOW" pill preset)
  // ---------------------------------------------------------------------------

  Widget _buildCtaOverlay(Color bgColor) {
    return Positioned.fill(child: LayoutBuilder(builder: (context, constraints) {
      const pillW = 160.0;
      const pillH = 40.0;
      final defaultPos = Offset(
        (constraints.maxWidth - pillW) / 2,
        constraints.maxHeight - pillH - _computeCanvasPhotoPadding().bottom - 24,
      );
      final pos = _ctaPosition.dx < 0 ? defaultPos : _ctaPosition;
      final maxX = max(0.0, constraints.maxWidth - pillW);
      final maxY = max(0.0, constraints.maxHeight - pillH);
      final clamped = Offset(pos.dx.clamp(0.0, maxX), pos.dy.clamp(0.0, maxY));
      return Stack(children: [
        Positioned(
          left: clamped.dx, top: clamped.dy,
          child: GestureDetector(
            onPanUpdate: (d) => setState(() {
              final cur = _ctaPosition.dx < 0 ? defaultPos : _ctaPosition;
              _ctaPosition = Offset(
                (cur.dx + d.delta.dx).clamp(0.0, maxX),
                (cur.dy + d.delta.dy).clamp(0.0, maxY),
              );
            }),
            onTap: _editCtaText,
            child: _renderCtaPill(),
          ),
        ),
      ]);
    }));
  }

  Widget _renderCtaPill() {
    final text = _ctaText.isEmpty ? 'START NOW' : _ctaText;
    switch (_ctaStyle) {
      case 'pill_dark':
        return _ctaPill(
          bg: Colors.black, fg: Colors.white, text: text,
          leading: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
        );
      case 'arrow':
        return _ctaPill(
          bg: Colors.white, fg: Colors.black, text: text,
          trailing: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.black),
        );
      case 'neon':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFFF4D8D), Color(0xFFFF8A00), Color(0xFFFFD600)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: const Color(0xFFFF4D8D).withOpacity(0.6), blurRadius: 18, spreadRadius: 1)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.link, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
          ]),
        );
      case 'ticket':
        return ClipPath(
          clipper: _TicketClipper(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: const Color(0xFFFFD166),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt, size: 18, color: Colors.black),
              const SizedBox(width: 6),
              Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
            ]),
          ),
        );
      case 'pill_light':
      default:
        return _ctaPill(
          bg: Colors.white, fg: Colors.black, text: text,
          leading: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link, size: 12, color: Colors.white),
          ),
        );
    }
  }

  Widget _ctaPill({
    required Color bg, required Color fg, required String text,
    Widget? leading, Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (leading != null) ...[leading, const SizedBox(width: 8)],
        Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ]),
    );
  }

  Future<void> _editCtaText() async {
    final controller = TextEditingController(text: _ctaText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CTA label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'START NOW'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _ctaText = result.isEmpty ? 'START NOW' : result);
    }
  }

  Widget _buildCtaControls(ColorScheme colorScheme) {
    const presets = <MapEntry<String, (String, IconData)>>[
      MapEntry('pill_light', ('Light', Icons.light_mode)),
      MapEntry('pill_dark', ('Dark', Icons.dark_mode)),
      MapEntry('arrow', ('Arrow', Icons.arrow_forward_rounded)),
      MapEntry('neon', ('Neon', Icons.auto_awesome)),
      MapEntry('ticket', ('Ticket', Icons.local_activity_outlined)),
    ];
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _showCta
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Text('CTA', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _editCtaText,
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(_ctaText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...presets.map((p) {
                    final isActive = _ctaStyle == p.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _ctaStyle = p.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isActive ? colorScheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isActive ? colorScheme.primary : colorScheme.outlineVariant, width: 1),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(p.value.$2, size: 13, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(p.value.$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
                          ]),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _ctaPosition = const Offset(-1, -1)),
                    icon: Icon(Icons.restart_alt, size: 14, color: colorScheme.onSurfaceVariant),
                    label: Text('Reset', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ]),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Compact horizontal strip of viral template previews, placed above the
  /// customization canvas on Step 3. Shows the first 5 templates as live
  /// thumbnails + a "See all" tile that opens the full gallery grid.
  Widget _buildTemplatesStrip(ColorScheme colorScheme) {
    if (_selectedPhotos.length < 2) return const SizedBox.shrink();
    final shareData = _buildProgressShareData();
    if (shareData == null) return const SizedBox.shrink();

    // Preview subset — the rest live in "See all".
    const previewKinds = <ProgressTemplateKind>[
      ProgressTemplateKind.igStoryCta,
      ProgressTemplateKind.wrapped,
      ProgressTemplateKind.tradingCard,
      ProgressTemplateKind.magazineCover,
      ProgressTemplateKind.retro80s,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome, size: 14, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text('Templates', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface,
            )),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${ProgressTemplateKind.values.length} viral',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: 0.5),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _openViralGallery,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('See all', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.primary,
                )),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: colorScheme.primary),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: previewKinds.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                if (i == previewKinds.length) {
                  return _buildSeeAllCard(colorScheme);
                }
                return _buildTemplateThumb(previewKinds[i], shareData, colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateThumb(
    ProgressTemplateKind kind,
    ProgressShareData data,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _openTemplatePreview(kind, data),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 54, height: 76,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          clipBehavior: Clip.antiAlias,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: kProgressShareCanvas.width,
              height: kProgressShareCanvas.height,
              child: _buildTemplateWidget(kind, data, showWatermark: false),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 54,
          child: Text(
            kind.label,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSeeAllCard(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _openViralGallery,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 54, height: 76,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.2),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.apps_rounded, size: 22, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text('+${ProgressTemplateKind.values.length - 5}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colorScheme.primary),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 54,
          child: Text('See all',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colorScheme.primary),
          ),
        ),
      ]),
    );
  }

  /// Build the actual viral template widget for the given kind.
  /// Kept inline so the editor-page strip doesn't need to import the gallery
  /// screen's private state.
  Widget _buildTemplateWidget(
    ProgressTemplateKind kind,
    ProgressShareData data, {
    required bool showWatermark,
  }) {
    switch (kind) {
      case ProgressTemplateKind.igStoryCta:
        return IgStoryCtaTemplate(data: data, ctaText: _ctaText, showWatermark: showWatermark);
      case ProgressTemplateKind.wrapped:
        return WrappedTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.receipt:
        return ReceiptTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.tradingCard:
        return TradingCardTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.newspaper:
        return NewspaperTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.polaroidDiary:
        return PolaroidDiaryTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.magazineCover:
        return MagazineCoverTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.retro80s:
        return Retro80sTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.neonTabloid:
        return NeonTabloidTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.swissEditorial:
        return SwissEditorialTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.achievementUnlocked:
        return AchievementUnlockedTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.calendarGrid:
        return CalendarGridTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.progressBar:
        return ProgressBarTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.tapeMeasure:
        return TapeMeasureTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.transformationTuesday:
        return TransformationTuesdayTemplate(data: data, showWatermark: showWatermark);
      case ProgressTemplateKind.timelineRuler:
        return TimelineRulerTemplate(data: data, showWatermark: showWatermark);
    }
  }

  void _openTemplatePreview(ProgressTemplateKind kind, ProgressShareData data) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProgressShareGalleryScreen(
        data: data,
        ctaText: _ctaText,
        initialKind: kind,
      ),
    ));
  }

  ProgressShareData? _buildProgressShareData() {
    if (_selectedPhotos.length < 2) return null;
    final before = _selectedPhotos.first;
    final after = _selectedPhotos.last;
    final authState = ref.read(authStateProvider);
    return ProgressShareData(
      before: before,
      after: after,
      beforeDate: _dateOverrides[0] ?? before.takenAt,
      afterDate: _dateOverrides[_selectedPhotos.length - 1] ?? after.takenAt,
      beforeWeightKg: _resolvePhotoWeight(before),
      afterWeightKg: _resolvePhotoWeight(after),
      username: authState.user?.username,
      totalWorkouts: ref.read(prStatsProvider)?.totalPrs ?? 0,
      currentStreak: ref.read(currentStreakProvider),
      useKg: true,
    );
  }

  void _openViralGallery() {
    final data = _buildProgressShareData();
    if (data == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProgressShareGalleryScreen(data: data, ctaText: _ctaText),
    ));
  }

  Future<void> _shareComparison() async {
    if (_selectedPhotoIndex >= 0) { setState(() => _selectedPhotoIndex = -1); await Future.delayed(const Duration(milliseconds: 50)); }
    try {
      await ComparisonExportService.captureAndShare(_captureKey, pixelRatio: 3.0, targetAspectRatio: _exportRatio);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }
}

/// Ticket-stub clipper for the CTA pill "Ticket" style — notches on the sides.
class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 8.0;
    final path = Path();
    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.arcToPoint(Offset(size.width, size.height - r), radius: const Radius.circular(r), clockwise: false);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.arcToPoint(Offset(0, r), radius: const Radius.circular(r), clockwise: false);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
