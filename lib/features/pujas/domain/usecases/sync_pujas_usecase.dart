import 'package:satya_devotte_app/features/pujas/domain/repositories/puja_repository.dart';

class SyncRitualsUseCase {
  SyncRitualsUseCase(this._repository);
  final RitualRepository _repository;

  Future<void> call() => _repository.syncRituals();
}
