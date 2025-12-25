import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';

/// Search metadata containing result count
class SearchMetadata {
  final int nbHits;
  const SearchMetadata(this.nbHits);
}

/// Page of results for infinite scroll
class HitsPage {
  final List<Restaurant> items;
  final int pageKey;
  final int? nextPageKey;
  const HitsPage(this.items, this.pageKey, this.nextPageKey);
}

/// Restaurant service using Vercel API for search and CRUD operations
class RestaurantService with ChangeNotifier {
  static final String _searchEndpoint = AppConfig.getEndpoint('API/Algolia/Restaurants');
  static final String _apiEndpoint = AppConfig.getEndpoint('API/Restaurants');

  final _searchResultsController = StreamController<List<Restaurant>>.broadcast();
  final _metadataController = StreamController<SearchMetadata>.broadcast();
  final _pagesController = StreamController<HitsPage>.broadcast();

  List<Restaurant> _searchResults = [];
  int _totalHits = 0;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<Restaurant> get searchResults => _searchResults;
  int get totalHits => _totalHits;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<Restaurant>> get responsesStream => _searchResultsController.stream;
  Stream<SearchMetadata> get metadataStream => _metadataController.stream;
  Stream<HitsPage> get pagesStream => _pagesController.stream;

  RestaurantService() {
    if (kDebugMode) print('RestaurantService: Initialised with Vercel API');
  }

