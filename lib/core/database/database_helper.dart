import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('condominios_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla para la cola de sincronización offline idempotente
    await db.execute('''
      CREATE TABLE offline_sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_uuid TEXT NOT NULL UNIQUE,
        tipo TEXT NOT NULL,
        condominio_id INTEGER NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL, -- PENDING, SYNCING, SYNCED, ERROR
        retry_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabla de caché local de unidades para seleccionar offline
    await db.execute('''
      CREATE TABLE cached_unidades (
        id INTEGER PRIMARY KEY,
        condominio_id INTEGER NOT NULL,
        codigo TEXT NOT NULL,
        estado TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertSyncItem(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      'offline_sync_queue',
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingItems(int condominioId) async {
    final db = await instance.database;
    return await db.query(
      'offline_sync_queue',
      where: 'condominio_id = ? AND status IN (?, ?)',
      whereArgs: [condominioId, 'PENDING', 'ERROR'],
      orderBy: 'id ASC',
    );
  }

  Future<int> updateItemStatus(String syncUuid, String status, {String? errorMessage}) async {
    final db = await instance.database;
    return await db.update(
      'offline_sync_queue',
      {
        'status': status,
        'error_message': errorMessage,
      },
      where: 'sync_uuid = ?',
      whereArgs: [syncUuid],
    );
  }

  Future<int> getPendingCount(int condominioId) async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_sync_queue WHERE condominio_id = ? AND status != ?',
      [condominioId, 'SYNCED'],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }
}
