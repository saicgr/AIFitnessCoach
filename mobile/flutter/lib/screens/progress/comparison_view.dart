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
import '../../data/repositories/progress_photos_repository.dart';
import '../../widgets/glass_back_button.dart';
import 'comparison_layouts.dart';
import 'comparison_export_service.dart';

// =============================================================================
// StatCategory - Rich stat categories for comparison stats bar
// =============================================================================

enum StatCategory {
  duration('Duration', Icons.timer_outlined),
  weight('Weight', Icons.monitor_weight_outlined),
  body('Body', Icons.straighten),
  strength('Strength', Icons.fitness_center);

  final String label;
  final IconData icon;
  const StatCategory(this.label, this.icon);

  static StatCategory? fromString(String value) {
    for (final cat in StatCategory.values) {
      if (cat.name == value) return cat;
    }
    return null;
  }
}

enum DatePosition {
  left('Left', Icons.format_align_left),
  center('Center', Icons.format_align_center),
  right('Right', Icons.format_align_right);

  final String label;
  final IconData icon;
  const DatePosition(this.label, this.icon);
}

enum PhotoShape {
  rectangle('Rectangle', Icons.crop_square),
  squircle('Squircle', Icons.rounded_corner),
  circle('Circle', Icons.circle_outlined);

  final String label;
  final IconData icon;
  const PhotoShape(this.label, this.icon);

