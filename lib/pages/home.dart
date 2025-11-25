import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/restaurant_service.dart';
import '../services/location_service.dart';
import '../models.dart';
import 'restaurant_detail.dart';

/// Home Page with Direct Vercel API Integration
///
/// This page fetches all restaurants from the Vercel Express API endpoint
/// rather than using Algolia search. The restaurants are then processed
/// locally to create featured and nearby lists.
///
/// Architecture decisions:
/// - Fetch once from API and cache results in memory
/// - Featured list: Random selection of 10 restaurants
/// - Nearby list: 10 closest restaurants based on GPS distance
/// - Results persist until explicit refresh
///
/// User journey:
/// 1. Page loads and fetches all restaurants from Vercel API
/// 2. Featured restaurants are randomly selected and cached
/// 3. GPS permission is requested (if not already granted)
/// 4. Location is acquired and nearest restaurants are calculated
/// 5. Both lists are displayed with carousel and horizontal scroll
/// 6. Pull-to-refresh reloads everything from scratch
class FrontPage extends StatefulWidget {
  final bool isTraditionalChinese;
  final ValueChanged<int>? onNavigate;

  const FrontPage({
    this.isTraditionalChinese = false,
    this.onNavigate,
    super.key,
  });

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  /// Current index for the featured restaurants carousel
  int _currentIndex = 0;

  /// Loading states for different operations
  bool _loadingFeatured = false;
  bool _loadingNearby = false;
  bool _initialLoadComplete = false;

  /// Cached restaurant lists
  /// These persist until explicit refresh to avoid unnecessary API calls
  List<Restaurant> _cachedFeatured = [];
  List<Restaurant> _cachedNearby = [];

  /// All restaurants fetched from API
  /// Used as source for both featured and nearby calculations
  List<Restaurant> _allRestaurants = [];

