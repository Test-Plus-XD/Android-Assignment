import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/booking_service.dart';
import '../../models.dart';

/// Booking Dialog Widget
///
/// Displays a dialog for creating a table booking with:
/// - Date and time picker
/// - Number of guests selector
/// - Confirmation button
class BookingDialog extends StatefulWidget {
  final Restaurant restaurant;
  final bool isTraditionalChinese;

  const BookingDialog({
    required this.restaurant,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? _selectedDateTime;
  int _numberOfGuests = 1;
  bool _isBooking = false;

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future<void> _createBooking() async {
    if (_selectedDateTime == null) return;

    setState(() => _isBooking = true);

    try {
      final bookingService = context.read<BookingService>();
      final restaurantName = widget.isTraditionalChinese
          ? (widget.restaurant.nameTc ?? widget.restaurant.nameEn ?? '')
          : (widget.restaurant.nameEn ?? widget.restaurant.nameTc ?? '');

      final booking = await bookingService.createBooking(
        restaurantId: widget.restaurant.id,
        restaurantName: restaurantName,
        dateTime: _selectedDateTime!,
        numberOfGuests: _numberOfGuests,
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog

        if (booking != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isTraditionalChinese ? '預訂成功！' : 'Booking successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.isTraditionalChinese ? '預訂失敗' : 'Booking failed'}: ${bookingService.errorMessage}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isTraditionalChinese ? '預訂餐桌' : 'Book a Table',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and time picker
            Text(
              widget.isTraditionalChinese ? '日期和時間' : 'Date and Time',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDateTime == null
                    ? (widget.isTraditionalChinese ? '選擇日期時間' : 'Select date & time')
                    : _formatDateTime(_selectedDateTime!),
              ),
              onPressed: () async {
                // Show date picker
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 17, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            // Number of guests selector
            Text(
              widget.isTraditionalChinese ? '人數' : 'Number of Guests',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _numberOfGuests > 1
                      ? () => setState(() => _numberOfGuests--)
                      : null,
                ),
                Text(
                  '$_numberOfGuests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _numberOfGuests < 10
                      ? () => setState(() => _numberOfGuests++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedDateTime == null || _isBooking ? null : _createBooking,
          child: _isBooking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isTraditionalChinese ? '確認預訂' : 'Confirm'),
        ),
      ],
    );
  }
}
