import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db.dart';

/// GET /get_incompatible
/// Reads from pending_alerts and returns items as incompatible-style alerts.
Future<Response> getIncompatibleHandler(Request request) async {
  try {
    final conn = await openDb();

    final result = await conn.execute(
  '''
  SELECT id, item_a, item_b, zone, reason, severity, detected_at
  FROM   proximity_warnings
  ORDER  BY detected_at DESC
  ''',
);

    final List<Map<String, dynamic>> alerts = [];

    for (final row in result.rows) {
  final itemA    = row.colByName('item_a')?.toString()    ?? '';
  final itemB    = row.colByName('item_b')?.toString()    ?? '';
  final reason   = row.colByName('reason')?.toString()    ?? '';
  final severity = row.colByName('severity')?.toString()  ?? '';

  alerts.add({
    'id':          row.colByName('id')?.toString() ?? '',
    'item_a':      itemA,
    'item_b':      itemB,
    'title':       '$itemA & $itemB — incompatible',
    'description': reason,
    'severity':    severity,
    'detected_at': _formatTimestamp(row.colByName('detected_at')?.toString() ?? ''),
    'type':        'incompatible',
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

String _formatTimestamp(String raw) {
  try {
    final dt = DateTime.parse(raw);
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day  = dt.day.toString().padLeft(2, '0');
    final mon  = months[dt.month];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min  = dt.minute.toString().padLeft(2, '0');
    return '$day $mon · $hour:$min';
  } catch (_) {
    return raw;
  }
}