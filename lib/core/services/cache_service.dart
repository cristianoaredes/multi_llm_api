import 'dart:collection';

/// A simple in-memory cache service with LRU (Least Recently Used) eviction policy.
///
/// This cache service is used to store and retrieve values by key, with automatic
/// expiration and LRU eviction when the cache reaches its maximum size.
class CacheService<K, V> {
  /// Creates a new cache service with the specified maximum size and TTL.
  ///
  /// [maxSize] is the maximum number of entries to keep in the cache.
  /// [ttlSeconds] is the time-to-live in seconds for each entry.
  CacheService({
    required this.maxSize,
    required this.ttlSeconds,
  });

  /// The maximum number of entries to keep in the cache.
  final int maxSize;

  /// The time-to-live in seconds for each entry.
  final int ttlSeconds;

  /// The cache entries, ordered by most recently used.
  final _cache = LinkedHashMap<K, _CacheEntry<V>>();

  /// Gets a value from the cache by key.
  ///
  /// Returns null if the key is not found or the entry has expired.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }

    // Check if the entry has expired
    if (_isExpired(entry)) {
      _cache.remove(key);
      return null;
    }

    // Move the entry to the end of the linked hash map (most recently used)
    _cache.remove(key);
    _cache[key] = entry;

    return entry.value;
  }

  /// Puts a value in the cache with the specified key.
  ///
  /// If the cache is full, the least recently used entry will be evicted.
  void put(K key, V value) {
    // Remove the entry if it already exists
    _cache.remove(key);

    // Evict the least recently used entry if the cache is full
    if (_cache.length >= maxSize) {
      _evictLRU();
    }

    // Add the new entry
    _cache[key] = _CacheEntry<V>(
      value: value,
      timestamp: DateTime.now(),
    );
  }

  /// Removes a value from the cache by key.
  void remove(K key) {
    _cache.remove(key);
  }

  /// Clears all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// Gets the current size of the cache.
  int get size => _cache.length;

  /// Checks if the cache contains a non-expired entry for the specified key.
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) {
      return false;
    }

    if (_isExpired(entry)) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Evicts all expired entries from the cache.
  void evictExpired() {
    final expiredKeys = <K>[];

    _cache.forEach((key, entry) {
      if (_isExpired(entry)) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Checks if an entry has expired.
  bool _isExpired(_CacheEntry<V> entry) {
    final now = DateTime.now();
    return now.difference(entry.timestamp).inSeconds > ttlSeconds;
  }

  /// Evicts the least recently used entry from the cache.
  void _evictLRU() {
    if (_cache.isEmpty) {
      return;
    }

    // The first entry in the linked hash map is the least recently used
    final lruKey = _cache.keys.first;
    _cache.remove(lruKey);
  }
}

/// A cache entry with a value and a timestamp.
class _CacheEntry<V> {
  /// Creates a new cache entry with the specified value and timestamp.
  _CacheEntry({
    required this.value,
    required this.timestamp,
  });

  /// The cached value.
  final V value;

  /// The timestamp when the entry was created or last accessed.
  final DateTime timestamp;
}
