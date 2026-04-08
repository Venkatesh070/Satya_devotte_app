import 'package:satya_devotte_app/features/rituals/domain/entities/ritual_entity.dart';

abstract class RitualRepository {
  Future<List<RitualEntity>> getRituals({bool forceSync = false});
  Future<RitualEntity?> getRitualDetail(String ritualId);
  Future<void> syncRituals();
}
