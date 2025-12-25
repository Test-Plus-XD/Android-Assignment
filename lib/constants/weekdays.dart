/// Weekday Constants
///
/// This file contains weekday names in various formats with bilingual support.

class Weekdays {
  /// Short English weekday names (3 letters)
  static const List<String> enShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Full English weekday names
  static const List<String> enFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Traditional Chinese weekday names
  static const List<String> tc = [
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
    '星期日',
  ];

  /// Short Traditional Chinese weekday names
  static const List<String> tcShort = [
    '週一',
    '週二',
    '週三',
    '週四',
    '週五',
    '週六',
    '週日',
  ];

  /// Get weekday name by index (0 = Monday, 6 = Sunday)
  static String getName(
    int index, {
    bool isTraditionalChinese = false,
    bool useShortForm = false,
  }) {
    if (index < 0 || index > 6) {
      throw ArgumentError('Index must be between 0 and 6');
    }

    if (isTraditionalChinese) {
      return useShortForm ? tcShort[index] : tc[index];
    } else {
      return useShortForm ? enShort[index] : enFull[index];
    }
  }

  /// Get all weekday names based on language preference
  static List<String> getAll({
    bool isTraditionalChinese = false,
    bool useShortForm = false,
  }) {
    if (isTraditionalChinese) {
      return useShortForm ? tcShort : tc;
    } else {
      return useShortForm ? enShort : enFull;
    }
  }

  /// Convert DateTime weekday to our index (Monday = 0)
  /// DateTime.weekday: Monday = 1, Sunday = 7
  static int dateTimeToIndex(int dateTimeWeekday) {
    return dateTimeWeekday - 1;
  }

  /// Convert our index to DateTime weekday (Monday = 1, Sunday = 7)
  static int indexToDateTime(int index) {
    return index + 1;
  }

  /// Get current weekday name
  static String today({
    bool isTraditionalChinese = false,
    bool useShortForm = false,
  }) {
    final now = DateTime.now();
    final index = dateTimeToIndex(now.weekday);
    return getName(
      index,
      isTraditionalChinese: isTraditionalChinese,
      useShortForm: useShortForm,
    );
  }

  /// Check if a given index represents a weekend (Saturday or Sunday)
  static bool isWeekend(int index) {
    return index == 5 || index == 6; // Saturday or Sunday
  }

  /// Get index from English name (case-insensitive)
  static int? indexFromEnglish(String name) {
    final lowerName = name.toLowerCase();

    // Check full names
    for (int i = 0; i < enFull.length; i++) {
      if (enFull[i].toLowerCase() == lowerName) {
        return i;
      }
    }

    // Check short names
    for (int i = 0; i < enShort.length; i++) {
      if (enShort[i].toLowerCase() == lowerName) {
        return i;
      }
    }

    return null;
  }

  /// Get index from Chinese name
  static int? indexFromChinese(String name) {
    // Check full names
    for (int i = 0; i < tc.length; i++) {
      if (tc[i] == name) {
        return i;
      }
    }

    // Check short names
    for (int i = 0; i < tcShort.length; i++) {
      if (tcShort[i] == name) {
        return i;
      }
    }

    return null;
  }
}
