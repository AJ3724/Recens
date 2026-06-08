import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';

/// GET  /get_expiry
/// Returns all items from `predictions` that still need expiry confirmation.
///
/// POST /set_expiry
/// Body: { "id": <int>, "initial_life": <double> }
/// Updates the item's initial_life in the database.

Future<Response> getExpiryHandler(Request request) async {
  try {
    final conn   = await openDb();
    final result = await conn.execute('SELECT * FROM predictions WHERE confirmation = 0');

    final items = result.rows.map((row) {
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

Future<Response> setExpiryHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final id          = data['id'];
    final initialLife = data['initial_life'];

    if (id == null || initialLife == null) {
      return Response.badRequest(
        body:    jsonEncode({'error': 'id and initial_life are required'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final conn = await openDb();
    await conn.execute(
      'UPDATE predictions SET initial_life = :life , confirmation = 1 WHERE id = :id',
      {'life': initialLife, 'id': id},
    );
    await conn.close();

    return Response.ok(
      jsonEncode({'success': true}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body:    jsonEncode({'error': 'DB error: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}