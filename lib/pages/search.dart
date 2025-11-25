import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
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

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchController;
  late final PagingController<int, Restaurant> _pagingController;
  final Set<String> _selectedDistrictsEn = {};
  final Set<String> _selectedKeywordsEn = {};
  DateTime? _lastSearchTime;
  static const int _resultsPerPage = 12;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Initialises the paging controller with fetchPage and getNextPageKey functions
    _pagingController = PagingController<int, Restaurant>(
      fetchPage: _fetchPage,
      getNextPageKey: (state) {
        // Returns null if the last page is empty (indicating no more pages)
        if (state.lastPageIsEmpty) return null;
        // Otherwise, returns the next page key
        return state.nextIntPageKey;
      },
    );
    _searchController.addListener(_onSearchChanged);
  }

  /// Handles search input changes with debouncing
  void _onSearchChanged() {
    _lastSearchTime = DateTime.now();
    // Delays refresh by 300ms to avoid excessive API calls whilst typing
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastSearchTime != null &&
          DateTime.now().difference(_lastSearchTime!) >= const Duration(milliseconds: 300)) {
        _pagingController.refresh();
      }
    });
  }

  /// Fetches a page of restaurants from the API and returns the items directly
  Future<List<Restaurant>> _fetchPage(int pageKey) async {
    try {
      final restaurantService = context.read<RestaurantService>();
      // Performs the search with current filters and query
      await restaurantService.searchRestaurants(
        query: _searchController.text.trim(),
        districtsEn: _selectedDistrictsEn.isEmpty ? null : _selectedDistrictsEn.toList(),
        keywordsEn: _selectedKeywordsEn.isEmpty ? null : _selectedKeywordsEn.toList(),
        isTraditionalChinese: widget.isTraditionalChinese,
        page: pageKey,
        hitsPerPage: _resultsPerPage,
      );
      // Retrieves the page results from the stream
      final hitsPage = await restaurantService.pagesStream.first;
      if (kDebugMode) print('Fetched page ${hitsPage.pageKey}: ${hitsPage.items.length} items');
      // Returns the list of items directly; the controller handles pagination logic
      return hitsPage.items;
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching page $pageKey: $error');
      }
      // Re-throws error so the controller can handle it
      rethrow;
    }
  }

  /// Opens a dialogue for selecting district filters
  Future<void> _openDistrictFilter() async {
    final districts = HongKongDistricts.withAllOption;
    final selected = Set<String>.from(_selectedDistrictsEn);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '選擇地區' : 'Select District'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: districts.map((district) {
              final label = district.getLabel(widget.isTraditionalChinese);
              final isSelected = selected.contains(district.en);
              return CheckboxListTile(
                title: Text(label),
                value: isSelected,
                onChanged: (bool? checked) {
                  // Updates the selected districts set based on checkbox state
                  setState(() {
                    if (checked == true) {
                      selected.add(district.en);
                    } else {
                      selected.remove(district.en);
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
            onPressed: () { setState(() => selected.clear()); },
            child: Text(widget.isTraditionalChinese ? '清除' : 'Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text(widget.isTraditionalChinese ? '確認' : 'Apply'),
          ),
        ],
      ),
    );
    // Applies the selected districts and refreshes the results
    if (result != null) {
      setState(() {
        _selectedDistrictsEn.clear();
        _selectedDistrictsEn.addAll(result);
      });
      _pagingController.refresh();
    }
  }

  /// Opens a dialogue for selecting keyword/category filters
  Future<void> _openKeywordFilter() async {
    final keywords = RestaurantKeywords.withAllOption;
    final selected = Set<String>.from(_selectedKeywordsEn);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '選擇分類' : 'Select Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: keywords.map((keyword) {
              final label = keyword.getLabel(widget.isTraditionalChinese);
              final isSelected = selected.contains(keyword.en);
              return CheckboxListTile(
                title: Text(label),
                value: isSelected,
                onChanged: (bool? checked) {
                  // Updates the selected keywords set based on checkbox state
                  setState(() {
                    if (checked == true) {
                      selected.add(keyword.en);
                    } else {
                      selected.remove(keyword.en);
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
              setState(() => selected.clear());
            },
            child: Text(widget.isTraditionalChinese ? '清除' : 'Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text(widget.isTraditionalChinese ? '確認' : 'Apply'),
          ),
        ],
      ),
    );
    // Applies the selected keywords and refreshes the results
    if (result != null) {
      setState(() {
        _selectedKeywordsEn.clear();
        _selectedKeywordsEn.addAll(result);
      });
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
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => RestaurantDetailPage(
              restaurant: restaurant,
              isTraditionalChinese: widget.isTraditionalChinese,
            ),
          )),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Restaurant image with error fallback
            if (restaurant.imageUrl != null)
              Image.network(
                restaurant.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 200, color: Colors.grey.shade300, child: const Icon(Icons.restaurant, size: 64)),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Restaurant name
                Text(displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                // District location
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Expanded(child: Text(displayDistrict, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium)),
                ]),
                // Keywords/categories (up to 3)
                if (keywords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: keywords.take(3).map((k) =>
                        Chip(label: Text(k, style: const TextStyle(fontSize: 12)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)
                    ).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                // View details link
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(widget.isTraditionalChinese ? '查看詳情' : 'View Details',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: Theme.of(context).colorScheme.primary),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.isTraditionalChinese ? '搜尋名稱或地址' : 'Search name or address',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(153)),
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            // Uses PagingListener to handle the paging state
            child: PagingListener<int, Restaurant>(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) {
                return PagedListView<int, Restaurant>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  builderDelegate: PagedChildBuilderDelegate<Restaurant>(
                    itemBuilder: (context, restaurant, index) => _buildRestaurantCard(restaurant),
                    // Loading indicator for first page
                    firstPageProgressIndicatorBuilder: (_) => const Center(child: CircularProgressIndicator()),
                    // Loading indicator for subsequent pages
                    newPageProgressIndicatorBuilder: (_) => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                    // Empty state when no results found
                    noItemsFoundIndicatorBuilder: (_) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(widget.isTraditionalChinese ? '沒有找到餐廳' : 'No restaurants found', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(widget.isTraditionalChinese ? '嘗試調整您的搜尋或篩選條件' : 'Try adjusting your search or filters', style: Theme.of(context).textTheme.bodyMedium),
                          if (_selectedDistrictsEn.isNotEmpty ||
                              _selectedKeywordsEn.isNotEmpty ||
                              _searchController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: OutlinedButton(
                                onPressed: _clearAllFilters,
                                child: Text(widget.isTraditionalChinese ? '清除篩選' : 'Clear Filters'),
                              ),
                            ),
                        ]),
                      ),
                    ),
                    // Error state for first page load failure
                    firstPageErrorIndicatorBuilder: (_) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(widget.isTraditionalChinese ? '載入失敗' : 'Failed to load', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(widget.isTraditionalChinese ? '請檢查您的網路連接' : 'Please check your internet connection', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: () => _pagingController.refresh(), child: Text(widget.isTraditionalChinese ? '重試' : 'Retry')),
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