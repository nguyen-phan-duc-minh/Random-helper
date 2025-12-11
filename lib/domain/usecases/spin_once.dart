import 'dart:math';
import '../repositories/spin_repository.dart';
import '../entities/item.dart';

class SpinOnce {
  final SpinRepository repository;
  final Random _rnd;

  SpinOnce(this.repository, [Random? rnd]) : _rnd = rnd ?? Random();

  Future<Item> execute(int spinId) async {
    final items = await repository.getItemsBySpinId(spinId);
    if (items.isEmpty) {
      throw Exception('Không có mục nào để quay');
    }

    // Tính tổng trọng số
    final total = items.fold<int>(
      0,
      (p, e) => p + (e.weight > 0 ? e.weight : 1),
    );

    if (total <= 0) {
      throw Exception('Tổng trọng số không hợp lệ');
    }

    // Chọn ngẫu nhiên dựa trên trọng số
    final r = _rnd.nextInt(total);
    var acc = 0;
    Item? selectedItem;

    for (var it in items) {
      acc += (it.weight > 0 ? it.weight : 1);
      if (r < acc) {
        selectedItem = it;
        break;
      }
    }

    // Fallback về item đầu tiên nếu không tìm thấy (không nên xảy ra)
    selectedItem ??= items.first;

    // Lưu kết quả nếu có id
    if (selectedItem.id != null) {
      await repository.saveResult(spinId, selectedItem.id!, selectedItem.label);
    }

    return selectedItem;
  }
}

