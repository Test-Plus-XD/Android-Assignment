import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';

/// Booking Form Widget
///
/// Bottom sheet form for creating/editing restaurant table bookings.
/// Includes date/time picker, guest count selector, and special requests field.
class BookingForm extends StatefulWidget {
  final Restaurant restaurant;
  final Booking? existingBooking;
  final Function(DateTime dateTime, int numberOfGuests, String? specialRequests) onSubmit;
  final bool isTraditionalChinese;

  const BookingForm({
    super.key,
    required this.restaurant,
    this.existingBooking,
    required this.onSubmit,
    this.isTraditionalChinese = false,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _specialRequestsController = TextEditingController();

  late DateTime _selectedDateTime;
  late int _numberOfGuests;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingBooking != null) {
      _selectedDateTime = widget.existingBooking!.dateTime;
      _numberOfGuests = widget.existingBooking!.numberOfGuests;
      _specialRequestsController.text = widget.existingBooking!.specialRequests ?? '';
    } else {
      // Default to tomorrow at 7 PM
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _selectedDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19, 0);
      _numberOfGuests = 2;
    }
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: widget.isTraditionalChinese ? '選擇日期' : 'Select Date',
      cancelText: widget.isTraditionalChinese ? '取消' : 'Cancel',
      confirmText: widget.isTraditionalChinese ? '確認' : 'OK',
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      helpText: widget.isTraditionalChinese ? '選擇時間' : 'Select Time',
      cancelText: widget.isTraditionalChinese ? '取消' : 'Cancel',
      confirmText: widget.isTraditionalChinese ? '確認' : 'OK',
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final specialRequests = _specialRequestsController.text.trim();
      widget.onSubmit(
        _selectedDateTime,
        _numberOfGuests,
        specialRequests.isEmpty ? null : specialRequests,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.restaurant_menu, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isTraditionalChinese ? '預訂餐桌' : 'Book a Table',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.restaurant.getDisplayName(widget.isTraditionalChinese),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Selection
              Text(
                widget.isTraditionalChinese ? '日期' : 'Date',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        dateFormat.format(_selectedDateTime),
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time Selection
              Text(
                widget.isTraditionalChinese ? '時間' : 'Time',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        timeFormat.format(_selectedDateTime),
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Number of Guests
              Text(
                widget.isTraditionalChinese ? '人數' : 'Number of Guests',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _numberOfGuests > 1
                          ? () => setState(() => _numberOfGuests--)
                          : null,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_numberOfGuests',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _numberOfGuests < 20
                          ? () => setState(() => _numberOfGuests++)
                          : null,
                      color: theme.colorScheme.primary,
                    ),
                    const Spacer(),
                    Text(
                      widget.isTraditionalChinese ? '位客人' : 'guests',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Special Requests
              Text(
                widget.isTraditionalChinese ? '特別要求（可選）' : 'Special Requests (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _specialRequestsController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: widget.isTraditionalChinese
                      ? '例如：素食選項、生日慶祝、靠窗座位...'
                      : 'e.g., Dietary restrictions, celebration, window seat...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.existingBooking != null
                              ? (widget.isTraditionalChinese ? '更新預訂' : 'Update Booking')
                              : (widget.isTraditionalChinese ? '確認預訂' : 'Confirm Booking'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
