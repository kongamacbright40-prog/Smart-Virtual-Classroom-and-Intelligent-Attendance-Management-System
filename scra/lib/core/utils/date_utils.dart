/// Date helpers implemented without extra dependencies.
abstract final class AppDateUtils {
  static const List<String> monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> monthsLong = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> weekdaysShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const List<String> weekdaysLong = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
    'Sunday',
  ];

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime d, {DateTime? now}) =>
      isSameDay(d, now ?? DateTime.now());

  static bool isTomorrow(DateTime d, {DateTime? now}) =>
      isSameDay(d, (now ?? DateTime.now()).add(const Duration(days: 1)));

  static bool isYesterday(DateTime d, {DateTime? now}) =>
      isSameDay(d, (now ?? DateTime.now()).subtract(const Duration(days: 1)));

  /// Monday of the week containing [d].
  static DateTime startOfWeek(DateTime d) =>
      dateOnly(d).subtract(Duration(days: d.weekday - DateTime.monday));

  /// The seven days (Mon–Sun) of the week containing [d].
  static List<DateTime> weekDays(DateTime d) {
    final start = startOfWeek(d);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  /// Minutes since midnight for a `HH:mm` string, or null if malformed.
  static int? parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  static String minutesToHhmm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Combines a date with a `HH:mm` time string.
  static DateTime combine(DateTime date, String hhmm) {
    final minutes = parseMinutes(hhmm) ?? 0;
    return DateTime(date.year, date.month, date.day, minutes ~/ 60,
        minutes % 60);
  }
}
