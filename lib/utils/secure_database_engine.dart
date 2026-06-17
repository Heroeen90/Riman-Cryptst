import 'package:sqflite_sqlcipher/sqflite.dart';

class SecureDatabaseEngine {
  static Future<Database> open(String path, String password) async {
    return await openDatabase(
      path,
      password: password,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE secure_data (id INTEGER PRIMARY KEY, key TEXT, value TEXT)');
      },
    );
  }

  static Future<void> shredData(List<int> bytes) async {
    // Overwrite with zeros
    bytes.fillRange(0, bytes.length, 0);
  }
}
