// lib/data/local/db_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/utils/constants.dart';

class DBHelper {
  static const _dbName = AppConstants.dbName;
  static const _dbVersion = 5;
  static Database? _database;

  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Thêm cột spin_duration cho version 2
      await db.execute('ALTER TABLE spins ADD COLUMN spin_duration INTEGER');
    }
    if (oldVersion < 3) {
      // Thêm cột item_label vào results cho version 3
      try {
        await db.execute('ALTER TABLE results ADD COLUMN item_label TEXT');
        // Cập nhật item_label cho các records cũ bằng cách JOIN với items
        final results = await db.query('results');
        for (var result in results) {
          final itemId = result['item_id'] as int;
          final itemMaps =
              await db.query('items', where: 'id = ?', whereArgs: [itemId]);
          if (itemMaps.isNotEmpty) {
            final label = itemMaps.first['label'] as String;
            await db.update(
              'results',
              {'item_label': label},
              where: 'id = ?',
              whereArgs: [result['id']],
            );
          }
        }
      } catch (e) {
        // Cột đã tồn tại hoặc lỗi, bỏ qua
      }
    }
    if (oldVersion < 4) {
      // Thêm cột is_favorite vào spins cho version 4
      try {
        await db.execute('ALTER TABLE spins ADD COLUMN is_favorite INTEGER DEFAULT 0');
      } catch (e) {
        // Cột đã tồn tại hoặc lỗi, bỏ qua
      }
    }
    if (oldVersion < 5) {
      // Thêm cột was_removed vào results cho version 5
      try {
        await db.execute(
          'ALTER TABLE results ADD COLUMN was_removed INTEGER DEFAULT 0',
        );
        // Trước version 5, app luôn loại mục sau khi quay => toàn bộ lịch sử cũ được xem là "đã loại"
        await db.execute('UPDATE results SET was_removed = 1');
      } catch (e) {
        // Cột đã tồn tại hoặc lỗi, bỏ qua
      }
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        theme_color TEXT,
        created_at INTEGER NOT NULL,
        spin_duration INTEGER,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        spin_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        weight INTEGER NOT NULL DEFAULT 1,
        color TEXT,
        FOREIGN KEY(spin_id) REFERENCES spins(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        spin_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        item_label TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        was_removed INTEGER DEFAULT 0
      )
    ''');
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
