// File: lib/restaurants.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';
import 'restaurant_detail.dart';

// Restaurants page with client-side search, district filter and Veggie/Vegan toggles.
// Note: District list is hardcoded for fastest client performance.

class RestaurantsPage extends StatefulWidget {
  final bool isTraditionalChinese;
  const RestaurantsPage({this.isTraditionalChinese = false, super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  // Text controller for name search.
  final TextEditingController searchController = TextEditingController();

  // Cached restaurants loaded from the large JSON file.
  late Future<List<Restaurant>> restaurantsFuture;

  // UI filter state.
  String selectedDistrict = 'All';
  bool filterVeggie = false; // Veggie (齋)
  bool filterVegan = false; // Vegan (純素)

  // Hardcoded district list for fastest client-side operation.
  // First entry 'All' represents no district filter.
  final List<Map<String, String>> districtList = [
    {'en': 'All', 'tc': '全部'},
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
  }

  @override
  void dispose() {
    searchController.dispose();
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
    // Use ToggleButtons-like UI but with ElevatedButton for clearer selected state.
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: filterVeggie ? 4 : 0,
              backgroundColor: filterVeggie ? Colors.green.shade700 : null,
            ),
            onPressed: () {
              setState(() {
                filterVeggie = !filterVeggie;
              });
            },
            child: Text(widget.isTraditionalChinese ? '齋 (Veggie)' : 'Veggie'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: filterVegan ? 4 : 0,
              backgroundColor: filterVegan ? Colors.green.shade700 : null,
            ),
            onPressed: () {
              setState(() {
                filterVegan = !filterVegan;
              });
            },
            child: Text(widget.isTraditionalChinese ? '純素 (Vegan)' : 'Vegan'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Replace the simple title with a search + filters bar.
    return Scaffold(
      appBar: AppBar(
        // AppBar shows a compact search field; keep label localised.
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
                // Filters area: district dropdown and diet buttons.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      // District dropdown.
                      buildDistrictDropdown(),
                      const SizedBox(height: 8),
                      // Diet filter buttons.
                      buildDietFilters(),
                    ],
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

                // Expanded list of results.
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(widget.isTraditionalChinese ? '沒有找到餐廳' : 'No restaurants found'))
                      : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final restaurant = filtered[index];
                      final String displayName = widget.isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;
                      return Card(
                        child: ListTile(
                          // Leading must be a sized widget; use SizedBox to constrain the image.
                          leading: SizedBox(
                            width: 84,
                            height: 72,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8), // Rounded corners for thumbnail.
                              child: Image.asset(
                                restaurant.image,
                                fit: BoxFit.cover, // Fill thumbnail while preserving aspect ratio.
                                // Do not set width/height to infinity here; bounding is provided by SizedBox.
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