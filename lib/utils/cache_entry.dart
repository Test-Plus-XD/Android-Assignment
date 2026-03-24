/// Generic cache entry with TTL support.
///
/// Wraps any value with a timestamp so callers can check expiry without
/// external packages — just DateTime arithmetic.
///
/// Usage:
/// ```dart
/// CacheEntry<List<Restaurant>>? _cache;
///
/// if (_cache != null && !_cache!.isExpired(CacheTTL.short)) {
///   return _cache!.data;
/// }
/// _cache = CacheEntry(await fetchFromApi());
/// ```
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;

  CacheEntry(this.data) : cachedAt = DateTime.now();

  bool isExpired(Duration ttl) =>
      DateTime.now().difference(cachedAt) > ttl;
}

/// TTL constants for the app.
///
/// - [short]: 1 hour — for data that changes moderately (bookings, reviews,
///   chat rooms, advertisements).
/// - [long]: 24 hours — for data that rarely changes (restaurant details,
///   store owner restaurant).
class CacheTTL {
  const CacheTTL._();

  static const Duration short = Duration(hours: 1);
  static const Duration long = Duration(hours: 24);
}
