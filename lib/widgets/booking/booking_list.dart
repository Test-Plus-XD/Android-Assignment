import 'package:flutter/material.dart';
import '../../models.dart';
import 'booking_card.dart';

/// Booking List Widget
///
/// Displays a list of bookings with filtering options (upcoming, past, all).
/// Includes pull-to-refresh and empty states.
class BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final bool isTraditionalChinese;
  final VoidCallback? onRefresh;
  final Function(Booking)? onBookingTap;
  final Function(Booking)? onCancelBooking;
  final Function(Booking)? onViewRestaurant;
  final String filterType; // 'all', 'upcoming', 'past'

  const BookingList({
    super.key,
    required this.bookings,
    this.isTraditionalChinese = false,
    this.onRefresh,
    this.onBookingTap,
    this.onCancelBooking,
    this.onViewRestaurant,
    this.filterType = 'all',
  });

  List<Booking> _getFilteredBookings() {
    final now = DateTime.now();

    switch (filterType) {
      case 'upcoming':
        return bookings.where((b) => b.dateTime.isAfter(now)).toList();
      case 'past':
        return bookings.where((b) => b.dateTime.isBefore(now)).toList();
      default:
        return bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredBookings = _getFilteredBookings();

    if (filteredBookings.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          return BookingCard(
            booking: booking,
            isTraditionalChinese: isTraditionalChinese,
            onTap: onBookingTap != null ? () => onBookingTap!(booking) : null,
            onCancel: onCancelBooking != null ? () => onCancelBooking!(booking) : null,
            onViewRestaurant: onViewRestaurant != null ? () => onViewRestaurant!(booking) : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    String message;
    IconData icon;

    switch (filterType) {
      case 'upcoming':
        message = isTraditionalChinese ? '沒有即將到來的預訂' : 'No upcoming bookings';
        icon = Icons.event_available;
        break;
      case 'past':
        message = isTraditionalChinese ? '沒有過去的預訂' : 'No past bookings';
        icon = Icons.history;
        break;
      default:
        message = isTraditionalChinese ? '您還沒有預訂' : 'You don\'t have any bookings yet';
        icon = Icons.bookmark_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (filterType == 'all') ...[
            const SizedBox(height: 8),
            Text(
              isTraditionalChinese
                  ? '在餐廳詳情頁面預訂餐桌'
                  : 'Book a table from a restaurant\'s detail page',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
