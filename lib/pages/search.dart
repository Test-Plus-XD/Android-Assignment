import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../services/restaurant_service.dart';
import '../models.dart';
import 'restaurant_detail.dart';

class RestaurantsPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const RestaurantsPage({this.isTraditionalChinese = false, super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  late final TextEditingController _searchController;
  late final PagingController<int, Restaurant> _pagingController;

  String? _selectedDistrictEn;
  String? _selectedKeywordEn;

  DateTime? _lastSearchTime;
  static const int _resultsPerPage = 12;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _pagingController = PagingController<int, Restaurant>(
      getNextPageKey: (state) {
        if (state.lastPageIsEmpty) {
          return null;
        }
        return state.nextIntPageKey;
      },
      fetchPage: (pageKey) => _fetchPage(pageKey),
    );

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pagingController.refresh();
    });
  }

  void _onSearchChanged() {
    _lastSearchTime = DateTime.now();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastSearchTime != null &&
          DateTime.now().difference(_lastSearchTime!) >=
              const Duration(milliseconds: 300)) {
        _pagingController.refresh();
      }
    });
  }

  Future<List<Restaurant>> _fetchPage(int pageKey) async {
    try {
      final restaurantService = context.read<RestaurantService>();

      await restaurantService.searchRestaurants(
        query: _searchController.text.trim(),
        districtEn: _selectedDistrictEn,
        keywordEn: _selectedKeywordEn,
        isTraditionalChinese: widget.isTraditionalChinese,
        page: pageKey,
        hitsPerPage: _resultsPerPage,
      );

      final hitsPage = await restaurantService.pagesStream.first;

      if (kDebugMode) {
        print('Fetched page ${hitsPage.pageKey}: ${hitsPage.items.length} items');
      }

      return hitsPage.items;
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching page $pageKey: $error');
      }
      rethrow;
    }
  }

  Future<void> _openDistrictFilter() async {
    final districts = HongKongDistricts.withAllOption;
    final selectedEn = _selectedDistrictEn ?? 'All Districts';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '選擇地區' : 'Select District'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: districts.map((district) {
              final label = district.getLabel(widget.isTraditionalChinese);
              return RadioListTile<String>(
                title: Text(label),
                value: district.en,
                groupValue: selectedEn,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel')),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (result == 'All Districts') {
          _selectedDistrictEn = null;
        } else {
          _selectedDistrictEn = result;
        }
      });
      _pagingController.refresh();
    }
  }

  Future<void> _openKeywordFilter() async {
    final keywords = RestaurantKeywords.withAllOption;
    final selectedEn = _selectedKeywordEn ?? 'All Categories';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '選擇分類' : 'Select Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: keywords.map((keyword) {
              final label = keyword.getLabel(widget.isTraditionalChinese);
              return RadioListTile<String>(
                title: Text(label),
                value: keyword.en,
                groupValue: selectedEn,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel')),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (result == 'All Categories') {
          _selectedKeywordEn = null;
        } else {
          _selectedKeywordEn = result;
        }
      });
      _pagingController.refresh();
    }
  }

  void _clearDistrict() {
    setState(() => _selectedDistrictEn = null);
    _pagingController.refresh();
  }

  void _clearKeyword() {
    setState(() => _selectedKeywordEn = null);
    _pagingController.refresh();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDistrictEn = null;
      _selectedKeywordEn = null;
      _searchController.clear();
    });
    _pagingController.refresh();
  }

  String get _selectedDistrictLabel {
    if (_selectedDistrictEn == null) {
      return widget.isTraditionalChinese ? '所有地區' : 'All Districts';
    }
    final district = HongKongDistricts.findByEn(_selectedDistrictEn!);
    return district?.getLabel(widget.isTraditionalChinese) ?? _selectedDistrictEn!;
  }

  String get _selectedKeywordLabel {
    if (_selectedKeywordEn == null) {
      return widget.isTraditionalChinese ? '所有分類' : 'All Categories';
    }
    final keyword = RestaurantKeywords.findByEn(_selectedKeywordEn!);
    return keyword?.getLabel(widget.isTraditionalChinese) ?? _selectedKeywordEn!;
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 4),
              Text(_selectedDistrictLabel),
              if (_selectedDistrictEn != null) ...[
                const SizedBox(width: 4),
                GestureDetector(onTap: _clearDistrict, child: const Icon(Icons.close, size: 16)),
              ],
            ]),
            selected: _selectedDistrictEn != null,
            onSelected: (_) => _openDistrictFilter(),
          ),
          FilterChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.category_outlined, size: 18),
              const SizedBox(width: 4),
              Text(_selectedKeywordLabel),
              if (_selectedKeywordEn != null) ...[
                const SizedBox(width: 4),
                GestureDetector(onTap: _clearKeyword, child: const Icon(Icons.close, size: 16)),
              ],
            ]),
            selected: _selectedKeywordEn != null,
            onSelected: (_) => _openKeywordFilter(),
          ),
          if (_selectedDistrictEn != null ||
              _selectedKeywordEn != null ||
              _searchController.text.isNotEmpty)
            ActionChip(
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.close, size: 18),
                const SizedBox(width: 4),
                Text(widget.isTraditionalChinese ? '清除所有' : 'Clear All'),
              ]),
              onPressed: _clearAllFilters,
            ),
        ],
      ),
    );
  }

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
                Text(displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Expanded(child: Text(displayDistrict, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium)),
                ]),
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
            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)),
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: PagingListener<int, Restaurant>(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) {
                return PagedListView<int, Restaurant>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  builderDelegate: PagedChildBuilderDelegate<Restaurant>(
                    itemBuilder: (context, restaurant, index) => _buildRestaurantCard(restaurant),
                    firstPageProgressIndicatorBuilder: (_) => const Center(child: CircularProgressIndicator()),
                    newPageProgressIndicatorBuilder: (_) => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                    noItemsFoundIndicatorBuilder: (_) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(widget.isTraditionalChinese ? '沒有找到餐廳' : 'No restaurants found', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(widget.isTraditionalChinese ? '嘗試調整您的搜尋或篩選條件' : 'Try adjusting your search or filters', style: Theme.of(context).textTheme.bodyMedium),
                          if (_selectedDistrictEn != null || _selectedKeywordEn != null || _searchController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: OutlinedButton(onPressed: _clearAllFilters, child: Text(widget.isTraditionalChinese ? '清除篩選' : 'Clear Filters')),
                            ),
                        ]),
                      ),
                    ),
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