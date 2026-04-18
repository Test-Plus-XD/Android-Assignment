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
import '../widgets/skeletons/restaurant_detail_skeleton.dart';
import '../widgets/store/add_restaurant_sheet.dart';
import '../widgets/store/booking_card.dart';
import 'restaurant_reviews_page.dart';
import 'store_info_edit_page.dart';
import 'store_menu_manage_page.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  // Track previous tab to detect when the Ads tab becomes visible
  int _previousTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOwnedRestaurant();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Auto-check for a pending Stripe session when the app resumes from background.
  /// This fires when the Chrome Custom Tab closes after Stripe redirects to pourrice://.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingStripeSession();
    }
  }

  /// Called whenever the tab changes.
  /// When the user switches to the Ads tab (index 2), check for a pending Stripe session.
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final newTab = _tabController.index;
    if (newTab == 2 && _previousTab != 2) {
      _checkPendingStripeSession();
    }
    _previousTab = newTab;
  }

  Future<void> _loadOwnedRestaurant({bool forceRefresh = false}) async {
    if (!mounted) return;
    await context.read<StoreService>().getOwnedRestaurant(forceRefresh: forceRefresh);
  }

  Future<void> _showAddRestaurantSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRestaurantSheet(isTraditionalChinese: widget.isTraditionalChinese),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese ? '餐廳已成功新增！' : 'Restaurant added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ── Stripe / Advertisement helpers ────────────────────────────────────────

  /// Checks SharedPreferences for a pending Stripe session.
  /// If found, navigates to the ad form so the owner can fill content.
  Future<void> _checkPendingStripeSession() async {
    if (!mounted) return;
    try {
      final adService = context.read<AdvertisementService>();
      final pendingSession = await adService.checkPendingSession();
      if (pendingSession == null || !mounted) return;

      final isPaid = await adService.verifyCheckoutSessionPaid(
        pendingSession.sessionId,
      );
      if (!mounted) return;

      if (!isPaid) {
        await adService.clearPendingSession();
        if (!mounted) return;
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '付款尚未完成，請完成付款後再建立廣告。'
                  : 'Payment is not completed yet. Please complete payment before creating an ad.',
            ),
            backgroundColor: colorScheme.tertiaryContainer,
          ),
        );
        return;
      }

      // Clear the session first so it doesn't trigger again
      await adService.clearPendingSession();
      if (!mounted) return;

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => StoreAdFormPage(
            restaurantId: pendingSession.restaurantId,
            isTraditionalChinese: widget.isTraditionalChinese,
            restaurant: context.read<StoreService>().ownedRestaurant,
          ),
        ),
      );

      if (result == true && mounted) {
        final storeService = context.read<StoreService>();
        if (storeService.hasOwnedRestaurant) {
          _loadAds(storeService.ownedRestaurant!.id);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('StorePage: failed to validate pending Stripe session - $e');
      debugPrint('$stackTrace');
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese
                ? '暫時無法驗證付款狀態，請稍後再試。'
                : 'Unable to verify payment status right now. Please try again shortly.',
          ),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
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
                    ? '搵同認領你嘅餐廳，或者新增一間'
                    : 'Claim your existing restaurant or add a new one',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _showAddRestaurantSheet(context),
                icon: const Icon(Icons.add_business),
                label: Text(
                  widget.isTraditionalChinese ? '新增餐廳' : 'Add New Restaurant',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
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
                  text: widget.isTraditionalChinese ? '概覽' : 'Dashboard',
                ),
                Tab(
                  icon: const Icon(Icons.calendar_today),
                  text: widget.isTraditionalChinese ? '預訂' : 'Bookings',
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
                  onRefresh: () => _loadOwnedRestaurant(forceRefresh: true),
                ),

                // Tab 1 — Bookings
                _BookingsTab(
                  restaurantId: restaurant.id,
                  isTraditionalChinese: widget.isTraditionalChinese,
                ),

                // Tab 2 — Advertisements
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
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: _isTC ? '編輯餐廳資訊' : 'Edit restaurant info',
                          onPressed: () {
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
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
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
                  icon: Icons.star,
                  title: _isTC ? '評價' : 'Reviews',
                  subtitle: _isTC ? '查看顧客評價' : 'View customer reviews',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RestaurantReviewsPage(
                        restaurantId: restaurant.id,
                        restaurantName: restaurantName,
                        isTraditionalChinese: isTraditionalChinese,
                        readOnly: true,
                      ),
                    ));
                  },
                ),
              ],
            ),

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _menuItemsFuture =
            context.read<MenuService>().getMenuItems(widget.restaurantId);
        _bookingsFuture =
            context.read<BookingService>().getRestaurantBookings(widget.restaurantId);
      });
    });
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
        Expanded(
          child: FutureBuilder<List<MenuItem>>(
            future: _menuItemsFuture ?? Future.value(<MenuItem>[]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const StoreStatCardSkeleton();
              }
              final count = snapshot.data?.length ?? 0;
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
        Expanded(
          child: FutureBuilder<List<Booking>>(
            future: _bookingsFuture ?? Future.value(<Booking>[]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const StoreStatCardSkeleton();
              }
              final count = _getTodayBookingCount(snapshot.data ?? []);
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

// ── Bookings Tab ──────────────────────────────────────────────────────────────

/// Inline bookings tab — embeds the full booking management UI without
/// navigating to a separate page.
class _BookingsTab extends StatefulWidget {
  final String restaurantId;
  final bool isTraditionalChinese;

  const _BookingsTab({
    required this.restaurantId,
    required this.isTraditionalChinese,
  });

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  Future<List<Booking>>? _bookingsFuture;
  String _selectedStatus = 'all';

  bool get _isTC => widget.isTraditionalChinese;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBookings();
    });
  }

  void _loadBookings() {
    if (!mounted) return;
    setState(() {
      _bookingsFuture = context
          .read<BookingService>()
          .getRestaurantBookings(widget.restaurantId);
    });
  }

  Future<void> _refreshBookings() async => _loadBookings();

  List<Booking> _filterBookings(List<Booking> bookings) {
    if (_selectedStatus == 'all') return bookings;
    return bookings.where((b) => b.status == _selectedStatus).toList();
  }

  Future<void> _acceptBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isTC ? '接受預約' : 'Accept Booking'),
        content: Text(_isTC ? '確認接受此預約？' : 'Accept this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_isTC ? '取消' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_isTC ? '接受' : 'Accept'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _performUpdate(() async {
        await context.read<BookingService>().acceptBooking(booking.id);
      });
    }
  }

  Future<void> _declineBooking(Booking booking) async {
    final messageController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isTC ? '拒絕預約' : 'Decline Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isTC
                  ? '確定要拒絕此預約？可提供拒絕原因（選填）。'
                  : 'Decline this booking? You may provide a reason (optional).',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: messageController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: _isTC ? '拒絕原因（選填）' : 'Reason (optional)',
                border: const OutlineInputBorder(),
                hintText: _isTC ? '例如：已客滿' : 'e.g. Fully booked for that time slot',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_isTC ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_isTC ? '拒絕' : 'Decline'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final message = messageController.text.trim().isEmpty
          ? null
          : messageController.text.trim();
      await _performUpdate(() async {
        await context.read<BookingService>().declineBooking(booking.id, message: message);
      });
    }
    messageController.dispose();
  }

  Future<void> _markCompleted(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isTC ? '完成預約' : 'Complete Booking'),
        content: Text(_isTC ? '將此預約標記為完成？' : 'Mark this booking as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_isTC ? '取消' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_isTC ? '完成' : 'Complete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _performUpdate(() async {
        await context.read<BookingService>().completeBooking(booking.id);
      });
    }
  }

  Future<void> _performUpdate(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTC ? '預約已更新' : 'Booking updated'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTC ? '更新失敗：$e' : 'Update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getTodayCount(List<Booking> bookings) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return bookings.where((b) =>
        b.dateTime.isAfter(start) &&
        b.dateTime.isBefore(end) &&
        b.status != 'cancelled' &&
        b.status != 'declined').length;
  }

  int _getPendingCount(List<Booking> bookings) =>
      bookings.where((b) => b.status == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CenteredLoadingIndicator();
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _isTC ? '載入失敗' : 'Failed to load',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshBookings,
                  icon: const Icon(Icons.refresh),
                  label: Text(_isTC ? '重試' : 'Retry'),
                ),
              ],
            ),
          );
        }

        final allBookings = snapshot.data ?? [];
        final filteredBookings = _filterBookings(allBookings);
        final todayCount = _getTodayCount(allBookings);
        final pendingCount = _getPendingCount(allBookings);

        return RefreshIndicator(
          onRefresh: _refreshBookings,
          child: Column(
            children: [
              // Stats row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.today,
                        label: _isTC ? '今日預約' : 'Today',
                        value: todayCount.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.pending_actions,
                        label: _isTC ? '待處理' : 'Pending',
                        value: pendingCount.toString(),
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.event_available,
                        label: _isTC ? '總數' : 'Total',
                        value: allBookings.length.toString(),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(label: _isTC ? '全部' : 'All', value: 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip(label: _isTC ? '待處理' : 'Pending', value: 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip(label: _isTC ? '已接受' : 'Accepted', value: 'accepted'),
                      const SizedBox(width: 8),
                      _buildFilterChip(label: _isTC ? '已完成' : 'Completed', value: 'completed'),
                      const SizedBox(width: 8),
                      _buildFilterChip(label: _isTC ? '已拒絕' : 'Declined', value: 'declined'),
                      const SizedBox(width: 8),
                      _buildFilterChip(label: _isTC ? '已取消' : 'Cancelled', value: 'cancelled'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bookings list
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _isTC ? '沒有預約' : 'No bookings',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return StoreBookingCard(
                            booking: booking,
                            isTraditionalChinese: _isTC,
                            onAccept: () => _acceptBooking(booking),
                            onDecline: () => _declineBooking(booking),
                            onComplete: () => _markCompleted(booking),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildFilterChip({required String label, required String value}) {
    return FilterChip(
      label: Text(label),
      selected: _selectedStatus == value,
      onSelected: (_) => setState(() => _selectedStatus = value),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 180), // Increased bottom padding to clear the FAB
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
          bottom: 100, // Increased from 24 to clear the bottom nav bar
          right: 24,
          child: FloatingActionButton.extended(
            heroTag: 'place-ad-fab',
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
