import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/local/database_provider.dart';

/// On-device semantic search using EmbeddingGemma.
///
/// Generates 768-dimensional embeddings for exercises and foods,
/// stores them in Drift (SQLite), and performs cosine similarity
/// search entirely offline. Typical query time: <22ms for <10k items.
///
/// NO FALLBACK — if the embedding model isn't loaded, methods throw.
class OnDeviceEmbeddingService {
  final AppDatabase _db;

  EmbeddingModel? _embedder;
  bool _isLoaded = false;
  Timer? _autoUnloadTimer;
  String? _loadedModelVersion;

  static const Duration _autoUnloadDelay = Duration(minutes: 5);
  static const int _batchSize = 32;

  /// In-memory cache of loaded embeddings for fast search.
  /// Key: entityType, Value: list of (entityId, searchableText, vector).
  final Map<String, List<_EmbeddingEntry>> _cache = {};

  OnDeviceEmbeddingService(this._db);

  bool get isModelLoaded => _isLoaded;
  String? get loadedModelVersion => _loadedModelVersion;

  // ---------------------------------------------------------------------------
  // Model lifecycle
  // ---------------------------------------------------------------------------

  /// Load the EmbeddingGemma model from local file paths.
  ///
  /// Requires both a model file and a tokenizer file (SentencePiece .model).
  Future<void> loadModel(String modelPath, String tokenizerPath) async {
    if (_isLoaded) {
      _resetAutoUnloadTimer();
      return;
    }

    debugPrint('[Embedding] Loading model from: $modelPath');

    try {
      await FlutterGemma.installEmbedder()
          .modelFromFile(modelPath)
          .tokenizerFromFile(tokenizerPath)
          .install();

      _embedder = await FlutterGemma.getActiveEmbedder();

      final dim = await _embedder!.getDimension();
      _loadedModelVersion = 'embeddingGemma_${dim}d';
      _isLoaded = true;
      _resetAutoUnloadTimer();

      debugPrint('[Embedding] Model loaded (dim=$dim)');
    } catch (e) {
      _isLoaded = false;
      _embedder = null;
      _loadedModelVersion = null;
      debugPrint('[Embedding] Failed to load model: $e');
      throw Exception('Failed to load embedding model: $e');
    }
  }

  /// Unload the model and free memory.
  Future<void> unloadModel() async {
    _autoUnloadTimer?.cancel();
    _autoUnloadTimer = null;

    if (_isLoaded && _embedder != null) {
      debugPrint('[Embedding] Unloading model');
      try {
        await _embedder!.close();
      } catch (e) {
        debugPrint('[Embedding] Error closing model: $e');
      }
      _embedder = null;
      _isLoaded = false;
      _loadedModelVersion = null;
    }
  }

  void _resetAutoUnloadTimer() {
    _autoUnloadTimer?.cancel();
    _autoUnloadTimer = Timer(_autoUnloadDelay, () {
      debugPrint('[Embedding] Auto-unloading after ${_autoUnloadDelay.inMinutes}min inactivity');
      unloadModel();
    });
  }

  // ---------------------------------------------------------------------------
  // Embedding generation
  // ---------------------------------------------------------------------------

  /// Generate a single embedding vector.
  Future<List<double>> generateEmbedding(String text) async {
    _ensureLoaded();
    _resetAutoUnloadTimer();
    return await _embedder!.generateEmbedding(text);
  }

