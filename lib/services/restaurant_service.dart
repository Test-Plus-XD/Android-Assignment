import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Restaurant Model
class Restaurant {
  final String id;
  final String? nameEn;
  final String? nameTc;
  final String? addressEn;
  final String? addressTc;
  final String? districtEn;
  final String? districtTc;
  final double? latitude;
  final double? longitude;
  final List<String>? keywordEn;
  final List<String>? keywordTc;
  final String? imageUrl;

  Restaurant({
    required this.id,
    this.nameEn,
    this.nameTc,
    this.addressEn,
    this.addressTc,
    this.districtEn,
    this.districtTc,
    this.latitude,
    this.longitude,
    this.keywordEn,
    this.keywordTc,
    this.imageUrl,
  });

  /// Create Restaurant from JSON
  // 
  /// Handles both Algolia search results and your API responses.
  /// Algolia returns objectID, your API returns id.
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['objectID'] ?? json['id'] ?? '',
      nameEn: json['Name_EN'] ?? json['name_en'],
      nameTc: json['Name_TC'] ?? json['name_tc'],
      addressEn: json['Address_EN'] ?? json['address_en'],
      addressTc: json['Address_TC'] ?? json['address_tc'],
      districtEn: json['District_EN'] ?? json['district_en'],
      districtTc: json['District_TC'] ?? json['district_tc'],
      latitude: json['Latitude']?.toDouble() ?? json['latitude']?.toDouble(),
      longitude: json['Longitude']?.toDouble() ?? json['longitude']?.toDouble(),
      keywordEn: (json['Keyword_EN'] ?? json['keyword_en'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      keywordTc: (json['Keyword_TC'] ?? json['keyword_tc'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      imageUrl: json['ImageUrl'] ?? json['imageUrl'] ?? json['Image'],
    );
  }

  // Get display name based on language
  String getDisplayName(bool isTraditionalChinese) {
    return isTraditionalChinese ? (nameTc ?? nameEn ?? 'Unknown') : (nameEn ?? nameTc ?? 'Unknown');
  }

  // Get display address based on language
  String getDisplayAddress(bool isTraditionalChinese) {
    return isTraditionalChinese ? (addressTc ?? addressEn ?? 'Unknown') : (addressEn ?? addressTc ?? 'Unknown');
  }

  // Get display district based on language
  String getDisplayDistrict(bool isTraditionalChinese) {
    return isTraditionalChinese ? (districtTc ?? districtEn ?? 'Unknown') : (districtEn ?? districtTc ?? 'Unknown');
  }

  // Get display keywords based on language
  List<String> getDisplayKeywords(bool isTraditionalChinese) {
    return isTraditionalChinese ? (keywordTc ?? keywordEn ?? []) : (keywordEn ?? keywordTc ?? []);
  }
}

/// Algolia Search Results
// 
/// This wraps the response from Algolia search API.
/// It includes the results plus metadata about the search (total hits, pages, etc.)
class SearchResults {
  final List<Restaurant> hits;
  final int nbHits;
  final int page;
  final int nbPages;

  SearchResults({
    required this.hits,
    required this.nbHits,
    required this.page,
    required this.nbPages,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      hits: (json['hits'] as List<dynamic>?)
          ?.map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      nbHits: json['nbHits'] as int? ?? 0,
      page: json['page'] as int? ?? 0,
      nbPages: json['nbPages'] as int? ?? 0,
    );
  }
}

/// Restaurant service handling all restaurant data operations
//
/// This service uses Algolia for fast search and your Node.js API for CRUD operations.
// 
/// Why Algolia?
/// - Instant search as you type (very fast)
/// - Full-text search across all fields
/// - Faceted filtering (district, keywords)
/// - Pagination for large datasets
/// - Typo tolerance and relevance ranking
// 
/// Your Angular service uses @algolia/client-search. Flutter uses HTTP directly
/// to call Algolia's REST API, which is simpler and gives you more control.
class RestaurantService with ChangeNotifier {
  // Algolia configuration from AppConfig
  static final String _algoliaAppId = AppConfig.algoliaAppId;
  static final String _algoliaSearchKey = AppConfig.algoliaSearchKey;
  static final String _algoliaIndexName = AppConfig.algoliaIndexName;

  // Your Node.js API endpoint from AppConfig
  final String _apiUrl = AppConfig.getEndpoint('API/Restaurants');

  // Cached search results to avoid unnecessary API calls
  List<Restaurant> _searchResults = [];
  int _totalHits = 0;
  int _currentPage = 0;
  int _totalPages = 0;

  // Loading and error state
  bool _isLoading = false;
  String? _errorMessage;

  // GETTERS
  List<Restaurant> get searchResults => _searchResults;
  int get totalHits => _totalHits;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Searches restaurants using Algolia with the multi-index endpoint
  //
  /// This implementation matches your working Ionic app exactly:
  /// 1. Uses the /1/indexes/*/queries endpoint (multi-index search)
  /// 2. Sends requests as an array with a single search request
  /// 3. Includes the x-algolia-agent header for better analytics
  ///
  /// How Algolia Search Works:
  /// 1. You send a POST request with search parameters
  /// 2. Algolia processes the query across its indexed data
  /// 3. Returns ranked results with highlighting and metadata
  //
  /// Parameters:
  /// - query: Search text (searches across name, address, keywords)
  /// - districtEn: Filter by district (English name)
  /// - keywordEn: Filter by keyword (English)
  /// - isTraditionalChinese: Language for display (doesn't affect search)
  /// - page: Page number for pagination (0-indexed)
  /// - hitsPerPage: Results per page
  Future<void> searchRestaurants({
    String query = '',
    String? districtEn,
    String? keywordEn,
    bool isTraditionalChinese = false,
    int page = 0,
    int hitsPerPage = 20,
  }) async {
    // Schedule the work to run after the current build cycle is complete.
    _isLoading = true;
    notifyListeners();

    // Build the filters string
    // Algolia uses a SQL-like syntax for filters
    // Format: field:value AND field:value
    try {
      final filters = _buildFilters(districtEn, keywordEn);

      // Construct the search request parameters
      final searchParams = <String, dynamic>{
        'indexName': _algoliaIndexName,
        'query': query,
        'page': page,
        'hitsPerPage': hitsPerPage,
      };

      // Add filters if they exist
      if (filters != null) {
        searchParams['filters'] = filters;
      }

      // Use the multi-index search endpoint - /1/indexes/*/queries
      final url = Uri.parse(
          'https://$_algoliaAppId-dsn.algolia.net/1/indexes/*/queries'
      );

      // Build the request body with the requests array
      final requestBody = {
        'requests': [searchParams],
      };

      if (kDebugMode) {
        print('RestaurantService: Searching Algolia...');
        print('URL: $url');
        print('Body: ${jsonEncode(requestBody)}');
      }

      // Send the POST request with proper headers
      final response = await http.post(
        url,
        headers: {
          'X-Algolia-API-Key': _algoliaSearchKey,
          'X-Algolia-Application-Id': _algoliaAppId,
          'Content-Type': 'application/json',
          'x-algolia-agent': 'Flutter Client; Algolia for Dart', // Add the user agent header for better analytics tracking
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Algolia search timed out after 10 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The multi-index endpoint returns a results array
        // Extract the first result (since only one request is sent)
        final resultsArray = data['results'] as List<dynamic>;
        if (resultsArray.isEmpty) {
          _searchResults = [];
          _totalHits = 0;
          _currentPage = 0;
          _totalPages = 0;
        } else {
          final searchResult = resultsArray[0] as Map<String, dynamic>;
          final results = SearchResults.fromJson(searchResult);

          _searchResults = results.hits;
          _totalHits = results.nbHits;
          _currentPage = results.page;
          _totalPages = results.nbPages;
        }
        _errorMessage = null;
        if (kDebugMode) print('RestaurantService: Search successful - found $_totalHits restaurants');
      } else {
        _errorMessage = 'Search failed: ${response.statusCode}';
        _searchResults = [];
        if (kDebugMode) print('RestaurantService Error: ${response.body}');
      }
    } catch (e) {
      _errorMessage = 'Search error: $e';
      _searchResults = [];
      if (kDebugMode) print('RestaurantService Exception: $e');
    } finally {
      // Ensure loading state is always turned off
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Builds Algolia filter syntax from selected filters
  //
  /// Algolia uses a SQL-like syntax for filters. This method constructs
  /// filter strings like: District_EN:"Kowloon" AND Keyword_EN:"veggie"
  String? _buildFilters(String? districtEn, String? keywordEn) {
    final parts = <String>[];

    // Add district filter if specified and not "All Districts"
    if (districtEn != null && districtEn.isNotEmpty && districtEn != 'All Districts') {
      // Escape any quotes in the value and wrap multi-word values in quotes
      final escapedDistrict = districtEn.replaceAll('"', '\\"');
      final quotedDistrict = districtEn.contains(' ') ? '"$escapedDistrict"' : escapedDistrict;
      parts.add('District_EN:$quotedDistrict');
    }

    // Add keyword filter if specified
    if (keywordEn != null && keywordEn.isNotEmpty) {
      final escapedKeyword = keywordEn.replaceAll('"', '\\"');
      final quotedKeyword = keywordEn.contains(' ') ? '"$escapedKeyword"' : escapedKeyword;
      parts.add('Keyword_EN:$quotedKeyword');
    }

    // Return null if no filters, otherwise join with AND
    return parts.isEmpty ? null : parts.join(' AND ');
  }

  /// Get Restaurant by ID from API
  // 
  // Fetches a single restaurant from Node.js API.
  Future<Restaurant?> getRestaurantById(String id) async {
    _setLoading(true);
    notifyListeners();

    try {
      if (kDebugMode) {
        print('RestaurantService: Fetching restaurant $id from API');
        print('URL: $_apiUrl/$id');
      }

      final response = await http.get(
        Uri.parse('$_apiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final restaurant = Restaurant.fromJson(data);
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return restaurant;
      } else {
        _errorMessage = 'Failed to load restaurant';
        _setLoading(false);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error loading restaurant: $e';
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Load All Restaurants from API
  // 
  // Fetches all restaurants from Node.js API.
  // Only use this for small datasets - for searching, use Algolia instead.
  Future<List<Restaurant>> getAllRestaurants() async {
    _setLoading(true);
    notifyListeners();

    try {
      if (kDebugMode) {
        print('RestaurantService: Fetching all restaurants from API');
        print('URL: $_apiUrl');
      }

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final restaurants = (data['data'] as List<dynamic>)
            .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
            .toList();

        _searchResults = restaurants;
        _totalHits = restaurants.length;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();

        return restaurants;
      } else {
        _errorMessage = 'Failed to load restaurants';
        _setLoading(false);
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorMessage = 'Error loading restaurants: $e';
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  // Clear Search Results
  void clearResults() {
    _searchResults = [];
    _totalHits = 0;
    _currentPage = 0;
    _totalPages = 0;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear Error Message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set Loading State
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}