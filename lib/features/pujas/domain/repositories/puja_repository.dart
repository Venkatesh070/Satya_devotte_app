import 'package:satya_devotte_app/features/pujas/domain/entities/puja_entity.dart';

abstract class RitualRepository {
  Future<List<RitualEntity>> getRituals({bool forceSync = false});
  Future<RitualEntity?> getRitualDetail(String ritualId);
  Future<void> syncRituals();
}
