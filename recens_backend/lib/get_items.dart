import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';

/// GET /get_items
///
/// Returns every row from the `predictions` table as a JSON array.
Future<Response> getItemsHandler(Request request) async {
  try {
    final conn   = await openDb();
    final result = await conn.execute('SELECT * FROM predictions');

    final items = result.rows.map((row) {
      // Build a map from every column name → value
      final map = <String, dynamic>{};
      for (final col in result.cols) {
        map[col.name] = row.colByName(col.name);
      }
      return map;
    }).toList();

    await conn.close();

    return Response.ok(
      jsonEncode(items),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body:    jsonEncode({'error': 'DB error: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}