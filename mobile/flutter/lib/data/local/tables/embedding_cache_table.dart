import 'package:drift/drift.dart';

/// Table for storing pre-computed embedding vectors for semantic search.
///
/// Supports both exercise and food embeddings in a single table,
/// differentiated by [entityType]. Vectors are stored as BLOBs
/// (serialized Float32List) for compact storage.
class EmbeddingCache extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Entity type: 'exercise' or 'food'
  TextColumn get entityType => text()();

  /// Foreign key to the source entity (exercise ID or food external ID)
  TextColumn get entityId => text()();

  /// The text that was embedded (for debugging and re-indexing detection)
  TextColumn get searchableText => text()();

  /// Embedding vector stored as BLOB (Float32List → Uint8List)
  BlobColumn get embeddingBlob => blob()();

  /// Embedding dimension (768 for EmbeddingGemma)
  IntColumn get dimension => integer().withDefault(const Constant(768))();

  /// Model version that produced this embedding (for invalidation on model change)
  TextColumn get modelVersion => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {entityType, entityId}
      ];
}
