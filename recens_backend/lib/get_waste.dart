import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';

Future<Response> getWasteHandler(Request request) async {
  final params = request.url.queryParameters;
  final monthCount = (int.tryParse(params['months'] ?? '6') ?? 6).clamp(1, 12);

  final conn = await openDb();
  try {
    // ── 1. Spoiled items per month ─────────────────────────────────────────
    // Last status per item per month; count those ending as 'spoiled'
    final spoiledRows = await conn.execute('''
      SELECT yr, mo, COUNT(*) AS spoiled_count
      FROM (
        SELECT
          YEAR(created_at)  AS yr,
          MONTH(created_at) AS mo,
          status,
          ROW_NUMBER() OVER (
            PARTITION BY item_name, YEAR(created_at), MONTH(created_at)
            ORDER BY created_at DESC
          ) AS rn
        FROM predictions_log
        WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL :months MONTH)
      ) sub
      WHERE rn = 1 AND status = 'spoiled'
      GROUP BY yr, mo
      ORDER BY yr DESC, mo DESC
    ''', {'months': monthCount});

    // ── 2. "Left out" = items deleted while still good ────────────────────
    // food_detections_log action='deleted' means removed from fridge.
    // Cross-reference with predictions_log: if the last known status was
    // NOT 'spoiled' or 'danger', the item was wasted outside the fridge.
    final leftOutRows = await conn.execute('''
      SELECT
        YEAR(fdl.created_at)  AS yr,
        MONTH(fdl.created_at) AS mo,
        COUNT(*)              AS left_out_count
      FROM food_detections_log fdl
      LEFT JOIN (
        SELECT item_name, status,
               ROW_NUMBER() OVER (
                 PARTITION BY item_name
                 ORDER BY created_at DESC
               ) AS rn
        FROM predictions_log
      ) pl ON pl.item_name = fdl.item_name AND pl.rn = 1
      WHERE fdl.created_at >= DATE_SUB(CURDATE(), INTERVAL :months MONTH)
        AND fdl.action = 'deleted'
        AND (pl.status IS NULL OR pl.status NOT IN ('spoiled', 'danger'))
      GROUP BY yr, mo
      ORDER BY yr DESC, mo DESC
    ''', {'months': monthCount});

    // ── 3. Total distinct items tracked per month ─────────────────────────
    final totalRows = await conn.execute('''
      SELECT
        YEAR(created_at)          AS yr,
        MONTH(created_at)         AS mo,
        COUNT(DISTINCT item_name) AS total_items
      FROM predictions_log
      WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL :months MONTH)
      GROUP BY yr, mo
      ORDER BY yr DESC, mo DESC
    ''', {'months': monthCount});

    // ── Build keyed maps ──────────────────────────────────────────────────
    Map<String, int> keyedInt(dynamic rows, String field) {
      final map = <String, int>{};
      for (final row in rows.rows) {
        final yr = row.colByName('yr')?.toString() ?? '';
        final mo = row.colByName('mo')?.toString() ?? '';
        map['$yr-$mo'] =
            int.tryParse(row.colByName(field)?.toString() ?? '0') ?? 0;
      }
      return map;
    }

    final spoiledMap = keyedInt(spoiledRows, 'spoiled_count');
    final leftOutMap = keyedInt(leftOutRows, 'left_out_count');
    final totalMap   = keyedInt(totalRows,   'total_items');

    // ── Build ordered month list (newest → oldest) ────────────────────────
    final now = DateTime.now();
    final monthList = <Map<String, dynamic>>[];

    for (int i = 0; i < monthCount; i++) {
      final dt      = DateTime(now.year, now.month - i, 1);
      final yr      = dt.year;
      final mo      = dt.month;
      final key     = '$yr-$mo';
      final spoiled = spoiledMap[key] ?? 0;
      final leftOut = leftOutMap[key] ?? 0;
      final total   = totalMap[key]   ?? 0;
      final waste   = total > 0
          ? ((spoiled + leftOut) / total * 1000).round() / 1000.0
          : 0.0;

      monthList.add({
        'label':          _monthLabel(yr, mo),
        'month':          mo,
        'year':           yr,
        'spoiled_count':  spoiled,
        'left_out_count': leftOut,
        'total_items':    total,
        'waste_rate':     waste,
      });
    }

    // ── Deltas (current vs previous month) ────────────────────────────────
    for (int i = 0; i < monthList.length - 1; i++) {
      monthList[i]['spoiled_delta'] =
          (monthList[i]['spoiled_count'] as int) -
          (monthList[i + 1]['spoiled_count'] as int);
      monthList[i]['left_out_delta'] =
          (monthList[i]['left_out_count'] as int) -
          (monthList[i + 1]['left_out_count'] as int);
    }
    if (monthList.isNotEmpty) {
      monthList.last['spoiled_delta']  ??= 0;
      monthList.last['left_out_delta'] ??= 0;
    }

    // ── Summary ───────────────────────────────────────────────────────────
    final spoiledCounts = monthList.map((m) => m['spoiled_count'] as int).toList();
    final leftOutCounts = monthList.map((m) => m['left_out_count'] as int).toList();

    final minSpoiled = spoiledCounts.isEmpty ? 0 : spoiledCounts.reduce((a, b) => a < b ? a : b);
    final maxSpoiled = spoiledCounts.isEmpty ? 0 : spoiledCounts.reduce((a, b) => a > b ? a : b);
    final bestIdx    = spoiledCounts.isEmpty ? 0 : spoiledCounts.indexOf(minSpoiled);
    final worstIdx   = spoiledCounts.isEmpty ? 0 : spoiledCounts.indexOf(maxSpoiled);

    final avgSpoiled = spoiledCounts.isEmpty ? 0.0
        : (spoiledCounts.reduce((a, b) => a + b) / spoiledCounts.length * 10).round() / 10.0;
    final avgLeftOut = leftOutCounts.isEmpty ? 0.0
        : (leftOutCounts.reduce((a, b) => a + b) / leftOutCounts.length * 10).round() / 10.0;

    final thisMonthSpoiled = monthList.isNotEmpty ? (monthList.first['spoiled_count'] as int) : 0;
    final totalSaved = (maxSpoiled - thisMonthSpoiled).clamp(0, 999);

    final summary = {
      'best_month':  monthList.isNotEmpty ? monthList[bestIdx]['label']  : '',
      'worst_month': monthList.isNotEmpty ? monthList[worstIdx]['label'] : '',
      'avg_spoiled':  avgSpoiled,
      'avg_left_out': avgLeftOut,
      'total_saved':  totalSaved,
    };

    return Response.ok(
      jsonEncode({'months': monthList, 'summary': summary}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e, st) {
    print('getWasteHandler error: $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  } finally {
    await conn.close();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _monthLabel(int year, int month) =>
    '${_monthNames[month - 1]} $year';