  @override
  void initState() {
    super.initState();
    /// Schedule initial load after first frame is built
    /// This prevents setState during build and ensures services are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }

  /// Performs initial data load on page creation
  ///
  /// This method orchestrates the loading sequence:
  /// 1. Fetch all restaurants from Vercel API
  /// 2. Extract featured restaurants randomly
  /// 3. Acquire GPS location and calculate nearest restaurants
  ///
  /// The method is designed to be called once on page load
  Future<void> _initialLoad() async {
    if (_initialLoadComplete) return;

    await _loadAllRestaurantsFromApi();
    _extractFeaturedRestaurants();
    await _calculateNearbyRestaurants();

    if (mounted) {
      setState(() {
        _initialLoadComplete = true;
      });
    }
  }

  /// Fetches all restaurant records from Vercel Express API
  ///
  /// This method calls the getAllRestaurants() endpoint which returns
  /// the complete restaurant dataset without pagination or search filters.
  /// The results are cached in _allRestaurants for subsequent processing.
  Future<void> _loadAllRestaurantsFromApi() async {
    if (_allRestaurants.isNotEmpty && !_loadingFeatured) return;

    setState(() => _loadingFeatured = true);

    try {
      final restaurantService = context.read<RestaurantService>();

      /// Fetch all restaurants from Vercel API endpoint
      /// This returns the complete dataset without search or filters
      final restaurants = await restaurantService.getAllRestaurants();

      if (mounted) {
        setState(() {
          _allRestaurants = restaurants;
          _loadingFeatured = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loadingFeatured = false);

        /// Show error message to user if API call fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '載入餐廳資料時發生錯誤'
                  : 'Error loading restaurants',
            ),
          ),
        );
      }
    }
  }

  /// Extracts featured restaurants through random selection
  ///
  /// This method selects 10 random restaurants from the complete dataset
  /// to display in the featured carousel. Random selection ensures users
  /// see different restaurants on each visit, improving content discovery.
  void _extractFeaturedRestaurants() {
    if (_allRestaurants.isEmpty) {
      setState(() => _cachedFeatured = []);
      return;
    }

    /// Create a copy to avoid modifying the original list
    final restaurantsCopy = List<Restaurant>.from(_allRestaurants);

    /// Shuffle the list to randomise selection
    restaurantsCopy.shuffle();

    /// Take the first 10 items after shuffling
    /// If fewer than 10 restaurants exist, take all available
    final featuredCount = restaurantsCopy.length >= 10 ? 10 : restaurantsCopy.length;

    setState(() {
      _cachedFeatured = restaurantsCopy.take(featuredCount).toList();
    });
  }

  /// Calculates and caches the 10 nearest restaurants
  ///
  /// This method performs the following steps:
  /// 1. Request and verify location permission
  /// 2. Acquire current GPS position
  /// 3. Calculate distance to each restaurant
  /// 4. Sort by distance and select 10 nearest
  ///
  /// The calculation happens client-side to avoid additional API calls
  /// and to provide real-time distance information.
  Future<void> _calculateNearbyRestaurants() async {
    setState(() => _loadingNearby = true);

    try {
      final locationService = context.read<LocationService>();

      /// Step 1: Verify location permission
      /// This shows the Android system permission dialogue if needed
      final hasPermission = await locationService.checkAndRequestPermission();

      if (!hasPermission) {
        if (mounted) {
          /// Show user-friendly message with action to open settings
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isTraditionalChinese
                    ? '無法取得位置權限。在設定中啟用以查看附近餐廳。'
                    : 'Location permission denied. Enable it in settings to see nearby restaurants.',
              ),
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

      /// Step 2: Acquire current position from GPS
      /// This may take several seconds as satellites are acquired
      final position = await locationService.getCurrentPosition();

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isTraditionalChinese
                    ? '無法取得您的位置。請確保 GPS 已啟用並稍後重試。'
                    : 'Could not get your location. Ensure GPS is enabled and try again.',
              ),
            ),
          );
        }
        setState(() => _loadingNearby = false);
        return;
      }

      /// Step 3: Calculate distance to each restaurant
      /// Only restaurants with valid coordinates are included
      final restaurantsWithDistance = <MapEntry<Restaurant, double>>[];

      for (final restaurant in _allRestaurants) {
        if (restaurant.latitude != null && restaurant.longitude != null) {
          /// Calculate great-circle distance using Haversine formula
          final distance = locationService.calculateDistance(
            position.latitude,
            position.longitude,
            restaurant.latitude!,
            restaurant.longitude!,
          );
          restaurantsWithDistance.add(MapEntry(restaurant, distance));
        }
      }

      /// Step 4: Sort by distance (ascending) and take first 10
      restaurantsWithDistance.sort((a, b) => a.value.compareTo(b.value));

      if (mounted) {
        setState(() {
          final nearbyCount = restaurantsWithDistance.length >= 10 ? 10 : restaurantsWithDistance.length;
          _cachedNearby = restaurantsWithDistance
              .take(nearbyCount)
              .map((entry) => entry.key)
              .toList();
          _loadingNearby = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '載入附近餐廳時發生錯誤'
                  : 'Error loading nearby restaurants',
            ),
          ),
        );
        setState(() => _loadingNearby = false);
      }
    }
  }

  /// Refreshes all data from scratch
  ///
  /// This method is called when user pulls down to refresh.
  /// It clears all caches and reloads everything from the API.
  Future<void> _refreshAll() async {
    setState(() {
      _loadingFeatured = true;
      _loadingNearby = true;
      _allRestaurants = [];
      _cachedFeatured = [];
      _cachedNearby = [];
    });

    await _loadAllRestaurantsFromApi();
    _extractFeaturedRestaurants();
    await _calculateNearbyRestaurants();
  }

  /// Builds a distance badge widget for a restaurant
  ///
  /// The badge shows the distance from user's current location
  /// with colour coding:
  /// - Green: < 500m (very close)
  /// - Orange: 500m - 2km (nearby)
  /// - Grey: > 2km (distant)
  Widget _buildDistanceBadge(Restaurant restaurant) {
    final locationService = context.read<LocationService>();

    /// Calculate distance from current position to restaurant
    final distance = locationService.calculateDistanceFromCurrent(
      restaurant.latitude!,
      restaurant.longitude!,
    );
    if (distance == null) return const SizedBox.shrink();
    /// Format distance for display (e.g., "1.2km" or "250m")
    final distanceText = locationService.formatDistance(distance);

    /// Determine badge colour based on distance thresholds
    Color badgeColour;
    if (distance < 500) {
      badgeColour = Colors.green;
    } else if (distance < 2000) {
      badgeColour = Colors.orange;
    } else {
      badgeColour = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColour,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            distanceText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Localised strings for UI elements
    final featuredHeading = widget.isTraditionalChinese
        ? '精選素食餐廳'
        : 'Featured Vegan Restaurants';
    final nearbyHeading = widget.isTraditionalChinese
        ? '附近素食餐廳'
        : 'Nearby Vegan Restaurants';
    final browseLabel = widget.isTraditionalChinese
        ? '瀏覽所有餐廳'
        : 'Browse All Restaurants';
    final refreshLabel = widget.isTraditionalChinese
        ? '重新整理位置'
        : 'Refresh Location';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            /// Nearby Restaurants Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nearbyHeading,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    tooltip: refreshLabel,
                    onPressed: _loadingNearby ? null : _calculateNearbyRestaurants,
                  ),
                ],
              ),
            ),

            /// Nearby restaurants loading, empty, or list state
            if (_loadingNearby)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_cachedNearby.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.location_off, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          widget.isTraditionalChinese
                              ? '無法取得附近餐廳。請啟用位置權限。'
                              : 'Unable to get nearby restaurants. Please enable location permission.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _calculateNearbyRestaurants,
                          child: Text(
                            widget.isTraditionalChinese ? '重試' : 'Retry',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _cachedNearby.length,
                  itemBuilder: (context, index) {
                    final restaurant = _cachedNearby[index];
                    final displayName = restaurant.getDisplayName(
                      widget.isTraditionalChinese,
                    );

                    return GestureDetector(
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
                      child: Card(
                        margin: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: restaurant.imageUrl ?? '',
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.restaurant),
                                          ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: _buildDistanceBadge(restaurant),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            /// Featured Restaurants Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                featuredHeading,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// Featured restaurants loading or carousel
            if (_loadingFeatured && _cachedFeatured.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_cachedFeatured.isNotEmpty)
              Column(
                children: [
                  CarouselSlider.builder(
                    itemCount: _cachedFeatured.length,
                    itemBuilder: (context, index, realIndex) {
                      final restaurant = _cachedFeatured[index];
                      final displayName = restaurant.getDisplayName(
                        widget.isTraditionalChinese,
                      );

                      return GestureDetector(
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
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: restaurant.imageUrl ?? '',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            Icons.restaurant,
                                            size: 48,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 220,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      enlargeCenterPage: true,
                      viewportFraction: 0.82,
                      onPageChanged: (index, reason) {
                        setState(() => _currentIndex = index);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// Carousel page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _cachedFeatured.length,
                          (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentIndex ? 12 : 8,
                          height: index == _currentIndex ? 12 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentIndex
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            /// Browse all restaurants button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: Text(browseLabel),
                onPressed: () {
                  /// Navigate to restaurants tab (index 1)
                  widget.onNavigate?.call(1);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}