  /// Generate embeddings for a batch of texts.
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    _ensureLoaded();
    _resetAutoUnloadTimer();
    return await _embedder!.generateEmbeddings(texts);
  }

  // ---------------------------------------------------------------------------
  // Indexing
  // ---------------------------------------------------------------------------

  /// Index all cached exercises into the embedding table.
  ///
  /// [onProgress] reports (completed, total) for UI progress bars.
  /// Skips exercises that already have an embedding with the current model version.
  Future<void> indexExercises({
    void Function(int completed, int total)? onProgress,
  }) async {
    _ensureLoaded();

    final exercises = await _db.exerciseLibraryDao.getAllCachedExercises();
    if (exercises.isEmpty) return;

    final existingIds =
        await _db.embeddingDao.getIndexedEntityIds('exercise');
    final existingSet = existingIds.toSet();

    // Build list of exercises needing embeddings
    final toIndex = <({String id, String text})>[];
    for (final ex in exercises) {
      if (existingSet.contains(ex.id)) continue;
      final text = _buildExerciseText(ex);
      toIndex.add((id: ex.id, text: text));
    }

    if (toIndex.isEmpty) {
      debugPrint('[Embedding] All ${exercises.length} exercises already indexed');
      onProgress?.call(exercises.length, exercises.length);
      return;
    }

    debugPrint('[Embedding] Indexing ${toIndex.length} exercises...');

    for (int i = 0; i < toIndex.length; i += _batchSize) {
      final batchEnd = min(i + _batchSize, toIndex.length);
      final batch = toIndex.sublist(i, batchEnd);
      final texts = batch.map((e) => e.text).toList();

      final vectors = await generateEmbeddings(texts);

      final companions = <EmbeddingCacheCompanion>[];
      for (int j = 0; j < batch.length; j++) {
        companions.add(EmbeddingCacheCompanion.insert(
          entityType: 'exercise',
          entityId: batch[j].id,
          searchableText: batch[j].text,
          embeddingBlob: _vectorToBlob(vectors[j]),
          modelVersion: _loadedModelVersion!,
          createdAt: DateTime.now(),
        ));
      }

      await _db.embeddingDao.batchInsert(companions);
      onProgress?.call(
        existingSet.length + batchEnd,
        exercises.length,
      );
    }

    // Refresh in-memory cache
    _cache.remove('exercise');
    debugPrint('[Embedding] Indexed ${toIndex.length} exercises');
  }

  /// Index all cached foods into the embedding table.
  Future<void> indexFoods({
    void Function(int completed, int total)? onProgress,
  }) async {
    _ensureLoaded();

    final foods = await _db.foodDao.searchFoods('', limit: 50000);
    if (foods.isEmpty) return;

    final existingIds = await _db.embeddingDao.getIndexedEntityIds('food');
    final existingSet = existingIds.toSet();

    final toIndex = <({String id, String text})>[];
    for (final food in foods) {
      final foodKey = '${food.externalId}_${food.source}';
      if (existingSet.contains(foodKey)) continue;
      final text = _buildFoodText(food);
      toIndex.add((id: foodKey, text: text));
    }

    if (toIndex.isEmpty) {
      debugPrint('[Embedding] All ${foods.length} foods already indexed');
      onProgress?.call(foods.length, foods.length);
      return;
    }

    debugPrint('[Embedding] Indexing ${toIndex.length} foods...');

    for (int i = 0; i < toIndex.length; i += _batchSize) {
      final batchEnd = min(i + _batchSize, toIndex.length);
      final batch = toIndex.sublist(i, batchEnd);
      final texts = batch.map((e) => e.text).toList();

      final vectors = await generateEmbeddings(texts);

      final companions = <EmbeddingCacheCompanion>[];
      for (int j = 0; j < batch.length; j++) {
        companions.add(EmbeddingCacheCompanion.insert(
          entityType: 'food',
          entityId: batch[j].id,
          searchableText: batch[j].text,
          embeddingBlob: _vectorToBlob(vectors[j]),
          modelVersion: _loadedModelVersion!,
          createdAt: DateTime.now(),
        ));
      }

      await _db.embeddingDao.batchInsert(companions);
      onProgress?.call(
        existingSet.length + batchEnd,
        foods.length,
      );
    }

    _cache.remove('food');
    debugPrint('[Embedding] Indexed ${toIndex.length} foods');
  }

  // ---------------------------------------------------------------------------
  // Semantic search
  // ---------------------------------------------------------------------------

  /// Semantic search over exercises.
  ///
  /// Returns a list of (exerciseId, similarityScore) sorted by relevance.
  Future<List<SemanticSearchResult>> searchExercises(
    String query, {
    int limit = 10,
    double minScore = 0.3,
  }) async {
    _ensureLoaded();
    _resetAutoUnloadTimer();
    return _semanticSearch('exercise', query, limit: limit, minScore: minScore);
  }

  /// Semantic search over foods.
  Future<List<SemanticSearchResult>> searchFoods(
    String query, {
    int limit = 10,
    double minScore = 0.3,
  }) async {
    _ensureLoaded();
    _resetAutoUnloadTimer();
    return _semanticSearch('food', query, limit: limit, minScore: minScore);
  }

  Future<List<SemanticSearchResult>> _semanticSearch(
    String entityType,
    String query, {
    required int limit,
    required double minScore,
  }) async {
    // Generate query embedding
    final queryVector = await generateEmbedding(query);

    // Load entity embeddings into memory (cached)
    final entries = await _loadEmbeddings(entityType);

    // Cosine similarity search
    final results = <SemanticSearchResult>[];
    for (final entry in entries) {
      final score = _cosineSimilarity(queryVector, entry.vector);
      if (score >= minScore) {
        results.add(SemanticSearchResult(
          entityId: entry.entityId,
          score: score,
          matchedText: entry.searchableText,
        ));
      }
    }

    // Sort by score descending
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// Load embeddings from DB into in-memory cache for fast search.
  Future<List<_EmbeddingEntry>> _loadEmbeddings(String entityType) async {
    if (_cache.containsKey(entityType)) return _cache[entityType]!;

    final rows = await _db.embeddingDao.getByType(entityType);
    final entries = rows.map((row) {
      return _EmbeddingEntry(
        entityId: row.entityId,
        searchableText: row.searchableText,
        vector: _blobToVector(row.embeddingBlob),
      );
    }).toList();

    _cache[entityType] = entries;
    debugPrint('[Embedding] Loaded ${entries.length} $entityType embeddings into memory');
    return entries;
  }

  /// Invalidate the in-memory cache (call after re-indexing).
  void invalidateCache() {
    _cache.clear();
  }

  /// Get indexing stats.
  Future<Map<String, int>> getIndexStats() async {
    final exerciseCount = await _db.embeddingDao.getCountByType('exercise');
    final foodCount = await _db.embeddingDao.getCountByType('food');
    return {'exercise': exerciseCount, 'food': foodCount};
  }

  /// Re-index everything (deletes old embeddings and regenerates).
  Future<void> reindexAll({
    void Function(String phase, int completed, int total)? onProgress,
  }) async {
    _ensureLoaded();

    await _db.embeddingDao.clearAll();
    _cache.clear();

    await indexExercises(
      onProgress: (c, t) => onProgress?.call('exercises', c, t),
    );
    await indexFoods(
      onProgress: (c, t) => onProgress?.call('foods', c, t),
    );
  }

  // ---------------------------------------------------------------------------
  // Text builders
  // ---------------------------------------------------------------------------

  String _buildExerciseText(CachedExercise ex) {
    final parts = <String>[
      ex.name,
      if (ex.bodyPart != null) ex.bodyPart!,
      if (ex.targetMuscle != null) ex.targetMuscle!,
      if (ex.primaryMuscle != null) ex.primaryMuscle!,
      if (ex.secondaryMuscles != null) ex.secondaryMuscles!,
      if (ex.equipment != null) ex.equipment!,
      if (ex.difficulty != null) ex.difficulty!,
      if (ex.instructions != null)
        ex.instructions!.substring(0, min(200, ex.instructions!.length)),
    ];
    return parts.join(' ').toLowerCase();
  }

  String _buildFoodText(CachedFood food) {
    final parts = <String>[
      food.description,
      if (food.foodCategory != null) food.foodCategory!,
      if (food.brandName != null) food.brandName!,
      'protein ${food.proteinG.toStringAsFixed(0)}g',
      'carbs ${food.carbsG.toStringAsFixed(0)}g',
      'fat ${food.fatG.toStringAsFixed(0)}g',
      '${food.calories.toStringAsFixed(0)} cal',
    ];
    return parts.join(' ').toLowerCase();
  }

  // ---------------------------------------------------------------------------
  // Vector math
  // ---------------------------------------------------------------------------

  /// Cosine similarity between two vectors. Returns value in [-1, 1].
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0.0) return 0.0;
    return dotProduct / denominator;
  }

  /// Serialize a List<double> to a Uint8List (Float32 BLOB).
  Uint8List _vectorToBlob(List<double> vector) {
    final float32 = Float32List.fromList(vector);
    return float32.buffer.asUint8List();
  }

  /// Deserialize a Uint8List back to List<double>.
  List<double> _blobToVector(Uint8List blob) {
    final float32 = blob.buffer.asFloat32List();
    return float32.toList();
  }

  void _ensureLoaded() {
    if (!_isLoaded || _embedder == null) {
      throw Exception('Embedding model not loaded. Download and load EmbeddingGemma first.');
    }
  }

  void dispose() {
    _cache.clear();
    unloadModel();
  }
}

// ---------------------------------------------------------------------------
// Internal types
// ---------------------------------------------------------------------------

class _EmbeddingEntry {
  final String entityId;
  final String searchableText;
  final List<double> vector;

  _EmbeddingEntry({
    required this.entityId,
    required this.searchableText,
    required this.vector,
  });
}

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/// Result of a semantic search query.
class SemanticSearchResult {
  final String entityId;
  final double score;
  final String matchedText;

  SemanticSearchResult({
    required this.entityId,
    required this.score,
    required this.matchedText,
  });

  @override
  String toString() => 'SemanticSearchResult($entityId, score=${score.toStringAsFixed(3)})';
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final onDeviceEmbeddingServiceProvider = Provider<OnDeviceEmbeddingService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = OnDeviceEmbeddingService(db);
  ref.onDispose(() => service.dispose());
  return service;
});
