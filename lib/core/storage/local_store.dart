import 'dart:convert';

import 'package:sqflite/sqflite.dart';

abstract interface class LocalStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> value);
  Future<void> close();
}

class SqliteStore implements LocalStore {
  SqliteStore._(this._db);
  final Database _db;

  static Future<SqliteStore> open() async {
    final root = await getDatabasesPath();
    final db = await openDatabase(
      '$root/rafeeq.db',
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE app_state (id INTEGER PRIMARY KEY, payload TEXT NOT NULL)',
      ),
    );
    return SqliteStore._(db);
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    final rows = await _db.query('app_state', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.single['payload']! as String)
        as Map<String, dynamic>;
  }

  @override
  Future<void> write(Map<String, dynamic> value) async {
    final payload = jsonEncode(value);
    await _db.transaction((txn) async {
      await txn.insert('app_state', {
        'id': 1,
        'payload': payload,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> close() => _db.close();
}
