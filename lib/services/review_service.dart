import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Review Service
///
/// Manages restaurant reviews via API endpoints documented in API.md.
/// All endpoints require x-api-passcode header.
/// Create/Update/Delete operations require Firebase authentication token.
class ReviewService extends ChangeNotifier {
  final AuthService _authService;

  // State management
  List<Review> _reviews = [];
  ReviewStats? _currentStats;
  bool _isLoading = false;
  String? _error;

  ReviewService(this._authService);

  // Getters
  List<Review> get reviews => _reviews;
  ReviewStats? get currentStats => _currentStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Sets loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets error message
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Gets common headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'x-api-passcode': AppConfig.apiPasscode,
    };
  }

  /// Gets headers with authentication token
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = _getHeaders();
    final token = await _authService.idToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Fetches reviews for a restaurant or user
  ///
  /// API: GET /API/Reviews?restaurantId=X or GET /API/Reviews?userId=X
  /// Auth: Not required
  Future<List<Review>> getReviews({String? restaurantId, String? userId}) async {
    _setLoading(true);
    _setError(null);

    try {
      final queryParams = <String, String>{};
      if (restaurantId != null) queryParams['restaurantId'] = restaurantId;
      if (userId != null) queryParams['userId'] = userId;

      final uri = Uri.parse(AppConfig.getEndpoint('Reviews')).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> reviewsData = jsonData['data'] ?? [];

        _reviews = reviewsData
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();

        _setLoading(false);
        return _reviews;
      } else {
        throw Exception('Failed to load reviews: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }

  /// Fetches a single review by ID
  ///
  /// API: GET /API/Reviews/:id
  /// Auth: Not required
  Future<Review?> getReview(String reviewId) async {
    _setError(null);

    try {
      final response = await http.get(
        Uri.parse(AppConfig.getEndpoint('Reviews/$reviewId')),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Review.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        _setError('Review not found');
        return null;
      } else {
        throw Exception('Failed to load review: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Creates a new review
  ///
  /// API: POST /API/Reviews
  /// Auth: Required
  /// Returns: Review ID on success
  Future<String?> createReview(CreateReviewRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      // Ensure user is authenticated
      if (_authService.currentUser == null) {
        throw Exception('Must be logged in to create a review');
      }

      final response = await http.post(
        Uri.parse(AppConfig.getEndpoint('Reviews')),
        headers: await _getAuthHeaders(),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final reviewId = jsonData['id'] as String;

        // Refresh the reviews list
        await getReviews(restaurantId: request.restaurantId);

        _setLoading(false);
        return reviewId;
      } else {
        throw Exception('Failed to create review: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  /// Updates an existing review
  ///
  /// API: PUT /API/Reviews/:id
  /// Auth: Required (user can only update their own reviews)
  Future<bool> updateReview(String reviewId, UpdateReviewRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      // Ensure user is authenticated
      if (_authService.currentUser == null) {
        throw Exception('Must be logged in to update a review');
      }

      final response = await http.put(
        Uri.parse(AppConfig.getEndpoint('Reviews/$reviewId')),
        headers: await _getAuthHeaders(),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Update the local reviews list
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          // Refresh the specific review from server
          final updatedReview = await getReview(reviewId);
          if (updatedReview != null) {
            _reviews[index] = updatedReview;
          }
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to update review: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Deletes a review
  ///
  /// API: DELETE /API/Reviews/:id
  /// Auth: Required (user can only delete their own reviews)
  Future<bool> deleteReview(String reviewId) async {
    _setLoading(true);
    _setError(null);

    try {
      // Ensure user is authenticated
      if (_authService.currentUser == null) {
        throw Exception('Must be logged in to delete a review');
      }

      final response = await http.delete(
        Uri.parse(AppConfig.getEndpoint('Reviews/$reviewId')),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Remove from local list
        _reviews.removeWhere((r) => r.id == reviewId);

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to delete review: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Gets review statistics for a restaurant
  ///
  /// API: GET /API/Reviews/Restaurant/:restaurantId/stats
  /// Auth: Not required
  Future<ReviewStats?> getReviewStats(String restaurantId) async {
    _setError(null);

    try {
      final response = await http.get(
        Uri.parse(AppConfig.getEndpoint('Reviews/Restaurant/$restaurantId/stats')),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        _currentStats = ReviewStats.fromJson(json.decode(response.body));
        notifyListeners();
        return _currentStats;
      } else if (response.statusCode == 404) {
        // No reviews yet for this restaurant
        _currentStats = ReviewStats(
          restaurantId: restaurantId,
          totalReviews: 0,
          averageRating: 0.0,
        );
        notifyListeners();
        return _currentStats;
      } else {
        throw Exception('Failed to load review stats: ${response.body}');
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Clears all cached reviews
  void clearReviews() {
    _reviews = [];
    _currentStats = null;
    _error = null;
    notifyListeners();
  }
}
