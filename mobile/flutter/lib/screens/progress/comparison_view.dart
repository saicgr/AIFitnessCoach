import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/progress_photos.dart';
import '../../data/repositories/progress_photos_repository.dart';

class ComparisonView extends ConsumerStatefulWidget {
  final String userId;

  const ComparisonView({super.key, required this.userId});

  @override
  ConsumerState<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends ConsumerState<ComparisonView> {
  PhotoViewType _selectedViewType = PhotoViewType.front;
  ProgressPhoto? _beforePhoto;
  ProgressPhoto? _afterPhoto;
  bool _isCreatingComparison = false;
  double _sliderPosition = 0.5;
  bool _useSliderMode = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(progressPhotosNotifierProvider(widget.userId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Compare Photos'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_beforePhoto != null && _afterPhoto != null)
            IconButton(
              icon: Icon(_useSliderMode ? Icons.view_column : Icons.compare),
              tooltip: _useSliderMode ? 'Side by Side' : 'Slider Mode',
              onPressed: () => setState(() => _useSliderMode = !_useSliderMode),
            ),
        ],
      ),
      body: Column(
        children: [
          // View Type Selector
          _buildViewTypeSelector(),

          // Comparison Area
          Expanded(
            child: _beforePhoto != null && _afterPhoto != null
                ? _buildComparisonView()
                : _buildPhotoSelector(state),
          ),

          // Photo Info & Actions
          if (_beforePhoto != null && _afterPhoto != null)
            _buildComparisonInfo(),
        ],
      ),
      floatingActionButton:
          _beforePhoto != null && _afterPhoto != null
              ? FloatingActionButton.extended(
                  onPressed: _isCreatingComparison ? null : _saveComparison,
                  icon: _isCreatingComparison
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Comparison'),
                )
              : null,
    );
  }

  Widget _buildViewTypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: PhotoViewType.values.map((type) {
            final isSelected = _selectedViewType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedViewType = type;
                    _beforePhoto = null;
                    _afterPhoto = null;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPhotoSelector(ProgressPhotosState state) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filter photos by selected view type
    final filteredPhotos = state.photos
        .where((p) => p.viewTypeEnum == _selectedViewType)
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt)); // Newest first

    if (filteredPhotos.isEmpty) {
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
                'No ${_selectedViewType.displayName} Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take at least 2 photos from this angle to compare.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredPhotos.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Need More Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need at least 2 ${_selectedViewType.displayName} photos to create a comparison.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Before Photo Selection
        Expanded(
          child: _buildPhotoSelectionSection(
            title: 'Select "Before" Photo',
            selectedPhoto: _beforePhoto,
            photos: filteredPhotos,
            onSelect: (photo) => setState(() => _beforePhoto = photo),
            otherSelectedPhoto: _afterPhoto,
          ),
        ),
        Divider(color: colorScheme.outlineVariant),
        // After Photo Selection
        Expanded(
          child: _buildPhotoSelectionSection(
            title: 'Select "After" Photo',
            selectedPhoto: _afterPhoto,
            photos: filteredPhotos,
            onSelect: (photo) => setState(() => _afterPhoto = photo),
            otherSelectedPhoto: _beforePhoto,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSelectionSection({
    required String title,
    required ProgressPhoto? selectedPhoto,
    required List<ProgressPhoto> photos,
    required Function(ProgressPhoto) onSelect,
    required ProgressPhoto? otherSelectedPhoto,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (selectedPhoto != null) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    DateFormat('MMM d, yyyy').format(selectedPhoto.takenAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () => onSelect(selectedPhoto),
                  deleteIcon: const Icon(Icons.close, size: 16),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              final isSelected = photo.id == selectedPhoto?.id;
              final isOtherSelected = photo.id == otherSelectedPhoto?.id;

              return GestureDetector(
                onTap: isOtherSelected ? null : () => onSelect(photo),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
                          fit: BoxFit.cover,
                          color: isOtherSelected
                              ? Colors.black.withOpacity(0.5)
                              : null,
                          colorBlendMode:
                              isOtherSelected ? BlendMode.darken : null,
                        ),
                      ),
                      if (isOtherSelected)
                        const Center(
                          child: Icon(
                            Icons.block,
                            color: Colors.white54,
                            size: 24,
                          ),
                        ),
                      if (isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
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
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            DateFormat('MMM d').format(photo.takenAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonView() {
    if (_useSliderMode) {
      return _buildSliderComparison();
    } else {
      return _buildSideBySideComparison();
    }
  }

  Widget _buildSliderComparison() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderPosition += details.delta.dx / constraints.maxWidth;
              _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
            });
          },
          child: Stack(
            children: [
              // After Photo (full width, behind)
              SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CachedNetworkImage(
                  imageUrl: _afterPhoto!.photoUrl,
                  fit: BoxFit.contain,
                ),
              ),
              // Before Photo (clipped)
              ClipRect(
                clipper: _SliderClipper(_sliderPosition * constraints.maxWidth),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: CachedNetworkImage(
                    imageUrl: _beforePhoto!.photoUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Slider Handle
              Positioned(
                left: _sliderPosition * constraints.maxWidth - 20,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Labels
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Before',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'After',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideBySideComparison() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Before',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: _beforePhoto!.photoUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_beforePhoto!.takenAt),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          color: Theme.of(context).colorScheme.outline,
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'After',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: _afterPhoto!.photoUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_afterPhoto!.takenAt),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonInfo() {
    final colorScheme = Theme.of(context).colorScheme;
    final daysBetween =
        _afterPhoto!.takenAt.difference(_beforePhoto!.takenAt).inDays;
    final weightChange = _afterPhoto!.bodyWeightKg != null &&
            _beforePhoto!.bodyWeightKg != null
        ? _afterPhoto!.bodyWeightKg! - _beforePhoto!.bodyWeightKg!
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoItem(
              icon: Icons.calendar_today,
              label: 'Duration',
              value: '$daysBetween days',
            ),
            if (weightChange != null)
              _buildInfoItem(
                icon: Icons.monitor_weight,
                label: 'Weight Change',
                value:
                    '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                valueColor: weightChange < 0 ? Colors.green : Colors.orange,
              ),
            _buildInfoItem(
              icon: Icons.view_carousel,
              label: 'View',
              value: _selectedViewType.displayName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _saveComparison() async {
    if (_beforePhoto == null || _afterPhoto == null) return;

    setState(() => _isCreatingComparison = true);

    try {
      await ref
          .read(progressPhotosNotifierProvider(widget.userId).notifier)
          .createComparison(
            beforePhotoId: _beforePhoto!.id,
            afterPhotoId: _afterPhoto!.id,
            title: '${_selectedViewType.displayName} Progress',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comparison saved!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingComparison = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save comparison: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

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
