import 'date_utils.dart';

/// Display formatting helpers used across screens.
abstract final class Formatters {
  /// `10:00 AM`
  static String time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// `10:00 AM` from a `HH:mm` string.
  static String timeFromHhmm(String hhmm) {
    final minutes = AppDateUtils.parseMinutes(hhmm);
    if (minutes == null) return hhmm;
    return time(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));
  }

  /// `10:00 AM — 11:30 AM`
  static String timeRange(DateTime start, DateTime end) =>
      '${time(start)} — ${time(end)}';

  /// `Oct 26, 2025`
  static String date(DateTime d) =>
      '${AppDateUtils.monthsShort[d.month - 1]} ${d.day}, ${d.year}';

  /// `Mon, Oct 26`
  static String shortDate(DateTime d) =>
      '${AppDateUtils.weekdaysShort[d.weekday - 1]}, '
      '${AppDateUtils.monthsShort[d.month - 1]} ${d.day}';

  /// `Oct 26`
  static String dayMonth(DateTime d) =>
      '${AppDateUtils.monthsShort[d.month - 1]} ${d.day}';

  /// `Oct 26, 2025 • 10:00 AM`
  static String dateTime(DateTime d) => '${date(d)} • ${time(d)}';

  /// `Today, 2:00 PM`, `Tomorrow, 10:00 AM` or `Mon, Oct 26, 9:00 AM`.
  static String relativeDay(DateTime d, {DateTime? now}) {
    final t = time(d);
    if (AppDateUtils.isToday(d, now: now)) return 'Today, $t';
    if (AppDateUtils.isTomorrow(d, now: now)) return 'Tomorrow, $t';
    if (AppDateUtils.isYesterday(d, now: now)) return 'Yesterday, $t';
    return '${shortDate(d)}, $t';
  }

  /// `Just now`, `5m ago`, `3h ago`, `2d ago`, or a date.
  static String timeAgo(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(d);
  }

  /// `1h 25m`, `45m`, `58 MIN` style durations.
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  /// `00:42`
  static String countdown(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// `94%` or `94.5%`
  static String percent(double value, {int decimals = 0}) =>
      '${value.toStringAsFixed(decimals)}%';

  /// `1,248`
  static String compactNumber(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}k';
    final s = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  /// Two-letter initials for avatars.
  static String initials(String name) {
    final parts = name
        .replaceAll(RegExp(r'^(Dr|Prof|Mr|Mrs|Ms)\.?\s+'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
