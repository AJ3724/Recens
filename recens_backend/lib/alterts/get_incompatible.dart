import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db.dart';

/// GET /get_incompatible
/// Reads proximity alerts directly from pending_alerts.
Future<Response> getIncompatibleHandler(Request request) async {
  try {
    final conn = await openDb();

    final result = await conn.execute(
      '''
      SELECT
        pa.id,
        pa.item_name,
        pa.alert_level,
        pa.created_at
      FROM   pending_alerts pa
      WHERE  pa.alert_type = 'incompatible'
        AND  pa.user_response IS NULL
      ORDER  BY pa.created_at DESC
      ''',
    );

    final List<Map<String, dynamic>> alerts = [];

    for (final row in result.rows) {
      final rawName = row.colByName('item_name')?.toString() ?? '';
      final level   = row.colByName('alert_level')?.toString() ?? '1';

      // Parse "itemA & itemB" — adjust delimiter if your Flask uses a different one
      final parts = rawName.split(' & ');
      final itemA = parts.isNotEmpty ? parts[0].trim() : rawName;
      final itemB = parts.length > 1  ? parts[1].trim() : '';

      final title = itemB.isNotEmpty
          ? '$itemA & $itemB — incompatible'
          : '$itemA — incompatible';

      final description = _buildDescription(itemA, itemB, level);

      alerts.add({
        'id':          row.colByName('id')?.toString() ?? '',
        'item_a':      itemA,
        'item_b':      itemB,
        'title':       title,
        'description': description,
        'severity':    _levelToSeverity(level),
        'detected_at': _formatTimestamp(
            row.colByName('created_at')?.toString() ?? ''),
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

String _levelToSeverity(String level) {
  switch (level) {
    case '3':  return 'high';
    case '2':  return 'medium';
    default:   return 'low';
  }
}

String _buildDescription(String itemA, String itemB, String level) {
  if (itemB.isEmpty) {
    return '$itemA should not be stored in its current position.';
  }
  final severity = level == '3' ? 'strongly' : 'not recommended to';
  return '$itemA and $itemB are $severity stored together — '
      'they may accelerate each other\'s spoilage.';
}

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