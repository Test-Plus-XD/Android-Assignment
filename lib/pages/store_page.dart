import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/booking_service.dart';
import '../services/advertisement_service.dart';
import '../models.dart';
import '../widgets/qr/menu_qr_generator.dart';
import '../widgets/common/loading_indicator.dart';
import 'store_info_edit_page.dart';
import 'store_menu_manage_page.dart';
import 'store_bookings_page.dart';
import 'store_ad_form_page.dart';

/// Store Dashboard Page
///
/// Dashboard for restaurant owners to manage their business.
/// Contains two tabs:
///   • Tab 0 — Dashboard: overview, quick actions, QR code, stats
///   • Tab 1 — Advertisements: ad list + Stripe payment flow
class StorePage extends StatefulWidget {
  final bool isTraditionalChinese;

  const StorePage({
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // Track previous tab to detect when the Ads tab becomes visible
  int _previousTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOwnedRestaurant();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Called whenever the tab changes.
  /// When the user switches to the Ads tab, check for a pending Stripe session.
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final newTab = _tabController.index;
    if (newTab == 1 && _previousTab != 1) {
      _checkPendingStripeSession();
    }
    _previousTab = newTab;
  }

  Future<void> _loadOwnedRestaurant() async {
    if (!mounted) return;
    await context.read<StoreService>().getOwnedRestaurant();
  }

  // ── Stripe / Advertisement helpers ────────────────────────────────────────

  /// Checks SharedPreferences for a pending Stripe session.
  /// If found, navigates to the ad form so the owner can fill content.
  Future<void> _checkPendingStripeSession() async {
    if (!mounted) return;
    final adService = context.read<AdvertisementService>();
    final restaurantId = await adService.checkPendingSession();
    if (restaurantId == null || !mounted) return;

    // Clear the session first so it doesn't trigger again
    await adService.clearPendingSession();
    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StoreAdFormPage(
          restaurantId: restaurantId,
          isTraditionalChinese: widget.isTraditionalChinese,
        ),
      ),
    );

