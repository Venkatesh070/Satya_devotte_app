import 'package:satya_devotte_app/features/pujas/domain/entities/puja_entity.dart';
import 'package:satya_devotte_app/features/pujas/domain/repositories/puja_repository.dart';

class GetRitualsUseCase {
  GetRitualsUseCase(this._repository);
  final RitualRepository _repository;

  Future<List<RitualEntity>> call({bool forceSync = false}) {
    return _repository.getRituals(forceSync: forceSync);
  }
}
