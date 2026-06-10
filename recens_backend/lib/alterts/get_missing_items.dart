import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db.dart';

Future<Response> getMissingItemsHandler(Request request) async {
  final conn = await openDb();
  try {
    final result = await conn.execute(
      'SELECT id, item_name, minutes_out, alert_level '
      "FROM pending_alerts "
      "WHERE user_response IS NULL AND alert_type = 'missing' "
      'ORDER BY alert_level DESC, id ASC',
    );

    final items = result.rows.map((row) {
      final itemName   = row.colByName('item_name')?.toString()  ?? '';
      final minutesOut = int.tryParse(row.colByName('minutes_out')?.toString() ?? '0') ?? 0;
      final alertLevel = int.tryParse(row.colByName('alert_level')?.toString() ?? '1') ?? 1;
      final id         = row.colByName('id')?.toString();

      final hours   = minutesOut ~/ 60;
      final mins    = minutesOut % 60;
      final timeStr = hours > 0
          ? (mins > 0 ? '${hours}h ${mins}m' : '${hours}h')
          : '${mins}m';
      final message = minutesOut > 0
          ? '$itemName has been out of the fridge for $timeStr.'
          : '$itemName was removed from the fridge.';

      return {
        'id':          id,
        'item_name':   itemName,
        'minutes_out': minutesOut,
        'alert_level': alertLevel,
        'message':     message,
      };
    }).toList();

    return Response.ok(
      jsonEncode(items),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e, stack) {
    print('getMissingItemsHandler error: $e\n$stack');
    return Response.internalServerError(
      body:    jsonEncode({'error': 'DB error: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  } finally {
    await conn.close();
  }
}

Future<Response> setResponseHandler(Request request) async {
  final conn = await openDb();
  try {
    final body         = await request.readAsString();
    print('setResponseHandler body: $body');
    final data         = jsonDecode(body) as Map<String, dynamic>;
    final id           = data['id'];
    final userResponse = data['user_response'] as String?;

    if (id == null || userResponse == null) {
      return Response.badRequest(
        body:    jsonEncode({'error': 'id and user_response are required'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (userResponse != 'returned' && userResponse != 'finished') {
      return Response.badRequest(
        body:    jsonEncode({'error': 'user_response must be returned or finished'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final alertResult = await conn.execute(
      'SELECT item_name, food_detection_id FROM pending_alerts WHERE id = :id',
      {'id': id},
    );

    if (alertResult.rows.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Alert not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final itemName        = alertResult.rows.first.colByName('item_name')?.toString();
    final foodDetectionId = alertResult.rows.first.colByName('food_detection_id')?.toString();

    print('setResponseHandler itemName: $itemName, foodDetectionId: $foodDetectionId');

    if (itemName == null || itemName.isEmpty) {
      return Response.internalServerError(
        body:    jsonEncode({'error': 'Could not resolve item name for alert $id'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (userResponse == 'returned') {
      // 1. Delete pending_alerts
      await conn.execute(
        'DELETE FROM pending_alerts WHERE item_name = :name AND user_response IS NULL',
        {'name': itemName},
      );

      // 2. Delete from missing_items
      await conn.execute(
        'DELETE FROM missing_items WHERE item_name = :name',
        {'name': itemName},
      );

      print('returned: deleted $itemName from pending_alerts and missing_items');

    } else {
      // finished
      String? detectionId = foodDetectionId;
      if (detectionId == null) {
        final detResult = await conn.execute(
          'SELECT id FROM food_detections WHERE item_name = :name ORDER BY id DESC LIMIT 1',
          {'name': itemName},
        );
        if (detResult.rows.isNotEmpty) {
          detectionId = detResult.rows.first.colByName('id')?.toString();
        }
      }

      print('setResponseHandler detectionId: $detectionId');

      if (detectionId != null) {
        await conn.execute(
          'UPDATE missing_items SET food_detection_id = NULL WHERE food_detection_id = :did',
          {'did': detectionId},
        );
        await conn.execute(
          'UPDATE pending_alerts SET food_detection_id = NULL WHERE food_detection_id = :did',
          {'did': detectionId},
        );
      }

      // 1. Delete pending_alerts
      await conn.execute(
        'DELETE FROM pending_alerts WHERE item_name = :name',
        {'name': itemName},
      );

      // 2. Delete from missing_items
      await conn.execute(
        'DELETE FROM missing_items WHERE item_name = :name',
        {'name': itemName},
      );

      // 3. Delete food_detections (FKs already nullified above)
      if (detectionId != null) {
        await conn.execute(
          'DELETE FROM food_detections WHERE id = :did',
          {'did': detectionId},
        );
      }

      // 4. Delete predictions
      await conn.execute(
        'DELETE FROM predictions WHERE item_name = :name',
        {'name': itemName},
      );

      print('finished: deleted $itemName from all tables');
    }

    return Response.ok(
      jsonEncode({'success': true, 'item': itemName, 'action': userResponse}),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e, stack) {
    print('setResponseHandler error: $e\n$stack');
    return Response.internalServerError(
      body:    jsonEncode({'error': 'DB error: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  } finally {
    await conn.close();
  }
}