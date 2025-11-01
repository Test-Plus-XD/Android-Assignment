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
  int nearbyCurrentIndex = 0;
  // Cached data.
  late Future<List<Restaurant>> restaurantsFuture;
  late Future<List<Review>> reviewsFuture;

  @override
  void initState() {
    super.initState();
    restaurantsFuture = loadRestaurantsFromAssets();
    reviewsFuture = loadReviewsFromAssets();
  }

  @override
  Widget build(BuildContext context) {
    final String featuredHeading = widget.isTraditionalChinese ? '精選素食餐廳' : 'Featured Vegan Restaurants';
    final String nearbyHeading = widget.isTraditionalChinese ? '附近素食餐廳' : 'Nearby Vegan Restaurants';
    final String reviewHeading = widget.isTraditionalChinese ? '最新評論' : 'Latest Reviews';
    final String browseLabel = widget.isTraditionalChinese ? '瀏覽所有餐廳' : 'Browse All Restaurants';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            // ADsCarouselSlider
            SizedBox(
              height: 100,
              child: FutureBuilder<List<Restaurant>>(
                future: restaurantsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final restaurants = snapshot.data!;
                    if (restaurants.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return CarouselSlider.builder(
                      itemCount: restaurants.length,
                      itemBuilder: (context, index, realIndex) {
                        final restaurant = restaurants[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: widget.isTraditionalChinese)),
                            );
                          },
                          child: Image.asset(restaurant.image, fit: BoxFit.cover, width: double.infinity),
                        );
                      },
                      options: CarouselOptions(
                        scrollDirection: Axis.vertical,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 5),
                        viewportFraction: 1.0,
                        height: double.infinity,
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(featuredHeading, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
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
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Card(
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
                                        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),child: Image.asset(restaurant.image, fit: BoxFit.cover))),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            options: CarouselOptions(
                              height: double.infinity,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 4),
                              enlargeCenterPage: true,
                              viewportFraction: 0.82,
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
            // Nearby Vegan Restaurants Slider
            Text(nearbyHeading, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
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
                        Expanded(
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.82),
                            itemCount: restaurants.length,
                            onPageChanged: (index) {
                              setState(() {
                                nearbyCurrentIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final restaurant = restaurants[index];
                              final String displayName = widget.isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Card(
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
                                        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),child: Image.asset(restaurant.image, fit: BoxFit.cover))),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Dots indicators for Nearby slider.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(restaurants.length, (index) {
                            final bool active = index == nearbyCurrentIndex;
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
            // Latest Reviews Slider
            Text(reviewHeading, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: FutureBuilder<List<Review>>(
                future: reviewsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final reviews = snapshot.data!;
                    if (reviews.isEmpty) {
                      return Center(child: Text(widget.isTraditionalChinese ? '沒有評論' : 'No reviews'));
                    }
                    return CarouselSlider.builder(
                      options: CarouselOptions(
                        height: 180,
                        enlargeCenterPage: true,
                        viewportFraction: 0.8,
                        autoPlay: true,
                      ),
                      itemCount: reviews.length,
                      itemBuilder: (context, index, realIndex) {
                        final review = reviews[index];
                        final restaurantName = widget.isTraditionalChinese ? review.restaurantNameTc : review.restaurantNameEn;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (review.photoURL != null && review.photoURL!.isNotEmpty)
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: NetworkImage(review.photoURL!),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(review.displayName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(review.review, maxLines: 2, overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // This is a bit of a hack. We need to find the restaurant from the list of restaurants.
                                      // In a real app, you would have a more direct way to get the restaurant details.
                                      restaurantsFuture.then((restaurants) {
                                        final restaurant = restaurants.firstWhere(
                                              (r) => r.nameEn == review.restaurantNameEn,
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: widget.isTraditionalChinese)),
                                        );
                                      });
                                    },
                                    child: Text(restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text(widget.isTraditionalChinese ? '載入評論時出錯' : 'Error loading reviews'));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: Text(browseLabel),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantsPage(isTraditionalChinese: widget.isTraditionalChinese)));
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('PourRice — vegan restaurant finder.'),
          ],
        ),
      ),
    );
  }
}
