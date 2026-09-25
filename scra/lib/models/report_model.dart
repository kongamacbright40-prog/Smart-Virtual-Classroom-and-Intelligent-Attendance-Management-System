import 'json_utils.dart';

enum ReportType {
  attendance('attendance', 'Attendance'),
  participation('participation', 'Participation'),
  course('course', 'Course'),
  institution('institution', 'Institution');

  const ReportType(this.value, this.label);

  final String value;
  final String label;

  static ReportType fromJson(Object? value) => ReportType.values.firstWhere(
    (e) => e.value == value,
    orElse: () => ReportType.attendance,
  );
}

enum ReportFormat {
  pdf('pdf', 'PDF Document (.pdf)'),
  xlsx('xlsx', 'Excel Spreadsheet (.xlsx)'),
  csv('csv', 'CSV Archive (.csv)');

  const ReportFormat(this.value, this.label);

  final String value;
  final String label;
}

/// One point of a chart series (e.g. week → attendance %).
class ReportDataPoint {
  const ReportDataPoint({required this.label, required this.value, this.extra});

  final String label;
  final double value;

  /// Optional secondary value, e.g. check-in count.
  final double? extra;

  factory ReportDataPoint.fromJson(Json json) => ReportDataPoint(
    label: json['label'] as String,
    value: JsonX.toDouble(json['value']),
    extra: json['extra'] == null ? null : JsonX.toDouble(json['extra']),
  );

  Json toJson() => {'label': label, 'value': value, 'extra': extra};
}

/// A labelled breakdown row, e.g. a faculty or course with its rate.
class ReportBreakdown {
  const ReportBreakdown({
    required this.id,
    required this.label,
    required this.value,
    this.subtitle,
    this.meta = const {},
  });

  final String id;
  final String label;
  final double value;
  final String? subtitle;
  final Map<String, String> meta;

  factory ReportBreakdown.fromJson(Json json) => ReportBreakdown(
    id: json['id'].toString(),
    label: json['label'] as String,
    value: JsonX.toDouble(json['value']),
    subtitle: json['subtitle'] as String?,
    meta: JsonX.map(json['meta']).map((k, v) => MapEntry(k, v.toString())),
  );

  Json toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'subtitle': subtitle,
    'meta': meta,
  };
}

class ReportModel {
  const ReportModel({
    required this.id,
    required this.title,
    required this.type,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    this.scopeId,
    this.metrics = const {},
    this.trend = const [],
    this.previousTrend = const [],
    this.breakdown = const [],
  });

  final String id;
  final String title;
  final ReportType type;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Course / department / lecturer id the report is scoped to.
  final String? scopeId;

  /// Headline numbers, e.g. `overall_rate`, `sessions`, `at_risk`.
  final Map<String, double> metrics;
  final List<ReportDataPoint> trend;
  final List<ReportDataPoint> previousTrend;
  final List<ReportBreakdown> breakdown;

  double metric(String key, [double fallback = 0]) => metrics[key] ?? fallback;

  factory ReportModel.fromJson(Json json) => ReportModel(
    id: json['id'].toString(),
    title: json['title'] as String,
    type: ReportType.fromJson(json['type']),
    generatedAt: JsonX.date(json['generated_at']),
    periodStart: JsonX.date(json['period_start']),
    periodEnd: JsonX.date(json['period_end']),
    scopeId: json['scope_id'] as String?,
    metrics: JsonX.map(json['metrics'])
        .map((k, v) => MapEntry(k, JsonX.toDouble(v))),
    trend: JsonX.list(json['trend'], ReportDataPoint.fromJson),
    previousTrend: JsonX.list(json['previous_trend'], ReportDataPoint.fromJson),
    breakdown: JsonX.list(json['breakdown'], ReportBreakdown.fromJson),
  );

  Json toJson() => {
    'id': id,
    'title': title,
    'type': type.value,
    'generated_at': generatedAt.toIso8601String(),
    'period_start': periodStart.toIso8601String(),
    'period_end': periodEnd.toIso8601String(),
    'scope_id': scopeId,
    'metrics': metrics,
    'trend': trend.map((e) => e.toJson()).toList(),
    'previous_trend': previousTrend.map((e) => e.toJson()).toList(),
    'breakdown': breakdown.map((e) => e.toJson()).toList(),
  };
}
