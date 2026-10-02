import 'dart:ui';

/// One pen stroke on the class whiteboard. Coordinates and width are
/// fractions of the board size (0..1) so the board scales to any screen.
class BoardStroke {
  BoardStroke({
    required this.id,
    required this.color,
    required this.width,
    List<Offset>? points,
  }) : points = points ?? [];

  final String id;

  /// ARGB colour value.
  final int color;

  /// Fraction of the board width.
  final double width;
  final List<Offset> points;
}

/// The lecturer's whiteboard as seen by everyone in the class.
///
/// The lecturer changes it locally and sends the matching messages over the
/// signaling socket; students apply the messages they receive ([apply]).
class Whiteboard {
  /// Board width / height on every device.
  static const double aspectRatio = 16 / 10;

  /// Board background; the eraser paints with this colour.
  static const int background = 0xFF111827;

  bool active = false;
  final List<BoardStroke> strokes = [];

  /// The lecturer is sharing their screen (students show the shared screen).
  bool screenSharing = false;

  /// Applies a `board` / `board_state` message. Returns whether it changed.
  bool apply(Map<String, dynamic> message) {
    if (message['type'] == 'board_state') {
      active = message['active'] == true;
      screenSharing = message['screen_on'] == true;
      strokes
        ..clear()
        ..addAll(
          (message['strokes'] is List ? message['strokes'] as List : const [])
              .whereType<Map>()
              .map((m) => _strokeFrom(Map<String, dynamic>.from(m)))
              .whereType<BoardStroke>(),
        );
      return true;
    }
    if (message['type'] != 'board') return false;
    switch (message['op']) {
      case 'screen':
        screenSharing = message['on'] == true;
      case 'show':
        active = true;
      case 'hide':
        active = false;
      case 'clear':
        strokes.clear();
      case 'undo':
        if (strokes.isEmpty) return false;
        strokes.removeLast();
      case 'begin':
        final stroke = _strokeFrom(message);
        if (stroke == null) return false;
        strokes.add(stroke);
      case 'extend':
        final id = message['id'];
        for (final stroke in strokes.reversed) {
          if (stroke.id == id) {
            stroke.points.addAll(parsePoints(message['points']));
            return true;
          }
        }
        return false;
      default:
        return false;
    }
    return true;
  }

  static BoardStroke? _strokeFrom(Map<String, dynamic> m) {
    final id = m['id'];
    final color = m['color'];
    final width = m['width'];
    if (id is! String || color is! int || width is! num) return null;
    return BoardStroke(
      id: id,
      color: color,
      width: width.toDouble(),
      points: parsePoints(m['points']),
    );
  }

  static List<Offset> parsePoints(Object? value) => [
    if (value is List)
      for (final p in value)
        if (p is List && p.length == 2 && p[0] is num && p[1] is num)
          Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
  ];

  static List<List<double>> encodePoints(Iterable<Offset> points) => [
    for (final p in points) [_round(p.dx), _round(p.dy)],
  ];

  static double _round(double v) => (v.clamp(0, 1) * 10000).round() / 10000;
}
