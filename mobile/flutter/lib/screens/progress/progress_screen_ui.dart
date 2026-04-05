part of 'progress_screen.dart';

/// UI builder methods extracted from _ProgressScreenState
extension _ProgressScreenStateUI on _ProgressScreenState {

  Widget? _buildFAB() {
    // No FAB for Scores tab (index 0)
    if (_tabController.index == 0) return null;

    final isPhotosTab = _tabController.index == 1;
    return FloatingActionButton.extended(
      onPressed: () => isPhotosTab
          ? _showAddPhotoSheet()
          : _showAddMeasurementSheet(),
      icon: Icon(isPhotosTab ? Icons.camera_alt : Icons.add),
      label: Text(isPhotosTab ? 'Add Photo' : 'Log Measurement'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }


  // ============================================
  // Scores Tab
  // ============================================

  Widget _buildScoresTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(scoresProvider.notifier).loadScoresOverview(userId: _userId);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Readiness Check-in Card
            ReadinessCheckinCard(
              userId: _userId!,
              onCheckInComplete: () {
                // Refresh overview after check-in
                ref.read(scoresProvider.notifier).loadScoresOverview();
              },
            ),
            const SizedBox(height: 16),

            // Strength Overview Card
            StrengthOverviewCard(
              userId: _userId!,
              onTapMuscleGroup: (muscleGroup) {
                // Navigate to muscle detail - we could add a detailed view later
                _showMuscleDetail(muscleGroup);
              },
            ),
            const SizedBox(height: 16),

            // Personal Records Summary Card
            PRSummaryCard(userId: _userId!),
            const SizedBox(height: 16),

            // Analytics Navigation Cards
            _buildAnalyticsNavigationSection(),
            const SizedBox(height: 80), // Bottom padding for scroll
          ],
        ),
      ),
    );
  }


  Widget _buildAnalyticsNavigationSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Analytics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AnalyticsNavCard(
                icon: Icons.history,
                title: 'Exercise History',
                subtitle: 'Per-exercise progress & PRs',
                color: colorScheme.primary,
                onTap: () => context.push('/stats/exercise-history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnalyticsNavCard(
                icon: Icons.fitness_center,
                title: 'Muscle Analytics',
                subtitle: 'Training volume & balance',
                color: colorScheme.secondary,
                onTap: () => context.push('/stats/muscle-analytics'),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }


  // ============================================
  // Photos Tab
  // ============================================

  Widget _buildPhotosTab() {
    final state = ref.watch(progressPhotosNotifierProvider(_userId!));
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(progressPhotosNotifierProvider(_userId!).notifier)
          .loadAll(),
      child: CustomScrollView(
        slivers: [
          // Stats Card
          SliverToBoxAdapter(
            child: _buildPhotoStatsCard(state),
          ),

          // View Type Filter
          SliverToBoxAdapter(
            child: _buildViewTypeFilter(),
          ),

          // Latest Photos by View
          if (state.latestByView != null && _selectedViewFilter == null)
            SliverToBoxAdapter(
              child: _buildLatestPhotosByView(state.latestByView!),
            ),

          // Photo Grid
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.photos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyPhotosState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final filteredPhotos = _selectedViewFilter == null
                        ? state.photos
                        : state.photos
                            .where((p) =>
                                p.viewTypeEnum == _selectedViewFilter)
                            .toList();
                    if (index >= filteredPhotos.length) return null;
                    return _buildPhotoCard(filteredPhotos[index]);
                  },
                  childCount: _selectedViewFilter == null
                      ? state.photos.length
                      : state.photos
                          .where(
                              (p) => p.viewTypeEnum == _selectedViewFilter)
                          .length,
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildPhotoStatsCard(ProgressPhotosState state) {
    final stats = state.stats;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 18, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 6),
              Text(
                'Photo Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${stats?.totalPhotos ?? 0}',
                'Total Photos',
                Icons.photo_library,
              ),
              _buildStatItem(
                '${stats?.viewTypesCaptured ?? 0}/4',
                'Views Captured',
                Icons.view_carousel,
              ),
              _buildStatItem(
                stats?.formattedTrackingDuration ?? '-',
                'Tracking',
                Icons.calendar_month,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }


  Widget _buildStatItem(String value, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }


  Widget _buildLatestPhotosByView(LatestPhotosByView latest) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest by View',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [PhotoViewType.front, PhotoViewType.sideLeft, PhotoViewType.sideRight, PhotoViewType.back].map((type) {
                final photo = latest.getPhoto(type);
                return _buildLatestViewCard(type, photo);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLatestViewCard(PhotoViewType type, ProgressPhoto? photo) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        if (photo != null) {
          _showPhotoDetail(photo);
        } else {
          _addPhotoForViewType(type);
        }
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: photo != null
                        ? colorScheme.primary.withOpacity(0.5)
                        : colorScheme.outline.withOpacity(0.3),
                    width: photo != null ? 2 : 1,
                  ),
                ),
                child: photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: CachedNetworkImage(
                          imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.broken_image,
                            color: colorScheme.error,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: colorScheme.outline,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPhotoCard(ProgressPhoto photo) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showPhotoDetail(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: colorScheme.errorContainer,
                  child: Icon(Icons.broken_image, color: colorScheme.error),
                ),
              ),
              // Gradient overlay for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.viewTypeEnum.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        photo.formattedDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
      ),
    );
  }


  Widget _buildEmptyPhotosState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Progress Photos Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take photos from different angles to track your visual progress over time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddPhotoSheet,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take First Photo'),
            ),
          ],
        ),
      ),
    );
  }


  // ============================================
  // Measurements Tab
  // ============================================

  Widget _buildMeasurementsTab() {
    final measState = ref.watch(measurementsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (measState.isLoading) {
      return AppLoading.fullScreen();
    }

    if (measState.error != null && measState.historyByType.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text('Failed to load measurements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Please try again.',
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_userId != null) {
                    ref.read(measurementsProvider.notifier).loadAllMeasurements(_userId!);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = measState.summary;
    final latestByType = summary?.latestByType ?? {};
    final changeFromPrevious = summary?.changeFromPrevious ?? {};

    if (latestByType.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.straighten_outlined, size: 80, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text('Body Measurements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Track your body measurements to see detailed progress beyond the scale.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddMeasurementSheet,
                icon: const Icon(Icons.add),
                label: const Text('Log Measurements'),
              ),
            ],
          ),
        ),
      );
    }

    // Group measurement types by body area
    const coreTypes = [
      MeasurementType.weight, MeasurementType.bodyFat,
      MeasurementType.chest, MeasurementType.waist, MeasurementType.hips,
      MeasurementType.neck, MeasurementType.shoulders,
    ];
    const armTypes = [
      MeasurementType.bicepsLeft, MeasurementType.bicepsRight,
      MeasurementType.forearmLeft, MeasurementType.forearmRight,
    ];
    const legTypes = [
      MeasurementType.thighLeft, MeasurementType.thighRight,
      MeasurementType.calfLeft, MeasurementType.calfRight,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Last updated info
        if (latestByType.values.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Last updated ${DateFormat('MMM d, yyyy').format(latestByType.values.first.recordedAt)}',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ),

        _buildMeasurementSection('Core', Icons.accessibility, coreTypes, latestByType, changeFromPrevious),
        const SizedBox(height: 16),
        _buildMeasurementSection('Arms', Icons.fitness_center, armTypes, latestByType, changeFromPrevious),
        const SizedBox(height: 16),
        _buildMeasurementSection('Legs', Icons.directions_walk, legTypes, latestByType, changeFromPrevious),

        const SizedBox(height: 100), // Bottom padding for FAB
      ],
    );
  }


  Widget _buildMeasurementSection(
    String title,
    IconData icon,
    List<MeasurementType> types,
    Map<MeasurementType, MeasurementEntry> latestByType,
    Map<MeasurementType, double> changeFromPrevious,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    // Only show types that have data
    final typesWithData = types.where((t) => latestByType.containsKey(t)).toList();
    if (typesWithData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 12),
        ...typesWithData.map((type) {
          final entry = latestByType[type]!;
          final change = changeFromPrevious[type];
          return _buildMeasurementRow2(entry, change);
        }),
      ],
    );
  }


  Widget _buildMeasurementRow2(MeasurementEntry entry, double? change) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueStr = entry.value % 1 == 0
        ? entry.value.toInt().toString()
        : entry.value.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(entry.type.displayName,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
            ),
            Text('$valueStr ${entry.unit}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            if (change != null && change != 0) ...[
              const SizedBox(width: 8),
              _buildChangeIndicator(change, entry.unit),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildChangeIndicator(double change, String unit) {
    // For waist/body fat, decrease is good. For most others, increase could be good.
    // Use neutral colors - just show direction.
    final isPositive = change > 0;
    final color = isPositive ? Colors.orange : Colors.green;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final changeStr = change.abs() % 1 == 0
        ? change.abs().toInt().toString()
        : change.abs().toStringAsFixed(1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text('$changeStr$unit',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

}
