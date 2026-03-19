import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';
import '../config.dart';
import '../models.dart';

/// Advertisement Service
///
/// Manages restaurant advertisements through the Node.js API.
/// Supports full CRUD operations plus Stripe checkout for ad payments.
///
/// Stripe checkout flow (differs from Ionic's browser redirect approach):
///   1. Call createAdCheckoutSession(restaurantId) to get a Stripe hosted URL
///   2. Open the URL in a Chrome Custom Tab via url_launcher
///   3. Store the sessionId + timestamp in SharedPreferences (2hr TTL)
///   4. When user returns to the app, check for pending session
///   5. If found, prompt to create the advertisement content
///
/// Endpoints:
///   GET    /API/Advertisements             — List ads (optional ?restaurantId=X)
///   GET    /API/Advertisements/:id         — Single ad by ID
///   POST   /API/Advertisements             — Create new ad
///   PUT    /API/Advertisements/:id         — Update ad
///   DELETE /API/Advertisements/:id         — Delete ad
///   POST   /API/Stripe/create-ad-checkout-session — Stripe payment
class AdvertisementService with ChangeNotifier {
  // API endpoints
  final String _apiUrl = AppConfig.getEndpoint('API/Advertisements');
  final String _stripeApiUrl = AppConfig.getEndpoint('API/Stripe');
  // Reference to AuthService for authentication tokens
  AuthService _authService;
  // Cached list of advertisements
  List<Advertisement> _advertisements = [];
  // Loading state
  bool _isLoading = false;
  // Error message
  String? _errorMessage;

  // SharedPreferences key for pending Stripe session
  static const String _pendingSessionKey = 'pendingAdSession';
  static const String _pendingSessionTimestampKey = 'pendingAdSessionTimestamp';
  static const String _pendingSessionRestaurantKey = 'pendingAdSessionRestaurantId';
  // Session TTL: 2 hours (matches Stripe session expiry)
  static const int _sessionTtlMs = 2 * 60 * 60 * 1000;

  // GETTERS
  List<Advertisement> get advertisements => _advertisements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AdvertisementService(this._authService);

  /// Update the AuthService dependency without recreating the service instance
  void updateAuth(AuthService authService) {
    _authService = authService;
  }

