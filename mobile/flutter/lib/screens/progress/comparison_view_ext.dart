part of 'comparison_view.dart';

/// Methods extracted from _ComparisonViewState
extension __ComparisonViewStateExt on _ComparisonViewState {

  // ===========================================================================
  // STEP 2 - Select Photos
  // ===========================================================================

  Widget _buildPhotosStep(ColorScheme colorScheme) {
    final state = ref.watch(progressPhotosNotifierProvider(widget.userId));
    final allPhotos = state.photos;
    final filteredPhotos = _filterViewType != null
        ? allPhotos.where((p) => p.viewTypeEnum == _filterViewType).toList()
        : allPhotos;
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
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
                final label = index < labels.length ? labels[index] : 'Photo ${index + 1}';
                return SelectedPhotoChip(
                  photo: photo, label: label, orderNumber: index + 1,
                  colorScheme: colorScheme,
                  onRemove: () => setState(() => _selectedPhotos.removeAt(index)),
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
                  onSelected: (_) => setState(() => _filterViewType = null),
                ),
              ),
              ...PhotoViewType.values
                  .where((t) => allPhotos.any((p) => p.viewTypeEnum == t))
                  .map((type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.displayName),
                      selected: _filterViewType == type,
                      onSelected: (_) => setState(() {
                        _filterViewType = _filterViewType == type ? null : type;
                      }),
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Photo grid
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : sortedPhotos.isEmpty
              ? _buildEmptyPhotosState(colorScheme)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.7,
                  ),
                  itemCount: sortedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = sortedPhotos[index];
                    final selectedIndex = _selectedPhotos.indexWhere((p) => p.id == photo.id);
                    final isSelected = selectedIndex >= 0;
                    final canSelect = isSelected || _selectedPhotos.length < _maxPhotoCount;

                    return ComparisonPhotoGridCard(
                      photo: photo, isSelected: isSelected,
                      orderNumber: isSelected ? selectedIndex + 1 : null,
                      enabled: canSelect, colorScheme: colorScheme,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPhotos.removeWhere((p) => p.id == photo.id);
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

}
