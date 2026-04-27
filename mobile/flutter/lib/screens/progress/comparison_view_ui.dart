part of 'comparison_view.dart';

/// UI builder methods extracted from _ComparisonViewState
extension _ComparisonViewStateUI on _ComparisonViewState {

  Widget _buildStepContent(ColorScheme colorScheme) {
    switch (_currentStep) {
      case 0: return _buildLayoutStep(colorScheme);
      case 1: return _buildPhotosStep(colorScheme);
      case 2: return _buildCustomizeStep(colorScheme);
      default: return const SizedBox.shrink();
    }
  }


  // ===========================================================================
  // STEP 1 - Choose Layout
  // ===========================================================================

  Widget _buildLayoutStep(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildLayoutGroup(title: '2-Photo Layouts', layouts: twoPhotoLayouts, colorScheme: colorScheme),
        const SizedBox(height: 24),
        _buildLayoutGroup(title: 'Multi-Photo Layouts', layouts: multiPhotoLayouts, colorScheme: colorScheme),
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
            Icon(Icons.photo_library_outlined, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No Photos Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
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


  // ---------------------------------------------------------------------------
  // Canvas layout renderers
  // ---------------------------------------------------------------------------

  Widget _buildCanvasLayout(Color bgColor) {
    if (_selectedPhotos.isEmpty) {
      return const Center(child: Text('No photos selected', style: TextStyle(color: Colors.white54)));
    }
    switch (_selectedLayout) {
      case ComparisonLayout.sideBySide: return _buildSideBySideLayout();
      case ComparisonLayout.slider: return _buildSliderLayout();
      case ComparisonLayout.verticalStack: return _buildVerticalStackLayout();
      case ComparisonLayout.story: return _buildStoryLayout(bgColor);
      case ComparisonLayout.diagonalSplit: return _buildDiagonalSplitLayout();
      case ComparisonLayout.polaroid: return _buildPolaroidLayout(bgColor);
      case ComparisonLayout.triptych: return _buildTriptychLayout();
      case ComparisonLayout.fourPanel: return _buildFourPanelLayout();
      case ComparisonLayout.monthlyGrid: return _buildMonthlyGridLayout();
      case ComparisonLayout.ghostOverlay: return _buildGhostOverlayLayout();
    }
  }


  // -- Layout renderers --

  Widget _buildSideBySideLayout() {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.length < 2) return _buildPhotoWidget(photos.first, 0);
    return Row(children: [Expanded(child: _buildPhotoWidget(photos[0], 0)), SizedBox(width: _photoSpacing), Expanded(child: _buildPhotoWidget(photos[1], 1))]);
  }


  Widget _buildVerticalStackLayout() {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.length < 2) return _buildPhotoWidget(photos.first, 0);
    return Column(children: [Expanded(child: _buildPhotoWidget(photos[0], 0)), SizedBox(height: _photoSpacing), Expanded(child: _buildPhotoWidget(photos[1], 1))]);
  }


