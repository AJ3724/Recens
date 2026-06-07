import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db.dart';

/// GET /get_alerts
///
/// Returns a JSON array of alert objects grouped by status:
///   spoiled     → "Item has expired…"
///   danger      → "X hours/days left…"
///   acceptable  → "Still usable but monitor…"
Future<Response> getAlertsHandler(Request request) async {
  final List<Map<String, dynamic>> alerts = [];
  final now = _formatNow();

  try {
    final conn = await openDb();

    // ── Spoiled ─────────────────────────────────────────────────────────────
    var result = await conn.execute(
      "SELECT item_name FROM predictions WHERE status = 'spoiled'",
    );
    for (final row in result.rows) {
      alerts.add({
        'title':       '${row.colByName('item_name')} spoiled',
        'description': 'Item has expired. Remove from fridge immediately.',
        'time':        now,
        'type':        'spoiled',
      });
    }

    // ── Danger ──────────────────────────────────────────────────────────────
    result = await conn.execute(
      "SELECT item_name, life_remaining FROM predictions WHERE status = 'danger'",
    );
    for (final row in result.rows) {
      final h       = double.tryParse(
                        row.colByName('life_remaining')?.toString() ?? '0',
                      )?.toInt() ?? 0;
      final timeStr = _formatTime(h);
      alerts.add({
        'title':       '${row.colByName('item_name')} expiring soon',
        'description': '$timeStr left. Check your fridge and use it soon.',
        'time':        now,
        'type':        'danger',
      });
    }

    // ── Acceptable ──────────────────────────────────────────────────────────
    result = await conn.execute(
      "SELECT item_name, life_remaining FROM predictions WHERE status = 'acceptable'",
    );
    for (final row in result.rows) {
      final h       = double.tryParse(
                        row.colByName('life_remaining')?.toString() ?? '0',
                      )?.toInt() ?? 0;
      final timeStr = _formatTime(h);
      alerts.add({
        'title':       '${row.colByName('item_name')} — use soon',
        'description': '$timeStr left. Item is still usable but monitor it.',
        'time':        now,
        'type':        'acceptable',
      });
    }

    await conn.close();

    return Response.ok(
      jsonEncode(alerts),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body:    jsonEncode({'error': 'DB error: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Mirrors PHP's  date("d M · H:i")  e.g. "29 May · 14:30"
String _formatNow() {
  final d = DateTime.now();
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day  = d.day.toString().padLeft(2, '0');
  final mon  = months[d.month];
  final hour = d.hour.toString().padLeft(2, '0');
  final min  = d.minute.toString().padLeft(2, '0');
  return '$day $mon · $hour:$min';
}

/// < 24 h → "Xh"  else → "X.X days"
String _formatTime(int hours) {
  if (hours < 24) return '${hours}h';
  final days = (hours / 24).toStringAsFixed(1);
  return '$days days';
}