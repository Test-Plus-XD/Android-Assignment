import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';

// Search metadata containing result count
class SearchMetadata {
  final int nbHits;
  const SearchMetadata(this.nbHits);
  factory SearchMetadata.fromResponse(SearchResponse response) {
    return SearchMetadata(response.nbHits);
  }
}

// Page of results for infinite scroll
class HitsPage {
  final List<Restaurant> items;
  final int pageKey;
  final int? nextPageKey;
  const HitsPage(this.items, this.pageKey, this.nextPageKey);

  factory HitsPage.fromResponse(SearchResponse response) {
    final items = response.hits.map((hit) => Restaurant.fromJson(hit)).toList();
    // Debug: log pagination info
    if (kDebugMode) print('Algolia response → page: ${response.page}, nbPages: ${response.nbPages}, hits this page: ${response.hits.length}, totalHits: ${response.nbHits}');
    // Compute next page key more defensively, treat `response.page` as zero-based.
    final isLastPage = (response.page >= response.nbPages - 1);
    final int? nextPageKey = isLastPage ? null : response.page + 1;
    if (kDebugMode) print('Computed nextPageKey = $nextPageKey (isLastPage: $isLastPage)');
    return HitsPage(items, response.page, nextPageKey);
  }
}

// Restaurant service managing Algolia search and REST API operations
class RestaurantService with ChangeNotifier {
  // Algolia configuration
  static final String _algoliaAppId = AppConfig.algoliaAppId;
  static final String _algoliaSearchKey = AppConfig.algoliaSearchKey;
  static final String _algoliaIndexName = AppConfig.algoliaIndexName;
  // REST API configuration
  //static final String _apiBaseUrl = AppConfig.apiBaseUrl;
  //static final String _apiEndpoint = '$_apiBaseUrl/API/Restaurants';
  static final String _apiEndpoint = AppConfig.getEndpoint('API/Restaurants');
  // Algolia search components
  late final HitsSearcher _hitsSearcher;
  // Stream subscriptions
  StreamSubscription<SearchResponse>? _responsesSubscription;

  // Cached state
  List<Restaurant> _searchResults = [];
  int _totalHits = 0;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters for cached state
  List<Restaurant> get searchResults => _searchResults;
  int get totalHits => _totalHits;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Reactive streams
  Stream<SearchResponse> get responsesStream => _hitsSearcher.responses;
  Stream<SearchMetadata> get metadataStream =>
      _hitsSearcher.responses.map(SearchMetadata.fromResponse);
  Stream<HitsPage> get pagesStream =>
      _hitsSearcher.responses.map(HitsPage.fromResponse);

  RestaurantService() {
    _initialiseAlgolia();
    _setupStreamListeners();
  }

  // Initialises Algolia searcher
  void _initialiseAlgolia() {
    _hitsSearcher = HitsSearcher(
      applicationID: _algoliaAppId,
      apiKey: _algoliaSearchKey,
      indexName: _algoliaIndexName,
    );
    if (kDebugMode) print('RestaurantService: Algolia initialised. AppId=$_algoliaAppId, Index=$_algoliaIndexName');
  }

  // Sets up reactive listeners for search responses
  void _setupStreamListeners() {
    _responsesSubscription = _hitsSearcher.responses.listen(
          (response) {
        _searchResults = response.hits
            .map((hit) => Restaurant.fromJson(hit))
            .toList();
        _totalHits = response.nbHits;
        _currentPage = response.page;
        _totalPages = response.nbPages;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();

        if (kDebugMode) print('∘ RestaurantService: Received response → page=$_currentPage, total pages=$_totalPages, total hits=$_totalHits');
      },
      onError: (error) {
        _errorMessage = 'Search error: $error';
        _isLoading = false;
        _searchResults = [];
        notifyListeners();
        if (kDebugMode) print('RestaurantService Error: $error');
      },
    );
  }

  // Performs search with query, district and keyword filters
  Future<void> searchRestaurants({
    String query = '',
    String? districtEn,
    String? keywordEn,
    bool isTraditionalChinese = false,
    int page = 0,
    int hitsPerPage = 12,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Build facet filters
    final List<String> facetFilters = [];
    if (districtEn != null && districtEn.isNotEmpty) facetFilters.add('District_EN:$districtEn');
    if (keywordEn != null && keywordEn.isNotEmpty) facetFilters.add('Keyword_EN:$keywordEn');

    // Build state with page = 0 when new search is triggered
    _hitsSearcher.applyState(
          (state) => state.copyWith(
        query: query,
        page: page,
        hitsPerPage: hitsPerPage,
        facetFilters: facetFilters.isEmpty ? null : facetFilters,
      ),
    );
    if (kDebugMode) print('∘RestaurantService: searchRestaurants called → query="$query", page=$page, hitsPerPage=$hitsPerPage, filters=$facetFilters');
  }

  // Loads specific page (for infinite scroll)
  void loadPage(int page) {
    _isLoading = true;
    notifyListeners();
    _hitsSearcher.applyState((state) => state.copyWith(page: page));
    if (kDebugMode) print('∘RestaurantService: loadPage called → page=$page');
  }

  // Clears search results and resets state
  void clearResults() {
    _searchResults = [];
    _totalHits = 0;
    _currentPage = 0;
    _totalPages = 0;
    _errorMessage = null;
    _isLoading = false;
    _hitsSearcher.applyState((state) => state.copyWith(query: '', page: 0, facetFilters: null));
    notifyListeners();
    if (kDebugMode) print('RestaurantService: Results cleared');
  }

  // Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // === REST API CRUD Operations ===
  /// Get HTTP headers with API passcode
  Map<String, String> _getHeaders({String? authToken}) {
    return {
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
      if (authToken != null) 'Authorisation': 'Bearer $authToken',
    };
  }

  // Gets single restaurant by ID from REST API
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

  /// Create new restaurant (requires authentication)
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
        final id = json['id'] as String;
        if (kDebugMode) print('Restaurant created with ID: $id');
        return id;
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

      if (response.statusCode == 204) {
        if (kDebugMode) print('Restaurant updated: $id');
      } else if (response.statusCode == 404) {
        throw Exception('Restaurant not found: $id');
      } else {
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

      if (response.statusCode == 204) {
        if (kDebugMode) print('Restaurant deleted: $id');
      } else if (response.statusCode == 404) {
        throw Exception('Restaurant not found: $id');
      } else {
        throw Exception('Failed to delete restaurant: ${response.statusCode}');
      }
    } catch (error) {
      if (kDebugMode) print('Error deleting restaurant: $error');
      rethrow;
    }
  }

  @override
  void dispose() {
    _responsesSubscription?.cancel();
    _hitsSearcher.dispose();
    super.dispose();
    if (kDebugMode) print('RestaurantService: Disposed');
  }
}