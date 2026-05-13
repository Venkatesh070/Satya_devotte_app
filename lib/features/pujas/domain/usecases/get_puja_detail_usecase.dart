import 'package:satya_devotte_app/features/pujas/domain/entities/puja_entity.dart';
import 'package:satya_devotte_app/features/pujas/domain/repositories/puja_repository.dart';

class GetRitualDetailUseCase {
  GetRitualDetailUseCase(this._repository);
  final RitualRepository _repository;

  Future<RitualEntity?> call(String ritualId) {
    return _repository.getRitualDetail(ritualId);
  }
}
