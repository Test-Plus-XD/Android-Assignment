import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/restaurant_service.dart';
import '../services/location_service.dart';
import '../models.dart';
import 'restaurant_detail.dart';

/// Home Page with GPS "Near Me" Integration
/// 
/// This page demonstrates native Android location features by showing
/// restaurants sorted by proximity to the user's current location.
/// 
/// User Journey:
/// 1. User opens app
/// 2. App requests location permission (first time only)
/// 3. GPS acquires position (2-5 seconds typically)
/// 4. Nearby restaurants appear, sorted by distance
/// 5. User can refresh to update their location
/// 
/// Why This Feels Native:
/// - Uses Android's system permission dialog
/// - Shows distance badges (like Google Maps)
/// - Respects user's permission choices
/// - Handles permission denial gracefully
/// - Works offline after initial load
class FrontPage extends StatefulWidget {
  final bool isTraditionalChinese;
  final ValueChanged<int>? onNavigate; // Public callback: ask shell to navigate
  const FrontPage({this.isTraditionalChinese = false, this.onNavigate, super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  // Carousel index for featured restaurants
  int _currentIndex = 0;
  // Loading flag for nearby restaurants
  bool _loadingNearby = false;
  // Nearby restaurants computed from GPS
  List<Restaurant> _nearbyRestaurants = [];

  @override
  void initState() {
    super.initState();
    // Load featured and nearby after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeaturedRestaurants();
      _loadNearbyRestaurants();
    });
  }

  // Load featured restaurants (simple search)
  Future<void> _loadFeaturedRestaurants() async {
    final restaurantService = context.read<RestaurantService>();
    await restaurantService.searchRestaurants(
      query: '',
      isTraditionalChinese: widget.isTraditionalChinese,
      hitsPerPage: 10,
    );
  }