  /// Get HTTP headers with authentication.
  /// Includes the API passcode and Firebase ID token (if authenticated).
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.idToken;
    return {
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all advertisements, optionally filtered by restaurant ID.
  /// Uses GET /API/Advertisements?restaurantId=X
  /// Set includeInactive to true to include inactive ads (for store owner view).
  Future<List<Advertisement>> getAdvertisements({
    String? restaurantId,
    bool includeInactive = false,
  }) async {
    try {
      _setLoading(true);

      final headers = await _getHeaders();
      // Build query parameters
      final queryParams = <String, String>{};
      if (restaurantId != null) queryParams['restaurantId'] = restaurantId;
      if (includeInactive) queryParams['includeInactive'] = 'true';

      final uri = Uri.parse(_apiUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ads = (data['data'] as List<dynamic>)
            .map((json) => Advertisement.fromJson(json as Map<String, dynamic>))
            .toList();

        _advertisements = ads;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return ads;
      } else {
        _errorMessage = 'Failed to load advertisements';
        _setLoading(false);
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorMessage = 'Error loading advertisements: $e';
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  /// Get a single advertisement by ID.
  /// Uses GET /API/Advertisements/:id
  Future<Advertisement?> getAdvertisement(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_apiUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Advertisement.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('AdvertisementService: Error getting ad - $e');
      return null;
    }
  }

  /// Create a new advertisement.
  /// Uses POST /API/Advertisements — requires authentication.
  /// The API auto-sets the userId from the auth token.
  Future<Advertisement?> createAdvertisement(CreateAdvertisementRequest request) async {
    try {
      _setLoading(true);

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final adId = data['id'] as String;
        // Fetch the full advertisement to get all fields
        final ad = await getAdvertisement(adId);
        if (ad != null) _advertisements.insert(0, ad);
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return ad;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to create advertisement';
        _setLoading(false);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error creating advertisement: $e';
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Update an existing advertisement.
  /// Uses PUT /API/Advertisements/:id — only owner can update.
  Future<bool> updateAdvertisement(String id, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_apiUrl/$id'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh the ad in the local cache
        final index = _advertisements.indexWhere((a) => a.id == id);
        if (index != -1) {
          final updated = await getAdvertisement(id);
          if (updated != null) _advertisements[index] = updated;
        }
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to update advertisement';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating advertisement: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Delete an advertisement.
  /// Uses DELETE /API/Advertisements/:id — only owner can delete.
  /// The API also attempts to delete associated images from Firebase Storage.
  Future<bool> deleteAdvertisement(String id) async {
    try {
      _setLoading(true);

      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_apiUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _advertisements.removeWhere((a) => a.id == id);
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to delete advertisement';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting advertisement: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Toggle advertisement status between active and inactive.
  /// Convenience wrapper around updateAdvertisement.
  Future<bool> toggleAdStatus(String id, {required bool activate}) async {
    return await updateAdvertisement(id, {
      'status': activate ? 'active' : 'inactive',
    });
  }

  // ───────────────────────────────────────────────────────
  // AI Content Generation
  // ───────────────────────────────────────────────────────

  /// Generate bilingual advertisement copy using Gemini AI.
  /// Calls POST /API/Gemini/restaurant-advertisement.
  /// Returns a [GeminiAdCopyResponse] with Title_EN/TC and Content_EN/TC,
  /// or null on error. Does not modify shared loading/advertisement state.
  Future<GeminiAdCopyResponse?> generateAdCopy({
    required String restaurantId,
    required String name,
    required String district,
    List<String>? keywords,
    String? message,
  }) async {
    try {
      final headers = await _getHeaders();
      final request = GeminiAdCopyRequest(
        restaurantId: restaurantId,
        name: name,
        district: district,
        keywords: keywords,
        message: message,
      );

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Gemini/restaurant-advertisement'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GeminiAdCopyResponse.fromJson(data);
      } else {
        if (kDebugMode) {
          print('AdvertisementService: Ad copy generation failed - ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AdvertisementService: Error generating ad copy - $e');
      }
      return null;
    }
  }

  // ───────────────────────────────────────────────────────
  // Stripe Checkout Flow
  // ───────────────────────────────────────────────────────

  /// Create a Stripe checkout session for purchasing an advertisement.
  /// Calls POST /API/Stripe/create-ad-checkout-session with restaurantId.
  /// Returns the Stripe hosted checkout URL and opens it in a Chrome Custom Tab.
  /// Stores the session ID in SharedPreferences for retrieval when user returns.
  Future<bool> createAdCheckoutSession(String restaurantId) async {
    try {
      _setLoading(true);

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_stripeApiUrl/create-ad-checkout-session'),
        headers: headers,
        body: jsonEncode({'restaurantId': restaurantId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['sessionId'] as String;
        final url = data['url'] as String;

        // Store session info in SharedPreferences for when user returns
        await _storePendingSession(sessionId, restaurantId);

        // Open Stripe checkout URL in Chrome Custom Tab
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to create checkout session';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating checkout session: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Store a pending Stripe session in SharedPreferences.
  /// Includes a timestamp for TTL checking (expires after 2 hours).
  Future<void> _storePendingSession(String sessionId, String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSessionKey, sessionId);
    await prefs.setInt(_pendingSessionTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(_pendingSessionRestaurantKey, restaurantId);
  }

  /// Check for a pending Stripe session in SharedPreferences.
  /// Returns the restaurant ID if a valid (non-expired) session exists,
  /// or null if no session or session has expired (2hr TTL).
  Future<String?> checkPendingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_pendingSessionKey);
    final timestamp = prefs.getInt(_pendingSessionTimestampKey);
    final restaurantId = prefs.getString(_pendingSessionRestaurantKey);

    if (sessionId == null || timestamp == null || restaurantId == null) {
      return null;
    }

    // Check if session has expired (2-hour TTL)
    final elapsed = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (elapsed > _sessionTtlMs) {
      // Session expired, clean up
      await clearPendingSession();
      return null;
    }

    return restaurantId;
  }

  /// Clear the pending Stripe session from SharedPreferences.
  /// Called after the ad creation form has been submitted or dismissed.
  Future<void> clearPendingSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSessionKey);
    await prefs.remove(_pendingSessionTimestampKey);
    await prefs.remove(_pendingSessionRestaurantKey);
  }

  /// Clear all cached advertisement data
  void clearCache() {
    _advertisements = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear the current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Internal helper to set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
