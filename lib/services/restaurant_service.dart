import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import '../config.dart';

/// Restaurant Model
///
/// Represents a restaurant entity with bilingual support (English and Traditional Chinese).
/// This model handles both Algolia search results and potential API responses.
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

  /// Creates a Restaurant instance from JSON data
  ///
  /// This factory constructor handles both Algolia search results (which use objectID)
  /// and your custom API responses (which might use id). It safely extracts values
  /// and provides defaults for missing fields.
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

  /// Returns the restaurant name in the appropriate language
  ///
  /// Falls back to the alternate language if the preferred language is unavailable.
  String getDisplayName(bool isTraditionalChinese) {
    return isTraditionalChinese ? (nameTc ?? nameEn ?? 'Unknown') : (nameEn ?? nameTc ?? 'Unknown');
  }

  /// Returns the restaurant address in the appropriate language
  String getDisplayAddress(bool isTraditionalChinese) {
    return isTraditionalChinese ? (addressTc ?? addressEn ?? 'Unknown') : (addressEn ?? addressTc ?? 'Unknown');
  }

  /// Returns the district name in the appropriate language
  String getDisplayDistrict(bool isTraditionalChinese) {
    return isTraditionalChinese ? (districtTc ?? districtEn ?? 'Unknown') : (districtEn ?? districtTc ?? 'Unknown');
  }

  /// Returns the keywords list in the appropriate language
  List<String> getDisplayKeywords(bool isTraditionalChinese) {
    return isTraditionalChinese ? (keywordTc ?? keywordEn ?? []) : (keywordEn ?? keywordTc ?? []);
  }
}

/// Search Metadata Model
///
/// Contains metadata about a search response, primarily the total number of hits.
/// This is used to display search statistics to users (e.g., "Found 42 restaurants").
class SearchMetadata {
  final int nbHits;

  const SearchMetadata(this.nbHits);

  /// Creates SearchMetadata from an Algolia SearchResponse
  ///
  /// Extracts the total number of hits from the response object.
  factory SearchMetadata.fromResponse(SearchResponse response) {
    return SearchMetadata(response.nbHits);
  }
}

/// Hits Page Model
///
/// Represents a single page of search results for pagination purposes.
/// This model works with the infinite_scroll_pagination package to handle
/// loading subsequent pages as the user scrolls.
class HitsPage {
  final List<Restaurant> items;
  final int pageKey;
  final int? nextPageKey;

  const HitsPage(this.items, this.pageKey, this.nextPageKey);

  /// Creates a HitsPage from an Algolia SearchResponse
  ///
  /// This factory method performs several important tasks:
  /// 1. Converts raw JSON hits into Restaurant objects
  /// 2. Determines if this is the last page of results
  /// 3. Calculates the next page key (null if this is the last page)
  ///
  /// The infinite scroll pagination library uses the nextPageKey to know
  /// whether to load more results. A null value indicates no more pages.
  factory HitsPage.fromResponse(SearchResponse response) {
    final items = response.hits.map((hit) => Restaurant.fromJson(hit)).toList();
    final isLastPage = response.page >= response.nbPages - 1;
    final nextPageKey = isLastPage ? null : response.page + 1;
    return HitsPage(items, response.page, nextPageKey);
  }
}

/// Restaurant Service - Algolia Helper Flutter Implementation
///
/// This service manages restaurant search using Algolia's official Flutter helper library.
/// It provides a reactive, stream-based interface for search operations.
///
/// Architecture Overview:
/// - Uses HitsSearcher from algolia_helper_flutter for search operations
/// - Provides streams that UI widgets can listen to for reactive updates
/// - Handles search state management including filters, pagination, and query text
/// - Integrates seamlessly with infinite_scroll_pagination for smooth scrolling
///
/// Why algolia_helper_flutter?
/// 1. Official Algolia library designed specifically for Flutter
/// 2. Built-in support for common UI patterns (infinite scroll, faceting)
/// 3. Automatic state management and debouncing
/// 4. Stream-based reactive architecture matches Flutter's patterns
/// 5. Simpler API than raw HTTP or low-level client packages
class RestaurantService with ChangeNotifier {
  /// Algolia configuration from AppConfig
  static final String _algoliaAppId = AppConfig.algoliaAppId;
  static final String _algoliaSearchKey = AppConfig.algoliaSearchKey;
  static final String _algoliaIndexName = AppConfig.algoliaIndexName;

  /// HitsSearcher - The core search component
  ///
  /// HitsSearcher manages the entire search lifecycle:
  /// - Sends search requests to Algolia
  /// - Manages search state (query, filters, page number)
  /// - Provides reactive streams for responses
  /// - Handles debouncing to avoid excessive API calls
  ///
  /// This is initialised once when the service is created and reused throughout
  /// the app's lifecycle. The searcher maintains its own internal state.
  late final HitsSearcher _hitsSearcher;

