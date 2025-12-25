import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Review Service
class ReviewService extends ChangeNotifier {
  AuthService _authService;
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
      // If auth state changed, we might want to clear or refresh user reviews
      if (!_authService.isLoggedIn) {
        _reviews.clear();
        _currentStats = null;
        notifyListeners();
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

  Future<List<Review>> getReviews({String? restaurantId, String? userId}) async {
    _setLoading(true);
    _setError(null);
    try {
      final queryParams = <String, String>{};
      if (restaurantId != null) queryParams['restaurantId'] = restaurantId;
      if (userId != null) queryParams['userId'] = userId;
      final uri = Uri.parse(AppConfig.getEndpoint('Reviews')).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> reviewsData = jsonData['data'] ?? [];
        _reviews = reviewsData.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
        _setLoading(false);
        return _reviews;
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }

  Future<Review?> getReview(String reviewId) async {
    try {
      final response = await http.get(Uri.parse(AppConfig.getEndpoint('Reviews/$reviewId')), headers: _getHeaders());
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
      final response = await http.post(Uri.parse(AppConfig.getEndpoint('Reviews')), headers: await _getAuthHeaders(), body: json.encode(request.toJson()));
      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final reviewId = jsonData['id'] as String;
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
      final response = await http.put(Uri.parse(AppConfig.getEndpoint('Reviews/$reviewId')), headers: await _getAuthHeaders(), body: json.encode(request.toJson()));
      if (response.statusCode == 204 || response.statusCode == 200) {
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          final updatedReview = await getReview(reviewId);
          if (updatedReview != null) _reviews[index] = updatedReview;
        }
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
      final response = await http.delete(Uri.parse(AppConfig.getEndpoint('Reviews/$reviewId')), headers: await _getAuthHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) {
        _reviews.removeWhere((r) => r.id == reviewId);
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

  Future<ReviewStats?> getReviewStats(String restaurantId) async {
    try {
      final response = await http.get(Uri.parse(AppConfig.getEndpoint('Reviews/Restaurant/$restaurantId/stats')), headers: _getHeaders());
      if (response.statusCode == 200) {
        _currentStats = ReviewStats.fromJson(json.decode(response.body));
        notifyListeners();
        return _currentStats;
      }
    } catch (e) {
      if (kDebugMode) print('ReviewService: Error - $e');
    }
    return null;
  }

  void clearReviews() {
    _reviews = [];
    _currentStats = null;
    _error = null;
    notifyListeners();
  }
}
