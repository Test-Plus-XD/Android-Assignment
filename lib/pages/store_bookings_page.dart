import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/booking_service.dart';
import '../models.dart';
import '../widgets/store/booking_card.dart';
import '../widgets/common/loading_indicator.dart';

/// Store Bookings Management Page
///
/// Allows restaurant owners to manage bookings:
/// - View all bookings with enriched diner contact info
/// - Filter by status (all, pending, accepted, declined, completed, cancelled)
/// - Accept pending bookings
/// - Decline pending bookings with an optional message
/// - Mark accepted bookings as completed
class StoreBookingsPage extends StatefulWidget {
  final String restaurantId;
  final bool isTraditionalChinese;

  const StoreBookingsPage({
    required this.restaurantId,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<StoreBookingsPage> createState() => _StoreBookingsPageState();
}

class _StoreBookingsPageState extends State<StoreBookingsPage> {
  Future<List<Booking>>? _bookingsFuture;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
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

  /// Accept a pending booking — sets status to 'accepted'
  Future<void> _acceptBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '接受預約' : 'Accept Booking'),
        content: Text(
          widget.isTraditionalChinese ? '確認接受此預約？' : 'Accept this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(widget.isTraditionalChinese ? '接受' : 'Accept'),
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

  /// Decline a pending booking — shows a dialog with an optional message field
  Future<void> _declineBooking(Booking booking) async {
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '拒絕預約' : 'Decline Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isTraditionalChinese
                  ? '確定要拒絕此預約？可提供拒絕原因（選填）。'
                  : 'Decline this booking? You may provide a reason (optional).',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: messageController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '拒絕原因（選填）' : 'Reason (optional)',
                border: const OutlineInputBorder(),
                hintText: widget.isTraditionalChinese
                    ? '例如：已客滿'
                    : 'e.g. Fully booked for that time slot',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(widget.isTraditionalChinese ? '拒絕' : 'Decline'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final message = messageController.text.trim().isEmpty
          ? null
          : messageController.text.trim();
      await _performUpdate(() async {
        await context
            .read<BookingService>()
            .declineBooking(booking.id, message: message);
      });
    }

    messageController.dispose();
  }

  /// Mark an accepted booking as completed
  Future<void> _markCompleted(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '完成預約' : 'Complete Booking'),
        content: Text(
          widget.isTraditionalChinese
              ? '將此預約標記為完成？'
              : 'Mark this booking as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(widget.isTraditionalChinese ? '完成' : 'Complete'),
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

  /// Shared update handler — runs the action, shows feedback, then reloads
  Future<void> _performUpdate(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese ? '預約已更新' : 'Booking updated'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese ? '更新失敗：$e' : 'Update failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getTodayCount(List<Booking> bookings) {
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

  int _getPendingCount(List<Booking> bookings) =>
      bookings.where((b) => b.status == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTraditionalChinese ? '預約管理' : 'Manage Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBookings,
            tooltip: widget.isTraditionalChinese ? '重新整理' : 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Booking>>(
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
                    widget.isTraditionalChinese ? '載入失敗' : 'Failed to load',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshBookings,
                    icon: const Icon(Icons.refresh),
                    label: Text(widget.isTraditionalChinese ? '重試' : 'Retry'),
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
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context: context,
                          icon: Icons.today,
                          label: widget.isTraditionalChinese ? '今日預約' : 'Today',
                          value: todayCount.toString(),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context: context,
                          icon: Icons.pending_actions,
                          label: widget.isTraditionalChinese ? '待處理' : 'Pending',
                          value: pendingCount.toString(),
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context: context,
                          icon: Icons.event_available,
                          label: widget.isTraditionalChinese ? '總數' : 'Total',
                          value: allBookings.length.toString(),
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter Chips — includes accepted and declined
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: widget.isTraditionalChinese ? '全部' : 'All',
                          value: 'all',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: widget.isTraditionalChinese ? '待處理' : 'Pending',
                          value: 'pending',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: widget.isTraditionalChinese ? '已接受' : 'Accepted',
                          value: 'accepted',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: widget.isTraditionalChinese ? '已完成' : 'Completed',
                          value: 'completed',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: widget.isTraditionalChinese ? '已拒絕' : 'Declined',
                          value: 'declined',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: widget.isTraditionalChinese ? '已取消' : 'Cancelled',
                          value: 'cancelled',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bookings List
                Expanded(
                  child: filteredBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                widget.isTraditionalChinese ? '沒有預約' : 'No bookings',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            return StoreBookingCard(
                              booking: booking,
                              isTraditionalChinese: widget.isTraditionalChinese,
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