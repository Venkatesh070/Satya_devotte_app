import 'package:equatable/equatable.dart';

class RitualEntity extends Equatable {
  const RitualEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.mediaUrl,
    required this.offlineAvailable,
    required this.updatedAtEpoch,
  });

  final String id;
  final String title;
  final String description;
  final List<String> steps;
  final String mediaUrl;
  final bool offlineAvailable;
  final int updatedAtEpoch;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        steps,
        mediaUrl,
        offlineAvailable,
        updatedAtEpoch,
      ];
}
