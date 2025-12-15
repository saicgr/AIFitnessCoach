import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/measurements_repository.dart';

class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  MeasurementType _selectedType = MeasurementType.weight;
  String _selectedPeriod = '30d';
  bool _isMetric = true;

  final _periods = [
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': 'All', 'value': 'all', 'days': 365},
  ];

  // Group measurement types by body part
  static const _measurementGroups = [
    {
      'title': 'Body Composition',
      'types': [MeasurementType.weight, MeasurementType.bodyFat],
    },
    {
      'title': 'Upper Body',
      'types': [
        MeasurementType.neck,
        MeasurementType.shoulders,
        MeasurementType.chest,
        MeasurementType.bicepsLeft,
        MeasurementType.bicepsRight,
        MeasurementType.forearmLeft,
        MeasurementType.forearmRight,
      ],
    },
    {
      'title': 'Core',
      'types': [MeasurementType.waist, MeasurementType.hips],
    },
    {
      'title': 'Lower Body',
      'types': [
        MeasurementType.thighLeft,
        MeasurementType.thighRight,
        MeasurementType.calfLeft,
        MeasurementType.calfRight,
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final auth = ref.read(authStateProvider);
    if (auth.user != null) {
      await ref.read(measurementsProvider.notifier).loadAllMeasurements(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurementsState = ref.watch(measurementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Body Measurements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // Unit toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => setState(() => _isMetric = !_isMetric),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardBorder),
                ),
                child: Text(
                  _isMetric ? 'Metric' : 'Imperial',
                  style: TextStyle(
                    fontSize: 12,
                    color: cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMeasurements,
          color: cyan,
          child: CustomScrollView(
            slivers: [
              // Period selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period['value'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = period['value'] as String),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? cyan.withOpacity(0.2) : elevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? cyan : cardBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                period['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? cyan : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ),

              // Selected measurement chart
              SliverToBoxAdapter(
                child: _buildChartSection(
                  measurementsState,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                ).animate().fadeIn(delay: 150.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Measurement type selector (horizontal scroll)
              SliverToBoxAdapter(
                child: _buildTypeSelector(
                  measurementsState,
                  isDark: isDark,
                  elevated: elevated,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  cardBorder: cardBorder,
                  cyan: cyan,
                ).animate().fadeIn(delay: 200.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Measurement summary cards by group
              ..._measurementGroups.expand((group) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      group['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildMeasurementGroupCard(
                      measurementsState,
                      group['types'] as List<MeasurementType>,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      cardBorder: cardBorder,
                      cyan: cyan,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ),
              ]),

              // History list for selected type
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HISTORY - ${_selectedType.displayName.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (measurementsState.historyByType[_selectedType]?.isNotEmpty ?? false)
                        Text(
                          '${measurementsState.historyByType[_selectedType]?.length ?? 0} entries',
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms),
              ),

              _buildHistoryList(
                measurementsState,
                isDark: isDark,
                elevated: elevated,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                cardBorder: cardBorder,
                cyan: cyan,
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMeasurementSheet(context),
        backgroundColor: cyan,
        foregroundColor: isDark ? AppColors.pureBlack : Colors.white,
        child: const Icon(Icons.add),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
    );
  }

  Widget _buildChartSection(
    MeasurementsState state, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    final history = state.historyByType[_selectedType] ?? [];
    final filteredHistory = _filterByPeriod(history);
    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedType.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (state.summary?.latestByType[_selectedType] != null)
                    Text(
                      '${_formatValue(state.summary!.latestByType[_selectedType]!.getValueInUnit(_isMetric))} $unit',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cyan,
                      ),
                    ),
                ],
              ),
              if (state.summary?.changeFromPrevious[_selectedType] != null)
                _buildChangeIndicator(
                  state.summary!.changeFromPrevious[_selectedType]!,
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: cyan))
                : filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.straighten, size: 40, color: textMuted),
                            const SizedBox(height: 8),
                            Text(
                              'No ${_selectedType.displayName.toLowerCase()} data yet',
                              style: TextStyle(color: textMuted),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _showAddMeasurementSheet(context),
                              child: Text('Add Entry', style: TextStyle(color: cyan)),
                            ),
                          ],
                        ),
                      )
                    : _buildChart(filteredHistory, cyan: cyan, textMuted: textMuted, isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    List<MeasurementEntry> history, {
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Reverse to show oldest first (left to right)
    final reversedHistory = history.reversed.toList();

    final spots = reversedHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.getValueInUnit(_isMetric));
    }).toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.05;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) => Text(
                _formatValue(value),
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (reversedHistory.length / 4).ceil().toDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < reversedHistory.length) {
                  final date = reversedHistory[index].recordedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(date),
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: cyan,
                  strokeWidth: 2,
                  strokeColor: isDark ? AppColors.pureBlack : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [cyan.withOpacity(0.3), cyan.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => isDark ? AppColors.nearBlack : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final date = index < reversedHistory.length
                    ? reversedHistory[index].recordedAt
                    : DateTime.now();
                final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;
                return LineTooltipItem(
                  '${_formatValue(spot.y)} $unit\n${DateFormat('MMM d, y').format(date)}',
                  TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChangeIndicator(double change, {required bool isDark}) {
    final isPositive = change > 0;
    final isNegative = change < 0;

    // For weight and body fat, decrease is usually good
    final isGoodChange = (_selectedType == MeasurementType.weight ||
                          _selectedType == MeasurementType.bodyFat)
        ? isNegative
        : isPositive;

    final color = change.abs() < 0.1
        ? (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
        : isGoodChange
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _formatValue(change.abs()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(
    MeasurementsState state, {
    required bool isDark,
    required Color elevated,
    required Color textSecondary,
    required Color textMuted,
    required Color cardBorder,
    required Color cyan,
  }) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: MeasurementType.values.length,
        itemBuilder: (context, index) {
          final type = MeasurementType.values[index];
          final isSelected = _selectedType == type;
          final hasData = state.historyByType[type]?.isNotEmpty ?? false;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cyan.withOpacity(0.2) : elevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? cyan : cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? cyan : textSecondary,
                      ),
                    ),
                    if (hasData) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeasurementGroupCard(
    MeasurementsState state,
    List<MeasurementType> types, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardBorder,
    required Color cyan,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: types.asMap().entries.map((entry) {
          final index = entry.key;
          final type = entry.value;
          final latest = state.summary?.latestByType[type];
          final change = state.summary?.changeFromPrevious[type];
          final unit = _isMetric ? type.metricUnit : type.imperialUnit;

          return Column(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedType = type),
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : index == types.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(12))
                        : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (_selectedType == type ? cyan : textMuted).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForType(type),
                          size: 18,
                          color: _selectedType == type ? cyan : textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            if (latest != null)
                              Text(
                                'Last: ${DateFormat('MMM d').format(latest.recordedAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (latest != null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_formatValue(latest.getValueInUnit(_isMetric))} $unit',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: cyan,
                              ),
                            ),
                            if (change != null && change.abs() >= 0.1)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 10,
                                    color: _getChangeColor(type, change),
                                  ),
                                  Text(
                                    _formatValue(change.abs()),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getChangeColor(type, change),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ] else
                        Text(
                          '--',
                          style: TextStyle(
                            fontSize: 15,
                            color: textMuted,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (index < types.length - 1)
                Divider(height: 1, color: cardBorder, indent: 62),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList(
    MeasurementsState state, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardBorder,
    required Color cyan,
  }) {
    final history = state.historyByType[_selectedType] ?? [];
    final filteredHistory = _filterByPeriod(history);
    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;

    if (filteredHistory.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 40, color: textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No history yet',
                    style: TextStyle(color: textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = filteredHistory[index];
          final previousValue = index < filteredHistory.length - 1
              ? filteredHistory[index + 1].getValueInUnit(_isMetric)
              : null;
          final currentValue = entry.getValueInUnit(_isMetric);
          final change = previousValue != null ? currentValue - previousValue : null;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 4, 16, 4),
            child: Dismissible(
              key: Key(entry.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) => _confirmDelete(entry),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('d').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cyan,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: cyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatValue(currentValue)} $unit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          if (entry.notes?.isNotEmpty ?? false)
                            Text(
                              entry.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (change != null && change.abs() >= 0.01)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getChangeColor(_selectedType, change).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: _getChangeColor(_selectedType, change),
                            ),
                            Text(
                              _formatValue(change.abs()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getChangeColor(_selectedType, change),
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
        },
        childCount: filteredHistory.length,
      ),
    );
  }

  Future<bool> _confirmDelete(MeasurementEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.elevated
            : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry?'),
        content: Text(
          'Delete this ${entry.type.displayName} entry from ${DateFormat('MMM d, y').format(entry.recordedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final auth = ref.read(authStateProvider);
      if (auth.user != null) {
        await ref.read(measurementsProvider.notifier).deleteMeasurement(
          auth.user!.id,
          entry.id,
          entry.type,
        );
      }
    }
    return false; // Return false so dismissible doesn't animate out
  }

  List<MeasurementEntry> _filterByPeriod(List<MeasurementEntry> history) {
    if (_selectedPeriod == 'all') return history;

    final days = _periods.firstWhere((p) => p['value'] == _selectedPeriod)['days'] as int;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return history.where((e) => e.recordedAt.isAfter(cutoff)).toList();
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Color _getChangeColor(MeasurementType type, double change) {
    // For weight and body fat, decrease is good
    if (type == MeasurementType.weight || type == MeasurementType.bodyFat) {
      return change < 0 ? AppColors.success : AppColors.error;
    }
    // For other measurements (muscle), increase is usually good
    return change > 0 ? AppColors.success : AppColors.error;
  }

  IconData _getIconForType(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight:
        return Icons.monitor_weight;
      case MeasurementType.bodyFat:
        return Icons.percent;
      case MeasurementType.chest:
        return Icons.accessibility_new;
      case MeasurementType.waist:
        return Icons.straighten;
      case MeasurementType.hips:
        return Icons.straighten;
      case MeasurementType.bicepsLeft:
      case MeasurementType.bicepsRight:
        return Icons.fitness_center;
      case MeasurementType.thighLeft:
      case MeasurementType.thighRight:
        return Icons.directions_walk;
      case MeasurementType.calfLeft:
      case MeasurementType.calfRight:
        return Icons.directions_run;
      case MeasurementType.neck:
        return Icons.face;
      case MeasurementType.shoulders:
        return Icons.accessibility;
      case MeasurementType.forearmLeft:
      case MeasurementType.forearmRight:
        return Icons.sports_gymnastics;
    }
  }

  void _showAddMeasurementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMeasurementSheet(
        selectedType: _selectedType,
        isMetric: _isMetric,
        onSubmit: (type, value, unit, notes) async {
          final auth = ref.read(authStateProvider);
          if (auth.user != null) {
            final success = await ref.read(measurementsProvider.notifier).recordMeasurement(
              userId: auth.user!.id,
              type: type,
              value: value,
              unit: unit,
              notes: notes,
            );
            if (success && mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${type.displayName} recorded'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Add Measurement Sheet
// ─────────────────────────────────────────────────────────────────

class _AddMeasurementSheet extends StatefulWidget {
  final MeasurementType selectedType;
  final bool isMetric;
  final Future<void> Function(MeasurementType type, double value, String unit, String? notes) onSubmit;

  const _AddMeasurementSheet({
    required this.selectedType,
    required this.isMetric,
    required this.onSubmit,
  });

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  late MeasurementType _selectedType;
  late bool _isMetric;
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _isMetric = widget.isMetric;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Measurement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Unit toggle
                GestureDetector(
                  onTap: () => setState(() => _isMetric = !_isMetric),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      _isMetric ? 'Metric' : 'Imperial',
                      style: TextStyle(
                        fontSize: 12,
                        color: cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Measurement type selector
            Text(
              'MEASUREMENT TYPE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: MeasurementType.values.length,
                itemBuilder: (context, index) {
                  final type = MeasurementType.values[index];
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? cyan.withOpacity(0.2) : elevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? cyan : cardBorder,
                          ),
                        ),
                        child: Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? cyan : textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Value input
            Text(
              'VALUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: unit,
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes input
            Text(
              'NOTES (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add any notes...',
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: isDark ? AppColors.pureBlack : Colors.white,
                  disabledBackgroundColor: cyan.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppColors.pureBlack : Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a value'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;
    final notes = _notesController.text.trim();

    // Convert to metric if imperial was entered
    double valueToStore = value;
    String unitToStore = unit;

    if (!_isMetric && _selectedType != MeasurementType.bodyFat) {
      // Convert to metric for storage
      if (unit == 'in') {
        valueToStore = value * 2.54;
        unitToStore = 'cm';
      } else if (unit == 'lbs') {
        valueToStore = value / 2.20462;
        unitToStore = 'kg';
      }
    }

    await widget.onSubmit(
      _selectedType,
      valueToStore,
      unitToStore,
      notes.isNotEmpty ? notes : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
