import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';
import 'restaurant_detail.dart';

// Restaurants page with client-side search, district filter and Veggie/Vegan toggles.
// District list is hardcoded for fastest client performance.

class RestaurantsPage extends StatefulWidget {
  final bool isTraditionalChinese;
  const RestaurantsPage({this.isTraditionalChinese = false, super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  // Text controller for name search (kept in AppBar elsewhere).
  final TextEditingController searchController = TextEditingController();

  // Scroll controller to detect scroll direction for hiding the filter row.
  final ScrollController listScrollController = ScrollController();

  // Cached restaurants loaded from the large JSON file.
  late Future<List<Restaurant>> restaurantsFuture;

  // UI filter state.
  String selectedDistrict = 'All';
  bool filterVeggie = false; // Veggie (齋)
  bool filterVegan = false; // Vegan (純素)

  // Show/hide state for the filter row.
  bool showFilterRow = true;
  double lastScrollOffset = 0.0;
  final double scrollThreshold = 6.0; // Small deadzone to avoid jitter.

  // Hardcoded district list for fastest client-side operation.
  // First entry 'All' represents no district filter.
  final List<Map<String, String>> districtList = [
    {'en': 'All districts', 'tc': '全部地區'},
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
    {'en': 'Yau Tsim Mong', 'tc': '油尖旺區'},
    {'en': 'Central/Western', 'tc': '中西區'},
    {'en': 'Eastern', 'tc': '東區'},
    {'en': 'Southern', 'tc': '南區'},
    {'en': 'Wan Chai', 'tc': '灣仔'},
  ];

  @override
  void initState() {
    super.initState();
    // Load the large data file containing all restaurants.
    restaurantsFuture = loadAllRestaurants();

    // Attach scroll listener to show/hide filter row on scroll direction.
    listScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    listScrollController.removeListener(_onScroll);
    listScrollController.dispose();
    super.dispose();
  }

  // Load restaurants from the larger JSON file in assets.
  Future<List<Restaurant>> loadAllRestaurants() async {
    // Load JSON from assets. File should be declared in pubspec.yaml:
    // assets/vegetarian_restaurants_hk.json
    final String jsonString = await rootBundle.loadString('assets/vegetarian_restaurants_hk.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    final List<dynamic> restaurantList = jsonMap['restaurants'] as List<dynamic>;
    return restaurantList.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Scroll listener to detect up/down scrolling.
  void _onScroll() {
    final double offset = listScrollController.offset;
    final double delta = offset - lastScrollOffset;

    // If user scrolled down (positive delta) beyond threshold, hide filters.
    if (delta > scrollThreshold && showFilterRow) {
      setState(() {
        showFilterRow = false;
      });
    } else if (delta < -scrollThreshold && !showFilterRow) {
      // If user scrolled up (negative delta) beyond threshold, show filters.
      setState(() {
        showFilterRow = true;
      });
    }

    // Update last offset (clamped to avoid overflow).
    lastScrollOffset = offset;
  }

  // Apply client-side filters to the loaded list.
  List<Restaurant> applyFilters(List<Restaurant> sourceList) {
    final String query = searchController.text.trim().toLowerCase();

    bool Function(Restaurant) dietMatches = (restaurant) {
      // If neither filter selected, allow all diets.
      if (!filterVeggie && !filterVegan) return true;

      final List<String> keywordLower = [
        ...restaurant.keywordEn.map((k) => k.toLowerCase()),
        ...restaurant.keywordTc.map((k) => k.toLowerCase())
      ];

      // Check veggie keywords (looking for 'veggie' or '齋').
      final bool hasVeggie = keywordLower.any((k) => k.contains('veggie') || k.contains('齋'));

      // Check vegan keywords (looking for 'vegan' or '純素').
      final bool hasVegan = keywordLower.any((k) => k.contains('vegan') || k.contains('純素'));

      // If both toggles on, accept if either matches.
      if (filterVeggie && filterVegan) return hasVeggie || hasVegan;
      if (filterVeggie) return hasVeggie;
      return hasVegan;
    };

    return sourceList.where((restaurant) {
      // District filter.
      if (selectedDistrict != 'All') {
        if (restaurant.districtEn != selectedDistrict && restaurant.districtTc != selectedDistrict) {
          return false;
        }
      }

      // Diet filter.
      if (!dietMatches(restaurant)) return false;

      // Text search: match against English and Traditional Chinese names and addresses.
      if (query.isNotEmpty) {
        final String nameEn = restaurant.nameEn.toLowerCase();
        final String nameTc = restaurant.nameTc.toLowerCase();
        final String addressEn = restaurant.addressEn.toLowerCase();
        final String addressTc = restaurant.addressTc.toLowerCase();
        return nameEn.contains(query) || nameTc.contains(query) || addressEn.contains(query) || addressTc.contains(query);
      }

      return true;
    }).toList();
  }

  // Helper to build district dropdown.
  Widget buildDistrictDropdown() {
    final List<DropdownMenuItem<String>> items = districtList
        .map((d) => DropdownMenuItem<String>(
      value: d['en'],
      child: Text(widget.isTraditionalChinese ? (d['tc'] ?? d['en']!) : (d['en'] ?? d['tc']!)),
    ))
        .toList();

    return DropdownButton<String>(
      value: selectedDistrict,
      items: items,
      isExpanded: true,
      onChanged: (val) {
        if (val == null) return;
        setState(() {
          selectedDistrict = val;
        });
      },
    );
  }

  // Helper to build Veggie/Vegan toggle buttons.
  Widget buildDietFilters() {
    // Use compact ElevatedButtons for clearer selected state.
    return Row(
      children: [
        SizedBox(
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: filterVeggie ? 4 : 0,
              backgroundColor: filterVeggie ? Colors.green.shade700 : null,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () {
              setState(() {
                filterVeggie = !filterVeggie;
              });
            },
            child: Text(widget.isTraditionalChinese ? '齋' : 'Veggie'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: filterVegan ? 4 : 0,
              backgroundColor: filterVegan ? Colors.green.shade700 : null,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () {
              setState(() {
                filterVegan = !filterVegan;
              });
            },
            child: Text(widget.isTraditionalChinese ? '純素' : 'Vegan'),
          ),
        ),
      ],
    );
  }

  // Combined filter row as a single widget: dropdown + diet buttons in one row.
  Widget buildFilterRow() {
    return Material(
      // Use Material so elevation and background follow theme naturally.
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // District dropdown takes remaining space.
            Expanded(child: buildDistrictDropdown()),
            const SizedBox(width: 12),
            // Diet buttons.
            buildDietFilters(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Replace the simple title with a search + filters bar controlled elsewhere.
    return Scaffold(
      // Keep search TextField in AppBar to reduce vertical clutter.
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: widget.isTraditionalChinese ? '搜尋名稱或地址' : 'Search name or address',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}), // Rebuild to apply search live.
        ),
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Restaurant> allRestaurants = snapshot.data!;
            final List<Restaurant> filtered = applyFilters(allRestaurants);

            return Column(
              children: [
                // Animated filter row that slides up/down based on scroll direction.
                AnimatedSlide(
                  offset: showFilterRow ? Offset.zero : const Offset(0, -1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: showFilterRow ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: buildFilterRow(),
                  ),
                ),

                // Info row showing number of results.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        widget.isTraditionalChinese
                            ? '顯示 ${filtered.length} 個餐廳 (共 ${allRestaurants.length})'
                            : 'Showing ${filtered.length} restaurants (total ${allRestaurants.length})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Expanded list of results with horizontal padding outside each card.
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(widget.isTraditionalChinese ? '沒有找到餐廳' : 'No restaurants found'))
                      : ListView.builder(
                    controller: listScrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final restaurant = filtered[index];
                      final String displayName = widget.isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;

                      // Each card has horizontal padding so cards don't touch screen edges.
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.hardEdge,
                          child: ListTile(
                            // Reduce the default ListTile padding so thumbnail can touch inner border.
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            // Leading width explicit so layout is stable.
                            minLeadingWidth: 84,
                            horizontalTitleGap: 8,
                            // Leading thumbnail constrained by SizedBox.
                            leading: SizedBox(
                              width: 84,
                              height: 72,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  restaurant.image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            title: Text(displayName),
                            subtitle: Text(widget.isTraditionalChinese ? restaurant.districtTc : restaurant.districtEn),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: widget.isTraditionalChinese),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text(widget.isTraditionalChinese ? '載入錯誤' : 'Error loading restaurants'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}