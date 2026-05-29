import 'package:mysql_client/mysql_client.dart';
import 'package:dotenv/dotenv.dart';

/// Opens and returns a MySQL connection using values from .env.
/// Caller is responsible for calling [conn.close()] when done.
Future<MySQLConnection> openDb() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

final conn = await MySQLConnection.createConnection(
  host:         env['DB_HOST']     ?? 'localhost',
  port:         int.parse(env['DB_PORT'] ?? '3306'),
  userName:     env['DB_USER']     ?? 'root',
  password:     env['DB_PASSWORD'] ?? '',
  databaseName: env['DB_NAME']     ?? 'fyp_test',
  secure:       false,
);

  await conn.connect();
  return conn;
}