import 'package:satya_devotte_app/features/rituals/domain/entities/ritual_entity.dart';
import 'package:satya_devotte_app/features/rituals/domain/repositories/ritual_repository.dart';

class GetRitualDetailUseCase {
  GetRitualDetailUseCase(this._repository);
  final RitualRepository _repository;

  Future<RitualEntity?> call(String ritualId) {
    return _repository.getRitualDetail(ritualId);
  }
}
