import '../repositories/spin_repository.dart';
import '../entities/spin.dart';

class GetSpins {
  final SpinRepository repository;
  GetSpins(this.repository);

  Future<List<Spin>> execute() => repository.getAllSpins();
}
