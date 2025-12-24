import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Service for managing restaurant menu items via REST API
///
/// Handles CRUD operations for menu items stored as sub-collections
/// in Firestore. All authenticated operations require Firebase ID token.
class MenuService extends ChangeNotifier {
  final AuthService _authService;

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

  /// Fetches all menu items for a specific restaurant
  ///
  /// GET /API/Restaurants/:restaurantId/menu
  /// Returns list of menu items sorted by category
  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    _isLoading = true;
    _error = null;
    _currentRestaurantId = restaurantId;
    notifyListeners();

    try {
      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu');

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

        // Sort by category for better organization
        _menuItems.sort((a, b) {
          final catA = a.category ?? '';
          final catB = b.category ?? '';
          return catA.compareTo(catB);
        });

        if (kDebugMode) {
          print('MenuService: Loaded ${_menuItems.length} menu items');
        }
      } else if (response.statusCode == 404) {
        // Restaurant not found or no menu items
        _menuItems = [];
        if (kDebugMode) {
          print('MenuService: No menu items found for restaurant $restaurantId');
        }
      } else {
        throw Exception('Failed to load menu items: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _menuItems = [];
      if (kDebugMode) {
        print('MenuService Error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _menuItems;
  }

  /// Fetches a single menu item by ID
  ///
  /// GET /API/Restaurants/:restaurantId/menu/:menuItemId
  Future<MenuItem?> getMenuItem(String restaurantId, String menuItemId) async {
    try {
      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu/$menuItemId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MenuItem.fromJson(data);
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('MenuService: Menu item not found');
        }
        return null;
      } else {
        throw Exception('Failed to load menu item: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MenuService Error: $e');
      }
      return null;
    }
  }

  /// Creates a new menu item (requires authentication)
  ///
  /// POST /API/Restaurants/:restaurantId/menu
  /// Returns the ID of the created menu item
  Future<String> createMenuItem(
      String restaurantId, CreateMenuItemRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get Firebase ID token
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) {
        throw Exception('Authentication required');
      }

      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu');

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

        // Refresh menu items list
        if (_currentRestaurantId == restaurantId) {
          await getMenuItems(restaurantId);
        }

        if (kDebugMode) {
          print('MenuService: Created menu item $menuItemId');
        }

        return menuItemId;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create menu item');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('MenuService Error: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing menu item (requires authentication)
  ///
  /// PUT /API/Restaurants/:restaurantId/menu/:menuItemId
  Future<void> updateMenuItem(String restaurantId, String menuItemId,
      UpdateMenuItemRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get Firebase ID token
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) {
        throw Exception('Authentication required');
      }

      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu/$menuItemId');

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
        // Refresh menu items list
        if (_currentRestaurantId == restaurantId) {
          await getMenuItems(restaurantId);
        }

        if (kDebugMode) {
          print('MenuService: Updated menu item $menuItemId');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else if (response.statusCode == 404) {
        throw Exception('Menu item not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update menu item');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('MenuService Error: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a menu item (requires authentication)
  ///
  /// DELETE /API/Restaurants/:restaurantId/menu/:menuItemId
  Future<void> deleteMenuItem(String restaurantId, String menuItemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get Firebase ID token
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) {
        throw Exception('Authentication required');
      }

      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/API/Restaurants/$restaurantId/menu/$menuItemId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Remove from local list
        _menuItems.removeWhere((item) => item.id == menuItemId);

        if (kDebugMode) {
          print('MenuService: Deleted menu item $menuItemId');
        }

        notifyListeners();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else if (response.statusCode == 404) {
        throw Exception('Menu item not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete menu item');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('MenuService Error: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Groups menu items by category
  ///
  /// Returns a map where keys are category names and values are lists of items
  Map<String, List<MenuItem>> getMenuItemsByCategory() {
    final Map<String, List<MenuItem>> grouped = {};

    for (final item in _menuItems) {
      final category = item.category ?? 'Other';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }

    return grouped;
  }

  /// Clears menu items cache
  void clearCache() {
    _menuItems = [];
    _currentRestaurantId = null;
    _error = null;
    notifyListeners();
  }
}
