import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../models.dart';

/// Store Dashboard Page
///
/// Dashboard for restaurant owners to manage their business.
/// Features:
/// - Restaurant overview
/// - Quick stats
/// - Menu management access
/// - Settings access
class StoreDashboardPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const StoreDashboardPage({
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<StoreDashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadOwnedRestaurant();
  }

  Future<void> _loadOwnedRestaurant() async {
    final storeService = context.read<StoreService>();
    await storeService.getOwnedRestaurant();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final storeService = context.watch<StoreService>();

    if (!authService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isTraditionalChinese ? '餐廳管理' : 'Store Dashboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese ? '請先登入' : 'Please log in',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (storeService.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isTraditionalChinese ? '餐廳管理' : 'Store Dashboard'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!storeService.hasOwnedRestaurant) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isTraditionalChinese ? '餐廳管理' : 'Store Dashboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_mall_directory_outlined,
                  size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese ? '您尚未擁有餐廳' : 'You don\'t own a restaurant yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isTraditionalChinese
                    ? '聯絡管理員以認領您的餐廳'
                    : 'Contact admin to claim your restaurant',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final restaurant = storeService.ownedRestaurant!;
    final name = widget.isTraditionalChinese
        ? (restaurant.nameTc ?? restaurant.nameEn ?? '')
        : (restaurant.nameEn ?? restaurant.nameTc ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTraditionalChinese ? '餐廳管理' : 'Store Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: widget.isTraditionalChinese ? '重新整理' : 'Refresh',
            onPressed: _loadOwnedRestaurant,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOwnedRestaurant,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isTraditionalChinese
                                  ? (restaurant.addressTc ??
                                      restaurant.addressEn ??
                                      '')
                                  : (restaurant.addressEn ??
                                      restaurant.addressTc ??
                                      ''),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (restaurant.seats != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.event_seat, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.isTraditionalChinese ? "座位數量" : "Seats"}: ${restaurant.seats}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions Grid
              Text(
                widget.isTraditionalChinese ? '快速操作' : 'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildActionCard(
                    context: context,
                    icon: Icons.restaurant_menu,
                    title: widget.isTraditionalChinese ? '管理菜單' : 'Manage Menu',
                    subtitle: widget.isTraditionalChinese
                        ? '新增、編輯、刪除菜單項目'
                        : 'Add, edit, delete menu items',
                    onTap: () {
                      // TODO: Navigate to menu management
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isTraditionalChinese
                                ? '菜單管理功能開發中'
                                : 'Menu management coming soon',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.calendar_today,
                    title: widget.isTraditionalChinese ? '預訂管理' : 'Bookings',
                    subtitle: widget.isTraditionalChinese
                        ? '查看和管理預訂'
                        : 'View and manage bookings',
                    onTap: () {
                      // TODO: Navigate to bookings management
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isTraditionalChinese
                                ? '預訂管理功能開發中'
                                : 'Bookings management coming soon',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.star,
                    title: widget.isTraditionalChinese ? '評價' : 'Reviews',
                    subtitle: widget.isTraditionalChinese
                        ? '查看顧客評價'
                        : 'View customer reviews',
                    onTap: () {
                      // TODO: Navigate to reviews
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isTraditionalChinese
                                ? '評價管理功能開發中'
                                : 'Reviews management coming soon',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.settings,
                    title: widget.isTraditionalChinese ? '設定' : 'Settings',
                    subtitle: widget.isTraditionalChinese
                        ? '更新餐廳資訊'
                        : 'Update restaurant info',
                    onTap: () {
                      // TODO: Navigate to settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isTraditionalChinese
                                ? '設定功能開發中'
                                : 'Settings coming soon',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Statistics Section
              Text(
                widget.isTraditionalChinese ? '統計數據' : 'Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              Consumer<MenuService>(
                builder: (context, menuService, child) {
                  return FutureBuilder<List<MenuItem>>(
                    future: menuService.getMenuItems(restaurant.id),
                    builder: (context, snapshot) {
                      final menuItemCount =
                          snapshot.hasData ? snapshot.data!.length : 0;

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: Icons.restaurant_menu,
                              label: widget.isTraditionalChinese
                                  ? '菜單項目'
                                  : 'Menu Items',
                              value: menuItemCount.toString(),
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: Icons.calendar_today,
                              label: widget.isTraditionalChinese
                                  ? '今日預訂'
                                  : 'Today\'s Bookings',
                              value: '0', // TODO: Implement booking count
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
