import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/restaurant_service.dart';
import '../models.dart';
import '../constants/districts.dart';
import '../constants/keywords.dart';
import 'restaurant_detail_page.dart';

/// Search Page with Infinite Scroll Pagination (Version 5)
//
/// Version 5 architecture:
/// - PagingState is managed manually in the widget's state
/// - fetchPage returns a Future<List<ItemType>> containing the page items
/// - State updates happen through copyWith method
/// - Pages and keys are tracked separately for proper pagination
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
  /// Scroll controller to coordinate scrolling behavior
  final ScrollController _scrollController = ScrollController();
  /// Text controller for search input field
  final TextEditingController _searchController = TextEditingController();

  /// Pagination controller using version 5 API
  ///
  /// The getNextPageKey now explicitly handles the empty state to ensure page 0 is fetched first, not page 1.
  late final PagingController<int, Restaurant> _pagingController;

  // Search bar visibility state
  bool _isSearchBarVisible = true;
  double _lastScrollOffset = 0.0;

  /// Selected filters - now using Sets for multi-selection
  /// Using Set<String> allows for efficient add/remove/contains operations
  final Set<String> _selectedDistrictsEn = {};
  final Set<String> _selectedKeywordsEn = {};

  /// Current search query
  String _currentQuery = '';
  /// Number of results to fetch per page
  static const int _pageSize = 12;
  /// Card height for restaurant cards (used for consistent sizing)
  static const double _cardHeight = 220.0;

  @override
  void initState() {
    super.initState();

    /// Initialise the paging controller with corrected page key logic
    //
    /// The getNextPageKey callback now properly handles
    /// the initial state where keys is empty. Previously, nextIntPageKey
    /// might have returned 1 instead of 0 on first fetch after refresh.
    _pagingController = PagingController<int, Restaurant>(
      getNextPageKey: (state) {
        // CRITICAL: When keys is empty (fresh state after refresh),
        // Must return 0 to fetch the first page
        if (state.keys?.isEmpty ?? true) return 0;
        // If the last page had no items, there are no more pages
        if (state.lastPageIsEmpty) return null;
        // Otherwise, return the next sequential page number
        // nextIntPageKey calculates this as: lastKey + 1
        return state.nextIntPageKey;
      },
      fetchPage: (pageKey) => _fetchPage(pageKey),
    );
    // Scroll listener for hiding/showing search bar
    _scrollController.addListener(_onScroll);
  }

  // Handles scroll events to show/hide search bar
  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final difference = currentOffset - _lastScrollOffset;

    // Only update if scrolled more than 5 pixels to avoid jitter
    if (difference.abs() > 5) {
      final shouldHide = difference > 0 && currentOffset > 50;
      final shouldShow = difference < 0 || currentOffset <= 50;

      if (shouldHide && _isSearchBarVisible) {
        setState(() => _isSearchBarVisible = false);
      } else if (shouldShow && !_isSearchBarVisible) {
        setState(() => _isSearchBarVisible = true);
      }

      _lastScrollOffset = currentOffset;
    }
  }

  /// Fetches a page of restaurants from the API
  //
  /// This method converts the selected filter Sets to Lists for the API call,
  /// then returns the list of restaurants for the requested page.
  Future<List<Restaurant>> _fetchPage(int pageKey) async {
    try {
      final restaurantService = context.read<RestaurantService>();

      // Convert selected filter Sets to Lists for API
      // Empty set means no filter applied
      final districtsEn = _selectedDistrictsEn.isNotEmpty
          ? _selectedDistrictsEn.toList()
          : null;
      final keywordsEn = _selectedKeywordsEn.isNotEmpty
          ? _selectedKeywordsEn.toList()
          : null;

      // Determine if this is the initial search (page 0)
      final isInitialSearch = pageKey == 0;

      // Call the service to fetch results
      final hitsPage = await restaurantService.searchRestaurants(
        query: _currentQuery,
        districtsEn: districtsEn,
        keywordsEn: keywordsEn,
        isTraditionalChinese: widget.isTraditionalChinese,
        page: pageKey,
        hitsPerPage: _pageSize,
        isInitialSearch: isInitialSearch,
      );

      // Return the items for this page
      return hitsPage.items;
    } catch (error) {
      // Rethrow to let the controller handle the error state
      rethrow;
    }
  }

  /// Performs a new search, resetting pagination
  ///
  /// Called when:
  /// - User submits search query
  /// - User modifies filter selections
  void _performSearch() {
    _currentQuery = _searchController.text.trim();
    // Refresh clears all state and triggers fetchPage with the first key
    // which will be 0 thanks to our corrected getNextPageKey logic
    _pagingController.refresh();
  }

  /// Shows the district selection dialog with checkboxes
  ///
  /// This creates a modal bottom sheet with all available districts.
  /// Users can select multiple districts, and the selection persists
  /// until explicitly changed.
  void _showDistrictFilterDialog() {
    // Create a temporary copy to track changes during dialog
    final tempSelected = Set<String>.from(_selectedDistrictsEn);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle indicator
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with title and action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isTraditionalChinese ? '選擇地區' : 'Select Districts',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            // Clear all button
                            TextButton(
                              onPressed: () {
                                setModalState(() => tempSelected.clear());
                              },
                              child: Text(
                                widget.isTraditionalChinese ? '清除' : 'Clear',
                              ),
                            ),
                            // Apply button
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDistrictsEn.clear();
                                  _selectedDistrictsEn.addAll(tempSelected);
                                });
                                Navigator.pop(context);
                                _performSearch();
                              },
                              child: Text(
                                widget.isTraditionalChinese ? '套用' : 'Apply',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Scrollable list of districts with checkboxes
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: HKDistricts.all.length,
                      itemBuilder: (context, index) {
                        final district = HKDistricts.all[index];
                        final isSelected = tempSelected.contains(district.en);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                tempSelected.add(district.en);
                              } else {
                                tempSelected.remove(district.en);
                              }
                            });
                          },
                          title: Text(
                            district.getLabel(widget.isTraditionalChinese),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Shows the keyword/category selection dialog with checkboxes
  ///
  /// Similar to district dialog but for restaurant categories/keywords.
  void _showKeywordFilterDialog() {
    final tempSelected = Set<String>.from(_selectedKeywordsEn);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isTraditionalChinese ? '選擇分類' : 'Select Categories',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() => tempSelected.clear());
                              },
                              child: Text(
                                widget.isTraditionalChinese ? '清除' : 'Clear',
                              ),
                            ),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedKeywordsEn.clear();
                                  _selectedKeywordsEn.addAll(tempSelected);
                                });
                                Navigator.pop(context);
                                _performSearch();
                              },
                              child: Text(
                                widget.isTraditionalChinese ? '套用' : 'Apply',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Keyword list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: RestaurantKeywords.all.length,
                      itemBuilder: (context, index) {
                        final keyword = RestaurantKeywords.all[index];
                        final isSelected = tempSelected.contains(keyword.en);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                tempSelected.add(keyword.en);
                              } else {
                                tempSelected.remove(keyword.en);
                              }
                            });
                          },
                          title: Text(
                            keyword.getLabel(widget.isTraditionalChinese),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds a single restaurant card with background image and overlay
  ///
  /// Design approach:
  /// - Full-width card with fixed height for consistent scrolling
  /// - Restaurant image fills the entire card as background
  /// - Gradient overlay from bottom ensures text readability
  /// - Restaurant info positioned at bottom with white text
  /// - Rounded corners and subtle shadow for depth
  Widget _buildRestaurantCard(Restaurant restaurant) {
    final displayName = restaurant.getDisplayName(widget.isTraditionalChinese);
    final displayDistrict = restaurant.getDisplayDistrict(widget.isTraditionalChinese);
    final displayAddress = restaurant.getDisplayAddress(widget.isTraditionalChinese);
    final displayKeywords = restaurant.getDisplayKeywords(widget.isTraditionalChinese);

    return Container(
      height: _cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image - fills the entire card
              CachedNetworkImage(
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
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),

              // Gradient overlay for text readability
              // Gradient goes from transparent at top to dark at bottom
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),

              // Content overlay positioned at bottom
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Restaurant name - large and prominent
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Keywords as small chips
                    if (displayKeywords.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: displayKeywords.take(3).map((keyword) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              keyword,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 8),

                    // District with location icon
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayDistrict,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Address
                    Text(
                      displayAddress,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Top-right decorative element (optional: could show rating/favourite)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the filter section with buttons and selected filter chips
  ///
  /// Design:
  /// - Two filter buttons that open multi-select dialogs
  /// - Selected filters shown as removable chips below
  /// - Chips have smooth animations when added/removed
  Widget _buildFilterSection() {
    final hasFilters = _selectedDistrictsEn.isNotEmpty ||
        _selectedKeywordsEn.isNotEmpty;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // District filter button
                Expanded(
                  child: _FilterButton(
                    label: widget.isTraditionalChinese ? '地區' : 'Districts',
                    count: _selectedDistrictsEn.length,
                    onTap: _showDistrictFilterDialog,
                    isTraditionalChinese: widget.isTraditionalChinese,
                  ),
                ),

                const SizedBox(width: 12),

                // Category filter button
                Expanded(
                  child: _FilterButton(
                    label: widget.isTraditionalChinese ? '分類' : 'Categories',
                    count: _selectedKeywordsEn.length,
                    onTap: _showKeywordFilterDialog,
                    isTraditionalChinese: widget.isTraditionalChinese,
                  ),
                ),
              ],
            ),
          ),

          // Selected filters displayed as chips
          if (hasFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Row(
                children: [
                  // District chips
                  ..._selectedDistrictsEn.map((districtEn) {
                    final district = HKDistricts.findByEn(districtEn);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          district?.getLabel(widget.isTraditionalChinese) ??
                              districtEn,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedDistrictsEn.remove(districtEn);
                          });
                          _performSearch();
                        },
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                        deleteIconColor: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),

                  // Keyword chips
                  ..._selectedKeywordsEn.map((keywordEn) {
                    final keyword = RestaurantKeywords.findByEn(keywordEn);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          keyword?.getLabel(widget.isTraditionalChinese) ??
                              keywordEn,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedKeywordsEn.remove(keywordEn);
                          });
                          _performSearch();
                        },
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        deleteIconColor: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),

                  // Clear all button (when multiple filters selected)
                  if (_selectedDistrictsEn.length + _selectedKeywordsEn.length > 1)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDistrictsEn.clear();
                          _selectedKeywordsEn.clear();
                        });
                        _performSearch();
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: Text(
                        widget.isTraditionalChinese ? '清除全部' : 'Clear All',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchHint = widget.isTraditionalChinese
        ? '搜尋餐廳...'
        : 'Search restaurants...';
    final noResultsMessage = widget.isTraditionalChinese
        ? '找不到餐廳'
        : 'No restaurants found';
    final tryAdjustingMessage = widget.isTraditionalChinese
        ? '嘗試調整搜尋或篩選條件'
        : 'Try adjusting your search or filters';

    return Column(
      children: [
        // Animated container wrapping both search bar and filters
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isSearchBarVisible ? null : 0,
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isSearchBarVisible ? 1.0 : 0.0,
            child: Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade900
                          : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                // Filter section
                _buildFilterSection(),
              ],
            ),
          ),
        ),
        const Divider(height: 0.4),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _pagingController.refresh();
            },
            color: Theme.of(context).colorScheme.primary,
            child: PagingListener<int, Restaurant>(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) {
                return PagedListView<int, Restaurant>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  scrollController: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  builderDelegate: PagedChildBuilderDelegate<Restaurant>(
                    itemBuilder: (context, restaurant, index) {
                      return _buildRestaurantCard(restaurant);
                    },

                    // Replace CircularProgressIndicator with Eclipse.gif
                    firstPageProgressIndicatorBuilder: (_) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Image.asset(
                          'assets/images/Eclipse.gif',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),

                    newPageProgressIndicatorBuilder: (_) => Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/Eclipse.gif',
                        width: 60,
                        height: 60,
                      ),
                    ),

                    // Empty state
                    noItemsFoundIndicatorBuilder: (_) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              noResultsMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tryAdjustingMessage,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedDistrictsEn.clear();
                                  _selectedKeywordsEn.clear();
                                });
                                _performSearch();
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                widget.isTraditionalChinese
                                    ? '重設篩選'
                                    : 'Reset Filters',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Error state for first page
                    firstPageErrorIndicatorBuilder: (_) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red.shade300,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              widget.isTraditionalChinese
                                  ? '載入錯誤'
                                  : 'Error Loading',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isTraditionalChinese
                                  ? '請檢查網絡連接'
                                  : 'Please check your connection',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _pagingController.refresh(),
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                widget.isTraditionalChinese ? '重試' : 'Retry',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Error state for subsequent pages
                    newPageErrorIndicatorBuilder: (_) => Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(
                            widget.isTraditionalChinese
                                ? '載入更多時出錯'
                                : 'Error loading more',
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _pagingController.refresh(),
                            child: Text(
                              widget.isTraditionalChinese ? '重試' : 'Retry',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // No more items indicator
                    noMoreItemsIndicatorBuilder: (_) => Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text(
                        widget.isTraditionalChinese
                            ? '— 已顯示全部結果 —'
                            : '— End of Results —',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pagingController.dispose();
    super.dispose();
  }
}

/// Custom filter button widget
///
/// Displays a tappable button that shows:
/// - Filter label (Districts/Categories)
/// - Badge with count of selected items (if any)
/// - Visual feedback when filters are active
class _FilterButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  final bool isTraditionalChinese;

  const _FilterButton({
    required this.label,
    required this.count,
    required this.onTap,
    required this.isTraditionalChinese,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = count > 0;
    final theme = Theme.of(context);

    return Material(
      color: hasSelection
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasSelection
                  ? theme.colorScheme.primary
                  : Colors.grey.shade400,
              width: hasSelection ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list,
                size: 18,
                color: hasSelection
                    ? theme.colorScheme.primary
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: hasSelection ? FontWeight.bold : FontWeight.normal,
                  color: hasSelection
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
              if (hasSelection) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: hasSelection
                    ? theme.colorScheme.primary
                    : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}