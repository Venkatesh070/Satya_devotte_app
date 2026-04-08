import 'package:hive/hive.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';
import 'package:satya_devotte_app/features/rituals/data/models/ritual_model.dart';

class RitualLocalDataSource {
  Box<dynamic> get _box => Hive.box(AppConstants.ritualsBox);

  Future<void> saveRituals(List<RitualModel> rituals) async {
    final map = <String, dynamic>{};
    for (final ritual in rituals) {
      map[ritual.id] = ritual.toJson();
    }
    await _box.putAll(map);
  }

  Future<List<RitualModel>> getRituals() async {
    return _box.values
        .map((json) => RitualModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<RitualModel?> getRitualDetail(String ritualId) async {
    final json = _box.get(ritualId);
    if (json == null) return null;
    return RitualModel.fromJson(Map<String, dynamic>.from(json));
  }
}
