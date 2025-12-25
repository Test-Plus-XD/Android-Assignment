import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../models.dart';
import '../widgets/booking/booking_list.dart';
import 'restaurant_detail.dart';
import 'login.dart';

/// Bookings Page
///
/// Displays user's booking history with filtering (All, Upcoming, Past).
/// Allows users to view booking details, cancel bookings, and navigate to restaurants.
class BookingsPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const BookingsPage({
    super.key,
    this.isTraditionalChinese = false,
  });

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTabIndex = _tabController.index);
    });

    // Load bookings on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      if (authService.isLoggedIn) {
        context.read<BookingService>().getUserBookings();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<BookingService>().getUserBookings();
  }

  void _handleCancelBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '取消預訂' : 'Cancel Booking'),
        content: Text(
          widget.isTraditionalChinese
              ? '您確定要取消這個預訂嗎？此操作無法撤銷。'
              : 'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isTraditionalChinese ? '取消' : 'No'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final bookingService = context.read<BookingService>();
              final success = await bookingService.cancelBooking(booking.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (widget.isTraditionalChinese ? '預訂已取消' : 'Booking cancelled')
                          : (widget.isTraditionalChinese ? '取消失敗' : 'Failed to cancel'),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );

                if (success) {
                  await _handleRefresh();
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(widget.isTraditionalChinese ? '確認取消' : 'Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleViewRestaurant(Booking booking) {
    // Navigate to restaurant detail page
    // Note: Would need to fetch restaurant data first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isTraditionalChinese
              ? '功能即將推出：查看餐廳詳情'
              : 'Coming soon: View restaurant details',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final bookingService = context.watch<BookingService>();

    // Not logged in
    if (!authService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isTraditionalChinese ? '我的預訂' : 'My Bookings'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login,
                  size: 80,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isTraditionalChinese ? '請先登入' : 'Please login first',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isTraditionalChinese
                      ? '您需要登入才能查看您的預訂'
                      : 'You need to login to view your bookings',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          isTraditionalChinese: widget.isTraditionalChinese,
                          isDarkMode: theme.brightness == Brightness.dark,
                          onThemeChanged: () {}, // Handled by main app level usually
                          onLanguageChanged: () {},
                          onSkip: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: Text(widget.isTraditionalChinese ? '登入' : 'Login'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTraditionalChinese ? '我的預訂' : 'My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: widget.isTraditionalChinese ? '全部' : 'All',
              icon: const Icon(Icons.list),
            ),
            Tab(
              text: widget.isTraditionalChinese ? '即將到來' : 'Upcoming',
              icon: const Icon(Icons.event_available),
            ),
            Tab(
              text: widget.isTraditionalChinese ? '過去' : 'Past',
              icon: const Icon(Icons.history),
            ),
          ],
        ),
      ),
      body: bookingService.isLoading && bookingService.userBookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // All Bookings
                BookingList(
                  bookings: bookingService.userBookings,
                  isTraditionalChinese: widget.isTraditionalChinese,
                  onRefresh: _handleRefresh,
                  onCancelBooking: _handleCancelBooking,
                  onViewRestaurant: _handleViewRestaurant,
                  filterType: 'all',
                ),
                // Upcoming Bookings
                BookingList(
                  bookings: bookingService.userBookings,
                  isTraditionalChinese: widget.isTraditionalChinese,
                  onRefresh: _handleRefresh,
                  onCancelBooking: _handleCancelBooking,
                  onViewRestaurant: _handleViewRestaurant,
                  filterType: 'upcoming',
                ),
                // Past Bookings
                BookingList(
                  bookings: bookingService.userBookings,
                  isTraditionalChinese: widget.isTraditionalChinese,
                  onRefresh: _handleRefresh,
                  onViewRestaurant: _handleViewRestaurant,
                  filterType: 'past',
                ),
              ],
            ),
    );
  }
}
