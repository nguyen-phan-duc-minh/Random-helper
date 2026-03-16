import 'package:flutter/material.dart';
import '../../domain/repositories/spin_repository.dart';
import '../../domain/entities/spin.dart';
import '../../domain/entities/item.dart';
import '../../domain/usecases/get_spins.dart';
import '../../domain/usecases/create_spin.dart';
import '../../domain/usecases/spin_once.dart';
import '../../domain/usecases/restore_items.dart';
import '../../domain/usecases/shuffle_items.dart';

class SpinProvider extends ChangeNotifier {
  final SpinRepository repository;
  late final GetSpins _getSpins;
  late final CreateSpin _createSpin;
  late final SpinOnce _spinOnce;
  late final RestoreItems _restoreItems;
  late final ShuffleItems _shuffleItems;

  List<Spin> spins = [];
  bool loading = false;
  String? _error;

  String? get error => _error;

  SpinProvider(this.repository) {
    _getSpins = GetSpins(repository);
    _createSpin = CreateSpin(repository);
    _spinOnce = SpinOnce(repository);
    _restoreItems = RestoreItems(repository);
    _shuffleItems = ShuffleItems(repository);
  }

  Future<void> loadSpins() async {
    try {
      loading = true;
      _error = null;
      notifyListeners();
      spins = await _getSpins.execute();
      _error = null;
    } catch (e) {
      _error = 'Lỗi khi tải danh sách: ${e.toString()}';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<int> createSpin(Spin spin, List<Item> items) async {
    try {
      _error = null;
      final id = await _createSpin.execute(spin, items);
      await loadSpins();
      return id;
    } catch (e) {
      _error = 'Lỗi khi tạo vòng quay: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSpin(int id) async {
    try {
      _error = null;
      await repository.deleteSpin(id);
      await loadSpins();
    } catch (e) {
      _error = 'Lỗi khi xóa vòng quay: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Item>> getItems(int spinId) async {
    try {
      return await repository.getItemsBySpinId(spinId);
    } catch (e) {
      _error = 'Lỗi khi tải danh sách mục: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<Item> spinOnce(int spinId) async {
    try {
      _error = null;
      final chosen = await _spinOnce.execute(spinId);
      if (chosen.id != null) {
        await repository.saveResult(
          spinId,
          chosen.id!,
          chosen.label,
          wasRemoved: false,
        );
      }
      return chosen;
    } catch (e) {
      _error = 'Lỗi khi quay: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<Item> spinOnceWithMode(int spinId, {required bool removeAfterSpin}) async {
    try {
      _error = null;
      final chosen = await _spinOnce.execute(spinId);
      if (chosen.id != null) {
        await repository.saveResult(
          spinId,
          chosen.id!,
          chosen.label,
          wasRemoved: removeAfterSpin,
        );
      }
      return chosen;
    } catch (e) {
      _error = 'Lỗi khi quay: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      _error = null;
      await repository.deleteItem(itemId);
      notifyListeners();
    } catch (e) {
      _error = 'Lỗi khi xóa mục: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addItem(int spinId, Item item) async {
    try {
      _error = null;
      await repository.addItem(spinId, item);
      notifyListeners();
    } catch (e) {
      _error = 'Lỗi khi thêm mục: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSpin(int spinId, Spin spin) async {
    try {
      _error = null;
      await repository.updateSpin(spinId, spin);
      await loadSpins();
    } catch (e) {
      _error = 'Lỗi khi cập nhật: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<String> generateShareLink(int spinId) async {
    try {
      final spin = spins.firstWhere((s) => s.id == spinId);
      final items = await getItems(spinId);

      // Tạo deep link cho app
      final deepLink = 'randomhelper://spin/$spinId';

      // Tạo shareable text đẹp với link
      final buffer = StringBuffer();
      buffer.writeln('🎰 Random Helper: ${spin.name}');
      buffer.writeln('');
      buffer.writeln('📋 Danh sách mục (${items.length} mục):');
      for (var i = 0; i < items.length; i++) {
        buffer.writeln('${i + 1}. ${items[i].label}');
      }
      buffer.writeln('');
      buffer.writeln('🔗 Link vòng quay:');
      buffer.writeln(deepLink);
      buffer.writeln('');
      buffer.writeln('💡 Tải app Random Helper để quay ngay!');
      buffer.writeln('');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('Random Helper - Chọn ngẫu nhiên');

      return buffer.toString();
    } catch (e) {
      _error = 'Lỗi khi tạo link chia sẻ: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<String> exportSpinJson(int spinId) async {
    try {
      final spin = spins.firstWhere((s) => s.id == spinId);
      final items = await getItems(spinId);
      final map = {
        'version': 1,
        'spin': {
          'name': spin.name,
          'theme_color': spin.themeColor,
          'created_at': spin.createdAt,
        },
        'items': items
            .map(
              (it) => {
                'label': it.label,
                'weight': it.weight,
                'color': it.color,
              },
            )
            .toList(),
      };
      // Convert to pretty JSON string
      return map.toString().replaceAll(', ', ',\n    ');
    } catch (e) {
      _error = 'Lỗi khi export: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Khôi phục lại tất cả items đã bị xóa từ lịch sử quay
  /// Trả về số lượng items đã khôi phục
  Future<int> restoreItems(int spinId) async {
    try {
      _error = null;
      final count = await _restoreItems.execute(spinId);
      notifyListeners();
      return count;
    } catch (e) {
      _error = 'Lỗi khi khôi phục items: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearHistory(int spinId) async {
    try {
      _error = null;
      await repository.deleteResultsBySpinId(spinId);
      notifyListeners();
    } catch (e) {
      _error = 'Lỗi khi xóa lịch sử: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Trộn (shuffle) danh sách items trong vòng quay
  Future<void> shuffleItems(int spinId) async {
    try {
      _error = null;
      await _shuffleItems.execute(spinId);
      notifyListeners();
    } catch (e) {
      _error = 'Lỗi khi trộn items: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Đánh dấu/bỏ đánh dấu vòng quay yêu thích
  Future<void> toggleFavorite(int spinId, bool isFavorite) async {
    try {
      _error = null;
      await repository.toggleFavorite(spinId, isFavorite);
      // Cập nhật lại danh sách spins để reflect thay đổi
      await loadSpins();
    } catch (e) {
      _error = 'Lỗi khi cập nhật yêu thích: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Lấy danh sách vòng quay yêu thích
  Future<List<Spin>> getFavoriteSpins() async {
    try {
      _error = null;
      return await repository.getFavoriteSpins();
    } catch (e) {
      _error = 'Lỗi khi tải danh sách yêu thích: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}
