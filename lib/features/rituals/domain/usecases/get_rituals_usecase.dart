import 'package:satya_devotte_app/features/rituals/domain/entities/ritual_entity.dart';
import 'package:satya_devotte_app/features/rituals/domain/repositories/ritual_repository.dart';

class GetRitualsUseCase {
  GetRitualsUseCase(this._repository);
  final RitualRepository _repository;

  Future<List<RitualEntity>> call({bool forceSync = false}) {
    return _repository.getRituals(forceSync: forceSync);
  }
}
