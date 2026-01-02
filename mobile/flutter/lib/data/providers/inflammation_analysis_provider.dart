import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inflammation_analysis.dart';
import '../repositories/inflammation_repository.dart';

/// Parameters for inflammation analysis
class InflammationAnalysisParams {
  final String userId;
  final String barcode;
  final String ingredientsText;
  final String? productName;

  const InflammationAnalysisParams({
    required this.userId,
    required this.barcode,
    required this.ingredientsText,
    this.productName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InflammationAnalysisParams &&
        other.userId == userId &&
        other.barcode == barcode &&
        other.ingredientsText == ingredientsText &&
        other.productName == productName;
  }

  @override
  int get hashCode =>
      userId.hashCode ^
      barcode.hashCode ^
      ingredientsText.hashCode ^
      (productName?.hashCode ?? 0);
}

/// Provider for inflammation analysis with auto-dispose
/// Uses family pattern to key by analysis parameters
final inflammationAnalysisProvider = StateNotifierProvider.autoDispose
    .family<InflammationAnalysisNotifier, InflammationAnalysisState, InflammationAnalysisParams>(
  (ref, params) {
    final repository = ref.watch(inflammationRepositoryProvider);
    return InflammationAnalysisNotifier(repository, params);
  },
);

/// Simpler provider keyed just by ingredients text (for widget use)
final inflammationByIngredientsProvider = StateNotifierProvider.autoDispose
    .family<InflammationByIngredientsNotifier, InflammationAnalysisState, String>(
  (ref, ingredientsText) {
    final repository = ref.watch(inflammationRepositoryProvider);
    return InflammationByIngredientsNotifier(repository, ingredientsText);
  },
);

/// Notifier for inflammation analysis state
class InflammationAnalysisNotifier extends StateNotifier<InflammationAnalysisState> {
  final InflammationRepository _repository;
  final InflammationAnalysisParams _params;

  InflammationAnalysisNotifier(this._repository, this._params)
      : super(const InflammationAnalysisState()) {
    // Auto-start analysis when provider is created
    _analyze();
  }

  Future<void> _analyze() async {
    if (_params.ingredientsText.isEmpty) {
      state = InflammationAnalysisState.error('No ingredients to analyze');
      return;
    }

    state = InflammationAnalysisState.loading();

    try {
      if (kDebugMode) {
        print('🔍 [Inflammation] Starting analysis for ${_params.productName ?? "unknown product"}...');
      }

      final analysis = await _repository.analyzeIngredients(
        userId: _params.userId,
        barcode: _params.barcode,
        ingredientsText: _params.ingredientsText,
        productName: _params.productName,
      );

      if (kDebugMode) {
        print('✅ [Inflammation] Analysis complete: score=${analysis.overallScore}');
      }

      state = InflammationAnalysisState.success(analysis);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Inflammation] Analysis failed: $e');
      }
      state = InflammationAnalysisState.error(e.toString());
    }
  }

  /// Retry analysis
  void retry() => _analyze();
}

/// Simpler notifier that doesn't require full params (for use in widgets)
class InflammationByIngredientsNotifier extends StateNotifier<InflammationAnalysisState> {
  final InflammationRepository _repository;
  final String _ingredientsText;

  // These will be set when analyze is called
  String? _userId;
  String? _barcode;
  String? _productName;

  InflammationByIngredientsNotifier(this._repository, this._ingredientsText)
      : super(const InflammationAnalysisState());

  /// Start analysis with the required parameters
  Future<void> analyze({
    required String userId,
    required String barcode,
    String? productName,
  }) async {
    _userId = userId;
    _barcode = barcode;
    _productName = productName;

    await _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    if (_ingredientsText.isEmpty) {
      state = InflammationAnalysisState.error('No ingredients to analyze');
      return;
    }

    if (_userId == null || _barcode == null) {
      state = InflammationAnalysisState.error('Missing required parameters');
      return;
    }

    state = InflammationAnalysisState.loading();

    try {
      if (kDebugMode) {
        print('🔍 [Inflammation] Starting analysis...');
      }

      final analysis = await _repository.analyzeIngredients(
        userId: _userId!,
        barcode: _barcode!,
        ingredientsText: _ingredientsText,
        productName: _productName,
      );

      if (kDebugMode) {
        print('✅ [Inflammation] Analysis complete: score=${analysis.overallScore}');
      }

      state = InflammationAnalysisState.success(analysis);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Inflammation] Analysis failed: $e');
      }
      state = InflammationAnalysisState.error(e.toString());
    }
  }

  /// Retry analysis
  void retry() {
    if (_userId != null && _barcode != null) {
      _runAnalysis();
    }
  }
}
