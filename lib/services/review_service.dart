import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import '../utils/cache_entry.dart';
import 'auth_service.dart';

/// Review Service
///
/// Uses per-restaurant Map caching (1h TTL) for both reviews and stats,
/// mirroring the MenuService pattern.  Cache keys:
///   - reviews: 'r:<restaurantId>' or 'u:<userId>'
///   - stats:   '<restaurantId>'
class ReviewService extends ChangeNotifier {
  AuthService _authService;

  // Per-key reviews cache (1h TTL)
  final Map<String, CacheEntry<List<Review>>> _reviewsCache = {};
  // Per-restaurant stats cache (1h TTL)
  final Map<String, CacheEntry<ReviewStats>> _statsCache = {};

  // Backward-compatible flat view of the most recently fetched reviews list
  List<Review> _reviews = [];
  ReviewStats? _currentStats;
  bool _isLoading = false;
  String? _error;

  ReviewService(this._authService);

  List<Review> get reviews => _reviews;
  ReviewStats? get currentStats => _currentStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Update the AuthService dependency without recreating the service instance
  void updateAuth(AuthService authService) {
    if (_authService != authService) {
      _authService = authService;
      if (!_authService.isLoggedIn) {
        clearCache();
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'x-api-passcode': AppConfig.apiPasscode,
    };
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = _getHeaders();
    final token = await _authService.idToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Builds the cache key from optional query params
  String _reviewCacheKey({String? restaurantId, String? userId}) {
    if (restaurantId != null) return 'r:$restaurantId';
    if (userId != null) return 'u:$userId';
    return 'all';
  }

  Future<List<Review>> getReviews({
    String? restaurantId,
    String? userId,
    bool forceRefresh = false,
  }) async {
    final key = _reviewCacheKey(restaurantId: restaurantId, userId: userId);
    final cached = _reviewsCache[key];
    if (!forceRefresh && cached != null && !cached.isExpired(CacheTTL.short)) {
      _reviews = cached.data;
      return _reviews;
    }

    _setLoading(true);
    _setError(null);
    try {
      final queryParams = <String, String>{};
      if (restaurantId != null) queryParams['restaurantId'] = restaurantId;
      if (userId != null) queryParams['userId'] = userId;
      final uri = Uri.parse(AppConfig.getEndpoint('API/Reviews')).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (kDebugMode) print('ReviewService: Fetching reviews from $uri');
      final response = await http.get(uri, headers: _getHeaders());
      if (kDebugMode) print('ReviewService: Response status ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> reviewsData = jsonData['data'] ?? [];
        final reviews = reviewsData
            .map((j) => Review.fromJson(j as Map<String, dynamic>))
            .toList();
        _reviewsCache[key] = CacheEntry(reviews);
        _reviews = reviews;
        if (kDebugMode) print('ReviewService: Loaded ${_reviews.length} reviews');
        _setLoading(false);
        return _reviews;
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('ReviewService: Error loading reviews: $e');
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }

  Future<Review?> getReview(String reviewId) async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getEndpoint('API/Reviews/$reviewId')),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) return Review.fromJson(json.decode(response.body));
    } catch (e) {
      if (kDebugMode) print('ReviewService: Error - $e');
    }
    return null;
  }

  Future<String?> createReview(CreateReviewRequest request) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.getEndpoint('API/Reviews')),
        headers: await _getAuthHeaders(),
        body: json.encode(request.toJson()),
      );
      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final reviewId = jsonData['id'] as String;
        // Invalidate the restaurant's reviews cache and re-fetch
        _invalidateForRestaurant(request.restaurantId);
        await getReviews(restaurantId: request.restaurantId);
        _setLoading(false);
        return reviewId;
      }
      throw Exception('Failed to create review');
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateReview(String reviewId, UpdateReviewRequest request) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.put(
        Uri.parse(AppConfig.getEndpoint('API/Reviews/$reviewId')),
        headers: await _getAuthHeaders(),
        body: json.encode(request.toJson()),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        // Update in-place in the flat list + invalidate cache
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          final updatedReview = await getReview(reviewId);
          if (updatedReview != null) _reviews[index] = updatedReview;
        }
        // Invalidate all review caches (we don't know which key this belongs to)
        _reviewsCache.clear();
        _setLoading(false);
        notifyListeners();
        return true;
      }
      throw Exception('Failed to update review');
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.delete(
        Uri.parse(AppConfig.getEndpoint('API/Reviews/$reviewId')),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        _reviews.removeWhere((r) => r.id == reviewId);
        // Invalidate all review caches
        _reviewsCache.clear();
        _setLoading(false);
        notifyListeners();
        return true;
      }
      throw Exception('Failed to delete review');
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<ReviewStats?> getReviewStats(String restaurantId, {bool forceRefresh = false}) async {
    final cached = _statsCache[restaurantId];
    if (!forceRefresh && cached != null && !cached.isExpired(CacheTTL.short)) {
      _currentStats = cached.data;
      return _currentStats;
    }

    try {
      final uri = Uri.parse(AppConfig.getEndpoint('API/Reviews/Restaurant/$restaurantId/stats'));
      if (kDebugMode) print('ReviewService: Fetching review stats from $uri');
      final response = await http.get(uri, headers: _getHeaders());
      if (kDebugMode) print('ReviewService: Stats response status ${response.statusCode}');
      if (response.statusCode == 200) {
        final stats = ReviewStats.fromJson(json.decode(response.body));
        _statsCache[restaurantId] = CacheEntry(stats);
        _currentStats = stats;
        if (kDebugMode) {
          print('ReviewService: Loaded stats - avg: ${stats.averageRating}, total: ${stats.totalReviews}');
        }
        notifyListeners();
        return _currentStats;
      }
    } catch (e) {
      if (kDebugMode) print('ReviewService: Error loading stats - $e');
    }
    return null;
  }

  /// Clears cache entries for a specific restaurant
  void _invalidateForRestaurant(String restaurantId) {
    _reviewsCache.remove('r:$restaurantId');
    _statsCache.remove(restaurantId);
  }

  void clearCache() {
    _reviewsCache.clear();
    _statsCache.clear();
    _reviews = [];
    _currentStats = null;
    _error = null;
    notifyListeners();
  }

  /// Legacy alias kept for backward compatibility
  void clearReviews() => clearCache();
}
