import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/restaurant_service.dart';
import '../models.dart';

// Store management page for restaurant owners to manage their claimed restaurant
class StorePage extends StatefulWidget {
  final bool isTraditionalChinese;
  final bool isDarkMode;

  const StorePage({
    required this.isTraditionalChinese,
    required this.isDarkMode,
    super.key,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  // Claimed restaurant data
  Restaurant? _restaurant;
  // Loading state
  bool _isLoading = false;
  // Error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurantData();
    });
  }

  // Loads the restaurant data based on user's restaurantId
  Future<void> _loadRestaurantData() async {
    final userService = context.read<UserService>();
    final restaurantService = context.read<RestaurantService>();
    final user = userService.currentProfile;

    // Check if user has a claimed restaurant
    if (user == null || !user.hasClaimedRestaurant) {
      setState(() {
        _errorMessage = widget.isTraditionalChinese
            ? '您尚未認領任何餐廳'
            : 'You have not claimed any restaurant';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final restaurant = await restaurantService.getRestaurantById(user.restaurantId!);
      if (mounted) {
        setState(() {
          _restaurant = restaurant;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = widget.isTraditionalChinese
              ? '載入餐廳資料失敗: $error'
              : 'Failed to load restaurant data: $error';
          _isLoading = false;
        });
      }
    }
  }

  // Builds a statistic card widget
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: widget.isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Builds an info row widget
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userService = context.watch<UserService>();
    final user = userService.currentProfile;

    // Not logged in state
    if (!authService.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese ? '請先登入' : 'Please log in first',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    // Not a restaurant owner
    if (user == null || !user.isRestaurantOwner) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese ? '此頁面僅供餐廳商戶使用' : 'This page is for restaurant owners only',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isTraditionalChinese
                    ? '請在帳戶設定中將帳戶類型更改為「商戶」'
                    : 'Please change your account type to "Restaurant" in account settings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // No claimed restaurant
    if (!user.hasClaimedRestaurant) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_business,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese ? '您尚未認領任何餐廳' : 'You have not claimed any restaurant',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isTraditionalChinese
                    ? '瀏覽餐廳列表並認領您的餐廳以開始管理'
                    : 'Browse restaurants and claim yours to start managing',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadRestaurantData,
                icon: const Icon(Icons.refresh),
                label: Text(widget.isTraditionalChinese ? '重試' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Restaurant data not loaded
    if (_restaurant == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Display restaurant management interface
    final restaurant = _restaurant!;
    final name = restaurant.getDisplayName(widget.isTraditionalChinese);
    final address = restaurant.getDisplayAddress(widget.isTraditionalChinese);
    final district = restaurant.getDisplayDistrict(widget.isTraditionalChinese);
    final keywords = restaurant.getDisplayKeywords(widget.isTraditionalChinese);

    return RefreshIndicator(
      onRefresh: _loadRestaurantData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Restaurant header image
            CachedNetworkImage(
              imageUrl: restaurant.imageUrl ?? '',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey.shade300,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey.shade300,
                child: const Icon(Icons.restaurant, size: 64),
              ),
            ),

            // Restaurant name and status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              widget.isTraditionalChinese ? '已認領' : 'Claimed',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Statistics section
            _buildSectionHeader(
              widget.isTraditionalChinese ? '統計資料' : 'Statistics',
              Icons.analytics,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: widget.isTraditionalChinese ? '座位數' : 'Seats',
                      value: '${restaurant.seats ?? 0}',
                      icon: Icons.event_seat,
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      title: widget.isTraditionalChinese ? '評價' : 'Reviews',
                      value: '0',
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      title: widget.isTraditionalChinese ? '預訂' : 'Bookings',
                      value: '0',
                      icon: Icons.calendar_today,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),

            // Restaurant information section
            _buildSectionHeader(
              widget.isTraditionalChinese ? '餐廳資訊' : 'Restaurant Information',
              Icons.info,
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildInfoRow(
                    widget.isTraditionalChinese ? '地址' : 'Address',
                    address,
                    Icons.location_on,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    widget.isTraditionalChinese ? '地區' : 'District',
                    district,
                    Icons.map,
                  ),
                  if (restaurant.contacts != null) ...[
                    if (restaurant.contacts!['phone'] != null) ...[
                      const Divider(height: 1),
                      _buildInfoRow(
                        widget.isTraditionalChinese ? '電話' : 'Phone',
                        restaurant.contacts!['phone'].toString(),
                        Icons.phone,
                      ),
                    ],
                    if (restaurant.contacts!['email'] != null) ...[
                      const Divider(height: 1),
                      _buildInfoRow(
                        widget.isTraditionalChinese ? '電郵' : 'Email',
                        restaurant.contacts!['email'].toString(),
                        Icons.email,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // Keywords/Features section
            if (keywords.isNotEmpty) ...[
              _buildSectionHeader(
                widget.isTraditionalChinese ? '特色標籤' : 'Features',
                Icons.label,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: keywords.map((keyword) {
                    return Chip(
                      label: Text(keyword),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Management actions section
            _buildSectionHeader(
              widget.isTraditionalChinese ? '管理操作' : 'Management Actions',
              Icons.settings,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      // TODO: Navigate to edit restaurant page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isTraditionalChinese ? '功能開發中...' : 'Feature coming soon...',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(
                      widget.isTraditionalChinese ? '編輯餐廳資料' : 'Edit Restaurant Info',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to booking management
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isTraditionalChinese ? '功能開發中...' : 'Feature coming soon...',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      widget.isTraditionalChinese ? '管理預訂' : 'Manage Bookings',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to reviews management
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isTraditionalChinese ? '功能開發中...' : 'Feature coming soon...',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review),
                    label: Text(
                      widget.isTraditionalChinese ? '查看評價' : 'View Reviews',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
