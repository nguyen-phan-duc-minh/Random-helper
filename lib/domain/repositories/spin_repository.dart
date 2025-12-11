import '../entities/spin.dart';
import '../entities/item.dart';

abstract class SpinRepository {
  Future<List<Spin>> getAllSpins();
  Future<int> createSpin(Spin spin, List<Item> items);
  Future<void> deleteSpin(int id);
  Future<List<Item>> getItemsBySpinId(int spinId);
  Future<void> saveResult(int spinId, int itemId, String itemLabel);
  Future<List<Map<String, dynamic>>> getResultsBySpinId(int spinId);
  Future<void> deleteItem(int itemId);
  Future<void> addItem(int spinId, Item item);
  Future<void> updateSpin(int spinId, Spin spin);
}
