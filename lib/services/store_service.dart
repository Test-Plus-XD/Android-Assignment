import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import '../utils/cache_entry.dart';
import 'auth_service.dart';

/// Store Service - Restaurant Owner Management
class StoreService extends ChangeNotifier {
  AuthService _authService;
  Restaurant? _ownedRestaurant;
  // TTL timestamp for owned restaurant cache (24h — rarely changes externally)
  DateTime? _ownedRestaurantCachedAt;
  bool _isLoading = false;
  String? _error;

  Restaurant? get ownedRestaurant => _ownedRestaurant;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOwnedRestaurant => _ownedRestaurant != null;

  StoreService(this._authService);

  /// Update the AuthService dependency without recreating the service instance
  void updateAuth(AuthService authService) {
    if (_authService != authService) {
      _authService = authService;
      // If logged out, clear the owned restaurant cache
      if (!_authService.isLoggedIn) {
        clearOwnedRestaurant();
      }
    }
  }

  Future<bool> claimRestaurant(String restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _authService.getIdToken(forceRefresh: true);
      if (token == null) throw Exception('Not authenticated');
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _ownedRestaurant = Restaurant.fromJson(json.decode(response.body));
        _ownedRestaurantCachedAt = DateTime.now();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = json.decode(response.body)['message'] ?? 'Failed to claim restaurant';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Restaurant?> getOwnedRestaurant({bool forceRefresh = false}) async {
    // Return cached data if still valid (24h TTL)
    if (!forceRefresh &&
        _ownedRestaurant != null &&
        _ownedRestaurantCachedAt != null &&
        DateTime.now().difference(_ownedRestaurantCachedAt!) < CacheTTL.long) {
      return _ownedRestaurant;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _authService.getIdToken(forceRefresh: true);
      if (token == null) throw Exception('Not authenticated');
      final userResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Users/${_authService.uid}'),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );
      if (userResponse.statusCode == 200) {
        final restaurantId = json.decode(userResponse.body)['restaurantId'];
        if (restaurantId != null) {
          final res = await http.get(
            Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId'),
            headers: {'x-api-passcode': AppConfig.apiPasscode},
          );
          if (res.statusCode == 200) {
            _ownedRestaurant = Restaurant.fromJson(json.decode(res.body));
            _ownedRestaurantCachedAt = DateTime.now();
            _isLoading = false;
            notifyListeners();
            return _ownedRestaurant;
          }
        }
      }
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateRestaurant(String restaurantId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _authService.getIdToken(forceRefresh: true);
      if (token == null) throw Exception('Not authenticated');
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
        },
        body: json.encode(updates),
      );
      if (response.statusCode == 200) {
        _ownedRestaurant = Restaurant.fromJson(json.decode(response.body));
        _ownedRestaurantCachedAt = DateTime.now();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = json.decode(response.body)['message'] ?? 'Failed to update';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Alias for updateRestaurant for consistency with store info editing
  Future<bool> updateRestaurantInfo(String restaurantId, Map<String, dynamic> updates) {
    return updateRestaurant(restaurantId, updates);
  }

  Future<String?> uploadRestaurantImage(String restaurantId, String imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _authService.getIdToken(forceRefresh: true);
      if (token == null) throw Exception('Not authenticated');
      final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/image'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'x-api-passcode': AppConfig.apiPasscode,
      });
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final imageUrl = data['imageUrl'] ?? data['downloadURL'];
        if (_ownedRestaurant != null) {
          _ownedRestaurant = Restaurant(
            id: _ownedRestaurant!.id,
            nameEn: _ownedRestaurant!.nameEn,
            nameTc: _ownedRestaurant!.nameTc,
            addressEn: _ownedRestaurant!.addressEn,
            addressTc: _ownedRestaurant!.addressTc,
            districtEn: _ownedRestaurant!.districtEn,
            districtTc: _ownedRestaurant!.districtTc,
            latitude: _ownedRestaurant!.latitude,
            longitude: _ownedRestaurant!.longitude,
            keywordEn: _ownedRestaurant!.keywordEn,
            keywordTc: _ownedRestaurant!.keywordTc,
            imageUrl: imageUrl,
            menu: _ownedRestaurant!.menu,
            openingHours: _ownedRestaurant!.openingHours,
            seats: _ownedRestaurant!.seats,
            contacts: _ownedRestaurant!.contacts,
          );
        }
        _isLoading = false;
        notifyListeners();
        return imageUrl;
      }
      _error = json.decode(response.body)['message'] ?? 'Upload failed';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Create a new restaurant with ownerId set, then link it to the user profile.
  /// Returns true on success, false on failure. Sets _error on failure.
  Future<bool> createRestaurant(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = _authService.uid;
      if (uid == null) throw Exception('Not authenticated');
      final token = await _authService.getIdToken(forceRefresh: true);

      // 1. POST /API/Restaurants — no auth header needed; ownerId set in body
      payload['ownerId'] = uid;
      final createResp = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
        },
        body: json.encode(payload),
      );
      if (createResp.statusCode != 201) {
        _error = json.decode(createResp.body)['error'] ?? 'Failed to create restaurant';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final newId = json.decode(createResp.body)['id'] as String;

      // 2. PUT /API/Users/:uid to link restaurantId (auth required)
      if (token == null) throw Exception('Not authenticated');
      final userResp = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Users/$uid'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'restaurantId': newId}),
      );
      if (userResp.statusCode != 204) {
        _error = 'Restaurant created but failed to link to profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Fetch the newly created restaurant to populate _ownedRestaurant
      _ownedRestaurantCachedAt = null;
      await getOwnedRestaurant(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearOwnedRestaurant() {
    _ownedRestaurant = null;
    _ownedRestaurantCachedAt = null;
    _error = null;
    notifyListeners();
  }
}