  /// Stream subscriptions for reactive updates
  ///
  /// These subscriptions listen to the HitsSearcher's response streams and
  /// update the service's cached state accordingly. They're stored so we can
  /// properly dispose of them when the service is destroyed.
  StreamSubscription<SearchResponse>? _responsesSubscription;
  StreamSubscription<SearchMetadata>? _metadataSubscription;

  /// Cached search state
  ///
  /// These properties store the current search results and metadata.
  /// They're updated whenever new responses arrive from Algolia.
  /// The UI reads these values and rebuilds when notifyListeners() is called.
  List<Restaurant> _searchResults = [];
  int _totalHits = 0;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = false;
  String? _errorMessage;

  /// Public getters for accessing cached state
  ///
  /// These getters allow UI components to read the current search state
  /// without being able to modify it directly. All state changes go through
  /// the service's methods, maintaining a single source of truth.
  List<Restaurant> get searchResults => _searchResults;
  int get totalHits => _totalHits;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Stream exposing the HitsSearcher's responses
  ///
  /// This stream emits SearchResponse objects whenever a search completes.
  /// UI components can listen to this stream for reactive updates.
  /// The stream automatically handles errors and provides them to listeners.
  Stream<SearchResponse> get responsesStream => _hitsSearcher.responses;

  /// Stream exposing search metadata
  ///
  /// This stream emits SearchMetadata objects containing information like
  /// total hit count. It's useful for displaying search statistics in the UI.
  Stream<SearchMetadata> get metadataStream =>
      _hitsSearcher.responses.map(SearchMetadata.fromResponse);

  /// Stream exposing paginated results
  ///
  /// This stream is specifically designed for use with infinite_scroll_pagination.
  /// It emits HitsPage objects that contain:
  /// - The current page's items
  /// - The current page number
  /// - The next page number (or null if this is the last page)
  ///
  /// The pagination library uses this information to automatically load more
  /// results as the user scrolls down the list.
  Stream<HitsPage> get pagesStream =>
      _hitsSearcher.responses.map(HitsPage.fromResponse);

  /// Constructor initialises the Algolia searcher
  ///
  /// This sets up the HitsSearcher with your Algolia credentials and configures
  /// the initial search state. The searcher is created once and reused for all
  /// searches, maintaining its state between requests.
  RestaurantService() {
    _initialiseAlgolia();
    _setupStreamListeners();
  }

  /// Initialises the Algolia HitsSearcher
  //
  /// The HitsSearcher is configured with:
  /// - applicationID: Algolia application ID
  /// - apiKey: Search-only API key (safe for client-side use)
  /// - indexName: Which Algolia index to search
  //
  /// The initial state sets up:
  /// - indexName: Which Algolia index to search
  /// - query: Empty string (shows all results initially)
  /// - page: 0 (first page)
  /// - hitsPerPage: Number of results per page
  void _initialiseAlgolia() {
    _hitsSearcher = HitsSearcher(
      applicationID: _algoliaAppId,
      apiKey: _algoliaSearchKey,
      indexName: 'Restaurants',
    );

    if (kDebugMode) {
      print('RestaurantService: Algolia Helper initialised');
      print('App ID: $_algoliaAppId');
      print('Index: $_algoliaIndexName');
    }
  }

  /// Sets up stream listeners for reactive state updates
  ///
  /// This method subscribes to the HitsSearcher's response streams and updates
  /// the service's cached state whenever new search results arrive. The listeners
  /// handle both successful responses and errors.
  ///
  /// Why use streams?
  /// - Reactive updates: UI automatically rebuilds when data changes
  /// - Asynchronous: Doesn't block the UI thread while waiting for results
  /// - Error handling: Errors flow through the same stream pipeline
  /// - Composable: Multiple listeners can subscribe to the same stream
  void _setupStreamListeners() {
    /// Listen to search responses
    ///
    /// This subscription updates the cached search results whenever a new
    /// response arrives from Algolia. It extracts the restaurants from the
    /// response and calculates pagination metadata.
    _responsesSubscription = _hitsSearcher.responses.listen(
          (response) {
        _searchResults = response.hits.map((hit) => Restaurant.fromJson(hit)).toList();
        _totalHits = response.nbHits;
        _currentPage = response.page;
        _totalPages = response.nbPages;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();

        if (kDebugMode) {
          print('RestaurantService: Received ${_searchResults.length} results');
          print('Page $_currentPage of $_totalPages, $_totalHits total hits');
        }
      },
      onError: (error) {
        _errorMessage = 'Search error: $error';
        _isLoading = false;
        _searchResults = [];
        notifyListeners();

        if (kDebugMode) {
          print('RestaurantService Error: $error');
        }
      },
    );
  }

