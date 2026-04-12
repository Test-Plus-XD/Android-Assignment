import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';

/// Booking card for the restaurant owner view.
///
/// Shows enriched diner contact info, decline reason when present,
/// and contextual action buttons per status.
class StoreBookingCard extends StatelessWidget {
  final Booking booking;
  final bool isTraditionalChinese;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onComplete;

  const StoreBookingCard({
    required this.booking,
    required this.isTraditionalChinese,
    required this.onAccept,
    required this.onDecline,
    required this.onComplete,
    super.key,
  });

  bool get _isTC => isTraditionalChinese;

  Color _getStatusColor() {
    switch (booking.status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'cancelled':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (booking.status) {
      case 'pending':
        return _isTC ? '待處理' : 'Pending';
      case 'accepted':
        return _isTC ? '已接受' : 'Accepted';
      case 'completed':
        return _isTC ? '已完成' : 'Completed';
      case 'declined':
        return _isTC ? '已拒絕' : 'Declined';
      case 'cancelled':
        return _isTC ? '已取消' : 'Cancelled';
      default:
        return booking.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final dinerName = booking.diner?.displayName ??
        (_isTC ? '未知用戶' : 'Unknown User');

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: diner name + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dinerName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

            // Diner contact info
            if (booking.diner?.email != null ||
                booking.diner?.phoneNumber != null) ...[
              const SizedBox(height: 8),
              if (booking.diner?.email != null)
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      booking.diner!.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              if (booking.diner?.phoneNumber != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        booking.diner!.phoneNumber!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 12),

            // Date / time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(dateFormat.format(booking.dateTime),
                    style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),

            // Party size
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${booking.partySize} ${_isTC ? "人" : "guests"}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            // Special requests
            if (booking.specialRequests != null &&
                booking.specialRequests!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(booking.specialRequests!,
                        style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ],

            // Decline reason
            if (booking.status == 'declined' &&
                booking.declineMessage != null &&
                booking.declineMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_isTC ? "拒絕原因：" : "Reason: "}${booking.declineMessage}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (booking.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(_isTC ? '拒絕' : 'Decline'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(_isTC ? '接受' : 'Accept'),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == 'accepted') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text(_isTC ? '標記為完成' : 'Mark as Completed'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
