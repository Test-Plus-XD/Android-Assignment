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
  // Text controller for name search.
  final TextEditingController searchController = TextEditingController();

  // Cached restaurants loaded from the large JSON file.
  late Future<List<Restaurant>> restaurantsFuture;

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
    final String jsonString = await rootBundle.loadString('assets/vegetarian_restaurants_hk.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    final List<dynamic> restaurantList = jsonMap['restaurants'] as List<dynamic>;
    return restaurantList.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Apply client-side filters to the loaded list.
  List<Restaurant> applyFilters(List<Restaurant> sourceList) {
    final String query = searchController.text.trim().toLowerCase();

    bool dietMatches(Restaurant restaurant) {
      if (!filterVeggie && !filterVegan) return true;
      final List<String> keywordLower = [
        ...restaurant.keywordEn.map((k) => k.toLowerCase()),
        ...restaurant.keywordTc.map((k) => k.toLowerCase())
      ];
      final bool hasVeggie = keywordLower.any((k) => k.contains('veggie') || k.contains('齋'));
      final bool hasVegan = keywordLower.any((k) => k.contains('vegan') || k.contains('純素'));
      if (filterVeggie && filterVegan) return hasVeggie || hasVegan;
      if (filterVeggie) return hasVeggie;
      return hasVegan;
    }

    return sourceList.where((restaurant) {
      if (selectedDistrict != 'All Districts') {
        if (restaurant.districtEn != selectedDistrict) {
          return false;
        }
      }

      if (!dietMatches(restaurant)) return false;

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
      underline: Container(), // Hide default underline to avoid double borders
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
    return Row(
      children: [
        SizedBox(
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: filterVeggie ? 4 : 0,
              backgroundColor: filterVeggie ? Colors.green.shade300 : null,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => setState(() => filterVeggie = !filterVeggie),
            child: Text(widget.isTraditionalChinese ? '齋' : 'Veggie'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: filterVegan ? 4 : 0,
              backgroundColor: filterVegan ? Colors.green.shade300 : null,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => setState(() => filterVegan = !filterVegan),
            child: Text(widget.isTraditionalChinese ? '純素' : 'Vegan'),
          ),
        ),
      ],
    );
  }

  // Combined filter row as a single widget.
  PreferredSizeWidget buildFilterRow() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56.0),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.green.shade300, width: 1.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(child: buildDistrictDropdown()),
                const SizedBox(width: 12),
                buildDietFilters(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Restaurant>>(
        future: restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Restaurant> allRestaurants = snapshot.data!;
            final List<Restaurant> filtered = applyFilters(allRestaurants);

            // **REFACTORED: Use CustomScrollView for advanced scrolling effects**
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
                  // Place the filter row in the AppBar's bottom property
                  bottom: buildFilterRow(),
                ),

                // Info row showing number of results, now as a Sliver
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Visibility(
                      visible: filtered.isNotEmpty,
                      child: Text(
                        widget.isTraditionalChinese
                            ? '顯示 ${filtered.length} 個餐廳 (共 ${allRestaurants.length})'
                            : 'Showing ${filtered.length} restaurants (total ${allRestaurants.length})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),

                // The list of restaurants, now as a SliverList
                filtered.isEmpty
                    ? SliverFillRemaining(
                  child: Center(child: Text(widget.isTraditionalChinese ? '沒有找到餐廳' : 'No restaurants found')),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final restaurant = filtered[index];
                      final String displayName = widget.isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;
                      final String displayAddress = widget.isTraditionalChinese ? restaurant.addressTc : restaurant.addressEn;
                      final List<String> keywords = widget.isTraditionalChinese ? restaurant.keywordTc : restaurant.keywordEn;
                      final String keywordsText = keywords.join(', ');
                      final Color textColor = Theme.of(context).colorScheme.onSurface; // Primary text color from theme
                      final Color secondaryTextColor = textColor.withOpacity(0.75); // Slightly transparent for secondary text
                      final Color gradientBaseColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;

                      // Define a subtle shadow for the text to improve readability over images.
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Card(
                          // The card now uses the color defined in main.dart's CardTheme
                          margin: EdgeInsets.zero,
                          // The shape and clipBehavior are correctly inherited from the theme
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: widget.isTraditionalChinese),
                                ),
                              );
                            },
                            child: Ink.image(
                              height: 200,
                              image: AssetImage(restaurant.image),
                              fit: BoxFit.cover,
                              child: Container(
                                // Add the new gradient overlay from the bottom up to 30%.
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      gradientBaseColor.withOpacity(0.97), // Opaque at the very bottom
                                      gradientBaseColor.withOpacity(0.79), // Semi-transparent
                                      Colors.transparent, // Fully transparent
                                    ],
                                    stops: const [0.0, 0.3, 0.6], // Gradient ends at 60% height
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 3. Use RichText with theme-based colors.
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: textColor, // Use main text color from theme
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            TextSpan(text: displayName),
                                            TextSpan(
                                              text: ' ⚪ $keywordsText',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: secondaryTextColor, // Use slightly fainter color
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // 4. Use theme-based color for the address.
                                      Text(
                                        displayAddress,
                                        style: TextStyle(
                                          color: secondaryTextColor, // Use secondary text color
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                        },
                    childCount: filtered.length,
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