  static PhotoShape fromString(String value) {
    for (final s in PhotoShape.values) {
      if (s.name == value) return s;
    }
    return PhotoShape.rectangle;
  }
}

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

  @override
  void initState() {
    super.initState();
    _initFromExisting();
  }

  void _initFromExisting() {
    final existing = widget.existingComparison;
    if (existing == null) return;

    // Pre-populate from existing comparison
    if (existing.layout != null) {
      _selectedLayout = ComparisonLayout.fromString(existing.layout!);
    }
    if (existing.settingsJson != null) {
      _settings = ComparisonSettings.fromJson(existing.settingsJson!);
      _logoPosition = Offset(_settings.logoDx, _settings.logoDy);
      _showStats = _settings.showStats;

      // Restore date positions
      for (final entry in _settings.datePositions.entries) {
        if (entry.value.length == 2) {
          _datePositions[entry.key] = Offset(entry.value[0], entry.value[1]);
        }
      }

      // Restore stats position
      if (_settings.statsPosition != null &&
          _settings.statsPosition!.length == 2) {
        _statsPosition = Offset(
          _settings.statsPosition![0],
          _settings.statsPosition![1],
        );
      }

      // Restore rich stats settings
      _enabledStatCategories = _settings.enabledStatCategories
          .map((s) => StatCategory.fromString(s))
          .whereType<StatCategory>()
          .toSet();
      if (_enabledStatCategories.isEmpty) {
        _enabledStatCategories = {StatCategory.duration, StatCategory.weight};
      }
      _showPhotoWeights = _settings.showPhotoWeights;

      // Restore style settings
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
    }
    if (existing.aiSummary != null) {
      _aiSummary = existing.aiSummary;
    }

    // Collect photos from the existing comparison
    _selectedPhotos = [existing.beforePhoto, existing.afterPhoto];

    // Jump directly to customize step
    _currentStep = 2;
  }

  // ---------------------------------------------------------------------------
  // Computed helpers
  // ---------------------------------------------------------------------------

  bool get _hasEnoughPhotos {
    final layout = _selectedLayout;
    if (layout.isVariable) {
      return _selectedPhotos.length >= layout.minPhotos;
    }
    return _selectedPhotos.length == layout.photoCount;
  }

  int get _maxPhotoCount => _selectedLayout.maxPhotos;

  Color _resolveBackgroundColor(ColorScheme colorScheme) {
    switch (_settings.backgroundColor) {
      case '#FFFFFF':
        return Colors.white;
      case 'theme':
        return colorScheme.surface;
      case 'gradient_midnight':
        return const Color(0xFF1a1a2e);
      case 'gradient_ocean':
        return const Color(0xFF0f2027);
      case 'gradient_ember':
        return const Color(0xFF2d1b3d);
      case 'gradient_forest':
        return const Color(0xFF0a1612);
      case '#000000':
      default:
        return Colors.black;
    }
  }

  BoxDecoration _resolveBackgroundDecoration(ColorScheme colorScheme) {
    switch (_settings.backgroundColor) {
      case 'gradient_midnight':
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
          borderRadius: BorderRadius.circular(4),
        );
      case 'gradient_ocean':
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
          ),
          borderRadius: BorderRadius.circular(4),
        );
      case 'gradient_ember':
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2d1b3d), Color(0xFF6b2737), Color(0xFFc94b4b)],
          ),
          borderRadius: BorderRadius.circular(4),
        );
      case 'gradient_forest':
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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

  // ---------------------------------------------------------------------------
  // App Bar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    const titles = ['Choose Layout', 'Select Photos', 'Customize'];
    return AppBar(
      title: Text(titles[_currentStep]),
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: GlassBackButton(
        onTap: () {
          if (_currentStep > 0 && widget.existingComparison == null) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      actions: _currentStep == 2
          ? [
              IconButton(
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onSurface,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                tooltip: 'Save comparison',
                onPressed: _isSaving ? null : _saveComparison,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: _isSaving ? null : _shareComparison,
              ),
            ]
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Step Indicator
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    const labels = ['Layout', 'Photos', 'Customize'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: List.generate(5, (i) {
          // Indices: 0=circle, 1=line, 2=circle, 3=line, 4=circle
          if (i.isOdd) {
            // Line connector
            final beforeStep = i ~/ 2;
            final isCompleted = beforeStep < _currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            );
          }
          // Circle
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isActive
                        ? colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isCompleted || isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check,
                            size: 16, color: colorScheme.onPrimary)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive || isCompleted
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step Content Router
  // ---------------------------------------------------------------------------

  Widget _buildStepContent(ColorScheme colorScheme) {
    switch (_currentStep) {
      case 0:
        return _buildLayoutStep(colorScheme);
      case 1:
        return _buildPhotosStep(colorScheme);
      case 2:
        return _buildCustomizeStep(colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ===========================================================================
  // STEP 1 - Choose Layout
  // ===========================================================================

  Widget _buildLayoutStep(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildLayoutGroup(
          title: '2-Photo Layouts',
          layouts: twoPhotoLayouts,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),
        _buildLayoutGroup(
          title: 'Multi-Photo Layouts',
          layouts: multiPhotoLayouts,
          colorScheme: colorScheme,
        ),
      ],
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
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: layouts.length,
          itemBuilder: (context, index) {
            final layout = layouts[index];
            final isSelected = _selectedLayout == layout;
            return _LayoutCard(
              layout: layout,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedLayout = layout),
              colorScheme: colorScheme,
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2 - Select Photos
  // ===========================================================================

  Widget _buildPhotosStep(ColorScheme colorScheme) {
    final state = ref.watch(progressPhotosNotifierProvider(widget.userId));
    final allPhotos = state.photos;

    // Apply view type filter
    final filteredPhotos = _filterViewType != null
        ? allPhotos.where((p) => p.viewTypeEnum == _filterViewType).toList()
        : allPhotos;

    // Sort newest first
    final sortedPhotos = List<ProgressPhoto>.from(filteredPhotos)
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

    final labels = _selectedLayout.getLabels(_selectedPhotos.length);
    final isVariable = _selectedLayout.isVariable;

    return Column(
      children: [
        // Photo slot indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.photo_library, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                isVariable
                    ? '${_selectedPhotos.length} selected (${_selectedLayout.minPhotos}-${_selectedLayout.maxPhotos} photos)'
                    : '${_selectedPhotos.length} / ${_selectedLayout.photoCount} selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_selectedPhotos.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  onPressed: () => setState(() => _selectedPhotos.clear()),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),

        // Selected photos preview row
        if (_selectedPhotos.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _selectedPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final photo = _selectedPhotos[index];
                final label = index < labels.length
                    ? labels[index]
                    : 'Photo ${index + 1}';
                return _SelectedPhotoChip(
                  photo: photo,
                  label: label,
                  orderNumber: index + 1,
                  colorScheme: colorScheme,
                  onRemove: () {
                    setState(() => _selectedPhotos.removeAt(index));
                  },
                );
              },
            ),
          ),

        if (_selectedPhotos.isNotEmpty) const SizedBox(height: 8),

        // View type filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _filterViewType == null,
                  onSelected: (_) =>
                      setState(() => _filterViewType = null),
                ),
              ),
              ...PhotoViewType.values
                  .where((t) => allPhotos.any((p) => p.viewTypeEnum == t))
                  .map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type.displayName),
                    selected: _filterViewType == type,
                    onSelected: (_) => setState(() {
                      _filterViewType =
                          _filterViewType == type ? null : type;
                    }),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Photo grid
        Expanded(
          child: sortedPhotos.isEmpty
              ? _buildEmptyPhotosState(colorScheme)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: sortedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = sortedPhotos[index];
                    final selectedIndex = _selectedPhotos
                        .indexWhere((p) => p.id == photo.id);
                    final isSelected = selectedIndex >= 0;
                    final canSelect =
                        isSelected || _selectedPhotos.length < _maxPhotoCount;

                    return _PhotoGridCard(
                      photo: photo,
                      isSelected: isSelected,
                      orderNumber: isSelected ? selectedIndex + 1 : null,
                      enabled: canSelect,
                      colorScheme: colorScheme,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPhotos
                                .removeWhere((p) => p.id == photo.id);
                          } else if (canSelect) {
                            _selectedPhotos.add(photo);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyPhotosState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Photos Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filterViewType != null
                  ? 'No ${_filterViewType!.displayName} photos yet. Try a different filter.'
                  : 'Take some progress photos first to create a comparison.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 3 - Customize & Export
  // ===========================================================================

  Widget _buildCustomizeStep(ColorScheme colorScheme) {
    final bgColor = _resolveBackgroundColor(colorScheme);

    return Column(
      children: [
        // Canvas area
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
                        // 1. Photo layout
                        Positioned.fill(
                          child: Padding(
                            padding: _computeCanvasPhotoPadding(),
                            child: _buildCanvasLayout(bgColor),
                          ),
                        ),

                        // 2. Background decorative pattern
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CanvasPatternPainter(bgColor),
                            ),
                          ),
                        ),

                        // 3. Branding footer
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildBrandingFooter(bgColor),
                        ),

                        // 4. Draggable stats bar
                        if (_showStats && _buildRichStatsData() != null)
                          _buildDraggableStatsBar(bgColor),

                        // 5. AI Summary
                        if (_settings.showAiSummary && _aiSummary != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 28,
                            child: _buildAiSummaryOverlay(bgColor),
                          ),

                        // 6. Draggable date chips
                        if (_settings.showDates) _buildDateOverlays(),

                        // 7. Draggable logo
                        if (_settings.showLogo)
                          Positioned(
                            left: _logoPosition.dx,
                            top: _logoPosition.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _logoPosition += details.delta;
                                });
                              },
                              child: _buildAppIconLogo(),
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

        // Toolbar
        _buildToolbar(colorScheme),
      ],
    );
  }

  EdgeInsets _computeCanvasPhotoPadding() {
    double bottom = 28; // branding footer height
    if (_settings.showAiSummary && _aiSummary != null) {
      bottom += 60;
    }
    final statsH = _computeStatsBarHeight();
    if (statsH > 0) {
      bottom += statsH;
    }
    return EdgeInsets.only(bottom: bottom);
  }

  // ---------------------------------------------------------------------------
  // Canvas layout renderers
  // ---------------------------------------------------------------------------

  Widget _buildCanvasLayout(Color bgColor) {
    if (_selectedPhotos.isEmpty) {
      return const Center(
        child: Text(
          'No photos selected',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    switch (_selectedLayout) {
      case ComparisonLayout.sideBySide:
        return _buildSideBySideLayout();
      case ComparisonLayout.slider:
        return _buildSliderLayout();
      case ComparisonLayout.verticalStack:
        return _buildVerticalStackLayout();
      case ComparisonLayout.story:
        return _buildStoryLayout(bgColor);
      case ComparisonLayout.diagonalSplit:
        return _buildDiagonalSplitLayout();
      case ComparisonLayout.polaroid:
        return _buildPolaroidLayout(bgColor);
      case ComparisonLayout.triptych:
        return _buildTriptychLayout();
      case ComparisonLayout.fourPanel:
        return _buildFourPanelLayout();
      case ComparisonLayout.monthlyGrid:
        return _buildMonthlyGridLayout();
    }
  }

  BorderRadius? get _shapeBorderRadius {
    switch (_photoShape) {
      case PhotoShape.squircle:
        return BorderRadius.circular(_squircleRadius);
      case PhotoShape.circle:
        return BorderRadius.circular(9999);
      case PhotoShape.rectangle:
        return null;
    }
  }

  /// Wraps an entire overlay layout (slider, diagonal) with shape clip + border.
  Widget _applyLayoutShapeAndBorder(Widget content) {
    final br = _shapeBorderRadius;
    if (br != null) {
      content = ClipRRect(borderRadius: br, child: content);
    }
    if (_photoBorderEnabled && _photoBorderWidth > 0) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _photoBorderColor,
            width: _photoBorderWidth,
          ),
          borderRadius: br,
        ),
        child: content,
      );
    }
    return content;
  }

  Widget _buildPhotoWidget(ProgressPhoto photo, int index,
      {BoxFit fit = BoxFit.cover}) {
    final isSelected = _selectedPhotoIndex == index;
    final weight = _showPhotoWeights ? _resolvePhotoWeight(photo) : null;
    final br = _shapeBorderRadius;

    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        _PannablePhoto(
          photo: photo,
          fit: fit,
          isSelected: isSelected,
          onTap: () => setState(() {
            _selectedPhotoIndex =
                _selectedPhotoIndex == index ? -1 : index;
          }),
        ),
        // Per-photo weight label
        if (weight != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${weight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Selection highlight border
        if (isSelected)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.green, width: 2.5),
                borderRadius: br,
              ),
            ),
          ),
        // Delete button (top-right corner)
        if (isSelected)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedPhotos.removeAt(index);
                _selectedPhotoIndex = -1;
                _resetOverlayPositions();
              }),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 1),
                ),
                child: const Icon(Icons.close,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );

    // Apply shape clipping
    if (br != null) {
      content = ClipRRect(borderRadius: br, child: content);
    }

    // Apply photo border
    if (_photoBorderEnabled && _photoBorderWidth > 0) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _photoBorderColor,
            width: _photoBorderWidth,
          ),
          borderRadius: br,
        ),
        child: br != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(
                  max(0, (br.topLeft.x) - _photoBorderWidth),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [content],
                ),
              )
            : content,
      );
    }

    return content;
  }

  // -- Side by side --
  Widget _buildSideBySideLayout() {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.length < 2) return _buildPhotoWidget(photos.first, 0);

    return Row(
      children: [
        Expanded(child: _buildPhotoWidget(photos[0], 0)),
        SizedBox(width: _photoSpacing),
        Expanded(child: _buildPhotoWidget(photos[1], 1)),
      ],
    );
  }

  // -- Slider --
  Widget _buildSliderLayout() {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.length < 2) return _buildPhotoWidget(photos.first, 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderPosition +=
                  details.delta.dx / constraints.maxWidth;
              _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
            });
          },
          child: Stack(
            children: [
              // After photo (full, behind)
              SizedBox.expand(
                child: CachedNetworkImage(
                  imageUrl: photos[1].photoUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                ),
              ),
              // Before photo (clipped)
              ClipRect(
                clipper: _SliderClipper(
                    _sliderPosition * constraints.maxWidth),
                child: SizedBox.expand(
                  child: CachedNetworkImage(
                    imageUrl: photos[0].photoUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    memCacheHeight: 600,
                  ),
                ),
              ),
              // Slider handle
              Positioned(
                left:
                    _sliderPosition * constraints.maxWidth - 16,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 32,
                  child: Center(
                    child: Container(
                      width: 3,
                      color: Colors.white,
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows,
                            color: Colors.black87,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Before / After labels
              Positioned(top: 8, left: 8, child: _buildLabel('Before')),
              Positioned(top: 8, right: 8, child: _buildLabel('After')),
            ],
          ),
        );
        return _applyLayoutShapeAndBorder(content);
      },
    );
  }

  // -- Vertical stack --
  Widget _buildVerticalStackLayout() {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.length < 2) return _buildPhotoWidget(photos.first, 0);

    return Column(
      children: [
        Expanded(child: _buildPhotoWidget(photos[0], 0)),
        SizedBox(height: _photoSpacing),
        Expanded(child: _buildPhotoWidget(photos[1], 1)),
      ],
    );
  }

  // -- Story (9:16 with branding) --
  Widget _buildStoryLayout(Color bgColor) {
    final photos = _selectedPhotos.take(2).toList();
    final textColor =
        bgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;

    return Column(
      children: [
        // Top brand area
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'MY PROGRESS',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
        // Photos area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: photos.length >= 2
                ? Row(
                    children: [
                      Expanded(
                        child: _buildPhotoWidget(photos[0], 0),
                      ),
                      SizedBox(width: _photoSpacing),
                      Expanded(
                        child: _buildPhotoWidget(photos[1], 1),
                      ),
                    ],
                  )
                : _buildPhotoWidget(photos.first, 0),
          ),
        ),
        // Bottom stats area
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildStoryStats(textColor),
        ),
      ],
    );
  }

  Widget _buildStoryStats(Color textColor) {
    final statsData = _buildRichStatsData();
    if (statsData == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statsData.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.value.first,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                e.key.label,
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // -- Diagonal split --
  Widget _buildDiagonalSplitLayout() {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.length < 2) return _buildPhotoWidget(photos.first, 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = Stack(
          children: [
            // Bottom (After) photo
            SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: photos[1].photoUrl,
                fit: BoxFit.cover,
                memCacheWidth: 600,
                memCacheHeight: 600,
              ),
            ),
            // Top (Before) photo - clipped diagonally
            ClipPath(
              clipper: _DiagonalClipper(),
              child: SizedBox.expand(
                child: CachedNetworkImage(
                  imageUrl: photos[0].photoUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                ),
              ),
            ),
            // Diagonal line
            CustomPaint(
              size:
                  Size(constraints.maxWidth, constraints.maxHeight),
              painter: _DiagonalLinePainter(),
            ),
            Positioned(
                top: 8, left: 8, child: _buildLabel('Before')),
            Positioned(
                bottom: 8, right: 8, child: _buildLabel('After')),
          ],
        );
        return _applyLayoutShapeAndBorder(content);
      },
    );
  }

  // -- Polaroid --
  Widget _buildPolaroidLayout(Color bgColor) {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gapOffset = _photoSpacing / 2;
            final maxW = constraints.maxWidth * 0.42 - gapOffset;
            final maxH = constraints.maxHeight * 0.75;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (photos.isNotEmpty)
                  Positioned(
                    left: constraints.maxWidth * 0.04 + gapOffset,
                    child: Transform.rotate(
                      angle: -0.06,
                      child: _buildPolaroidFrame(
                          photos[0], maxW, maxH, bgColor),
                    ),
                  ),
                if (photos.length >= 2)
                  Positioned(
                    right: constraints.maxWidth * 0.04 + gapOffset,
                    child: Transform.rotate(
                      angle: 0.05,
                      child: _buildPolaroidFrame(
                          photos[1], maxW, maxH, bgColor),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPolaroidFrame(
    ProgressPhoto photo,
    double width,
    double height,
    Color bgColor,
  ) {
    final frameBg =
        bgColor == Colors.white ? Colors.white : Colors.grey[100]!;
    final imageRadius = _shapeBorderRadius ?? BorderRadius.circular(2);

    Widget imageContent = ClipRRect(
      borderRadius: imageRadius,
      child: CachedNetworkImage(
        imageUrl: photo.photoUrl,
        fit: BoxFit.cover,
        memCacheWidth: 600,
        memCacheHeight: 600,
      ),
    );

    // Apply photo border inside the polaroid frame
    if (_photoBorderEnabled && _photoBorderWidth > 0) {
      imageContent = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _photoBorderColor,
            width: _photoBorderWidth,
          ),
          borderRadius: imageRadius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            max(0, imageRadius.topLeft.x - _photoBorderWidth),
          ),
          child: CachedNetworkImage(
            imageUrl: photo.photoUrl,
            fit: BoxFit.cover,
            memCacheWidth: 600,
            memCacheHeight: 600,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: frameBg,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
      child: imageContent,
    );
  }

  // -- Triptych (3 photos) --
  Widget _buildTriptychLayout() {
    final photos = _selectedPhotos.take(3).toList();
    final halfGap = _photoSpacing / 2;
    return Row(
      children: photos.asMap().entries.map((entry) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: entry.key == 0 ? 0 : halfGap,
              right: entry.key == photos.length - 1 ? 0 : halfGap,
            ),
            child: _buildPhotoWidget(entry.value, entry.key),
          ),
        );
      }).toList(),
    );
  }

  // -- Four panel (2x2) --
  Widget _buildFourPanelLayout() {
    final photos = _selectedPhotos.take(4).toList();
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              if (photos.isNotEmpty)
                Expanded(child: _buildPhotoWidget(photos[0], 0)),
              SizedBox(width: _photoSpacing),
              if (photos.length > 1)
                Expanded(child: _buildPhotoWidget(photos[1], 1)),
            ],
          ),
        ),
        SizedBox(height: _photoSpacing),
        Expanded(
          child: Row(
            children: [
              if (photos.length > 2)
                Expanded(child: _buildPhotoWidget(photos[2], 2)),
              SizedBox(width: _photoSpacing),
              if (photos.length > 3)
                Expanded(child: _buildPhotoWidget(photos[3], 3)),
            ],
          ),
        ),
      ],
    );
  }

  // -- Monthly grid --
  Widget _buildMonthlyGridLayout() {
    final photos = _selectedPhotos;
    if (photos.isEmpty) return const SizedBox.shrink();

    final cols = max(2, min(4, sqrt(photos.length).ceil()));

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: _photoSpacing,
        crossAxisSpacing: _photoSpacing,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return _buildPhotoWidget(photos[index], index);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Overlays
  // ---------------------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _dateAlignX(double segmentLeft, double segmentWidth, double chipWidth) {
    switch (_datePosition) {
      case DatePosition.left:
        return segmentLeft + 6;
      case DatePosition.center:
        return segmentLeft + (segmentWidth - chipWidth) / 2;
      case DatePosition.right:
        return segmentLeft + segmentWidth - chipWidth - 6;
    }
  }

  Offset _computeDefaultDatePosition(
    int index,
    int totalPhotos,
    BoxConstraints constraints,
  ) {
    final isHorizontal = _selectedLayout == ComparisonLayout.sideBySide ||
        _selectedLayout == ComparisonLayout.triptych;
    final footerH = 28.0;
    const chipW = 80.0; // approximate chip width

    if (isHorizontal && totalPhotos > 1) {
      final segmentWidth = constraints.maxWidth / totalPhotos;
      final x = _dateAlignX(index * segmentWidth, segmentWidth, chipW);
      return Offset(x, constraints.maxHeight - footerH - 24);
    }

    if (_selectedLayout == ComparisonLayout.verticalStack && totalPhotos >= 2) {
      final segmentHeight = constraints.maxHeight / totalPhotos;
      final x = _dateAlignX(0, constraints.maxWidth, chipW);
      return Offset(x, (index + 1) * segmentHeight - footerH - 24);
    }

    // Slider / diagonal / polaroid / others
    if (totalPhotos >= 2) {
      if (index == 0) {
        final x = _dateAlignX(0, constraints.maxWidth / 2, chipW);
        return Offset(x, constraints.maxHeight - footerH - 24);
      }
      final x = _dateAlignX(constraints.maxWidth / 2, constraints.maxWidth / 2, chipW);
      return Offset(x, constraints.maxHeight - footerH - 24);
    }

    final x = _dateAlignX(0, constraints.maxWidth, chipW);
    return Offset(x, constraints.maxHeight - footerH - 24);
  }

  Widget _buildDateOverlays() {
    if (_selectedPhotos.isEmpty) return const SizedBox.shrink();

    final labels = _selectedLayout.getLabels(_selectedPhotos.length);
    final photosToLabel = _selectedPhotos.take(labels.length).toList();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: photosToLabel.asMap().entries.map((entry) {
              final photo = entry.value;
              final i = entry.key;
              final pos = _datePositions[i] ??
                  _computeDefaultDatePosition(
                      i, photosToLabel.length, constraints);

              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final current = _datePositions[i] ??
                          _computeDefaultDatePosition(
                              i, photosToLabel.length, constraints);
                      _datePositions[i] = Offset(
                        (current.dx + details.delta.dx)
                            .clamp(0, constraints.maxWidth - 80),
                        (current.dy + details.delta.dy)
                            .clamp(0, constraints.maxHeight - 20),
                      );
                    });
                  },
                  child: _buildDateChip(photo),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDateChip(ProgressPhoto photo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        DateFormat('MMM d, yyyy').format(photo.takenAt),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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

    // Fallback: find closest weight measurement within 7 days
    final measState = ref.read(measurementsProvider);
    final weightHistory = measState.historyByType[MeasurementType.weight];
    if (weightHistory == null || weightHistory.isEmpty) return null;

    return _findClosestMeasurementValue(weightHistory, photo.takenAt);
  }

  double? _findClosestMeasurementValue(
    List<MeasurementEntry> history,
    DateTime target,
  ) {
    MeasurementEntry? closest;
    int closestDiff = 8; // > 7 days threshold

    for (final entry in history) {
      final diff = entry.recordedAt.difference(target).inDays.abs();
      if (diff < closestDiff) {
        closestDiff = diff;
        closest = entry;
      }
    }

    return closest?.value;
  }

  // ---------------------------------------------------------------------------
  // Rich stats data (multi-category)
  // ---------------------------------------------------------------------------

  Map<StatCategory, List<String>>? _buildRichStatsData() {
    if (_selectedPhotos.length < 2) return null;
    if (_enabledStatCategories.isEmpty) return null;

    final first = _selectedPhotos.first;
    final last = _selectedPhotos.last;
    final result = <StatCategory, List<String>>{};

    // Duration
    if (_enabledStatCategories.contains(StatCategory.duration)) {
      final days = last.takenAt.difference(first.takenAt).inDays.abs();
      String durText;
      if (days == 0) {
        durText = 'Same day';
      } else if (days < 30) {
        durText = '$days days';
      } else if (days < 365) {
        final months = (days / 30).round();
        durText = '$months month${months > 1 ? 's' : ''}';
      } else {
        durText =
            '${(days / 365).round()}y ${((days % 365) / 30).round()}m';
      }
      final items = <String>[durText];
      if (_selectedPhotos.length > 2) {
        items.add('${_selectedPhotos.length} photos');
      }
      if (_filterViewType != null) {
        items.add(_filterViewType!.displayName);
      }
      result[StatCategory.duration] = items;
    }

    // Weight
    if (_enabledStatCategories.contains(StatCategory.weight)) {
      final firstW = _resolvePhotoWeight(first);
      final lastW = _resolvePhotoWeight(last);
      if (firstW != null && lastW != null) {
        final change = lastW - firstW;
        final sign = change > 0 ? '+' : '';
        result[StatCategory.weight] = [
          '${firstW.toStringAsFixed(1)} \u2192 ${lastW.toStringAsFixed(1)} kg',
          '($sign${change.toStringAsFixed(1)} kg)',
        ];
      } else if (firstW != null) {
        result[StatCategory.weight] = ['${firstW.toStringAsFixed(1)} kg'];
      } else if (lastW != null) {
        result[StatCategory.weight] = ['${lastW.toStringAsFixed(1)} kg'];
      }
    }

    // Body measurements
    if (_enabledStatCategories.contains(StatCategory.body)) {
      final measState = ref.read(measurementsProvider);
      final bodyTypes = [
        MeasurementType.chest,
        MeasurementType.waist,
        MeasurementType.hips,
        MeasurementType.bicepsLeft,
        MeasurementType.thighLeft,
        MeasurementType.neck,
        MeasurementType.shoulders,
      ];
      final bodyItems = <String>[];
      for (final type in bodyTypes) {
        final history = measState.historyByType[type];
        if (history == null || history.isEmpty) continue;
        final beforeVal =
            _findClosestMeasurementValue(history, first.takenAt);
        final afterVal =
            _findClosestMeasurementValue(history, last.takenAt);
        if (beforeVal != null && afterVal != null) {
          final delta = afterVal - beforeVal;
          if (delta.abs() >= 0.1) {
            final sign = delta > 0 ? '+' : '';
            // Short label: remove "(L)" / "(R)" for brevity
            final shortName = type.displayName
                .replaceAll(' (L)', '')
                .replaceAll(' (R)', '');
            bodyItems.add(
                '$shortName $sign${delta.toStringAsFixed(1)}${type.metricUnit}');
          }
        }
        if (bodyItems.length >= 4) break; // limit to avoid overflow
      }
      if (bodyItems.isNotEmpty) {
        result[StatCategory.body] = bodyItems;
      }
    }

    // Strength
    if (_enabledStatCategories.contains(StatCategory.strength)) {
      final strengthItems = <String>[];
      final score = ref.read(overallStrengthScoreProvider);
      if (score > 0) {
        strengthItems.add('Score: $score');
      }
      final prStats = ref.read(prStatsProvider);
      if (prStats != null && prStats.totalPrs > 0) {
        strengthItems.add('PRs: ${prStats.totalPrs}');
        if (prStats.prsThisPeriod > 0) {
          strengthItems.add('${prStats.prsThisPeriod} recent');
        }
      }
      if (strengthItems.isNotEmpty) {
        result[StatCategory.strength] = strengthItems;
      }
    }

    return result.isEmpty ? null : result;
  }

  double _computeStatsBarHeight() {
    final data = _buildRichStatsData();
    if (data == null || !_showStats) return 0;
    // Each row is ~20px text + 8px padding top/bottom = ~28px per row, min 36
    final rowCount = data.length;
    return max(36, rowCount * 22.0 + 16);
  }

  Widget _buildStatsBar(Color bgColor) {
    final data = _buildRichStatsData();
    if (data == null) return const SizedBox.shrink();

    final textColor = bgColor.computeLuminance() < 0.5
        ? Colors.white
        : Colors.black;

    return Container(
      color: bgColor.withOpacity(0.85),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              entry.value.join('  \u00B7  '),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withOpacity(0.9),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAiSummaryOverlay(Color bgColor) {
    final textColor = bgColor.computeLuminance() < 0.5
        ? Colors.white
        : Colors.black;

    return Container(
      constraints: const BoxConstraints(maxHeight: 60),
      width: double.infinity,
      color: bgColor.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        _aiSummary ?? '',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor.withOpacity(0.85),
          fontSize: 10,
          fontStyle: FontStyle.italic,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildAppIconLogo() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          'assets/images/app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple]),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.fitness_center,
                size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableStatsBar(Color bgColor) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final footerH = 28.0;
          final aiH = (_settings.showAiSummary && _aiSummary != null) ? 60.0 : 0.0;
          final barH = _computeStatsBarHeight();
          final defaultPos = Offset(0, constraints.maxHeight - footerH - aiH - barH);
          final pos = _statsPosition.dx < 0 ? defaultPos : _statsPosition;

          return Stack(
            children: [
              Positioned(
                left: pos.dx,
                top: pos.dy,
                width: constraints.maxWidth,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final current =
                          _statsPosition.dx < 0 ? defaultPos : _statsPosition;
                      _statsPosition = Offset(
                        (current.dx + details.delta.dx)
                            .clamp(0, 0), // keep full-width, lock x
                        (current.dy + details.delta.dy)
                            .clamp(0, constraints.maxHeight - barH),
                      );
                    });
                  },
                  child: _buildStatsBar(bgColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandingFooter(Color bgColor) {
    final textColor =
        bgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;
    final authState = ref.watch(authStateProvider);
    final username = authState.user?.username;

    return Container(
      height: 28,
      color: bgColor.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Left: app icon + FitWiz
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 16,
              height: 16,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.fitness_center,
                size: 14,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'FitWiz',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Right: @username
          if (username != null && username.isNotEmpty)
            Text(
              '@$username',
              style: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  void _resetOverlayPositions() {
    _datePositions.clear();
    _statsPosition = const Offset(-1, -1);
    _selectedPhotoIndex = -1;
  }

  // ---------------------------------------------------------------------------
  // Toolbar (Step 3)
  // ---------------------------------------------------------------------------

  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Logo toggle
                  _ToolbarChip(
                    label: 'Logo',
                    icon: Icons.auto_awesome,
                    isActive: _settings.showLogo,
                    colorScheme: colorScheme,
                    onTap: () => setState(() {
                      _settings = _settings.copyWith(
                          showLogo: !_settings.showLogo);
                    }),
                  ),
                  const SizedBox(width: 8),

                  // Stats toggle
                  _ToolbarChip(
                    label: 'Stats',
                    icon: Icons.bar_chart,
                    isActive: _showStats,
                    colorScheme: colorScheme,
                    onTap: () => setState(() {
                      _showStats = !_showStats;
                    }),
                  ),
                  const SizedBox(width: 8),

                  // Weights toggle (per-photo weight labels)
                  _ToolbarChip(
                    label: 'Weights',
                    icon: Icons.monitor_weight_outlined,
                    isActive: _showPhotoWeights,
                    colorScheme: colorScheme,
                    onTap: () => setState(() {
                      _showPhotoWeights = !_showPhotoWeights;
                    }),
                  ),
                  const SizedBox(width: 8),

                  // Dates toggle
                  _ToolbarChip(
                    label: 'Dates',
                    icon: Icons.calendar_today,
                    isActive: _settings.showDates,
                    colorScheme: colorScheme,
                    onTap: () => setState(() {
                      _settings = _settings.copyWith(
                          showDates: !_settings.showDates);
                    }),
                  ),
                  const SizedBox(width: 8),

                  // AI Summary
                  _ToolbarChip(
                    label: 'AI Summary',
                    icon: Icons.auto_fix_high,
                    isActive: _settings.showAiSummary,
                    isLoading: _isLoadingAiSummary,
                    colorScheme: colorScheme,
                    onTap: _handleAiSummaryToggle,
                  ),
                  const SizedBox(width: 16),

                  // Background color picker
                  _buildBgColorPicker(colorScheme),
                  const SizedBox(width: 16),

                  // Aspect ratio chips
                  ..._buildAspectRatioChips(colorScheme),
                ],
              ),
            ),

            // Stat category pills (shown when Stats is active)
            _buildStatCategoryPills(colorScheme),

            // Date position pills (shown when Dates is active)
            _buildDatePositionPills(colorScheme),

            // Style controls: Shape, Border, Spacing
            _buildStyleControls(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCategoryPills(ColorScheme colorScheme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _showStats
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: StatCategory.values.map((cat) {
                  final isActive = _enabledStatCategories.contains(cat);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (isActive) {
                          _enabledStatCategories.remove(cat);
                        } else {
                          _enabledStatCategories.add(cat);
                        }
                        // Reset stats position so it recalculates with new height
                        _statsPosition = const Offset(-1, -1);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 13,
                              color: isActive
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDatePositionPills(ColorScheme colorScheme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _settings.showDates
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    'Align',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...DatePosition.values.map((pos) {
                    final isActive = _datePosition == pos;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _datePosition = pos;
                          _datePositions.clear(); // recalculate defaults
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pos.icon,
                                size: 13,
                                color: isActive
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pos.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isActive
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildStyleControls(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Shape selection + border toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Shape label
                Text(
                  'Shape',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                // Shape pills
                ...PhotoShape.values.map((shape) {
                  final isActive = _photoShape == shape;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _photoShape = shape),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(shape.icon, size: 13,
                              color: isActive
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(shape.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              )),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 12),

                // Border toggle
                _ToolbarChip(
                  label: 'Border',
                  icon: Icons.border_style,
                  isActive: _photoBorderEnabled,
                  colorScheme: colorScheme,
                  onTap: () => setState(() {
                    _photoBorderEnabled = !_photoBorderEnabled;
                  }),
                ),
              ],
            ),
          ),

          // Row 2: Squircle radius (when squircle selected)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _photoShape == PhotoShape.squircle
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text('Radius',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          )),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: _squircleRadius,
                              min: 0,
                              max: 48,
                              onChanged: (v) =>
                                  setState(() => _squircleRadius = v),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${_squircleRadius.round()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Row 3: Border controls (when border enabled)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _photoBorderEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text('Width',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          )),
                        SizedBox(
                          width: 100,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: _photoBorderWidth,
                              min: 1,
                              max: 8,
                              onChanged: (v) =>
                                  setState(() => _photoBorderWidth = v),
                            ),
                          ),
                        ),
                        Text('${_photoBorderWidth.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          )),
                        const SizedBox(width: 12),
                        // Border color dots
                        ..._buildBorderColorDots(colorScheme),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Row 4: Spacing control
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Text('Gap',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  )),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: _photoSpacing,
                      min: 0,
                      max: 24,
                      onChanged: (v) =>
                          setState(() => _photoSpacing = v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${_photoSpacing.round()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBorderColorDots(ColorScheme colorScheme) {
    final colors = <MapEntry<Color, String>>[
      const MapEntry(Colors.white, '#FFFFFF'),
      const MapEntry(Colors.black, '#000000'),
      const MapEntry(Color(0xFF4CAF50), '#4CAF50'),
      const MapEntry(Color(0xFF2196F3), '#2196F3'),
      const MapEntry(Color(0xFFFF9800), '#FF9800'),
    ];

    return colors.map((entry) {
      final isSelected = _photoBorderColor.value == entry.key.value;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: () => setState(() => _photoBorderColor = entry.key),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: entry.key,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBgColorPicker(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'BG',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        // Solid colors
        _buildColorDot(
          color: Colors.black,
          isSelected: _settings.backgroundColor == '#000000',
          onTap: () => setState(() {
            _settings =
                _settings.copyWith(backgroundColor: '#000000');
          }),
        ),
        const SizedBox(width: 4),
        _buildColorDot(
          color: Colors.white,
          isSelected: _settings.backgroundColor == '#FFFFFF',
          onTap: () => setState(() {
            _settings =
                _settings.copyWith(backgroundColor: '#FFFFFF');
          }),
        ),
        const SizedBox(width: 4),
        _buildColorDot(
          color: colorScheme.surface,
          isSelected: _settings.backgroundColor == 'theme',
          borderColor: colorScheme.outline,
          onTap: () => setState(() {
            _settings =
                _settings.copyWith(backgroundColor: 'theme');
          }),
        ),
        const SizedBox(width: 8),
        // Gradient presets
        _buildGradientDot(
          colors: const [Color(0xFF1a1a2e), Color(0xFF0f3460)],
          isSelected: _settings.backgroundColor == 'gradient_midnight',
          onTap: () => setState(() {
            _settings =
                _settings.copyWith(backgroundColor: 'gradient_midnight');
          }),
        ),
        const SizedBox(width: 4),
        _buildGradientDot(
          colors: const [Color(0xFF0f2027), Color(0xFF2c5364)],
          isSelected: _settings.backgroundColor == 'gradient_ocean',
          onTap: () => setState(() {
            _settings =
                _settings.copyWith(backgroundColor: 'gradient_ocean');
          }),
        ),
        const SizedBox(width: 4),
        _buildGradientDot(
          colors: const [Color(0xFF2d1b3d), Color(0xFFc94b4b)],
          isSelected: _settings.backgroundColor == 'gradient_ember',
          onTap: () => setState(() {
            _settings =
                _settings.copyWith(backgroundColor: 'gradient_ember');
          }),
        ),
        const SizedBox(width: 4),
        _buildGradientDot(
          colors: const [Color(0xFF0a1612), Color(0xFF2d5a42)],
          isSelected: _settings.backgroundColor == 'gradient_forest',
          onTap: () => setState(() {
            _settings =
                _settings.copyWith(backgroundColor: 'gradient_forest');
          }),
        ),
      ],
    );
  }

  Widget _buildColorDot({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : borderColor ?? Colors.grey,
            width: isSelected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientDot({
    required List<Color> colors,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            width: isSelected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAspectRatioChips(ColorScheme colorScheme) {
    return ExportAspectRatio.values.map((ratio) {
      final isSelected = _settings.exportAspectRatio == ratio.label;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => setState(() {
            _settings = _settings.copyWith(
                exportAspectRatio: ratio.label);
            _resetOverlayPositions();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              ratio.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Bottom bar (steps 0 & 1)
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(ColorScheme colorScheme) {
    if (_currentStep == 2) return const SizedBox.shrink();

    final canProceed = _currentStep == 0 ? true : _hasEnoughPhotos;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: canProceed
              ? () {
                  if (_currentStep == 0) {
                    // Trim photos if layout changed and count mismatch
                    if (_selectedPhotos.length > _maxPhotoCount) {
                      _selectedPhotos =
                          _selectedPhotos.sublist(0, _maxPhotoCount);
                    }
                    _resetOverlayPositions();
                  }
                  if (_currentStep == 1) {
                    _resetOverlayPositions();
                  }
                  setState(() => _currentStep++);
                }
              : null,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(
            _currentStep == 0
                ? 'Next: Select Photos'
                : 'Next: Customize',
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _handleAiSummaryToggle() {
    if (_settings.showAiSummary) {
      // Turn off
      setState(() {
        _settings = _settings.copyWith(showAiSummary: false);
      });
      return;
    }

    // Turn on - load summary if needed
    if (_aiSummary != null) {
      setState(() {
        _settings = _settings.copyWith(showAiSummary: true);
      });
      return;
    }

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
      if (first.bodyWeightKg != null && last.bodyWeightKg != null) {
        weightChange = last.bodyWeightKg! - first.bodyWeightKg!;
      }

      final summary = await ref
          .read(progressPhotosRepositoryProvider)
          .getAiSummary(
            beforePhotoUrl: first.photoUrl,
            afterPhotoUrl: last.photoUrl,
            daysBetween: days,
            weightChangeKg: weightChange,
          );

      if (mounted) {
        setState(() {
          _aiSummary = summary;
          _isLoadingAiSummary = false;
          _settings = _settings.copyWith(showAiSummary: true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAiSummary = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate AI summary: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveComparison() async {
    if (_selectedPhotos.length < 2) return;

    setState(() {
      _isSaving = true;
      _selectedPhotoIndex = -1; // Clear selection for clean capture
    });

    try {
      // Build settings with current positions
      final datePosMap = <int, List<double>>{};
      for (final entry in _datePositions.entries) {
        datePosMap[entry.key] = [entry.value.dx, entry.value.dy];
      }
      final finalSettings = _settings.copyWith(
        layout: _selectedLayout.value,
        logoDx: _logoPosition.dx,
        logoDy: _logoPosition.dy,
        showStats: _showStats,
        datePositions: datePosMap,
        statsPosition: _statsPosition.dx >= 0
            ? [_statsPosition.dx, _statsPosition.dy]
            : null,
        enabledStatCategories:
            _enabledStatCategories.map((c) => c.name).toList(),
        showPhotoWeights: _showPhotoWeights,
        datePosition: _datePosition.name,
        photoShape: _photoShape.name,
        squircleRadius: _squircleRadius,
        photoBorderEnabled: _photoBorderEnabled,
        photoBorderColor: _borderColorToHex(_photoBorderColor),
        photoBorderWidth: _photoBorderWidth,
        photoSpacing: _photoSpacing,
      );

      final labels =
          _selectedLayout.getLabels(_selectedPhotos.length);
      final photosJsonList =
          _selectedPhotos.asMap().entries.map((entry) {
        return {
          'photo_id': entry.value.id,
          'order': entry.key,
          'label': labels[min(entry.key, labels.length - 1)],
        };
      }).toList();

      final notifier = ref.read(
        progressPhotosNotifierProvider(widget.userId).notifier,
      );

      if (widget.existingComparison != null) {
        await notifier.updateComparison(
          comparisonId: widget.existingComparison!.id,
          layout: _selectedLayout.value,
          settingsJson: finalSettings.toJson(),
          aiSummary: _aiSummary,
          photosJson: photosJsonList,
        );
      } else {
        // Create the comparison first, then update with full settings
        final created = await notifier.createComparison(
          beforePhotoId: _selectedPhotos.first.id,
          afterPhotoId: _selectedPhotos.last.id,
          title: '${_selectedLayout.displayName} Comparison',
        );
        if (created == null) {
          throw Exception('Failed to create comparison');
        }
        // Now update with layout, settings, photos, and AI summary
        await notifier.updateComparison(
          comparisonId: created.id,
          layout: _selectedLayout.value,
          settingsJson: finalSettings.toJson(),
          aiSummary: _aiSummary,
          photosJson: photosJsonList,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comparison saved!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareComparison() async {
    // Clear selection so it doesn't appear in export
    if (_selectedPhotoIndex >= 0) {
      setState(() => _selectedPhotoIndex = -1);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    try {
      await ComparisonExportService.captureAndShare(
        _captureKey,
        pixelRatio: 3.0,
        targetAspectRatio: _exportRatio,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// =============================================================================
// Supporting Widgets
// =============================================================================

/// A tappable layout card for Step 1
class _LayoutCard extends StatelessWidget {
  final ComparisonLayout layout;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _LayoutCard({
    required this.layout,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.green.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.green
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LayoutPreviewIcon(
                    layout: layout,
                    isSelected: isSelected,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    layout.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.green
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    layout.aspectRatioHint,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chip showing a selected photo in Step 2
class _SelectedPhotoChip extends StatelessWidget {
  final ProgressPhoto photo;
  final String label;
  final int orderNumber;
  final ColorScheme colorScheme;
  final VoidCallback onRemove;

  const _SelectedPhotoChip({
    required this.photo,
    required this.label,
    required this.orderNumber,
    required this.colorScheme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
            fit: BoxFit.cover,
          ),
          // Order badge
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$orderNumber',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 12, color: Colors.white),
              ),
            ),
          ),
          // Label at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: Colors.black54,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A photo card in the selection grid (Step 2)
class _PhotoGridCard extends StatelessWidget {
  final ProgressPhoto photo;
  final bool isSelected;
  final int? orderNumber;
  final bool enabled;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PhotoGridCard({
    required this.photo,
    required this.isSelected,
    this.orderNumber,
    required this.enabled,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(isSelected ? 5 : 8),
              child: CachedNetworkImage(
                imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
                fit: BoxFit.cover,
                color: !enabled && !isSelected
                    ? Colors.black.withOpacity(0.5)
                    : null,
                colorBlendMode:
                    !enabled && !isSelected ? BlendMode.darken : null,
              ),
            ),

            // Order badge
            if (isSelected && orderNumber != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$orderNumber',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Date + weight at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(photo.takenAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      photo.viewTypeEnum.displayName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (photo.formattedWeight != null)
                      Text(
                        photo.formattedWeight!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toolbar toggle chip for Step 3
class _ToolbarChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ToolbarChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.isLoading = false,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isActive ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            else if (isActive)
              Icon(Icons.check,
                  size: 14, color: colorScheme.primary)
            else
              Icon(icon,
                  size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Pannable Photo Widget
// =============================================================================

/// A photo widget that supports tap-to-select, pan, and pinch-to-zoom.
/// Pan/zoom only enabled when [isSelected] is true.
/// Panning at 1x zoom repositions the visible crop area via alignment shift.
class _PannablePhoto extends StatefulWidget {
  final ProgressPhoto photo;
  final BoxFit fit;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PannablePhoto({
    required this.photo,
    this.fit = BoxFit.cover,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_PannablePhoto> createState() => _PannablePhotoState();
}

class _PannablePhotoState extends State<_PannablePhoto> {
  double _scale = 1.0;
  double _baseScale = 1.0;
  Alignment _alignment = Alignment.center;

  void _zoomIn() {
    setState(() {
      _scale = (_scale + 0.3).clamp(1.0, 4.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.3).clamp(1.0, 4.0);
      if (_scale <= 1.0) _alignment = Alignment.center;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            GestureDetector(
              onTap: widget.onTap,
              // Always register scale callbacks so the ScaleGestureRecognizer
              // exists in the gesture arena. Guard transform logic on isSelected.
              onScaleStart: (_) {
                _baseScale = _scale;
              },
              onScaleUpdate: (details) {
                if (!widget.isSelected) return;
                setState(() {
                  // Zoom
                  _scale =
                      (_baseScale * details.scale).clamp(1.0, 4.0);
                  // Pan via alignment shift
                  final dx = details.focalPointDelta.dx /
                      (constraints.maxWidth * 0.5);
                  final dy = details.focalPointDelta.dy /
                      (constraints.maxHeight * 0.5);
                  _alignment = Alignment(
                    (_alignment.x - dx).clamp(-1.0, 1.0),
                    (_alignment.y - dy).clamp(-1.0, 1.0),
                  );
                });
              },
              child: ClipRect(
                child: Transform.scale(
                  scale: _scale,
                  child: SizedBox.expand(
                    child: CachedNetworkImage(
                      imageUrl: widget.photo.photoUrl,
                      fit: widget.fit,
                      alignment: _alignment,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.white54, size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Zoom +/- buttons (visible when selected)
            if (widget.isSelected)
              Positioned(
                bottom: 6,
                right: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ZoomButton(
                      icon: Icons.add,
                      onTap: _scale < 4.0 ? _zoomIn : null,
                    ),
                    const SizedBox(height: 4),
                    _ZoomButton(
                      icon: Icons.remove,
                      onTap: _scale > 1.0 ? _zoomOut : null,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ZoomButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(enabled ? 0.7 : 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.white70 : Colors.white24,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}

// =============================================================================
// Custom Clippers & Painters
// =============================================================================

/// Clips content to a vertical slice for the slider comparison
class _SliderClipper extends CustomClipper<Rect> {
  final double position;

  _SliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, position, size.height);
  }

  @override
  bool shouldReclip(covariant _SliderClipper oldClipper) {
    return oldClipper.position != position;
  }
}

/// Clips content diagonally from bottom-left to top-right
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _DiagonalClipper oldClipper) => false;
}

/// Paints a diagonal divider line from top-right to bottom-left
class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagonalLinePainter oldDelegate) =>
      false;
}

/// Crosshatch diagonal pattern for canvas background decoration
class _CanvasPatternPainter extends CustomPainter {
  final Color bgColor;

  _CanvasPatternPainter(this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final isLight = bgColor.computeLuminance() > 0.5;
    final lineColor = isLight
        ? Colors.black.withOpacity(0.06)
        : Colors.white.withOpacity(0.06);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    // Diagonal lines (top-left to bottom-right)
    for (double i = -size.height; i < size.width + size.height; i += 32) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Crosshatch (top-right to bottom-left)
    for (double i = -size.height; i < size.width + size.height; i += 32) {
      canvas.drawLine(
        Offset(size.width - i, 0),
        Offset(size.width - i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPatternPainter oldDelegate) =>
      oldDelegate.bgColor != bgColor;
}