    if (result == true && mounted) {
      final storeService = context.read<StoreService>();
      if (storeService.hasOwnedRestaurant) {
        _loadAds(storeService.ownedRestaurant!.id);
      }
    }
  }

  /// Starts the Stripe checkout flow for placing a new ad
  Future<void> _startStripeCheckout(String restaurantId) async {
    if (!mounted) return;
    final adService = context.read<AdvertisementService>();
    final success = await adService.createAdCheckoutSession(restaurantId);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese
                ? '無法建立付款連結，請稍後再試'
                : 'Could not create payment link. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    // The Stripe URL is opened inside createAdCheckoutSession.
    // When the user returns to the app and taps the Ads tab, _checkPendingStripeSession fires.
  }

  Future<void> _loadAds(String restaurantId) async {
    if (!mounted) return;
    await context
        .read<AdvertisementService>()
        .getAdvertisements(restaurantId: restaurantId);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final storeService = context.watch<StoreService>();

    if (!authService.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Colors.grey),
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
      return const Scaffold(body: CenteredLoadingIndicator.large());
    }

    if (!storeService.hasOwnedRestaurant) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store_mall_directory_outlined,
                  size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese
                    ? '您尚未擁有餐廳'
                    : 'You don\'t own a restaurant yet',
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
      body: Column(
        children: [
          // Safe area spacing (no AppBar)
          SizedBox(height: MediaQuery.of(context).padding.top),

          // ── Tab bar — positioned at top of body, below status bar ───────
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 1,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.dashboard),
                  text: widget.isTraditionalChinese ? '儀表板' : 'Dashboard',
                ),
                Tab(
                  icon: const Icon(Icons.campaign),
                  text: widget.isTraditionalChinese ? '廣告' : 'Advertisements',
                ),
              ],
            ),
          ),

          // ── Tab views ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0 — Dashboard
                _DashboardTab(
                  restaurant: restaurant,
                  restaurantName: name,
                  isTraditionalChinese: widget.isTraditionalChinese,
                  onRefresh: _loadOwnedRestaurant,
                ),

                // Tab 1 — Advertisements
                _AdsTab(
                  restaurantId: restaurant.id,
                  isTraditionalChinese: widget.isTraditionalChinese,
                  onStartCheckout: () => _startStripeCheckout(restaurant.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final Restaurant restaurant;
  final String restaurantName;
  final bool isTraditionalChinese;
  final VoidCallback onRefresh;

  const _DashboardTab({
    required this.restaurant,
    required this.restaurantName,
    required this.isTraditionalChinese,
    required this.onRefresh,
  });

  bool get _isTC => isTraditionalChinese;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
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
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isTC
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
                          const Icon(Icons.event_seat,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${_isTC ? "座位數量" : "Seats"}: ${restaurant.seats}',
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
              _isTC ? '快速操作' : 'Quick Actions',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                  title: _isTC ? '管理菜單' : 'Manage Menu',
                  subtitle: _isTC
                      ? '新增、編輯、刪除菜單項目'
                      : 'Add, edit, delete menu items',
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                          builder: (_) => StoreMenuManagePage(
                            restaurantId: restaurant.id,
                            isTraditionalChinese: isTraditionalChinese,
                          ),
                        ))
                        .then((_) => onRefresh());
                  },
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.calendar_today,
                  title: _isTC ? '預訂管理' : 'Bookings',
                  subtitle: _isTC ? '查看和管理預訂' : 'View and manage bookings',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => StoreBookingsPage(
                        restaurantId: restaurant.id,
                        isTraditionalChinese: isTraditionalChinese,
                      ),
                    ));
                  },
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.star,
                  title: _isTC ? '評價' : 'Reviews',
                  subtitle: _isTC ? '查看顧客評價' : 'View customer reviews',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isTC ? '評價管理功能開發中' : 'Reviews management coming soon',
                        ),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.settings,
                  title: _isTC ? '設定' : 'Settings',
                  subtitle: _isTC ? '更新餐廳資訊' : 'Update restaurant info',
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                          builder: (_) => StoreInfoEditPage(
                            restaurant: restaurant,
                            isTraditionalChinese: isTraditionalChinese,
                          ),
                        ))
                        .then((result) {
                      if (result == true) onRefresh();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // QR Code Section
            Text(
              _isTC ? '菜單二維碼' : 'Menu QR Code',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            MenuQRGenerator(
              restaurantId: restaurant.id,
              restaurantName: restaurantName,
              isTraditionalChinese: isTraditionalChinese,
            ),

            const SizedBox(height: 24),

            // Statistics Section
            Text(
              _isTC ? '統計數據' : 'Statistics',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _StatisticsSection(
              restaurantId: restaurant.id,
              isTraditionalChinese: isTraditionalChinese,
            ),

            const SizedBox(height: 80),
          ],
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Icon(icon,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Statistics Section ────────────────────────────────────────────────────────

/// Fetches menu item count and today's booking count to display as stat cards.
/// Both futures are initialised in initState to avoid setState-during-build.
class _StatisticsSection extends StatefulWidget {
  final String restaurantId;
  final bool isTraditionalChinese;

  const _StatisticsSection({
    required this.restaurantId,
    required this.isTraditionalChinese,
  });

  @override
  State<_StatisticsSection> createState() => _StatisticsSectionState();
}

class _StatisticsSectionState extends State<_StatisticsSection> {
  Future<List<MenuItem>>? _menuItemsFuture;
  Future<List<Booking>>? _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _menuItemsFuture =
        context.read<MenuService>().getMenuItems(widget.restaurantId);
    _bookingsFuture =
        context.read<BookingService>().getRestaurantBookings(widget.restaurantId);
  }

  int _getTodayBookingCount(List<Booking> bookings) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return bookings.where((b) {
      return b.dateTime.isAfter(start) &&
          b.dateTime.isBefore(end) &&
          b.status != 'cancelled' &&
          b.status != 'declined';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Menu item count
        Expanded(
          child: FutureBuilder<List<MenuItem>>(
            future: _menuItemsFuture,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : 0;
              return _buildStatCard(
                context: context,
                icon: Icons.restaurant_menu,
                label: widget.isTraditionalChinese ? '菜單項目' : 'Menu Items',
                value: count.toString(),
                color: Colors.orange,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        // Today's booking count (from real API data)
        Expanded(
          child: FutureBuilder<List<Booking>>(
            future: _bookingsFuture,
            builder: (context, snapshot) {
              final count = snapshot.hasData
                  ? _getTodayBookingCount(snapshot.data!)
                  : 0;
              return _buildStatCard(
                context: context,
                icon: Icons.calendar_today,
                label: widget.isTraditionalChinese ? '今日預訂' : 'Today\'s Bookings',
                value: count.toString(),
                color: Colors.blue,
              );
            },
          ),
        ),
      ],
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Advertisements Tab ────────────────────────────────────────────────────────

/// Advertisements tab content.
///
/// Loads the restaurant's ads on first view, shows a "Place New Ad" button
/// that starts the Stripe checkout flow, and provides toggle/delete actions
/// on each ad card.
class _AdsTab extends StatefulWidget {
  final String restaurantId;
  final bool isTraditionalChinese;
  final VoidCallback onStartCheckout;

  const _AdsTab({
    required this.restaurantId,
    required this.isTraditionalChinese,
    required this.onStartCheckout,
  });

  @override
  State<_AdsTab> createState() => _AdsTabState();
}

class _AdsTabState extends State<_AdsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAds());
  }

  bool get _isTC => widget.isTraditionalChinese;

  Future<void> _loadAds() async {
    if (!mounted) return;
    await context
        .read<AdvertisementService>()
        .getAdvertisements(restaurantId: widget.restaurantId);
  }

  Future<void> _toggleStatus(Advertisement ad) async {
    try {
      final newStatus = ad.status == 'active' ? 'inactive' : 'active';
      await context.read<AdvertisementService>().updateAdvertisement(
        ad.id,
        {'status': newStatus},
      );
      if (!mounted) return;
      await _loadAds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_isTC ? "更新失敗：" : "Update failed: "}$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAd(Advertisement ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isTC ? '刪除廣告' : 'Delete Advertisement'),
        content: Text(
          _isTC
              ? '確定要刪除此廣告？此操作無法撤銷。'
              : 'Are you sure you want to delete this ad? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_isTC ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_isTC ? '刪除' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<AdvertisementService>().deleteAdvertisement(ad.id);
        if (!mounted) return;
        await _loadAds();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isTC ? "刪除失敗：" : "Delete failed: "}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adService = context.watch<AdvertisementService>();
    final ads = adService.advertisements;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadAds,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Info banner — pricing info
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isTC
                              ? '每個廣告 HK\$10。付款後可填寫廣告內容。'
                              : 'HK\$10 per advertisement. Fill in content after payment.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading indicator
              if (adService.isLoading && ads.isEmpty)
                const SliverFillRemaining(
                  child: CenteredLoadingIndicator(),
                )
              // Empty state
              else if (ads.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 80,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                          _isTC ? '目前沒有廣告' : 'No advertisements yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isTC
                              ? '點擊下方按鈕投放您的第一個廣告'
                              : 'Tap the button below to place your first ad',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              // Ad list
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ad = ads[index];
                        return _AdCard(
                          ad: ad,
                          isTraditionalChinese: _isTC,
                          onToggle: () => _toggleStatus(ad),
                          onDelete: () => _deleteAd(ad),
                        );
                      },
                      childCount: ads.length,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // "Place New Ad" floating button
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: adService.isLoading ? null : widget.onStartCheckout,
            icon: const Icon(Icons.add),
            label: Text(_isTC ? '投放廣告' : 'Place New Ad'),
          ),
        ),
      ],
    );
  }
}

/// Ad card displayed in the Advertisements tab list
class _AdCard extends StatelessWidget {
  final Advertisement ad;
  final bool isTraditionalChinese;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AdCard({
    required this.ad,
    required this.isTraditionalChinese,
    required this.onToggle,
    required this.onDelete,
  });

  bool get _isTC => isTraditionalChinese;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isTC ? (ad.titleTc ?? ad.titleEn) : (ad.titleEn ?? ad.titleTc);
    final content = _isTC
        ? (ad.contentTc ?? ad.contentEn)
        : (ad.contentEn ?? ad.contentTc);
    final imageUrl = _isTC
        ? (ad.imageTc ?? ad.imageEn)
        : (ad.imageEn ?? ad.imageTc);

    final isActive = ad.status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge + title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      child: Text(
                        isActive
                            ? (_isTC ? '啟用中' : 'Active')
                            : (_isTC ? '已停用' : 'Inactive'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title ?? (_isTC ? '無標題' : 'No title'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (content != null && content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Action row — toggle + delete
                Row(
                  children: [
                    // Toggle active/inactive
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggle,
                        icon: Icon(
                          isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 18,
                        ),
                        label: Text(
                          isActive
                              ? (_isTC ? '停用' : 'Deactivate')
                              : (_isTC ? '啟用' : 'Activate'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: _isTC ? '刪除' : 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