  // Load nearby restaurants via location service, compute distances and sort
  Future<void> _loadNearbyRestaurants() async {
    setState(() => _loadingNearby = true);
    try {
      final locationService = context.read<LocationService>();
      final restaurantService = context.read<RestaurantService>();

      // Check/request permission
      final hasPermission = await locationService.checkAndRequestPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isTraditionalChinese
                  ? '無法取得位置權限。在設定中啟用以查看附近餐廳。'
                  : 'Location permission denied. Enable it in settings to see nearby restaurants.'),
              action: SnackBarAction(
                label: widget.isTraditionalChinese ? '設定' : 'Settings',
                onPressed: () => locationService.openAppSettings(),
              ),
            ),
          );
        }
        setState(() => _loadingNearby = false);
        return;
      }

      // Acquire position
      final position = await locationService.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isTraditionalChinese
                  ? '無法取得您的位置。請確保 GPS 已啟用並稍後重試。'
                  : 'Could not get your location. Ensure GPS is enabled and try again.'),
            ),
          );
        }
        setState(() => _loadingNearby = false);
        return;
      }

      // Fetch restaurants to compute distances
      await restaurantService.searchRestaurants(
        query: '',
        isTraditionalChinese: widget.isTraditionalChinese,
        hitsPerPage: 10,
      );

      // Calculate distances and pick top 10 nearest
      final allRestaurants = restaurantService.searchResults;
      final restaurantsWithDistance = <MapEntry<Restaurant, double>>[];
      for (final restaurant in allRestaurants) {
        if (restaurant.latitude != null && restaurant.longitude != null) {
          final distance = locationService.calculateDistance(
            position.latitude,
            position.longitude,
            restaurant.latitude!,
            restaurant.longitude!,
          );
          restaurantsWithDistance.add(MapEntry(restaurant, distance));
        }
      }
      restaurantsWithDistance.sort((a, b) => a.value.compareTo(b.value));
      setState(() {
        _nearbyRestaurants = restaurantsWithDistance.take(10).map((e) => e.key).toList();
        _loadingNearby = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isTraditionalChinese
                ? '載入附近餐廳時發生錯誤'
                : 'Error loading nearby restaurants'),
          ),
        );
      }
      setState(() => _loadingNearby = false);
    }
  }

  // Build small distance badge for a restaurant
  Widget _buildDistanceBadge(Restaurant restaurant) {
    final locationService = context.read<LocationService>();
    final distance = locationService.calculateDistanceFromCurrent(
      restaurant.latitude!,
      restaurant.longitude!,
    );
    if (distance == null) return const SizedBox.shrink();

    final distanceText = locationService.formatDistance(distance);
    Color badgeColor;
    if (distance < 500) badgeColor = Colors.green; else if (distance < 2000) badgeColor = Colors.orange; else badgeColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.location_on, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(distanceText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featuredHeading = widget.isTraditionalChinese ? '精選素食餐廳' : 'Featured Vegan Restaurants';
    final nearbyHeading = widget.isTraditionalChinese ? '附近素食餐廳' : 'Nearby Vegan Restaurants';
    final browseLabel = widget.isTraditionalChinese ? '瀏覽所有餐廳' : 'Browse All Restaurants';
    final refreshLabel = widget.isTraditionalChinese ? '重新整理位置' : 'Refresh Location';

    return Scaffold(
      body: Consumer<RestaurantService>(builder: (context, restaurantService, _) {
        final restaurants = restaurantService.searchResults;

        // Use RefreshIndicator with a ListView to avoid slivers
        return RefreshIndicator(
          onRefresh: () async {
            await _loadFeaturedRestaurants();
            await _loadNearbyRestaurants();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Nearby header with refresh button
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(nearbyHeading, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.my_location), tooltip: refreshLabel, onPressed: _loadingNearby ? null : _loadNearbyRestaurants),
                ]),
              ),

              // Nearby loading state, empty state, or horizontal list
              if (_loadingNearby)
                const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator()))
              else if (_nearbyRestaurants.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(children: [
                        const Icon(Icons.location_off, size: 48),
                        const SizedBox(height: 8),
                        Text(widget.isTraditionalChinese ? '無法取得附近餐廳。請啟用位置權限。' : 'Unable to get nearby restaurants. Please enable location permission.', textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _loadNearbyRestaurants, child: Text(widget.isTraditionalChinese ? '重試' : 'Retry')),
                      ]),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _nearbyRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = _nearbyRestaurants[index];
                      final displayName = restaurant.getDisplayName(widget.isTraditionalChinese);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: widget.isTraditionalChinese)));
                        },
                        child: Card(
                          margin: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 160,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Stack(children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: CachedNetworkImage(
                                    imageUrl: restaurant.imageUrl ?? '',
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey.shade300, child: const Center(child: CircularProgressIndicator())),
                                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade300, child: const Icon(Icons.restaurant)),
                                  ),
                                ),
                                Positioned(top: 8, right: 8, child: _buildDistanceBadge(restaurant)),
                              ]),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              // Featured header
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(featuredHeading, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),

              // Featured loading or carousel
              if (restaurants.isEmpty)
                const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator()))
              else
                Column(children: [
                  CarouselSlider.builder(
                    itemCount: restaurants.length,
                    itemBuilder: (context, index, realIndex) {
                      final restaurant = restaurants[index];
                      final displayName = restaurant.getDisplayName(widget.isTraditionalChinese);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: widget.isTraditionalChinese)));
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: CachedNetworkImage(
                                  imageUrl: restaurant.imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey.shade300, child: const Center(child: CircularProgressIndicator())),
                                  errorWidget: (context, url, error) => Container(color: Colors.grey.shade300, child: const Icon(Icons.restaurant, size: 48)),
                                ),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(12.0), child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 220,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      enlargeCenterPage: true,
                      viewportFraction: 0.82,
                      onPageChanged: (index, reason) => setState(() => _currentIndex = index),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(restaurants.length, (index) {
                    return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 4), width: index == _currentIndex ? 12 : 8, height: index == _currentIndex ? 12 : 8, decoration: BoxDecoration(shape: BoxShape.circle, color: index == _currentIndex ? Theme.of(context).colorScheme.primary : Colors.grey.shade400));
                  })),
                ]),
              const SizedBox(height: 24),
              // Browse button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant_menu),
                  label: Text(browseLabel),
                  onPressed: () {
                    // Ask parent shell to switch to the restaurants tab (index 1)
                    widget.onNavigate?.call(1);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}