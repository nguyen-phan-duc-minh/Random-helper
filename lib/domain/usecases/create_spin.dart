import '../repositories/spin_repository.dart';
import '../entities/spin.dart';
import '../entities/item.dart';

class CreateSpin {
  final SpinRepository repository;
  CreateSpin(this.repository);

  Future<int> execute(Spin spin, List<Item> items) =>
      repository.createSpin(spin, items);
}
