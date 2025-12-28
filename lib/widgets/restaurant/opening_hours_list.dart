import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Opening Hours List Widget
///
/// Displays a simple list of weekly opening hours
/// with the current day highlighted
class OpeningHoursList extends StatelessWidget {
  final Map<String, dynamic>? hours;
  final bool isTraditionalChinese;

  const OpeningHoursList({
    this.hours,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (hours == null || hours!.isEmpty) {
      return Text(
        isTraditionalChinese ? '暫未提供營業時間' : 'Opening hours not available',
      );
    }

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final chineseDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

    return Column(
      children: List.generate(days.length, (index) {
        final day = days[index];
        final chineseDay = chineseDays[index];
        final time = hours![day] ?? (isTraditionalChinese ? '休息' : 'Closed');

        // Highlight current day
        final isToday = DateFormat('EEEE').format(DateTime.now()) == day;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTraditionalChinese ? chineseDay : day,
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              Text(
                time.toString(),
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
