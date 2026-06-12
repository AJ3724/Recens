import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db.dart';

/// GET /get_temp_spikes
/// Returns all temperature spike alerts regardless of user_response.
Future<Response> getTempSpikesHandler(Request request) async {
  try {
    final conn = await openDb();

    final result = await conn.execute(
      '''
      SELECT
        pa.id                AS alert_id,
        pa.item_name,
        pa.alert_level,
        pa.created_at        AS alert_created_at,
        fd.temp_spike_start,
        fd.time_in_spike,
        fd.zone
      FROM   pending_alerts pa
      LEFT JOIN food_detections fd
             ON fd.id = pa.food_detection_id
      WHERE  pa.alert_type = 'temperature_spike'
      ORDER  BY pa.created_at DESC
      ''',
    );

    final List<Map<String, dynamic>> spikes = [];

    for (final row in result.rows) {
      final itemName    = row.colByName('item_name')?.toString()        ?? '';
      final alertLevel  = int.tryParse(
              row.colByName('alert_level')?.toString() ?? '1') ?? 1;
      final spikeStart  = row.colByName('temp_spike_start')?.toString() ?? '';
      final timeInSpike = int.tryParse(
              row.colByName('time_in_spike')?.toString() ?? '0') ?? 0;
      final zone        = row.colByName('zone')?.toString()             ?? 'unknown';
      final createdAt   = row.colByName('alert_created_at')?.toString() ?? '';

      spikes.add({
        'id':             row.colByName('alert_id')?.toString() ?? '',
        'item_name':      itemName,
        'alert_level':    alertLevel,
        'severity':       _levelToSeverity(alertLevel),
        'spike_start':    _formatTimestamp(spikeStart),
        'time_in_spike':  timeInSpike,
        'duration_label': _durationLabel(timeInSpike),
        'zone':           zone,
        'title':          _buildTitle(itemName, alertLevel),
        'description':    _buildDescription(itemName, timeInSpike, zone),
        'detected_at':    _formatTimestamp(createdAt),
      });
    }

    await conn.close();

    return Response.ok(
      jsonEncode(spikes),
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

String _levelToSeverity(int level) {
  switch (level) {
    case 3:  return 'critical';
    case 2:  return 'warning';
    default: return 'info';
  }
}

String _buildTitle(String itemName, int level) {
  if (itemName.isEmpty) {
    return level == 3 ? 'Critical Temperature Spike' : 'Temperature Spike Detected';
  }
  final name = _capitalize(itemName);
  return level == 3 ? '$name — Critical Temp Spike' : '$name — Temperature Spike';
}

String _buildDescription(String itemName, int minutes, String zone) {
  final duration = _durationLabel(minutes);
  final loc      = zone == 'unknown' ? 'the fridge' : 'zone $zone';
  final item     = itemName.isEmpty ? 'An item' : _capitalize(itemName);
  return '$item experienced a temperature spike lasting $duration in $loc. '
      'This may have accelerated spoilage — check its condition.';
}

String _durationLabel(int minutes) {
  if (minutes <= 0) return 'unknown duration';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s.replaceAll('_', ' ').split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

String _formatTimestamp(String raw) {
  if (raw.isEmpty) return '—';
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