  Map<String, String> _getHeaders({String? authToken}) {
    return {
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  /// Perform search using Vercel API
  Future<HitsPage> searchRestaurants({
    String query = '',
    List<String>? districtsEn,
    List<String>? keywordsEn,
    bool isTraditionalChinese = false,
    int page = 0,
    int hitsPerPage = 12,
    bool isInitialSearch = true,
  }) async {
    // Only set loading and notify if not already loading
    if (!_isLoading) {
      _isLoading = true;
    }

    // On a new initial search, clear previous results first
    if (isInitialSearch) {
      _searchResults = [];
      _totalHits = 0;
      _currentPage = 0;
      _totalPages = 0;
      _errorMessage = null;
    }
    
    notifyListeners();

    try {
      final int pageToFetch = isInitialSearch ? 0 : page;
      final uri = Uri.parse(_searchEndpoint).replace(queryParameters: {
        if (query.isNotEmpty) 'query': query,
        if (districtsEn != null && districtsEn.isNotEmpty) 'districts': districtsEn.join(','),
        if (keywordsEn != null && keywordsEn.isNotEmpty) 'keywords': keywordsEn.join(','),
        'page': pageToFetch.toString(),
        'hitsPerPage': hitsPerPage.toString(),
      });
      
      if (kDebugMode) print('RestaurantService: Searching → $uri');
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = (data['hits'] as List)
            .map((hit) => Restaurant.fromJson(hit))
            .toList();
            
        _searchResults = isInitialSearch ? List<Restaurant>.from(hits) : [..._searchResults, ...hits];
        _totalHits = data['nbHits'] as int;
        _currentPage = data['page'] as int;
        _totalPages = data['nbPages'] as int;

        final isLastPage = _currentPage >= _totalPages - 1;
        final nextPageKey = isLastPage ? null : _currentPage + 1;
        final hitsPage = HitsPage(hits, _currentPage, nextPageKey);

        _searchResultsController.add(List<Restaurant>.from(_searchResults));
        _metadataController.add(SearchMetadata(_totalHits));
        _pagesController.add(HitsPage(List<Restaurant>.from(_searchResults), _currentPage, nextPageKey));

        _errorMessage = null;
        _isLoading = false;
        notifyListeners();

        if (kDebugMode) {
          print('RestaurantService: Got ${_searchResults.length} results');
          print('Page $_currentPage of $_totalPages, $_totalHits total hits');
        }
        return hitsPage;
      } else {
        throw Exception('Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Search error: $e';
      _isLoading = false;
      _searchResults = [];
      notifyListeners();
      if (kDebugMode) print('RestaurantService Error: $e');
      rethrow;
    }
  }

  void clearResults() {
    _searchResults = [];
    _totalHits = 0;
    _currentPage = 0;
    _totalPages = 0;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    if (kDebugMode) print('RestaurantService: Results cleared');
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get single restaurant by ID
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      final url = Uri.parse('$_apiEndpoint/${Uri.encodeComponent(id)}');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Restaurant.fromJson(json);
      } else if (response.statusCode == 404) {
        if (kDebugMode) print('Restaurant not found: $id');
        return null;
      } else {
        throw Exception('Failed to load restaurant: ${response.statusCode}');
      }
    } catch (error) {
      if (kDebugMode) print('Error fetching restaurant: $error');
      rethrow;
    }
  }

  /// Get all restaurants
  Future<List<Restaurant>> getAllRestaurants() async {
    try {
      final url = Uri.parse(_apiEndpoint);
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        return data.map((item) => Restaurant.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (error) {
      if (kDebugMode) print('Error fetching restaurants: $error');
      rethrow;
    }
  }

  /// Create restaurant (requires authentication)
  Future<String?> createRestaurant(Restaurant restaurant, String authToken) async {
    try {
      final url = Uri.parse(_apiEndpoint);
      final response = await http.post(
        url,
        headers: _getHeaders(authToken: authToken),
        body: jsonEncode(restaurant.toJson()),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['id'] as String;
      } else {
        throw Exception('Failed to create restaurant: ${response.statusCode}');
      }
    } catch (error) {
      if (kDebugMode) print('Error creating restaurant: $error');
      rethrow;
    }
  }

  /// Update restaurant (requires authentication)
  Future<void> updateRestaurant(String id, Restaurant restaurant, String authToken) async {
    try {
      final url = Uri.parse('$_apiEndpoint/${Uri.encodeComponent(id)}');
      final response = await http.put(
        url,
        headers: _getHeaders(authToken: authToken),
        body: jsonEncode(restaurant.toJson()),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to update restaurant: ${response.statusCode}');
      }
    } catch (error) {
      if (kDebugMode) print('Error updating restaurant: $error');
      rethrow;
    }
  }

  /// Delete restaurant (requires authentication)
  Future<void> deleteRestaurant(String id, String authToken) async {
    try {
      final url = Uri.parse('$_apiEndpoint/${Uri.encodeComponent(id)}');
      final response = await http.delete(url, headers: _getHeaders(authToken: authToken));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete restaurant: ${response.statusCode}');
      }
    } catch (error) {
      if (kDebugMode) print('Error deleting restaurant: $error');
      rethrow;
    }
  }

  /// Advanced search with full SearchResponse metadata
  Future<SearchResponse> advancedSearch(AdvancedSearchRequest request) async {
    _isLoading = true;
    if (request.page == 0) {
      _searchResults = [];
    }
    notifyListeners();

    try {
      final uri = Uri.parse(_searchEndpoint).replace(
        queryParameters: request.toQueryParameters(),
      );

      if (kDebugMode) print('RestaurantService: Advanced search → $uri');
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final searchResponse = SearchResponse.fromJson(jsonDecode(response.body));

        // Update internal state
        _searchResults = request.page == 0
            ? List<Restaurant>.from(searchResponse.hits)
            : [..._searchResults, ...searchResponse.hits];
        _totalHits = searchResponse.nbHits;
        _currentPage = searchResponse.page;
        _totalPages = searchResponse.nbPages;

        // Notify listeners
        _searchResultsController.add(List<Restaurant>.from(_searchResults));
        _metadataController.add(SearchMetadata(_totalHits));

        _errorMessage = null;
        _isLoading = false;
        notifyListeners();

        return searchResponse;
      } else {
        throw Exception('Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Advanced search error: $e';
      _isLoading = false;
      _searchResults = [];
      notifyListeners();
      rethrow;
    }
  }

  /// Search restaurants near a location (geo search)
  Future<SearchResponse> searchNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    String? query,
    List<String>? districts,
    List<String>? keywords,
    int page = 0,
    int hitsPerPage = 20,
  }) async {
    final request = AdvancedSearchRequest(
      query: query,
      districts: districts,
      keywords: keywords,
      page: page,
      hitsPerPage: hitsPerPage,
      aroundLatLng: '$latitude,$longitude',
      aroundRadius: radiusMeters,
    );

    return advancedSearch(request);
  }

  /// Quick search for nearby restaurants (returns list directly)
  Future<List<Restaurant>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    int limit = 10,
  }) async {
    final response = await searchNearby(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      hitsPerPage: limit,
    );

    return response.hits;
  }

  @override
  void dispose() {
    _searchResultsController.close();
    _metadataController.close();
    _pagesController.close();
    super.dispose();
    if (kDebugMode) print('RestaurantService: Disposed');
  }
}
