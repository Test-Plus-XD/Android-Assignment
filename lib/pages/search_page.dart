import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../services/restaurant_service.dart';
import '../models.dart';
import '../constants/districts.dart';
import '../constants/keywords.dart';
import '../widgets/search/restaurant_card.dart';
import '../widgets/search/search_filter_section.dart';

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
    /// Check if widget is still mounted before updating state
    /// The scroll listener continues to fire after navigation
    if (!mounted) return;

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

      // Show toast with search results count on initial search (page 0)
      if (isInitialSearch && mounted) {
        final totalHits = restaurantService.totalHits;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '找到 $totalHits 間餐廳'
                  : 'Found $totalHits restaurant${totalHits != 1 ? 's' : ''}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

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
                                /// Check if widget is still mounted before updating state
                                /// Modal dialogs might outlive the parent widget
                                if (mounted) {
                                  setState(() {
                                    _selectedDistrictsEn.clear();
                                    _selectedDistrictsEn.addAll(tempSelected);
                                  });
                                }
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
                                /// Check if widget is still mounted before updating state
                                /// Modal dialogs might outlive the parent widget
                                if (mounted) {
                                  setState(() {
                                    _selectedKeywordsEn.clear();
                                    _selectedKeywordsEn.addAll(tempSelected);
                                  });
                                }
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
                SearchFilterSection(
                  isTraditionalChinese: widget.isTraditionalChinese,
                  selectedDistrictsEn: _selectedDistrictsEn,
                  selectedKeywordsEn: _selectedKeywordsEn,
                  onDistrictFilterTap: _showDistrictFilterDialog,
                  onKeywordFilterTap: _showKeywordFilterDialog,
                  onDistrictRemoved: (districtEn) {
                    if (mounted) {
                      setState(() => _selectedDistrictsEn.remove(districtEn));
                    }
                    _performSearch();
                  },
                  onKeywordRemoved: (keywordEn) {
                    if (mounted) {
                      setState(() => _selectedKeywordsEn.remove(keywordEn));
                    }
                    _performSearch();
                  },
                  onClearAll: () {
                    if (mounted) {
                      setState(() {
                        _selectedDistrictsEn.clear();
                        _selectedKeywordsEn.clear();
                      });
                    }
                    _performSearch();
                  },
                ),
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
                      return RestaurantCard(
                        restaurant: restaurant,
                        isTraditionalChinese: widget.isTraditionalChinese,
                      );
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