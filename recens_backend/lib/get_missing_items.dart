import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';

/// GET  /get_missing_items
/// Fetches only the items that need a response from the user.
Future<Response> getMissingItemsHandler(Request request) async {
  try {
    final conn   = await openDb();
    
    // 1. We added 'id' so the app knows which alert to update.
    // 2. We explicitly check 'IS NULL' so new alerts show up.
    final result = await conn.execute(
      'SELECT id, item_name FROM pending_alerts '
      'WHERE user_response IS NULL'
    );

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

/// POST /set_response
/// Updates the user's choice and sets the timestamp.
Future<Response> setResponseHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final id = data['id'];
    final userResponse = data['user_response'];

    if (id == null || userResponse == null) {
      return Response.badRequest(
        body:    jsonEncode({'error': 'id and user_response are required'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final conn = await openDb();
    
    // We update the response and use NOW() to save the exact completion time
    await conn.execute(
      'UPDATE pending_alerts SET user_response = :response, responded_at = NOW() WHERE id = :id',
      {'response': userResponse, 'id': id},
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