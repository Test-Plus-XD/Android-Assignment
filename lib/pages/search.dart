import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../services/restaurant_service.dart';
import '../models.dart';
import 'restaurant_detail.dart';

/// Widget for searching and displaying restaurants with filtering capabilities
class SearchPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const SearchPage({this.isTraditionalChinese = false, super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

/// Filter option data class
class _FilterOption {
  final String value;
  final String label;
  _FilterOption(this.value, this.label);
}

/// Reusable filter dialog with proper state management
class _FilterDialog extends StatefulWidget {
  final String title;
  final bool isTraditionalChinese;
  final List<_FilterOption> options;
  final Set<String> initialSelection;

  const _FilterDialog({
    required this.title,
    required this.isTraditionalChinese,
    required this.options,
    required this.initialSelection,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.options.map((option) {
            final isSelected = _selected.contains(option.value);
            return CheckboxListTile(
              title: Text(option.label),
              value: isSelected,
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(option.value);
                  } else {
                    _selected.remove(option.value);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() => _selected.clear());
          },
          child: Text(widget.isTraditionalChinese ? '清除' : 'Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(widget.isTraditionalChinese ? '確認' : 'Apply'),
        ),
      ],
    );
  }
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final PagingController<int, Restaurant> _pagingController;
  final Set<String> _selectedDistrictsEn = {};
  final Set<String> _selectedKeywordsEn = {};
  DateTime? _lastSearchTime;
  static const int _resultsPerPage = 12;

  // Added for scroll-to-hide functionality
  late final ScrollController _scrollController;
  late final AnimationController _animationController;
  bool _showSearch = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // PagingController configuration for infinite_scroll_pagination 5.x
    // The getNextPageKey function determines what the next page key should be
    // For zero-indexed pagination (page 0, 1, 2...), we use (state.keys?.last ?? -1) + 1
    // This ensures the first page key will be 0 (null ?? -1) + 1 = 0
    _pagingController = PagingController<int, Restaurant>(
      fetchPage: _fetchPage,
      getNextPageKey: (state) {
        // If the last page is empty, there are no more pages to fetch
        if (state.lastPageIsEmpty) return null;
        // Calculate the next page key by incrementing the last key
        // If no keys exist yet (first load), start from -1 so next key becomes 0
        return (state.keys?.last ?? -1) + 1;
      },
    );
    _searchController.addListener(_onSearchChanged);
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showSearch) {
          setState(() {
            _showSearch = false;
            _animationController.reverse();
          });
        }
      }
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showSearch) {
          setState(() {
            _showSearch = true;
            _animationController.forward();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }


  /// Handles search input changes with debouncing
  void _onSearchChanged() {
    _lastSearchTime = DateTime.now();
    // Delays refresh by 300ms to avoid excessive API calls whilst typing
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastSearchTime != null &&
          DateTime.now().difference(_lastSearchTime!) >= const Duration(milliseconds: 300)) {
        // This is an initial search, so we call it directly here to reset the state.
        context.read<RestaurantService>().searchRestaurants(
          query: _searchController.text.trim(),
          districtsEn: _selectedDistrictsEn.isEmpty ? null : _selectedDistrictsEn.toList(),
          keywordsEn: _selectedKeywordsEn.isEmpty ? null : _selectedKeywordsEn.toList(),
          isTraditionalChinese: widget.isTraditionalChinese,
          isInitialSearch: true, // Force page to 0 and clear results
          hitsPerPage: _resultsPerPage,
        );
        _pagingController.refresh();
      }
    });
  }


  /// Fetches a page of restaurants from the API and returns the items directly
  Future<List<Restaurant>> _fetchPage(int pageKey) async {
    try {
      final restaurantService = context.read<RestaurantService>();
      //1. Perform the search with current filters and query
      await restaurantService.searchRestaurants(
        query: _searchController.text.trim(),
        districtsEn: _selectedDistrictsEn.isEmpty ? null : _selectedDistrictsEn.toList(),
        keywordsEn: _selectedKeywordsEn.isEmpty ? null : _selectedKeywordsEn.toList(),
        isTraditionalChinese: widget.isTraditionalChinese,
        page: pageKey ?? 0,
        hitsPerPage: _resultsPerPage,
        isInitialSearch: false, // Let PagingController handle the page number
      );
      // 2. The searchResults property on your service holds the latest list
      final hits = restaurantService.searchResults;
      if (kDebugMode) print('Fetched page $pageKey: ${hits.length} items');
      // 3. Return the list of items. The PagingController will automatically detect if this is the last page if hits.length < _resultsPerPage.
      return hits;
    } catch (error) {
      if (kDebugMode) print('Error fetching page $pageKey: $error');
      // Re-throw the error so the PagingController can display an error tile
      rethrow;
    }
  }

  /// Opens a dialogue for selecting district filters
  Future<void> _openDistrictFilter() async {
    final districts = HongKongDistricts.all;
    final selectedCopy = Set<String>.from(_selectedDistrictsEn);

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => _FilterDialog(
        title: widget.isTraditionalChinese ? '選擇地區' : 'Select Districts',
        isTraditionalChinese: widget.isTraditionalChinese,
        options: districts.map((d) => _FilterOption(d.en, d.getLabel(widget.isTraditionalChinese))).toList(),
        initialSelection: selectedCopy,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDistrictsEn.clear();
        _selectedDistrictsEn.addAll(result);
      });
      context.read<RestaurantService>().clearResults(); // Clear previous results and reset the page count
      _pagingController.refresh();
    }
  }

  /// Opens a dialogue for selecting keyword/category filters
  Future<void> _openKeywordFilter() async {
    final keywords = RestaurantKeywords.all;
    final selectedCopy = Set<String>.from(_selectedKeywordsEn);

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => _FilterDialog(
        title: widget.isTraditionalChinese ? '選擇分類' : 'Select Categories',
        isTraditionalChinese: widget.isTraditionalChinese,
        options: keywords.map((k) => _FilterOption(k.en, k.getLabel(widget.isTraditionalChinese))).toList(),
        initialSelection: selectedCopy,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedKeywordsEn.clear();
        _selectedKeywordsEn.addAll(result);
      });
      context.read<RestaurantService>().clearResults(); // Clear previous results and reset the page count
      _pagingController.refresh();
    }
  }

  /// Clears all active filters and search query
  void _clearAllFilters() {
    setState(() {
      _selectedDistrictsEn.clear();
      _selectedKeywordsEn.clear();
      _searchController.clear();
    });
    context.read<RestaurantService>().clearResults(); // Clear previous results and reset the page count
    _pagingController.refresh();
  }

  /// Builds the filter chips UI showing active filters
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // District filter chip
          FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 4),
                Text(_selectedDistrictsEn.isEmpty
                    ? (widget.isTraditionalChinese ? '所有地區' : 'All Districts')
                    : '${_selectedDistrictsEn.length} ${widget.isTraditionalChinese ? "個地區" : "districts"}'),
              ],
            ),
            selected: _selectedDistrictsEn.isNotEmpty,
            onSelected: (_) => _openDistrictFilter(),
          ),
          // Individual district chips for each selected district
          if (_selectedDistrictsEn.isNotEmpty)
            ..._selectedDistrictsEn.map((districtEn) {
              final district = HongKongDistricts.findByEn(districtEn);
              final label = district?.getLabel(widget.isTraditionalChinese) ?? districtEn;
              return Chip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  // Removes the selected district and refreshes results
                  setState(() => _selectedDistrictsEn.remove(districtEn));
                  _pagingController.refresh();
                },
              );
            }),
          // Keyword/category filter chip
          FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.category_outlined, size: 18),
                const SizedBox(width: 4),
                Text(_selectedKeywordsEn.isEmpty
                    ? (widget.isTraditionalChinese ? '所有分類' : 'All Categories')
                    : '${_selectedKeywordsEn.length} ${widget.isTraditionalChinese ? "個分類" : "categories"}'),
              ],
            ),
            selected: _selectedKeywordsEn.isNotEmpty,
            onSelected: (_) => _openKeywordFilter(),
          ),
          // Individual keyword chips for each selected keyword
          if (_selectedKeywordsEn.isNotEmpty)
            ..._selectedKeywordsEn.map((keywordEn) {
              final keyword = RestaurantKeywords.findByEn(keywordEn);
              final label = keyword?.getLabel(widget.isTraditionalChinese) ?? keywordEn;
              return Chip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  // Removes the selected keyword and refreshes results
                  setState(() => _selectedKeywordsEn.remove(keywordEn));
                  _pagingController.refresh();
                },
              );
            }),
          // Clear all filters button (only shown when filters are active)
          if (_selectedDistrictsEn.isNotEmpty ||
              _selectedKeywordsEn.isNotEmpty ||
              _searchController.text.isNotEmpty)
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

  /// Builds a card widget for displaying a single restaurant
  Widget _buildRestaurantCard(Restaurant restaurant) {
    final displayName = restaurant.getDisplayName(widget.isTraditionalChinese);
    final displayDistrict = restaurant.getDisplayDistrict(widget.isTraditionalChinese);
    final keywords = restaurant.getDisplayKeywords(widget.isTraditionalChinese);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailPage(
                restaurant: restaurant,
                isTraditionalChinese: widget.isTraditionalChinese,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: restaurant.imageUrl ?? '',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.restaurant, size: 64),
                ),
              ),
              // Gradient overlay
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Restaurant info overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayDistrict,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (keywords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: keywords.take(3).map((k) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              k,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text(widget.isTraditionalChinese ? '搜尋' : 'Search'), ),
      body: Column(
        children: [
          SizeTransition(
            sizeFactor: _animationController,
            axisAlignment: -1.0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: widget.isTraditionalChinese
                          ? '搜尋名稱或地址'
                          : 'Search name or address',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withAlpha(153)),
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                _buildFilterChips(),
                Container(
                  height: 1,
                  color: Colors.green,
                ),
              ],
            ),
          ),
          Expanded(
            child: PagingListener<int, Restaurant>(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) {
                return PagedListView<int, Restaurant>(
                  scrollController: _scrollController,
                  state: state,
                  fetchNextPage: fetchNextPage,
                  builderDelegate: PagedChildBuilderDelegate<Restaurant>(
                    itemBuilder: (context, restaurant, index) =>
                        _buildRestaurantCard(restaurant),
                    firstPageProgressIndicatorBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                    newPageProgressIndicatorBuilder: (_) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator())),
                    noItemsFoundIndicatorBuilder: (_) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                  widget.isTraditionalChinese
                                      ? '沒有找到餐廳'
                                      : 'No restaurants found',
                                  style:
                                  Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(
                                  widget.isTraditionalChinese
                                      ? '嘗試調整您的搜尋或篩選條件'
                                      : 'Try adjusting your search or filters',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                              if (_selectedDistrictsEn.isNotEmpty ||
                                  _selectedKeywordsEn.isNotEmpty ||
                                  _searchController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: OutlinedButton(
                                    onPressed: _clearAllFilters,
                                    child: Text(widget.isTraditionalChinese
                                        ? '清除篩選'
                                        : 'Clear Filters'),
                                  ),
                                ),
                            ]),
                      ),
                    ),
                    firstPageErrorIndicatorBuilder: (_) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text(
                                  widget.isTraditionalChinese
                                      ? '載入失敗'
                                      : 'Failed to load',
                                  style:
                                  Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(
                                  widget.isTraditionalChinese
                                      ? '請檢查您的網路連接'
                                      : 'Please check your internet connection',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                  onPressed: () => _pagingController.refresh(),
                                  child: Text(widget.isTraditionalChinese
                                      ? '重試'
                                      : 'Retry')),
                            ]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}