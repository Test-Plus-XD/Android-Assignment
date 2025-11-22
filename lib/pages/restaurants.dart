import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/restaurant_service.dart';
import 'restaurant_detail.dart';

/// Restaurants Search Page - Algolia Implementation
///
/// This page now matches your working Ionic search.page.ts architecture:
/// - Uses Algolia search instead of local filtering
/// - Supports district and keyword filters
/// - Real-time search with debouncing
/// - Pagination support
class RestaurantsPage extends StatefulWidget {
  final bool isTraditionalChinese;
  const RestaurantsPage({this.isTraditionalChinese = false, super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  // Search query text controller
  final TextEditingController searchController = TextEditingController();
  // Selected filters (using EN tokens as canonical values, like Ionic)
  final List<String> selectedDistrictTokens = [];
  final List<String> selectedKeywordTokens = [];

  // Available filter options (loaded from Algolia)
  List<DistrictOption> availableDistricts = [];
  List<KeywordOption> availableKeywords = [];

  // Pagination state
  int currentPage = 0;
  final int resultsPerPage = 12;

  // Debounce timer for search input
  DateTime? lastSearchTime;

  // Cached restaurants loaded from the service.
  //late Future<List<Restaurant>> restaurantsFuture;

  // UI filter state.
  String selectedDistrict = 'All Districts';
  bool filterVeggie = false; // Veggie (齋)
  bool filterVegan = false; // Vegan (純素)

  // Hardcoded district list for fastest client-side operation.
  // First entry 'All' represents no district filter.
  final List<Map<String, String>> districtList = [
    {'en': 'All Districts', 'tc': '所有地區'}, // The one and only "All"
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

  @override
  void initState() {
    super.initState();
    // Load initial results after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Perform Algolia Search
  Future<void> _performSearch() async {
    final restaurantService = context.read<RestaurantService>();

    // Build Algolia filter string (like Ionic does)
    final filters = _buildAlgoliaFilter(selectedDistrictTokens, []);

    // Call Algolia search (like Ionic searchRestaurantsWithFilters)
    await restaurantService.searchRestaurants(
      query: searchController.text.trim(),
      districtEn: filters,
      isTraditionalChinese: widget.isTraditionalChinese,
      page: currentPage,
      hitsPerPage: resultsPerPage,
    );
  }

  /// Build Algolia Filter String
  // Converts selected districts into Algolia filter syntax
  // Example: District_EN:"Kowloon" OR District_EN:"Wan Chai"
  String? _buildAlgoliaFilter(List<String> districts, List<String> keywords) {
    final parts = <String>[];

    // Add district filters
    if (districts.isNotEmpty) {
      final districtClauses = districts
          .map((d) => 'District_EN:"${_escapeFilterValue(d)}"')
          .join(' OR ');
      if (districtClauses.isNotEmpty) {
        parts.add(districtClauses);
      }
    }

    // Add keyword filters (for future implementation)
    if (keywords.isNotEmpty) {
      final keywordClauses = keywords
          .map((k) => 'Keyword_EN:"${_escapeFilterValue(k)}"')
          .join(' OR ');
      if (keywordClauses.isNotEmpty) {
        parts.add('(${keywordClauses})');
      }
    }

    if (parts.isEmpty) return null;
    return parts.join(' AND ');
  }

  // Escape filter values for Algolia
  String _escapeFilterValue(String value) {
    return value.replaceAll('"', '\\"');
  }

  // Handle search input with debounce
  void _onSearchChanged() {
    lastSearchTime = DateTime.now();

    // Debounce by 300ms (like Ionic)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (lastSearchTime != null &&
          DateTime.now().difference(lastSearchTime!) >= const Duration(milliseconds: 300)) {
        currentPage = 0;
        _performSearch();
      }
    });
  }

  // Open district filter dialog
  Future<void> _openDistrictFilter() async {
    final currentLang = widget.isTraditionalChinese ? 'TC' : 'EN';

    // Build checkbox options
    final selectedDistrict = selectedDistrictTokens.isNotEmpty
        ? selectedDistrictTokens[0]
        : 'All Districts';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentLang == 'TC' ? '選擇地區' : 'Select District'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: districtList.map((district) {
              final districtEn = district['en']!;
              final districtTc = district['tc']!;
              final label = currentLang == 'TC' ? districtTc : districtEn;
              final isSelected = districtEn == selectedDistrict;

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
    ).then((value) {
      if (value != null) {
        setState(() {
          if (value == 'All Districts') {
            selectedDistrictTokens.clear();
          } else {
            selectedDistrictTokens.clear();
            selectedDistrictTokens.add(value);
          }
          currentPage = 0;
        });
        _performSearch();
      }
    });
  }

  // Clear district filter
  void _clearDistrict() {
    setState(() {
      selectedDistrictTokens.clear();
      currentPage = 0;
    });
    _performSearch();
  }

  // Clear keyword filter
  void _clearKeyword() {
    setState(() {
      selectedKeywordTokens.clear();
      currentPage = 0;
    });
    _performSearch();
  }

  // Clear all filters
  void _clearAllFilters() {
    setState(() {
      selectedDistrictTokens.clear();
      selectedKeywordTokens.clear();
      searchController.clear();
      currentPage = 0;
    });
    _performSearch();
  }

  // Get display label for selected district
  String get selectedDistrictLabel {
    if (selectedDistrictTokens.isEmpty) {
      return widget.isTraditionalChinese ? '所有地區' : 'All Districts';
    }

    final token = selectedDistrictTokens[0];
    final district = districtList.firstWhere(
          (d) => d['en'] == token,
      orElse: () => {'en': token, 'tc': token},
    );

    return widget.isTraditionalChinese ? district['tc']! : district['en']!;
  }

  /// Build filter chips
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
                Text(selectedDistrictLabel),
                if (selectedDistrictTokens.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _clearDistrict,
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ],
            ),
            selected: selectedDistrictTokens.isNotEmpty,
            onSelected: (_) => _openDistrictFilter(),
          ),

