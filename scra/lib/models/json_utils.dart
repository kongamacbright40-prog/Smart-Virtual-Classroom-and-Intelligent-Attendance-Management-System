/// JSON parsing helpers shared by every model.
///
/// Backend payloads are expected to use `snake_case` keys (FastAPI /
/// Pydantic default), ISO-8601 timestamps and string enum values.
typedef Json = Map<String, dynamic>;

abstract final class JsonX {
  static DateTime date(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw FormatException('Invalid date value: $value');
  }

  static DateTime? dateOrNull(Object? value) =>
      value == null ? null : date(value);

  static String? isoOrNull(DateTime? value) => value?.toIso8601String();

  static double toDouble(Object? value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int toInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static List<String> stringList(Object? value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];

  static List<T> list<T>(Object? value, T Function(Json json) fromJson) =>
      value is List
          ? value.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : <T>[];

  static Json map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  /// Looks up an enum by its `name`, falling back to [fallback].
  static T enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
