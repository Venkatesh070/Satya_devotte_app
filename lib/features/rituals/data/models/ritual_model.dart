import 'package:satya_devotte_app/features/rituals/domain/entities/ritual_entity.dart';

class RitualModel extends RitualEntity {
  const RitualModel({
    required super.id,
    required super.title,
    required super.description,
    required super.steps,
    required super.mediaUrl,
    required super.offlineAvailable,
    required super.updatedAtEpoch,
  });

  factory RitualModel.fromJson(Map<String, dynamic> json) {
    return RitualModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>? ?? []).cast<String>(),
      mediaUrl: json['mediaUrl'] as String? ?? '',
      offlineAvailable: json['offlineAvailable'] as bool? ?? false,
      updatedAtEpoch: json['updatedAtEpoch'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'steps': steps,
        'mediaUrl': mediaUrl,
        'offlineAvailable': offlineAvailable,
        'updatedAtEpoch': updatedAtEpoch,
      };

  RitualModel copyWith({bool? offlineAvailable}) {
    return RitualModel(
      id: id,
      title: title,
      description: description,
      steps: steps,
      mediaUrl: mediaUrl,
      offlineAvailable: offlineAvailable ?? this.offlineAvailable,
      updatedAtEpoch: updatedAtEpoch,
    );
  }
}
