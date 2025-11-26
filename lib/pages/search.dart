import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/restaurant_service.dart';
import '../models.dart';
import 'restaurant_detail.dart';

/// Search Page with Infinite Scroll Pagination (Version 5)
///
/// This implementation uses version 5 of infinite_scroll_pagination correctly
/// by managing PagingState directly with setState rather than through the
/// PagingController's automatic state management.
///
/// Version 5 architecture:
/// - PagingState is managed manually in the widget's state
/// - fetchPage returns a Future<List<ItemType>> containing the page items
/// - State updates happen through copyWith method
/// - Pages and keys are tracked separately for proper pagination
///
/// Modern aesthetic features:
/// - Card-based layout with consistent spacing
/// - Smooth animations on filter changes
/// - Empty state with helpful messaging
/// - Filter chips with visual feedback
class SearchPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const SearchPage({
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  /// Text controller for search input field
  final TextEditingController _searchController = TextEditingController();

  /// Pagination controller using version 5 API correctly
  ///
  /// The key difference in version 5 is that fetchPage must return
  /// Future<List<Restaurant>> containing just the items for that page,
  /// not Future<void>. The controller handles state management internally.
  late final PagingController<int, Restaurant> _pagingController;

  /// Currently selected filters
  String? _selectedDistrictEn;
  String? _selectedKeywordEn;

  /// Current search query
  String _currentQuery = '';

  /// Number of results to fetch per page
  static const int _pageSize = 12;

  @override
  void initState() {
    super.initState();

    /// Initialise the paging controller with version 5 API
    ///
    /// The controller configuration includes:
    /// 1. getNextPageKey: Determines the next page number to fetch
    /// 2. fetchPage: Returns the actual list of items for a page
    _pagingController = PagingController<int, Restaurant>(
      /// getNextPageKey calculates what page to fetch next
      ///
      /// The state parameter provides:
      /// - lastPageIsEmpty: true if the last fetched page had no items
      /// - nextIntPageKey: automatically calculated next page number
      /// - keys: list of all page numbers that have been fetched
      getNextPageKey: (state) {
        /// If the last page was empty, there are no more pages
        if (state.lastPageIsEmpty) return null;
        /// Return the next page number
        /// nextIntPageKey automatically increments from the last key
        return state.nextIntPageKey;
      },

      /// fetchPage must return Future<List<Restaurant>>
      ///
      /// This is the critical difference from version 4:
      /// - Version 4: fetchPage was void, you called appendPage manually
      /// - Version 5: fetchPage returns the list, controller handles state
      fetchPage: (pageKey) => _fetchPage(pageKey),
    );
  }

  /// Fetches a page of restaurants and returns the list
  ///
  /// CRITICAL: This method must return Future<List<Restaurant>>
  /// The controller will automatically:
  /// 1. Add the returned items to its internal state
  /// 2. Track the page key
  /// 3. Determine if more pages exist based on getNextPageKey
  ///
  /// This is different from version 4 where you manually called
  /// appendPage or appendLastPage to update the controller.
  Future<List<Restaurant>> _fetchPage(int pageKey) async {
    try {
      final restaurantService = context.read<RestaurantService>();

      /// Convert selected filters to lists for API
      final districtsEn = _selectedDistrictEn != null
          ? [_selectedDistrictEn!]
          : null;
      final keywordsEn = _selectedKeywordEn != null
          ? [_selectedKeywordEn!]
          : null;

      /// Determine if this is the initial search
      final isInitialSearch = pageKey == 0;

      /// Call the service to fetch results
      /// The service updates its internal state and returns a HitsPage
      final hitsPage = await restaurantService.searchRestaurants(
        query: _currentQuery,
        districtsEn: districtsEn,
        keywordsEn: keywordsEn,
        isTraditionalChinese: widget.isTraditionalChinese,
        page: pageKey,
        hitsPerPage: _pageSize,
        isInitialSearch: isInitialSearch,
      );

      /// Return just the items for this page
      /// The controller will handle adding them to its state
      return hitsPage.items;

    } catch (error) {
      /// If an error occurs, rethrow it
      /// The controller will catch it and update its error state
      rethrow;
    }
  }

  /// Handles search query submission
  ///
  /// This method is called when:
  /// - User presses enter in the search field
  /// - User presses the search button
  /// - User changes filter selections
  void _performSearch() {
    /// Update the current query from the text field
    _currentQuery = _searchController.text.trim();

    /// Refresh the pagination controller
    /// This clears all state and triggers a fetch of page 0
    _pagingController.refresh();
  }

  /// Builds a single restaurant card in the grid
  ///
  /// Modern card design with:
  /// - Rounded corners
  /// - Shadow elevation
  /// - Image at top
  /// - Text content below
  /// - Smooth tap animation
  Widget _buildRestaurantCard(Restaurant restaurant) {
    final displayName = restaurant.getDisplayName(widget.isTraditionalChinese);
    final displayDistrict = restaurant.getDisplayDistrict(widget.isTraditionalChinese);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
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
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.restaurant,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            /// Restaurant details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Restaurant name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  /// District with location icon
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displayDistrict,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the filter row with district and keyword dropdowns
  ///
  /// Modern chip-based design with:
  /// - Pill-shaped filter buttons
  /// - Visual feedback on selection
  /// - Clear filter options
  Widget _buildFilterRow() {
    final allDistrictsLabel = widget.isTraditionalChinese ? '所有地區' : 'All Districts';
    final allCategoriesLabel = widget.isTraditionalChinese ? '所有分類' : 'All Categories';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          /// District filter dropdown
          Expanded(
            child: PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  /// Null represents "All Districts" - no filter
                  _selectedDistrictEn = value == 'ALL' ? null : value;
                });
                _performSearch();
              },
              itemBuilder: (context) {
                return [
                  /// "All Districts" option
                  PopupMenuItem(
                    value: 'ALL',
                    child: Text(allDistrictsLabel),
                  ),

                  /// Individual district options
                  ...HongKongDistricts.all.map((district) {
                    return PopupMenuItem(
                      value: district.en,
                      child: Text(district.getLabel(widget.isTraditionalChinese)),
                    );
                  }),
                ];
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedDistrictEn != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDistrictEn != null
                            ? HongKongDistricts.findByEn(_selectedDistrictEn!)
                            ?.getLabel(widget.isTraditionalChinese) ?? allDistrictsLabel
                            : allDistrictsLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: _selectedDistrictEn != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          /// Keyword filter dropdown
          Expanded(
            child: PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  /// Null represents "All Categories" - no filter
                  _selectedKeywordEn = value == 'ALL' ? null : value;
                });
                _performSearch();
              },
              itemBuilder: (context) {
                return [
                  /// "All Categories" option
                  PopupMenuItem(
                    value: 'ALL',
                    child: Text(allCategoriesLabel),
                  ),

                  /// Individual keyword options
                  ...RestaurantKeywords.all.map((keyword) {
                    return PopupMenuItem(
                      value: keyword.en,
                      child: Text(keyword.getLabel(widget.isTraditionalChinese)),
                    );
                  }),
                ];
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedKeywordEn != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedKeywordEn != null
                            ? RestaurantKeywords.findByEn(_selectedKeywordEn!)
                            ?.getLabel(widget.isTraditionalChinese) ?? allCategoriesLabel
                            : allCategoriesLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: _selectedKeywordEn != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchHint = widget.isTraditionalChinese ? '搜尋餐廳...' : 'Search restaurants...';
    final noResultsMessage = widget.isTraditionalChinese ? '找不到餐廳' : 'No restaurants found';
    final tryAdjustingMessage = widget.isTraditionalChinese
        ? '嘗試調整搜尋或篩選條件'
        : 'Try adjusting your search or filters';

    return Column(
      children: [
        /// Search bar with modern styling
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _performSearch();
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) => _performSearch(),
            onChanged: (_) => setState(() {}),
          ),
        ),

        /// Filter row
        _buildFilterRow(),

        const Divider(height: 1),

        /// Results grid with infinite scroll pagination
        ///
        /// In version 5, we use PagingListener to connect the controller
        /// to the PagedGridView. The listener observes the controller's
        /// state and provides it to the grid widget.
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _pagingController.refresh();
            },
            child: PagingListener<int, Restaurant>(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) {
                return PagedGridView<int, Restaurant>(
                  /// The state from the controller
                  state: state,

                  /// Callback to fetch the next page
                  fetchNextPage: fetchNextPage,

                  /// Grid configuration
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),

                  /// Builder configuration for different states
                  builderDelegate: PagedChildBuilderDelegate<Restaurant>(
                    itemBuilder: (context, restaurant, index) {
                      return _buildRestaurantCard(restaurant);
                    },

                    /// Loading indicator shown whilst fetching first page
                    firstPageProgressIndicatorBuilder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),

                    /// Loading indicator shown whilst fetching subsequent pages
                    newPageProgressIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),

                    /// Empty state shown when no results are found
                    noItemsFoundIndicatorBuilder: (_) => Center(
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
                            noResultsMessage,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tryAdjustingMessage,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    /// Error state shown when API call fails
                    firstPageErrorIndicatorBuilder: (_) => Center(
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
                            widget.isTraditionalChinese ? '載入錯誤' : 'Error loading',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _pagingController.refresh(),
                            child: Text(
                              widget.isTraditionalChinese ? '重試' : 'Retry',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }
}