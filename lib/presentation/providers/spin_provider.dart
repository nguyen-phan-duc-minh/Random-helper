import 'package:flutter/material.dart';
import '../../domain/repositories/spin_repository.dart';
import '../../domain/entities/spin.dart';
import '../../domain/entities/item.dart';
import '../../domain/usecases/get_spins.dart';
import '../../domain/usecases/create_spin.dart';
import '../../domain/usecases/spin_once.dart';

class SpinProvider extends ChangeNotifier {
  final SpinRepository repository;
  late final GetSpins _getSpins;
  late final CreateSpin _createSpin;
  late final SpinOnce _spinOnce;

  List<Spin> spins = [];
  bool loading = false;
  String? _error;

  String? get error => _error;

  SpinProvider(this.repository) {
    _getSpins = GetSpins(repository);
    _createSpin = CreateSpin(repository);
    _spinOnce = SpinOnce(repository);
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
      return await _spinOnce.execute(spinId);
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
      
      // Tạo shareable text đẹp
      final buffer = StringBuffer();
      buffer.writeln('🎰 Vòng quay may mắn: ${spin.name}');
      buffer.writeln('');
      buffer.writeln('📋 Danh sách mục:');
      for (var i = 0; i < items.length; i++) {
        buffer.writeln('${i + 1}. ${items[i].label}');
      }
      buffer.writeln('');
      buffer.writeln('💡 Mở app LuckyHub để quay ngay!');
      
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
}
