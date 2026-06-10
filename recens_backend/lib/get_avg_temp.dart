import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';

// ─────────────────────────────────────────────────────────────────────────────
// /get_avg_temp
//
// Query params:
//   mode   – 'hourly' | 'daily' | 'weekly' | 'monthly'  (default: 'hourly')
//   date   – YYYY-MM-DD  (used for hourly / daily modes, default: today)
//   week   – ISO week number (used for weekly mode, default: current week)
//   year   – 4-digit year (used with week / monthly, default: current year)
//   months – how many months back for monthly mode (default: 6, max: 12)
//
// Response shape (all modes share the same envelope):
// {
//   "mode":   "hourly",
//   "label":  "9 Jun 2025",
//   "safe_min": 2.0,
//   "safe_max": 5.0,
//   "points": [
//     { "label": "00:00", "avg": 3.8, "min": 3.5, "max": 4.1 },
//     ...
//   ],
//   "overall_avg": 3.9,
//   "overall_min": 3.5,
//   "overall_max": 4.3,
//   "in_range_pct": 97.2    // % of readings within safe range
// }
// ─────────────────────────────────────────────────────────────────────────────

const double _safeMin = 2.0;
const double _safeMax = 5.0;

Future<Response> getAvgTempHandler(Request request) async {
  final params = request.url.queryParameters;
  final mode   = params['mode'] ?? 'hourly';

  final conn   = await openDb();
  try {
    late List<Map<String, dynamic>> points;
    late String label;

    switch (mode) {
      case 'hourly':
        final dateStr = params['date'] ?? _todayStr();
        label  = dateStr;
        points = await _hourly(conn, dateStr);
        break;

      case 'daily':
        // Returns all days in the calendar month of the given date.
        final dateStr = params['date'] ?? _todayStr();
        final dt      = DateTime.parse(dateStr);
        label  = '${_monthNames[dt.month - 1]} ${dt.year}';
        points = await _daily(conn, dt.year, dt.month);
        break;

      case 'weekly':
        final year = int.tryParse(params['year'] ?? '') ?? DateTime.now().year;
        final week = int.tryParse(params['week'] ?? '')
            ?? _isoWeekNumber(DateTime.now());
        label  = 'Week $week, $year';
        points = await _weekly(conn, year, week);
        break;

      case 'monthly':
        final months = (int.tryParse(params['months'] ?? '6') ?? 6)
            .clamp(1, 12);
        label  = 'Last $months months';
        points = await _monthly(conn, months);
        break;

      default:
        return Response.badRequest(
          body: jsonEncode({'error': 'Unknown mode "$mode"'}),
          headers: {'Content-Type': 'application/json'},
        );
    }

    // ── Aggregate stats ──────────────────────────────────────────────────────
    double overallAvg = 0, overallMin = 999, overallMax = -999;
    int inRangeCount = 0;

    if (points.isNotEmpty) {
      double sum = 0;
      for (final p in points) {
        final avg = (p['avg'] as num).toDouble();
        final mn  = (p['min'] as num).toDouble();
        final mx  = (p['max'] as num).toDouble();
        sum += avg;
        if (mn < overallMin) overallMin = mn;
        if (mx > overallMax) overallMax = mx;
        if (avg >= _safeMin && avg <= _safeMax) inRangeCount++;
      }
      overallAvg = sum / points.length;
    } else {
      overallMin = 0;
      overallMax = 0;
    }

    final inRangePct = points.isNotEmpty
        ? (inRangeCount / points.length * 1000).round() / 10.0
        : 0.0;

    return Response.ok(
      jsonEncode({
        'mode':        mode,
        'label':       label,
        'safe_min':    _safeMin,
        'safe_max':    _safeMax,
        'points':      points,
        'overall_avg': _round1(overallAvg),
        'overall_min': overallMin == 999  ? 0.0 : _round1(overallMin),
        'overall_max': overallMax == -999 ? 0.0 : _round1(overallMax),
        'in_range_pct': inRangePct,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  } finally {
    await conn.close();
  }
}

// ── Query builders ────────────────────────────────────────────────────────────

/// One row per hour (0-23) for the given calendar day.
Future<List<Map<String, dynamic>>> _hourly(dynamic conn, String dateStr) async {
  final rows = await conn.execute('''
    SELECT
      HOUR(recorded_at)         AS hr,
      ROUND(AVG(temperature),1) AS avg_t,
      ROUND(MIN(temperature),1) AS min_t,
      ROUND(MAX(temperature),1) AS max_t
    FROM temp_readings_raw
    WHERE DATE(recorded_at) = :d
    GROUP BY hr
    ORDER BY hr
  ''', {'d': dateStr});

  return _mapRows(rows, (row) {
    final hr = int.parse(row.colByName('hr')?.toString() ?? '0');
    return {
      'label': '${hr.toString().padLeft(2, '0')}:00',
      'avg':   _parseDouble(row.colByName('avg_t')),
      'min':   _parseDouble(row.colByName('min_t')),
      'max':   _parseDouble(row.colByName('max_t')),
    };
  });
}

/// One row per day in the given year/month.
Future<List<Map<String, dynamic>>> _daily(
    dynamic conn, int year, int month) async {
  final rows = await conn.execute('''
    SELECT
      DAY(recorded_at)          AS dy,
      ROUND(AVG(temperature),1) AS avg_t,
      ROUND(MIN(temperature),1) AS min_t,
      ROUND(MAX(temperature),1) AS max_t
    FROM temp_readings_raw
    WHERE YEAR(recorded_at)  = :y
      AND MONTH(recorded_at) = :m
    GROUP BY dy
    ORDER BY dy
  ''', {'y': year, 'm': month});

  return _mapRows(rows, (row) {
    final d = row.colByName('dy')?.toString() ?? '?';
    return {
      'label': d,
      'avg':   _parseDouble(row.colByName('avg_t')),
      'min':   _parseDouble(row.colByName('min_t')),
      'max':   _parseDouble(row.colByName('max_t')),
    };
  });
}

/// One row per day of the given ISO week.
Future<List<Map<String, dynamic>>> _weekly(
    dynamic conn, int year, int week) async {
  // MySQL: YEARWEEK with mode 3 = ISO week
  final rows = await conn.execute('''
    SELECT
      DAYOFWEEK(recorded_at)    AS dow,
      DATE(recorded_at)         AS dt,
      ROUND(AVG(temperature),1) AS avg_t,
      ROUND(MIN(temperature),1) AS min_t,
      ROUND(MAX(temperature),1) AS max_t
    FROM temp_readings_raw
    WHERE YEARWEEK(recorded_at, 3) = YEARWEEK(
      STR_TO_DATE(CONCAT(:y, ' ', :w, ' 1'), '%X %V %w'), 3
    )
    GROUP BY dt, dow
    ORDER BY dt
  ''', {'y': year.toString(), 'w': week.toString().padLeft(2, '0')});

  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return _mapRows(rows, (row) {
    final dow = int.tryParse(row.colByName('dow')?.toString() ?? '1') ?? 1;
    return {
      'label': dayNames[dow - 1],
      'avg':   _parseDouble(row.colByName('avg_t')),
      'min':   _parseDouble(row.colByName('min_t')),
      'max':   _parseDouble(row.colByName('max_t')),
    };
  });
}

/// One row per calendar month for the last N months.
Future<List<Map<String, dynamic>>> _monthly(
    dynamic conn, int monthCount) async {
  final rows = await conn.execute('''
    SELECT
      YEAR(recorded_at)         AS yr,
      MONTH(recorded_at)        AS mo,
      ROUND(AVG(temperature),1) AS avg_t,
      ROUND(MIN(temperature),1) AS min_t,
      ROUND(MAX(temperature),1) AS max_t
    FROM temp_readings_raw
    WHERE recorded_at >= DATE_SUB(CURDATE(), INTERVAL :n MONTH)
    GROUP BY yr, mo
    ORDER BY yr ASC, mo ASC
  ''', {'n': monthCount});

  return _mapRows(rows, (row) {
    final yr = int.tryParse(row.colByName('yr')?.toString() ?? '0') ?? 0;
    final mo = int.tryParse(row.colByName('mo')?.toString() ?? '1') ?? 1;
    return {
      'label': '${_monthShort[mo - 1]} $yr',
      'avg':   _parseDouble(row.colByName('avg_t')),
      'min':   _parseDouble(row.colByName('min_t')),
      'max':   _parseDouble(row.colByName('max_t')),
    };
  });
}

// ── Utility ───────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _mapRows(
    dynamic result, Map<String, dynamic> Function(dynamic row) mapper) {
  final list = <Map<String, dynamic>>[];
  for (final row in result.rows) {
    list.add(mapper(row));
  }
  return list;
}

double _parseDouble(dynamic v) =>
    double.tryParse(v?.toString() ?? '0') ?? 0.0;

double _round1(double v) => (v * 10).round() / 10.0;

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
}

/// Returns the ISO 8601 week number for a given date.
int _isoWeekNumber(DateTime date) {
  final dayOfYear =
      date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  final weekday  = date.weekday; // 1=Mon … 7=Sun
  return ((dayOfYear - weekday + 10) / 7).floor();
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];