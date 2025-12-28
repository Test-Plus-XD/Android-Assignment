import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Service for managing restaurant menu items via REST API
///
/// This service uses per-restaurant caching to prevent state clashes when
/// multiple pages (e.g., RestaurantDetailPage, StorePage) load
/// menu items for different restaurants simultaneously.
///
/// Key features:
/// - Map-based caching: Each restaurant's menu is cached separately by ID
/// - Intelligent refresh: Returns cached data by default, with forceRefresh option
/// - Isolated state: Loading and error states tracked per restaurant
/// - No data conflicts: Multiple pages can safely load different restaurant menus
class MenuService extends ChangeNotifier {
  AuthService _authService;

  // State management - cache menu items per restaurant ID to avoid clashes
  // Each restaurant ID maps to its own menu items, loading state, and error state
  final Map<String, List<MenuItem>> _menuItemsCache = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _errorStates = {};

  // Getters for backward compatibility (returns empty if no current restaurant)
  List<MenuItem> get menuItems => [];
  bool get isLoading => _loadingStates.values.any((loading) => loading);
  String? get error => _errorStates.values.firstWhere((e) => e != null, orElse: () => null);

  // Restaurant-specific getters - use these to access menu data for a specific restaurant
  // This prevents state clashes when multiple pages load different restaurants
  List<MenuItem> getMenuItemsForRestaurant(String restaurantId) =>
      _menuItemsCache[restaurantId] ?? [];
  bool isLoadingForRestaurant(String restaurantId) =>
      _loadingStates[restaurantId] ?? false;
  String? getErrorForRestaurant(String restaurantId) =>
      _errorStates[restaurantId];

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
  ///
  /// Uses intelligent caching to improve performance:
  /// - Returns cached data if available (unless forceRefresh is true)
  /// - Each restaurant's menu is cached separately by ID
  /// - Use forceRefresh: true after create/update/delete operations
  ///
  /// Example:
  /// ```dart
  /// // Load menu (uses cache if available)
  /// final menu = await menuService.getMenuItems('restaurant123');
  ///
  /// // Force refresh after adding a new item
  /// await menuService.getMenuItems('restaurant123', forceRefresh: true);
  /// ```
  Future<List<MenuItem>> getMenuItems(String restaurantId, {bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _menuItemsCache.containsKey(restaurantId)) {
      return _menuItemsCache[restaurantId]!;
    }

    // Update state without notifying to avoid setState during build
    // The UI will be notified after the async operation completes
    _loadingStates[restaurantId] = true;
    _errorStates[restaurantId] = null;

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
        final responseData = json.decode(response.body);
        List<dynamic> data;

        // Handle both response formats:
        // 1. Direct array: [...]
        // 2. Object with data array: {count: number, data: [...]}
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map<String, dynamic> && responseData['data'] != null) {
          data = responseData['data'] as List;
        } else {
          data = [];
        }

        final menuItems = data.map((json) => MenuItem.fromJson(json)).toList();
        menuItems.sort((a, b) => (a.category ?? '').compareTo(b.category ?? ''));
        _menuItemsCache[restaurantId] = menuItems;
      } else if (response.statusCode == 404) {
        _menuItemsCache[restaurantId] = [];
      } else {
        throw Exception('Failed to load menu items: ${response.statusCode}');
      }
    } catch (e) {
      _errorStates[restaurantId] = e.toString();
      _menuItemsCache[restaurantId] = [];
    } finally {
      _loadingStates[restaurantId] = false;
      notifyListeners();
    }
    return _menuItemsCache[restaurantId] ?? [];
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
    _loadingStates[restaurantId] = true;
    _errorStates[restaurantId] = null;
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
        // Refresh the cache for this restaurant
        await getMenuItems(restaurantId, forceRefresh: true);
        return menuItemId;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create menu item');
      }
    } catch (e) {
      _errorStates[restaurantId] = e.toString();
      rethrow;
    } finally {
      _loadingStates[restaurantId] = false;
      notifyListeners();
    }
  }

  Future<void> updateMenuItem(String restaurantId, String menuItemId, UpdateMenuItemRequest request) async {
    _loadingStates[restaurantId] = true;
    _errorStates[restaurantId] = null;
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

      // API returns 200 or 204 on successful update
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh the cache for this restaurant
        await getMenuItems(restaurantId, forceRefresh: true);
      } else {
        // Only try to parse error response if body is not empty
        String errorMessage = 'Failed to update menu item';
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['error'] ?? errorMessage;
          } catch (e) {
            // If parsing fails, use default error message
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _errorStates[restaurantId] = e.toString();
      rethrow;
    } finally {
      _loadingStates[restaurantId] = false;
      notifyListeners();
    }
  }

  Future<void> deleteMenuItem(String restaurantId, String menuItemId) async {
    _loadingStates[restaurantId] = true;
    _errorStates[restaurantId] = null;
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

      // API returns 204 No Content on successful deletion
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Update cache by removing the deleted item
        if (_menuItemsCache.containsKey(restaurantId)) {
          _menuItemsCache[restaurantId]!.removeWhere((item) => item.id == menuItemId);
        }
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete menu item');
      }
    } catch (e) {
      _errorStates[restaurantId] = e.toString();
      rethrow;
    } finally {
      _loadingStates[restaurantId] = false;
      notifyListeners();
    }
  }

  Map<String, List<MenuItem>> getMenuItemsByCategory(String restaurantId) {
    final Map<String, List<MenuItem>> grouped = {};
    final menuItems = _menuItemsCache[restaurantId] ?? [];
    for (final item in menuItems) {
      final category = item.category ?? 'Other';
      if (!grouped.containsKey(category)) grouped[category] = [];
      grouped[category]!.add(item);
    }
    return grouped;
  }

  void clearCache() {
    _menuItemsCache.clear();
    _loadingStates.clear();
    _errorStates.clear();
    notifyListeners();
  }

  void clearCacheForRestaurant(String restaurantId) {
    _menuItemsCache.remove(restaurantId);
    _loadingStates.remove(restaurantId);
    _errorStates.remove(restaurantId);
    notifyListeners();
  }
}
