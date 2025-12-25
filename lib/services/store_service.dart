import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Store Service - Restaurant Owner Management
class StoreService extends ChangeNotifier {
  AuthService _authService;
  Restaurant? _ownedRestaurant;
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

  Future<Restaurant?> getOwnedRestaurant() async {
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

  void clearOwnedRestaurant() {
    _ownedRestaurant = null;
    _error = null;
    notifyListeners();
  }
}
