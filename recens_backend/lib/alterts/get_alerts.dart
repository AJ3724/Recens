import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db.dart';

/// GET /get_alerts
///
/// Returns a JSON array of alert objects grouped by status:
///   critical    → "Item has expired or is critically low…"
///   warning     → "X days left…"
///   active      → "Still usable but monitor…"
Future<Response> getAlertsHandler(Request request) async {
  final List<Map<String, dynamic>> alerts = [];
  final now = _formatNow();

  try {
    final conn = await openDb();

    // ── Critical ─────────────────────────────────────────────────────────────
    var result = await conn.execute(
      "SELECT item_name FROM predictions WHERE status = 'critical'",
    );
    for (final row in result.rows) {
      alerts.add({
        'title':       '${row.colByName('item_name')} — critical',
        'description': 'Item has expired or is critically low. Remove from fridge immediately.',
        'time':        now,
        'type':        'critical',
      });
    }

    // ── Warning ──────────────────────────────────────────────────────────────
    result = await conn.execute(
      "SELECT item_name, life_remaining FROM predictions WHERE status = 'warning'",
    );
    for (final row in result.rows) {
      final days    = double.tryParse(
                        row.colByName('life_remaining')?.toString() ?? '0',
                      ) ?? 0.0;
      final timeStr = _formatTime(days);
      alerts.add({
        'title':       '${row.colByName('item_name')} expiring soon',
        'description': '$timeStr left. Check your fridge and use it soon.',
        'time':        now,
        'type':        'warning',
      });
    }

    // ── Active ───────────────────────────────────────────────────────────────
    result = await conn.execute(
      "SELECT item_name, life_remaining FROM predictions WHERE status = 'active'",
    );
    for (final row in result.rows) {
      final days    = double.tryParse(
                        row.colByName('life_remaining')?.toString() ?? '0',
                      ) ?? 0.0;
      final timeStr = _formatTime(days);
      alerts.add({
        'title':       '${row.colByName('item_name')} — use soon',
        'description': '$timeStr left. Item is still usable but monitor it.',
        'time':        now,
        'type':        'active',
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

/// life_remaining is stored in days (float).
/// < 1 day → "Xh"  else → "X.X days"
String _formatTime(double days) {
  if (days < 1.0) {
    final hours = (days * 24).round();
    return '${hours}h';
  }
  return '${days.toStringAsFixed(1)} days';
}