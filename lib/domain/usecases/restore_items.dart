import '../repositories/spin_repository.dart';
import '../entities/item.dart';

/// Use case để khôi phục lại các items đã bị xóa sau khi quay
/// Lấy từ lịch sử results và tạo lại items (với weight và color mặc định)
class RestoreItems {
  final SpinRepository repository;

  RestoreItems(this.repository);

  /// Khôi phục tất cả items đã quay từ lịch sử results
  /// Trả về số lượng items đã khôi phục
  Future<int> execute(int spinId) async {
    // Lấy tất cả results của spin này
    final results = await repository.getResultsBySpinId(spinId);

    if (results.isEmpty) {
      return 0; // Không có gì để khôi phục
    }

    // Chỉ khôi phục các lượt quay đã loại mục (was_removed = 1)
    final removedResults = results.where((r) {
      final removed = r['was_removed'];
      return (removed is int && removed == 1) || (removed is bool && removed == true);
    }).toList();

    if (removedResults.isEmpty) {
      return 0; // Không có mục nào bị loại để khôi phục
    }

    // Tạo lại items theo đúng các lượt đã bị loại.
    // (Giữ được cả trường hợp label trùng nhau)
    int restoredCount = 0;
    for (var result in removedResults) {
      final label = result['item_label'] as String?;
      if (label == null || label.trim().isEmpty) continue;
      final item = Item(
        label: label.trim(),
        weight: 1, // Mặc định
        color: null, // Không lưu color trong results nên để null
      );
      await repository.addItem(spinId, item);
      restoredCount++;
    }

    // Xóa các results "đã loại" sau khi khôi phục (giữ lại lịch sử không loại)
    await repository.deleteRemovedResultsBySpinId(spinId);

    return restoredCount;
  }
}