  Widget _buildStoryLayout(Color bgColor) {
    final photos = _selectedPhotos.take(2).toList();
    final textColor = bgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('MY PROGRESS', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2))),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: photos.length >= 2
          ? Row(children: [Expanded(child: _buildPhotoWidget(photos[0], 0)), SizedBox(width: _photoSpacing), Expanded(child: _buildPhotoWidget(photos[1], 1))])
          : _buildPhotoWidget(photos.first, 0))),
      Padding(padding: const EdgeInsets.all(16), child: _buildStoryStats(textColor)),
    ]);
  }


  Widget _buildStoryStats(Color textColor) {
    final statsData = _buildRichStatsData();
    if (statsData == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statsData.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(e.value.first, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(e.key.label, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
        ]),
      )).toList(),
    );
  }


  Widget _buildDiagonalSplitLayout() {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.length < 2) return _buildPhotoWidget(photos.first, 0);
    return LayoutBuilder(builder: (context, constraints) {
      Widget content = Stack(children: [
        SizedBox.expand(child: CachedNetworkImage(imageUrl: photos[1].photoUrl, fit: BoxFit.cover, memCacheWidth: 600, memCacheHeight: 600)),
        ClipPath(clipper: DiagonalClipper(), child: SizedBox.expand(child: CachedNetworkImage(imageUrl: photos[0].photoUrl, fit: BoxFit.cover, memCacheWidth: 600, memCacheHeight: 600))),
        CustomPaint(size: Size(constraints.maxWidth, constraints.maxHeight), painter: DiagonalLinePainter()),
        Positioned(top: 8, left: 8, child: _buildLabel('Before')),
        Positioned(bottom: 8, right: 8, child: _buildLabel('After')),
      ]);
      return _applyLayoutShapeAndBorder(content);
    });
  }


  Widget _buildPolaroidLayout(Color bgColor) {
    final photos = _selectedPhotos.take(2).toList();
    if (photos.isEmpty) return const SizedBox.shrink();
    return Center(child: Padding(padding: const EdgeInsets.all(16), child: LayoutBuilder(builder: (context, constraints) {
      final gapOffset = _photoSpacing / 2;
      final maxW = constraints.maxWidth * 0.42 - gapOffset;
      final maxH = constraints.maxHeight * 0.75;
      return Stack(alignment: Alignment.center, children: [
        if (photos.isNotEmpty) Positioned(left: constraints.maxWidth * 0.04 + gapOffset, child: Transform.rotate(angle: -0.06, child: _buildPolaroidFrame(photos[0], maxW, maxH, bgColor))),
        if (photos.length >= 2) Positioned(right: constraints.maxWidth * 0.04 + gapOffset, child: Transform.rotate(angle: 0.05, child: _buildPolaroidFrame(photos[1], maxW, maxH, bgColor))),
      ]);
    })));
  }


  Widget _buildPolaroidFrame(ProgressPhoto photo, double width, double height, Color bgColor) {
    final frameBg = bgColor == Colors.white ? Colors.white : Colors.grey[100]!;
    final imageRadius = _shapeBorderRadius ?? BorderRadius.circular(2);
    Widget imageContent = ClipRRect(borderRadius: imageRadius, child: CachedNetworkImage(imageUrl: photo.photoUrl, fit: BoxFit.cover, memCacheWidth: 600, memCacheHeight: 600));
    if (_photoBorderEnabled && _photoBorderWidth > 0) {
      imageContent = Container(
        decoration: BoxDecoration(border: Border.all(color: _photoBorderColor, width: _photoBorderWidth), borderRadius: imageRadius),
        child: ClipRRect(borderRadius: BorderRadius.circular(max(0, imageRadius.topLeft.x - _photoBorderWidth)), child: CachedNetworkImage(imageUrl: photo.photoUrl, fit: BoxFit.cover, memCacheWidth: 600, memCacheHeight: 600)),
      );
    }
    return Container(width: width, height: height, decoration: BoxDecoration(color: frameBg, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(2, 4))]), padding: const EdgeInsets.fromLTRB(8, 8, 8, 28), child: imageContent);
  }


  Widget _buildTriptychLayout() {
    final photos = _selectedPhotos.take(3).toList();
    final halfGap = _photoSpacing / 2;
    return Row(children: photos.asMap().entries.map((entry) => Expanded(child: Padding(padding: EdgeInsets.only(left: entry.key == 0 ? 0 : halfGap, right: entry.key == photos.length - 1 ? 0 : halfGap), child: _buildPhotoWidget(entry.value, entry.key)))).toList());
  }


  Widget _buildFourPanelLayout() {
    final photos = _selectedPhotos.take(4).toList();
    return Column(children: [
      Expanded(child: Row(children: [if (photos.isNotEmpty) Expanded(child: _buildPhotoWidget(photos[0], 0)), SizedBox(width: _photoSpacing), if (photos.length > 1) Expanded(child: _buildPhotoWidget(photos[1], 1))])),
      SizedBox(height: _photoSpacing),
      Expanded(child: Row(children: [if (photos.length > 2) Expanded(child: _buildPhotoWidget(photos[2], 2)), SizedBox(width: _photoSpacing), if (photos.length > 3) Expanded(child: _buildPhotoWidget(photos[3], 3))])),
    ]);
  }


  Widget _buildMonthlyGridLayout() {
    final photos = _selectedPhotos;
    if (photos.isEmpty) return const SizedBox.shrink();
    final cols = max(2, min(4, sqrt(photos.length).ceil()));
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: _photoSpacing, crossAxisSpacing: _photoSpacing),
      itemCount: photos.length,
      itemBuilder: (context, index) => _buildPhotoWidget(photos[index], index),
    );
  }


  Widget _buildGhostOverlayLayout() {
    if (_selectedPhotos.length < 2) return const Center(child: Text('Select 2 photos', style: TextStyle(color: Colors.white54)));
    return Stack(fit: StackFit.expand, children: [
      CachedNetworkImage(imageUrl: _selectedPhotos[1].photoUrl, fit: BoxFit.contain, placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white38))),
      GhostOverlayWidget(beforeImageUrl: _selectedPhotos[0].photoUrl, opacity: _ghostOpacity, showGuides: _ghostOverlayEnabled),
    ]);
  }


  // ---------------------------------------------------------------------------
  // Overlays
  // ---------------------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }


  Widget _buildDateChip(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.edit, size: 8, color: Colors.white70),
        const SizedBox(width: 3),
        Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500)),
      ]),
    );
  }


  // ---------------------------------------------------------------------------
  // Rich stats data
  // ---------------------------------------------------------------------------

  Map<StatCategory, List<String>>? _buildRichStatsData() {
    if (_selectedPhotos.length < 2 || _enabledStatCategories.isEmpty) return null;
    final first = _selectedPhotos.first;
    final last = _selectedPhotos.last;
    final firstDate = _dateOverrides[0] ?? first.takenAt;
    final lastDate = _dateOverrides[_selectedPhotos.length - 1] ?? last.takenAt;
    final result = <StatCategory, List<String>>{};

    if (_enabledStatCategories.contains(StatCategory.duration)) {
      final days = lastDate.difference(firstDate).inDays.abs();
      String durText;
      if (days == 0) { durText = 'Same day'; }
      else if (days < 30) { durText = '$days days'; }
      else if (days < 365) { final months = (days / 30).round(); durText = '$months month${months > 1 ? 's' : ''}'; }
      else { durText = '${(days / 365).round()}y ${((days % 365) / 30).round()}m'; }
      final items = <String>[durText];
      if (_selectedPhotos.length > 2) items.add('${_selectedPhotos.length} photos');
      if (_filterViewType != null) items.add(_filterViewType!.displayName);
      result[StatCategory.duration] = items;
    }

    if (_enabledStatCategories.contains(StatCategory.weight)) {
      final firstW = _resolvePhotoWeight(first);
      final lastW = _resolvePhotoWeight(last);
      if (firstW != null && lastW != null) {
        final change = lastW - firstW;
        final sign = change > 0 ? '+' : '';
        result[StatCategory.weight] = ['${firstW.toStringAsFixed(1)} \u2192 ${lastW.toStringAsFixed(1)} kg', '($sign${change.toStringAsFixed(1)} kg)'];
      } else if (firstW != null) { result[StatCategory.weight] = ['${firstW.toStringAsFixed(1)} kg']; }
      else if (lastW != null) { result[StatCategory.weight] = ['${lastW.toStringAsFixed(1)} kg']; }
    }

    if (_enabledStatCategories.contains(StatCategory.body)) {
      final measState = ref.read(measurementsProvider);
      final bodyTypes = [MeasurementType.chest, MeasurementType.waist, MeasurementType.hips, MeasurementType.bicepsLeft, MeasurementType.thighLeft, MeasurementType.neck, MeasurementType.shoulders];
      final bodyItems = <String>[];
      for (final type in bodyTypes) {
        final history = measState.historyByType[type];
        if (history == null || history.isEmpty) continue;
        final beforeVal = _findClosestMeasurementValue(history, first.takenAt);
        final afterVal = _findClosestMeasurementValue(history, last.takenAt);
        if (beforeVal != null && afterVal != null) {
          final delta = afterVal - beforeVal;
          if (delta.abs() >= 0.1) {
            final sign = delta > 0 ? '+' : '';
            final shortName = type.displayName.replaceAll(' (L)', '').replaceAll(' (R)', '');
            bodyItems.add('$shortName $sign${delta.toStringAsFixed(1)}${type.metricUnit}');
          }
        }
        if (bodyItems.length >= 4) break;
      }
      if (bodyItems.isNotEmpty) result[StatCategory.body] = bodyItems;
    }

    if (_enabledStatCategories.contains(StatCategory.strength)) {
      final strengthItems = <String>[];
      final score = ref.read(overallStrengthScoreProvider);
      if (score > 0) strengthItems.add('Score: $score');
      final prStats = ref.read(prStatsProvider);
      if (prStats != null && prStats.totalPrs > 0) {
        strengthItems.add('PRs: ${prStats.totalPrs}');
        if (prStats.prsThisPeriod > 0) strengthItems.add('${prStats.prsThisPeriod} recent');
      }
      if (strengthItems.isNotEmpty) result[StatCategory.strength] = strengthItems;
    }

    return result.isEmpty ? null : result;
  }


  Widget _buildStatsBar(Color bgColor) {
    final data = _buildRichStatsData();
    if (data == null) return const SizedBox.shrink();
    final textColor = bgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;
    return Container(
      color: bgColor.withOpacity(0.85),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: data.entries.map((entry) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(entry.value.join('  \u00B7  '), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 10.5, fontWeight: FontWeight.w500, height: 1.4)),
      )).toList()),
    );
  }


  Widget _buildAiSummaryOverlay(Color bgColor) {
    // FitBudd-style gradient narrative card. Replaces the prior 60-px
    // italic overlay so the Progress Summary actually reads as a summary,
    // not a caption.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8A5C2), Color(0xFFB24BF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Progress Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _aiSummary ?? '',
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }


  /// Resolves the logo tint based on variant + background luminance.
  /// Returns null to render the original colored app icon.
  Color? _resolveLogoTint(Color bgColor) {
    switch (_logoVariant) {
      case 'original':
        return null;
      case 'light':
        return Colors.white;
      case 'dark':
        return Colors.black;
      case 'auto':
      default:
        return bgColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;
    }
  }

  Widget _buildLogoIcon(Color bgColor, {double size = 16}) {
    final tint = _resolveLogoTint(bgColor);
    Widget icon = Image.asset(
      'assets/images/app_icon.png',
      width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(Icons.fitness_center, size: size * 0.85, color: tint ?? Colors.white),
    );
    if (tint != null) {
      icon = ColorFiltered(colorFilter: ColorFilter.mode(tint, BlendMode.srcIn), child: icon);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(size * 0.25), child: icon);
  }

  /// Draggable branding pill — Zealova logo + optional @username.
  /// Replaces the old duplicate (top-left overlay + bottom footer).
  Widget _buildBrandingPill(Color bgColor) {
    final tint = _resolveLogoTint(bgColor) ?? Colors.white;
    final authState = ref.watch(authStateProvider);
    final username = authState.user?.username;
    final showUsername = _showUsername && username != null && username.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _buildLogoIcon(bgColor, size: 16),
        const SizedBox(width: 5),
        Text('${Branding.appName}', style: TextStyle(color: tint.withOpacity(0.95), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        if (showUsername) ...[
          const SizedBox(width: 6),
          Container(width: 0.5, height: 10, color: tint.withOpacity(0.4)),
          const SizedBox(width: 6),
          Text('@$username', style: TextStyle(color: tint.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ]),
    );
  }


  Widget _buildColorDot({required Color color, required bool isSelected, required VoidCallback onTap, Color? borderColor}) {
    return GestureDetector(onTap: onTap, child: Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : borderColor ?? Colors.grey, width: isSelected ? 2.5 : 1))));
  }


  Widget _buildGradientDot({required List<Color> colors, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(width: 24, height: 24, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors), shape: BoxShape.circle, border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey, width: isSelected ? 2.5 : 1))));
  }

}
