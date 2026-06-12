import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db.dart';

/// GET /get_alerts
Future<Response> getAlertsHandler(Request request) async {
  final List<Map<String, dynamic>> alerts = [];
  final now = _formatNow();

  try {
    final conn = await openDb();

    // ── Spoiled ───────────────────────────────────────────────────────────────
    var result = await conn.execute(
      "SELECT item_name, life_remaining FROM predictions WHERE status = 'spoiled' AND (response IS NULL OR response NOT IN ('returned', 'finished'))",
    );
    for (final row in result.rows) {
      final name = _capitalize(row.colByName('item_name')?.toString() ?? '');
      alerts.add({
        'title':       '$name — Spoiled',
        'description': 'This item has spoiled. Remove it from the fridge immediately.',
        'time':        now,
        'type':        'spoiled',
      });
    }

    // ── Danger ────────────────────────────────────────────────────────────────
    result = await conn.execute(
      "SELECT item_name, life_remaining FROM predictions WHERE status = 'danger' AND (response IS NULL OR response NOT IN ('returned', 'finished'))",
    );
    for (final row in result.rows) {
      final name    = _capitalize(row.colByName('item_name')?.toString() ?? '');
      final days    = double.tryParse(row.colByName('life_remaining')?.toString() ?? '0') ?? 0.0;
      final timeStr = _formatTime(days);
      alerts.add({
        'title':       '$name — Expiring Soon',
        'description': '$timeStr left. Use it soon before it spoils.',
        'time':        now,
        'type':        'danger',
      });
    }

    // ── Good ──────────────────────────────────────────────────────────────────
    result = await conn.execute(
      "SELECT item_name, life_remaining FROM predictions WHERE status = 'good' AND (response IS NULL OR response NOT IN ('returned', 'finished'))",
    );
    for (final row in result.rows) {
      final name    = _capitalize(row.colByName('item_name')?.toString() ?? '');
      final days    = double.tryParse(row.colByName('life_remaining')?.toString() ?? '0') ?? 0.0;
      final timeStr = _formatTime(days);
      alerts.add({
        'title':       '$name — Good',
        'description': '$timeStr left. Item is fresh and in good condition.',
        'time':        now,
        'type':        'good',
      });
    }

    // ── Acceptable ────────────────────────────────────────────────────────────
    result = await conn.execute(
      "SELECT item_name, life_remaining FROM predictions WHERE status = 'acceptable' AND (response IS NULL OR response NOT IN ('returned', 'finished'))",
    );
    for (final row in result.rows) {
      final name    = _capitalize(row.colByName('item_name')?.toString() ?? '');
      final days    = double.tryParse(row.colByName('life_remaining')?.toString() ?? '0') ?? 0.0;
      final timeStr = _formatTime(days);
      alerts.add({
        'title':       '$name — Acceptable',
        'description': '$timeStr left. Still usable but monitor it closely.',
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

String _formatTime(double days) {
  if (days < 1.0) {
    final hours = (days * 24).round();
    return '${hours}h';
  }
  return '${days.toStringAsFixed(1)} days';
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);