          // Clear all button (if any filters active)
          if (selectedDistrictTokens.isNotEmpty || searchController.text.isNotEmpty)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<RestaurantService>(
            builder: (context, restaurantService, _) {
              final restaurants = restaurantService.searchResults;
              final isLoading = restaurantService.isLoading;
              final totalResults = restaurantService.totalHits;
              final totalPages = restaurantService.totalPages;

            // Use CustomScrollView for advanced scrolling effects
            return CustomScrollView(
              slivers: [
                // The AppBar that will hide and show on scroll
                SliverAppBar(
                  title: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: widget.isTraditionalChinese ? '搜尋名稱或地址' : 'Search name or address',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                  ),
                  pinned: false,  // The app bar will not stay at the top
                  floating: true, // It will become visible as soon as you scroll up
                  snap: true,     // It will snap into place (fully visible or fully hidden)
                ),

                // Loading indicator
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // Empty state
                if (!isLoading && restaurants.isEmpty)
                  SliverFillRemaining(
                    child: Center(
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
                          if (selectedDistrictTokens.isNotEmpty || searchController.text.isNotEmpty)
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

                // Restaurant cards
                if (!isLoading && restaurants.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final restaurant = restaurants[index];
                        final displayName = restaurant.getDisplayName(widget.isTraditionalChinese);
                        final displayAddress = restaurant.getDisplayAddress(widget.isTraditionalChinese);
                        final displayDistrict = restaurant.getDisplayDistrict(widget.isTraditionalChinese);
                        final keywords = restaurant.getDisplayKeywords(widget.isTraditionalChinese);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Card(
                            clipBehavior: Clip.hardEdge,
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
                                  // Restaurant image
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

                                  // Restaurant info
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Name
                                        Text(
                                          displayName,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),

                                        // District
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

                                        // Keywords
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

                                        // View details
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              widget.isTraditionalChinese
                                                  ? '查看詳情'
                                                  : 'View Details',
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
                      },
                      childCount: restaurants.length,
                    ),
                  ),

                // Pagination (if multiple pages)
                if (!isLoading && totalPages > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: currentPage > 0
                                ? () {
                              setState(() => currentPage--);
                              _performSearch();
                            }
                                : null,
                          ),
                          Text(
                            '${currentPage + 1} / $totalPages',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: currentPage < totalPages - 1
                                ? () {
                              setState(() => currentPage++);
                              _performSearch();
                            }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom spacer
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            );
            },
        ),
    );
  }
}

// District option model
class DistrictOption {
  final String districtEn;
  final String districtTc;

  DistrictOption({
    required this.districtEn,
    required this.districtTc,
  });
}

// Keyword option model
class KeywordOption {
  final String valueEn;
  final String labelEn;
  final String labelTc;

  KeywordOption({
    required this.valueEn,
    required this.labelEn,
    required this.labelTc,
  });
}