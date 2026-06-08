import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';

import 'package:recens_backend/get_recipes.dart';
import 'package:recens_backend/get_items.dart';
import 'package:recens_backend/alterts/get_alerts.dart';
import 'package:recens_backend/get_expiry.dart';
import 'package:recens_backend/alterts/get_missing_items.dart';
import 'package:recens_backend/alterts/get_incompatible.dart';


void main() async {
  final env  = DotEnv(includePlatformEnvironment: true)..load();
  final port = int.parse(env['PORT'] ?? '8080');

  // ── Router ──────────────────────────────────────────────────────────────────
  final router = Router()
    ..get('/get_recipes', getRecipesHandler)
    ..get('/get_items',   getItemsHandler)
    ..get('/get_alerts',  getAlertsHandler)
    ..get('/get_expiry',  getExpiryHandler)
    ..get('/get_missing_items', getMissingItemsHandler) // ✅ Leaves this as a GET request
    ..post('/set_response', setResponseHandler)         // ✅ Fixed: Changed to .post and matches the app URL
    ..get('/get_incompatible', getIncompatibleHandler) // ✅ New route for incompatible-item alerts
    ..post('/set_expiry', setExpiryHandler);

  // ── Middleware ───────────────────────────────────────────────────────────────
  final handler = Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('✅  Recens backend listening on http://0.0.0.0:${server.port}');
  print('   Routes:');
  print('     GET  /get_recipes');
  print('     GET  /get_items');
  print('     GET  /get_alerts');
  print('     GET  /get_expiry');
  print('     POST /set_expiry');
}

// ── CORS middleware ────────────────────────────────────────────────────────────
Middleware _corsMiddleware() {
  const corsHeaders = {
    'Access-Control-Allow-Origin':  '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      final response = await inner(request);
      return response.change(headers: corsHeaders);
    };
  };
}