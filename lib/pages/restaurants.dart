import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../services/restaurant_service.dart';
import 'restaurant_detail.dart';

/// Restaurants Search Page - Infinite Scroll Implementation
///
/// This page implements a modern infinite scroll search experience using:
/// - algolia_helper_flutter: For reactive Algolia search
/// - infinite_scroll_pagination: For smooth infinite scrolling
/// - Stream-based architecture: For reactive UI updates
///
/// Key Features:
/// - Search as you type with automatic debouncing
/// - District filtering with a clean radio selection dialog
/// - Infinite scroll pagination (no manual "Load More" buttons)
/// - Reactive updates using Flutter streams
/// - Proper loading states and error handling
///
/// How Infinite Scroll Works:
/// 1. The PagingController detects when user scrolls near the bottom
/// 2. It requests the next page from RestaurantService
/// 3. New results are appended to the existing list
/// 4. The UI updates smoothly without page transitions
class RestaurantsPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const RestaurantsPage({
    this.isTraditionalChinese = false,
    super.key,
  });

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  /// Text controller for the search input field
  ///
  /// This controller captures user input and triggers search updates.
  /// We listen to its changes to implement search-as-you-type functionality.
  late final TextEditingController _searchController;

  /// Paging controller for infinite scroll
  ///
  /// This controller manages the infinite scroll pagination logic:
  /// - Tracks which pages have been loaded
  /// - Requests new pages when user scrolls near the bottom
  /// - Handles loading states and errors
  /// - Appends new items to the existing list
  ///
  /// The generic types <int, Restaurant> specify:
  /// - int: The type of the page key (page numbers are integers)
  /// - Restaurant: The type of items in the list
  late final PagingController<int, Restaurant> _pagingController;

  /// Stream subscriptions for reactive updates
  ///
  /// These subscriptions listen to the RestaurantService's streams and update
  /// the paging controller when new search results arrive. They're stored so
  /// we can properly cancel them when the widget is disposed.
  late final Stream<HitsPage> _pagesStream;
  late final Stream<SearchMetadata> _metadataStream;

  /// Selected filters state
  ///
  /// These lists store the currently selected filters. We use English tokens
  /// as the canonical values (matching your Ionic implementation) and translate
  /// them for display purposes.
  final List<String> _selectedDistrictTokens = [];

  /// Hardcoded district list for client-side filtering
  ///
  /// This list contains all Hong Kong districts with bilingual labels.
  /// The 'en' field is used as the canonical value for Algolia filters,
  /// while the 'tc' field is used for Traditional Chinese display.
  final List<Map<String, String>> _districtList = [
    {'en': 'All Districts', 'tc': '所有地區'},
    {'en': 'Islands', 'tc': '離島'},
    {'en': 'Kwai Tsing', 'tc': '葵青'},
    {'en': 'North', 'tc': '北區'},
    {'en': 'Sai Kung', 'tc': '西貢'},
    {'en': 'Sha Tin', 'tc': '沙田'},
    {'en': 'Tai Po', 'tc': '大埔'},
    {'en': 'Tsuen Wan', 'tc': '荃灣'},
    {'en': 'Tuen Mun', 'tc': '屯門'},
    {'en': 'Yuen Long', 'tc': '元朗'},
    {'en': 'Kowloon City', 'tc': '九龍城'},
    {'en': 'Kwun Tong', 'tc': '觀塘'},
    {'en': 'Sham Shui Po', 'tc': '深水埗'},
    {'en': 'Wong Tai Sin', 'tc': '黃大仙'},
    {'en': 'Yau Tsim Mong', 'tc': '油尖旺'},
    {'en': 'Central and Western', 'tc': '中西區'},
    {'en': 'Eastern', 'tc': '東區'},
    {'en': 'Southern', 'tc': '南區'},
    {'en': 'Wan Chai', 'tc': '灣仔'},
  ];

  /// Debounce timer for search input
  ///
  /// This timestamp tracks when the user last typed in the search box.
  /// We use it to implement a 300ms debounce delay, preventing excessive
  /// API calls while the user is still typing.
  DateTime? _lastSearchTime;

  /// Results per page for pagination
  ///
  /// This value determines how many restaurants are loaded at once.
  /// A larger value means fewer API calls but longer initial load time.
  /// A smaller value means smoother scrolling but more API calls.
  static const int _resultsPerPage = 12;

  @override
  void initState() {
    super.initState();

    /// Initialise controllers
    _searchController = TextEditingController();
    _pagingController = PagingController<int, Restaurant>(firstPageKey: 0);

    /// Set up stream listeners for reactive updates
    ///
    /// We need to access the RestaurantService from the Provider, but we can't
    /// use context.read() in initState. Instead, we schedule this to run after
    /// the first frame is built using addPostFrameCallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupStreams();
      _setupSearchListener();
      _setupPageRequestListener();
    });
  }

  /// Sets up stream subscriptions for reactive updates
  ///
  /// This method connects the RestaurantService's streams to the paging controller.
  /// When new search results arrive from Algolia, the paging controller is updated
  /// automatically, triggering a UI rebuild with the new data.
  void _setupStreams() {
    final restaurantService = context.read<RestaurantService>();

    /// Listen to the pages stream from RestaurantService
    ///
    /// The pages stream emits HitsPage objects containing:
    /// - items: The restaurants for this page
    /// - pageKey: The current page number
    /// - nextPageKey: The next page number (or null if last page)
    ///
    /// When a new page arrives, we:
    /// 1. Check if it's the first page (pageKey == 0)
    /// 2. If so, refresh the entire list (replaces existing items)
    /// 3. Otherwise, append the new items to the existing list
    /// 4. Pass the nextPageKey so the controller knows if there are more pages
    _pagesStream = restaurantService.pagesStream;
    _pagesStream.listen(
          (page) {
        if (page.pageKey == 0) {
          /// First page - refresh the entire list
          ///
          /// This happens when:
          /// - The page first loads
          /// - User enters a new search query
          /// - User changes filters
          ///
          /// We use refresh() to clear the existing items and replace them
          /// with the new first page of results.
          _pagingController.refresh();
          _pagingController.appendPage(page.items, page.nextPageKey);
        } else {
          /// Subsequent page - append to existing list
          ///
          /// This happens when:
          /// - User scrolls to the bottom and triggers loading more results
          ///
          /// The appendPage method:
          /// - Adds the new items to the end of the current list
          /// - Updates the nextPageKey (null means no more pages)
          /// - Triggers a UI rebuild to show the new items
          _pagingController.appendPage(page.items, page.nextPageKey);
        }
      },
      onError: (error) {
        /// Handle errors in the search stream
        ///
        /// If an error occurs during search (network failure, invalid query, etc.),
        /// we pass it to the paging controller. The controller will display an
        /// error message and provide a retry button to the user.
        _pagingController.error = error;
      },
    );
  }

  /// Sets up the search input listener with debouncing
  ///
  /// This method implements search-as-you-type functionality with debouncing.
  /// Debouncing prevents sending a new search request for every keystroke,
  /// which would waste API calls and make the UI feel sluggish.
  ///
  /// How debouncing works:
  /// 1. User types a character
  /// 2. We record the current time
  /// 3. We wait 300ms
  /// 4. If no new characters were typed during those 300ms, we search
  /// 5. If the user kept typing, we wait another 300ms
  void _setupSearchListener() {
    final restaurantService = context.read<RestaurantService>();

    _searchController.addListener(() {
      /// Record when the user last typed
      _lastSearchTime = DateTime.now();

      /// Schedule a delayed search operation
      ///
      /// We use Future.delayed to wait 300ms before checking if we should search.
      /// This creates a simple but effective debounce mechanism.
      Future.delayed(const Duration(milliseconds: 300), () {
        /// Check if enough time has passed since the last keystroke
        ///
        /// If the user has typed again during the delay, _lastSearchTime will
        /// be newer than our checkpoint, so we skip this search and wait for
        /// the next delayed callback to fire.
        if (_lastSearchTime != null &&
            DateTime.now().difference(_lastSearchTime!) >= const Duration(milliseconds: 300)) {
          /// Perform the search with current query and filters
          ///
          /// We build the Algolia filter string from selected districts and
          /// pass it along with the search query to the service.
          final filters = _buildAlgoliaFilter();
          restaurantService.search(
            query: _searchController.text.trim(),
            filters: filters,
            page: 0,
            hitsPerPage: _resultsPerPage,
          );
        }
      });
    });
  }

  /// Sets up the page request listener for infinite scroll
  ///
  /// This listener is called by the PagingController when the user scrolls
  /// near the bottom of the list and more items need to be loaded. It requests
  /// the next page from the RestaurantService.
  ///
  /// The infinite_scroll_pagination library automatically:
  /// - Detects when user approaches the end of the list
  /// - Calls this listener with the next page key
  /// - Shows a loading indicator at the bottom
  /// - Appends new items when they arrive
  void _setupPageRequestListener() {
    final restaurantService = context.read<RestaurantService>();

    _pagingController.addPageRequestListener((pageKey) {
      /// Load the requested page
      ///
      /// The pageKey is the page number to load. For the first page, it's 0.
      /// For subsequent pages, it's 1, 2, 3, etc.
      ///
      /// We don't need to pass query or filters here because the RestaurantService
      /// maintains those in its internal state. We only need to update the page number.
      restaurantService.loadPage(pageKey);
    });
  }

  /// Builds the Algolia filter string from selected filters
  ///
  /// This method constructs a filter string using Algolia's query language.
  /// Filters restrict which restaurants appear in search results.
  ///
  /// Algolia Filter Syntax Examples:
  /// - Single filter: District_EN:"Kowloon"
  /// - Multiple values (OR): District_EN:"Kowloon" OR District_EN:"Wan Chai"
  /// - Multiple filters (AND): District_EN:"Kowloon" AND Keyword_EN:"veggie"
  ///
  /// Returns null if no filters are selected (shows all results).
  String? _buildAlgoliaFilter() {
    final parts = <String>[];

    /// Add district filters if any are selected
    ///
    /// If multiple districts are selected (not currently supported in this UI,
    /// but the code is ready for it), we join them with OR operators.
    if (_selectedDistrictTokens.isNotEmpty) {
      final districtClauses = _selectedDistrictTokens
          .map((district) => 'District_EN:"${_escapeFilterValue(district)}"')
          .join(' OR ');
      if (districtClauses.isNotEmpty) {
        parts.add(districtClauses);
      }
    }

    /// Return null if no filters, otherwise join with AND
    ///
    /// Returning null tells Algolia to show all results (no filtering).
    /// If we have filters, we join them with AND so all conditions must be met.
    return parts.isEmpty ? null : parts.join(' AND ');
  }

  /// Escapes special characters in filter values
  ///
  /// Algolia filter values need to have quotes escaped to avoid syntax errors.
  /// For example, a district named 'O"Brien' would break the filter string
  /// without escaping.
  String _escapeFilterValue(String value) {
    return value.replaceAll('"', '\\"');
  }

  /// Opens the district filter selection dialog
  ///
  /// This method displays a modal dialog with a radio button list of all
  /// available districts. The user can select one district at a time.
  ///
  /// Why use radio buttons instead of checkboxes?
  /// - Simpler UX for most users (select one district at a time)
  /// - Clearer selected state visualisation
  /// - Matches common mobile UI patterns
  Future<void> _openDistrictFilter() async {
    final currentLang = widget.isTraditionalChinese ? 'TC' : 'EN';

    /// Determine the currently selected district
    ///
    /// If no district is selected, we show "All Districts" as selected.
    /// Otherwise, we show the first (and only) selected district.
    final selectedDistrict = _selectedDistrictTokens.isNotEmpty
        ? _selectedDistrictTokens[0]
        : 'All Districts';

    /// Show the filter dialog
    ///
    /// We use showDialog with AlertDialog to create a modal overlay.
    /// The dialog contains a scrollable list of radio buttons for each district.
    await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentLang == 'TC' ? '選擇地區' : 'Select District'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _districtList.map((district) {
              final districtEn = district['en']!;
              final districtTc = district['tc']!;
              final label = currentLang == 'TC' ? districtTc : districtEn;

              /// Each district gets a RadioListTile
              ///
              /// RadioListTile automatically:
              /// - Shows a radio button
              /// - Displays the district name
              /// - Handles selection (only one can be selected)
              /// - Closes the dialog when tapped
              return RadioListTile<String>(
                title: Text(label),
                value: districtEn,
                groupValue: selectedDistrict,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(currentLang == 'TC' ? '取消' : 'Cancel'),
          ),
        ],
      ),
    ).then((selectedValue) {
      /// Handle the selected district
      ///
      /// When the user selects a district and closes the dialog, this callback
      /// is called with the selected value. We update the filters and trigger
      /// a new search.
      if (selectedValue != null) {
        setState(() {
          if (selectedValue == 'All Districts') {
            /// "All Districts" means no filtering
            _selectedDistrictTokens.clear();
          } else {
            /// A specific district was selected
            _selectedDistrictTokens.clear();
            _selectedDistrictTokens.add(selectedValue);
          }
        });

        /// Trigger a new search with the updated filters
        _performSearch();
      }
    });
  }

  /// Performs a search with current query and filters
  ///
  /// This is a convenience method that packages up the current search state
  /// and sends it to the RestaurantService. It's called whenever the user
  /// changes filters or when the page first loads.
  void _performSearch() {
    final restaurantService = context.read<RestaurantService>();
    final filters = _buildAlgoliaFilter();

    restaurantService.search(
      query: _searchController.text.trim(),
      filters: filters,
      page: 0,
      hitsPerPage: _resultsPerPage,
    );
  }

  /// Clears the district filter
  ///
  /// This method removes all district filters and triggers a new search
  /// to show results from all districts.
  void _clearDistrict() {
    setState(() {
      _selectedDistrictTokens.clear();
    });
    _performSearch();
  }

  /// Clears all filters and search query
  ///
  /// This method resets the search page to its initial state:
  /// - Clears the search text
  /// - Removes all filters
  /// - Triggers a new search to show all results
  void _clearAllFilters() {
    setState(() {
      _selectedDistrictTokens.clear();
      _searchController.clear();
    });
    _performSearch();
  }

  /// Gets the display label for the selected district
  ///
  /// This method converts the internal district token (English name) into
  /// the appropriate display label based on the current language setting.
  String get _selectedDistrictLabel {
    if (_selectedDistrictTokens.isEmpty) {
      return widget.isTraditionalChinese ? '所有地區' : 'All Districts';
    }

    final token = _selectedDistrictTokens[0];
    final district = _districtList.firstWhere(
          (d) => d['en'] == token,
      orElse: () => {'en': token, 'tc': token},
    );

    return widget.isTraditionalChinese ? district['tc']! : district['en']!;
  }

  /// Builds the filter chips UI
  ///
  /// Filter chips show the currently active filters and allow users to
  /// quickly remove them by tapping the 'x' icon. This provides immediate
  /// visual feedback about what filters are applied.
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          /// District filter chip
          ///
          /// This chip shows the currently selected district (or "All Districts").
          /// Tapping it opens the district selection dialog.
          /// If a specific district is selected, an 'x' icon appears to clear it.
          FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 4),
                Text(_selectedDistrictLabel),
                if (_selectedDistrictTokens.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _clearDistrict,
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ],
            ),
            selected: _selectedDistrictTokens.isNotEmpty,
            onSelected: (_) => _openDistrictFilter(),
          ),

          /// Clear all button
          ///
          /// This button appears when any filters or search text is active.
          /// It provides a quick way to reset everything and start fresh.
          if (_selectedDistrictTokens.isNotEmpty || _searchController.text.isNotEmpty)
            ActionChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, size: 18),
                  const SizedBox(width: 4),
                  Text(widget.isTraditionalChinese ? '清除所有' : 'Clear All'),
                ],
              ),
              onPressed: _clearAllFilters,
            ),
        ],
      ),
    );
  }

  /// Builds a restaurant card widget
  ///
  /// This method creates the visual representation of a single restaurant
  /// in the search results list. It includes the restaurant's image, name,
  /// district, keywords, and a "View Details" link.
  Widget _buildRestaurantCard(Restaurant restaurant) {
    final displayName = restaurant.getDisplayName(widget.isTraditionalChinese);
    final displayDistrict = restaurant.getDisplayDistrict(widget.isTraditionalChinese);
    final keywords = restaurant.getDisplayKeywords(widget.isTraditionalChinese);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            /// Navigate to restaurant detail page
            ///
            /// When the user taps a restaurant card, we push the detail page
            /// onto the navigation stack. This allows them to see full information
            /// about the restaurant and then return to the search results.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantDetailPage(
                  restaurant: restaurant,
                  isTraditionalChinese: widget.isTraditionalChinese,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Restaurant image
              ///
              /// If the restaurant has an image URL, we display it using Image.network.
              /// The errorBuilder provides a fallback placeholder if the image fails to load.
              if (restaurant.imageUrl != null)
                Image.network(
                  restaurant.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.restaurant,
                        size: 64,
                      ),
                    );
                  },
                ),

              /// Restaurant information
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Restaurant name
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    /// District
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayDistrict,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    /// Keywords
                    ///
                    /// We show up to 3 keywords as chips to give users a quick
                    /// sense of what type of restaurant this is.
                    if (keywords.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: keywords.take(3).map((keyword) => Chip(
                          label: Text(
                            keyword,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),
                    ],

                    /// View details link
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.isTraditionalChinese ? '查看詳情' : 'View Details',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    /// Clean up resources when the widget is destroyed
    ///
    /// This prevents memory leaks by:
    /// 1. Disposing of the search text controller
    /// 2. Disposing of the paging controller (which cancels stream subscriptions)
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          /// Search bar in a collapsible app bar
          ///
          /// SliverAppBar creates an app bar that can hide when scrolling down
          /// and reappear when scrolling up. This saves screen space on mobile.
          ///
          /// Properties:
          /// - floating: true - bar appears as soon as user scrolls up
          /// - snap: true - bar snaps into place (fully visible or hidden)
          /// - pinned: false - bar can scroll off screen completely
          SliverAppBar(
            title: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.isTraditionalChinese
                    ? '搜尋名稱或地址'
                    : 'Search name or address',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
            floating: true,
            snap: true,
          ),

          /// Filter chips
          ///
          /// We wrap the filter chips in a SliverToBoxAdapter to include them
          /// in the CustomScrollView. This allows them to scroll with the content.
          SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),

          /// Infinite scroll list of restaurants
          ///
          /// PagedSliverList is the core of the infinite scroll implementation.
          /// It's provided by the infinite_scroll_pagination package and handles:
          /// - Displaying the current list of items
          /// - Detecting when user scrolls near the bottom
          /// - Showing loading indicators
          /// - Handling errors with retry buttons
          /// - Managing the pagination state
          ///
          /// The builderDelegate specifies how to build each item and how to
          /// display loading, error, and empty states.
          PagedSliverList<int, Restaurant>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<Restaurant>(
              /// Item builder
              ///
              /// This callback is called for each restaurant in the list.
              /// It receives the restaurant object and its index, and returns
              /// a widget to display that restaurant.
              itemBuilder: (context, restaurant, index) =>
                  _buildRestaurantCard(restaurant),

              /// First page loading indicator
              ///
              /// Shown when loading the initial page of results (before any
              /// restaurants are displayed). We centre a circular progress
              /// indicator on the screen.
              firstPageProgressIndicatorBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),

              /// New page loading indicator
              ///
              /// Shown at the bottom of the list when loading additional pages.
              /// This appears while the user waits for more results to load.
              newPageProgressIndicatorBuilder: (_) => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

              /// Empty list indicator
              ///
              /// Shown when a search returns no results. We display a helpful
              /// message and a button to clear filters if any are active.
              noItemsFoundIndicatorBuilder: (_) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isTraditionalChinese
                            ? '沒有找到餐廳'
                            : 'No restaurants found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isTraditionalChinese
                            ? '嘗試調整您的搜尋或篩選條件'
                            : 'Try adjusting your search or filters',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_selectedDistrictTokens.isNotEmpty ||
                          _searchController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: OutlinedButton(
                            onPressed: _clearAllFilters,
                            child: Text(
                              widget.isTraditionalChinese
                                  ? '清除篩選'
                                  : 'Clear Filters',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              /// Error indicator
              ///
              /// Shown when an error occurs during search (network failure,
              /// invalid query, etc.). The infinite_scroll_pagination package
              /// automatically provides a retry button.
              firstPageErrorIndicatorBuilder: (_) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isTraditionalChinese
                            ? '載入失敗'
                            : 'Failed to load',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isTraditionalChinese
                            ? '請檢查您的網路連接'
                            : 'Please check your internet connection',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _pagingController.retryLastFailedRequest(),
                        child: Text(
                          widget.isTraditionalChinese ? '重試' : 'Retry',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Bottom spacer
          ///
          /// Adds some padding at the bottom of the list so the last item
          /// doesn't appear cut off or too close to the screen edge.
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}