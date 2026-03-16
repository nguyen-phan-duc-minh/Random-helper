// lib/data/repositories/spin_repository_impl.dart
import '../../domain/entities/spin.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/spin_repository.dart';
import '../local/db_helper.dart';
import '../local/models/spin_model.dart';
import '../local/models/item_model.dart';

class SpinRepositoryImpl implements SpinRepository {
  final DBHelper _dbHelper = DBHelper.instance;

  @override
  Future<List<Spin>> getAllSpins() async {
    final db = await _dbHelper.database;
    final maps = await db.query('spins', orderBy: 'created_at DESC');
    return maps.map((m) => SpinModel.fromMap(m) as Spin).toList();
  }

  @override
  Future<int> createSpin(Spin spin, List<Item> items) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      'spins',
      SpinModel(
        name: spin.name,
        themeColor: spin.themeColor,
        createdAt: spin.createdAt,
        spinDuration: spin.spinDuration,
        isFavorite: spin.isFavorite, // Lưu trạng thái favorite
      ).toMap(),
    );
    for (var it in items) {
      final itemMap = ItemModel(
        spinId: id,
        label: it.label,
        weight: it.weight,
        color: it.color,
      ).toMap();
      await db.insert('items', itemMap);
    }
    return id;
  }

  @override
  Future<void> deleteSpin(int id) async {
    final db = await _dbHelper.database;
    // Xóa items trước (có thể tự động xóa nếu có CASCADE)
    await db.delete('items', where: 'spin_id = ?', whereArgs: [id]);
    // Xóa results
    await db.delete('results', where: 'spin_id = ?', whereArgs: [id]);
    // Xóa spin
    await db.delete('spins', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Item>> getItemsBySpinId(int spinId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'items',
      where: 'spin_id = ?',
      whereArgs: [spinId],
    );
    return maps.map((m) => ItemModel.fromMap(m) as Item).toList();
  }

  @override
  Future<void> saveResult(
    int spinId,
    int itemId,
    String itemLabel, {
    required bool wasRemoved,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('results', {
      'spin_id': spinId,
      'item_id': itemId,
      'item_label': itemLabel,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'was_removed': wasRemoved ? 1 : 0,
    });
  }

  @override
  Future<void> addItem(int spinId, Item item) async {
    final db = await _dbHelper.database;
    await db.insert(
        'items',
        ItemModel(
          spinId: spinId,
          label: item.label,
          weight: item.weight,
          color: item.color,
        ).toMap());
  }

  @override
  Future<void> updateSpin(int spinId, Spin spin) async {
    final db = await _dbHelper.database;
    await db.update(
      'spins',
      SpinModel(
        id: spinId,
        name: spin.name,
        themeColor: spin.themeColor,
        createdAt: spin.createdAt,
        spinDuration: spin.spinDuration,
        isFavorite: spin.isFavorite,
      ).toMap(),
      where: 'id = ?',
      whereArgs: [spinId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getResultsBySpinId(int spinId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'results',
      where: 'spin_id = ?',
      whereArgs: [spinId],
      orderBy: 'timestamp ASC', // Sắp xếp cũ nhất lên đầu (số 1)
    );
  }

  @override
  Future<void> deleteItem(int itemId) async {
    final db = await _dbHelper.database;
    await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  @override
  Future<void> deleteResultsBySpinId(int spinId) async {
    final db = await _dbHelper.database;
    await db.delete('results', where: 'spin_id = ?', whereArgs: [spinId]);
  }

  @override
  Future<void> deleteRemovedResultsBySpinId(int spinId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'results',
      where: 'spin_id = ? AND was_removed = ?',
      whereArgs: [spinId, 1],
    );
  }

  @override
  Future<void> replaceItems(int spinId, List<Item> newItems) async {
    final db = await _dbHelper.database;
    // Bắt đầu transaction để đảm bảo atomicity
    await db.transaction((txn) async {
      // Xóa tất cả items cũ của spin này
      await txn.delete('items', where: 'spin_id = ?', whereArgs: [spinId]);

      // Insert lại tất cả items theo thứ tự mới
      for (var item in newItems) {
        await txn.insert(
            'items',
            ItemModel(
              spinId: spinId,
              label: item.label,
              weight: item.weight,
              color: item.color,
            ).toMap());
      }
    });
  }

  @override
  Future<void> toggleFavorite(int spinId, bool isFavorite) async {
    final db = await _dbHelper.database;
    await db.update(
      'spins',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [spinId],
    );
  }

  @override
  Future<List<Spin>> getFavoriteSpins() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'spins',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SpinModel.fromMap(m) as Spin).toList();
  }
}
