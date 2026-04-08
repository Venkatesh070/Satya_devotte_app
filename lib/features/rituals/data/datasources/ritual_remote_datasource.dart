import 'package:satya_devotte_app/features/rituals/data/models/ritual_model.dart';

class RitualRemoteDataSource {
  RitualRemoteDataSource();

  Future<List<RitualModel>> getRituals() async {
    return const [
      RitualModel(
        id: 'ritual_1',
        title: 'Morning Prayer',
        description: 'Begin the day with gratitude and a short mantra.',
        steps: ['Clean altar', 'Light lamp', 'Chant mantra 11 times'],
        mediaUrl: '',
        offlineAvailable: false,
        updatedAtEpoch: 1,
      ),
    ];
  }

  Future<RitualModel?> getRitualDetail(String ritualId) async {
    final rituals = await getRituals();
    for (final ritual in rituals) {
      if (ritual.id == ritualId) {
        return ritual;
      }
    }
    return null;
  }
}
