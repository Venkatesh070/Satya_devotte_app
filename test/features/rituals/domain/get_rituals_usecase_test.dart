import 'package:flutter_test/flutter_test.dart';
import 'package:satya_devotte_app/features/rituals/domain/entities/ritual_entity.dart';
import 'package:satya_devotte_app/features/rituals/domain/repositories/ritual_repository.dart';
import 'package:satya_devotte_app/features/rituals/domain/usecases/get_rituals_usecase.dart';

class _FakeRitualRepository implements RitualRepository {
  @override
  Future<RitualEntity?> getRitualDetail(String ritualId) async => null;

  @override
  Future<List<RitualEntity>> getRituals({bool forceSync = false}) async {
    return [
      const RitualEntity(
        id: '1',
        title: 'Morning Pooja',
        description: 'Daily prayer ritual',
        steps: ['Light lamp', 'Offer flowers'],
        mediaUrl: '',
        offlineAvailable: false,
        updatedAtEpoch: 1,
      ),
    ];
  }

  @override
  Future<void> syncRituals() async {}
}

void main() {
  test('returns rituals from repository', () async {
    final useCase = GetRitualsUseCase(_FakeRitualRepository());
    final result = await useCase();
    expect(result, isNotEmpty);
    expect(result.first.title, 'Morning Pooja');
  });
}
