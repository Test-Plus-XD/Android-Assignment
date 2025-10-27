import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'restaurant_detail.dart';
import 'restaurants.dart';

// FrontPage with an auto-playing carousel and visible indicators (dots).
class FrontPage extends StatefulWidget {
  final bool isTraditionalChinese;
  const FrontPage({this.isTraditionalChinese = false, super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  // Controller for the carousel.
  final CarouselController carouselController = CarouselController();
  // Current index for indicators.
  int currentIndex = 0;
  // Cached restaurants.
  late Future<List<Restaurant>> restaurantsFuture;

  @override
  void initState() {
    super.initState();
    restaurantsFuture = loadRestaurantsFromAssets();
  }

  @override
  Widget build(BuildContext context) {
    final String heading = widget.isTraditionalChinese ? '精選素食餐廳' : 'Featured Vegan Restaurants';
    final String browseLabel = widget.isTraditionalChinese ? '瀏覽所有餐廳' : 'Browse All Restaurants';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(heading, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: FutureBuilder<List<Restaurant>>(
              future: restaurantsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final restaurants = snapshot.data!;
                  if (restaurants.isEmpty) {
                    return Center(child: Text(widget.isTraditionalChinese ? '沒有餐廳' : 'No restaurants'));
                  }

                  return Column(
                    children: [
                      // CarouselSlider builder.
                      Expanded(
                        child: CarouselSlider.builder(
                          itemCount: restaurants.length,
                          itemBuilder: (context, index, realIndex) {
                            final restaurant = restaurants[index];
                            final String displayName = widget.isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;
                            return Card(
                              clipBehavior: Clip.hardEdge,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: widget.isTraditionalChinese)),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: Image.asset(restaurant.image, fit: BoxFit.cover)),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: double.infinity,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 4),
                            enlargeCenterPage: true,
                            viewportFraction: 0.92,
                            enableInfiniteScroll: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                currentIndex = index;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dots indicators.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(restaurants.length, (index) {
                          final bool active = index == currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 12 : 8,
                            height: active ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? Theme.of(context).colorScheme.secondary : Colors.grey.shade400,
                            ),
                          );
                        }),
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
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.restaurant_menu),
            label: Text(browseLabel),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantsPage(isTraditionalChinese: widget.isTraditionalChinese)));
            },
          ),
          const SizedBox(height: 12),
          const Text('PourRice — vegan restaurant finder.'),
        ],
      ),
    );
  }
}