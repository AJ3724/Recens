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
      SELECT id, item_name, message, created_at
      FROM   pending_alerts
      ORDER  BY created_at DESC
      ''',
    );

    final List<Map<String, dynamic>> alerts = [];

    for (final row in result.rows) {
      final itemName  = row.colByName('item_name')?.toString()  ?? '';
      final message   = row.colByName('message')?.toString()    ?? '';
      final createdAt = row.colByName('created_at')?.toString() ?? '';

      alerts.add({
        'id':          row.colByName('id')?.toString() ?? '',
        'item_a':      itemName,
        'item_b':      '',
        'title':       '$itemName — incompatible alert',
        'description': message.isNotEmpty
            ? message
            : 'This item may cause storage issues.',
        'detected_at': _formatTimestamp(createdAt),
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