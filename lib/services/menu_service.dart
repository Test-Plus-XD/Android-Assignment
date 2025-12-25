import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Service for managing restaurant menu items via REST API
class MenuService extends ChangeNotifier {
  AuthService _authService;

  // State management
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _error;
  String? _currentRestaurantId;

  // Getters
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MenuService(this._authService);

  /// Update the AuthService dependency without recreating the service instance
  void updateAuth(AuthService authService) {
    if (_authService != authService) {
      _authService = authService;
      // Clear cache on logout
      if (!_authService.isLoggedIn) {
        clearCache();
      }
    }
  }

  /// Fetches all menu items for a specific restaurant
  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    _isLoading = true;
    _error = null;
    _currentRestaurantId = restaurantId;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _menuItems = data.map((json) => MenuItem.fromJson(json)).toList();
        _menuItems.sort((a, b) => (a.category ?? '').compareTo(b.category ?? ''));
      } else if (response.statusCode == 404) {
        _menuItems = [];
      } else {
        throw Exception('Failed to load menu items: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _menuItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _menuItems;
  }

  Future<MenuItem?> getMenuItem(String restaurantId, String menuItemId) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu/$menuItemId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );
      if (response.statusCode == 200) {
        return MenuItem.fromJson(json.decode(response.body));
      }
    } catch (e) {
      if (kDebugMode) print('MenuService Error: $e');
    }
    return null;
  }

  Future<String> createMenuItem(String restaurantId, CreateMenuItemRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) throw Exception('Authentication required');

      final url = Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final menuItemId = data['id'] as String;
        if (_currentRestaurantId == restaurantId) await getMenuItems(restaurantId);
        return menuItemId;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create menu item');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMenuItem(String restaurantId, String menuItemId, UpdateMenuItemRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) throw Exception('Authentication required');

      final url = Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu/$menuItemId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        if (_currentRestaurantId == restaurantId) await getMenuItems(restaurantId);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update menu item');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMenuItem(String restaurantId, String menuItemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) throw Exception('Authentication required');

      final url = Uri.parse('${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu/$menuItemId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _menuItems.removeWhere((item) => item.id == menuItemId);
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete menu item');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, List<MenuItem>> getMenuItemsByCategory() {
    final Map<String, List<MenuItem>> grouped = {};
    for (final item in _menuItems) {
      final category = item.category ?? 'Other';
      if (!grouped.containsKey(category)) grouped[category] = [];
      grouped[category]!.add(item);
    }
    return grouped;
  }

  void clearCache() {
    _menuItems = [];
    _currentRestaurantId = null;
    _error = null;
    notifyListeners();
  }
}
