import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dotenv/dotenv.dart';
import 'db.dart';

/// GET /get_recipes
///
/// 1. Reads fridge contents from `predictions` table.
/// 2. Pipes them as JSON to the Python recommend.py script via stdin.
/// 3. Streams the script's stdout back to the client as JSON.
Future<Response> getRecipesHandler(Request request) async {
  // ── 1. Fetch fridge items ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> fridge = [];

  try {
    final conn = await openDb();
    final result = await conn.execute(
      'SELECT item_name, status, life_remaining FROM predictions',
    );

    for (final row in result.rows) {
      fridge.add({
        'name':           row.colByName('item_name'),
        'status':         row.colByName('status'),
        'life_remaining': double.tryParse(
                            row.colByName('life_remaining')?.toString() ?? '0',
                          ) ?? 0.0,
      });
    }

    await conn.close();
  } catch (e) {
    return _jsonError('DB error: $e');
  }

  // ── 2. Spawn Python recommend.py, pipe JSON via stdin ─────────────────────
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final pythonExe    = env['PYTHON_EXE']        ?? 'python';
  final scriptPath   = env['RECOMMEND_SCRIPT']  ?? 'recommend.py';
  final fridgeJson   = jsonEncode(fridge);

  Process process;
  try {
    process = await Process.start(pythonExe, [scriptPath]);
  } catch (e) {
    return _jsonError('Failed to start Python process: $e');
  }

  process.stdin.write(fridgeJson);
  await process.stdin.close();

  final output = await process.stdout.transform(utf8.decoder).join();
  final errors = await process.stderr.transform(utf8.decoder).join();
  await process.exitCode;

  final trimmed = output.trim();

  if (trimmed.isEmpty) {
    return _jsonError(
      'Python returned nothing. Stderr: ${errors.trim()}',
    );
  }

  if (trimmed[0] != '[' && trimmed[0] != '{') {
    return _jsonError(
      'Python error: $trimmed',
      extra: {'stderr': errors.trim()},
    );
  }

  // ── 3. Return the Python output directly (already valid JSON) ─────────────
  return Response.ok(
    trimmed,
    headers: {'Content-Type': 'application/json'},
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Response _jsonError(String message, {Map<String, dynamic>? extra}) {
  final body = <String, dynamic>{'error': message};
  if (extra != null) body.addAll(extra);
  return Response.internalServerError(
    body:    jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}