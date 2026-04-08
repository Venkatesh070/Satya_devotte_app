import 'package:flutter_test/flutter_test.dart';
import 'package:satya_devotte_app/features/rituals/domain/entities/ritual_entity.dart';
import 'package:satya_devotte_app/features/rituals/domain/repositories/ritual_repository.dart';
import 'package:satya_devotte_app/features/rituals/domain/usecases/get_ritual_detail_usecase.dart';
import 'package:satya_devotte_app/features/rituals/domain/usecases/get_rituals_usecase.dart';
import 'package:satya_devotte_app/features/rituals/domain/usecases/sync_rituals_usecase.dart';
import 'package:satya_devotte_app/features/rituals/presentation/controllers/ritual_controller.dart';

class _FakeRepo implements RitualRepository {
  final _ritual = const RitualEntity(
    id: 'r1',
    title: 'Ganesh Puja',
    description: 'Auspicious ritual',
    steps: ['Prepare altar'],
    mediaUrl: '',
    offlineAvailable: true,
    updatedAtEpoch: 1,
  );

  @override
  Future<RitualEntity?> getRitualDetail(String ritualId) async => _ritual;

  @override
  Future<List<RitualEntity>> getRituals({bool forceSync = false}) async => [_ritual];

  @override
  Future<void> syncRituals() async {}
}

void main() {
  test('loadRituals populates list', () async {
    final repo = _FakeRepo();
    final controller = RitualController(
      GetRitualsUseCase(repo),
      GetRitualDetailUseCase(repo),
      SyncRitualsUseCase(repo),
    );

    await controller.loadRituals();
    expect(controller.rituals.length, 1);
    expect(controller.errorMessage.value, '');
  });
}
