import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import '../db.dart';

Future<Response> getInsightsHandler(Request request) async {
  final conn = await openDb();
  try {
    final result = await conn.execute(
      'SELECT insight_type, value, confidence, generated_at '
      'FROM user_insights '
      'ORDER BY generated_at DESC',
    );

    if (result.rows.isEmpty) {
      return Response.ok(
        jsonEncode({'available': false}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final Map<String, dynamic> insights = {'available': true};

    for (final row in result.rows) {
      final type      = row.colByName('insight_type')?.toString() ?? '';
      final value     = row.colByName('value')?.toString()        ?? '';
      final conf      = double.tryParse(row.colByName('confidence')?.toString() ?? '0') ?? 0.0;
      final genAt     = row.colByName('generated_at')?.toString() ?? '';

      // Parse JSON fields back into lists
      if (type == 'top_items' || type == 'wasted_items' || type == 'fast_consumed') {
        try {
          insights[type] = jsonDecode(value);
        } catch (_) {
          insights[type] = <String>[];
        }
      } else {
        insights[type] = value;
      }

      insights['confidence']   = conf;
      insights['generated_at'] = genAt;
    }

    return Response.ok(
      jsonEncode(insights),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e, stack) {
    print('getInsightsHandler error: $e\n$stack');
    return Response.internalServerError(
      body:    jsonEncode({'error': 'DB error: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  } finally {
    await conn.close();
  }
}