import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Opening Hours Card Widget
///
/// Displays restaurant opening hours in a weekly schedule format.
/// Shows current day highlighted and indicates if restaurant is open now.
class OpeningHoursCard extends StatelessWidget {
  final Map<String, dynamic>? openingHours;
  final bool isTraditionalChinese;

  const OpeningHoursCard({
    required this.openingHours,
    required this.isTraditionalChinese,
    super.key,
  });

  String _getDayName(int dayIndex, bool isTC) {
    const daysEN = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const daysTC = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return isTC ? daysTC[dayIndex] : daysEN[dayIndex];
  }

  String _getDayKey(int dayIndex) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayIndex];
  }

  /// Parse time string to TimeOfDay
  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      // Try parsing formats like "09:00", "9:00 AM", "09:00:00"
      final parts = timeStr.split(':');
      if (parts.isEmpty) return null;

      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = parts.length > 1 ? (int.tryParse(parts[1].split(' ')[0]) ?? 0) : 0;

      // Handle AM/PM if present
      if (timeStr.toUpperCase().contains('PM') && hour < 12) {
        hour += 12;
      } else if (timeStr.toUpperCase().contains('AM') && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  /// Check if restaurant is currently open
  bool _isOpenNow() {
    if (openingHours == null) return false;

    final now = DateTime.now();
    final currentDay = _getDayKey(now.weekday - 1); // DateTime.weekday is 1-7, we need 0-6
    final currentTime = TimeOfDay.now();

    final dayHours = openingHours![currentDay];
    if (dayHours == null) return false;

    if (dayHours is String) {
      if (dayHours.toLowerCase() == 'closed') return false;
      // Parse time range like "09:00-22:00"
      final parts = dayHours.split('-');
      if (parts.length == 2) {
        final open = _parseTime(parts[0].trim());
        final close = _parseTime(parts[1].trim());
        if (open != null && close != null) {
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          final openMinutes = open.hour * 60 + open.minute;
          final closeMinutes = close.hour * 60 + close.minute;
          return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (openingHours == null || openingHours!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isOpen = _isOpenNow();
    final now = DateTime.now();
    final currentDayIndex = now.weekday - 1; // DateTime.weekday is 1-7 (Mon-Sun), we need 0-6

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTraditionalChinese ? '營業時間' : 'Opening Hours',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOpen ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isOpen ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTraditionalChinese
                            ? (isOpen ? '營業中' : '休息中')
                            : (isOpen ? 'Open Now' : 'Closed'),
                        style: TextStyle(
                          color: isOpen ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Weekly schedule
            ...List.generate(7, (index) {
              final dayKey = _getDayKey(index);
              final dayName = _getDayName(index, isTraditionalChinese);
              final hours = openingHours![dayKey];
              final isCurrentDay = index == currentDayIndex;

              String hoursText;
              if (hours == null) {
                hoursText = isTraditionalChinese ? '未提供' : 'Not available';
              } else if (hours is String) {
                if (hours.toLowerCase() == 'closed') {
                  hoursText = isTraditionalChinese ? '休息' : 'Closed';
                } else {
                  hoursText = hours;
                }
              } else {
                hoursText = hours.toString();
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isCurrentDay
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentDay
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    Text(
                      hoursText,
                      style: TextStyle(
                        fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentDay
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
