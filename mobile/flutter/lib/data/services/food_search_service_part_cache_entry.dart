part of 'food_search_service.dart';


/// LRU Cache entry with timestamp
class _CacheEntry {
  final FoodSearchResults results;
  final DateTime timestamp;

  _CacheEntry(this.results) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

