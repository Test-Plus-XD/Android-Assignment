import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';

/// Booking Card Widget
///
/// Displays a single booking with status, restaurant info, date/time, and actions.
/// Used in booking history list.
class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isTraditionalChinese;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onViewRestaurant;

  const BookingCard({
    super.key,
    required this.booking,
    this.isTraditionalChinese = false,
    this.onTap,
    this.onCancel,
    this.onViewRestaurant,
  });

  Color _getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'confirmed':
        return theme.colorScheme.primary;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusLabel(String status) {
    if (!isTraditionalChinese) return status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'pending':
        return '待確認';
      case 'confirmed':
        return '已確認';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  }

  String _getPaymentStatusLabel(String paymentStatus) {
    if (!isTraditionalChinese) return paymentStatus.toUpperCase();

    switch (paymentStatus.toLowerCase()) {
      case 'unpaid':
        return '未付款';
      case 'paid':
        return '已付款';
      case 'refunded':
        return '已退款';
      default:
        return paymentStatus;
    }
  }

  bool _isPastBooking() {
    return booking.dateTime.isBefore(DateTime.now());
  }

  bool _canCancel() {
    return (booking.status.toLowerCase() == 'pending' ||
            booking.status.toLowerCase() == 'confirmed') &&
           !_isPastBooking();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and Payment Row
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(context, booking.status),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(booking.status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(context, booking.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Payment Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          booking.paymentStatus.toLowerCase() == 'paid'
                              ? Icons.check_circle
                              : Icons.payment,
                          size: 14,
                          color: booking.paymentStatus.toLowerCase() == 'paid'
                              ? Colors.green
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPaymentStatusLabel(booking.paymentStatus),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Past booking indicator
                  if (_isPastBooking())
                    Icon(
                      Icons.history,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Restaurant Name
              Text(
                booking.restaurantName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Date and Time
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(booking.dateTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(booking.dateTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Number of Guests
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.numberOfGuests} ${isTraditionalChinese ? "位客人" : "guests"}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Special Requests
              if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.specialRequests!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Actions
              if (_canCancel() || onViewRestaurant != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onViewRestaurant != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onViewRestaurant,
                          icon: const Icon(Icons.restaurant, size: 18),
                          label: Text(
                            isTraditionalChinese ? '查看餐廳' : 'View Restaurant',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_canCancel()) const SizedBox(width: 8),
                    ],
                    if (_canCancel())
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: Text(
                            isTraditionalChinese ? '取消預訂' : 'Cancel',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
