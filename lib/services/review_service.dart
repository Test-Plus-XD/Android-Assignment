import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

// Review service for fetching and managing restaurant reviews
class ReviewService with ChangeNotifier {
  // Reference to AuthService for authenticated requests
  final AuthService _authService;
  // Cached list of reviews
  List<Review> _reviews = [];
  // Loading state
  bool _isLoading = false;
  // Error message
  String? _errorMessage;

  // Getters for UI consumption
  List<Review> get reviews => List.unmodifiable(_reviews);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReviewService(this._authService);

  // Gets HTTP headers with optional authentication
  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
    };

    if (requireAuth) {
      final token = await _authService.idToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Fetches all reviews from the API with optional limit
  Future<List<Review>> fetchReviews({int? limit}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url = AppConfig.reviewsEndpoint;
      if (limit != null) {
        url += '?limit=$limit';
      }

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reviewList = data is List ? data : (data['data'] as List? ?? data['reviews'] as List? ?? []);
        _reviews = reviewList.map((r) => Review.fromJson(r as Map<String, dynamic>)).toList();

        // Sort by dateTime descending (newest first)
        _reviews.sort((a, b) {
          if (a.dateTime == null && b.dateTime == null) return 0;
          if (a.dateTime == null) return 1;
          if (b.dateTime == null) return -1;
          return b.dateTime!.compareTo(a.dateTime!);
        });

        _isLoading = false;
        notifyListeners();

        if (kDebugMode) print('ReviewService: Fetched ${_reviews.length} reviews');
        return _reviews;
      } else {
        throw Exception('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (error) {
      _errorMessage = 'Error fetching reviews: $error';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('ReviewService: Error - $error');
      return [];
    }
  }

  // Fetches reviews for a specific restaurant
  Future<List<Review>> fetchRestaurantReviews(String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${AppConfig.reviewsEndpoint}?restaurantId=$restaurantId';
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reviewList = data is List ? data : (data['data'] as List? ?? data['reviews'] as List? ?? []);
        final restaurantReviews = reviewList.map((r) => Review.fromJson(r as Map<String, dynamic>)).toList();

        _isLoading = false;
        notifyListeners();

        return restaurantReviews;
      } else {
        throw Exception('Failed to fetch restaurant reviews: ${response.statusCode}');
      }
    } catch (error) {
      _errorMessage = 'Error fetching restaurant reviews: $error';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('ReviewService: Error - $error');
      return [];
    }
  }

  // Creates a new review (requires authentication)
  Future<Review?> createReview(Review review) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getHeaders(requireAuth: true);
      final response = await http.post(
        Uri.parse(AppConfig.reviewsEndpoint),
        headers: headers,
        body: jsonEncode(review.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdReview = Review.fromJson(data);

        // Add to local cache
        _reviews.insert(0, createdReview);

        _isLoading = false;
        notifyListeners();

        if (kDebugMode) print('ReviewService: Created review');
        return createdReview;
      } else {
        throw Exception('Failed to create review: ${response.statusCode}');
      }
    } catch (error) {
      _errorMessage = 'Error creating review: $error';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('ReviewService: Error - $error');
      return null;
    }
  }

  // Gets latest reviews for home page display (supplements with mock if needed)
  Future<List<Review>> getHomePageReviews({int maxCount = 10}) async {
    // First try to fetch genuine reviews
    final genuineReviews = await fetchReviews(limit: maxCount);

    // If we have enough reviews, return them
    if (genuineReviews.length >= maxCount) {
      return genuineReviews.take(maxCount).toList();
    }

    // Otherwise, supplement with mock reviews from assets
    try {
      final mockReviews = await loadReviewsFromAssets();
      final combined = [...genuineReviews];

      // Add mock reviews until we reach maxCount
      for (final mockReview in mockReviews) {
        if (combined.length >= maxCount) break;
        combined.add(mockReview);
      }

      return combined;
    } catch (error) {
      if (kDebugMode) print('ReviewService: Error loading mock reviews - $error');
      return genuineReviews;
    }
  }

  // Formats relative time for review display
  String formatTimeAgo(DateTime? dateTime, bool isTraditionalChinese) {
    if (dateTime == null) return isTraditionalChinese ? '未知時間' : 'Unknown time';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return isTraditionalChinese ? '今天' : 'Today';
    } else if (difference.inDays == 1) {
      return isTraditionalChinese ? '昨天' : 'Yesterday';
    } else if (difference.inDays < 7) {
      return isTraditionalChinese ? '${difference.inDays}天前' : '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return isTraditionalChinese ? '$weeks週前' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return isTraditionalChinese ? '$months個月前' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return isTraditionalChinese ? '$years年前' : '$years years ago';
    }
  }

  // Clears cached reviews
  void clearCache() {
    _reviews = [];
    _errorMessage = null;
    notifyListeners();
  }

  // Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