  /// Updates the search query text
  ///
  /// This method modifies the HitsSearcher's state to include a new query string.
  /// The searcher automatically debounces rapid changes and triggers a new search.
  ///
  /// The applyState method uses a callback pattern to update the state immutably:
  /// 1. It receives the current state
  /// 2. Creates a copy with the new query
  /// 3. Resets to page 0 (since it's a new search)
  /// 4. Triggers a new Algolia request
  ///
  /// Parameters:
  /// - query: The search text entered by the user
  void setQuery(String query) {
    _isLoading = true;
    notifyListeners();

    _hitsSearcher.applyState(
          (state) => state.copyWith(
        query: query,
        page: 0,
      ),
    );

    if (kDebugMode) {
      print('RestaurantService: Query set to "$query"');
    }
  }

  /// Updates the search filters
  ///
  /// This method applies Algolia filter syntax to restrict search results.
  /// Filters use a SQL-like syntax, for example:
  /// - District_EN:"Kowloon"
  /// - District_EN:"Kowloon" AND Keyword_EN:"veggie"
  ///
  /// When filters change, we reset to page 0 since it's effectively a new search.
  ///
  /// Parameters:
  /// - filters: Algolia filter string (null removes all filters)
  void setFilters(String? filters) {
    _isLoading = true;
    notifyListeners();

    _hitsSearcher.applyState(
          (state) => state.copyWith(
        filters: filters,
        page: 0,
      ),
    );

    if (kDebugMode) {
      print('RestaurantService: Filters set to "$filters"');
    }
  }

  /// Loads a specific page of results
  ///
  /// This method is typically called by the infinite scroll pagination controller
  /// when the user scrolls near the end of the current results. It updates the
  /// page number in the search state, triggering a new Algolia request.
  ///
  /// Parameters:
  /// - page: The zero-indexed page number to load
  void loadPage(int page) {
    _isLoading = true;
    notifyListeners();

    _hitsSearcher.applyState(
          (state) => state.copyWith(page: page),
    );

    if (kDebugMode) {
      print('RestaurantService: Loading page $page');
    }
  }

  /// Performs a complete search with all parameters
  ///
  /// This is a convenience method that updates multiple search parameters at once.
  /// It's useful when you want to change the query, filters, and pagination
  /// settings in a single operation, triggering only one Algolia request.
  ///
  /// Parameters:
  /// - query: Search text (optional)
  /// - filters: Algolia filter string (optional)
  /// - page: Page number (defaults to 0)
  /// - hitsPerPage: Results per page (optional)
  Future<void> search({
    String? query,
    String? filters,
    int page = 0,
    int? hitsPerPage,
  }) async {
    _isLoading = true;
    notifyListeners();

    _hitsSearcher.applyState(
          (state) => state.copyWith(
        query: query ?? state.query,
        filters: filters,
        page: page,
        hitsPerPage: hitsPerPage ?? state.hitsPerPage,
      ),
    );

    if (kDebugMode) {
      print('RestaurantService: Searching with query="$query", filters="$filters", page=$page');
    }
  }

  /// Clears all search results and resets state
  ///
  /// This method resets the service to its initial state, clearing all cached
  /// results and resetting the search query and filters. It's useful when the
  /// user wants to start a fresh search or when navigating away from the search page.
  void clearResults() {
    _searchResults = [];
    _totalHits = 0;
    _currentPage = 0;
    _totalPages = 0;
    _errorMessage = null;
    _isLoading = false;

    _hitsSearcher.applyState(
          (state) => state.copyWith(
        query: '',
        filters: null,
        page: 0,
      ),
    );
    notifyListeners();

    if (kDebugMode) {
      print('RestaurantService: Results cleared');
    }
  }

  /// Clears only the error message
  ///
  /// This allows the UI to dismiss error messages without affecting the search state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Disposes of resources when the service is destroyed
  ///
  /// This is critical for preventing memory leaks. It:
  /// 1. Cancels all stream subscriptions (stops listening to Algolia responses)
  /// 2. Disposes of the HitsSearcher (closes network connections)
  /// 3. Calls super.dispose() to complete the ChangeNotifier disposal
  ///
  /// Flutter calls this method automatically when the service is removed from
  /// the widget tree (e.g., when the app is closed or when using Provider with
  /// dependency injection).
  @override
  void dispose() {
    _responsesSubscription?.cancel();
    _metadataSubscription?.cancel();
    _hitsSearcher.dispose();
    super.dispose();

    if (kDebugMode) {
      print('RestaurantService: Disposed');
    }
  }
}