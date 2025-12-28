import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../models.dart';

/// Store Bookings Management Page
///
/// Allows restaurant owners to manage bookings:
/// - View all bookings
/// - Filter by status (pending, confirmed, completed, cancelled)
/// - Confirm or reject pending bookings
/// - Mark confirmed bookings as completed
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
  String _selectedStatus = 'all'; // all, pending, confirmed, completed, cancelled

  @override
  void initState() {
    super.initState();
    // Load bookings after build is complete to avoid setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBookings();
      }
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

  Future<void> _refreshBookings() async {
    _loadBookings();
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    if (_selectedStatus == 'all') return bookings;
    return bookings.where((b) => b.status == _selectedStatus).toList();
  }

  Future<void> _updateBookingStatus(Booking booking, String newStatus) async {
    try {
      final bookingService = context.read<BookingService>();
      await bookingService.updateBooking(booking.id, status: newStatus);

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
          content: Text(widget.isTraditionalChinese ? '更新失敗：$e' : 'Update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '確認預約' : 'Confirm Booking'),
        content: Text(
          widget.isTraditionalChinese ? '確認此預約？' : 'Confirm this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.isTraditionalChinese ? '確認' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateBookingStatus(booking, 'confirmed');
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '拒絕預約' : 'Reject Booking'),
        content: Text(
          widget.isTraditionalChinese ? '確定要拒絕此預約？' : 'Are you sure you want to reject this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(widget.isTraditionalChinese ? '拒絕' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateBookingStatus(booking, 'cancelled');
    }
  }

  Future<void> _markCompleted(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '完成預約' : 'Complete Booking'),
        content: Text(
          widget.isTraditionalChinese ? '將此預約標記為完成？' : 'Mark this booking as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.isTraditionalChinese ? '完成' : 'Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateBookingStatus(booking, 'completed');
    }
  }

  int _getTodayBookingsCount(List<Booking> bookings) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return bookings.where((b) {
      final bookingDate = b.dateTime;
      return bookingDate.isAfter(startOfDay) &&
          bookingDate.isBefore(endOfDay) &&
          b.status != 'cancelled';
    }).length;
  }

  int _getPendingCount(List<Booking> bookings) {
    return bookings.where((b) => b.status == 'pending').length;
  }

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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    widget.isTraditionalChinese ? '載入失敗' : 'Failed to load',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
          final todayCount = _getTodayBookingsCount(allBookings);
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

                // Filter Chips
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
                          label: widget.isTraditionalChinese ? '已確認' : 'Confirmed',
                          value: 'confirmed',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: widget.isTraditionalChinese ? '已完成' : 'Completed',
                          value: 'completed',
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
                              Icon(Icons.event_busy, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                widget.isTraditionalChinese ? '沒有預約' : 'No bookings',
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
                            return _BookingCard(
                              booking: booking,
                              isTraditionalChinese: widget.isTraditionalChinese,
                              onConfirm: () => _confirmBooking(booking),
                              onReject: () => _rejectBooking(booking),
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

  Widget _buildFilterChip({required String label, required String value}) {
    final isSelected = _selectedStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }
}

/// Booking Card Widget
class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isTraditionalChinese;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onComplete;

  const _BookingCard({
    required this.booking,
    required this.isTraditionalChinese,
    required this.onConfirm,
    required this.onReject,
    required this.onComplete,
  });

  Color _getStatusColor() {
    switch (booking.status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (booking.status) {
      case 'pending':
        return isTraditionalChinese ? '待處理' : 'Pending';
      case 'confirmed':
        return isTraditionalChinese ? '已確認' : 'Confirmed';
      case 'completed':
        return isTraditionalChinese ? '已完成' : 'Completed';
      case 'cancelled':
        return isTraditionalChinese ? '已取消' : 'Cancelled';
      default:
        return booking.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.userName ?? (isTraditionalChinese ? '未知用戶' : 'Unknown User'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor()),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Booking Details
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(booking.dateTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${booking.partySize} ${isTraditionalChinese ? "人" : "guests"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.specialRequests!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],

            // Action Buttons
            if (booking.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(isTraditionalChinese ? '拒絕' : 'Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(isTraditionalChinese ? '確認' : 'Confirm'),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == 'confirmed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text(isTraditionalChinese ? '標記為完成' : 'Mark as Completed'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
