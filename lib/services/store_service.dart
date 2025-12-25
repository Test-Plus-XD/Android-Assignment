import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Store Service - Restaurant Owner Management
///
/// Handles restaurant ownership claims, updates, and management.
/// This service is for restaurant owners to manage their businesses.
class StoreService extends ChangeNotifier {
  final AuthService _authService;

  // State
  Restaurant? _ownedRestaurant;
  bool _isLoading = false;
  String? _error;

  // Getters
  Restaurant? get ownedRestaurant => _ownedRestaurant;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOwnedRestaurant => _ownedRestaurant != null;

  StoreService(this._authService);

  /// Claim restaurant ownership
  ///
  /// POST /API/Restaurants/:id/claim
  /// Requires authentication
  Future<bool> claimRestaurant(String restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: true);
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _ownedRestaurant = Restaurant.fromJson(data);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['message'] ?? 'Failed to claim restaurant';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error claiming restaurant: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get owned restaurant
  ///
  /// Fetches the restaurant owned by the current user
  /// Note: This requires the user to have 'restaurantId' field in their profile
  Future<Restaurant?> getOwnedRestaurant() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: true);
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get user profile to find owned restaurant ID
      final userResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Users/${user.uid}'),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final restaurantId = userData['restaurantId'];

        if (restaurantId != null) {
          // Fetch restaurant details
          final restaurantResponse = await http.get(
            Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId'),
            headers: {
              'x-api-passcode': AppConfig.apiPasscode,
            },
          );

          if (restaurantResponse.statusCode == 200) {
            final restaurantData = json.decode(restaurantResponse.body);
            _ownedRestaurant = Restaurant.fromJson(restaurantData);
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
      if (kDebugMode) print('Error getting owned restaurant: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update restaurant details
  ///
  /// PUT /API/Restaurants/:id
  /// Requires authentication and ownership
  Future<bool> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: true);
      if (token == null) {
        throw Exception('Not authenticated');
      }

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
        final data = json.decode(response.body);
        _ownedRestaurant = Restaurant.fromJson(data);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['message'] ?? 'Failed to update restaurant';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error updating restaurant: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload restaurant image
  ///
  /// POST /API/Restaurants/:id/image
  /// Requires authentication and ownership
  Future<String?> uploadRestaurantImage(
    String restaurantId,
    String imagePath,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: true);
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'x-api-passcode': AppConfig.apiPasscode,
      });

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final imageUrl = data['imageUrl'] ?? data['downloadURL'];

        // Update owned restaurant image URL
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
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['message'] ?? 'Failed to upload image';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Error uploading restaurant image: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear owned restaurant data
  void clearOwnedRestaurant() {
    _ownedRestaurant = null;
    _error = null;
    notifyListeners();
  }
}
